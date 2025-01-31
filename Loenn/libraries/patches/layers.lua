--[[
    Adds support for Editor Layers - allows for putting entities/decals/triggers into many seperate layers to ease editing

    NOTE: This file is *extremely* hacky.
]]

local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() or not extSettings.get("_enabled", true, "layers") then
    return {}
end

local prevLayerHotkey = extSettings.get("hotkeys_previousLayer", "shift + left", "layers") -- left arrow
local nextLayerHotkey = extSettings.get("hotkeys_nextLayer", "shift + right", "layers") -- right arrow
local resetLayerHotkey = extSettings.get("hotkeys_viewAllLayers", "shift + down", "layers") -- Makes you see all layers at once

local entities = require("entities")
local decals = require("decals")
local utils = require("utils")
local hotkeyHandler = require("hotkey_handler")
local celesteRender = require("celeste_render")
local loadedState = require("loaded_state")
local selectionUtils = require("selections")
local placementUtils = require("placement_utils")
local decalStruct = require("structs.decal")
local selectionTool = require("tools.selection")

local layersAPI = require("mods").requireFromPlugin("libraries.api.layers")

-- if we just hot reloaded, we'll need to undo our "hooks"
if entities.___lonnLayers then
    entities.___lonnLayers.unload()
end

local function currentLayer()
    return layersAPI.getCurrentLayer()
end

local function isInCurrentLayer(item)
    --if not item._editorLayer then return true end
    return layersAPI.isInCurrentLayer(item)
end

---tries to set the alpha of a drawable
local function setAlpha(drawable, alpha)
    if drawable.color then
        local c = drawable.color
        drawable.color = {c[1] * alpha, c[2] * alpha, c[3] * alpha, (c[4] or 1) * alpha}
    elseif drawable.setColor then
        drawable:setColor({1, 1, 1, alpha})
    end

    return drawable
end

-- set alpha to sprites
local _orig_getDrawableUnsafe = entities.getDrawableUnsafe
function entities.getDrawableUnsafe(name, handler, room, entity, ...)
    local entityDrawable, depth = _orig_getDrawableUnsafe(name, handler, room, entity, ...)

    if not isInCurrentLayer(entity) then
        if utils.typeof(entityDrawable) == "table" then
            for _, value in ipairs(entityDrawable) do
                setAlpha(value, layersAPI.hiddenLayerAlpha)
            end
        else
            setAlpha(entityDrawable, layersAPI.hiddenLayerAlpha)
        end
    end


    return entityDrawable, depth
end

local _orig_decal_getDrawable = decals.getDrawable
function decals.getDrawable(texture, handler, room, decal, viewport)
    local drawable, depth = _orig_decal_getDrawable(texture, handler, room, decal, viewport)

    if drawable and not isInCurrentLayer(decal) then
        setAlpha(drawable, layersAPI.hiddenLayerAlpha)
    end

    if drawable and isInCurrentLayer(decal) then
        setAlpha(drawable, 1.5) -- ???
    end

    return drawable, depth
end

-- disable selections for items in the wrong editor layer
local _orig_getSelectionsForItem = selectionUtils.getSelectionsForItem
function selectionUtils.getSelectionsForItem(room, layer, item, rectangles)
    if item._fromLayer then
        -- this field gets set when pasting something
        -- Paste the item in your current layer, required to not crash and it's nicer to use
        layersAPI.setLayer(item, layersAPI.getCurrentLayer())
    end

    if isInCurrentLayer(item) then
        return _orig_getSelectionsForItem(room, layer, item, rectangles)
    end

    return rectangles or {}
end

-- set layer on place
local _orig_finalizePlacement = placementUtils.finalizePlacement
placementUtils.finalizePlacement = function(room, layer, item)
    _orig_finalizePlacement(room, layer, item)

    if not item._editorLayer then
        local newLayer = currentLayer()
        if newLayer ~= 0 then
            item._editorLayer = newLayer
        end
    end

end

-- read decal layers from the .bin
local _orig_decal_decode = decalStruct.decode
function decalStruct.decode(data)
    local decal = _orig_decal_decode(data)

    decal._editorLayer = data._editorLayer

    return decal
end

-- save decal layers to the .bin
local _orig_decal_encode = decalStruct.encode
function decalStruct.encode(decal)
    local res = _orig_decal_encode(decal)

    local layer = decal._editorLayer
    if layer and layer ~= 0 then
        res._editorLayer = layer
    end

    return res
end

-- force rerender a room when you select it - this way, if you changed layers while in a different room, the correct layers will be visible in the newly selected room
--[[

    local orig_loadedState_selectItem = loadedState.selectItem
    function loadedState.selectItem(item, add, ...)
        orig_loadedState_selectItem(item, add, ...)
    
        local itemType = utils.typeof(item)
    
        if itemType == "room" then
            celesteRender.invalidateRoomCache(item)
            celesteRender.forceRoomBatchRender(item, loadedState)
        end
    end
]]

-- hotkeys
local layerHotkeys = { }

-- redraws the currently selected room, used for hotkeys
local function hotkeyRedraw()
    local room = loadedState.getSelectedRoom()
    celesteRender.invalidateRoomCache(room)
    celesteRender.forceRoomBatchRender(room, loadedState)
end

hotkeyHandler.addHotkey("global", nextLayerHotkey, function ()
    entities.___lonnLayers.nextLayer(1)
end)
hotkeyHandler.addHotkey("global", prevLayerHotkey, function ()
    entities.___lonnLayers.nextLayer(-1)
end, layerHotkeys)
hotkeyHandler.addHotkey("global", resetLayerHotkey, function ()
    entities.___lonnLayers.nextLayer(nil)
end, layerHotkeys)

-- unloads our "hooks"
local function unload()
    entities.getDrawableUnsafe = _orig_getDrawableUnsafe
    selectionUtils.getSelectionsForItem = _orig_getSelectionsForItem
    placementUtils.finalizePlacement = _orig_finalizePlacement
    decals.getDrawable = _orig_decal_getDrawable
    decalStruct.encode = _orig_decal_encode
    decalStruct.decode = _orig_decal_decode
end

-- we'll hackily save our data to somewhere that doesn't get hot-reloaded. This way, we can undo our hooks, preserve layers, etc.
entities.___lonnLayers = {
    layer = 0,
    any = true,
    unload = unload,
    nextLayer = function (by)
        if not by then
            entities.___lonnLayers.any = not entities.___lonnLayers.any
        else
            entities.___lonnLayers.any = false
            entities.___lonnLayers.layer = entities.___lonnLayers.layer + by
        end

        -- TODO: move somewhere more sane...
        if not entities.___lonnLayers.layerDisplayAdded then
            require("input_device").newInputDevice(
                require("scene_handler").getCurrentScene().inputDevices,
                require("mods").requireFromPlugin("input_devices.layerDisplay")
            )
            entities.___lonnLayers.layerDisplayAdded = true
        end

        hotkeyRedraw()
    end,
    layerDisplayAdded = false,
}

return {}