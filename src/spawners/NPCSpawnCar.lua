NPCSpawnCar = {}


local NPCSpawnCar_mt = Class(NPCSpawnCar, NPCSpawn)


function NPCSpawnCar.registerXMLPaths(schema, basePath) end


function NPCSpawnCar.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#isFacingFront", "NPC spawn car is facing front")
    schema:register(XMLValueType.VECTOR_3, basePath .. "#colour", "NPC spawn car colour")
    schema:register(XMLValueType.INT, basePath .. "#vehicleId", "NPC spawn car vehicle id")
end


function NPCSpawnCar.new()

    local self = NPCSpawn.new(NPCSpawnCar_mt)

    return self

end


function NPCSpawnCar:delete(placeable)

    NPCSpawnCar:superClass().delete(self, placeable)

    local x1, z1, x2, z2 = self:getArea()
    placeable:setAreaBlocked(x1, z1, x2, z2, self.y, false)

    if self.vehicleNode ~= nil then
        removeFromPhysics(self.vehicleNode)
        delete(self.vehicleNode)
    end

end


function NPCSpawnCar.loadDataFromXMLFile(xmlFile, key, spawn)

    spawn.vehicles = {}

    xmlFile:iterate(key .. ".vehicles.vehicle", function(_, vehicleKey)

        local filename = xmlFile:getValue(vehicleKey .. "#filename")
        local minDepth = xmlFile:getValue(vehicleKey .. "#minDepth")
        local maxDepth = xmlFile:getValue(vehicleKey .. "#maxDepth")
        local driverOffset = xmlFile:getValue(vehicleKey .. "#driverOffset", 0)

        NPCSpawnCar.preloadCar(spawn.vehicles, filename, minDepth, maxDepth, driverOffset)
            
    end)

end


function NPCSpawnCar.preloadCar(vehicles, xmlFilename, minDepth, maxDepth, driverOffset, factor)

    local xmlFile = XMLFile.load("vehicle", xmlFilename)

    local i3dFilename = Utils.getFilename(xmlFile:getString("vehicle.assets#filename"))
    local rootNode = getChildAt(g_i3DManager:loadI3DFile(i3dFilename, false, false), 0)
    local vehicle = {}

    vehicle.width = xmlFile:getFloat("vehicle.assets.collisionGeometry#width") * 1.15
    vehicle.colourNodePath = xmlFile:getString("vehicle.assets.colors.colorNodes.colorNode(0)#node")
    vehicle.driverNodePath = xmlFile:getString("vehicle.assets#driverNode")
    vehicle.collisionNodePath = xmlFile:getString("vehicle.assets.collisionGeometry#node")
    vehicle.colours = {}

    local driverNode = I3DUtil.indexToObject(rootNode, vehicle.driverNodePath)
    local lightsNode = I3DUtil.indexToObject(rootNode, xmlFile:getString("vehicle.assets.lights.light#node"))
    local leftIndicatorNode = I3DUtil.indexToObject(rootNode, xmlFile:getString("vehicle.assets.lights.turnLeft#decoration"))
    local rightIndicatorNode = I3DUtil.indexToObject(rootNode, xmlFile:getString("vehicle.assets.lights.turnRight#decoration"))

    xmlFile:iterate("vehicle.assets.colors.availableColors.color", function(_, key)
        local r, g, b = table.unpack(xmlFile:getVector(key .. "#rgb"))
        table.insert(vehicle.colours, { r, g, b })
    end)

    xmlFile:delete()
    
    setVisibility(rootNode, false)
    setVisibility(lightsNode, false)
    setShaderParameter(leftIndicatorNode, "lightTypeBitMask", 0, nil, nil, nil, false)
    setShaderParameter(rightIndicatorNode, "lightTypeBitMask", 0, nil, nil, nil, false)

    local _, _, driverLZ = getTranslation(driverNode)
    setTranslation(driverNode, vehicle.width * 1.25 / 2, 0, driverLZ + driverOffset)

    vehicle.rootNode, vehicle.minDepth, vehicle.maxDepth = rootNode, minDepth, maxDepth
    table.insert(vehicles, vehicle)

