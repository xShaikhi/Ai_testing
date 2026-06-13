# Bear Mini Games

A round-based Roblox minigame experience: players are dropped into small
bear-themed arenas and must complete an objective (collect honey, escape,
survive) before the timer runs out — while a bear NPC hunts them.

This folder is a [Rojo](https://rojo.space) project. Everything — the lobby,
the minigame maps, and the bear rig itself — is generated procedurally from
Parts at server start, so no `.rbxl` or model assets are required to get a
playable prototype.

## Getting it into Roblox Studio

1. Install Rojo (`aftman add rojo-rbx/rojo` or the Studio plugin).
2. From this folder run `rojo serve`, then connect from the Rojo plugin in
   an empty baseplate place (delete the baseplate).
3. Press Play. The lobby, forest arena, and bear are built automatically.

## Layout

```
src/
  ReplicatedStorage/        -> ReplicatedStorage.Shared
    Config.luau               All tuning values (timers, bear stats, rewards)
    Remotes.luau              RemoteEvent registry shared by server + client
  ServerScriptService/      -> ServerScriptService.Server
    Main.server.luau          Bootstrap: folders, builders, round loop
    Builders/                 Procedural generators (lobby, maps, bear rig)
    Services/                 Round flow, minigames, bear AI, rewards, data
  StarterPlayerScripts/     -> StarterPlayer.StarterPlayerScripts.Client
    UIController.client.luau  HUD: timer, objective, coins, bear warning
```

## Round flow

Lobby -> Intermission -> Map load -> Teleport -> Round (Honey Hunt) ->
Win/Lose -> Rewards -> Cleanup -> back to Lobby.
