PlaceableNPC = {}

local PlaceableNPC_mt = Class(PlaceableNPC)

PlaceableNPCManager.registerNPCClass(PlaceableNPC)

g_xmlManager:addCreateSchemaFunction(function()
	PlaceableNPC.xmlSchema = XMLSchema.new("auctionNPC")
end)

g_xmlManager:addInitSchemaFunction(function()
	PlayerStyle.registerSavegameXMLPaths(PlaceableNPC.xmlSchema, "playerStyle")
end)


function PlaceableNPC.registerXMLPaths(schema, basePath) end


function PlaceableNPC.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "NPC name")
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "NPC unique id")
	schema:register(XMLValueType.STRING, basePath .. "#class", "NPC class")
	schema:register(XMLValueType.INT, basePath .. "#preset", "NPC appearance preset")
	schema:register(XMLValueType.VECTOR_3, basePath .. "#position", "NPC world translation")
	schema:register(XMLValueType.VECTOR_3, basePath .. "#rotation", "NPC world rotation")
	schema:register(XMLValueType.STRING, basePath .. "#gender", "NPC gender")
	schema:register(XMLValueType.BOOL, basePath .. ".state#isTurning", "NPC is turning")
	schema:register(XMLValueType.BOOL, basePath .. ".state#isIdle", "NPC is idle")
	schema:register(XMLValueType.FLOAT, basePath .. ".state#turnTarget", "NPC turn target")
	schema:register(XMLValueType.INT, basePath .. ".path#target", "NPC path current target")
	schema:register(XMLValueType.FLOAT, basePath .. ".path#direction", "NPC path target direction")
	schema:register(XMLValueType.FLOAT, basePath .. ".path#nextDirection", "NPC path next direction")
	schema:register(XMLValueType.FLOAT, basePath .. ".path#endDirection", "NPC path end direction")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".path.point(?)", "NPC path world translation vector")
	schema:register(XMLValueType.STRING, basePath .. ".task#type", "NPC task type")
	schema:register(XMLValueType.FLOAT, basePath .. ".task#time", "NPC task time")
	schema:register(XMLValueType.FLOAT, basePath .. ".task#targetTime", "NPC task target time")
	schema:register(XMLValueType.STRING, basePath .. ".task#node", "NPC task node")
	schema:register(XMLValueType.BOOL, basePath .. ".task#started", "NPC task has started")
	PlayerStyle.registerSavegameXMLPaths(schema, basePath .. ".appearance")
end


function PlaceableNPC.new(owner, customMt)

	local self = setmetatable({}, customMt or PlaceableNPC_mt)

	self.owner = owner
	self.room = "outside"

	self.playerGraphics = NPCGraphicsComponent.new()
	self.playerGraphics:setIsFacialAnimationEnabled(true)
	self.playerGraphics:setSoundsEnabled(false)
	self.speed = 0.5

	self.isWalking = false
	self.isIdle = true
	self.turning = false

	self.x, self.y, self.z, self.rx, self.ry, self.rz = 0, 0, 0, 0, 0, 0

	self.state = NPCGraphicsComponentState.new()
	self.state.isWalking = false
	self.state.isRunning = false
	self.state.isIdling = true
	self.state.absSpeed = 0

	return self

end


function PlaceableNPC:delete()

	self.owner:registerUnloadedNPC(self)

	if self.node ~= nil and self.node ~= 0 then removeFromPhysics(self.node) end
	self.speechBubble:delete()
	self.playerGraphics:delete()
	g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

end


function PlaceableNPC:saveToXMLFile(xmlFile, key)

	if self.name ~= nil then xmlFile:setValue(key .. "#name", self.name) end
	xmlFile:setValue(key .. "#class", self.className)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#position", self.x, self.y, self.z)
	xmlFile:setValue(key .. "#rotation", self.rx, self.ry, self.rz)
	xmlFile:setValue(key .. "#gender", self.gender)
	xmlFile:setValue(key .. "#preset", self.preset)
	xmlFile:setValue(key .. ".state#isIdle", self.isIdle)
	xmlFile:setValue(key .. ".state#isTurning", self.isTurning)
	xmlFile:setValue(key .. ".state#turnTarget", self.turnTarget)

	local task, path = self.task, self.path

	if path ~= nil then

		xmlFile:setValue(key .. ".path#target", path.target)
		xmlFile:setValue(key .. ".path#direction", path.direction)
		xmlFile:setValue(key .. ".path#nextDirection", path.nextDirection or path.direction)
		xmlFile:setValue(key .. ".path#endDirection", path.endDirection or path.direction)
		
		for i, point in pairs(path.path) do
			xmlFile:setValue(string.format("%s.path.point(%d)", key, i - 1), point.x, point.y, point.z)
		end

	end

	if task ~= nil then

		xmlFile:setValue(key .. ".task#type", task.type)
		xmlFile:setValue(key .. ".task#time", task.time)
		xmlFile:setValue(key .. ".task#targetTime", task.targetTime)
		xmlFile:setValue(key .. ".task#node", task.name)
		xmlFile:setValue(key .. ".task#started", task.started)

	end

	self.playerStyle:saveToXMLFile(xmlFile, key .. ".appearance")

