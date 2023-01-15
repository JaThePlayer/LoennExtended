local utils = require("utils")
local layers = require("mods").requireFromPlugin("libraries.api.layers")

local layerDisplay = {_enabled = true, _type = "device"}

function layerDisplay.draw()
    love.graphics.push()

    local text = layers.isEveryLayerVisible() and "Layer: all" or string.format("Layer: %s", layers.getCurrentLayer())
    --fixed_printCenteredText(text, 140, 15, 260, 100, nil, 3)

    love.graphics.scale(3, 3)

    love.graphics.printf(text, 90, 10, 360, "left")

    love.graphics.pop()
end

return layerDisplay