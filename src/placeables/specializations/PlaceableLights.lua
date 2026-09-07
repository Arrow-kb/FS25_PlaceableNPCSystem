function PlaceableLights:saveToXMLFile(xmlFile, key)

    for i, group in pairs(self.spec_lights.groups) do

        if group.triggerNode == nil then continue end

        local path = I3DUtil.getNodePathIndices(group.triggerNode, getChildAt(self.rootNode, 0))

        if string.find(path, "|") then
            path = string.gsub(path, "|", ">", 1)
        elseif not string.find(path, ">") then
            path = path .. ">"
        end

        xmlFile:setString(string.format("%s.group(%d)#node", key, i - 1), path)
        xmlFile:setBool(string.format("%s.group(%d)#isActive", key, i - 1), group.isActive or false)

    end

end


function PlaceableLights:loadFromXMLFile(xmlFile, key)

    local groups = self.spec_lights.triggerToGroup

    xmlFile:iterate(key .. ".group", function(_, groupKey)
    
        local node = I3DUtil.indexToObject(self.components, xmlFile:getString(groupKey .. "#node"))

        if node == nil then return end

        local group = groups[node]

        if group == nil then return end

        self:setGroupIsActive(group.index, xmlFile:getBool(groupKey .. "#isActive", false))
    
    end)

end