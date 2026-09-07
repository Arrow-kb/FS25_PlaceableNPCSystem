PlaceableNPCNavigation = {}


local specName = "spec_npcNavigation"


function PlaceableNPCNavigation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("npcNavigation")
	schema:register(XMLValueType.STRING, basePath .. ".npcNavigation#geometryFilename", "Navigation geometry filename")
	schema:register(XMLValueType.FLOAT, basePath .. ".npcNavigation#cellSize", "Navigation inner geometry cell size")
	schema:register(XMLValueType.STRING, basePath .. ".npcNavigation.targets.group(?)#key", "Target group key")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.targets.group(?).target(?)#node", "Target node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.targets.group(?).target(?)#linkNode", "Target linked node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.targets.target(?)#node", "Target node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.targets.target(?)#linkNode", "Target linked node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.paths.path(?)#startNode", "Preloaded path start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.paths.path(?)#endNode", "Preloaded path end node")
	schema:register(XMLValueType.STRING, basePath .. ".npcNavigation.rooms.room(?)#id", "Room ID")
	schema:register(XMLValueType.STRING, basePath .. ".npcNavigation.rooms.room(?).connection(?)#id", "Room connection ID")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".npcNavigation.rooms.room(?).connection(?)#node", "Room connection node")
	schema:setXMLSpecializationType()
end


function PlaceableNPCNavigation.registerEventListeners(placeable)
	SpecializationUtil.registerEventListener(placeable, "onFinalizePlacement", PlaceableNPCNavigation)
	SpecializationUtil.registerEventListener(placeable, "onUpdate", PlaceableNPCNavigation)
end


function PlaceableNPCNavigation.registerEvents(placeable)
    SpecializationUtil.registerEvent(placeable, "onNavigationMeshLoaded")
end


function PlaceableNPCNavigation.registerFunctions(placeable)
	SpecializationUtil.registerFunction(placeable, "branchToClosestPoint", PlaceableNPCNavigation.branchToClosestPoint)
	SpecializationUtil.registerFunction(placeable, "consoleCommandFindPath", PlaceableNPCNavigation.consoleCommandFindPath)
	SpecializationUtil.registerFunction(placeable, "createNavigationMesh", PlaceableNPCNavigation.createNavigationMesh)
	SpecializationUtil.registerFunction(placeable, "createPathTargets", PlaceableNPCNavigation.createPathTargets)
	SpecializationUtil.registerFunction(placeable, "fillMesh", PlaceableNPCNavigation.fillMesh)
	SpecializationUtil.registerFunction(placeable, "findPath", PlaceableNPCNavigation.findPath)
	SpecializationUtil.registerFunction(placeable, "finishLoadingNavigationMesh", PlaceableNPCNavigation.finishLoadingNavigationMesh)
	SpecializationUtil.registerFunction(placeable, "getClosestPoint", PlaceableNPCNavigation.getClosestPoint)
	SpecializationUtil.registerFunction(placeable, "getIsPointInsideMesh", PlaceableNPCNavigation.getIsPointInsideMesh)
	SpecializationUtil.registerFunction(placeable, "getIsPointInsidePolygon", PlaceableNPCNavigation.getIsPointInsidePolygon)
	SpecializationUtil.registerFunction(placeable, "getNPCSpawnPoint", PlaceableNPCNavigation.getNPCSpawnPoint)
	SpecializationUtil.registerFunction(placeable, "getPath", PlaceableNPCNavigation.getPath)
	SpecializationUtil.registerFunction(placeable, "getPathByType", PlaceableNPCNavigation.getPathByType)
	SpecializationUtil.registerFunction(placeable, "getRoomForPoint", PlaceableNPCNavigation.getRoomForPoint)
	SpecializationUtil.registerFunction(placeable, "getTargetLinkedNode", PlaceableNPCNavigation.getTargetLinkedNode)
	SpecializationUtil.registerFunction(placeable, "intIndexToPoint", PlaceableNPCNavigation.intIndexToPoint)
	SpecializationUtil.registerFunction(placeable, "setTargetOccupied", PlaceableNPCNavigation.setTargetOccupied)
	SpecializationUtil.registerFunction(placeable, "getTargetByName", PlaceableNPCNavigation.getTargetByName)
	SpecializationUtil.registerFunction(placeable, "getTargetNodeByName", PlaceableNPCNavigation.getTargetNodeByName)
	SpecializationUtil.registerFunction(placeable, "normalizeCoordinate", PlaceableNPCNavigation.normalizeCoordinate)
	SpecializationUtil.registerFunction(placeable, "pointToIntIndex", PlaceableNPCNavigation.pointToIntIndex)
	SpecializationUtil.registerFunction(placeable, "preloadPaths", PlaceableNPCNavigation.preloadPaths)
	SpecializationUtil.registerFunction(placeable, "removeQueueRequest", PlaceableNPCNavigation.removeQueueRequest)
	SpecializationUtil.registerFunction(placeable, "setAreaBlocked", PlaceableNPCNavigation.setAreaBlocked)
	SpecializationUtil.registerFunction(placeable, "visualiseNavigation", PlaceableNPCNavigation.visualiseNavigation)
end


function PlaceableNPCNavigation.prerequisitesPresent()

	print("Loaded placeable: PlaceableNPCNavigation")

	return true

end


