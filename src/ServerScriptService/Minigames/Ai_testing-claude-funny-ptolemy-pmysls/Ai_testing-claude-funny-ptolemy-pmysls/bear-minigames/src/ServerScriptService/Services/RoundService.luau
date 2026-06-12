local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerStateService = require(script.Parent.PlayerStateService)
local MapService = require(script.Parent.MapService)
local RewardService = require(script.Parent.RewardService)

local RoundService = {}

local function broadcastState(state, detail)
	Remotes.get("RoundState"):FireAllClients(state, detail)
end

local function countdown(seconds, label)
	local timerRemote = Remotes.get("Timer")
	for remaining = seconds, 1, -1 do
		timerRemote:FireAllClients(remaining, label)
		task.wait(1)
	end
	timerRemote:FireAllClients(0, label)
end

local function getMinigameService()
	local module = script.Parent:FindFirstChild("MinigameService")
	if module then
		return require(module)
	end
	return nil
end

local function getLobbySpawnCFrame()
	local builders = script.Parent.Parent:FindFirstChild("Builders")
	local lobbyBuilder = builders and builders:FindFirstChild("LobbyBuilder")
	if lobbyBuilder then
		return require(lobbyBuilder).getSpawnCFrame()
	end
	return CFrame.new(0, 10, 0)
end

local function fallbackRound()
	countdown(Config.Timing.RoundLength, "Survive!")
	return { winners = PlayerStateService.getAlive() }
end

local function giveRewards(results)
	local resultRemote = Remotes.get("ResultScreen")
	local winnerSet = {}
	for _, player in ipairs(results.winners or {}) do
		winnerSet[player] = true
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if winnerSet[player] then
			RewardService.addCoins(player, Config.Rewards.WonObjective)
			RewardService.addWin(player)
			resultRemote:FireClient(player, true, Config.Rewards.WonObjective, results.summary)
		else
			RewardService.addCoins(player, Config.Rewards.Participation)
			resultRemote:FireClient(player, false, Config.Rewards.Participation, results.summary)
		end
	end
end

local function runOneRound()
	broadcastState("Intermission")
	countdown(Config.Timing.Intermission, "Next round in")

	local minigameService = getMinigameService()
	local minigame = minigameService and minigameService.pick()

	local mapName = minigame and minigame.mapName or nil
	broadcastState("Loading", minigame and minigame.displayName or "Round")
	local map = mapName and MapService.load(mapName) or nil
	task.wait(Config.Timing.MapLoad)

	PlayerStateService.setAll(PlayerStateService.ALIVE)
	PlayerStateService.watchDeaths()
	if map then
		MapService.teleportToMarkers(PlayerStateService.getAlive(), "PlayerSpawn")
	end

	broadcastState("InRound", minigame and minigame.displayName or "Survive")

	local results
	if minigame then
		results = minigame.run({
			map = map,
			countdown = countdown,
			playerState = PlayerStateService,
			rewards = RewardService,
		})
	else
		results = fallbackRound()
	end

	broadcastState("RoundOver")
	giveRewards(results or { winners = {} })
	task.wait(Config.Timing.EndScreen)

	PlayerStateService.stopWatching()
	PlayerStateService.setAll(PlayerStateService.LOBBY)
	MapService.teleportToLobby(Players:GetPlayers(), getLobbySpawnCFrame())
	MapService.cleanup()
end

function RoundService.start()
	PlayerStateService.init()
	RewardService.init()

	task.spawn(function()
		while true do
			if #Players:GetPlayers() >= Config.MinPlayers then
				local ok, err = pcall(runOneRound)
				if not ok then
					warn("RoundService: round crashed: " .. tostring(err))
					local bearModule = script.Parent:FindFirstChild("BearAIService")
					if bearModule then
						require(bearModule).stop()
					end
					MapService.cleanup()
					PlayerStateService.stopWatching()
					PlayerStateService.setAll(PlayerStateService.LOBBY)
				end
			else
				broadcastState("WaitingForPlayers")
				task.wait(2)
			end
		end
	end)
end

return RoundService
