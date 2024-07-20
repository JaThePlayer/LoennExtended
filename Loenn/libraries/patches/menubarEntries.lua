local menubar = require("ui.menubar")
local mods = require("mods")
local quickActionWindow = mods.requireFromPlugin("ui.windows.quickActionInfoWindow")
local entities = require("entities")
local celesteRender = require("celeste_render")
local loadedState = require("loaded_state")

local function quickActionsButton()
    quickActionWindow.showquickActionWindow()
end

local function allLayer()
    entities.___lonnLayers.nextLayer(nil)
end

local function prevLayer()
    entities.___lonnLayers.nextLayer(-1)
end

local function nextLayer()
    entities.___lonnLayers.nextLayer(1)
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
        { "le_all_layer", allLayer },
        { "le_next_layer", nextLayer },
        { "le_prev_layer", prevLayer },
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