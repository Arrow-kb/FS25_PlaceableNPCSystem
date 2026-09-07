PlaceableNPCDialogue = {}
PlaceableNPCDialogue.SCHEMA = {}


local specName = "spec_npcDialogue"


g_xmlManager:addCreateSchemaFunction(function()
	PlaceableNPCDialogue.SCHEMA.CONDITIONS = XMLSchema.new("npcDialogueConditions")
	PlaceableNPCDialogue.SCHEMA.CONVERSATIONS = XMLSchema.new("npcDialogueConversations")
	PlaceableNPCDialogue.SCHEMA.WORDS = XMLSchema.new("npcDialogueWords")
end)


g_xmlManager:addInitSchemaFunction(function()
	AnimatedObject.registerXMLPaths(AnimatedMapObject.xmlSchema, "animatedObjects")
	AnimatedObject.registerSavegameXMLPaths(OnCreateObjectSystem.xmlSchemaSavegame, "onCreateLoadedObjects.object(?)")
end)


function PlaceableNPCDialogue.registerXMLPaths(placeableSchema, basePath)

	placeableSchema:setXMLSpecializationType("npcDialogue")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue#words", "Words XML file path")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue#conditions", "Conditions XML file path")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue.conversation(?)#id", "Conversation ID")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue.conversation(?)#defaultStart", "Conversation default start point")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue.conversation(?)#path", "Conversation xml file path")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue.conversation(?).npc(?)#id", "Conversation NPC type ID")
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue.conversation(?).npc(?)#start", "Conversation NPC type entry point")
    placeableSchema:setXMLSpecializationType()

    local conditionsSchema = PlaceableNPCDialogue.SCHEMA.CONDITIONS
    conditionsSchema:register(XMLValueType.STRING, "conditions.condition(?)#id", "Condition ID")
    conditionsSchema:register(XMLValueType.STRING, "conditions.condition(?)#type", "Condition value type (string/bool/number/float/dynamic)")
    conditionsSchema:register(XMLValueType.STRING, "conditions.condition(?)#target", "Condition target")
    conditionsSchema:register(XMLValueType.STRING, "conditions.condition(?)#operator", "Condition comparison operator")

    local conversationSchema = PlaceableNPCDialogue.SCHEMA.CONVERSATIONS
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?)#id", "Conversation section ID")
    conversationSchema:register(XMLValueType.BOOL, "conversation.section(?)#canEnd", "Conversation section can be end of conversation")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).text(?)", "Conversation section phrase text")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).text(?)#language", "Conversation section phrase language")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).reply#id", "Conversation section phrase reply ID")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).condition(?)#id", "Conversation section phrase condition ID")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).trigger(?)#function", "Conversation section phrase function to be triggered")

    local wordsSchema = PlaceableNPCDialogue.SCHEMA.WORDS
    wordsSchema:register(XMLValueType.STRING, "words.type(?)#id", "Word type ID")
    wordsSchema:register(XMLValueType.STRING, "words.type(?).word(?).text(?)", "Word text")
    wordsSchema:register(XMLValueType.STRING, "words.type(?).word(?).text(?)#language", "Word language")
    wordsSchema:register(XMLValueType.STRING, "words.type(?).word(?).condition(?)#id", "Word condition")

end


function PlaceableNPCDialogue.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("npcDialogue")

	schema:setXMLSpecializationType()
end


function PlaceableNPCDialogue.registerEventListeners(placeable)
	SpecializationUtil.registerEventListener(placeable, "onLoad", PlaceableNPCDialogue)
end


function PlaceableNPCDialogue.registerFunctions(placeable)
	SpecializationUtil.registerFunction(placeable, "getConversation", PlaceableNPCDialogue.getConversation)
	SpecializationUtil.registerFunction(placeable, "getPhrase", PlaceableNPCDialogue.getPhrase)
	SpecializationUtil.registerFunction(placeable, "getWord", PlaceableNPCDialogue.getWord)
	SpecializationUtil.registerFunction(placeable, "loadConditions", PlaceableNPCDialogue.loadConditions)
	SpecializationUtil.registerFunction(placeable, "loadConversation", PlaceableNPCDialogue.loadConversation)
	SpecializationUtil.registerFunction(placeable, "loadWords", PlaceableNPCDialogue.loadWords)
	SpecializationUtil.registerFunction(placeable, "resolveDialogueConditions", PlaceableNPCDialogue.resolveDialogueConditions)
