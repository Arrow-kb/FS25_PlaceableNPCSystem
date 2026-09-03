NPCTask = {}


local NPCTask_mt = Class(NPCTask)


function NPCTask.registerXMLPaths(schema, basePath)
end


function NPCTask.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#class", "Task class name")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Task type ID")
	schema:register(XMLValueType.STRING, basePath .. "#node", "Task node name")
	schema:register(XMLValueType.FLOAT, basePath .. "#time", "Task current time")
	schema:register(XMLValueType.FLOAT, basePath .. "#targetTime", "Task duration")
	schema:register(XMLValueType.BOOL, basePath .. "#started", "Task has started")
end


function NPCTask.loadTaskType(xmlFile, key, env)

    local class, errorMessage = ClassUtil.getClassObjectFromUnresolvedEnvironment(xmlFile:getValue(key .. "#class", "NPCTask"), env)

    if class == nil then
        printWarning(string.format("NPCTask.loadTaskType: task type \"%s\" could not be loaded (error: %s)", xmlFile:getValue(key .. "#id"), errorMessage))
        return
    end

    local maxTime = xmlFile:getValue(key .. "#maxTime", -1)

    local task = {
        ["class"] = class,
        ["className"] = ClassUtil.getClassName(class),
        ["group"] = xmlFile:getValue(key .. "#group"),
        ["minTime"] = xmlFile:getValue(key .. "#minTime", 30) * 1000,
        ["maxTime"] = maxTime ~= -1 and maxTime * 1000 or -1,
        ["unique"] = xmlFile:getValue(key .. "#unique", false),
        ["valid"] = true
    }

    if class ~= NPCTask and rawget(class, "loadTaskType") then class.loadTaskType(xmlFile, key, env, task) end

    return task, xmlFile:getValue(key .. "#id")

end


function NPCTask.new(customMt)

    local self = setmetatable({}, customMt or NPCTask_mt)

    self.started, self.time = false, 0

    return self

end


function NPCTask:delete()

    self:getPlaceable():setTargetOccupied(self.name, false)

end


function NPCTask:saveToXMLFile(xmlFile, key)

    xmlFile:setValue(key .. "#class", self.className)
    xmlFile:setValue(key .. "#type", self.type)
    xmlFile:setValue(key .. "#node", self.name)
    xmlFile:setValue(key .. "#time", self.time)
    xmlFile:setValue(key .. "#targetTime", self.targetTime)
    xmlFile:setValue(key .. "#started", self.started)

end


function NPCTask:loadFromXMLFile(xmlFile, key)

    self.type = xmlFile:getValue(key .. "#type")
    self.name = xmlFile:getValue(key .. "#node")
    self.time = xmlFile:getValue(key .. "#time", 0)
    self.targetTime = xmlFile:getValue(key .. "#targetTime", -1)
    self.started = xmlFile:getValue(key .. "#started", false)

end


function NPCTask:loadExtraVariablesFromType(type)
end


function NPCTask:getPlaceable()
    return self.owner:getPlaceable()
end


function NPCTask:setOwner(owner)
    self.owner = owner
end


function NPCTask:setClass(className)
	self.className = className
end


function NPCTask:getClass()
	return ClassUtil.getClassObject(self.className)
end


function NPCTask:setType(type)
    self.type = type
end


function NPCTask:getType()
    return self.type
end


function NPCTask:setTargetTime(targetTime)
    self.targetTime = targetTime
end


function NPCTask:setNode(node)
    self.node = node
    self.name = getName(node)
    self:getPlaceable():setTargetOccupied(self.name, true)
end


function NPCTask:getHasStarted()
    return self.started
end


function NPCTask:onNavigationMeshLoaded()
	
    local node = self:getPlaceable():getTargetNodeByName(self.name)
    self:setNode(node)

end


function NPCTask:startTask()

    self.started = true

end


function NPCTask:endTask()

    self.owner:endTaskFromTask()

end


function NPCTask:update(dt)

    if not self.started then return false end

    local time, targetTime = self.time, self.targetTime

    if targetTime ~= -1 then time = time + dt end

    if targetTime ~= -1 and time >= targetTime then
        self:endTask()
        return false
    end

    self.time = time

    return true

end


function NPCTask:visualiseTask(info)

    table.insert(info.content, { ["sizeFactor"] = 0.55, ["name"] = "class = ", ["value"] = self.className })
    table.insert(info.content, { ["sizeFactor"] = 0.55, ["name"] = "type = ", ["value"] = self.type })
	table.insert(info.content, { ["sizeFactor"] = 0.55, ["name"] = "time = ", ["value"] = string.format("%.2fs / %.2fs", self.time / 1000, self.targetTime / 1000) })
	table.insert(info.content, { ["sizeFactor"] = 0.55, ["name"] = "started = ", ["value"] = string.format("%s", self.started) })
	table.insert(info.content, { ["sizeFactor"] = 0.55, ["name"] = "node = ", ["value"] = string.format("%s (%d)", self.name, self.node) })

end


PlaceableNPCManager.registerTaskClass(NPCTask)