local script = {
    name = "trimEditorLayers",
    displayName = "Trim Editor Layers",
    tooltip = "Removes all editor layers from the room.",
}

local function trim(from)
    for _, obj in ipairs(from) do
        obj._editorLayer = nil
        --obj._editorLayer = obj.editorLayer
        --obj.editorLayer = nil
    end
end

function script.run(room, args)
    trim(room.entities)
    trim(room.triggers)
    trim(room.decalsFg)
    trim(room.decalsBg)
end

return script