end


function PlaceableNPCDialogue.prerequisitesPresent()

	print("Loaded placeable: PlaceableNPCDialogue")

	return true

end


function PlaceableNPCDialogue:onLoad()

    local spec = self[specName]
    local xmlFile = self.xmlFile

    self:loadConditions(XMLFile.load("conditions", Utils.getFilename(xmlFile:getValue("placeable.npcDialogue#conditions"), self.baseDirectory), PlaceableNPCDialogue.SCHEMA.CONDITIONS))
    self:loadWords(XMLFile.load("words", Utils.getFilename(xmlFile:getValue("placeable.npcDialogue#words"), self.baseDirectory), PlaceableNPCDialogue.SCHEMA.WORDS))

    local conversations = {}

    xmlFile:iterate("placeable.npcDialogue.conversation", function(_, key)

        local conversationXMLFile = XMLFile.loadIfExists("conversation", Utils.getFilename(xmlFile:getValue(key .. "#path", self.baseDirectory), self.baseDirectory), PlaceableNPCDialogue.SCHEMA.CONVERSATIONS)

        if conversationXMLFile == nil then return end

        local conversationId = xmlFile:getValue(key .. "#id")
        local conversation = self:loadConversation(conversationXMLFile, conversationId)
        conversationXMLFile:delete()

        local npcs = {}

        xmlFile:iterate(key .. ".npc", function(_, npcKey)
            npcs[xmlFile:getValue(npcKey .. "#id")] = xmlFile:getValue(npcKey .. "#start")
        end)


        conversations[conversationId] = {
            ["conversation"] = conversation,
            ["default"] = xmlFile:getValue(key .. "#defaultStart"),
            ["npcs"] = npcs
        }

    end)

    spec.conversations = conversations

end


function PlaceableNPCDialogue:loadConversation(xmlFile, conversationId)

    local conversation = {}

    xmlFile:iterate("conversation.section", function(_, key)
    
        local phrases = {}
        local abortLoad = false
        local sectionId = xmlFile:getValue(key .. "#id")

        xmlFile:iterate(key .. ".phrase", function(_, phraseKey)

            local conditions, triggers = {}, {}

            xmlFile:iterate(phraseKey .. ".condition", function(_, conditionKey)
                table.insert(conditions, xmlFile:getValue(conditionKey .. "#id"))
            end)

            xmlFile:iterate(phraseKey .. ".trigger", function(_, triggerKey)
                table.insert(triggers, xmlFile:getValue(triggerKey .. "#function"))
            end)

            local text

            xmlFile:iterate(phraseKey .. ".text", function(_, textKey)
                local lang = xmlFile:getValue(textKey .. "#language", "en")
                if lang == "en" then text = xmlFile:getValue(textKey) end
                if lang == g_languageShort then
                    text = xmlFile:getValue(textKey)
                    return
                end
            end)

            if text == nil then
                abortLoad = true
                printWarning(string.format("PlaceableNPCDialogue.loadConversation: could not load conversation '%s' - no suitable text language found at section '%s'", conversationId, sectionId))
                conversation = nil
                return
            end

            table.insert(phrases, {
                ["text"] = string.split(text, " "),
                ["reply"] = xmlFile:getValue(phraseKey .. ".reply#id"),
                ["conditions"] = conditions,
                ["triggers"] = triggers
            })

        end)

        if abortLoad then return end

        conversation[sectionId] = {
            ["phrases"] = phrases,
            ["end"] = xmlFile:getValue(key .. "#canEnd", false)
        }
    
    end)

    return conversation

end


