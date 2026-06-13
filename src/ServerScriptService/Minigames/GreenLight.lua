local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = require(script.Parent.Shared)

local GreenLight = {}
GreenLight.__index = GreenLight

-- Red Light, Green Light. Reach the finish line, but only move while the light
-- is green; any movement caught under the red light eliminates you.
local RUNWAY_LENGTH = 150
local RUNWAY_WIDTH = 44
local FINISH_INSET = 12
local MOVE_TOLERANCE = 2.6
local RED_GRACE = 0.45
local GREEN_MIN = 2.2
local GREEN_MAX = 4.5
local RED_MIN = 1.6
local RED_MAX = 3.2

local GREEN_COLOR = Color3.fromRGB(70, 230, 110)
local RED_COLOR = Color3.fromRGB(255, 70, 70)

function GreenLight.new(context)
	local self = setmetatable({}, GreenLight)
	self.name = "Green Light"
	self.context = context
	self.origin = context.config.Arenas.GreenLight
	self.folder = Instance.new("Folder")
	self.folder.Name = "GreenLight"
	self.folder.Parent = context.rootFolder
	-- Players run along +X from the start line to the finish line.
	self.startX = self.origin.X - RUNWAY_LENGTH / 2 + 8
	self.finishX = self.origin.X + RUNWAY_LENGTH / 2 - FINISH_INSET
	self.deckY = self.origin.Y + 0.6
	self.lightParts = {}
	self.lightState = "Red"
	self:build()
	return self
end

function GreenLight:build()
	local deck = Shared.makePart("GreenLightRunway", Vector3.new(RUNWAY_LENGTH, 1.2, RUNWAY_WIDTH), CFrame.new(self.origin), Color3.fromRGB(196, 170, 120), Enum.Material.Sand, self.folder)
	deck.CanCollide = true
	deck.Anchored = true
	self.deckY = deck.Position.Y + 0.6

	-- Side walls so players cannot run around the field.
	for _, side in ipairs({ 1, -1 }) do
		local wall = Shared.makePart("GreenLightWall", Vector3.new(RUNWAY_LENGTH, 8, 2), CFrame.new(self.origin + Vector3.new(0, 4, side * RUNWAY_WIDTH / 2)), Color3.fromRGB(120, 90, 60), Enum.Material.WoodPlanks, self.folder)
		wall.CanCollide = true
	end

	local startLine = Shared.makePart("GreenLightStartLine", Vector3.new(1.5, 1.4, RUNWAY_WIDTH), CFrame.new(self.origin + Vector3.new(-RUNWAY_LENGTH / 2 + 8, 0.4, 0)), Color3.fromRGB(240, 240, 245), Enum.Material.Neon, self.folder)
	startLine.CanCollide = false

	local finishLine = Shared.makePart("GreenLightFinishLine", Vector3.new(1.8, 1.4, RUNWAY_WIDTH), CFrame.new(Vector3.new(self.finishX, self.origin.Y + 0.4, self.origin.Z), self.origin), Color3.fromRGB(255, 215, 70), Enum.Material.Neon, self.folder)
	finishLine.CanCollide = false

	-- Winners pen past the finish line where finished players wait out the round.
	self.penPosition = Vector3.new(self.finishX + 14, self.origin.Y + 1, self.origin.Z)
	local pen = Shared.makePart("GreenLightWinnersPen", Vector3.new(18, 1, RUNWAY_WIDTH), CFrame.new(self.penPosition - Vector3.new(0, 0.4, 0)), Color3.fromRGB(90, 180, 230), Enum.Material.SmoothPlastic, self.folder)
	pen.CanCollide = true

	self:buildDoll()

	Shared.makeBillboard("GreenLightSign", "Green Light: run on GREEN, freeze on RED, reach the finish", self.origin + Vector3.new(0, 16, -RUNWAY_WIDTH / 2 - 6), self.folder)
end