end


function PlaceableNPC:loadFromXMLFile(xmlFile, key)

	self.name = xmlFile:getValue(key .. "#name", nil)
	self.uniqueId = xmlFile:getValue(key .. "#uniqueId")
	self.x, self.y, self.z = xmlFile:getValue(key .. "#position")
	self.rx, self.ry, self.rz = xmlFile:getValue(key .. "#rotation")
	self.gender = xmlFile:getValue(key .. "#gender")
	self.preset = xmlFile:getValue(key .. "#preset")
	self.isIdle = xmlFile:getValue(key .. ".state#isIdle", false)
	self.isTurning = xmlFile:getValue(key .. ".state#isTurning", false)
	self.turnTarget = xmlFile:getValue(key .. ".state#turnTarget", 0)

	self.path, self.task = nil, nil

	if xmlFile:hasProperty(key .. ".path") then

		local target = xmlFile:getValue(key .. ".path#target")
		local direction = xmlFile:getValue(key .. ".path#direction")
		local nextDirection = xmlFile:getValue(key .. ".path#nextDirection", direction)
		local endDirection = xmlFile:getValue(key .. ".path#endDirection", direction)

		local path = {}

		xmlFile:iterate(key .. ".path.point", function(_, pointKey)
			local x, y, z = xmlFile:getValue(pointKey)
			table.insert(path, { ["x"] = x, ["y"] = y, ["z"] = z })
		end)

		self.path = {
			["target"] = target,
			["direction"] = direction,
			["nextDirection"] = nextDirection,
			["endDirection"] = endDirection,
			["path"] = path
		}

	end

	if xmlFile:hasProperty(key .. ".task") then

		self.task = {
			["name"] = xmlFile:getValue(key .. ".task#node"),
			["type"] = xmlFile:getValue(key .. ".task#type"),
			["time"] = xmlFile:getValue(key .. ".task#time", 0),
			["targetTime"] = xmlFile:getValue(key .. ".task#targetTime", -1),
			["started"] = xmlFile:getValue(key .. ".task#started", false)
		}

	end

	self.playerStyle = PlayerStyle.new()
	self.playerStyle:loadFromXMLFile(xmlFile, key .. ".appearance")

end


function PlaceableNPC:onNavigationMeshLoaded()

	local task = self.task

	if task == nil then return end

	task.node = task.owner:getTargetNodeByName(task.name)
	task.owner:setTargetOccupied(task.name)

end


function PlaceableNPC:setClass(className)
	self.className = className
end


function PlaceableNPC:getClass()
	return ClassUtil.getClassObject(self.className)
end


function PlaceableNPC:setAppearance(appearance)

	self.gender = appearance.gender or "playerM"
	self.head = appearance.head or "head01"
	self.jacket = appearance.jacket
	self.shirt = appearance.shirt
	self.pants = appearance.pants
	self.beard = appearance.beard
	self.hair = appearance.hairStyle
	self.hairColour = appearance.hairColour or 1
	self.glasses = appearance.glasses
	self.hat = appearance.hat
	self.shoes = appearance.shoes

end


function PlaceableNPC:setAppearancePreset(preset)
	self.preset = preset
end


function PlaceableNPC:getAppearancePreset()
	return self.preset
end


function PlaceableNPC:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end


function PlaceableNPC:getUniqueId()
	return self.uniqueId
end


