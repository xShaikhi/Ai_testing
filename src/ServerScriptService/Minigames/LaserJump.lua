local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = require(script.Parent.Shared)

local LaserJump = {}
LaserJump.__index = LaserJump

local RADIUS = 56
local START_SPEED = 0.78
local SPEED_UP_EVERY = 12
local SPEED_MULTIPLIER = 1.12
local LASER_WIDTH = 2.1
local FLOOR_Y_OFFSET = -0.85
local FLOOR_TOP_OFFSET = FLOOR_Y_OFFSET + 0.7
local JUMP_CLEAR_ROOT_OFFSET = FLOOR_TOP_OFFSET + 4.05

local LASER_DEFINITIONS = {
	{ name = "GroundJumpLaser", kind = "Jump", angle = 0, height = FLOOR_TOP_OFFSET + 1.15, color = Color3.fromRGB(255, 72, 72) },
	{ name = "HeadCrouchLaser", kind = "Prone", angle = math.rad(92), height = FLOOR_TOP_OFFSET + 4.15, color = Color3.fromRGB(70, 220, 255) },
}

function LaserJump.new(context)
	local self = setmetatable({}, LaserJump)
	self.name = "Laser Jump"
	self.context = context
	self.origin = context.config.Arenas.LaserJump
	self.folder = Instance.new("Folder")
	self.folder.Name = "LaserJump"
	self.folder.Parent = context.rootFolder
	self.lasers = {}
	self.floor = nil
	self.floorTopY = self.origin.Y + FLOOR_TOP_OFFSET
	self.pulseParts = {}
	self.angularSpeed = START_SPEED
	self.baseAngle = 0
	self:build()
	return self
end

