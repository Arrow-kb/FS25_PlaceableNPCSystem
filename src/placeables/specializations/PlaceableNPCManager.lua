PlaceableNPCManager = {}


local specName = "spec_npcManager"
local spawnClasses = {}
local npcClasses = {}
local taskClasses = {}


function PlaceableNPCManager.registerSpawnClass(class)
    table.insert(spawnClasses, class)
    g_placeableNPCSystemProfiler:addClass(class)
end


function PlaceableNPCManager.registerNPCClass(class)
    table.insert(npcClasses, class)
    g_placeableNPCSystemProfiler:addClass(class)
end


function PlaceableNPCManager.registerTaskClass(class)
    table.insert(taskClasses, class)
    g_placeableNPCSystemProfiler:addClass(class)
end


function PlaceableNPCManager.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("npcManager")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager#namesFilename", "NPC names xml filename")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.spawn(?)#class", "NPC spawn lua class")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.spawn(?)#group", "NPC spawn navigation group")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.spawn(?).vehicles.vehicle(?)#filename", "Vehicle xml filename")
	schema:register(XMLValueType.FLOAT, basePath .. ".npcManager.spawn(?).vehicles.vehicle(?)#minDepth", "Vehicle collision node min depth (z)")
	schema:register(XMLValueType.FLOAT, basePath .. ".npcManager.spawn(?).vehicles.vehicle(?)#maxDepth", "Vehicle collision node max depth (z)")
	schema:register(XMLValueType.FLOAT, basePath .. ".npcManager.spawn(?).vehicles.vehicle(?)#factor", "Vehicle spawn factor")
	schema:register(XMLValueType.FLOAT, basePath .. ".npcManager.spawn(?).vehicles.vehicle(?)#driverOffset", "Vehicle driver depth offset")
    schema:register(XMLValueType.STRING, basePath .. ".npcManager.tasks.task(?)#id", "Task ID")
    schema:register(XMLValueType.STRING, basePath .. ".npcManager.tasks.task(?)#class", "Task class")
    schema:register(XMLValueType.STRING, basePath .. ".npcManager.tasks.task(?)#group", "Task target group ID")
    schema:register(XMLValueType.INT, basePath .. ".npcManager.tasks.task(?)#minTime", "Task min duration time (seconds)")
    schema:register(XMLValueType.INT, basePath .. ".npcManager.tasks.task(?)#maxTime", "Task max duration time (seconds) (-1 for infinite)")
    schema:register(XMLValueType.BOOL, basePath .. ".npcManager.tasks.task(?)#unique", "Task is unique (can be reset)")
    schema:register(XMLValueType.STRING, basePath .. ".npcManager.tasks.task(?).conversations.conversation(?)#id", "Task conversation ID")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?)#id", "NPC unique ID")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?)#class", "NPC lua class")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).spawn.group(?)", "NPC spawn group")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?)#gender", "NPC appearance gender")
	schema:register(XMLValueType.BOOL, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?)#unique", "NPC appearance preset is unique")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?)#firstName", "NPC appearance preset first name for unique presets")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?)#lastName", "NPC appearance preset last name for unique presets")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).heads.head(?)", "NPC appearance head")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).jackets.jacket(?)", "NPC appearance jacket")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).shirts.shirt(?)", "NPC appearance shirt")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).pants.pants(?)", "NPC appearance trousers")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).hair.hair(?)", "NPC appearance hair style")
	schema:register(XMLValueType.INT, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).hairColour.colour(?)#min", "NPC appearance hair colour range min")
	schema:register(XMLValueType.INT, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).hairColour.colour(?)#max", "NPC appearance hair colour range max")
	schema:register(XMLValueType.FLOAT, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).hairColour.colour(?)#factor", "NPC appearance hair colour range factor")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).beards.head(?)#name", "NPC appearance beard head name")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).beards.head(?).beard(?)", "NPC appearance beard for head")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).hats.hat(?)", "NPC appearance hat")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).glasses.glasses(?)", "NPC appearance glasses")
	schema:register(XMLValueType.STRING, basePath .. ".npcManager.npcs.npc(?).appearance.preset(?).shoes.shoe(?)", "NPC appearance shoes")

    for _, class in pairs(spawnClasses) do
        if rawget(class, "registerXMLPaths") then class.registerXMLPaths(schema, basePath .. ".npcManager.spawn") end
    end
    for _, class in pairs(npcClasses) do
        if rawget(class, "registerXMLPaths") then class.registerXMLPaths(schema, basePath .. ".npcManager.npcs") end
    end
    for _, class in pairs(taskClasses) do
        if rawget(class, "registerXMLPaths") then class.registerXMLPaths(schema, basePath .. ".npcManager.tasks") end
    end

	schema:setXMLSpecializationType()