function PlaceableNPC:load()

	self.i3dFilename = Utils.getFilename("dataS/character/npc/npcBase.i3d")
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, true, self.onI3DFileLoaded, self, nil)

	self.playerGraphics:setModelGender(self.gender)
	self.playerGraphics:initialize()
	link(getRootNode(), self.playerGraphics.graphicsRootNode)

	if self.playerStyle == nil then

		local xmlFile = XMLFile.create("tempAuctionNPC", g_modSettingsDirectory .. "tempNPC.xml", "playerStyle", PlaceableNPC.xmlSchema)

		xmlFile:setString("playerStyle#filename", string.format("dataS/character/%s/%s.xml", self.gender, self.gender))

		xmlFile:setInt("playerStyle.bottom#color", 1)
		xmlFile:setString("playerStyle.bottom#name", self.pants)

		xmlFile:setInt("playerStyle.face#color", 1)
		xmlFile:setString("playerStyle.face#name", self.head)

		xmlFile:setInt("playerStyle.top#color", 1)
		xmlFile:setString("playerStyle.top#name", self.jacket or self.shirt)

		xmlFile:setInt("playerStyle.hairStyle#color", self.hairColour)
		xmlFile:setString("playerStyle.hairStyle#name", self.hair)

		xmlFile:setInt("playerStyle.footwear#color", 1)
		xmlFile:setString("playerStyle.footwear#name", self.shoes)

		if self.beard ~= nil then
			xmlFile:setInt("playerStyle.beard#color", self.hairColour)
			xmlFile:setString("playerStyle.beard#name", self.beard)
		end

		if self.glasses ~= nil then
			xmlFile:setInt("playerStyle.glasses#color", 1)
			xmlFile:setString("playerStyle.glasses#name", self.glasses)
		end

		if self.hat ~= nil then
			xmlFile:setInt("playerStyle.headgear#color", 1)
			xmlFile:setString("playerStyle.headgear#name", self.hat)
		end

		xmlFile:save(false, true)
		self.playerStyle = PlayerStyle.new()
		self.playerStyle:loadFromXMLFile(xmlFile, "playerStyle")
		xmlFile:delete()

	end

	self.playerGraphics:setStyleAsync(self.playerStyle, self.loadCharacterFinished, self, {})

end


function PlaceableNPC:loadCharacterFinished(state)

	if state == HumanModelLoadingState.OK then

		self.playerGraphics:defaultAllParameters()
		self.speechBubble = SpeechBubble.new()
		self.speechBubble:createFromHeadNode(self.playerGraphics.model.thirdPersonHeadNode)
		self:updatePosition()

		--local animation = self.playerGraphics.animation
		--local skeletonNode = animation.skeletonNode
		--local animCharsetId = getAnimCharacterSet(getChildAt(skeletonNode, 0))

		--for i = 0, getAnimNumOfClips(animCharsetId) - 1 do
			--local clip = getAnimClipName(animCharsetId, i)
			--print(clip)
		--end

	else

		if state == HumanModelLoadingState.CANCELED then
			Logging.info("Loading player model canceled")
		else
			Logging.error("Loading player model failed")
		end

		self.playerGraphics:delete()
		self.playerGraphics = nil

	end

end


function PlaceableNPC:onI3DFileLoaded(node, state)

	if state == LoadI3DFailedReason.NONE then

		link(getRootNode(), node)
		self.node = node
		setClipDistance(node, 300)
		self:updatePosition()

	end

end


function PlaceableNPC:setPath(path, endDirection)

    self.path = {
		["target"] = 2,
		["path"] = path,
		["direction"] = math.atan2(path[2].x - self.x, path[2].z - self.z),
		["endDirection"] = endDirection
	}

	self.path.nextDirection = #path > 2 and math.atan2(path[3].x - path[2].x, path[3].z - path[2].z) or path.direction

	if self.ry >= self.path.direction -0.025 and self.ry <= self.path.direction + 0.025 then
		self.isTurning = false
		self.turnTarget = self.ry
		self.isIdle = false
	else
		self.isTurning = true
		self.turnTarget= self.path.direction
		self.isIdle = true
	end

end


function PlaceableNPC:setRoom(room)
	self.room = room
end


function PlaceableNPC:findTask()



end


function PlaceableNPC:onPathFound(path, endDirection, node)

	if path == nil then
		self.taskQueueRequest = nil
		self.pendingTask = nil
		return
	end

	local task = self.pendingTask

	if task == nil then return end

	self:setPath(path, endDirection)
	self:setTask(node, task.type, task.targetTime)
	self.pendingTask = nil
	self.taskQueueRequest = nil

end


function PlaceableNPC:getPathByType(taskType, targetTime)

	local taskRequestId = self.owner:getPathByType(taskType, self.x, self.y, self.z, self.onPathFound, self)

	if taskRequestId == nil then return false end

	self.taskRequestId = taskRequestId
	self:setPendingTask(taskType, targetTime)

	return true

end


