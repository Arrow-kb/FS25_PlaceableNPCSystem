NPCSpawn = {}


local NPCSpawn_mt = Class(NPCSpawn)


function NPCSpawn.registerXMLPaths(schema, basePath) end


function NPCSpawn.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_3, basePath .. "#position", "NPC spawn world translation")
    schema:register(XMLValueType.FLOAT, basePath .. "#rotation", "NPC spawn world y rotation")
    schema:register(XMLValueType.STRING, basePath .. "#class", "NPC spawn class name")
    schema:register(XMLValueType.STRING, basePath .. "#group", "NPC spawn group name")
    schema:register(XMLValueType.STRING, basePath .. "#node", "NPC spawn node name")
end


function NPCSpawn.new(customMt)

    local self = setmetatable({}, customMt or NPCSpawn_mt)

    self.x, self.y, self.z, self.ry = 0, 0, 0, 0

    return self

end


function NPCSpawn:delete(placeable)
    placeable:setTargetOccupied(self.node, false)
end


function NPCSpawn:saveToXMLFile(xmlFile, key)

    xmlFile:setValue(key .. "#position", self.x, self.y, self.z)
    xmlFile:setValue(key .. "#rotation", self.ry)
    xmlFile:setValue(key .. "#class", ClassUtil.getClassNameByObject(self))
    xmlFile:setValue(key .. "#group", self.groupName)
    xmlFile:setValue(key .. "#node", self.node)

end


function NPCSpawn:loadFromXMLFile(xmlFile, key)

    self.x, self.y, self.z = xmlFile:getValue(key .. "#position")
    self.ry = xmlFile:getValue(key .. "#rotation")
    self.groupName = xmlFile:getValue(key .. "#group")
    self.node = xmlFile:getValue(key .. "#node")

end


function NPCSpawn:setSpawnNode(name)
    self.node = name
end


function NPCSpawn:setPosition(x, y, z)
    self.x, self.y, self.z = x, y, z
end


function NPCSpawn:setRotation(ry)
    self.ry = ry
end


function NPCSpawn:setGroupName(groupName)
    self.groupName = groupName
end


function NPCSpawn:getGroupName()
    return self.groupName
end


function NPCSpawn:load(placeable, group)
    placeable:setTargetOccupied(self.node, true)
end


function NPCSpawn:getNPCSpawnPoint()
    return self.x, self.y, self.z
end


PlaceableNPCManager.registerSpawnClass(NPCSpawn)