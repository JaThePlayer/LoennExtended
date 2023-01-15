local utils = require("utils")

local textRender = {}

local function getCenteredTextPos(text, font, fontSize, width, height)
    local fontHeight = font:getHeight()
    local fontLineHeight = font:getLineHeight()
    local longest, lines = font:getWrap(text, width / fontSize)
    local textHeight = ((#lines - 1) * (fontHeight * fontLineHeight) + fontHeight) * fontSize

    local offsetX = 1 * fontSize
    local offsetY = math.floor((height - textHeight) / 2) + 1 * fontSize
    local wrapLimit = math.floor(width / fontSize)

    return offsetX, offsetY, wrapLimit
end

---Adds text to the given batch, centered on the provided rectangle, optionally colored
---@param batch any
---@param text string
---@param x number
---@param y number
---@param width number
---@param height number
---@param font any|nil
---@param fontSize number|nil
---@param trim boolean|nil Whether to trim the text before rendering
---@param color table|string|nil
function textRender.addCenteredText(batch, text, x, y, width, height, font, fontSize, trim, color)
    if not batch then
        error("Tried to render to a null batch")
    end

    font = font or love.graphics.getFont()
    fontSize = fontSize or 1

    if trim ~= false then
        text = utils.trim(text)
    end

    local offsetX, offsetY, wrapLimit = getCenteredTextPos(text, font, fontSize, width, height)

    batch:addf(color and {utils.getColor(color), text} or text, wrapLimit, "center", x + offsetX, y + offsetY, 0, fontSize, fontSize)
end

---Renders the given text, centered in the given rectangle. This is a fixed version of drawing.printCenteredText, and it will call that method once its fixed.
---To render with color, use love.graphics.setColor
---@param text string
---@param x number
---@param y number
---@param width number
---@param height number
---@param font any|nil
---@param fontSize number|nil
---@param trim boolean|nil Whether to trim the text before rendering
function textRender.printCenteredText(text, x, y, width, height, font, fontSize, trim)
    font = font or love.graphics.getFont()
    fontSize = fontSize or 1

    if trim ~= false then
        text = utils.trim(text)
    end

    local offsetX, offsetY, wrapLimit = getCenteredTextPos(text, font, fontSize, width, height)

    love.graphics.push()

    love.graphics.translate(x + offsetX, y + offsetY)
    love.graphics.scale(fontSize, fontSize)

    love.graphics.printf(text, 0, 0, wrapLimit, "center")

    love.graphics.pop()
end

return textRender