end


function PlaceableNPCManager.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("npcManager")

    for _, class in pairs(spawnClasses) do
        if rawget(class, "registerSavegameXMLPaths") then class.registerSavegameXMLPaths(schema, basePath .. ".npcs.npc(?).spawn") end
    end
    for _, class in pairs(npcClasses) do
        if rawget(class, "registerSavegameXMLPaths") then class.registerSavegameXMLPaths(schema, basePath .. ".npcs.npc(?)") end
    end
    for _, class in pairs(taskClasses) do
        if rawget(class, "registerSavegameXMLPaths") then class.registerSavegameXMLPaths(schema, basePath .. ".npcs.npc(?).task") end
    end

    schema:register(XMLValueType.STRING, basePath .. ".tasks.task(?)#id", "Task ID")
    schema:register(XMLValueType.BOOL, basePath .. ".tasks.task(?)#valid", "Task is valid (only unique tasks)")

	schema:setXMLSpecializationType()
end


function PlaceableNPCManager.registerEventListeners(placeable)
	SpecializationUtil.registerEventListener(placeable, "onLoad", PlaceableNPCManager)
	SpecializationUtil.registerEventListener(placeable, "onNavigationMeshLoaded", PlaceableNPCManager)
	SpecializationUtil.registerEventListener(placeable, "onUpdate", PlaceableNPCManager)
end


function PlaceableNPCManager.registerEvents(placeable)
    SpecializationUtil.registerEvent(placeable, "onNPCLoaded")
    SpecializationUtil.registerEvent(placeable, "onNPCDeleted")
end


function PlaceableNPCManager.registerFunctions(placeable)
	SpecializationUtil.registerFunction(placeable, "addNPCPath", PlaceableNPCManager.addNPCPath)
	SpecializationUtil.registerFunction(placeable, "consoleCommandClearNPCs", PlaceableNPCManager.consoleCommandClearNPCs)
	SpecializationUtil.registerFunction(placeable, "createNPC", PlaceableNPCManager.createNPC)
	SpecializationUtil.registerFunction(placeable, "createNPCTask", PlaceableNPCManager.createNPCTask)
	SpecializationUtil.registerFunction(placeable, "getClosestNPC", PlaceableNPCManager.getClosestNPC)
	SpecializationUtil.registerFunction(placeable, "getNPCAtTargetLinkedNode", PlaceableNPCManager.getNPCAtTargetLinkedNode)
	SpecializationUtil.registerFunction(placeable, "getNPCRandomFirstName", PlaceableNPCManager.getNPCRandomFirstName)
	SpecializationUtil.registerFunction(placeable, "getNPCRandomLastName", PlaceableNPCManager.getNPCRandomLastName)
	SpecializationUtil.registerFunction(placeable, "getNPCTaskById", PlaceableNPCManager.getNPCTaskById)
	SpecializationUtil.registerFunction(placeable, "getNPCTaskIsValid", PlaceableNPCManager.getNPCTaskIsValid)
	SpecializationUtil.registerFunction(placeable, "getNPCTaskTargetGroup", PlaceableNPCManager.getNPCTaskTargetGroup)
	SpecializationUtil.registerFunction(placeable, "getPlayerPosition", PlaceableNPCManager.getPlayerPosition)
	SpecializationUtil.registerFunction(placeable, "getRandomNPCAppearance", PlaceableNPCManager.getRandomNPCAppearance)
	SpecializationUtil.registerFunction(placeable, "getSpawnGroupByName", PlaceableNPCManager.getSpawnGroupByName)
	SpecializationUtil.registerFunction(placeable, "loadNPCNames", PlaceableNPCManager.loadNPCNames)
	SpecializationUtil.registerFunction(placeable, "loadNPCTasks", PlaceableNPCManager.loadNPCTasks)
	SpecializationUtil.registerFunction(placeable, "loadNPCTypes", PlaceableNPCManager.loadNPCTypes)
	SpecializationUtil.registerFunction(placeable, "registerDeletedNPC", PlaceableNPCManager.registerDeletedNPC)
	SpecializationUtil.registerFunction(placeable, "registerLoadedNPC", PlaceableNPCManager.registerLoadedNPC)
	SpecializationUtil.registerFunction(placeable, "setNPCTaskIsValid", PlaceableNPCManager.setNPCTaskIsValid)
	SpecializationUtil.registerFunction(placeable, "visualiseNPCs", PlaceableNPCManager.visualiseNPCs)
