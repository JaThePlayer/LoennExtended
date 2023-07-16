--[[
    Adds the following:
    - Color coding for triggers
    - Support for changing
      * text font size
      * node line size
      * trimming mod name
      * showing extended text, defined by trigger plugins
      * always showing nodes

    NOTE: This file is *extremely* hacky, and completely rewrites some methods.
]]
local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() or not extSettings.get("_enabled", true, "triggers") then
    return {}
end

local layers = require("mods").requireFromPlugin("libraries.api.layers")
local textRendering = require("mods").requireFromPlugin("libraries.api.textRendering")
local triggerRendering = require("mods").requireFromPlugin("libraries.api.triggerRendering")

local triggers = require("triggers")
local colors = require("consts.colors")
local utils = require("utils")
local drawing = require("utils.drawing")
local drawableFunction = require("structs.drawable_function")
local placementUtils = require("placement_utils")

-- Settings
local backgroundAlpha = extSettings.get("backgroundAlpha", 0.5, "triggers")

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

if triggers.lonnExt_colorCodeTriggers then
    triggers.lonnExt_colorCodeTriggers.unload()
end

-- edit colors
local _orig_getDrawable = triggers.getDrawable
function triggers.getDrawable(name, handler, room, trigger, viewport)
    local bg = triggerRendering.getTriggerDrawableBg(trigger)

    local displayName = triggerRendering.getDisplayText(trigger)

    local bgFunc = bg.func
    bg.func = function ()
        bgFunc()

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16
        textRendering.printCenteredText(displayName, x, y, width, height, font, triggerRendering.getFontSize())
    end

    return bg, 0
end

-- edit colors
local _orig_addDrawables = triggers.addDrawables
function triggers.addDrawables(batch, room, targets, viewport, yieldRate)
    local font = love.graphics.getFont()

    -- Add rectangles first, then batch draw all text

    for i, trigger in ipairs(targets) do
        batch:addFromDrawable(triggerRendering.getTriggerDrawableBg(trigger))

        if i % yieldRate == 0 then
            coroutine.yield(batch)
        end
    end

    local textBatch = love.graphics.newText(font)

    for i, trigger in ipairs(targets) do
        local displayName = triggerRendering.getDisplayText(trigger)

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        local color = colors.triggerTextColor
        -- add integration for layers
        if not layers.isInCurrentLayer(trigger) then
            color = multColor(color, layers.hiddenLayerAlpha)
        end
        textRendering.addCenteredText(textBatch, displayName, x, y, width, height, font, triggerRendering.getFontSize(), nil, color)
    end

    local function func()
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(colors.triggerTextColor)
            love.graphics.draw(textBatch)
        end)
    end

    batch:addFromDrawable(drawableFunction.fromFunction(func))

    return batch
end

-- set color on placement
local _orig_finalizePlacement = placementUtils.finalizePlacement
placementUtils.finalizePlacement = function(room, layer, item)
    _orig_finalizePlacement(room, layer, item)

    if layer == "triggers" and not item._editorColor then
        item._editorColor = "265B50"
    end
end

triggers.lonnExt_colorCodeTriggers = {
    unload = function ()
        placementUtils.finalizePlacement = _orig_finalizePlacement
        triggers.addDrawables = _orig_addDrawables
        triggers.getDrawable = _orig_getDrawable
    end
}

return {}