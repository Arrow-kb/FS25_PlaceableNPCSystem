NPCGraphicsComponentState = {}


local NPCGraphicsComponentState_mt = Class(NPCGraphicsComponentState)


function NPCGraphicsComponentState.new()

    local self = setmetatable({}, NPCGraphicsComponentState_mt)

    self:setDefault()

    return self

end


function NPCGraphicsComponentState:setDefault()
	self.absSpeed = 0
	self.relativeVelocityX = 0
	self.relativeVelocityY = 0
	self.relativeVelocityZ = 0
	self.rotationVelocity = 0
	self.movementDirX = 0
	self.movementDirZ = 1
	self.isIdling = true
	self.isWalking = false
	self.isRunning = false
	self.isCrouching = false
	self.isStrafeWalkMode = false
    self.isTalking = false
    self.isSitting = false
end


function NPCGraphicsComponentState:drawDebug(posX, posY, textSize)

	local renderValue = function(key)
		local value = self[key]
		local str = nil
		if type(value) == "boolean" then
			str = tostring(value)
		else
			str = string.format("%.4f", value)
		end
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX, posY, textSize, key .. " : ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(posX, posY, textSize, str)
		posY = posY - textSize - 2 * g_pixelSizeY
	end

	renderValue("absSpeed")
	renderValue("movementDirX")
	renderValue("movementDirZ")
	renderValue("relativeVelocityX")
	renderValue("relativeVelocityY")
	renderValue("relativeVelocityZ")
	renderValue("rotationVelocity")
	renderValue("isIdling")
	renderValue("isWalking")
	renderValue("isRunning")
	renderValue("isCrouching")
	renderValue("isStrafeWalkMode")
	renderValue("isTalking")
	renderValue("isSitting")
end