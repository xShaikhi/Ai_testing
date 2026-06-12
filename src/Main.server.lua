-- Main round controller. Each minigame lives in ServerScriptService/Minigames.

local Players = game:GetService("Players")

local Shared = require(script.Parent.Minigames.Shared)
local ColorDrop = require(script.Parent.Minigames.ColorDrop)
local ArenaBrawl = require(script.Parent.Minigames.ArenaBrawl)
local PolarPush = require(script.Parent.Minigames.PolarPush)

local CONFIG = {
	Intermission = 10,
	RoundDuration = 65,
	MinPlayers = 1,
	LobbySpawn = Vector3.new(0, 8, 0),
	Arenas = {
		ColorDrop = Vector3.new(-160, 8, 0),
		ArenaBrawl = Vector3.new(0, 8, 0),
		PolarPush = Vector3.new(160, 8, 0),
	},
}

local rootFolder = workspace:FindFirstChild("CrashBashPrototype")
if rootFolder then
	rootFolder:Destroy()
end

rootFolder = Instance.new("Folder")
rootFolder.Name = "CrashBashPrototype"
rootFolder.Parent = workspace

local statusValue = Instance.new("StringValue")
statusValue.Name = "GameStatus"
statusValue.Value = "Loading..."
statusValue.Parent = rootFolder

local lobby = Instance.new("Folder")
lobby.Name = "Lobby"
lobby.Parent = rootFolder

Shared.makePart("LobbyBase", Vector3.new(100, 2, 64), CFrame.new(CONFIG.LobbySpawn - Vector3.new(0, 4, 0)), Color3.fromRGB(35, 38, 55), Enum.Material.Slate, lobby)
Shared.makeSpawn("LobbySpawn", CONFIG.LobbySpawn, lobby)
local lobbySign = Shared.makeBillboard("LobbyStatus", "Crash Bash Minigames", CONFIG.LobbySpawn + Vector3.new(0, 4, -20), lobby)

local context = {
	config = CONFIG,
	rootFolder = rootFolder,
	statusValue = statusValue,
	lobbySign = lobbySign,
}

local games = {
	ColorDrop.new(context),
	ArenaBrawl.new(context),
	PolarPush.new(context),
}

local function announce(message)
	statusValue.Value = message
	lobbySign.Text = message
	print("[Minigames] " .. message)
end

local function resetPlayersToLobby()
	Shared.clearRoundState()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		end
		if root then
			root.CFrame = CFrame.new(CONFIG.LobbySpawn + Vector3.new(0, 5, 0))
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

local function waitForPlayers()
	while #Players:GetPlayers() < CONFIG.MinPlayers do
		announce("Waiting for players...")
		task.wait(2)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(CONFIG.LobbySpawn + Vector3.new(0, 5, 0))
		end
	end)
end)

task.spawn(function()
	while true do
		waitForPlayers()
		resetPlayersToLobby()

		for seconds = CONFIG.Intermission, 1, -1 do
			announce("Next minigame in " .. seconds .. " seconds")
			task.wait(1)
		end

		for _, gameModule in ipairs(games) do
			announce(gameModule.name .. " starting")
			gameModule:run()
			resetPlayersToLobby()
			task.wait(4)
		end
	end
end)
