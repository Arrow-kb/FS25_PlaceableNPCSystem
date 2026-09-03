PlaceableNPCSystemProfiler = {}

local PlaceableNPCSystemProfiler_mt = Class(PlaceableNPCSystemProfiler)


function PlaceableNPCSystemProfiler.new(xmlFile, modSource)

	local self = setmetatable({}, PlaceableNPCSystemProfiler_mt)

	self.modName = g_currentModName
	self.modTitle = xmlFile:getString("modDesc.title.en", "")
	self.modVersion = xmlFile:getString("modDesc.version", "1.0.0.0")
	self.modSource = modSource
	self.debugEnabled = xmlFile:getBool("modDesc.debug", false)

	self.profiles = {}
    self.visualiseCallers = {}
	self.ticksSinceLastWipe = 0
	self.highest = {}

	self:setupFunctions()

	addConsoleCommand("togglePlaceableNPCDebug", "Toggle placeable NPC system debug mode", "consoleCommandToggleDebug", self)

	return self

end


function PlaceableNPCSystemProfiler:setupFunctions()

	local classes = {
		SpeechBubble
	}

	for _, class in pairs(classes) do self:addClass(class) end

end


function PlaceableNPCSystemProfiler:addClass(class)

	local className = ClassUtil.getClassName(class)

	local skipFunctions = {
		["new"] = true,
		["emptyNew"] = true,
		["copy"] = true,
		["isa"] = true,
		["class"] = true,
		["superClass"] = true
	}

	self.profiles[className] = {}

	if class.visualise ~= nil then table.insert(self.visualiseCallers, class) end
			
	for funcName, func in pairs(class) do

		if type(func) ~= "function" or skipFunctions[funcName] then continue end

		class[funcName] = Utils.overwrittenFunction(class[funcName], function(object, superFunc, ...)

			if not self.debugEnabled then return superFunc(object, ...) end

			local time1 = getTimeSec() * 1000
			local returnValues = { superFunc(object, ...) }

			local profiles = self.profiles[className]

			if profiles[funcName] == nil then
				profiles[funcName] = {
					["calls"] = 0,
					["time"] = 0
				}
			end

			local profile = profiles[funcName]
				
			profile.calls = profile.calls + 1
			profile.time = profile.time + (getTimeSec() * 1000 - time1)

			return table.unpack(returnValues)
				
		end)

	end

end


function PlaceableNPCSystemProfiler:visualise()

	if self.debugOverlay == nil then
		_, self.offsetY = getNormalizedScreenValues(20, 20)
		self.debugOverlay = g_overlayManager:createOverlay("gui.serverDetails", 0.3, 0.05, 0.35, 0.75)
        self.debugOverlay:setAlignment(Overlay.ALIGN_VERTICAL_TOP, Overlay.ALIGN_HORIZONTAL_LEFT)
		self.debugOverlay:setColor(0, 0, 0, 0.75)
		self.debugOverlay:setPosition(0.675, 0.9)
	end

	self.debugOverlay:render()
	
	setTextColor(1, 0, 0, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(true)
	
	renderText(0.775, 0.875, self.offsetY / 2, string.format("%s (%s - v%s) Profiler", self.modTitle, self.modSource, self.modVersion))
	renderText(0.7, 0.85, self.offsetY / 2, "Function")
	renderText(0.85, 0.85, self.offsetY / 2, "Time")
	renderText(0.9, 0.85, self.offsetY / 2, "Calls")
	renderText(0.925, 0.85, self.offsetY / 2, "Time / Call")

	setTextColor(1, 1, 1, 1)
	setTextBold(false)

	local y = 0.825
	local sortedTimes = {}

	for className, functions in pairs(self.profiles) do
	
		for funcName, profile in pairs(functions) do
		
			table.insert(sortedTimes, {
				["name"] = className .. "." .. funcName,
				["time"] = profile.time,
				["calls"] = profile.calls
			})
			
		end
	
	end

	table.sort(sortedTimes, function(a, b)

		if a.time == b.time then
			if a.calls == b.calls then return a.name > b.name end
			return a.calls > b.calls
		end
	
		return a.time > b.time
	
	end)

	for i = 1, math.min(#sortedTimes, 25) do

		local profile = sortedTimes[i]

		renderText(0.7, y, self.offsetY / 2, profile.name)
		renderText(0.85, y, self.offsetY / 2, string.format("%.6f ms", profile.time))
		renderText(0.9, y, self.offsetY / 2, string.format("%s", profile.calls))
		renderText(0.925, y, self.offsetY / 2, string.format("%.6f ms", profile.time / profile.calls))

		y = y - self.offsetY

	end

	self.ticksSinceLastWipe = self.ticksSinceLastWipe + 1
	local highest = self.highest

	if self.ticksSinceLastWipe >= 500 then
		self.ticksSinceLastWipe = 0

		for i = 1, 10 do
			
			local profile = sortedTimes[i]
			if profile == nil then continue end
			local average, isViable = profile.time / profile.calls, true

			for i, highestProfile in pairs(highest) do
				if highestProfile.name ~= profile.name then continue end
				isViable = average > highestProfile.average
				if isViable then table.remove(highest, i) end
				break
			end
			
			if isViable and (#highest < 10 or average > highest[10].average) then
				if #highest >= 10 then table.remove(highest, 10) end
				table.insert(highest, {
					["name"] = profile.name,
					["average"] = average
				})
				table.sort(highest, function(a, b)
					if a.average == b.average then return a.name < b.name end
					return a.average > b.average
				end)
			end

		end

		for className, _ in pairs(self.profiles) do self.profiles[className] = {} end

	end

	y = 0.4
	
	setTextColor(1, 0, 0, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(true)
	
	renderText(0.7, y, self.offsetY / 2, "Function")
	renderText(0.85, y, self.offsetY / 2, "Longest Average Time")

	setTextColor(1, 1, 1, 1)
	setTextBold(false)

	y = y - self.offsetY

	for _, profile in pairs(highest) do

		renderText(0.7, y, self.offsetY / 2, profile.name)
		renderText(0.85, y, self.offsetY / 2, string.format("%.6f ms", profile.average))

		y = y - self.offsetY

	end

    for _, classObject in pairs(self.visualiseCallers) do classObject:visualise() end

end


function PlaceableNPCSystemProfiler:draw()

	if not self.debugEnabled then return end

	self:visualise()

end


function PlaceableNPCSystemProfiler:consoleCommandToggleDebug()
	self.debugEnabled = not self.debugEnabled
end


local xmlFile = XMLFile.load("aaProfilerXML", g_modNameToDirectory[g_currentModName] .. "modDesc.xml")
local modSource = xmlFile:getString("modDesc.source", "ModHub")
if modSource == "Development" then
	g_placeableNPCSystemProfiler = PlaceableNPCSystemProfiler.new(xmlFile, modSource)
	addModEventListener(g_placeableNPCSystemProfiler)
end
xmlFile:delete()