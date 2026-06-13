local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = require(script.Parent.Shared)

local LaserJump = {}
LaserJump.__index = LaserJump

local START_RADIUS = 56
local MIN_RADIUS = 26
local START_SPEED = 0.78
local SPEED_MULTIPLIER = 1.1
local LASER_WIDTH = 2.1
local FLOOR_Y_OFFSET = -0.85
local FLOOR_TOP_OFFSET = FLOOR_Y_OFFSET + 0.7
local JUMP_CLEAR_ROOT_OFFSET = FLOOR_TOP_OFFSET + 4.05
local WAVE_INTERVAL = 11
local SHOCKWAVE_TRAVEL = 1.4

-- Wave script. Each wave escalates: more rotating beams, faster spin, a smaller
-- deck, and from wave 2 an expanding shockwave you have to JUMP over. Inspired by
-- the rotating-beam survival rounds in party games like Fall Guys.
local WAVES = {
	{ beams = { "JumpA" }, label = "JUMP the red beam" },
	{ beams = { "JumpA", "DuckA" }, label = "JUMP red, DUCK blue" },
	{ beams = { "JumpA", "DuckA", "JumpB" }, shockwave = true, label = "Two red beams + shockwaves" },
	{ beams = { "JumpA", "JumpB", "DuckA", "DuckB" }, shockwave = true, label = "Four beams, deck shrinking" },
	{ beams = { "JumpA", "JumpB", "DuckA", "DuckB" }, shockwave = true, shrink = true, label = "SUDDEN DEATH" },
}

local BEAM_DEFINITIONS = {
	JumpA = { kind = "Jump", angle = 0, heightOffset = 1.15, color = Color3.fromRGB(255, 72, 72), spin = 1 },
	JumpB = { kind = "Jump", angle = math.pi, heightOffset = 1.15, color = Color3.fromRGB(255, 130, 60), spin = -1 },
	DuckA = { kind = "Prone", angle = math.rad(92), heightOffset = 4.15, color = Color3.fromRGB(70, 220, 255), spin = 1 },
	DuckB = { kind = "Prone", angle = math.rad(268), heightOffset = 4.15, color = Color3.fromRGB(150, 120, 255), spin = -1 },
}

function LaserJump.new(context)
	local self = setmetatable({}, LaserJump)
	self.name = "Laser Jump"
	self.context = context
	self.origin = context.config.Arenas.LaserJump
	self.folder = Instance.new("Folder")
	self.folder.Name = "LaserJump"
	self.folder.Parent = context.rootFolder
	self.beams = {}
	self.beamParts = {}
	self.floor = nil
	self.floorTopY = self.origin.Y + FLOOR_TOP_OFFSET
	self.pulseParts = {}
	self.deckRings = {}
	self.angularSpeed = START_SPEED
	self.baseAngle = 0
	self.currentRadius = START_RADIUS
	self.shockwave = nil
	self:build()
	return self
end