function PlaceableNPCDialogue:loadWords(xmlFile)

    local spec = self[specName]
    local words = {}

    xmlFile:iterate("words.type", function(_, key)
    
        local wordType = {}
        local wordId = xmlFile:getValue(key .. "#id")

        xmlFile:iterate(key .. ".word", function(index, wordKey)
        
            local conditions = {}

            xmlFile:iterate(wordKey .. ".condition", function(_, conditionKey)
                table.insert(conditions, xmlFile:getValue(conditionKey .. "#id"))
            end)

            local text

            xmlFile:iterate(wordKey .. ".text", function(_, textKey)
                local lang = xmlFile:getValue(textKey .. "#language", "en")
                if lang == "en" then text = xmlFile:getValue(textKey) end
                if lang == g_languageShort then
                    text = xmlFile:getValue(textKey)
                    return
                end
            end)

            if text == nil then
                printWarning(string.format("PlaceableNPCDialogue.loadWords: could not load word '%s' - no suitable text language found at index '%d'", wordId, index))
            else
                table.insert(wordType, {
                    ["text"] = text,
                    ["conditions"] = conditions
                })
            end
        
        end)

        words[wordId] = wordType
    
    end)

    spec.words = words

end


function PlaceableNPCDialogue:loadConditions(xmlFile)

    local spec = self[specName]
    local conditions = {}

    xmlFile:iterate("conditions.condition", function(_, key)

        local valueType = xmlFile:getValue(key .. "#type", "string")
        local target = xmlFile:getValue(key .. "#target")
        local targetIsLength, valueIsLength, value

        if valueType == "string" then
            value = xmlFile:getString(key .. "#value")
        elseif valueType == "dynamic" then
            value = xmlFile:getString(key .. "#value")
            if value[1] == "#" then
                valueIsLength = true
                value = string.sub(value, 2)
            end
            value = string.split(value, ".")
        elseif valueType == "number" then
            value = xmlFile:getInt(key .. "#value")
        elseif valueType == "float" then
            value = xmlFile:getFloat(key .. "#value")
        elseif valueType == "bool" then
            value = xmlFile:getBool(key .. "#value")
        end

        if target[1] == "#" then
            targetIsLength = true
            target = string.sub(target, 2)
        end
            
        conditions[xmlFile:getValue(key .. "#id")] = {
            ["target"] = string.split(target, "."),
            ["value"] = value,
            ["valueType"] = valueType,
            ["op"] = xmlFile:getValue(key .. "#operator"),
            ["valueIsLength"] = valueIsLength,
            ["targetIsLength"] = targetIsLength
        }
    
    end)

    spec.conditions = conditions

end


function PlaceableNPCDialogue.resolveConversationValue(split, args, isLength)

    local value = _G
        
    for _, var in pairs(split) do

        if args[var] ~= nil then
            value = args[var]
            continue
        end

        local newValue = value[var]

        if newValue == nil then return nil end

        local valueType = type(newValue)
        if valueType ~= "table" then
            if valueType == "function" then
                value = newValue(value)
            else
                value = newValue
            end
            break
        end

        value = newValue

    end

    return isLength and #value or value

end


function PlaceableNPCDialogue:resolveDialogueConditions(conditions, args)

    if conditions == nil or #conditions == 0 then return true end

    local allConditions = self[specName].conditions

    for _, rawCondition in pairs(conditions) do

        local isNot = utf8Substr(rawCondition, 0, 1) == "!"
        local formattedCondition = isNot and utf8Substr(rawCondition, 1) or rawCondition
        local condition = allConditions[formattedCondition]

        if condition == nil or condition.target == nil then continue end

        local value = PlaceableNPCDialogue.resolveConversationValue(condition.target, args, condition.targetIsLength)

        if value == nil then return false end
            
        local targetValue

        if condition.valueType == "dynamic" then
            targetValue = PlaceableNPCDialogue.resolveConversationValue(condition.value, args, condition.valueIsLength)
        else
            targetValue = condition.value
        end

        if condition.op == nil then
            if isNot and targetValue == value then return false end
            if not isNot and targetValue ~= value then return false end
        elseif condition.op == "not_equals" then
            if isNot and targetValue ~= value then return false end
            if not isNot and targetValue == value then return false end
        elseif condition.op == "lesser" then
            if isNot and targetValue > value then return false end
            if not isNot and targetValue <= value then return false end
        elseif condition.op == "greater" then
            if isNot and targetValue < value then return false end
            if not isNot and targetValue >= value then return false end
        end

    end

    return true

end