end


function PlaceableNPCManager.prerequisitesPresent()

	print("Loaded placeable: PlaceableNPCManager")

	return true

end


function PlaceableNPCManager:onLoad()

    local spec = self[specName]

    spec.npcs = {}
    spec.npcsSorted = {}
    spec.lastStateUpdate = 1
    spec.lastStateUpdateTicks = 0
    spec.lastPlayerUpdateTicks = 0
    spec.spawn = {}
    spec.types = {}
    spec.tasks = {}
	spec.playerCache = { ["x"] = 0, ["y"] = 0, ["z"] = 0 }

    local xmlFile = self.xmlFile

    xmlFile:iterate("placeable.npcManager.spawn", function(_, key)

        local class, errorMessage = ClassUtil.getClassObjectFromUnresolvedEnvironment(xmlFile:getValue(key .. "#class", "NPCSpawn"), self.customEnvironment)

        if class == nil then
            printWarning(string.format("PlaceableNPCManager.onLoad: spawn type \"%s\" could not be loaded (error: %s)", xmlFile:getValue(key .. "#group"), errorMessage))
            return
        end
        
        local spawn = {
            ["class"] = class
        }

        class.loadDataFromXMLFile(xmlFile, key, spawn)
        spec.spawn[xmlFile:getValue(key .. "#group")] = spawn
    
    end)

    self:loadNPCNames(Utils.getFilename(xmlFile:getValue("placeable.npcManager#namesFilename"), self.baseDirectory))
    self:loadNPCTypes(xmlFile, "placeable.npcManager.npcs")
    self:loadNPCTasks(xmlFile, "placeable.npcManager.tasks")
    
    addConsoleCommand("debugClearNPCs", "Debug clear NPCs", "consoleCommandClearNPCs", self)

end


function PlaceableNPCManager:loadNPCTasks(xmlFile, key)

    local spec = self[specName]
    local tasks = spec.tasks

    xmlFile:iterate(key .. ".task", function(_, taskKey)

        local task, id = NPCTask.loadTaskType(xmlFile, taskKey, self.customEnvironment)

        if task ~= nil and id ~= nil then tasks[id] = task end
    
    end)

end


