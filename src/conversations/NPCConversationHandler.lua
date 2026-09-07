NPCConversationHandler = {}


local NPCConversationHandler_mt = Class(NPCConversationHandler)


function NPCConversationHandler.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#index", "Conversation current section index")
    schema:register(XMLValueType.BOOL, basePath .. "#isTalking", "NPC is currently talking")
    schema:register(XMLValueType.STRING, basePath .. "#id", "Conversation ID")
    schema:register(XMLValueType.STRING, basePath .. ".section(?)#text", "Conversation section text")
    schema:register(XMLValueType.STRING, basePath .. ".section(?).trigger(?)#function", "Conversation section function to be triggered")
end


function NPCConversationHandler.new(owner)

    local self = setmetatable({}, NPCConversationHandler_mt)

    self.owner = owner
 
    return self

end


function NPCConversationHandler:delete()
    if self.speechBubble ~= nil then self.speechBubble:delete() end
end


function NPCConversationHandler:saveToXMLFile(xmlFile, key)

    if self.conversation == nil then return end

    xmlFile:setValue(key .. "#index", self.index)
    xmlFile:setValue(key .. "#isTalking", self.isTalking)
    xmlFile:setValue(key .. "#id", self.conversationId)

    for i, section in pairs(self.conversation) do
        local sectionKey = string.format("%s.section(%d)", key, i - 1)
        xmlFile:setValue(sectionKey .. "#text", section.text)
        for j, trigger in pairs(section.triggers) do
            xmlFile:setValue(string.format("%s.trigger(%d)#function", sectionKey, j - 1), trigger)
        end
    end

end


function NPCConversationHandler:loadFromXMLFile(xmlFile, key)

    self.index = xmlFile:getValue(key .. "#index")
    
    if self.index == nil then return end

    self.conversationId = xmlFile:getValue(key .. "#id")
    self.isTalking = xmlFile:getValue(key .. "#isTalking")
    self.owner:setIsTalking(self.isTalking)

    self.conversation = {}

    xmlFile:iterate(key .. ".section", function(_, sectionKey)
        local triggers = {}
        xmlFile:iterate(sectionKey .. ".trigger", function(_, triggerKey)
            table.insert(triggers, xmlFile:getValue(triggerKey .. "#function"))
        end)
        table.insert(self.conversation, {
            ["text"] = xmlFile:getValue(sectionKey .. "#text"),
            ["triggers"] = triggers
        })
    end)

end


function NPCConversationHandler:createSpeechBubble(headNode)

    self.speechBubble = SpeechBubble.new()
	self.speechBubble:createFromHeadNode(headNode)

end


function NPCConversationHandler:setListener(npc)
    self.listener = npc
end


function NPCConversationHandler:getId()
    return self.conversationId
end


function NPCConversationHandler:getHasConversation()
    return self.conversation ~= nil
end


function NPCConversationHandler:endConversation()
    self:setConversation()
end


function NPCConversationHandler:setConversation(conversation, id, listener)
    self.conversation = conversation
    self.conversationId = id
    self.isTalking = false
    self:setListener(listener)
end


function NPCConversationHandler:endConversationForBoth()
    self.listener:endConversation()
    self.owner:endConversation()
end


function NPCConversationHandler:replyToConversation(index)

    local section = self.conversation[index]

    if section == nil then
        self:endConversationForBoth()
        return
    end

    self.owner:setIsTalking(true)
    self.isTalking = true
    self.index = index
    self:setText(section.text)

    local args = {
        ["placeable"] = self.owner:getPlaceable(),
        ["self"] = self.owner,
        ["listener"] = self.listener
    }

    for _, trigger in pairs(section.triggers) do
        PlaceableNPCDialogue.resolveConversationValue(string.split(trigger, "."), args, false)
    end

end


function NPCConversationHandler:setText(text)
    self.time = math.clamp(utf8Strlen(text) * 100, 1500, 6000)
    self.speechBubble:setText(text, self.time)
end


function NPCConversationHandler:setPlayerPosition(x, y, z)
    if self.speechBubble ~= nil then self.speechBubble:setReferencePosition(x, y, z) end
end


function NPCConversationHandler:update(dt)

	if self.speechBubble ~= nil then self.speechBubble:update(dt) end

    if not self.isTalking then return end

    self.time = self.time - dt

    if self.time <= 0 then
        self.listener:replyToConversation(self.index + 1)
        self.isTalking = false
        self.owner:setIsTalking(false)
    end

end


function NPCConversationHandler:visualiseConversation(info)

    if self.conversation == nil then return end

    table.insert(info, { ["title"] = "Conversation", ["content"] = {} })

    table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "id = ", ["value"] = self.conversationId })
    table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "talking = ", ["value"] = self.isTalking })
    table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "listener = ", ["value"] = self.listener:getUniqueId() })
    if self.isTalking then
        local duration = math.clamp(utf8Strlen(self.conversation[self.index].text) * 100, 1500, 6000) / 1000
        table.insert(info[#info].content, { ["sizeFactor"] = 0.55, ["name"] = "time = ", ["value"] = string.format("%.2fs/%.2f", math.clamp(duration - self.time / 1000, 0, 10), duration) })
    end

end