--[[
    Handles ordering extra attributes added to entities/triggers by Loenn Extended: _editorLayer, and _editorColor
]]
local utils = require("utils")
local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() then
    return {}
end

local formUtils = require("ui.utils.forms")

local editorColorFieldInfo = {
    fieldType = "color",
    allowXNAColors = true,
    displayName = "Editor Color",
    tooltipText = "The color to use when rendering this trigger in-editor.\nLeave empty to use lonn's defaults instead.\nAdded by Loenn Extended",
    allowEmpty = true,
}

local editorLayerFieldInfo = {
    fieldType = "integer",
    displayName = "Editor Layer",
    tooltipText = "The layer in which this entity is in-editor.\nAdded by Loenn Extended"
}

local paddingFieldInfo = {
    fieldType = "spacer",
}

if formUtils._lonnExt_extraAttrOrdering then
    formUtils._lonnExt_extraAttrOrdering.unload()
end

local _orig_formUtils_prepareFormData = formUtils.prepareFormData
function formUtils.prepareFormData(handler, data, options, handlerArguments, ...)
    local dummyData, fieldInformation, fieldOrder = _orig_formUtils_prepareFormData(handler, data, options, handlerArguments, ...)

    fieldOrder = fieldOrder or {}
    fieldInformation = fieldInformation or {}

    local insertIndex = 3
    if data.width then
        insertIndex += 1
    end
    if data.height then
        insertIndex += 1
    end

    local layer = handlerArguments and handlerArguments[1]

    local hasLayer = false
    if data._editorLayer or (layer == "triggers" or layer == "entities" or layer == "decalsFg" or layer == "decalsBg") then
        hasLayer = true
        table.insert(fieldOrder, insertIndex, "_editorLayer")
        insertIndex += 1
        fieldInformation._editorLayer = editorLayerFieldInfo
        if not dummyData._editorLayer then
            dummyData._editorLayer = 0
        end
    end

    if data._editorColor or layer == "triggers" then
        table.insert(fieldOrder, insertIndex, "_editorColor")
        insertIndex += 1
        fieldInformation._editorColor = editorColorFieldInfo
        if not dummyData._editorColor then
            dummyData._editorColor = ""
        end
    elseif hasLayer then
        -- Add padding to not mess up the layout
        table.insert(fieldOrder, insertIndex, "__lonnExt_pad")
        insertIndex += 1
        fieldInformation.__lonnExt_pad = paddingFieldInfo
        --dummyData.__lonnExt_pad = ""
    end

    return dummyData, fieldInformation, fieldOrder
end

formUtils._lonnExt_extraAttrOrdering = {
    unload = function ()
        formUtils.prepareFormData = _orig_formUtils_prepareFormData
    end
}

return {}