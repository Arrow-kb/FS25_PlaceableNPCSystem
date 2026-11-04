# FS25_PlaceableNPCSystem

This is a framework mod designed to be used by other mods, primarily by my Animal Auctions mod. This mod adds a much more dynamic and complex NPC system than the current NPC system, which is limited to engine-controlled pedestrians and static NPCs.

# Features

## Overview
- Contains 3 placeable specialisations; PlaceableNPCNavigation, PlaceableNPCManager and PlaceableNPCDialogue
- Contains a dedicated base NPC class
- Contains 2 NPC spawn classes
- Contains 4 NPC tasks
- Contains a detailed debugging overlay

## Navigation
- Custom navmesh system based on cellmaps
- Basic navmesh parameters are defined in blender (blender script provided for this), then built in-game
- Several settings in the placeable's XML file to adjust the navmesh such as cell density
- Custom pathfinding system (works fast if set up properly) with preloaded paths and NPC targets defined in the XML file
- Room system

## NPCs
- All NPC movement, dialogue, tasks, pathfinding, graphics and animations are handled by the base NPC class
- Task system which allows for much more dynamic NPCs that can handle various jobs
- Spawn system which handles the spawning of NPCs, currently a base spawner class and a car spawner class
- Customisable appearances, which can be defined in a unique preset per NPC or randomised from a set of unique/non-unique presets
- Custom spawn types, task types and NPC types can be easily added in using XML and minimal luau

## Dialogue System
- Custom dialogue system which allows for branching dialogue
- Dialogue defined in XML files
- Currently only supports dialogue between 2 NPCs, but dialogue between player and NPCs will also be supported

## Debugging
- Performance profiler
- Navmesh viewer
- Pathfinding viewer
- NPC animation, graphics, movement, task, path and dialogue visualisation


# Example
An example of how this mod is added in to another mod, taken from my Animal Auctions mod:
<img width="1743" height="1108" alt="image" src="https://github.com/user-attachments/assets/dd91734b-3c5e-4c7c-bc60-5cee9426a8f6" />
<img width="1149" height="1087" alt="image" src="https://github.com/user-attachments/assets/2b21a6d5-d479-4cb1-bec0-809938ffa283" />
<img width="1031" height="811" alt="image" src="https://github.com/user-attachments/assets/f38345b7-3ad3-4b40-838f-664d41191baa" />
<img width="1475" height="227" alt="image" src="https://github.com/user-attachments/assets/407a9f75-5279-4078-8774-673ee76e9770" />

NPC (this is a complete receptionist NPC class from Animal Auctions - almost no code required):
<img width="1049" height="786" alt="image" src="https://github.com/user-attachments/assets/8dece365-22fa-4a53-a01d-5e1f4d8c4cff" />

Dialogue:
<img width="1634" height="428" alt="image" src="https://github.com/user-attachments/assets/841122d8-06f2-4dc5-a6a0-d1bb465d44a7" />
<img width="640" height="1311" alt="image" src="https://github.com/user-attachments/assets/6b0c1a1f-92b8-4eea-93fa-64f6b9ce0578" />
<img width="1709" height="1288" alt="image" src="https://github.com/user-attachments/assets/ee529f02-1a86-4bd5-8b69-5163c9d37cc7" />
<img width="1350" height="1447" alt="image" src="https://github.com/user-attachments/assets/a2cb0005-8185-4161-9564-8b812ece743b" />
