NPCTaskToggleLights = {}


local NPCTaskToggleLights_mt = Class(NPCTaskToggleLights, NPCTask)


function NPCTaskToggleLights.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".task(?).lights.group(?)#index", "Lights group index")
end


function NPCTaskToggleLights.registerSavegameXMLPaths(schema, basePath)
end


function NPCTaskToggleLights.loadTaskType(xmlFile, key, env, task)

    local lights = {}

    xmlFile:iterate(key .. ".lights.group", function(_, groupKey)
        table.insert(lights, xmlFile:getValue(groupKey .. "#index"))
    end)

    task.lights = lights

end


function NPCTaskToggleLights.new()

    local self = NPCTask.new(NPCTaskToggleLights_mt)

    return self

end


function NPCTaskToggleLights:loadExtraVariablesFromType(type)

    NPCTaskToggleLights:superClass().loadExtraVariablesFromType(self, type)

    self.lights = type.lights

end


function NPCTaskToggleLights:endTask()
	
	local placeable = self:getPlaceable()

    for _, index in pairs(self.lights) do placeable:setGroupIsActive(index) end

    NPCTaskToggleLights:superClass().endTask(self)

end


PlaceableNPCManager.registerTaskClass(NPCTaskToggleLights)