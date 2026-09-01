NPCGraphicsComponent = {}


local NPCGraphicsComponent_mt = Class(NPCGraphicsComponent, HumanGraphicsComponent)
local modDirectory = g_currentModDirectory


function NPCGraphicsComponent.new()

    local self = setmetatable({}, NPCGraphicsComponent_mt)
    
	self.foliageBendingId = nil
	self.foliageBendingNode = nil
	self.graphicsRootNode = nil
	self.isGraphicsRootNodeVisible = true
	self.rightShoulderCameraNode = nil
	self.style = PlayerStyle.new()
	self.baseStyle = PlayerStyle.new()
	self.model = HumanModel.new()
	self.model:loadEmpty()
	self.nameTagOffsetY = 1.9
	self.facialAnimation = nil
	self.facialAnimationEnabled = false
	self.facialAnimationMinimumDistance = FacialAnimation.MINIMUM_VISIBLE_CAMERA_DISTANCE
	self.facialAnimationMaximumDistance = FacialAnimation.MAXIMUM_VISIBLE_CAMERA_DISTANCE
	self.postAnimationCallbackHandle = nil
	self.sounds = HumanSounds.new()
	self.soundsEnabled = true

    local animation = ConditionalAnimation.new()
    local parameters = {}
	parameters.absSpeed = animation:registerParameter("absSpeed", ConditionalAnimation.TYPE.FLOAT)
	parameters.relativeVelocityX = animation:registerParameter("relativeVelocityX", ConditionalAnimation.TYPE.FLOAT)
	parameters.relativeVelocityY = animation:registerParameter("relativeVelocityY", ConditionalAnimation.TYPE.FLOAT)
	parameters.relativeVelocityZ = animation:registerParameter("relativeVelocityZ", ConditionalAnimation.TYPE.FLOAT)
	parameters.rotationVelocity = animation:registerParameter("rotationVelocity", ConditionalAnimation.TYPE.FLOAT)
	parameters.movementDirX = animation:registerParameter("movementDirX", ConditionalAnimation.TYPE.FLOAT)
	parameters.movementDirZ = animation:registerParameter("movementDirZ", ConditionalAnimation.TYPE.FLOAT)
	parameters.isIdling = animation:registerParameter("isIdling", ConditionalAnimation.TYPE.BOOL)
	parameters.isWalking = animation:registerParameter("isWalking", ConditionalAnimation.TYPE.BOOL)
	parameters.isRunning = animation:registerParameter("isRunning", ConditionalAnimation.TYPE.BOOL)
	parameters.isCrouching = animation:registerParameter("isCrouching", ConditionalAnimation.TYPE.BOOL)
	parameters.isStrafeWalkMode = animation:registerParameter("isStrafeWalkMode", ConditionalAnimation.TYPE.BOOL)
	parameters.isTalking = animation:registerParameter("isTalking", ConditionalAnimation.TYPE.BOOL)
	parameters.isSitting = animation:registerParameter("isSitting", ConditionalAnimation.TYPE.BOOL)
	animation:setSpecialParameterIds(parameters.absSpeed, parameters.rotationVelocity)
    
    self.animation = animation
    self.animationParameters = parameters
	self.defaultState = NPCGraphicsComponentState.new()
	self:defaultAllParameters()

    return self

end


function NPCGraphicsComponent:loadAnimation()

	self.animation:unload()
	local model = self.model
	local skeletonNode = model:getSkeletonNode()

	if skeletonNode ~= nil and 0 < getNumOfChildren(skeletonNode) then
		local animNode = g_animCache:getNode(AnimationCache.CHARACTER)
		self:defaultAllParameters()
		self.animation:load(skeletonNode, modDirectory .. "xml/animation/" .. self.gender .. ".xml", "conditionalAnimation", animNode)
	end

end


function NPCGraphicsComponent:applyState(state)

	local animation = self.animation
	local parameters = self.animationParameters

	animation:setParameter(parameters.absSpeed, state.absSpeed)
	animation:setParameter(parameters.relativeVelocityX, state.relativeVelocityX)
	animation:setParameter(parameters.relativeVelocityY, state.relativeVelocityY)
	animation:setParameter(parameters.relativeVelocityZ, state.relativeVelocityZ)
	animation:setParameter(parameters.rotationVelocity, state.rotationVelocity)
	animation:setParameter(parameters.movementDirX, state.movementDirX)
	animation:setParameter(parameters.movementDirZ, state.movementDirZ)
	animation:setParameter(parameters.isStrafeWalkMode, state.isStrafeWalkMode)
	animation:setParameter(parameters.isIdling, state.isIdling)
	animation:setParameter(parameters.isWalking, state.isWalking)
	animation:setParameter(parameters.isRunning, state.isRunning)
	animation:setParameter(parameters.isCrouching, state.isCrouching)
	animation:setParameter(parameters.isTalking, state.isTalking)
	animation:setParameter(parameters.isSitting, state.isSitting)

	self.sounds:applyState(state)

end


function NPCGraphicsComponent:setModelGender(gender)
	self.gender = gender
end


function NPCGraphicsComponent:debugDraw(x, y, textSize, debugDrawModel)
	if (debugDrawModel or debugDrawModel == nil) and self.model ~= nil then
		self.model:debugDraw(x, y, textSize)
	end
	return y
end