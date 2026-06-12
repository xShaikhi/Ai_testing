local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = require(script.Parent.Shared)

local ArenaBrawl = {}
ArenaBrawl.__index = ArenaBrawl

local START_SIZE = 108
local MIN_SIZE = 30
local SHRINK_EVERY = 12
local SHRINK_AMOUNT = 13
local PUNCH_COOLDOWN = 0.34

function ArenaBrawl.new(context)
	local self = setmetatable({}, ArenaBrawl)
	self.name = "Arena Brawl"
	self.context = context
	self.origin = context.config.Arenas.ArenaBrawl
	self.folder = Instance.new("Folder")
	self.folder.Name = "ArenaBrawl"
	self.folder.Parent = context.rootFolder
	self.currentSize = START_SIZE
	self.floor = nil
	self.hazardFloor = nil
	self.boundaries = {}
	self.cornerPosts = {}
	self.inlays = {}
	self.lastPunchAt = {}
	self:build()
	return self
end

function ArenaBrawl:build()
	self.hazardFloor = Shared.makePart("ArenaOuterVoid", Vector3.new(136, 1, 136), CFrame.new(self.origin + Vector3.new(0, -5.4, 0)), Color3.fromRGB(30, 11, 18), Enum.Material.Slate, self.folder)
	self.hazardFloor.CanCollide = false

	self.floor = Shared.makePart("ShrinkingSquareRing", Vector3.new(START_SIZE, 2, START_SIZE), CFrame.new(self.origin - Vector3.new(0, 4, 0)), Color3.fromRGB(110, 82, 64), Enum.Material.WoodPlanks, self.folder)
	self.floor:SetAttribute("SafeSize", START_SIZE)

	for i = 1, 9 do
		local offset = -START_SIZE / 2 + (i - 1) * (START_SIZE / 8)
		local lineX = Shared.makePart("ArenaInlayX", Vector3.new(0.35, 0.08, START_SIZE), CFrame.new(self.origin + Vector3.new(offset, -2.92, 0)), Color3.fromRGB(255, 198, 84), Enum.Material.Neon, self.folder)
		lineX.CanCollide = false
		lineX.Transparency = if i == 1 or i == 9 then 0 else 0.65
		table.insert(self.inlays, { part = lineX, axis = "X", slot = i })

		local lineZ = Shared.makePart("ArenaInlayZ", Vector3.new(START_SIZE, 0.08, 0.35), CFrame.new(self.origin + Vector3.new(0, -2.91, offset)), Color3.fromRGB(255, 198, 84), Enum.Material.Neon, self.folder)
		lineZ.CanCollide = false
		lineZ.Transparency = if i == 1 or i == 9 then 0 else 0.65
		table.insert(self.inlays, { part = lineZ, axis = "Z", slot = i })
	end

	local borderData = {
		{ name = "NorthBoundary", size = Vector3.new(START_SIZE + 4, 2.2, 1.4), offset = Vector3.new(0, -2.1, -START_SIZE / 2), color = Color3.fromRGB(255, 70, 84) },
		{ name = "SouthBoundary", size = Vector3.new(START_SIZE + 4, 2.2, 1.4), offset = Vector3.new(0, -2.1, START_SIZE / 2), color = Color3.fromRGB(255, 70, 84) },
		{ name = "WestBoundary", size = Vector3.new(1.4, 2.2, START_SIZE + 4), offset = Vector3.new(-START_SIZE / 2, -2.1, 0), color = Color3.fromRGB(255, 70, 84) },
		{ name = "EastBoundary", size = Vector3.new(1.4, 2.2, START_SIZE + 4), offset = Vector3.new(START_SIZE / 2, -2.1, 0), color = Color3.fromRGB(255, 70, 84) },
	}

	for _, info in ipairs(borderData) do
		local boundary = Shared.makePart(info.name, info.size, CFrame.new(self.origin + info.offset), info.color, Enum.Material.Neon, self.folder)
		boundary.CanCollide = false
		boundary:SetAttribute("Boundary", true)
		table.insert(self.boundaries, boundary)
	end

	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local post = Shared.makePart("ArenaCornerTower", Vector3.new(4.5, 15, 4.5), CFrame.new(self.origin + Vector3.new(x * START_SIZE / 2, 3.5, z * START_SIZE / 2)), Color3.fromRGB(45, 34, 32), Enum.Material.Metal, self.folder)
			post:SetAttribute("CornerX", x)
			post:SetAttribute("CornerZ", z)
			table.insert(self.cornerPosts, post)

			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 90, 80)
			light.Range = 20
			light.Brightness = 1.8
			light.Parent = post
		end
	end

	for side = 1, 4 do
		local angle = math.rad((side - 1) * 90)
		local stand = Shared.makePart("ArenaGrandstand", Vector3.new(72, 8, 12), CFrame.new(self.origin + Vector3.new(math.cos(angle) * 76, -0.5, math.sin(angle) * 76)) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(36, 38, 48), Enum.Material.Concrete, self.folder)
		stand.CanCollide = true
	end

	Shared.makeBillboard("BrawlerSign", "Arena Brawl: stay inside the shrinking square", self.origin + Vector3.new(0, 12, -70), self.folder)
