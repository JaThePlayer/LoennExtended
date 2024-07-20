local triggers = require("triggers")
local colors = require("consts.colors")
local utils = require("utils")
local drawing = require("utils.drawing")
local drawableFunction = require("structs.drawable_function")

local extSettings = require("mods").requireFromPlugin("libraries.settings")
local layers = require("mods").requireFromPlugin("libraries.api.layers")

local triggerRendering = {}

-- Settings
local backgroundAlpha = extSettings.get("backgroundAlpha", 0.5, "triggers")
local triggerFontSize = extSettings.get("textSize", 1, "triggers")
local lineSizeMult = extSettings.get("lineSize", 1, "triggers")
local alwaysShowNodes = extSettings.get("alwaysShowNodes", true, "triggers")

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

--- DEPRECATED, CALL triggers.triggerColor INSTEAD!
--- Gets the border color of a given trigger, taking into account the Editor Color property.
---@param trigger table
---@return table
function triggerRendering.getBorderColor(trigger)
    local backgroundColor, borderColor = triggers.triggerColor(nil, trigger)

    return borderColor
end

--- DEPRECATED, CALL triggers.triggerColor INSTEAD!
---Gets the background color of a given trigger, taking into account the Editor Color property.
---@param trigger table
---@return table
function triggerRendering.getBackgroundColor(trigger)
    local backgroundColor, borderColor = triggers.triggerColor(nil, trigger)

    return backgroundColor
end

---Returns the size of the font that should be used for trigger rendering
---@return number
function triggerRendering.getFontSize()
    return triggerFontSize
end

--- DEPRECATED: NEVER CALL
--- Only exists temporarily until viv helper gets fixed
function triggerRendering.getTriggerDrawableBg(trigger)
    local x = trigger.x or 0
    local y = trigger.y or 0

    local width = trigger.width or 16
    local height = trigger.height or 16

    local borderColor = triggerRendering.getBorderColor(trigger)
    local backgroundColor = triggerRendering.getBackgroundColor(trigger)

    local origColor = colors.triggerColor
    colors.triggerColor = backgroundColor

    drawing.callKeepOriginalColor(function()
        if alwaysShowNodes then
            triggers.drawSelected(room, "triggers", trigger, borderColor)
        end
        local origWidth = love.graphics.getLineWidth()

        love.graphics.setColor(backgroundColor)
        love.graphics.rectangle("fill", x + (origWidth / 2), y + (origWidth / 2), width - origWidth, height - origWidth)
        love.graphics.setColor(borderColor)
        love.graphics.rectangle("line", x, y, width, height)
    end)
    colors.triggerColor = origColor
end

local humanizedNameCache = {}

-- DEPRECATED, call triggers.triggerText instead!
---Gets the text that needs to be rendered for this trigger, taking into account all Lonn Extended settings
---@param trigger table
---@return string
function triggerRendering.getDisplayText(trigger)
    return triggers.triggerText(nil, trigger)
end

---Adds extended text support for the given trigger. Returns the handler itself. Will redirect to the officially supported version once that's implemented.
---@param triggerHandler table The trigger handler table. (a.k.a the one you return from trigger plugins)
---@param getter function function(trigger) -> string, which returns a string that represents the text to be rendered.
---@return table triggerHandler
function triggerRendering.addExtendedText(triggerHandler, getter)
    triggerHandler._lonnExt_extendedText = getter

    return triggerHandler
end

return triggerRendering