end


function NPCSpawnCar:saveToXMLFile(xmlFile, key)

    NPCSpawnCar:superClass().saveToXMLFile(self, xmlFile, key)

    xmlFile:setValue(key .. "#isFacingFront", self.isFacingFront)
    xmlFile:setValue(key .. "#vehicleId", self.vehicleId)
    xmlFile:setValue(key .. "#colour", table.unpack(self.colour))

end


function NPCSpawnCar:loadFromXMLFile(xmlFile, key)

    NPCSpawnCar:superClass().loadFromXMLFile(self, xmlFile, key)

    self.isFacingFront = xmlFile:getValue(key .. "#isFacingFront")
    self.vehicleId = xmlFile:getValue(key .. "#vehicleId")
    self.colour = table.pack(xmlFile:getValue(key .. "#colour"))

end


function NPCSpawnCar:load(placeable)

    NPCSpawnCar:superClass().load(self, placeable)

    local group = placeable:getSpawnGroupByName(self:getGroupName())

    self.isFacingFront = self.isFacingFront == nil and math.random() >= 0.5 or self.isFacingFront or false
    self.vehicleId = self.vehicleId or math.random(#group.vehicles)

    self:loadCar(group.vehicles[self.vehicleId])
    local x1, z1, x2, z2 = self:getArea()
    placeable:setAreaBlocked(x1, z1, x2, z2, self.y, true)

end


function NPCSpawnCar:loadCar(vehicleData)

    local sx, sy, sz = self.x, self.y, self.z
    local ry = self.isFacingFront and self.ry or (math.pi - math.rad(math.deg(self.ry) + 180))

    local rootNode = clone(vehicleData.rootNode, false)
    local driverNode = I3DUtil.indexToObject(rootNode, vehicleData.driverNodePath)
    local colourNode = I3DUtil.indexToObject(rootNode, vehicleData.colourNodePath)
    local collisionNode1 = I3DUtil.indexToObject(rootNode, vehicleData.collisionNodePath)
    local collisionNode2 = clone(collisionNode1, true)

    self.colour = self.colour or vehicleData.colours[math.random(#vehicleData.colours)]

    for i = 0, 30 do
        if getMaterial(colourNode, i) == 0 or not getHasShaderParameter(colourNode, "colorScale", i) then continue end
        setShaderParameter(colourNode, "colorScale", self.colour[1], self.colour[2], self.colour[3], nil, false, i)
    end

    link(getRootNode(), rootNode)
    setWorldRotation(rootNode, 0, ry, 0)
    setWorldTranslation(rootNode, sx, sy, sz)

    setTranslation(collisionNode1, 0, 0, self.isFacingFront and vehicleData.maxDepth or vehicleData.minDepth)
    local fx, _, fz = getWorldTranslation(collisionNode1)    
    local dx, dz = math.abs(sx - fx), math.abs(sz - fz)
    local x, z = dx * (dx / (dx + dz)), dz * (dz / (dx + dz))
    setWorldTranslation(rootNode, sx + (fx > sx and -x or x), sy, sz + (fz > sz and -z or z))

    setTranslation(collisionNode1, vehicleData.width / 2, 0, vehicleData.maxDepth)
    local x1, _, z1 = getWorldTranslation(collisionNode1)
    setTranslation(collisionNode2, -vehicleData.width / 2, 0, vehicleData.minDepth)
    local x2, _, z2 = getWorldTranslation(collisionNode2)

    self.getArea = function()
        return x1 < x2 and x1 or x2, z1 < z2 and z1 or z2, x2 > x1 and x2 or x1, z2 > z1 and z2 or z1
    end

    setVisibility(rootNode, true)
    self.vehicleNode = rootNode

    local driverX, _, driverZ = getWorldTranslation(driverNode)
    delete(driverNode)

    self.getNPCSpawnPoint = function()
        return driverX, sy, driverZ
    end

end


PlaceableNPCManager.registerSpawnClass(NPCSpawnCar)