function LaserJump:build()
	local floorCenter = self.origin + Vector3.new(0, FLOOR_Y_OFFSET, 0)
	local floor = Shared.makePart("LaserJumpFullRoundDeck", Vector3.new(RADIUS * 2 + 10, 2.2, RADIUS * 2 + 10), CFrame.new(floorCenter - Vector3.new(0, 0.4, 0)), Color3.fromRGB(35, 44, 57), Enum.Material.Metal, self.folder)
	floor.CanCollide = true
	floor.CanTouch = true
	floor:SetAttribute("Purpose", "SolidPlayerFloor")
	self.floor = floor

	local roundVisual = Shared.makePart("LaserJumpRoundVisualDeck", Vector3.new(RADIUS * 2, 0.22, RADIUS * 2), CFrame.new(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 0.03, 0)), Color3.fromRGB(62, 88, 105), Enum.Material.Neon, self.folder)
	roundVisual.Shape = Enum.PartType.Cylinder
	roundVisual.Transparency = 0.45
	roundVisual.CanCollide = false
	roundVisual.CanTouch = false
	roundVisual.CanQuery = false

	local underGlow = Shared.makePart("LaserJumpUnderGlow", Vector3.new(RADIUS * 2 + 10, 0.35, RADIUS * 2 + 10), CFrame.new(self.origin + Vector3.new(0, FLOOR_Y_OFFSET - 1, 0)), Color3.fromRGB(40, 220, 255), Enum.Material.Neon, self.folder)
	underGlow.Shape = Enum.PartType.Cylinder
	underGlow.Transparency = 0.55
	underGlow.CanCollide = false

	local pillar = Shared.makePart("LaserJumpCorePillar", Vector3.new(9, 78, 9), CFrame.new(self.origin + Vector3.new(0, 35, 0)), Color3.fromRGB(18, 22, 30), Enum.Material.Metal, self.folder)
	pillar.Shape = Enum.PartType.Cylinder

	local coreGlow = Shared.makePart("LaserJumpCoreGlow", Vector3.new(10.5, 76, 10.5), CFrame.new(self.origin + Vector3.new(0, 35, 0)), Color3.fromRGB(70, 220, 255), Enum.Material.Neon, self.folder)
	coreGlow.Shape = Enum.PartType.Cylinder
	coreGlow.Transparency = 0.78
	coreGlow.CanCollide = false
	table.insert(self.pulseParts, coreGlow)

	local ceiling = Shared.makePart("LaserJumpCeilingLock", Vector3.new(RADIUS * 1.1, 2.5, RADIUS * 1.1), CFrame.new(self.origin + Vector3.new(0, 74, 0)), Color3.fromRGB(29, 35, 48), Enum.Material.Metal, self.folder)
	ceiling.Shape = Enum.PartType.Cylinder

	for ring = 1, 3 do
		local radius = RADIUS - ring * 9
		local ringPart = Shared.makePart("MechaDeckRing", Vector3.new(radius * 2, 0.16, radius * 2), CFrame.new(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 0.08 + ring * 0.04, 0)), Color3.fromRGB(65, 98, 118), Enum.Material.Neon, self.folder)
		ringPart.Shape = Enum.PartType.Cylinder
		ringPart.Transparency = 0.74
		ringPart.CanCollide = false
	end

	for index = 1, 16 do
		local angle = (math.pi * 2 / 16) * index
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local rail = Shared.makePart("LaserJumpOuterRail", Vector3.new(1.2, 5, 8), CFrame.lookAt(self.origin + dir * RADIUS + Vector3.new(0, FLOOR_TOP_OFFSET + 2.4, 0), self.origin), Color3.fromRGB(16, 20, 29), Enum.Material.Metal, self.folder)
		rail.CanCollide = false
	end

	for _, definition in ipairs(LASER_DEFINITIONS) do
		local laser = Shared.makePart(definition.name, Vector3.new(LASER_WIDTH, 0.46, RADIUS * 2 - 12), CFrame.new(self.origin), definition.color, Enum.Material.Neon, self.folder)
		laser.CanCollide = false
		laser.CanTouch = false
		laser:SetAttribute("LaserKind", definition.kind)

		local light = Instance.new("PointLight")
		light.Color = definition.color
		light.Range = 18
		light.Brightness = 2.3
		light.Parent = laser

		table.insert(self.lasers, {
			part = laser,
			kind = definition.kind,
			angleOffset = definition.angle,
			height = definition.height,
			color = definition.color,
			length = RADIUS * 2 - 12,
		})
	end

	Shared.makeBillboard("LaserJumpSign", "Laser Jump: jump red, hold Crouch for blue", self.origin + Vector3.new(0, 14, -68), self.folder)
end

function LaserJump:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[LaserJump] " .. message)
end

function LaserJump:updateLaserVisuals(deltaTime)
	self.baseAngle += deltaTime * self.angularSpeed
	for _, laser in ipairs(self.lasers) do
		local angle = self.baseAngle + laser.angleOffset
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = self.origin + Vector3.new(0, laser.height, 0)
		laser.part.CFrame = CFrame.lookAt(position, position + dir)
	end

	for _, pulse in ipairs(self.pulseParts) do
		local targetTransparency = 0.66 + math.sin(os.clock() * 5) * 0.08
		pulse.Transparency = math.clamp(targetTransparency, 0.52, 0.82)
	end
end

function LaserJump:laserHitsContestant(laser, contestant)
	local root = contestant.root
	if not root then
		return false
	end

	local angle = self.baseAngle + laser.angleOffset
	local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local delta = root.Position - self.origin
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local projection = flat:Dot(dir)
	local perpendicular = (flat - dir * projection).Magnitude

	if math.abs(projection) > laser.length / 2 or perpendicular > LASER_WIDTH then
		return false
	end

	if laser.kind == "Jump" then
		return root.Position.Y < self.origin.Y + JUMP_CLEAR_ROOT_OFFSET
	end

	return not Shared.isProne(contestant.subject)
end

