local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local github = require("utils.github")
local configs = require("configs")
local meta = require("meta")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "quick_action_info_window"

local quickActionWindow = {}

local quickActionWindowGroup = uiElements.group({})


local noPaddingSpacing = {
    style = {
        spacing = 8,
        padding = 8
    }
}

local extSettings = require("mods").requireFromPlugin("libraries.settings")

local function saveChangesCallback(formFields)
    form.formDataSaved(formFields)
end

function quickActionWindow.showquickActionWindow()
    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.quickActionInfoWindow.title)

    local formButtons = {
        {
            text = tostring(language.ui.selection_context_window.save_changes),
            formMustBeValid = true,
            callback = saveChangesCallback,
        }
    }

    local formData = {}
    local fieldInformation = {}
    local fieldOrder = {}

    local actions = extSettings.getPersistence("quickActions", {})
    for hotkey, value in pairs(actions) do
        table.insert(fieldOrder, hotkey)

        fieldInformation[hotkey] = {
            fieldType = "keyboard_hotkey"
        }

        formData[hotkey] = hotkey
    end


    local tabForm, tabFields = form.getForm(formButtons, formData, {
        fields = fieldInformation,
        --groups = fieldGroups,
        fieldOrder = fieldOrder,
        --ignoreUnordered = true,
    })

    --local window = uiElements.window(windowTitle, windowContent)
    local window = uiElements.window(windowTitle, tabForm)
    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)

    windowPersister.trackWindow(windowPersisterName, window)

    require("ui.windows").windows["quickActionPlacementAdd"].parent:addChild(window)

    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    widgetUtils.preventOutOfBoundsMovement(window)
    form.prepareScrollableWindow(window)
    form.addTitleChangeHandler(window, windowTitle, tabFields)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function quickActionWindow.getWindow()
    return quickActionWindowGroup
end

return quickActionWindow