function LaserJump:build()
	local floorCenter = self.origin + Vector3.new(0, FLOOR_Y_OFFSET, 0)
	local floor = Shared.makePart("LaserJumpFullRoundDeck", Vector3.new(START_RADIUS * 2 + 10, 2.2, START_RADIUS * 2 + 10), CFrame.new(floorCenter - Vector3.new(0, 0.4, 0)), Color3.fromRGB(35, 44, 57), Enum.Material.Metal, self.folder)
	floor.CanCollide = true
	floor.CanTouch = true
	floor:SetAttribute("Purpose", "SolidPlayerFloor")
	self.floor = floor

	local roundVisual = Shared.makePart("LaserJumpRoundVisualDeck", Vector3.new(START_RADIUS * 2, 0.22, START_RADIUS * 2), CFrame.new(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 0.03, 0)), Color3.fromRGB(62, 88, 105), Enum.Material.Neon, self.folder)
	roundVisual.Shape = Enum.PartType.Cylinder
	roundVisual.Transparency = 0.45
	roundVisual.CanCollide = false
	roundVisual.CanTouch = false
	roundVisual.CanQuery = false

	local underGlow = Shared.makePart("LaserJumpUnderGlow", Vector3.new(START_RADIUS * 2 + 10, 0.35, START_RADIUS * 2 + 10), CFrame.new(self.origin + Vector3.new(0, FLOOR_Y_OFFSET - 1, 0)), Color3.fromRGB(40, 220, 255), Enum.Material.Neon, self.folder)
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

	local ceiling = Shared.makePart("LaserJumpCeilingLock", Vector3.new(START_RADIUS * 1.1, 2.5, START_RADIUS * 1.1), CFrame.new(self.origin + Vector3.new(0, 74, 0)), Color3.fromRGB(29, 35, 48), Enum.Material.Metal, self.folder)
	ceiling.Shape = Enum.PartType.Cylinder

	-- Concentric deck rings double as the shrink indicator: outer rings dim as the
	-- safe radius closes in during later waves.
	for ring = 1, 3 do
		local radius = START_RADIUS - ring * 9
		local ringPart = Shared.makePart("MechaDeckRing", Vector3.new(radius * 2, 0.16, radius * 2), CFrame.new(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 0.08 + ring * 0.04, 0)), Color3.fromRGB(65, 98, 118), Enum.Material.Neon, self.folder)
		ringPart.Shape = Enum.PartType.Cylinder
		ringPart.Transparency = 0.74
		ringPart.CanCollide = false
		table.insert(self.deckRings, { part = ringPart, radius = radius })
	end

	for index = 1, 16 do
		local angle = (math.pi * 2 / 16) * index
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local rail = Shared.makePart("LaserJumpOuterRail", Vector3.new(1.2, 5, 8), CFrame.lookAt(self.origin + dir * START_RADIUS + Vector3.new(0, FLOOR_TOP_OFFSET + 2.4, 0), self.origin), Color3.fromRGB(16, 20, 29), Enum.Material.Metal, self.folder)
		rail.CanCollide = false
	end

	-- Danger ring: a neon cylinder that marks the live safe radius, shrinking with it.
	local dangerRing = Shared.makePart("LaserJumpDangerRing", Vector3.new(START_RADIUS * 2, 0.6, START_RADIUS * 2), CFrame.new(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 0.2, 0)), Color3.fromRGB(255, 80, 90), Enum.Material.Neon, self.folder)
	dangerRing.Shape = Enum.PartType.Cylinder
	dangerRing.Transparency = 0.86
	dangerRing.CanCollide = false
	dangerRing.CanTouch = false
	dangerRing.CanQuery = false
	self.dangerRing = dangerRing

	-- Expanding shockwave puck that rises from the core; players must JUMP it.
	local shockwave = Shared.makePart("LaserJumpShockwave", Vector3.new(2, 0.5, 2), CFrame.new(self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 0.9, 0)), Color3.fromRGB(255, 200, 60), Enum.Material.Neon, self.folder)
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Transparency = 1
	shockwave.CanCollide = false
	shockwave.CanTouch = false
	shockwave.CanQuery = false
	self.shockwavePart = shockwave

	Shared.makeBillboard("LaserJumpSign", "Laser Arena: JUMP red, DUCK blue, leap the shockwave", self.origin + Vector3.new(0, 14, -68), self.folder)
end

function LaserJump:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[LaserJump] " .. message)
end