function GreenLight:buildDoll()
	local dollBase = Vector3.new(self.finishX + 8, self.origin.Y + 1, self.origin.Z)
	local model = Instance.new("Model")
	model.Name = "GreenLightDoll"

	local body = Shared.makePart("DollBody", Vector3.new(4, 10, 3), CFrame.new(dollBase + Vector3.new(0, 5, 0)), Color3.fromRGB(255, 150, 40), Enum.Material.SmoothPlastic, model)
	body.CanCollide = false
	local head = Shared.makePart("DollHead", Vector3.new(3.2, 3, 3), CFrame.new(dollBase + Vector3.new(0, 11.5, 0)), Color3.fromRGB(250, 224, 196), Enum.Material.SmoothPlastic, model)
	head.Shape = Enum.PartType.Ball
	head.CanCollide = false

	-- A face plate marks the front so players can read which way the doll looks.
	local face = Shared.makePart("DollFace", Vector3.new(0.4, 1.4, 2), CFrame.new(dollBase + Vector3.new(-1.7, 11.5, 0)), Color3.fromRGB(30, 30, 35), Enum.Material.Neon, model)
	face.CanCollide = false

	-- Light orb above the doll communicates the current state at a glance.
	local orb = Shared.makePart("DollLightOrb", Vector3.new(3, 3, 3), CFrame.new(dollBase + Vector3.new(0, 15, 0)), RED_COLOR, Enum.Material.Neon, model)
	orb.Shape = Enum.PartType.Ball
	orb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = RED_COLOR
	light.Range = 30
	light.Brightness = 3
	light.Parent = orb

	model.PrimaryPart = body
	model.Parent = self.folder
	self.doll = model
	self.dollOrb = orb
	self.dollLight = light
	self.dollBase = dollBase
	-- Facing the players (toward -X) means red light is being watched.
	self.dollWatchCFrame = CFrame.lookAt(dollBase, dollBase - Vector3.new(1, 0, 0))
	self.dollAwayCFrame = CFrame.lookAt(dollBase, dollBase + Vector3.new(1, 0, 0))
	model:PivotTo(self.dollWatchCFrame)
end

function GreenLight:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[GreenLight] " .. message)
end

function GreenLight:setLight(state)
	self.lightState = state
	local color = state == "Green" and GREEN_COLOR or RED_COLOR
	if self.dollOrb then
		self.dollOrb.Color = color
	end
	if self.dollLight then
		self.dollLight.Color = color
	end
	if self.doll then
		self.doll:PivotTo(state == "Green" and self.dollAwayCFrame or self.dollWatchCFrame)
	end
end

function GreenLight:flashElimination(root)
	if not root then
		return
	end
	local burst = Shared.makePart("GreenLightHitBurst", Vector3.new(3, 3, 3), root.CFrame, RED_COLOR, Enum.Material.Neon, self.folder)
	burst.Shape = Enum.PartType.Ball
	burst.CanCollide = false
	Debris:AddItem(burst, 0.3)
	TweenService:Create(burst, TweenInfo.new(0.28), { Size = Vector3.new(10, 10, 10), Transparency = 1 }):Play()
end

function GreenLight:hasFinished(contestant)
	return contestant.root and contestant.root.Position.X >= self.finishX
end

function GreenLight:sendToPen(contestant)
	contestant.subject:SetAttribute("GreenLightFinished", true)
	if contestant.root then
		contestant.root.CFrame = CFrame.new(self.penPosition + Vector3.new(0, 3, 0))
		contestant.root.AssemblyLinearVelocity = Vector3.zero
	end
end

function GreenLight:isFinished(contestant)
	return contestant.subject:GetAttribute("GreenLightFinished") == true
end

function GreenLight:snapshotPositions()
	local snapshot = {}
	for _, contestant in ipairs(Shared.aliveContestants()) do
		if contestant.root and not self:isFinished(contestant) then
			snapshot[contestant.subject] = contestant.root.Position
		end
	end
	return snapshot
end

