--[[
DEPRECATED, DON'T USE
]]
local layersApi = {}

local printedDeprecations = {}

local function printDeprecationWarning(funcName)
    if printedDeprecations[funcName] then
        return
    end

    printedDeprecations[funcName] = true

    local trace = debug.traceback()

    print(string.format("WARNING: LonnExtended.libraries.api.layers is deprecated! There was a call to '%s' at %s", funcName, trace))
end

---Gets the currently active layer
---@return number
function layersApi.getCurrentLayer()
    printDeprecationWarning("getCurrentLayer")
    return 0
end

---Returns whether all layers are currently visible
---@return boolean
function layersApi.isEveryLayerVisible()
    printDeprecationWarning("isEveryLayerVisible")
    return true
end

---Checks whether this item is in the currently active layer, by checking the input table's _editorLayer value.
---@param item table
---@return boolean
function layersApi.isInCurrentLayer(item)
    printDeprecationWarning("isInCurrentLayer")
    return true
end

---Gets the layer of the given table, or nil if the layer is not specified.
---@param item table
---@return number|nil
function layersApi.getLayer(item)
    printDeprecationWarning("getLayer")
    return 0
end

---Sets the layer of the given table to the value of the 2nd argument, or the current layer if the 2nd argument is not provided
---@param item table
---@param layer number|nil
function layersApi.setLayer(item, layer)
    printDeprecationWarning("setLayer")
end

---Alpha value that's used for tinting sprites from hidden layers
layersApi.hiddenLayerAlpha = 1

return layersApi