function LaserJump:setActiveBeams(beamNames, shockwaveOn)
	for _, entry in ipairs(self.beamParts) do
		entry.part:Destroy()
	end
	table.clear(self.beamParts)
	table.clear(self.beams)

	for _, beamName in ipairs(beamNames) do
		local definition = BEAM_DEFINITIONS[beamName]
		if definition then
			local length = self.currentRadius * 2 - 12
			local laser = Shared.makePart("LaserBeam_" .. beamName, Vector3.new(LASER_WIDTH, 0.46, length), CFrame.new(self.origin), definition.color, Enum.Material.Neon, self.folder)
			laser.CanCollide = false
			laser.CanTouch = false
			laser:SetAttribute("LaserKind", definition.kind)

			local light = Instance.new("PointLight")
			light.Color = definition.color
			light.Range = 18
			light.Brightness = 2.3
			light.Parent = laser

			table.insert(self.beamParts, { part = laser })
			table.insert(self.beams, {
				part = laser,
				kind = definition.kind,
				angleOffset = definition.angle,
				heightOffset = definition.heightOffset,
				color = definition.color,
				spin = definition.spin,
				length = length,
			})
		end
	end

	self.shockwaveEnabled = shockwaveOn == true
end

function LaserJump:updateBeamVisuals(deltaTime)
	self.baseAngle += deltaTime * self.angularSpeed
	for _, beam in ipairs(self.beams) do
		local angle = self.baseAngle * beam.spin + beam.angleOffset
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + beam.heightOffset, 0)
		beam.part.CFrame = CFrame.lookAt(position, position + dir)
	end

	for _, pulse in ipairs(self.pulseParts) do
		local targetTransparency = 0.66 + math.sin(os.clock() * 5) * 0.08
		pulse.Transparency = math.clamp(targetTransparency, 0.52, 0.82)
	end

	if self.dangerRing then
		self.dangerRing.Transparency = 0.78 + math.sin(os.clock() * 4) * 0.06
	end
end

function LaserJump:beamHitsContestant(beam, contestant)
	local root = contestant.root
	if not root then
		return false
	end

	local angle = self.baseAngle * beam.spin + beam.angleOffset
	local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local delta = root.Position - self.origin
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local projection = flat:Dot(dir)
	local perpendicular = (flat - dir * projection).Magnitude

	if math.abs(projection) > beam.length / 2 or perpendicular > LASER_WIDTH then
		return false
	end

	if beam.kind == "Jump" then
		return root.Position.Y < self.origin.Y + JUMP_CLEAR_ROOT_OFFSET
	end

	return not Shared.isProne(contestant.subject)
end

function LaserJump:startShockwave()
	self.shockwave = { startedAt = os.clock(), radius = 2 }
	if self.shockwavePart then
		self.shockwavePart.Transparency = 0.25
	end
end

function LaserJump:updateShockwave()
	if not self.shockwave then
		return
	end
	local elapsed = os.clock() - self.shockwave.startedAt
	local radius = 2 + elapsed * (self.currentRadius / SHOCKWAVE_TRAVEL)
	self.shockwave.radius = radius
	if self.shockwavePart then
		self.shockwavePart.Size = Vector3.new(radius * 2, 0.5, radius * 2)
	end
	if radius >= self.currentRadius then
		self.shockwave = nil
		if self.shockwavePart then
			self.shockwavePart.Transparency = 1
		end
	end
end

function LaserJump:shockwaveHits(contestant)
	if not self.shockwave or not contestant.root then
		return false
	end
	local flat = Vector3.new(contestant.root.Position.X - self.origin.X, 0, contestant.root.Position.Z - self.origin.Z)
	local distance = flat.Magnitude
	-- Hits a 4-stud-wide expanding band unless the player has jumped above it.
	if math.abs(distance - self.shockwave.radius) > 2 then
		return false
	end
	return contestant.root.Position.Y < self.origin.Y + JUMP_CLEAR_ROOT_OFFSET
end

function LaserJump:setRadius(radius)
	self.currentRadius = math.clamp(radius, MIN_RADIUS, START_RADIUS)
	if self.dangerRing then
		self.dangerRing.Size = Vector3.new(self.currentRadius * 2, 0.6, self.currentRadius * 2)
	end
	for _, beam in ipairs(self.beams) do
		beam.length = self.currentRadius * 2 - 12
		beam.part.Size = Vector3.new(LASER_WIDTH, 0.46, beam.length)
	end
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
	return flat.Magnitude <= self.currentRadius + 3 and root.Position.Y > self.floorTopY - 18
