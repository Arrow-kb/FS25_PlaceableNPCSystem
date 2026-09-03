NPCTaskSit = {}


local NPCTaskSit_mt = Class(NPCTaskSit, NPCTask)


function NPCTaskSit.registerXMLPaths(schema, basePath)
end


function NPCTaskSit.registerSavegameXMLPaths(schema, basePath)
end


function NPCTaskSit.new()

    local self = NPCTask.new(NPCTaskSit_mt)

    return self

end


function NPCTaskSit:onNavigationMeshLoaded()

    NPCTaskSit:superClass().onNavigationMeshLoaded(self)

    self:sitInChair()

end


function NPCTaskSit:startTask()

    NPCTaskSit:superClass().startTask(self)

    self:sitInChair()

end


function NPCTaskSit:endTask()
	
	local x, y, z = getWorldTranslation(self.node)
	local dx, _, dz = localDirectionToWorld(self.node, 0, 0, 1)
	self.owner:setPosition(x, y, z)
	self.owner:setRotation(0, math.atan2(dx, dz), 0)
	self.owner:setIsSitting(false)

    NPCTaskSit:superClass().endTask(self)

end


function NPCTaskSit:sitInChair()
	
    local node = getChildAt(self.node, 0)
	local x, y, z = getWorldTranslation(node)
	local dx, _, dz = localDirectionToWorld(node, 0, 0, 1)
	self.owner:setPosition(x, y, z)
	self.owner:setRotation(0, math.atan2(dx, dz), 0)
	self.owner:setIsSitting(true)

end


PlaceableNPCManager.registerTaskClass(NPCTaskSit)