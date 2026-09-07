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
	placeableSchema:register(XMLValueType.STRING, basePath .. ".npcDialogue.conversation(?)#folder", "Folder containing conversation xml file")
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
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).text", "Conversation section phrase text")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).reply#id", "Conversation section phrase reply ID")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).condition(?)#value", "Conversation section phrase condition ID")
    conversationSchema:register(XMLValueType.STRING, "conversation.section(?).phrase(?).trigger(?)#function", "Conversation section phrase function to be triggered")

    local wordsSchema = PlaceableNPCDialogue.SCHEMA.WORDS
    wordsSchema:register(XMLValueType.STRING, "words.type(?)#id", "Word type ID")
    wordsSchema:register(XMLValueType.STRING, "words.type(?).word(?).text", "Word text")
    wordsSchema:register(XMLValueType.STRING, "words.type(?).word(?).condition(?)#value", "Word condition")

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

        local folderPath = Utils.getFilename(xmlFile:getValue(key .. "#folder", self.baseDirectory), self.baseDirectory) .. "/"
        local filePath = fileExists(folderPath .. g_languageShort .. ".xml") and (folderPath .. g_languageShort .. ".xml") or (folderPath .. "en.xml")
        local conversationXMLFile = XMLFile.loadIfExists("conversation", filePath, PlaceableNPCDialogue.SCHEMA.CONVERSATIONS)

        if conversationXMLFile == nil then return end

        local conversation = self:loadConversation(conversationXMLFile)
        conversationXMLFile:delete()

        local npcs = {}

        xmlFile:iterate(key .. ".npc", function(_, npcKey)
            npcs[xmlFile:getValue(npcKey .. "#id")] = xmlFile:getValue(npcKey .. "#start")
        end)


        conversations[xmlFile:getValue(key .. "#id")] = {
            ["conversation"] = conversation,
            ["default"] = xmlFile:getValue(key .. "#defaultStart"),
            ["npcs"] = npcs
        }

    end)

    spec.conversations = conversations

end


function PlaceableNPCDialogue:loadConversation(xmlFile)

    local conversation = {}

    xmlFile:iterate("conversation.section", function(_, key)
    
        local phrases = {}

        xmlFile:iterate(key .. ".phrase", function(_, phraseKey)

            local conditions, triggers = {}, {}

            xmlFile:iterate(phraseKey .. ".condition", function(_, conditionKey)
                table.insert(conditions, xmlFile:getValue(conditionKey .. "#value"))
            end)

            xmlFile:iterate(phraseKey .. ".trigger", function(_, triggerKey)
                table.insert(triggers, xmlFile:getValue(triggerKey .. "#function"))
            end)

            table.insert(phrases, {
                ["text"] = string.split(xmlFile:getValue(phraseKey .. ".text"), " "),
                ["reply"] = xmlFile:getValue(phraseKey .. ".reply#id"),
                ["conditions"] = conditions,
                ["triggers"] = triggers
            })

        end)

        conversation[xmlFile:getValue(key .. "#id")] = {
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

        xmlFile:iterate(key .. ".word", function(_, wordKey)
        
            local conditions = {}

            xmlFile:iterate(wordKey .. ".condition", function(_, conditionKey)
                table.insert(conditions, xmlFile:getValue(conditionKey .. "#value"))
            end)

            table.insert(wordType, {
                ["text"] = xmlFile:getValue(wordKey .. ".text"),
                ["conditions"] = conditions
            })
        
        end)

        words[xmlFile:getValue(key .. "#id")] = wordType
    
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

        local condition = allConditions[rawCondition]

        if condition == nil or condition.target == nil then continue end

        local value = PlaceableNPCDialogue.resolveConversationValue(condition.target, args, condition.targetIsLength)

        if value == nil then return false end
            
        local targetValue

        if condition.valueType == "dynamic" then
            targetValue = PlaceableNPCDialogue.resolveConversationValue(condition.value, args, condition.valueIsLength)
        else
            targetValue = condition.value
        end

        if condition.op == nil and targetValue ~= value then return false end
        if condition.op == "not_equals" and targetValue == value then return false end
        if condition.op == "lesser" and targetValue <= value then return false end
        if condition.op == "greater" and targetValue >= value then return false end

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
    local wordTypesToRemove = {}

    for i = #wordTypesToRemove, 1, -1 do table.remove(wordTypes, wordTypesToRemove[i]) end

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

        if self:resolveDialogueConditions(word.conditions, args) then table.insert(viablePhrases, word.value) end

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

        if self:resolveDialogueConditions(phrase.conditions, args) then table.insert(viablePhrases, phrase ) end

    end

    if #viablePhrases == 0 then return "" end

    local phrase = table.clone(viablePhrases[math.random(#viablePhrases)], 10)
    local text = phrase.text
    local wordsToDelete = {}

    for i, word in pairs(text) do
                
        if not string.find(word, "{") and not string.find(word, "}") then continue end

        local variable = self:getWord(word, args)

        if variable == "" then
            table.insert(wordsToDelete, i)
            continue
        end

        local prev = text[i - 1]
        if prev ~= nil and (prev[-1] == "!" or prev[-1] == "." or prev[-1] == "?") or i == 1 then variable = string.sub(variable, 1, 1):upper() .. (#variable > 1 and string.sub(variable, 2) or "") end

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