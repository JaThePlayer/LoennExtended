local utils = require("utils")

local layersApi = {}

local enabled = true
local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() or not extSettings.get("_enabled", true, "layers") then
    enabled = false
end

local entities = require("entities")

---Gets the currently active layer
---@return number
function layersApi.getCurrentLayer()
    return enabled and entities.___lonnLayers.layer or 0
end

---Returns whether all layers are currently visible
---@return boolean
function layersApi.isEveryLayerVisible()
    if enabled then
        return entities.___lonnLayers.any
    else
        return true
    end
end

---Checks whether this item is in the currently active layer, by checking the input table's _editorLayer value.
---@param item table
---@return boolean
function layersApi.isInCurrentLayer(item)
    if not enabled or item._id == 0 then
        return true
    end

    return layersApi.isEveryLayerVisible() or (item._editorLayer or 0) == layersApi.getCurrentLayer()
end

---Gets the layer of the given table, or nil if the layer is not specified.
---@param item table
---@return number|nil
function layersApi.getLayer(item)
    return item._editorLayer
end

---Sets the layer of the given table to the value of the 2nd argument, or the current layer if the 2nd argument is not provided
---@param item table
---@param layer number|nil
function layersApi.setLayer(item, layer)
    item._editorLayer = layer or layersApi.getCurrentLayer()
end

---Alpha value that's used for tinting sprites from hidden layers
layersApi.hiddenLayerAlpha = enabled and extSettings.get("hiddenLayerAlpha", 0.1, "layers") or 1

return layersApi