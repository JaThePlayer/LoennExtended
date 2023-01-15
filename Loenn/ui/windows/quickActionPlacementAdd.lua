local uiElements = require("ui.elements")
local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")

local myWindow = {}

local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

local contextGroup

local function contextWindowUpdate(orig, self, dt)
    orig(self, dt)

    windowPreviousX = self.x
    windowPreviousY = self.y
end

local function removeWindow(window)
    for i, w in ipairs(activeWindows) do
        if w == window then
            table.remove(activeWindows, i)
            widgetUtils.focusMainEditor()

            break
        end
    end

    window:removeSelf()
end

function myWindow.createContextMenu(index, callbackOnClose)
    local window
    local windowX = windowPreviousX
    local windowY = windowPreviousY
    local language = languageRegistry.getLanguage()

    -- Don't stack windows on top of each other
    if #activeWindows > 0 then
        windowX, windowY = 0, 0
    end

    local windowTitle = "Creating Quick Action: " .. tostring(index)

    local buttons = {
        uiElements.button("From Current Settings", function()
            callbackOnClose(false)
            removeWindow(window)
        end),
        uiElements.button("From Clipboard", function()
            callbackOnClose(true)
            removeWindow(window)
        end),
    }

    local selectionForm = uiElements.column({
        uiElements.label("From where should the settings for this Quick Action be taken?\nIf you want make an action for an entity with non-default settings,\nyou'll need to copy the entity via the selection tool and Ctrl+C, then click the \"From Clipboard\" button.\nIf you just need default settings, you can use \"From Current Settings\""),
        uiElements.row(buttons)
    })

    window = uiElements.window(windowTitle, selectionForm):with({
        x = windowX,
        y = windowY,
        minWidth = 300,

        updateHidden = true
    }):hook({
        update = contextWindowUpdate
    })

    table.insert(activeWindows, window)

    require("ui.windows").windows["quickActionPlacementAdd"].parent:addChild(window)

    --form.prepareScrollableWindow(window)
    widgetUtils.addWindowCloseButton(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function myWindow.getWindow()
    contextGroup = uiElements.group({})
    return contextGroup
end

return myWindow