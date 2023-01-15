local script = {
    name = "trimTriggerColors",
    displayName = "Trim Trigger Colors",
    tooltip = "Removes all trigger colors from the room.",
}

function script.run(room, args)
    for _, trigger in ipairs(room.triggers) do
        trigger._editorColor = nil
    end
end

return script