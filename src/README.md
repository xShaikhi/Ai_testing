# Source Notes

This source tree contains five minigames plus shared server/client architecture.
It is the merged game: the original four-arena hub plus the bear game ported in
from `../bear-minigames` as the fifth minigame.

- `ServerScriptService/Main.server.lua` builds the giant hub, respawn point, spectator deck, terrain islands, and five map portals.
- `ServerScriptService/Minigames` contains `ColorDrop`, `ArenaBrawl`, `PolarPush` (the focus minigame), `PolarPushModels`, `LaserJump`, `BearHunt`, and `Shared`.
- `StarterPlayer/StarterPlayerScripts/GameClient` contains client controllers for prone input, primary action, map HUD, and spectator camera.
- `ReplicatedStorage/GameShared` contains shared constants/configuration.
- `ReplicatedStorage/Assets` contains the creature `.rbxmx` models (pets and wild creatures).

Bear Hunt: players collect 8 honey jars scattered around a walled forest arena
while a blocky AI bear patrols, roars, and chases the nearest contestant.
Getting caught eliminates you; filling the hive ends the round early and the
survivors win.

Use the repo-root `default.project.json` to sync the full tree into Roblox Studio
with Rojo. To test a single game in Studio, invoke the
`Runtime/StudioStartMinigame` BindableFunction with the game name
(e.g. `"Polar Push"` or `"Bear Hunt"`).