function PlaceableNPCNavigation:onFinalizePlacement()

    local spec = self[specName]

    self:raiseActive()

    spec.uniqueIdToQueueOrder = {}
    spec.queue = {}
    spec.debugTimer = {}
    spec.perimeter = {}
    spec.holes = {}
    spec.levels = {}
    spec.rooms = {}
    spec.targets = {}
    spec.groups = {}
    spec.cache = {}

    local xmlFile = self.xmlFile

    spec.geometryFilename = Utils.getFilename(xmlFile:getValue("placeable.npcNavigation#geometryFilename"), self.baseDirectory)
    spec.cellSize = roundNumber(xmlFile:getValue("placeable.npcNavigation#cellSize"), 4)

    spec.pathsToPreload = {}
    xmlFile:iterate("placeable.npcNavigation.paths.path", function(_, key)
    
        local startNode = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
        local endNode = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
        table.insert(spec.pathsToPreload, {
            ["startNode"] = getName(startNode),
            ["endNode"] = getName(endNode)
        })
    
    end)

    local rooms = spec.rooms

    xmlFile:iterate("placeable.npcNavigation.rooms.room", function(_, key)
    
        local id = xmlFile:getValue(key .. "#id")

        rooms[id] = rooms[id] or {
            ["connections"] = {}
        }

        local connections = rooms[id].connections

        xmlFile:iterate(key .. ".connection", function(_, connectionKey)
        
            local connectionId = xmlFile:getValue(connectionKey .. "#id")
            local connectionNode = getName(xmlFile:getValue(connectionKey .. "#node", nil, self.components, self.i3dMappings))

            rooms[connectionId] = rooms[connectionId] or {
                ["connections"] = {}
            }

            connections[connectionId] = connectionNode
            rooms[connectionId].connections[id] = connectionNode
        
        end)
    
    end)
    
    self:createPathTargets(xmlFile, "placeable.npcNavigation.targets")

    --g_asyncTaskManager:addTask(function()
    
        self:createNavigationMesh()

    --end, " - Load Placeable Navigation Mesh")

    addConsoleCommand("debugPathfinding", "Debug pathfinding", "consoleCommandFindPath", self)

end


function PlaceableNPCNavigation:createPathTargets(xmlFile, key)

    local spec = self[specName]

    xmlFile:iterate(key .. ".group", function(_, key)
    
        local group = {}

        xmlFile:iterate(key .. ".target", function(_, targetKey)
            local node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
            local linkedNode = xmlFile:getValue(targetKey .. "#linkNode", nil, self.components, self.i3dMappings)
            local name = getName(node)
            table.insert(group, name)
            spec.targets[name] = {
                ["node"] = node,
                ["occupied"] = false,
                ["linked"] = linkedNode ~= nil and getName(linkedNode) or nil
            }
        end)
        
        spec.groups[xmlFile:getValue(key .. "#key")] = group
    
    end)

    xmlFile:iterate(key .. ".target", function(_, targetKey)
        local node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
        local linkedNode = xmlFile:getValue(targetKey .. "#linkNode", nil, self.components, self.i3dMappings)
        spec.targets[getName(node)] = {
            ["node"] = node,
            ["occupied"] = false,
            ["linked"] = linkedNode ~= nil and getName(linkedNode) or nil
        }
    end)

end


function PlaceableNPCNavigation:preloadPaths()

    local spec = self[specName]
    local pathsToPreload = spec.pathsToPreload
    local targets = spec.targets
    
    for _, path in pairs(pathsToPreload) do

        local t1 = targets[path.startNode]
        local t2 = targets[path.endNode]

        self:findPath(t1.x, t1.y, t1.z, t2.x, t2.y, t2.z)
    
    end

    spec.pathsToPreload = nil

end


function roundNumber(n, i)
    return tonumber(string.format("%." .. i .. "f", n))
end