function PlaceableNPCDialogue:getWord(wordTypesString, args)

    local words = self[specName].words

    local indexStart = string.find(wordTypesString, "{")
    local indexEnd = string.find(wordTypesString, "}", indexStart)

    if indexStart == nil or indexEnd == nil then return wordTypesString end

    local variables = string.sub(wordTypesString, indexStart + 1, indexEnd - 1)
    local wordTypes = string.split(variables, "|")

    if #wordTypes == 0 then return "" end

    local wordType = wordTypes[math.random(#wordTypes)]

    if words[wordType] == nil then

        local isLength = wordType[1] == "#"
        if isLength then wordType = string.sub(wordType, 2) end
        local target = PlaceableNPCDialogue.resolveConversationValue(string.split(wordType, "."), args, isLength)

        return (indexStart == 1 and "" or string.sub(wordTypesString, 1, indexStart - 1)) .. tostring(target) .. (indexEnd == #wordTypesString and "" or string.sub(wordTypesString, indexEnd + 1))

    end
                    
    local viablePhrases = {}

    for _, word in pairs(words[wordType]) do

        if self:resolveDialogueConditions(word.conditions, args) then table.insert(viablePhrases, word.text) end

    end

    if #viablePhrases == 0 or (#viablePhrases == 1 and viablePhrases[1] == "NONE") then return "" end

    local phrasesToDelete = {}
    
    for i, phrase in pairs(viablePhrases) do
        if phrase == "NONE" then table.insert(phrasesToDelete, i) end
    end

    for i = #phrasesToDelete, 1, -1 do table.remove(viablePhrases, phrasesToDelete[i]) end

    if #viablePhrases == 0 then return "" end

    return (indexStart == 1 and "" or string.sub(wordTypesString, indexStart - 1)) .. viablePhrases[math.random(#viablePhrases)] .. (indexEnd == #wordTypesString and "" or string.sub(wordTypesString, indexEnd + 1))

end


function PlaceableNPCDialogue:getPhrase(phrases, args)

    local viablePhrases = {}

    for _, phrase in pairs(phrases) do

        if self:resolveDialogueConditions(phrase.conditions, args) then table.insert(viablePhrases, phrase) end

    end

    if #viablePhrases == 0 then return "" end

    local phrase = table.clone(viablePhrases[math.random(#viablePhrases)], 10)
    local text = phrase.text
    local wordsToDelete = {}

    for i, word in pairs(text) do
                
        if not string.find(word, "{") and not string.find(word, "}") then continue end

        local variable = self:getWord(word, args)

        if variable == nil or variable == "" then
            table.insert(wordsToDelete, i)
            continue
        end

        local prev = text[i - 1]
        local lastChar = prev ~= nil and utf8Substr(prev, utf8Strlen(prev) - 1, 1)
        if lastChar ~= nil and (lastChar == "!" or lastChar == "." or lastChar == "?") or i == 1 then variable = utf8ToUpper(utf8Substr(variable, 0, 1)) .. (utf8Strlen(variable) > 1 and utf8Substr(variable, 1) or "") end

        text[i] = variable

    end

    for i = #wordsToDelete, 1, -1 do table.remove(text, wordsToDelete[i]) end

    return table.concat(text, " "), phrase.reply, phrase.triggers

end


function PlaceableNPCDialogue:getConversation(conversationIds, npc, listener)

    local id = conversationIds[#conversationIds]
    local baseConversation = self[specName].conversations[id]

    if baseConversation == nil then return nil end

    local sections = baseConversation.conversation
    local section = sections[baseConversation.npcs[npc:getTypeId()] or baseConversation.default]

    local conversation = {}
    local args = {
        ["placeable"] = self,
        ["self"] = npc,
        ["listener"] = listener
    }

    while true do

        if section == nil then return nil end

        local phrase, reply, triggers = self:getPhrase(section.phrases, args)

        if phrase == nil then return nil end

        table.insert(conversation, {
            ["text"] = phrase,
            ["triggers"] = triggers
        })

        if reply == nil or (section.canEnd and math.random() >= 0.5) then break end

        section = sections[reply]

    end

    return conversation, id

end


g_placeableNPCSystemProfiler:addClass(PlaceableNPCDialogue)