function PlaceableNPC:setPendingTask(taskType, targetTime)

	self.pendingTask = {
		["type"] = taskType,
		["targetTime"] = targetTime
	}

end


function PlaceableNPC:setTask(node, type, targetTime)

	self.task = {
		["name"] = getName(node),
		["node"] = node,
		["type"] = type,
		["time"] = 0,
		["targetTime"] = targetTime,
		["started"] = false
	}

end


function PlaceableNPC:endTask()

	self.lastTask = self.task.type
	self.task = nil

	self.state.isSitting, self.isIdle = false, true

end


function PlaceableNPC:onDestinationReached()

	local direction = self.path.endDirection
	local ry = self.ry

	self.isTurning = false

	if ry < direction - 0.025 or ry > direction + 0.025 then
		self.turnTarget = direction
		self.isTurning = true
	end

	self.isWalking, self.isIdle = false, true
	self.path = nil

	if self.task == nil then return end

	self.task.started = true

end


function PlaceableNPC:updatePosition()

	self.isActive = true
	
	if self.isActive then

		addToPhysics(self.node)

		if self.node ~= nil then
			setWorldTranslation(self.node, self.x, self.y, self.z)
			setWorldRotation(self.node, self.rx, self.ry, self.rz)
		end

		if self.playerGraphics ~= nil then
			self.playerGraphics:setModelPosition(self.x, self.y, self.z)
			self.playerGraphics:setModelRotation(self.rx, self.ry, self.rz)
		end

	elseif self.node ~= nil then
		removeFromPhysics(self.node)
	end

end


function PlaceableNPC:update(dT)

	local task = self.task

	if task ~= nil then

		if task.targetTime ~= -1 then
			task.time = task.time + dT
			if task.time >= task.targetTime then self:endTask() end
		end

	end

	if self.isIdle and not self.isTurning and task == nil and self.taskQueueRequest == nil then
		self:findTask()
	end

	local path = self.path

	if not self.isIdle and path ~= nil then

		local x, y, z = self.x, self.y, self.z
		local target = path.path[path.target]
		local tx, ty, tz = target.x, target.y, target.z
		local dx, dy, dz = tx - x, ty - y, tz - z
		local distance = math.abs(dx) + math.abs(dy) + math.abs(dz)

		local stepX, stepY, stepZ = 0, 0, 0

		if distance > 0 then

			stepX, stepZ = MathUtil.getDirectionFromYRotation(self.ry)
			stepY = dy / distance
	
			x = x + stepX * dT * 0.0025 * self.speed
			y = y + stepY * dT * 0.0025 * self.speed
			z = z + stepZ * dT * 0.0025 * self.speed

			distance = math.abs(tx - x) + math.abs(ty - y) + math.abs(tz - z)

		end

		self.isWalking = stepX ~= 0 or stepY ~= 0 or stepZ ~= 0
		self.isIdle = not self.isWalking

		if self.isWalking then

			self.state.movementDirX = stepX
			self.state.movementDirZ = stepZ
			local nt = path.path[path.target + 1]

			if path.target < #path.path and distance <= 0.375 then
				local requiredRotation = math.atan2(nt.x - x, nt.z - z)
				if self.ry ~= requiredRotation then
					self.turnTarget = requiredRotation
					self.isTurning = true
				end
			elseif path.target < #path.path then
				local requiredRotation = math.atan2(tx - x, tz - z)
				if self.ry ~= requiredRotation then
					self.turnTarget = requiredRotation
					self.isTurning = true
				end
			end

		end

		self.distance = distance

		local hasReachedDestination = false

		if (stepY <= 0.02 and stepY >= -0.02 and distance <= 0.375) or distance <= 0.15 then

			path.target = path.target + 1

			x = math.clamp(x, tx - 0.02, tx + 0.02)
			y = ty
			z = math.clamp(z, tz - 0.02, tz + 0.02)

			local newTarget = path.path[path.target]

			if math.abs(newTarget.y - y) < 0.05 then y = newTarget.y end
			
			self.path.direction = path.nextDirection

			if path.target == #path.path then
				self.path.nextDirection = path.endDirection
				if self.ry ~= path.endDirection then
					self.isTurning = true
					self.turnTarget = path.endDirection
				end
				hasReachedDestination = true
			else
				local ct, nt = path.path[path.target], path.path[path.target + 1]
				self.path.nextDirection = math.atan2(nt.x - ct.x, nt.z - ct.z)
				if self.ry ~= path.direction then
					self.isTurning = true
					self.turnTarget = path.direction
				end
			end

		end

		self.x, self.y, self.z = x, y, z

		if hasReachedDestination then self:onDestinationReached() end

	end

	self.state.rotationVelocity = 0

	if self.isTurning then

		local ry, turnTarget = math.deg(self.ry), math.deg(self.turnTarget)
		local delta = self.isIdle and 0.1 or 0.25

		ry = ry % 360
		turnTarget = turnTarget % 360

		if ry < 0 then ry = ry + 180 end
		if turnTarget < 0 then turnTarget = turnTarget + 180 end

		if ry < turnTarget then

			if math.abs(ry - turnTarget) < 180 then
				ry = ry + dT * delta
				self.state.rotationVelocity = 0.1
			else
				ry = ry - dT * delta
				self.state.rotationVelocity = -0.1
			end

		else

			if math.abs(ry - turnTarget) < 180 then
				ry = ry - dT * delta
				self.state.rotationVelocity = -0.1
			else
				ry = ry + dT * delta
				self.state.rotationVelocity = 0.1
			end

		end

		if ry > 180 then ry = ry - 360 end
		self.ry = math.rad(ry)

		if self.ry <= self.turnTarget + 0.1 and self.ry >= self.turnTarget - 0.1 then
			self.ry = self.turnTarget
			self.turnTarget = 0
			self.isTurning = false
			if self.isIdle and path ~= nil and path.target ~= #path.path then self.isIdle = false end
		end

	end

	self.isWalking = not self.isIdle

	self:updatePosition()

	if self.playerGraphics ~= nil then

		self.state.isWalking = self.isWalking
		self.state.isIdling = self.isIdle
		self.state.absSpeed = (self.isIdle and 0) or (self.isWalking and self.speed)

		self.playerGraphics:applyState(self.state)
		self.playerGraphics:update(dT)

	end

	if self.speechBubble == nil then return end

	self.speechBubble:setReferencePosition(self.owner:getPlayerPosition())
	self.speechBubble:update(dT)