end

function LaserJump:updateBots()
	for _, bot in ipairs(Shared.testBots()) do
		local humanoid = Shared.humanoidFromSubject(bot)
		local root = Shared.rootFromSubject(bot)
		if humanoid and root and humanoid.Health > 0 and not bot:GetAttribute("Eliminated") then
			local angle = math.random() * math.pi * 2
			local distance = math.random(8, math.max(9, math.floor(self.currentRadius) - 9))
			humanoid:MoveTo(Vector3.new(self.origin.X + math.cos(angle) * distance, self.floorTopY + 3, self.origin.Z + math.sin(angle) * distance))

			local shouldProne = false
			for _, beam in ipairs(self.beams) do
				if beam.kind == "Prone" and self:beamHitsContestant(beam, { root = root, subject = bot }) then
					shouldProne = true
				elseif beam.kind == "Jump" and math.random() < 0.35 then
					humanoid.Jump = true
				end
			end
			if self.shockwave and math.random() < 0.5 then
				humanoid.Jump = true
			end
			bot:SetAttribute("IsProne", shouldProne)
		end
	end
end

function LaserJump:run()
	self.angularSpeed = START_SPEED
	self.baseAngle = 0
	self:setRadius(START_RADIUS)
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

	self:setActiveBeams(WAVES[1].beams, false)
	self:announce("Laser Arena: JUMP the red beam, hold C / Left-Ctrl to duck blue")
	task.wait(1.2)

	local roundEnd = os.clock() + self.context.config.RoundDuration
	local nextWaveAt = os.clock() + WAVE_INTERVAL
	local nextShockwaveAt = os.clock() + 4
	local nextBotUpdate = 0
	local lastClock = os.clock()
	local waveIndex = 1

	while Shared.roundShouldContinue(roundEnd) do
		local now = os.clock()
		local deltaTime = math.clamp(now - lastClock, 0, 0.1)
		lastClock = now

		self:updateBeamVisuals(deltaTime)
		self:updateShockwave()

		if now >= nextWaveAt then
			waveIndex = math.min(waveIndex + 1, #WAVES)
			local wave = WAVES[waveIndex]
			self.angularSpeed *= SPEED_MULTIPLIER
			self:setActiveBeams(wave.beams, wave.shockwave)
			if wave.shrink then
				self:setRadius(MIN_RADIUS)
			elseif waveIndex >= 4 then
				self:setRadius(self.currentRadius - 12)
			end
			self:announce("Wave " .. waveIndex .. ": " .. wave.label)
			Shared.spawnModifierPickups(self.folder, self.origin + Vector3.new(0, FLOOR_TOP_OFFSET + 1, 0), self.currentRadius * 0.6, 1)
			nextWaveAt = now + WAVE_INTERVAL
		end

		if self.shockwaveEnabled and not self.shockwave and now >= nextShockwaveAt then
			self:startShockwave()
			nextShockwaveAt = now + math.random(45, 70) / 10
		end

		if now >= nextBotUpdate then
			self:updateBots()
			nextBotUpdate = now + 0.5
		end

		for _, contestant in ipairs(Shared.aliveContestants()) do
			if contestant.root and not self:insideArena(contestant.root) then
				Shared.eliminate(contestant.subject)
			elseif self:shockwaveHits(contestant) then
				self:playEliminationFlash(contestant.root, Color3.fromRGB(255, 200, 60))
				Shared.eliminate(contestant.subject)
			else
				for _, beam in ipairs(self.beams) do
					if self:beamHitsContestant(beam, contestant) then
						self:playEliminationFlash(contestant.root, beam.color)
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
