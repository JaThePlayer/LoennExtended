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
local trimModName = extSettings.get("trimModName", true, "triggers")
local extendedText = extSettings.get("extendedText", true, "triggers")
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

---Gets the border color of a given trigger, taking into account the Editor Color property.
---@param trigger table
---@return table
function triggerRendering.getBorderColor(trigger)
    if trigger._editorColor then
        return utils.getColor(trigger._editorColor)
    end
    return colors.triggerBorderColor
end

---Gets the background color of a given trigger, taking into account the Editor Color property.
---@param trigger table
---@return table
function triggerRendering.getBackgroundColor(trigger)
    if trigger._editorColor then
        return multColor(triggerRendering.getBorderColor(trigger), backgroundAlpha)
    end
    return colors.triggerColor
end

---Returns the size of the font that should be used for trigger rendering
---@return number
function triggerRendering.getFontSize()
    return triggerFontSize
end

---Gets the drawable needed to render the background of a trigger, taking into account all Lonn Extended settings.
---@param trigger table
---@return table
function triggerRendering.getTriggerDrawableBg(trigger)
    local x = trigger.x or 0
    local y = trigger.y or 0

    local width = trigger.width or 16
    local height = trigger.height or 16

    local borderColor = triggerRendering.getBorderColor(trigger)
    local backgroundColor = triggerRendering.getBackgroundColor(trigger)

    -- add integration for layers
    if not layers.isInCurrentLayer(trigger) then
        borderColor = multColor(borderColor, layers.hiddenLayerAlpha)
        backgroundColor = multColor(backgroundColor, layers.hiddenLayerAlpha)
    end

    local nodeDrawable
    if alwaysShowNodes then
        nodeDrawable = drawableFunction.fromFunction(function ()
            local origWidth = love.graphics.getLineWidth()
            local origColor = colors.triggerColor
            love.graphics.setLineWidth(origWidth * lineSizeMult)
            colors.triggerColor = backgroundColor

            drawing.callKeepOriginalColor(function()
                triggers.drawSelected(room, "triggers", trigger, borderColor)

                love.graphics.setColor(backgroundColor)
                love.graphics.rectangle("fill", x, y, width, height)

                love.graphics.setColor(borderColor)
                love.graphics.rectangle("line", x, y, width, height)

                colors.triggerColor = origColor
                love.graphics.setLineWidth(origWidth)
            end)

        end)
    else
        nodeDrawable = drawableFunction.fromFunction(function ()
            local origWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(origWidth * lineSizeMult)

            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(backgroundColor)
                love.graphics.rectangle("fill", x, y, width, height)
                love.graphics.rectangle("line", x, y, width, height)
            end)


            love.graphics.setLineWidth(origWidth)
        end)
    end

    return nodeDrawable
end

local humanizedNameCache = {}
---Gets the text that needs to be rendered for this trigger, taking into account all Lonn Extended settings
---@param trigger table
---@return string
function triggerRendering.getDisplayText(trigger)
    local name = trigger._name
    local displayName = humanizedNameCache[name]

    if not displayName then
        -- NEW: trim mod name
        if trimModName and string.find(name, "/") then
            name = name:split("/")()[2]
        end
        -- Humanize data name and then remove " Trigger" at the end if possible
        displayName = utils.humanizeVariableName(name)
        displayName = string.match(displayName, "(.-) Trigger$") or displayName

        if extendedText then
            local handler = triggers.registeredTriggers[trigger._name]
            if handler and handler._lonnExt_extendedText then
                displayName = string.format("%s\n(%s)", displayName, utils.callIfFunction(handler._lonnExt_extendedText, trigger))
            end
        end

        humanizedNameCache[name] = displayName
    end

    return displayName
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