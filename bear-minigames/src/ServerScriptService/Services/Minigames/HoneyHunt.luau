local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local HoneyHunt = {}

HoneyHunt.mapName = "HoneyHunt_Forest"
HoneyHunt.displayName = "Honey Hunt"

local function makeJar(cframe, parent)
	local jar = Instance.new("Part")
	jar.Name = "HoneyJar"
	jar.Shape = Enum.PartType.Cylinder
	jar.Size = Vector3.new(2, 1.6, 1.6)
	jar.CFrame = cframe * CFrame.Angles(0, 0, math.pi / 2)
	jar.Color = Color3.fromRGB(255, 196, 50)
	jar.Material = Enum.Material.Neon
	jar.Anchored = true
	jar.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 80)
	light.Range = 8
	light.Parent = jar
	jar.Parent = parent
	return jar
end

local function pickSpawns(markers, count)
	local pool = {}
	for _, m in ipairs(markers) do
		table.insert(pool, m)
	end
	local rng = Random.new()
	local chosen = {}
	for _ = 1, math.min(count, #pool) do
		local index = rng:NextInteger(1, #pool)
		table.insert(chosen, pool[index])
		table.remove(pool, index)
	end
	return chosen
end

local function getBearAI()
	local module = script.Parent.Parent:FindFirstChild("BearAIService")
	if module then
		return require(module)
	end
	return nil
end

function HoneyHunt.run(context)
	local map = context.map
	local playerState = context.playerState
	local objectiveRemote = Remotes.get("Objective")
	local timerRemote = Remotes.get("Timer")

	local goal = Config.HoneyHunt.JarsToWin
	local collected = 0
	local perPlayer = {}
	local jarFolder = Instance.new("Folder")
	jarFolder.Name = "HoneyJars"
	jarFolder.Parent = map

	local markers = {}
	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant.Name == "HoneySpawn" and descendant:IsA("BasePart") then
			table.insert(markers, descendant)
		end
	end

	for _, spawnMarker in ipairs(pickSpawns(markers, Config.HoneyHunt.JarsSpawned)) do
		local jar = makeJar(spawnMarker.CFrame, jarFolder)
		local taken = false
		jar.Touched:Connect(function(hit)
			if taken then
				return
			end
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player and playerState.get(player) == playerState.ALIVE then
				taken = true
				jar:Destroy()
				collected = collected + 1
				perPlayer[player] = (perPlayer[player] or 0) + 1
				context.rewards.addCoins(player, Config.HoneyHunt.CoinsPerJar)
				objectiveRemote:FireAllClients("Collect Honey", collected, goal)
			end
		end)
	end

	objectiveRemote:FireAllClients("Collect Honey", 0, goal)

	local bearAI = getBearAI()
	if bearAI then
		bearAI.spawn(map, playerState)
	end

	local objectiveMet = false
	for remaining = Config.Timing.RoundLength, 1, -1 do
		timerRemote:FireAllClients(remaining, "Honey Hunt")
		if collected >= goal then
			objectiveMet = true
			break
		end
		if #playerState.getAlive() == 0 then
			break
		end
		task.wait(1)
	end

	if bearAI then
		bearAI.stop()
	end
	jarFolder:Destroy()

	local winners = playerState.getAlive()
	local summary
	if objectiveMet then
		summary = "The hive is full! Honey collected: " .. collected .. "/" .. goal
	elseif #winners > 0 then
		summary = "Time ran out, but you survived the bear."
	else
		summary = "The bear caught everyone!"
	end

	return { winners = winners, summary = summary, perPlayer = perPlayer }
end

return HoneyHunt
