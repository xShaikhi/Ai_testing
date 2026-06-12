# Source Notes

This source tree now contains four minigames plus shared server/client architecture.

- `ServerScriptService/Main.server.lua` builds the giant hub, respawn point, spectator deck, terrain islands, and four map portals.
- `ServerScriptService/Minigames` contains `ColorDrop`, `ArenaBrawl`, `PolarPush`, `PolarPushModels`, `LaserJump`, and `Shared`.
- `StarterPlayer/StarterPlayerScripts/GameClient` contains client controllers for prone input and spectator camera.
- `ReplicatedStorage/GameShared` contains shared constants/configuration.

Use `default.project.json` to sync the full tree into Roblox Studio.
