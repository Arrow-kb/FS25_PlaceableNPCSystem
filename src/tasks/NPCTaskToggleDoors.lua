NPCTaskToggleDoors = {}


local NPCTaskToggleDoors_mt = Class(NPCTaskToggleDoors, NPCTask)


function NPCTaskToggleDoors.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".task(?).doors.door(?)#saveId", "Door animated object save ID")
end


function NPCTaskToggleDoors.registerSavegameXMLPaths(schema, basePath)
end


function NPCTaskToggleDoors.loadTaskType(xmlFile, key, env, task)

    local doors = {}

    xmlFile:iterate(key .. ".doors.door", function(_, doorKey)
        table.insert(doors, xmlFile:getValue(doorKey .. "#saveId"))
    end)

    task.doors = doors

end


function NPCTaskToggleDoors.new()

    local self = NPCTask.new(NPCTaskToggleDoors_mt)

    return self

end


function NPCTaskToggleDoors:loadExtraVariablesFromType(type)

    NPCTaskToggleDoors:superClass().loadExtraVariablesFromType(self, type)

    self.doors = type.doors

end


function NPCTaskToggleDoors:setNode(node)

    NPCTaskToggleDoors:superClass().setNode(self, node)
    self:getPlaceable():setNPCTaskIsValid(self.type, false)

end


function NPCTaskToggleDoors:startTask()

    NPCTaskToggleDoors:superClass().startTask(self)
	
	local placeable = self:getPlaceable()

    for _, saveId in pairs(self.doors) do
        local animatedObject = placeable:getAnimatedObjectBySaveId(saveId)
        if animatedObject ~= nil then animatedObject:setDirection(0) end
    end

end


PlaceableNPCManager.registerTaskClass(NPCTaskToggleDoors)