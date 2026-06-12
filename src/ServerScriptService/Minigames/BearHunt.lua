local Players = game:GetService("Players")

local Shared = require(script.Parent.Shared)

local BearHunt = {}
BearHunt.__index = BearHunt

local ARENA_SIZE = 150
local WALL_HEIGHT = 26
local HONEY_GOAL = 8
local HONEY_COUNT = 14
local BEAR_WALK_SPEED = 10
local BEAR_CHASE_SPEED = 20
local BEAR_DETECTION_RANGE = 80
local BEAR_ATTACK_RANGE = 7
local BEAR_ATTACK_COOLDOWN = 2
local AI_TICK = 0.2

local FUR = Color3.fromRGB(82, 56, 36)
local FUR_DARK = Color3.fromRGB(60, 40, 26)
local SNOUT = Color3.fromRGB(150, 110, 75)
local HONEY = Color3.fromRGB(255, 196, 50)

function BearHunt.new(context)
	local self = setmetatable({}, BearHunt)
	self.name = "Bear Hunt"
	self.context = context
	self.origin = context.config.Arenas.BearHunt
	self.folder = Instance.new("Folder")
	self.folder.Name = "BearHunt"
	self.folder.Parent = context.rootFolder
	self.random = Random.new()
	self.aiRunning = false
	self:build()
	return self
end

function BearHunt:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[BearHunt] " .. message)
end

function BearHunt:randomGroundSpot(margin)
	local half = ARENA_SIZE / 2 - margin
	return self.origin + Vector3.new(self.random:NextNumber(-half, half), 0, self.random:NextNumber(-half, half))
end

