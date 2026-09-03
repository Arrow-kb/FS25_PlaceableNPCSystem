function ClassUtil.getClassObjectFromUnresolvedEnvironment(className, environmentName)

    local class = _G

    for _, subClass in pairs(string.split(className, ".")) do
        if subClass == "{modEnv}" and environmentName == nil then return nil, "required mod environment not provided" end
        class = class[subClass == "{modEnv}" and environmentName or subClass]
        if class == nil then return nil, string.format("provided class \"%s\" could not be found", subClass) end
        if type(class) ~= "table" then return nil, string.format("provided class \"%s\" is not a valid class", subClass) end
    end

    return class

end