function GreenLight:driveBots(greenLight)
	for _, bot in ipairs(Shared.testBots()) do
		local humanoid = Shared.humanoidFromSubject(bot)
		local root = Shared.rootFromSubject(bot)
		if humanoid and root and humanoid.Health > 0 and not bot:GetAttribute("Eliminated") and bot:GetAttribute("GreenLightFinished") ~= true then
			if greenLight then
				humanoid:MoveTo(Vector3.new(self.finishX + 4, root.Position.Y, root.Position.Z))
			else
				humanoid:MoveTo(root.Position)
			end
		end
	end
end

function GreenLight:run()
	for _, contestant in ipairs(Shared.aliveContestants()) do
		Shared.markContestantForGame(contestant.subject, self.name, false)
		contestant.subject:SetAttribute("GreenLightFinished", false)
		if contestant.humanoid then
			contestant.humanoid.WalkSpeed = 16
			contestant.humanoid.JumpPower = 0
			contestant.humanoid.JumpHeight = 0
		end
	end

	-- Line everyone up across the start line.
	local index = 0
	for _, contestant in ipairs(Shared.aliveContestants()) do
		if contestant.root then
			local laneZ = self.origin.Z + ((index % 9) - 4) * 4
			contestant.root.CFrame = CFrame.new(Vector3.new(self.startX, self.deckY + 3, laneZ))
			contestant.root.AssemblyLinearVelocity = Vector3.zero
			index += 1
		end
	end

	self:setLight("Red")
	self:announce("Green Light: get ready...")
	task.wait(1.5)

	local roundEnd = os.clock() + self.context.config.RoundDuration

	while Shared.roundShouldContinue(roundEnd) do
		-- GREEN: doll looks away, everyone may run.
		self:setLight("Green")
		self:announce("GREEN LIGHT - run!")
		self:driveBots(true)
		local greenTime = math.random(GREEN_MIN * 10, GREEN_MAX * 10) / 10
		local greenEnd = os.clock() + greenTime
		while os.clock() < greenEnd and Shared.roundShouldContinue(roundEnd) do
			for _, contestant in ipairs(Shared.aliveContestants()) do
				if not self:isFinished(contestant) and self:hasFinished(contestant) then
					self:sendToPen(contestant)
				end
			end
			if self:allFinished() then
				break
			end
			task.wait(0.1)
		end

		if self:allFinished() or not Shared.roundShouldContinue(roundEnd) then
			break
		end

		-- RED: doll turns. A short grace lets players brake before checks begin.
		self:setLight("Red")
		self:announce("RED LIGHT - FREEZE!")
		self:driveBots(false)
		task.wait(RED_GRACE)
		local snapshot = self:snapshotPositions()
		local redTime = math.random(RED_MIN * 10, RED_MAX * 10) / 10
		local redEnd = os.clock() + redTime
		while os.clock() < redEnd and Shared.roundShouldContinue(roundEnd) do
			for _, contestant in ipairs(Shared.aliveContestants()) do
				if not self:isFinished(contestant) and contestant.root then
					if self:hasFinished(contestant) then
						self:sendToPen(contestant)
					else
						local origin = snapshot[contestant.subject]
						if origin then
							local moved = (Vector3.new(contestant.root.Position.X, 0, contestant.root.Position.Z) - Vector3.new(origin.X, 0, origin.Z)).Magnitude
							if moved > MOVE_TOLERANCE then
								self:flashElimination(contestant.root)
								Shared.eliminate(contestant.subject)
							end
						else
							snapshot[contestant.subject] = contestant.root.Position
						end
					end
				end
			end
			task.wait(0.08)
		end
	end

	self:setLight("Green")
	Shared.awardSurvivors(self.name, function(message)
		self:announce(message)
	end)
end

function GreenLight:allFinished()
	local any = false
	for _, contestant in ipairs(Shared.aliveContestants()) do
		any = true
		if not self:isFinished(contestant) then
			return false
		end
	end
	return any
end

return GreenLight
