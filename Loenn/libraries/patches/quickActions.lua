--[[
    Adds support for Quick Actions - you can bind any tool action to the 0-9 keys for quick access.
    To create an action, press ctrl+<number key>
]]

local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() or not extSettings.get("_enabled", true, "quickActions") then
    return {}
end

local hotkeyHandler = require("hotkey_handler")
local toolHandler = require("tools")
local utils = require("utils")
local placementAddWindow = require("mods").requireFromPlugin("ui.windows.quickActionPlacementAdd")
local chooseHotkeyWindow = require("mods").requireFromPlugin("ui.windows.quickActionChooseHotkey")
local notifications = require("ui.notification")

local quickActionData = {}

local customHotkeyInfo = {}

local actions = extSettings.getPersistence("quickActions", {})
for key, value in pairs(actions) do
    if type(key) == "number" then
        actions[key] = nil
        actions[tostring(key)] = value
    end
end

function quickActionData.doAction(index)
    local action = actions[index]
    if action then
        toolHandler.selectTool(action.tool)
        toolHandler.setLayer(action.layer, action.tool)
        toolHandler.setMaterial(action.material, action.tool)
    end
end

local function getHotkeyHandler(index)
    return function()
        quickActionData.doAction(index)
    end
end

-- Attempt to prevent arbitrary code execution - from tools/selection.lua 
local function validateClipboard(text)
    if not text or text:sub(1, 1) ~= "{" or text:sub(-1, -1) ~= "}" then
        return false
    end

    return true
end

local function guessPlacementType(item)
    if item.width or item.height then
        return "rectangle"
    end

    return "point"
end

-- hotkey_handler.hotkeys
local targetHotkeyInfo = nil

local function addHotkey(key)
    hotkeyHandler.createAndRegisterHotkey(key, getHotkeyHandler(key), targetHotkeyInfo or customHotkeyInfo)
end

local function removeHotkey(index)
    -- remove the hotkey from the hotkey_handler
    targetHotkeyInfo[index] = nil

    local persistence = extSettings.getPersistence()
    persistence.quickActions = persistence.quickActions or {}
    if persistence.quickActions[index] then
        persistence.quickActions[index] = nil
        extSettings.savePersistence()
        notifications.notify(string.format("Removed Quick Action %s", index))
    else
        notifications.notify(string.format("Quick Action %s already doesn't exist!", index))
    end
end

local function finalizeAddingHotkeyStep2(index, action)
    -- Register the hotkey if it's not yet registered
    if not actions[index] then
        addHotkey(index)
    end

    actions[index] = action

    notifications.notify(string.format("Added Quick Action %s", index))

    local persistence = extSettings.getPersistence()
    persistence.quickActions = persistence.quickActions or {}
    persistence.quickActions[index] = action
    extSettings.savePersistence()
end

local function finalizeAddingHotkey(index, action)
    if index == 0 then -- Ctrl+0 now allows you to pick any arbitrary key for the quick action.
        chooseHotkeyWindow.createContextMenu(index, function(hotkey, shouldRemove)
            hotkey = string.gsub(hotkey, " ", "") -- remove spaces

            if shouldRemove then
                removeHotkey(hotkey)
                return
            end

            finalizeAddingHotkeyStep2(hotkey, action)
        end)
        return
    end

    finalizeAddingHotkeyStep2(index, action)
end

local function getHotkeyCreationHandler(index)
    return function ()
        local toolName = toolHandler.currentToolName
        local action = {
            tool = toolName,
            layer = toolHandler.getLayer(toolName),
            material = toolHandler.getMaterial(toolName),
        }

        if toolName == "placement" or toolName == "selection" then
            -- placement and selection tools require special handling because of selection info/placement templates being local :(
            placementAddWindow.createContextMenu(index, function(fromClipboard)
                if fromClipboard then
                    local clipboard = love.system.getClipboardText()

                    if validateClipboard(clipboard) then
                        local success, fromClipboard = utils.unserialize(clipboard, true, 3)

                        if success then
                            print(utils.serialize(fromClipboard))

                            local placement = fromClipboard[1]

                            action.tool = "placement"
                            action.layer = placement.layer
                            action.material = {
                                itemTemplate = placement.item,
                                displayName = "<quickActionItem>",
                                name = "<quickActionItem>",
                                placementType = guessPlacementType(placement.item)
                            }
                        end
                    end
                end

                finalizeAddingHotkey(index, action)
            end)
        else
            finalizeAddingHotkey(index, action)
        end
    end
end

-- Create hotkeys ctrl+(0..9) to register quick actions.
for i = 0, 9, 1 do
    hotkeyHandler.createAndRegisterHotkey(string.format("ctrl + %s", i), getHotkeyCreationHandler(i), customHotkeyInfo)
end

-- Add hotkeys for all actions
for key, _ in pairs(actions) do
    addHotkey(tostring(key))
end

-- lönn doesn't have proper mod hotkey support so time for horribleness
local orig = hotkeyHandler.createHotkeyDevice

function hotkeyHandler.createHotkeyDevice(hotkeys)
    for index, value in ipairs(customHotkeyInfo) do
        table.insert(hotkeys, value)
    end
    hotkeyHandler.createHotkeyDevice = orig

    -- store the hotkey table for later use
    targetHotkeyInfo = hotkeys
    return orig(hotkeys)
end

return {}