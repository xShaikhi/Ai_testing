local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BearAIService = {}

local activeBear = nil
local running = false
local stunnedUntil = 0

local function getRoot(bear)
	return bear:FindFirstChild("HumanoidRootPart")
end

local function nearestAlivePlayer(bearPosition, playerState)
	local nearest, nearestDistance = nil, math.huge
	for _, player in ipairs(playerState.getAlive()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local distance = (root.Position - bearPosition).Magnitude
			if distance < nearestDistance then
				nearest = player
				nearestDistance = distance
			end
		end
	end
	return nearest, nearestDistance
end

local function roar(bear, target)
	local root = getRoot(bear)
	local sound = root and root:FindFirstChild("Roar")
	if sound then
		sound:Play()
	end
	if target then
		Remotes.get("BearWarning"):FireClient(target, true)
	end
end

local function attack(bear, targetPlayer)
	local root = getRoot(bear)
	local sound = root and root:FindFirstChild("Swipe")
	if sound then
		sound:Play()
	end
	local character = targetPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(humanoid.MaxHealth)
	end
end

local function randomPatrolPoint(origin, radius)
	local rng = Random.new()
	local angle = rng:NextNumber(0, math.pi * 2)
	local distance = rng:NextNumber(10, radius)
	return origin + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

local function aiLoop(bear, playerState, homePosition)
	local humanoid = bear:FindFirstChildOfClass("Humanoid")
	local state = "Patrol"
	local target = nil
	local lastAttack = 0

	while running and bear.Parent do
		local root = getRoot(bear)
		if not root or not humanoid or humanoid.Health <= 0 then
			break
		end

		if os.clock() < stunnedUntil then
			state = "Stunned"
			humanoid:MoveTo(root.Position)
		elseif state == "Stunned" then
			state = "Patrol"
		end

		if state == "Patrol" then
			humanoid.WalkSpeed = Config.Bear.WalkSpeed
			local candidate, distance = nearestAlivePlayer(root.Position, playerState)
			if candidate and distance <= Config.Bear.DetectionRange then
				target = candidate
				state = "Chase"
				if Config.Bear.RoarBeforeChase then
					roar(bear, target)
					task.wait(0.8)
				end
			else
				if humanoid.WalkToPoint == Vector3.zero
					or (root.Position - humanoid.WalkToPoint).Magnitude < 6 then
					humanoid:MoveTo(randomPatrolPoint(homePosition, 45))
				end
			end
		elseif state == "Chase" then
			humanoid.WalkSpeed = Config.Bear.ChaseSpeed
			local character = target and target.Character
			local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
			local targetAlive = target
				and playerState.get(target) == playerState.ALIVE
				and targetRoot ~= nil

			if not targetAlive then
				target = nil
				state = "Patrol"
			else
				local distance = (targetRoot.Position - root.Position).Magnitude
				if distance > Config.Bear.LoseTargetRange then
					Remotes.get("BearWarning"):FireClient(target, false)
					target = nil
					state = "Patrol"
				elseif distance <= Config.Bear.AttackRange then
					if os.clock() - lastAttack >= Config.Bear.AttackCooldown then
						lastAttack = os.clock()
						attack(bear, target)
					end
				else
					humanoid:MoveTo(targetRoot.Position)
				end
			end
		end

		task.wait(0.2)
	end
end

function BearAIService.spawn(map, playerState)
	BearAIService.stop()

	local npcs = ServerStorage:WaitForChild("NPCs")
	local template = npcs:FindFirstChild("Bear")
	if not template then
		warn("BearAIService: no Bear rig in ServerStorage.NPCs")
		return nil
	end

	local spawnPoint = nil
	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant.Name == "BearSpawn" and descendant:IsA("BasePart") then
			spawnPoint = descendant
			break
		end
	end
	if not spawnPoint then
		warn("BearAIService: map has no BearSpawn marker")
		return nil
	end

	activeBear = template:Clone()
	activeBear.Parent = Workspace
	activeBear:PivotTo(spawnPoint.CFrame + Vector3.new(0, Config.Bear.Height / 2, 0))

	running = true
	stunnedUntil = 0
	local home = spawnPoint.Position
	task.spawn(function()
		aiLoop(activeBear, playerState, home)
	end)
	return activeBear
end

function BearAIService.stun()
	stunnedUntil = os.clock() + Config.Bear.StunDuration
end

function BearAIService.stop()
	running = false
	if activeBear then
		activeBear:Destroy()
		activeBear = nil
	end
end

return BearAIService