function LaserJump:playEliminationFlash(root, color)
	local burst = Shared.makePart("LaserHitBurst", Vector3.new(3, 3, 3), root.CFrame, color, Enum.Material.Neon, self.folder)
	burst.Shape = Enum.PartType.Ball
	burst.CanCollide = false
	burst.Transparency = 0.15
	Debris:AddItem(burst, 0.28)
	TweenService:Create(burst, TweenInfo.new(0.26), {
		Size = Vector3.new(11, 11, 11),
		Transparency = 1,
	}):Play()
end

function LaserJump:insideArena(root)
	local flat = Vector3.new(root.Position.X - self.origin.X, 0, root.Position.Z - self.origin.Z)
	return flat.Magnitude <= RADIUS + 3 and root.Position.Y > self.floorTopY - 18
end

function LaserJump:updateBots()
	for _, bot in ipairs(Shared.testBots()) do
		local humanoid = Shared.humanoidFromSubject(bot)
		local root = Shared.rootFromSubject(bot)
		if humanoid and root and humanoid.Health > 0 and not bot:GetAttribute("Eliminated") then
			local angle = math.random() * math.pi * 2
			local distance = math.random(10, RADIUS - 9)
			humanoid:MoveTo(Vector3.new(self.origin.X + math.cos(angle) * distance, self.floorTopY + 3, self.origin.Z + math.sin(angle) * distance))

			local shouldProne = false
			for _, laser in ipairs(self.lasers) do
				if laser.kind == "Prone" and self:laserHitsContestant(laser, {
					root = root,
					subject = bot,
				}) then
					shouldProne = true
				elseif laser.kind == "Jump" and math.random() < 0.35 then
					humanoid.Jump = true
				end
			end
			bot:SetAttribute("IsProne", shouldProne)
		end
	end
end

function LaserJump:run()
	self.angularSpeed = START_SPEED
	self.baseAngle = 0
	Shared.teleportPlayers(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 5, 0), 25)

	for _, contestant in ipairs(Shared.aliveContestants()) do
		Shared.markContestantForGame(contestant.subject, self.name, false)
		contestant.subject:SetAttribute("AllowProne", true)
		contestant.subject:SetAttribute("IsProne", false)
		if contestant.humanoid then
			contestant.humanoid.JumpPower = 52
			contestant.humanoid.JumpHeight = 7.2
			contestant.humanoid.WalkSpeed = math.max(contestant.humanoid.WalkSpeed, 18)
		end
	end

	self:announce("Laser Jump: JUMP the red laser, hold C / Left-Ctrl to duck the blue laser")
	task.wait(1.2)

	local roundEnd = os.clock() + self.context.config.RoundDuration
	local nextSpeedUp = os.clock() + SPEED_UP_EVERY
	local nextBotUpdate = 0
	local lastClock = os.clock()

	while Shared.roundShouldContinue(roundEnd) do
		local now = os.clock()
		local deltaTime = math.clamp(now - lastClock, 0, 0.1)
		lastClock = now

		self:updateLaserVisuals(deltaTime)

		if now >= nextSpeedUp then
			self.angularSpeed *= SPEED_MULTIPLIER
			self:announce("Laser Jump: lasers speeding up x" .. string.format("%.2f", self.angularSpeed / START_SPEED))
			nextSpeedUp = now + SPEED_UP_EVERY
		end

		if now >= nextBotUpdate then
			self:updateBots()
			nextBotUpdate = now + 0.65
		end

		for _, contestant in ipairs(Shared.aliveContestants()) do
			if contestant.root and not self:insideArena(contestant.root) then
				Shared.eliminate(contestant.subject)
			else
				for _, laser in ipairs(self.lasers) do
					if self:laserHitsContestant(laser, contestant) then
						self:playEliminationFlash(contestant.root, laser.color)
						Shared.eliminate(contestant.subject)
						break
					end
				end
			end
		end

		task.wait(0.04)
	end

	for _, contestant in ipairs(Shared.aliveContestants()) do
		contestant.subject:SetAttribute("AllowProne", false)
		Shared.setProne(contestant.subject, false)
	end

	Shared.awardSurvivors(self.name, function(message)
		self:announce(message)
	end)
end

return LaserJump
