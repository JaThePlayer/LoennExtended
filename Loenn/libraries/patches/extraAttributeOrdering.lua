--[[
    Handles ordering extra attributes added to entities/triggers by Loenn Extended: _editorLayer, and _editorColor
]]

local extSettings = require("mods").requireFromPlugin("libraries.settings")
if not extSettings.enabled() then
    return {}
end

local formUtils = require("ui.utils.forms")

local editorColorFieldInfo = {
    fieldType = "color",
    allowXNAColors = true,
    displayName = "Editor Color",
    tooltipText = "The color to use when rendering this trigger in-editor.\nAdded by Loenn Extended"
}

local editorLayerFieldInfo = {
    fieldType = "integer",
    displayName = "Editor Layer",
    tooltipText = "The layer in which this entity is in-editor.\nAdded by Loenn Extended"
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
    if data.width and data.height then
        insertIndex = 5
    end

    if data._editorLayer then
        table.insert(fieldOrder, insertIndex, "_editorLayer")
        fieldInformation._editorLayer = editorLayerFieldInfo
    end

    if data._editorColor then
        table.insert(fieldOrder, insertIndex, "_editorColor")
        fieldInformation._editorColor = editorColorFieldInfo
    end

    return dummyData, fieldInformation, fieldOrder
end

formUtils._lonnExt_extraAttrOrdering = {
    unload = function ()
        formUtils.prepareFormData = _orig_formUtils_prepareFormData
    end
}

return {}