end

function ArenaBrawl:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[ArenaBrawl] " .. message)
end

function ArenaBrawl:setActionEnabled(enabled)
	for _, contestant in ipairs(Shared.aliveContestants()) do
		contestant.subject:SetAttribute("AllowPrimaryAction", enabled == true)
		contestant.subject:SetAttribute("CurrentMinigame", if enabled then self.name else nil)
		if contestant.subject:IsA("Player") then
			Shared.clearSubjectTools(contestant.subject)
		end
	end
end

function ArenaBrawl:updateRingVisual(size, tweenTime)
	self.currentSize = size
	self.floor:SetAttribute("SafeSize", size)

	local half = size / 2
	local tweenInfo = TweenInfo.new(tweenTime or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(self.floor, tweenInfo, {
		Size = Vector3.new(size, 2, size),
		CFrame = CFrame.new(self.origin - Vector3.new(0, 4, 0)),
	}):Play()

	local targets = {
		NorthBoundary = { Size = Vector3.new(size + 4, 2.2, 1.4), CFrame = CFrame.new(self.origin + Vector3.new(0, -2.1, -half)) },
		SouthBoundary = { Size = Vector3.new(size + 4, 2.2, 1.4), CFrame = CFrame.new(self.origin + Vector3.new(0, -2.1, half)) },
		WestBoundary = { Size = Vector3.new(1.4, 2.2, size + 4), CFrame = CFrame.new(self.origin + Vector3.new(-half, -2.1, 0)) },
		EastBoundary = { Size = Vector3.new(1.4, 2.2, size + 4), CFrame = CFrame.new(self.origin + Vector3.new(half, -2.1, 0)) },
	}

	for _, boundary in ipairs(self.boundaries) do
		local target = targets[boundary.Name]
		if target then
			TweenService:Create(boundary, tweenInfo, target):Play()
		end
	end

	for _, post in ipairs(self.cornerPosts) do
		local x = post:GetAttribute("CornerX") or 1
		local z = post:GetAttribute("CornerZ") or 1
		TweenService:Create(post, tweenInfo, {
			CFrame = CFrame.new(self.origin + Vector3.new(x * half, 3.5, z * half)),
		}):Play()
	end

	for _, inlay in ipairs(self.inlays) do
		local offset = -half + (inlay.slot - 1) * (size / 8)
		local target
		if inlay.axis == "X" then
			target = {
				Size = Vector3.new(0.35, 0.08, size),
				CFrame = CFrame.new(self.origin + Vector3.new(offset, -2.92, 0)),
			}
		else
			target = {
				Size = Vector3.new(size, 0.08, 0.35),
				CFrame = CFrame.new(self.origin + Vector3.new(0, -2.91, offset)),
			}
		end
		TweenService:Create(inlay.part, tweenInfo, target):Play()
	end
end

function ArenaBrawl:flashHit(character)
	if not character then
		return
	end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local oldColor = part.Color
			part.Color = Color3.fromRGB(255, 245, 90)
			task.delay(0.16, function()
				if part.Parent then
					part.Color = oldColor
				end
			end)
		end
	end
end

function ArenaBrawl:emitPunch(root)
	local ring = Shared.makePart("PunchRing", Vector3.new(8, 0.16, 8), root.CFrame * CFrame.new(0, -2.3, -3.3) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(255, 82, 82), Enum.Material.Neon, self.folder)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	ring.Transparency = 0.25
	Debris:AddItem(ring, 0.3)
	TweenService:Create(ring, TweenInfo.new(0.28), {
		Size = Vector3.new(16, 0.16, 16),
		Transparency = 1,
	}):Play()
end

function ArenaBrawl:playPunchAnimation(character)
	if not character then
		return
	end

	local motors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			motors[descendant.Name] = descendant
		end
	end

	local function setMotor(name, transform)
		local motor = motors[name]
		if motor then
			motor.Transform = transform
		end
	end

	task.spawn(function()
		local startedAt = os.clock()
		local duration = 0.32
		while character.Parent and os.clock() - startedAt < duration do
			local t = math.clamp((os.clock() - startedAt) / duration, 0, 1)
			local punch = if t < 0.42 then t / 0.42 else 1 - ((t - 0.42) / 0.58)
			local recoil = math.sin(t * math.pi)

			setMotor("Waist", CFrame.Angles(math.rad(-4), math.rad(-12 * recoil), math.rad(7 * recoil)))
			setMotor("Root", CFrame.new(0, 0, -0.08 * recoil) * CFrame.Angles(math.rad(-2 * recoil), 0, 0))
			setMotor("RootJoint", CFrame.new(0, 0, -0.08 * recoil) * CFrame.Angles(math.rad(-2 * recoil), 0, 0))
			setMotor("Neck", CFrame.Angles(math.rad(-4 * recoil), math.rad(6 * recoil), 0))

			setMotor("RightShoulder", CFrame.Angles(math.rad(78 - 58 * punch), math.rad(-18), math.rad(28 - 18 * punch)))
			setMotor("Right Shoulder", CFrame.Angles(math.rad(78 - 58 * punch), math.rad(-18), math.rad(28 - 18 * punch)))
			setMotor("RightElbow", CFrame.Angles(math.rad(-62 + 74 * punch), 0, 0))
			setMotor("RightWrist", CFrame.Angles(math.rad(12 * punch), 0, math.rad(-8 * punch)))

			setMotor("LeftShoulder", CFrame.Angles(math.rad(28), math.rad(14), math.rad(-16)))
			setMotor("Left Shoulder", CFrame.Angles(math.rad(28), math.rad(14), math.rad(-16)))
			setMotor("LeftElbow", CFrame.Angles(math.rad(-28), 0, 0))

			RunService.Heartbeat:Wait()
		end

		for _, name in ipairs({ "Waist", "Root", "RootJoint", "Neck", "RightShoulder", "Right Shoulder", "RightElbow", "RightWrist", "LeftShoulder", "Left Shoulder", "LeftElbow" }) do
			setMotor(name, CFrame.identity)
		end
	end)
end

function ArenaBrawl:punchFrom(subject)
	local humanoid = Shared.humanoidFromSubject(subject)
	local root = Shared.rootFromSubject(subject)
	local character = Shared.characterFromSubject(subject)
	if not humanoid or not root or not character or humanoid.Health <= 0 or Shared.isSpectating(subject) then
		return
	end

	local now = os.clock()
	local lastPunch = self.lastPunchAt[subject] or 0
	if now - lastPunch < PUNCH_COOLDOWN then
		return
	end
	self.lastPunchAt[subject] = now

	humanoid.AutoRotate = false
	task.delay(0.18, function()
		if humanoid.Parent then
			humanoid.AutoRotate = true
		end
	end)

	self:playPunchAnimation(character)
	self:emitPunch(root)
	for _, other in ipairs(Shared.aliveContestants()) do
		local otherRoot = other.root
		if otherRoot and otherRoot ~= root and (otherRoot.Position - root.Position).Magnitude <= 13 then
			local delta = otherRoot.Position - root.Position
			local direction = if delta.Magnitude > 0 then delta.Unit else root.CFrame.LookVector
			local power = 92 * Shared.getStrengthMultiplier(subject)
			otherRoot.AssemblyLinearVelocity = direction * power + Vector3.new(0, 34, 0)
			self:flashHit(other.character)
		end
	end
end

function ArenaBrawl:isOutside(root)
	local delta = root.Position - self.origin
	local half = self.currentSize / 2
	return math.abs(delta.X) > half or math.abs(delta.Z) > half or root.Position.Y < self.origin.Y - 13
end

function ArenaBrawl:run()
	self:updateRingVisual(START_SIZE, 0)
	table.clear(self.lastPunchAt)
	Shared.teleportPlayers(self.origin + Vector3.new(0, 4, 0), 24)
	task.wait(1.2)

	for _, contestant in ipairs(Shared.aliveContestants()) do
		Shared.markContestantForGame(contestant.subject, self.name, true)
	end

	local primaryAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("PrimaryAction")
	local okConnection, actionConnection = pcall(function()
		return primaryAction.OnServerEvent:Connect(function(player, minigameName)
			if minigameName ~= self.name then
				return
			end
			if player:GetAttribute("CurrentMinigame") ~= self.name or player:GetAttribute("AllowPrimaryAction") ~= true then
				return
			end
			self:punchFrom(player)
		end)
	end)
	if not okConnection then
		warn("[ArenaBrawl] PrimaryAction connection unavailable in this context: " .. tostring(actionConnection))
		actionConnection = nil
	end

	self:announce("Arena Brawl: left click to punch, stay inside the square")
	Shared.spawnModifierPickups(self.folder, self.origin + Vector3.new(0, 1, 0), 32)

	local roundEnd = os.clock() + self.context.config.RoundDuration
	local nextShrink = os.clock() + SHRINK_EVERY
	while Shared.roundShouldContinue(roundEnd) do
		if os.clock() >= nextShrink then
			local newSize = math.max(MIN_SIZE, self.currentSize - SHRINK_AMOUNT)
			if newSize < self.currentSize then
				self:announce("Arena Brawl: ring shrinking to " .. math.floor(newSize) .. " studs")
				self:updateRingVisual(newSize, 0.85)
			end
			nextShrink = os.clock() + SHRINK_EVERY
		end

		for _, bot in ipairs(Shared.testBots()) do
			local humanoid = Shared.humanoidFromSubject(bot)
			local botRoot = Shared.rootFromSubject(bot)
			if humanoid and botRoot and humanoid.Health > 0 and not bot:GetAttribute("Eliminated") then
				local target = nil
				local targetDistance = math.huge
				for _, other in ipairs(Shared.aliveContestants()) do
					if other.subject ~= bot and other.root then
						local distance = (other.root.Position - botRoot.Position).Magnitude
						if distance < targetDistance then
							target = other.root
							targetDistance = distance
						end
					end
				end
				if target then
					humanoid:MoveTo(target.Position)
				else
					local half = math.max(8, self.currentSize / 2 - 8)
					local botRange = math.floor(half)
					humanoid:MoveTo(self.origin + Vector3.new(math.random(-botRange, botRange), 1, math.random(-botRange, botRange)))
				end
			end
			if botRoot and math.random() < 0.5 then
				self:punchFrom(bot)
			end
		end

		for _, contestant in ipairs(Shared.aliveContestants()) do
			if contestant.root and self:isOutside(contestant.root) then
				Shared.eliminate(contestant.subject)
			end
		end
		task.wait(0.45)
	end

	if actionConnection then
		actionConnection:Disconnect()
	end
	self:setActionEnabled(false)
	Shared.clearAllPlayerTools()
	self:updateRingVisual(START_SIZE, 0.8)
	Shared.awardSurvivors(self.name, function(message)
		self:announce(message)
	end)
end

return ArenaBrawl
