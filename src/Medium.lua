local files = {
	"src/placeables/PlaceableSpecLoader.lua",
    "src/graphics/NPCGraphicsComponent.lua",
    "src/graphics/NPCGraphicsComponentState.lua",
    "src/gui/SpeechBubble.lua",
	"src/npcs/PlaceableNPC.lua",
    "src/spawners/NPCSpawn.lua",
    "src/spawners/NPCSpawnCar.lua",
	"src/utils/PathUtil.lua"
}


local root = getmetatable(_G).__index
local modDirectory = g_currentModDirectory

for _, file in pairs(files) do root.source(modDirectory .. file) end