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
end

local orig_triggers_loadExternalTriggers = triggers.loadExternalTriggers
function triggers.loadExternalTriggers(registerAt)
    local ret = orig_triggers_loadExternalTriggers(registerAt)
    applyPatches()
    return ret
end