function BearHunt:build()
	local ground = Shared.makePart("BearHuntGround", Vector3.new(ARENA_SIZE, 2, ARENA_SIZE), CFrame.new(self.origin + Vector3.new(0, -1, 0)), Color3.fromRGB(52, 88, 48), Enum.Material.Grass, self.folder)
	ground.CanCollide = true

	for _, info in ipairs({
		{ offset = Vector3.new(0, 0, ARENA_SIZE / 2), size = Vector3.new(ARENA_SIZE, WALL_HEIGHT, 2) },
		{ offset = Vector3.new(0, 0, -ARENA_SIZE / 2), size = Vector3.new(ARENA_SIZE, WALL_HEIGHT, 2) },
		{ offset = Vector3.new(ARENA_SIZE / 2, 0, 0), size = Vector3.new(2, WALL_HEIGHT, ARENA_SIZE) },
		{ offset = Vector3.new(-ARENA_SIZE / 2, 0, 0), size = Vector3.new(2, WALL_HEIGHT, ARENA_SIZE) },
	}) do
		local wall = Shared.makePart("BearHuntWall", info.size, CFrame.new(self.origin + info.offset + Vector3.new(0, WALL_HEIGHT / 2, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, self.folder)
		wall.Transparency = 1
		wall.CanCollide = true
	end

	local treeRandom = Random.new(83)
	for index = 1, 18 do
		local half = ARENA_SIZE / 2 - 12
		local x = treeRandom:NextNumber(-half, half)
		local z = treeRandom:NextNumber(-half, half)
		if math.abs(x) > 18 or math.abs(z) > 18 then
			local scale = treeRandom:NextNumber(0.7, 1.4)
			local base = self.origin + Vector3.new(x, 0, z)
			local trunk = Shared.makePart("BearHuntTrunk", Vector3.new(2, 8, 2) * scale, CFrame.new(base + Vector3.new(0, 4 * scale, 0)), Color3.fromRGB(94, 64, 39), Enum.Material.Wood, self.folder)
			trunk.CanCollide = true
			local crown = Shared.makePart("BearHuntCrown", Vector3.new(7, 9, 7) * scale, CFrame.new(base + Vector3.new(0, 11 * scale, 0)), Color3.fromRGB(32, 86, 41), Enum.Material.Grass, self.folder)
			crown.Shape = Enum.PartType.Ball
			crown.CanCollide = false
		end
		if index % 3 == 0 then
			local crate = Shared.makePart("BearHuntCrate", Vector3.new(4, 4, 4), CFrame.new(self:randomGroundSpot(15) + Vector3.new(0, 2, 0)), Color3.fromRGB(140, 105, 65), Enum.Material.WoodPlanks, self.folder)
			crate.CanCollide = true
		end
	end

	self.denPosition = self.origin + Vector3.new(0, 0, -ARENA_SIZE / 2 + 15)
	local den = Shared.makePart("BearDen", Vector3.new(12, 7, 8), CFrame.new(self.denPosition + Vector3.new(0, 3.5, -4)), Color3.fromRGB(70, 70, 75), Enum.Material.Slate, self.folder)
	den.CanCollide = true

	Shared.makeBillboard("BearHuntSign", "Bear Hunt: grab " .. HONEY_GOAL .. " honey jars before the bear gets you", self.origin + Vector3.new(0, 14, -ARENA_SIZE / 2 - 4), self.folder)

	self.bear = self:buildBear()
end

local function bearPart(name, size, cframe, color, parent)
	local part = Shared.makePart(name, size, cframe, color, Enum.Material.SmoothPlastic, parent)
	part.Anchored = false
	part.CanCollide = false
	return part
end

function BearHunt:buildBear()
	local model = Instance.new("Model")
	model.Name = "HuntBear"

	local legHeight = 3.5
	local torsoHeight = 4
	local base = CFrame.new(self.denPosition + Vector3.new(0, 1, 4))

	local root = bearPart("HumanoidRootPart", Vector3.new(4, 2, 2.5), base * CFrame.new(0, legHeight + torsoHeight / 2, 0), FUR, model)
	root.Transparency = 1
	root.CanCollide = true

	local headY = legHeight + torsoHeight + 1.25
	local armY = legHeight + torsoHeight / 2 + 0.3
	local limbs = {
		bearPart("Torso", Vector3.new(5.5, torsoHeight, 3.5), base * CFrame.new(0, legHeight + torsoHeight / 2, 0), FUR, model),
		bearPart("Belly", Vector3.new(3.2, 2.6, 0.6), base * CFrame.new(0, legHeight + torsoHeight / 2 - 0.4, -1.6), SNOUT, model),
		bearPart("Head", Vector3.new(3.2, 2.5, 2.8), base * CFrame.new(0, headY, -0.4), FUR, model),
		bearPart("Snout", Vector3.new(1.6, 1.1, 1.2), base * CFrame.new(0, headY - 0.5, -2), SNOUT, model),
		bearPart("Ear_L", Vector3.new(0.9, 0.9, 0.6), base * CFrame.new(-1.3, headY + 1.5, -0.4), FUR_DARK, model),
		bearPart("Ear_R", Vector3.new(0.9, 0.9, 0.6), base * CFrame.new(1.3, headY + 1.5, -0.4), FUR_DARK, model),
		bearPart("Arm_L", Vector3.new(1.6, 4, 1.8), base * CFrame.new(-3.5, armY, 0), FUR, model),
		bearPart("Arm_R", Vector3.new(1.6, 4, 1.8), base * CFrame.new(3.5, armY, 0), FUR, model),
		bearPart("Paw_L", Vector3.new(1.8, 1, 2), base * CFrame.new(-3.5, armY - 2.4, -0.2), FUR_DARK, model),
		bearPart("Paw_R", Vector3.new(1.8, 1, 2), base * CFrame.new(3.5, armY - 2.4, -0.2), FUR_DARK, model),
		bearPart("Leg_L", Vector3.new(1.9, legHeight, 2), base * CFrame.new(-1.4, legHeight / 2, 0.2), FUR, model),
		bearPart("Leg_R", Vector3.new(1.9, legHeight, 2), base * CFrame.new(1.4, legHeight / 2, 0.2), FUR, model),
		bearPart("Foot_L", Vector3.new(2, 1, 2.6), base * CFrame.new(-1.4, 0.5, -0.2), FUR_DARK, model),
		bearPart("Foot_R", Vector3.new(2, 1, 2.6), base * CFrame.new(1.4, 0.5, -0.2), FUR_DARK, model),
	}

	local eyeL = bearPart("Eye_L", Vector3.new(0.45, 0.45, 0.2), base * CFrame.new(-0.7, headY + 0.3, -1.85), Color3.fromRGB(20, 20, 20), model)
	eyeL.Material = Enum.Material.Neon
	local eyeR = bearPart("Eye_R", Vector3.new(0.45, 0.45, 0.2), base * CFrame.new(0.7, headY + 0.3, -1.85), Color3.fromRGB(20, 20, 20), model)
	eyeR.Material = Enum.Material.Neon
	table.insert(limbs, eyeL)
	table.insert(limbs, eyeR)

	for _, limb in ipairs(limbs) do
		local weldJoint = Instance.new("WeldConstraint")
		weldJoint.Part0 = root
		weldJoint.Part1 = limb
		weldJoint.Parent = root
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = 100000
	humanoid.Health = 100000
	humanoid.WalkSpeed = BEAR_WALK_SPEED
	humanoid.HipHeight = legHeight + torsoHeight / 2 - 1
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid.Parent = model

	local roar = Instance.new("Sound")
	roar.Name = "Roar"
	roar.SoundId = "rbxassetid://9125402735"
	roar.Volume = 1
	roar.RollOffMaxDistance = 140
	roar.Parent = root

	model.PrimaryPart = root
	model.Parent = self.folder
	return model
end

function BearHunt:resetBear()
	local humanoid = self.bear and self.bear:FindFirstChildOfClass("Humanoid")
	if not self.bear or not humanoid or humanoid.Health <= 0 then
		if self.bear then
			self.bear:Destroy()
		end
		self.bear = self:buildBear()
		humanoid = self.bear:FindFirstChildOfClass("Humanoid")
	end
	humanoid.WalkSpeed = BEAR_WALK_SPEED
	self.bear:PivotTo(CFrame.new(self.denPosition + Vector3.new(0, 6, 4)))
end

function BearHunt:nearestContestant(fromPosition)
	local nearest, nearestDistance = nil, math.huge
	for _, contestant in ipairs(Shared.aliveContestants()) do
		if contestant.root then
			local distance = (contestant.root.Position - fromPosition).Magnitude
			if distance < nearestDistance then
				nearest = contestant
				nearestDistance = distance
			end
		end
	end
	return nearest, nearestDistance
end

function BearHunt:runBearAI()
	self.aiRunning = true
	task.spawn(function()
		local humanoid = self.bear:FindFirstChildOfClass("Humanoid")
		local root = self.bear and self.bear:FindFirstChild("HumanoidRootPart")
		local roar = root and root:FindFirstChild("Roar")
		local chasingName = nil
		local lastAttack = 0

		while self.aiRunning and self.bear.Parent and humanoid and humanoid.Health > 0 do
			local target, distance = self:nearestContestant(root.Position)
			if target and distance <= BEAR_DETECTION_RANGE then
				if chasingName ~= target.name then
					chasingName = target.name
					if roar then
						roar:Play()
					end
					self:announce("Bear Hunt: the bear is chasing " .. target.name .. "!")
				end
				humanoid.WalkSpeed = BEAR_CHASE_SPEED
				if distance <= BEAR_ATTACK_RANGE then
					if os.clock() - lastAttack >= BEAR_ATTACK_COOLDOWN then
						lastAttack = os.clock()
						Shared.eliminate(target.subject)
						self:announce("Bear Hunt: " .. target.name .. " got mauled by the bear!")
						chasingName = nil
					end
				else
					humanoid:MoveTo(target.root.Position)
				end
			else
				chasingName = nil
				humanoid.WalkSpeed = BEAR_WALK_SPEED
				if (root.Position - humanoid.WalkToPoint).Magnitude < 6 then
					humanoid:MoveTo(self:randomGroundSpot(14))
				end
			end
			task.wait(AI_TICK)
		end
	end)
end

function BearHunt:spawnHoney()
	local jarFolder = Instance.new("Folder")
	jarFolder.Name = "HoneyJars"
	jarFolder.Parent = self.folder
	self.jarFolder = jarFolder
	self.collected = 0

	for _ = 1, HONEY_COUNT do
		local jar = Shared.makePart("HoneyJar", Vector3.new(2, 1.6, 1.6), CFrame.new(self:randomGroundSpot(10) + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), HONEY, Enum.Material.Neon, jarFolder)
		jar.Shape = Enum.PartType.Cylinder
		jar.CanCollide = false
		jar.CanTouch = true
		local light = Instance.new("PointLight")
		light.Color = HONEY
		light.Range = 8
		light.Parent = jar

		local taken = false
		jar.Touched:Connect(function(hit)
			if taken then
				return
			end
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local humanoid = Shared.humanoidFromSubject(player)
			if not humanoid or humanoid.Health <= 0 or player:GetAttribute("RoundContestant") ~= true or Shared.isSpectating(player) then
				return
			end
			taken = true
			jar:Destroy()
			self.collected += 1
			self:announce("Bear Hunt: honey " .. self.collected .. " / " .. HONEY_GOAL .. " (" .. player.Name .. ")")
		end)
	end
end

function BearHunt:run()
	if self.jarFolder then
		self.jarFolder:Destroy()
		self.jarFolder = nil
	end
	self:resetBear()
	Shared.teleportPlayers(self.origin + Vector3.new(0, 4, 0), 16)
	task.wait(0.45)

	self:spawnHoney()
	self:announce("Bear Hunt: collect " .. HONEY_GOAL .. " honey jars, avoid the bear!")
	self:runBearAI()

	local roundEnd = os.clock() + self.context.config.RoundDuration
	local honeyWin = false
	while Shared.roundShouldContinue(roundEnd) do
		if self.collected >= HONEY_GOAL then
			honeyWin = true
			break
		end
		task.wait(0.1)
	end

	self.aiRunning = false
	if self.jarFolder then
		self.jarFolder:Destroy()
		self.jarFolder = nil
	end

	if honeyWin then
		self:announce("Bear Hunt: the hive is full! The bear gives up.")
		task.wait(1)
	end
	Shared.awardSurvivors(self.name, function(message)
		self:announce(message)
	end)
end

return BearHunt
