local mods = require("mods")
local v = require("utils.version_parser")
local meta = require("meta")
local notifications = require("ui.notification")
local config = require("utils.config")
local utils = require("utils")

local extSettings = {}

function extSettings.getPersistence(settingName, default)
    local settings = mods.getModPersistence()
    if not settingName then
        return settings
    end

    local value = settings[settingName]
    if value == nil then
        value = default
        settings[settingName] = default
    end

    return value
end

function extSettings.savePersistence()
    config.writeConfig(extSettings.getPersistence(), true)
end

function extSettings.get(settingName, default, namespace)
    local settings = mods.getModSettings()
    if not settingName then
        return settings
    end

    local target = settings
    if namespace then
        local nm = settings[namespace]
        if not nm then
            settings[namespace] = {}
            nm = settings[namespace]
        end

        target = nm
    end

    local value = target[settingName]
    if value == nil then
        value = default
        target[settingName] = default
    end

    if namespace then
        settings[namespace] = utils.deepcopy(target) -- since configMt:__newindex uses ~= behind the scenes to determine whether to save or not, we need to copy the table to make it save
    end

    return value
end

local supportedLonnVersion = v("0.9")
local nextBrokenLonnVersion = v("1.0")
local currentLonnVersion = meta.version

function extSettings.enabled()
    local enabled = (currentLonnVersion >= supportedLonnVersion and currentLonnVersion < nextBrokenLonnVersion) or currentLonnVersion == v("0.0.0")
    -- crashes
    -- notifications.notify(string.format("Loenn Extended does not yet support the version %s, the supported version is %s", currentLonnVersion, supportedLonnVersion), 10)
    return enabled
end

local settings = mods.getModSettings()
if settings.triggers then
    settings.triggers.trimModName = nil
end

return extSettings