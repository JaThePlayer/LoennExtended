--[[
    Adds the following:
    - Mapper-specified color coding for triggers
    - Support for changing via global settings
      * text font size
      * node line size
      * showing extended text, defined by trigger plugins
      * always showing nodes
]]
local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() or not extSettings.get("_enabled", true, "triggers") then
    return {}
end

local layersApi = require("mods").requireFromPlugin("libraries.api.layers")
local textRendering = require("mods").requireFromPlugin("libraries.api.textRendering")
local triggerRendering = require("mods").requireFromPlugin("libraries.api.triggerRendering")

local triggers = require("triggers")
local colors = require("consts.colors")
local utils = require("utils")
local drawableFunction = require("structs.drawable_function")

-- Settings
local backgroundAlpha = extSettings.get("backgroundAlpha", 0.5, "triggers")
local extendedText = extSettings.get("extendedText", true, "triggers")
local function alwaysShowNodes() return extSettings.get("alwaysShowNodes", true, "triggers") end

local function multColor(color, alpha)
    local newColor = {}
    newColor[1] = color[1] * alpha
    newColor[2] = color[2] * alpha
    newColor[3] = color[3] * alpha
    newColor[4] = (color[4] or 1) * alpha

    return newColor
end

-- Make default backgrounds use alpha from backgroundAlpha
colors.triggerColor = multColor({47 / 255, 114 / 255, 100 / 255, 1}, backgroundAlpha)

-- Change trigger font size
triggers.triggerFontSize = triggerRendering.getFontSize()

if triggers.lonnExt_colorCodeTriggers then
    triggers.lonnExt_colorCodeTriggers.unload()
end

local function multColor(color, alpha)
    local newColor = {}
    newColor[1] = color[1] * alpha
    newColor[2] = color[2] * alpha
    newColor[3] = color[3] * alpha
    newColor[4] = (color[4] or 1) * alpha

    return newColor
end

-- Implement _editorColor
local _orig_triggers_triggerColor = triggers.triggerColor
function triggers.triggerColor(room, trigger, ...)
    local backgroundColor, borderColor, triggerTextColor = _orig_triggers_triggerColor(room, trigger, ...)

    -- 265B50 used to be the default value for _editorColor, allow categories to take over
    if trigger._editorColor and trigger._editorColor ~= "" and trigger._editorColor ~= "265B50" then
        borderColor = utils.getColor(trigger._editorColor) or colors.triggerBorderColor
        backgroundColor = multColor(borderColor, backgroundAlpha)
    end

    -- Handle editor layers
    if not layersApi.isInCurrentLayer(trigger) then
        backgroundColor = multColor(backgroundColor, layersApi.hiddenLayerAlpha)
        borderColor = multColor(borderColor, layersApi.hiddenLayerAlpha)
        triggerTextColor = multColor(triggerTextColor, layersApi.hiddenLayerAlpha)
    end

    return backgroundColor, borderColor, triggerTextColor
end

-- Implement _lonnExt_extendedText
local _orig_triggers_triggerText = triggers.triggerText
function triggers.triggerText(room, trigger)
    local text = _orig_triggers_triggerText(room, trigger)

    if extendedText then
        local handler = triggers.registeredTriggers[trigger._name]
        if handler and handler._lonnExt_extendedText then
            local txt = utils.callIfFunction(handler._lonnExt_extendedText, trigger)
            if txt and txt ~= "" then
                text = string.format("%s\n(%s)", text, txt)
            end
        end
    end

    return text
end

-- Implement the alwaysShowNodes setting
--[[
    local _orig_triggers_nodeVisibility = triggers.nodeVisibility
    function triggers.nodeVisibility(layer, trigger, ...)
        if alwaysShowNodes() then
            return "always"
        end
    
        return _orig_triggers_nodeVisibility(layer, trigger, ...)
    end
]]

-- unfortunately, triggers.nodeVisibility doesn't work yet...
-- Time for some hacks :(
local _orig_triggers_getDrawable = triggers.getDrawable
function triggers.getDrawable(name, handler, room, trigger, viewport)
    local drawables, depth = _orig_triggers_getDrawable(name, handler, room, trigger, viewport)

    if alwaysShowNodes() then
        local layer = "" -- ??
        local _, color = triggers.triggerColor(room, trigger)
        table.insert(drawables, drawableFunction.fromFunction(triggers.drawSelected, room, layer, trigger, color))
    end

    return drawables, depth
end

triggers.lonnExt_colorCodeTriggers = {
    unload = function ()
        triggers.triggerColor = _orig_triggers_triggerColor
        triggers.triggerText = _orig_triggers_triggerText
        --triggers.nodeVisibility = _orig_triggers_nodeVisibility
        triggers.getDrawable = _orig_triggers_getDrawable
    end
}

return {}