function PlaceableNPCNavigation:getNPCSpawnPoint(spawnGroupName)

    local spec = self[specName]
    local validTargets = {}
    local targets = spec.targets

    for _, name in pairs(spec.groups[spawnGroupName]) do
        if not targets[name].occupied then table.insert(validTargets, name) end
    end

    if #validTargets == 0 then return nil end

    local name = validTargets[math.random(#validTargets)]
    local target = targets[name]

    local x, z = self:intIndexToPoint(target.x, target.z)

    return x, target.y, z, target.ry, name

end


function PlaceableNPCNavigation:onUpdate(dt)

    local spec = self[specName]

    if #spec.uniqueIdToQueueOrder == 0 then return end

    local uniqueId = table.remove(spec.uniqueIdToQueueOrder, 1)
    local job = spec.queue[uniqueId]
    local start, target = job.start, job.target

    local indexPath = self:getPath(start.x, start.y, start.z, target.x, target.y, target.z)
    local path = {}

    if indexPath ~= nil then

        for _, point in pairs(indexPath) do
            local x, z = self:intIndexToPoint(point.x, point.z)
            table.insert(path, {
                ["x"] = x,
                ["y"] = point.y,
                ["z"] = z
            })
        end

    end

    job.callback(job.owner, indexPath ~= nil and path or nil, job.ry, job.node)

    spec.queue[uniqueId] = nil

    self:raiseActive()

end


function PlaceableNPCNavigation:removeQueueRequest(uniqueId)

    local spec = self[specName]

    for i, id in pairs(spec.uniqueIdToQueueOrder) do
        if id == uniqueId then
            table.remove(spec.uniqueIdToQueueOrder, i)
            break
        end
    end

    local node = spec.queue[uniqueId].node
    self:setTargetOccupied(getName(node), false)

    spec.queue[uniqueId] = nil

end


function PlaceableNPCNavigation:getPathByType(pathType, x, y, z, callback, owner)

    local spec = self[specName]
    local group = spec.groups[pathType]
    local targets = spec.targets
    local target, name

    if group == nil then
        target = targets[pathType]
        if target == nil or target.occupied then return nil end
        name = pathType
    end

    if target == nil then

        local validTargets = {}

        for _, name in pairs(group) do
            if not targets[name].occupied then table.insert(validTargets, name) end
        end

        if #validTargets == 0 then return nil end

        name = validTargets[math.random(#validTargets)]
        target = targets[name]

    end
    
    self:setTargetOccupied(name, true, owner:getUniqueId())

    local queueId = Utils.getUniqueId(target, spec.queue, "navigationQueue", 32)
    local tx, tz = self:intIndexToPoint(target.x, target.z)

    spec.queue[queueId] = {
        ["start"] = {
            ["x"] = x,
            ["y"] = y,
            ["z"] = z
        },
        ["target"] = {
            ["x"] = tx,
            ["y"] = target.y,
            ["z"] = tz
        },
        ["callback"] = callback,
        ["owner"] = owner,
        ["ry"] = target.ry,
        ["node"] = target.node
    }
    table.insert(spec.uniqueIdToQueueOrder, queueId)

    self:raiseActive()

    return queueId

end


function PlaceableNPCNavigation:getTargetLinkedNode(targetName)

    local target = self[specName].targets[targetName]

    if target ~= nil then return target.linked end

end


function PlaceableNPCNavigation:setTargetOccupied(targetName, isOccupied, uniqueId)

    local target = self[specName].targets[targetName]

    if target == nil then return end
        
    target.occupied = isOccupied
    target.npc = uniqueId

end


function PlaceableNPCNavigation:getTargetNodeByName(targetName)

    local spec = self[specName]
    local target = spec.targets[targetName]

    return target ~= nil and target.node or nil

end


function PlaceableNPCNavigation:getTargetByName(targetName)

    return self[specName].targets[targetName]

end


local function findTargetRoom(rooms, visited, current, target, path)

    local room = rooms[current]
    visited[current] = true

    if room.connections[target] ~= nil then
        table.insert(path, room.connections[target])
        return path
    end

    for connectionRoomName, connectionNode in pairs(room.connections) do
        if visited[connectionRoomName] then continue end
        visited[connectionRoomName] = true
        local newPath = {}
        for _, node in pairs(path) do table.insert(newPath, node) end
        table.insert(newPath, connectionNode)
        return findTargetRoom(rooms, visited, connectionRoomName, target, newPath)
    end

end


function PlaceableNPCNavigation:getPath(sx, sy, sz, tx, ty, tz)

    local currentRoom = self:getRoomForPoint(sx, sy, sz)
    local targetRoom = self:getRoomForPoint(tx, ty, tz)

    sx, sz = self:pointToIntIndex(sx, sz)
    tx, tz = self:pointToIntIndex(tx, tz)

    if currentRoom == targetRoom then
        local path = self:findPath(sx, sy, sz, tx, ty, tz)
        if path == nil then return nil end
        table.insert(path, { ["x"] = tx, ["y"] = ty, ["z"] = tz })
        return path
    end

    local spec = self[specName]
    local rooms = spec.rooms
    local path = findTargetRoom(rooms, {}, currentRoom, targetRoom, {})
    
    if path == nil then return nil end

    local targets = spec.targets
    local fullPath = {}
    local osx, osy, osz = sx, sy, sz

    for _, node in pairs(path) do
        
        local target = targets[node]
        local nx, ny, nz = target.x, target.y, target.z
        local path = self:findPath(sx, sy, sz, nx, ny, nz)

        if path == nil then return nil end

        local copy = table.clone(path, 2)
        table.remove(copy, #copy)
        for _, point in pairs(copy) do table.insert(fullPath, point) end

        sx, sy, sz = nx, ny, nz

    end

    local path = self:findPath(sx, sy, sz, tx, ty, tz)

    if path == nil then return nil end

    local copy = table.clone(path, 2)
    for _, point in pairs(copy) do table.insert(fullPath, point) end

    local cellSize = spec.cellSize
    local levels = spec.levels
    local i = #fullPath

    while i > 2 do

        local p1 = fullPath[i]
        
        for j = 1, i - 1 do

            local p2 = fullPath[j]

            if p1.x == p2.x and p1.y == p2.y and p1.z == p2.z then
                
                for n = i, j, -1 do
                    table.remove(fullPath, n)
                end

                i = j
                break

            end

        end

        i = i - 1

    end

    i = #fullPath
    
    while i > 2 do

        local p1 = fullPath[i]
        local l1 = levels[p1.y]
        local lastY = p1.y
        local p0 = fullPath[i - 1]
        local requiredLevels = { [p0.y] = { p0.x, p0.z } }
        local levelsSorted = { p0.y }

        for j = i - 2, 1, -1 do
            
            local p2 = fullPath[j]

            if math.abs(lastY - p2.y) > 0.25 then break end

            if p1.x ~= p2.x and p1.z ~= p2.z then
                if requiredLevels[p2.y] == nil then
                    requiredLevels[p2.y] = { p2.x, p2.z }
                    table.insert(levelsSorted, p2.y)
                end
                lastY = p2.y
                continue
            end
                    
            local hasLine = true

            for k, y in pairs(levelsSorted) do
                hasLine = math.abs((k == 1 and p1.y or levelsSorted[k-1]) - y) < 0.25
                if not hasLine then break end
            end

            if not hasLine then break end

            local l2 = levels[p2.y]

            if p1.z == p2.z then

                local z = p1.z

                for x = p1.x + (p1.x > p2.x and -1 or 1), p2.x + (p2.x > p1.x and -1 or 1), p1.x > p2.x and -1 or 1 do
                    
                    local row1, row2 = l1.rows[x], l2.rows[x]

                    if (row1 == nil or row1[z] == nil) and (row2 == nil or row2[z] == nil) then

                        hasLine = false

                        for y, point in pairs(requiredLevels) do
                            if point[1] ~= x then continue end
                            local row3 = levels[y].rows[x]
                            hasLine = row3 ~= nil and row3[z] ~= nil and row3[z]
                            break
                        end

                        if not hasLine then break end

                    end
                end

                if not hasLine then continue end

                for k = i - 1, j + 1, -1 do

                    local p3 = fullPath[k]
                    local hasChanged = false
                    
                    for y, point in pairs(requiredLevels) do
                        if point[1] ~= p3.x then continue end
                        local row = levels[y].rows[point[1]]
                        if row ~= nil and row[p1.z] then p3.x, p3.z = point[1], p1.z end
                        requiredLevels[y] = nil
                        hasChanged = true
                        break
                    end

                    if not hasChanged then table.remove(fullPath, k) end

                end

            elseif p1.x == p2.x then

                local x = p1.x
                local columns1 = l1.rows[x]
                local columns2 = l2.rows[x] ~= nil and l2.rows[x] or nil

                for z = p1.z + (p1.z > p2.z and -1 or 1), p2.z + (p2.z > p1.z and -1 or 1), p1.z > p2.z and -1 or 1 do

                    if columns1[z] == nil and (columns2 == nil or columns2[z] == nil) then

                        hasLine = false

                        for y, point in pairs(requiredLevels) do
                            if point[2] ~= z then continue end
                            local row1 = levels[y].rows[x]
                            hasLine = row1 ~= nil and row1[z] ~= nil and row1[z]
                            break
                        end

                        if not hasLine then break end

                    end

                end

                if not hasLine then continue end

                for k = i - 1, j + 1, -1 do

                    local p3 = fullPath[k]
                    local hasChanged = false
                    
                    for y, point in pairs(requiredLevels) do
                        if point[2] ~= p3.z then continue end
                        local row = levels[y].rows[p1.x]
                        if row ~= nil and row[point[2]] then p3.x, p3.z = p1.x, point[2] end
                        requiredLevels[y] = nil
                        hasChanged = true
                        break
                    end

                    if not hasChanged then table.remove(fullPath, k) end

                end

            end

            i = j
            break

        end

        i = i - 1

    end

    if 1 == 2 then
    for i = #fullPath, 2, -1 do

        local p1 = fullPath[i]
        local prevX, prevZ = fullPath[i - 1].x, fullPath[i - 1].z
        local level = levels[p1.y]

        for j = 1, i - 2 do

            local p2 = fullPath[j]

            if p1.y ~= p2.y then continue end

            local hasConnection = true
            
            if roundNumber(p1.x - prevX, 4) == 0 then

                local columns = level.rows[p1.x].columns
                
                for z = p1.z + (p1.z > p2.z and -cellSize or cellSize), p2.z, p1.z > p2.z and -cellSize or cellSize do

                    z = roundNumber(z, 4)

                    if columns[z] == nil or not columns[z] then
                        hasConnection = false
                        break
                    end

                end

                if not hasConnection then continue end

                for x = p1.x + (p1.x > p2.x and -cellSize or cellSize), p2.x, p1.x > p2.x and -cellSize or cellSize do

                    x = roundNumber(x, 4)

                    if level.rows[x] == nil or level.rows[x].columns[p2.z] == nil or not level.rows[x].columns[p2.z] then
                        hasConnection = false
                        break
                    end

                end

                if not hasConnection then continue end

                print(string.format("checking connection between (%.4f, %.4f, %.4f) and (%.4f, %.4f, %.4f)", p1.x, p1.y, p1.z, p2.x, p2.y, p2.z))
                print("hasConnection (1)")

                for k = i - 1, j + 1, -1 do table.remove(fullPath, k) end

                table.insert(fullPath, j + 1, {
                    ["x"] = p1.x,
                    ["y"] = p1.y,
                    ["z"] = p2.z
                })

                i = j - 1

            else

                for x = p1.x + (p1.x > p2.x and -cellSize or cellSize), p2.x, p1.x > p2.x and -cellSize or cellSize do

                    x = roundNumber(x, 4)

                    if level.rows[x] == nil or level.rows[x].columns[p1.z] == nil or not level.rows[x].columns[p1.z] then
                        hasConnection = false
                        break
                    end

                end

                if not hasConnection then continue end

                local columns = level.rows[p2.x].columns

                for z = p1.z + (p1.z > p2.z and -cellSize or cellSize), p2.z, p1.z > p2.z and -cellSize or cellSize do

                    z = roundNumber(z, 4)

                    if columns[z] == nil or not columns[z] then
                        hasConnection = false
                        break
                    end

                end

                if not hasConnection then continue end

                print(string.format("checking connection between (%.4f, %.4f, %.4f) and (%.4f, %.4f, %.4f)", p1.x, p1.y, p1.z, p2.x, p2.y, p2.z))
                print("hasConnection (2)")

                for k = i - 1, j + 1, -1 do table.remove(fullPath, k) end

                table.insert(fullPath, j + 1, {
                    ["x"] = p2.x,
                    ["y"] = p1.y,
                    ["z"] = p1.z
                })

                i = j - 1

            end

            break

        end

    end
    end

    table.insert(fullPath, { ["x"] = tx, ["y"] = ty, ["z"] = tz })

    spec.debugTestPath = {
        ["sx"] = osx,
        ["sy"] = osy,
        ["sz"] = osz,
        ["tx"] = tx,
        ["ty"] = ty,
        ["tz"] = tz,
        ["path"] = fullPath,
        ["cost"] = 0
    }

    return fullPath

end


function PlaceableNPCNavigation:getRoomForPoint(x, y, z)

    local rooms = self[specName].rooms

    for name, room in pairs(rooms) do

        if room.x1 == nil then continue end

        if x >= room.x1 and x <= room.x2 and y + 0.1 >= room.y1 and y + 0.1 <= room.y2 and z >= room.z1 and z <= room.z2 then return name end

    end

    return "outside"

end


function PlaceableNPCNavigation:findPath(sx, sy, sz, tx, ty, tz)

	sx, sy, sz = self:getClosestPoint(sx, sy, sz)

	if sx == nil or sy == nil or sz == nil then return end

	tx, ty, tz = self:getClosestPoint(tx, ty, tz)

	if tx == nil or ty == nil or tz == nil then return end

    local spec = self[specName]

    spec.debugTestPath = {
        ["sx"] = sx,
        ["sy"] = sy,
        ["sz"] = sz,
        ["tx"] = tx,
        ["ty"] = ty,
        ["tz"] = tz
    }

	for _, cache in pairs(spec.cache) do

		local t1x, t1y, t1z, t2x, t2y, t2z = cache.sx, cache.sy, cache.sz, cache.tx, cache.ty, cache.tz

		if t1x == sx and t1y == sy and t1z == sz and t2x == tx and t2y == ty and t2z == tz then
            spec.debugTestPath.path = cache.path
            print("got path from forward cache")
            return cache.path
        end

		if t2x == sx and t2y == sy and t2z == sz and t1x == tx and t1y == ty and t1z == tz then
            local path, cachePath = {}, cache.path
            for i = #cachePath, 1, -1 do table.insert(path, cachePath[i]) end
            spec.debugTestPath.path = path
            print("got path from reverse cache")
            return path
        end

	end

	local path = PathUtil.findPath(sx, sy, sz, tx, ty, tz, spec.levels, self)

    if path == nil then return nil end
        
    local lastCorner = #path
    local numSinceCorner = 1

    for i = #path, 1, -1 do

        if i == 1 or i == #path then continue end
        
        local p1 = path[i]
        local p2 = path[i - 1]
        local p3 = path[lastCorner]

        if p1.x == p2.x and p1.x == p3.x and p1.y == p2.y and p1.y == p3.y then
            
            if math.abs(p2.z - p1.z) == 1 and math.abs(p3.z - p1.z) / numSinceCorner == 1 then
                table.remove(path, i)
                lastCorner = lastCorner - 1
                numSinceCorner = numSinceCorner + 1
                continue
            end

        end

        if p1.z == p2.z and p1.z == p3.z and p1.y == p2.y and p1.y == p3.y then
            
            if math.abs(p2.x - p1.x) == 1 and math.abs(p3.x - p1.x) / numSinceCorner == 1 then
                table.remove(path, i)
                lastCorner = lastCorner - 1
                numSinceCorner = numSinceCorner + 1
                continue
            end

        end

        lastCorner = i
        numSinceCorner = 1

    end

    local cache = {
        ["sx"] = sx,
        ["sy"] = sy,
        ["sz"] = sz,
        ["tx"] = tx,
        ["ty"] = ty,
        ["tz"] = tz,
        ["path"] = path
    }

    spec.debugTestPath.path = path
    table.insert(spec.cache, cache)

    print(string.format("added to cache (%d)", #spec.cache))

    return path

end


function PlaceableNPCNavigation:branchToClosestPoint(level, x, z)

    if level.rows[x] ~= nil then

        local row = level.rows[x]
        
        for h = 0, 2, 1 do
        
            if row[z - h] ~= nil then return x, z - h end
            if row[z + h] ~= nil then return x, z + h end

        end

    end

    for w = 0, 2, 1 do
        
        local row1, row2 = level.rows[x - w], level.rows[x + w]

        for h = 0, 2, 1 do

            if row1 ~= nil and row1[z] ~= nil then return x - w, z end
            if row2 ~= nil and row2[z] ~= nil then return x + w, z end

            if row1 ~= nil and row1[z - h] ~= nil then return x - w, z - h end
            if row2 ~= nil and row2[z - h] ~= nil then return x + w, z - h end

            if row1 ~= nil and row1[z + h] ~= nil then return x - w, z + h end
            if row2 ~= nil and row2[z + h] ~= nil then return x + w, z + h end

        end

    end

end


function PlaceableNPCNavigation:getClosestPoint(x, y, z)

    local closest
    local levels = self[specName].levels

    for ly, level in pairs(levels) do

        local distance = math.abs(y - ly)

        if (closest == nil or closest.distance > distance) then

            local x1, z1

            if level.rows[x] == nil or level.rows[x][z] == nil then
                x1, z1 = self:branchToClosestPoint(level, x, z)
            else
                x1, z1 = x, z
            end

            if x1 == nil or z1 == nil then continue end

            closest = {
                ["distance"] = distance,
                ["x"] = x1,
                ["y"] = ly,
                ["z"] = z1
            }

        end

    end

    if closest == nil then return nil, nil, nil end

	return closest.x, closest.y, closest.z

end


function PlaceableNPCNavigation:normalizeCoordinate(i, y, coordType)

    local spec = self[specName]
    local cellSize = spec.cellSize
	local decimal = i % cellSize

	if decimal < cellSize / 2 then return roundNumber((i - decimal) + spec["n" .. coordType], 4) end

	return roundNumber(i + (spec["n" .. coordType] - decimal), 4)

end


function PlaceableNPCNavigation:setAreaBlocked(x1, z1, x2, z2, y, isBlocked)

    x1, z1 = self:pointToIntIndex(x1, z1)
    x2, z2 = self:pointToIntIndex(x2, z2)

    x1, y, z1 = self:getClosestPoint(x1, y, z1)
    x2, _, z2 = self:getClosestPoint(x2, y, z2)

    local level = self[specName].levels[y]

    for x = x1, x2, 1 do
        for z = z1, z2, 1 do
            if level.rows[x] == nil or level.rows[x][z] == nil then continue end
            level.rows[x][z] = not isBlocked
        end
    end

end


function PlaceableNPCNavigation:createNavigationMesh()

    local spec = self[specName]
    local x, y, z = getWorldTranslation(self.rootNode)
    local xmlFile = XMLFile.load("navigationGeometry", spec.geometryFilename)
    local perimeter, holes, rooms = spec.perimeter, spec.holes, spec.rooms

    local perimeterPolygons = {}
    local holePolygons = {}

    xmlFile:iterate("navigation.outerPolygon.vertex", function(_, key)

        local x = roundNumber(x + xmlFile:getFloat(key .. "#x"), 4)
        local y = roundNumber(y + xmlFile:getFloat(key .. "#z"), 4)
        local z = roundNumber(z - xmlFile:getFloat(key .. "#y"), 4)
    
        table.insert(perimeter, {
            ["x"] = x,
            ["y"] = y,
            ["z"] = z
        })

        if perimeterPolygons[y] == nil then perimeterPolygons[y] = {} end
        table.insert(perimeterPolygons[y], { ["x"] = x, ["z"] = z })
    
    end)

    xmlFile:iterate("navigation.blockedPolygons.polygon", function(_, key)

        local hole = {}
        local polygon = {}

        xmlFile:iterate(key .. ".vertex", function(_, pointKey)

            local x = roundNumber(x + xmlFile:getFloat(pointKey .. "#x"), 4)
            local y = roundNumber(y + xmlFile:getFloat(pointKey .. "#z"), 4)
            local z = roundNumber(z - xmlFile:getFloat(pointKey .. "#y"), 4)
    
            table.insert(hole, {
                ["x"] = x,
                ["y"] = y,
                ["z"] = z
            })

            table.insert(polygon, { ["x"] = x, ["z"] = z })

        end)

        table.insert(holes, hole)
        local y = hole[1].y
        if holePolygons[y] == nil then holePolygons[y] = {} end
        table.insert(holePolygons[y], polygon)

    end)

    xmlFile:iterate("navigation.rooms.room", function(_, key)

        local name = xmlFile:getString(key .. "#name")
        local room = rooms[string.sub(name, string.find(name, "_") + 1)]
        
        room.x1 = roundNumber(x + xmlFile:getFloat(key .. "#minX"), 4)
        room.y1 = roundNumber(y + xmlFile:getFloat(key .. "#minZ"), 4)
        room.z1 = roundNumber(z - xmlFile:getFloat(key .. "#maxY"), 4)
        room.x2 = roundNumber(x + xmlFile:getFloat(key .. "#maxX"), 4)
        room.y2 = roundNumber(y + xmlFile:getFloat(key .. "#maxZ"), 4)
        room.z2 = roundNumber(z - xmlFile:getFloat(key .. "#minY"), 4)
    
    end)

    xmlFile:delete()

    spec.polygons = {
        ["perimeter"] = perimeterPolygons,
        ["holes"] = holePolygons
    }

    self:fillMesh()

end


function PlaceableNPCNavigation:fillMesh()

    local spec = self[specName]
    local levels = {}
    local perimeter = spec.perimeter
    local lx, lz, hx, hz

    for _, point in pairs(perimeter) do
        
        if levels[point.y] == nil then
            local r, g, b = math.random(), math.random(), math.random()
            levels[point.y] = { ["rows"] = {}, ["lx"] = point.x, ["lz"] = point.z, ["hx"] = point.x, ["hz"] = point.z, ["colour"] = { r, g, b } }
            if spec.oy == nil or point.y < spec.oy then spec.oy = point.y end
        end

        local level = levels[point.y]

        if lx == nil or point.x < lx then lx = point.x end
        if lz == nil or point.z < lz then lz = point.z end
        if hx == nil or point.x > hx then hx = point.x end
        if hz == nil or point.z > hz then hz = point.z end

        if point.x < level.lx then level.lx = point.x end
        if point.z < level.lz then level.lz = point.z end
        if point.x > level.hx then level.hx = point.x end
        if point.z > level.hz then level.hz = point.z end

    end

    local cellSize = spec.cellSize
    spec.nx, spec.nz = lx % cellSize, lz % cellSize
    spec.ox, spec.oz = math.floor(lx / cellSize) * cellSize, math.floor(lz / cellSize) * cellSize
    local ox, oz = spec.ox, spec.oz

    for y, level in pairs(levels) do

        local rows = level.rows

        for x = level.lx - cellSize, level.hx + cellSize, cellSize do

            local ix = math.floor((x - ox) / cellSize + 0.5)
            local px = ox + ix * cellSize
            local columns

            for z = level.lz - cellSize, level.hz + cellSize, cellSize do

                local iz = math.floor((z - oz) / cellSize + 0.5)

                if not self:getIsPointInsideMesh(px, y, oz + iz * cellSize) then continue end

                if columns == nil then columns = {} end

                columns[iz] = true

            end

            if columns == nil then continue end

            rows[ix] = columns

        end

    end

    spec.levels = levels
    self:finishLoadingNavigationMesh()

end


function PlaceableNPCNavigation:pointToIntIndex(x, z)

    local spec = self[specName]
    local cellSize = spec.cellSize

    return math.floor((x - spec.ox) / cellSize + 0.5), math.floor((z - spec.oz) / cellSize + 0.5)

end


function PlaceableNPCNavigation:intIndexToPoint(ix, iz)

    local spec = self[specName]
    local cellSize = spec.cellSize

    return spec.ox + ix * cellSize, spec.oz + iz * cellSize

end


function PlaceableNPCNavigation:finishLoadingNavigationMesh()

    local spec = self[specName]

    for _, target in pairs(spec.targets) do

        local x, y, z = getWorldTranslation(target.node)
        local dx, _, dz = localDirectionToWorld(target.node, 0, 0, 1)

        target.x, target.z = self:pointToIntIndex(x, z)
        target.y = y
        target.ry = math.atan2(dx, dz)

    end

    self:preloadPaths()
    SpecializationUtil.raiseEvent(self, "onNavigationMeshLoaded")

end


function PlaceableNPCNavigation:getIsPointInsideMesh(x, y, z)

    local polygons = self[specName].polygons
    local perimeterPolygon = polygons.perimeter[y]

	if perimeterPolygon == nil or not self:getIsPointInsidePolygon(x, z, perimeterPolygon) then return false end

    local holePolygons = polygons.holes[y]

    if holePolygons == nil then return true end

	for _, polygon in pairs(holePolygons) do
		if self:getIsPointInsidePolygon(x, z, polygon) then return false end
	end

    return true

end


function PlaceableNPCNavigation:getIsPointInsidePolygon(x, z, polygon)

    local inside = false
    local p1 = polygon[1]
    local p2

    for i = 1, #polygon do

        p2 = polygon[(i % #polygon) + 1]

        if z > math.min(p1.z, p2.z) and z <= math.max(p1.z, p2.z) and x <= math.max(p1.x, p2.x) then

            local intersection = (z - p1.z) * (p2.x - p1.x) / (p2.z - p1.z) + p1.x

            if p1.x == p2.x or x <= intersection then inside = not inside end

        end

        p1 = p2

    end

    return inside

end


function PlaceableNPCNavigation:visualiseNavigation()

    local spec = self[specName]

    --for i, point in pairs(spec.perimeter) do

		--local nextPoint = spec.perimeter[i + 1] or spec.perimeter[1]
		--drawDebugLine(point.x, point.y, point.z, 0, 1, 0, nextPoint.x, nextPoint.y, nextPoint.z, 0, 1, 0, false)

	--end

    --for _, hole in pairs(spec.holes) do

        --for i, point in pairs(hole) do

		    --local nextPoint = hole[i + 1] or hole[1]
		    --drawDebugLine(point.x, point.y, point.z, 0, 1, 0, nextPoint.x, nextPoint.y, nextPoint.z, 1, 0, 0, false)

        --end

	--end

    --drawDebugPoint(spec.ox, spec.oy, spec.oz, 1, 0, 0, 1, true)

	for y, level in pairs(spec.levels) do
        
        for ix, columns in pairs(level.rows) do
            
            for iz, point in pairs(columns) do
                
                local x, z = self:intIndexToPoint(ix, iz)
                if point then drawDebugPoint(x, y + 0.025, z, 0, 1, 0, 1, true) end
                --DebugFlag.renderAtPosition(x, y, z, nil, nil, nil, string.format("%d %.3f %d", ix, y, iz), 1.5, 0.5, 1, 2, 2)

            end

        end

        local r, g, b = level.colour[1], level.colour[2], level.colour[3]

        drawDebugLine(level.lx, y, level.lz, r, g, b, level.hx, y, level.lz, r, g, b, true)
        drawDebugLine(level.hx, y, level.lz, r, g, b, level.hx, y, level.hz, r, g, b, true)
        drawDebugLine(level.hx, y, level.hz, r, g, b, level.lx, y, level.hz, r, g, b, true)
        drawDebugLine(level.lx, y, level.hz, r, g, b, level.lx, y, level.lz, r, g, b, true)
        --DebugFlag.renderAtPosition(level.lx, y, level.lz, nil, nil, nil, string.format("lx=%.4f y=%.4f lz=%.4f", level.lx, y, level.lz), 1.5, 0.5, 1, 2, 2)
        --DebugFlag.renderAtPosition(level.hx, y, level.hz, nil, nil, nil, string.format("hx=%.4f y=%.4f hz=%.4f", level.hx, y, level.hz), 1.5, 0.5, 1, 2, 2)

    end

    if spec.debugTestPath ~= nil then

        local sx, sy, sz = spec.debugTestPath.sx, spec.debugTestPath.sy, spec.debugTestPath.sz
        local tx, ty, tz = spec.debugTestPath.tx, spec.debugTestPath.ty, spec.debugTestPath.tz

        sx, sz = self:intIndexToPoint(sx, sz)
        tx, tz = self:intIndexToPoint(tx, tz)
        
        DebugFlag.renderAtPosition(sx, sy, sz, nil, nil, nil, "start", 1, 0.5)
        DebugFlag.renderAtPosition(tx, ty, tz, nil, nil, nil, "end", 1, 0.5)

        if spec.debugTestPath.path ~= nil then
            for i, point in pairs(spec.debugTestPath.path) do

                if i == #spec.debugTestPath.path then break end
                local next = spec.debugTestPath.path[i + 1]
                local x1, z1 = self:intIndexToPoint(point.x, point.z)
                local x2, z2 = self:intIndexToPoint(next.x, next.z)
                drawDebugLine(x1, point.y + 0.01, z1, 0, 0, 1, x2, next.y + 0.01, z2, 0, 0, 1, true)
                --DebugFlag.renderAtPosition(point.x, point.y, point.z, nil, nil, nil, string.format("%d) %.4f %.4f %.4f", i, point.x, point.y, point.z), 1, 0.5, nil, 2, 3)
        
                --if i == math.floor(#self.debugTestPath.path / 2) then DebugFlag.renderAtPosition(point.x, point.y, point.z, nil, nil, nil, tostring((self.debugTestPath.cost or 1) - 1), 1, 0.5) end

            end
        end

    end

    --for name, target in pairs(spec.targets) do
        
        --DebugFlag.renderAtPosition(target.x, target.y, target.z, nil, nil, nil, string.format("%s (%.2f %.2f %.2f) (%.2fr %.0fr)", name, target.x, target.y, target.z, target.ry, math.deg(target.ry)), 1, 0.5, nil, 2, 3)

    --end

    if #spec.debugTimer > 0 then

        if spec.debugOverlay == nil then
            _, spec.debugOffsetY = getNormalizedScreenValues(20, 20)
            spec.debugOverlay = g_overlayManager:createOverlay("gui.serverDetails", 0.3, 0.05, 0.2, 0.55)
            spec.debugOverlay:setAlignment(Overlay.ALIGN_VERTICAL_TOP, Overlay.ALIGN_HORIZONTAL_LEFT)
            spec.debugOverlay:setColor(0, 0, 0, 0.75)
            spec.debugOverlay:setPosition(0.4, 0.9)
        end

        spec.debugOverlay:render()
	
        setTextColor(1, 0, 0, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(true)
        
        renderText(0.425, 0.85, spec.debugOffsetY / 2, "Distance")
        renderText(0.475, 0.85, spec.debugOffsetY / 2, "Time")

        setTextColor(1, 1, 1, 1)
        setTextBold(false)

        local y = 0.835

        table.sort(spec.debugTimer, function(a, b)

            if a.time == b.time then return a.distance > b.distance end
        
            return a.time > b.time
        
        end)

        local totalDistance, totalTime = 0, 0

        for i, profile in pairs(spec.debugTimer) do

            if i <= 20 then
                renderText(0.425, y, spec.debugOffsetY / 2, string.format("%.4f", profile.distance))
                renderText(0.475, y, spec.debugOffsetY / 2, string.format("%.6f ms", profile.time))
                y = y - spec.debugOffsetY
            end

            totalDistance, totalTime = totalDistance + profile.distance, totalTime + profile.time

        end

        setTextColor(1, 0, 0, 1)
        setTextBold(true)

        renderText(0.425, y - spec.debugOffsetY, spec.debugOffsetY / 2, "Average Distance")
        renderText(0.475, y - spec.debugOffsetY, spec.debugOffsetY / 2, "Average Time")

        setTextColor(1, 1, 1, 1)
        setTextBold(false)

        renderText(0.425, y - spec.debugOffsetY * 2, spec.debugOffsetY / 2, string.format("%.4f", totalDistance / #spec.debugTimer))
        renderText(0.475, y - spec.debugOffsetY * 2, spec.debugOffsetY / 2, string.format("%.6f ms", totalTime / #spec.debugTimer))

    end

end


function PlaceableNPCNavigation:consoleCommandFindPath()

    self:createNPC("BIDDER")

end


function PlaceableNPCNavigation.visualise()

    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if placeable.visualiseNavigation ~= nil then placeable:visualiseNavigation() end
    end

end


g_placeableNPCSystemProfiler:addClass(PlaceableNPCNavigation)