end


function PlaceableNPC:setName(name)

	self.name = name

end


function PlaceableNPC:getName()

	return self.name

end


function PlaceableNPC:speak(text)

	self.speechBubble:setText(text, math.clamp(utf8Strlen(text) * 100, 1000, 6000))

end


function PlaceableNPC:visualiseNPC()

	local info = {
		{ ["title"] = "Movement", ["content"] = {} }
	}

	local task, path = self.task, self.path

	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "class = ", ["value"] = self.className })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "uniqueId = ", ["value"] = self.uniqueId })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "room = ", ["value"] = self.room })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "isIdle = ", ["value"] = tostring(self.isIdle) })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "isWalking = ", ["value"] = tostring(self.isWalking) })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "isTurning = ", ["value"] = tostring(self.isTurning) })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "position = ", ["value"] = string.format("%.3f %.3f %.3f", self.x, self.y, self.z) })
	table.insert(info[1].content, { ["sizeFactor"] = 0.55, ["name"] = "rotation = ", ["value"] = string.format("%.3f %.3f %.3f", self.rx, self.ry, self.rz) })

	if task ~= nil then

		table.insert(info, { ["title"] = "Task", ["content"] = {} })

		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "type = ", ["value"] = task.type })
		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "time = ", ["value"] = string.format("%.2fs / %.2fs", task.time / 1000, task.targetTime / 1000) })
		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "node = ", ["value"] = string.format("%s (%d)", task.name, task.node) })

	end

	if path ~= nil then

		table.insert(info, { ["title"] = "Path", ["content"] = {} })

		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "target = ", ["value"] = string.format("%s/%s", path.target, #path.path) })
		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "distance = ", ["value"] = string.format("%.3f", self.distance or 0) })
		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "direction = ", ["value"] = string.format("%.3f", path.direction) })
		table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "nextDirection = ", ["value"] = string.format("%.3f", path.nextDirection) })

		for i, point in pairs(path.path) do
			table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = string.format("%d) point = ", i), ["value"] = string.format("%.3f %.3f %.3f", point.x, point.y, point.z) })
		end

	end

	local infoTable = DebugInfoTable.new()
	infoTable:createWithNodeToCamera(self.playerGraphics.model.thirdPersonHeadNode, info, 1.5, 0.05)
	g_debugManager:addFrameElement(infoTable)

	self.playerGraphics:debugDraw(0.2, 0.4, 0.01, true)
	self.playerGraphics:debugDrawAnimator(0.2, 0.2, 0.01, true)

end