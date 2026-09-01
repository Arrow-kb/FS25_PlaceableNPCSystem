NPCSpawn = {}


local NPCSpawn_mt = Class(NPCSpawn)


PlaceableNPCManager.registerSpawnClass(NPCSpawn)


function NPCSpawn.registerXMLPaths(schema, basePath) end


function NPCSpawn.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_3, basePath .. "#position", "NPC spawn world translation")
    schema:register(XMLValueType.FLOAT, basePath .. "#rotation", "NPC spawn world y rotation")
    schema:register(XMLValueType.STRING, basePath .. "#class", "NPC spawn class name")
end


function NPCSpawn.new(customMt)

    local self = setmetatable({}, customMt or NPCSpawn_mt)

    self.x, self.y, self.z, self.ry = 0, 0, 0, 0

    return self

end


function NPCSpawn:saveToXMLFile(xmlFile, key)

    xmlFile:setValue(key .. "#position", table.pack(self.x, self.y, self.z))
    xmlFile:setValue(key .. "#rotation", self.ry)
    xmlFile:setValue(key .. "#class", ClassUtil.getClassNameByObject(self))

end


function NPCSpawn:loadFromXMLFile(xmlFile, key)

    self.x, self.y, self.z = table.unpack(xmlFile:getValue(key .. "#position"))
    self.ry = table.unpack(xmlFile:getValue(key .. "#rotation"))

end