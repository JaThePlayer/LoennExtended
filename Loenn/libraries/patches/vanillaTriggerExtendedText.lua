local triggers = require("triggers")
local utils = require("utils")

local function applyPatches()
    local flagTrigger = triggers.registeredTriggers["everest/flagTrigger"]
    flagTrigger._lonnExt_extendedText = function (trigger)
        if trigger.state then
            return trigger.flag
        else
            return "!" .. trigger.flag
        end
    end

    triggers.registeredTriggers["everest/coreModeTrigger"]._lonnExt_extendedText = function (trigger)
        return trigger.mode
    end

    triggers.registeredTriggers["noRefillTrigger"]._lonnExt_extendedText = function (trigger)
        return trigger.state and "On" or "Off"
    end

    triggers.registeredTriggers["cameraOffsetTrigger"]._lonnExt_extendedText = function (trigger)
        return string.format("%s, %s", utils.prettifyFloat(trigger.cameraX), utils.prettifyFloat(trigger.cameraY))
    end

    triggers.registeredTriggers["cameraTargetTrigger"]._lonnExt_extendedText = function (trigger)
        if trigger.xOnly and trigger.yOnly then
            return "xy"
        end

        if trigger.xOnly then
            return "x"
        end

        if trigger.yOnly then
            return "y"
        end
    end

    triggers.registeredTriggers["cameraAdvanceTargetTrigger"]._lonnExt_extendedText = function (trigger)
        if trigger.xOnly and trigger.yOnly then
            return "xy"
        end

        if trigger.xOnly then
            return "x"
        end

        if trigger.yOnly then
            return "y"
        end
    end

    triggers.registeredTriggers["windTrigger"]._lonnExt_extendedText = function (trigger)
        return trigger.pattern
    end
end

local orig_triggers_loadExternalTriggers = triggers.loadExternalTriggers
function triggers.loadExternalTriggers(registerAt)
    local ret = orig_triggers_loadExternalTriggers(registerAt)
    applyPatches()
    return ret
end

