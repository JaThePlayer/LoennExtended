local menubar = require("ui.menubar")
local mods = require("mods")
local celesteRender = require("celeste_render")
local loadedState = require("loaded_state")

local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() then
    return {}
end

local function alwaysShowNodes()
    local settings = mods.getModSettings()
    settings.triggers.alwaysShowNodes = not settings.triggers.alwaysShowNodes

    local room = loadedState.getSelectedRoom()
    celesteRender.invalidateRoomCache(room)
    celesteRender.forceRoomBatchRender(room, loadedState)
end

local newEntries = {
    edit = {
        --{"le_quick_actions", quickActionsButton},
    },
    view = {
        {},
        { "le_always_show_nodes", alwaysShowNodes, "checkbox" },
    },
}


for k,v in pairs(newEntries) do
    local entry = $(menubar.menubar):find(t -> t[1] == k)[2]

    for _, data in ipairs(v) do
        -- Remove existing entries with the same name
        for index, existingEntryData in ipairs(entry) do
            if data[1] == existingEntryData[1] then
                table.remove(entry, index)
                break
            end
        end

        table.insert(entry, data)
    end
end

return {}