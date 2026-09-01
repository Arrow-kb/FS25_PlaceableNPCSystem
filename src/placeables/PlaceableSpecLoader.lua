local modDirectory = g_currentModDirectory
local path = modDirectory .. "xml/placeables.xml"
local xmlFile = XMLFile.loadIfExists("npcPlaceableSpecs", path)

if xmlFile ~= nil then

	xmlFile:iterate("placeables.specializations.specialization", function(_, key)

		local name = xmlFile:getString(key .. "#name")
		local className = xmlFile:getString(key .. "#className")
		local filename = xmlFile:getString(key .. "#filename")

		g_placeableSpecializationManager:addSpecialization(name, className, modDirectory .. filename)

	end)

end