function PlaceableNPCManager:loadNPCTypes(xmlFile, key)

    local spec = self[specName]
    local types = spec.types

    xmlFile:iterate(key .. ".npc", function(_, npcKey)

        local class, errorMessage = ClassUtil.getClassObjectFromUnresolvedEnvironment(xmlFile:getValue(npcKey .. "#class", "PlaceableNPC"), self.customEnvironment)

        if class == nil then
            printWarning(string.format("PlaceableNPCManager.loadNPCTypes: NPC type \"%s\" could not be loaded (error: %s)", xmlFile:getValue(npcKey .. "#id"), errorMessage))
            return
        end

        local groups = {}

        xmlFile:iterate(npcKey .. ".spawn.group", function(_, spawnKey)
            table.insert(groups, xmlFile:getValue(spawnKey))
        end)

        local appearance = {}

        xmlFile:iterate(npcKey .. ".appearance.preset", function(_, genderKey)

            local isUnique = xmlFile:getValue(genderKey .. "#unique", false)
        
            local items = {
                ["gender"] = xmlFile:getValue(genderKey .. "#gender"),
                ["unique"] = isUnique,
                ["firstName"] = isUnique and xmlFile:getValue(genderKey .. "#firstName") or nil,
                ["lastName"] = isUnique and xmlFile:getValue(genderKey .. "#lastName") or nil,
                ["available"] = true,
                ["heads"] = {},
                ["jackets"] = {},
                ["shirts"] = {},
                ["pants"] = {},
                ["hairStyles"] = {},
                ["hairColours"] = {},
                ["beards"] = {},
                ["glasses"] = {},
                ["shoes"] = {},
                ["hats"] = {}
            }

            xmlFile:iterate(genderKey .. ".heads.head", function(_, itemKey1)
                table.insert(items.heads, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".jackets.jacket", function(_, itemKey1)
                table.insert(items.jackets, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".shirts.shirt", function(_, itemKey1)
                table.insert(items.shirts, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".pants.pants", function(_, itemKey1)
                table.insert(items.pants, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".hair.hair", function(_, itemKey1)
                table.insert(items.hairStyles, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".hairColour.colour", function(_, itemKey1)
                table.insert(items.hairColours, {
                    ["min"] = xmlFile:getValue(itemKey1 .. "#min"),
                    ["max"] = xmlFile:getValue(itemKey1 .. "#max"),
                    ["factor"] = xmlFile:getValue(itemKey1 .. "#factor")
                })
            end)

            xmlFile:iterate(genderKey .. ".beards.head", function(_, itemKey1)
                local beards = {}
                xmlFile:iterate(itemKey1 .. ".beard", function(_, itemKey2)
                    table.insert(beards, xmlFile:getValue(itemKey2))
                end)
                items.beards[xmlFile:getValue(itemKey1 .. "#name")] = beards
            end)

            xmlFile:iterate(genderKey .. ".hats.hat", function(_, itemKey1)
                table.insert(items.hats, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".glasses.glasses", function(_, itemKey1)
                table.insert(items.glasses, xmlFile:getValue(itemKey1))
            end)

            xmlFile:iterate(genderKey .. ".shoes.shoe", function(_, itemKey1)
                table.insert(items.shoes, xmlFile:getValue(itemKey1))
            end)

            table.insert(appearance, items)
        
        end)

        types[xmlFile:getValue(npcKey .. "#id")] = {
            ["class"] = class,
            ["appearance"] = appearance,
            ["spawn"] = groups
        }
    
    end)

end


function PlaceableNPCManager:loadNPCNames(xmlFilename)

	local xmlFile = XMLFile.loadIfExists("npcNames", xmlFilename)

	local names = { ["first"] = { ["playerM"] = {}, ["playerF"] = {} }, ["last"] = {} }

	if xmlFile ~= nil then

		xmlFile:iterate("npcNames.first.male.name", function(_, key)

			table.insert(names.first.playerM, xmlFile:getString(key))

		end)

		xmlFile:iterate("npcNames.first.female.name", function(_, key)

			table.insert(names.first.playerF, xmlFile:getString(key))

		end)

		xmlFile:iterate("npcNames.last.name", function(_, key)

			table.insert(names.last, xmlFile:getString(key))

		end)

		xmlFile:delete()

	end

    self[specName].names = names

end


function PlaceableNPCManager:saveToXMLFile(xmlFile, key)

    local spec = self[specName]
    local i = 0

    for id, task in pairs(spec.tasks) do
        if not task.unique or task.valid then continue end
        local taskKey = string.format("%s.tasks.task(%d)", key, i)
        xmlFile:setValue(taskKey .. "#id", id)
        xmlFile:setValue(taskKey .. "#valid", false)
        i = i + 1
    end

    i = 0

    for _, npc in pairs(spec.npcs) do
        npc:saveToXMLFile(xmlFile, string.format("%s.npcs.npc(%d)", key, i))
        i = i + 1
    end

end


function PlaceableNPCManager:loadFromXMLFile(xmlFile, key)

    local spec = self[specName]

    local types = spec.types
    local tasks = spec.tasks

    xmlFile:iterate(key .. ".tasks.task", function(_, taskKey)
        local task = tasks[xmlFile:getValue(taskKey .. "#id")]
        if task ~= nil then task.valid = false end
    end)

    spec.npcs = {}
    spec.npcsSorted = {}

    xmlFile:iterate(key .. ".npcs.npc", function(_, npcKey)
    
        local className = xmlFile:getValue(npcKey .. "#class")
        local class = ClassUtil.getClassObject(className)
        local npc = class.new(self)

        npc:loadFromXMLFile(xmlFile, npcKey)
        npc:setClass(className)
        npc:load()

        local uniqueId = npc:getUniqueId()
        spec.npcs[uniqueId] = npc
        table.insert(spec.npcsSorted, uniqueId)

        for id, npcType in pairs(types) do
            if npcType.class ~= class then continue end
            self:registerLoadedNPC(npc)
            break
        end
    
    end)

end


function PlaceableNPCManager:registerLoadedNPC(npc)

    local spec = self[specName]
    local class = npc:getClass()
    local preset = npc:getAppearancePreset()

    for id, npcType in pairs(spec.types) do

        if npcType.class ~= class then continue end

        local appearance = npcType.appearance[preset]
        if appearance.unique then appearance.available = false end
            
        npc:setTypeId(id)
        SpecializationUtil.raiseEvent(self, "onNPCLoaded", id, npc)
        break

    end


end


function PlaceableNPCManager:registerDeletedNPC(npc)

    local spec = self[specName]
    local class = npc:getClass()
    local preset = npc:getAppearancePreset()

    for id, npcType in pairs(spec.types) do

        if npcType.class ~= class then continue end

        local appearance = npcType.appearance[preset]
        if appearance.unique then appearance.available = true end

        SpecializationUtil.raiseEvent(self, "onNPCDeleted", id, npc)
        break

    end

    local uniqueId = npc:getUniqueId()
    spec.npcs[uniqueId] = nil

    for i, id in pairs(spec.npcsSorted) do
        if id == uniqueId then
            table.remove(spec.npcsSorted, i)
            break
        end
    end

end


function PlaceableNPCManager:getNPCAtTargetLinkedNode(targetName)

    local linkedNode = self:getTargetLinkedNode(targetName)

    if linkedNode == nil then return nil end

    local spec = self[specName]
    local linked = self:getTargetByName(linkedNode)

    if linked == nil then return nil end

    local uniqueId = linked.npc
    
    return spec.npcs[uniqueId]

end


function PlaceableNPCManager:getClosestNPC(caller, forceSameType)

    local npcs = self[specName].npcs
    local typeId = caller:getTypeId()
    local closest
    local cx, cy, cz = caller:getPosition()

    for _, npc in pairs(npcs) do
        if npc == caller or npc.path ~= nil or (forceSameType and npc:getTypeId() ~= typeId) then continue end
        local x, y, z = npc:getPosition()
        local distance = MathUtil.vector2Length(cx - x, cz - z)
        if distance < 10 and math.abs(cy - y) < 0.5 and (closest == nil or distance < closest.distance) then
            closest = {
                ["distance"] = distance,
                ["npc"] = npc
            }
        end
    end

    return closest ~= nil and closest.npc or nil

end


function PlaceableNPCManager:getNPCTaskTargetGroup(id)

    local spec = self[specName]
    local taskType = spec.tasks[id]

    return taskType ~= nil and taskType.group or nil

end


function PlaceableNPCManager:setNPCTaskIsValid(id, isValid)

    local taskType = self[specName].tasks[id]

    if taskType.unique then taskType.valid = isValid end

end


function PlaceableNPCManager:getNPCTaskIsValid(id)

    local taskType = self[specName].tasks[id]

    return taskType ~= nil and taskType.valid or false

end


function PlaceableNPCManager:getNPCTaskById(id)

    return self[specName].tasks[id]

end


function PlaceableNPCManager:createNPCTask(id)

    local spec = self[specName]
    local taskType = spec.tasks[id]

    if taskType == nil or (taskType.unique and not taskType.valid) then return nil end

    local task = taskType.class.new()
    task:setClass(taskType.className)
    task:setType(id)
    task:setTargetTime(taskType.maxTime == -1 and -1 or math.random(taskType.minTime, taskType.maxTime))
    task:loadExtraVariablesFromType(taskType)
    self:setNPCTaskIsValid(id, false)

    return task

end


function PlaceableNPCManager:createNPC(id, spawnGroupName, preset)
    
    local spec = self[specName]
    local npcType = spec.types[id]

    if npcType == nil then return end

    local npc = npcType.class.new(self)

    if spawnGroupName == nil then spawnGroupName = npcType.spawn[math.random(#npcType.spawn)] end

    local spawnGroup = spec.spawn[spawnGroupName]
    local x, y, z, ry, nodeName = self:getNPCSpawnPoint(spawnGroupName)

    if x == nil then return end

    local appearances = npcType.appearance

    if preset ~= nil and (appearances[preset] == nil or (appearances[preset].unique and not appearances[preset].available)) then return end

    local appearance

    if preset == nil then
        local available = {}
        for i, preset in pairs(appearances) do
            if preset.unique and not preset.available then continue end
            table.insert(available, i)
        end
        if #available == 0 then return end
        preset = available[math.random(#available)]
        appearance = appearances[preset]
    else
        appearance = appearances[preset]
    end

    local spawn = spawnGroup.class.new()
    spawn:setSpawnNode(nodeName)
    spawn:setGroupName(spawnGroupName)
    spawn:setPosition(x, y, z)
    spawn:setRotation(ry)
    spawn:load(self)

    npc.x, npc.y, npc.z = spawn:getNPCSpawnPoint()
	npc:setAppearance(self:getRandomNPCAppearance(appearance))
    npc:setAppearancePreset(preset)
	npc:setName(appearance.firstName or self:getNPCRandomFirstName(npc.gender), appearance.lastName or self:getNPCRandomLastName())
    npc:setClass(ClassUtil.getClassName(npcType.class))
	npc:load()
    npc:setSpawn(spawn)

    local uniqueId = Utils.getUniqueId(npc, spec.npcs, "npc", 32)
    npc:setUniqueId(uniqueId)

    spec.npcs[uniqueId] = npc
    table.insert(spec.npcsSorted, uniqueId)

    self:registerLoadedNPC(npc)

end


function PlaceableNPCManager:getSpawnGroupByName(groupName)

    return self[specName].spawn[groupName]

end


function PlaceableNPCManager:onNavigationMeshLoaded()

    local npcs = self[specName].npcs

    for _, npc in pairs(npcs) do npc:onNavigationMeshLoaded() end

end


function PlaceableNPCManager:onUpdate(dt)

    self:raiseActive()

    local spec = self[specName]
    local numNpcs = #spec.npcsSorted

    if numNpcs == 0 then return end

    local ticks1 = spec.lastStateUpdateTicks + 1
    local ticks2 = spec.lastPlayerUpdateTicks + 1

    if ticks1 >= 3 then
        if spec.lastStateUpdate > numNpcs then spec.lastStateUpdate = 1 end
        ticks1 = 0
        local npc = spec.npcs[spec.npcsSorted[spec.lastStateUpdate]]
        npc:setRoom(self:getRoomForPoint(npc.x, npc.y, npc.z))
        spec.lastStateUpdate = spec.lastStateUpdate == #spec.npcsSorted and 1 or (spec.lastStateUpdate + 1)
    end

    local needsPlayerUpdate = ticks2 >= 5
    local x, y, z

    if needsPlayerUpdate then
        x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
        spec.playerCache.x, spec.playerCache.y, spec.playerCache.z = x, y, z
        ticks2 = 0
    end

    for _, npc in pairs(spec.npcs) do
        if needsPlayerUpdate then npc:setPlayerPosition(x, y, z) end
        npc:update(dt)
    end

    spec.lastStateUpdateTicks = ticks1
    spec.lastPlayerUpdateTicks = ticks2

end


function PlaceableNPCManager:getRandomNPCAppearance(preset)

    local appearance = {}

    appearance.gender = preset.gender

    if #preset.jackets  > 0 or #preset.shirts  > 0 then
        if #preset.jackets == 0 or (math.random() >= 0.5) then
            appearance.shirt = preset.shirts[math.random(#preset.shirts)]
        else
            appearance.jacket = preset.jackets[math.random(#preset.jackets)]
        end
    end

    if #preset.heads > 0 then appearance.head = preset.heads[math.random(#preset.heads)] end
    if #preset.beards > 0 and preset.beards[appearance.head] ~= nil then appearance.beard = preset.beards[appearance.head][math.random(#preset.beards[appearance.head])] end
    if #preset.pants > 0 then appearance.pants = preset.pants[math.random(#preset.pants)] end
    if #preset.hats > 0 then appearance.hat = preset.hats[math.random(#preset.hats)] end
    if #preset.glasses > 0 then appearance.glasses = preset.glasses[math.random(#preset.glasses)] end
    if #preset.shoes > 0 then appearance.shoes = preset.shoes[math.random(#preset.shoes)] end
    if #preset.hairStyles > 0 then appearance.hairStyle = preset.hairStyles[math.random(#preset.hairStyles)] end
    if #preset.hairColours > 0 then
        local n = math.random()
        for _, colour in ipairs(preset.hairColours) do
            if colour.factor < n then continue end
            appearance.hairColour = math.random(colour.min, colour.max)
            break
        end
    end

    return appearance

end

function PlaceableNPCManager:getNPCRandomFirstName(gender)

	local names = self[specName].names.first[gender]

	return (names == nil or #names == 0) and (gender == "playerM" and "John" or "Jane") or names[math.random(1, #names)]

end

function PlaceableNPCManager:getNPCRandomLastName()

	local names = self[specName].names.last

	return #names == 0 and "Smith" or names[math.random(1, #names)]

end


function PlaceableNPCManager:addNPCPath(id, path)

    self[specName].npcs[id]:setPath(path, 0)

end


function PlaceableNPCManager:getPlayerPosition()

	local cache = self[specName].playerCache
	return cache.x, cache.y, cache.z

end


function PlaceableNPCManager:visualiseNPCs()

    local spec = self[specName]
    local npcs = spec.npcs

    for _, npc in pairs(npcs) do
        local info, node = npc:visualiseNPC()
        if info == nil or node == nil or node == 0 then continue end
        local infoTable = DebugInfoTable.new()
        infoTable:createWithNodeToCamera(node, info, 1.5, 0.05)
        g_debugManager:addFrameElement(infoTable)
    end

end


function PlaceableNPCManager:consoleCommandClearNPCs()

    local spec = self[specName]

    for i = #spec.npcsSorted, 1, -1 do
        local npc = spec.npcs[spec.npcsSorted[i]]
        npc:delete()
    end

end


function PlaceableNPCManager.visualise()

    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if placeable.visualiseNPCs ~= nil then placeable:visualiseNPCs() end
    end

end


g_placeableNPCSystemProfiler:addClass(PlaceableNPCManager)