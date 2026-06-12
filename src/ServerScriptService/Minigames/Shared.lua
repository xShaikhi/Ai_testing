local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = {}

local activePickups = {}
local originalScales = {}
local originalProneState = {}
local testBots = {}
local remotesBound = false

local function getOrCreate(parent, className, name)
	local instance = parent:FindFirstChild(name)
	if instance and instance:IsA(className) then
		return instance
	end

	if instance then
		instance:Destroy()
	end

	instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

function Shared.ensureRemotes()
	local remotes = getOrCreate(ReplicatedStorage, "Folder", "Remotes")
	local movement = getOrCreate(remotes, "Folder", "Movement")
	getOrCreate(movement, "RemoteEvent", "SetProne")
	local combat = getOrCreate(remotes, "Folder", "Combat")
	getOrCreate(combat, "RemoteEvent", "PrimaryAction")
	return remotes
end

function Shared.bindMovementRemotes()
	if remotesBound then
		return
	end

	local remotes = Shared.ensureRemotes()
	if not RunService:IsServer() then
		return
	end

	remotesBound = true
	local movement = remotes:WaitForChild("Movement")
	local setProne = movement:WaitForChild("SetProne")

	setProne.OnServerEvent:Connect(function(player, enabled)
		Shared.setProne(player, enabled == true)
	end)
end

function Shared.makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function Shared.makeSpawn(name, position, parent)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(position)
	spawn.Color = Color3.fromRGB(70, 185, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = parent
	return spawn
end

function Shared.makeCylinder(name, radius, height, cframe, color, material, parent)
	local cylinder = Shared.makePart(name, Vector3.new(radius * 2, height, radius * 2), cframe, color, material, parent)
	cylinder.Shape = Enum.PartType.Cylinder
	return cylinder
end

function Shared.makeInvisibleTrigger(name, size, cframe, parent)
	local trigger = Shared.makePart(name, size, cframe, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, parent)
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.CanTouch = true
	trigger.CanQuery = false
	return trigger
end

function Shared.makeBillboard(name, text, position, parent)
	local holder = Shared.makePart(name .. "Holder", Vector3.new(1, 1, 1), CFrame.new(position), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, parent)
	holder.Transparency = 1
	holder.CanCollide = false

	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(460, 110)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = holder

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = gui
	return label
end

local function weldToRoot(root, part, offset)
	part.CFrame = root.CFrame * CFrame.new(offset)
	part.Anchored = false
	part.Massless = false
	part.Parent = root.Parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	return part
end

function Shared.createTestBots(parent, lobbySpawn, count)
	table.clear(testBots)

	local folder = Instance.new("Folder")
	folder.Name = "TestNPCs"
	folder.Parent = parent

	for index = 1, count do
		local model = Instance.new("Model")
		model.Name = "PracticeNPC_" .. index
		model:SetAttribute("IsTestBot", true)
		model:SetAttribute("Eliminated", false)
		model:SetAttribute("RoundContestant", false)
		model.Parent = folder

		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.Transparency = 1
		root.CanCollide = false
		root.CFrame = CFrame.new(lobbySpawn + Vector3.new(index * 4, 5, 10))
		root.Parent = model
		model.PrimaryPart = root

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2.05, 2.05, 1)
		torso.Color = Color3.fromRGB(70 + index * 35, 150, 255 - index * 25)
		torso.Material = Enum.Material.SmoothPlastic
		weldToRoot(root, torso, Vector3.new(0, 0, 0))

		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1.15, 1.15, 1.15)
		head.Color = Color3.fromRGB(255, 215, 165)
		weldToRoot(root, head, Vector3.new(0, 1.72, 0))

		local limbData = {
			{ name = "LeftArm", size = Vector3.new(0.72, 2.05, 0.72), offset = Vector3.new(-1.38, 0, 0), color = torso.Color },
			{ name = "RightArm", size = Vector3.new(0.72, 2.05, 0.72), offset = Vector3.new(1.38, 0, 0), color = torso.Color },
			{ name = "LeftLeg", size = Vector3.new(0.82, 2.05, 0.82), offset = Vector3.new(-0.52, -2.05, 0), color = Color3.fromRGB(45, 50, 64) },
			{ name = "RightLeg", size = Vector3.new(0.82, 2.05, 0.82), offset = Vector3.new(0.52, -2.05, 0), color = Color3.fromRGB(45, 50, 64) },
		}
		for _, limbInfo in ipairs(limbData) do
			local limb = Instance.new("Part")
			limb.Name = limbInfo.name
			limb.Size = limbInfo.size
			limb.Color = limbInfo.color
			limb.Material = Enum.Material.SmoothPlastic
			weldToRoot(root, limb, limbInfo.offset)
		end

		local humanoid = Instance.new("Humanoid")
		humanoid.DisplayName = "Practice NPC " .. index
		humanoid.WalkSpeed = 17
		humanoid.JumpPower = 0
		humanoid.BreakJointsOnDeath = false
		humanoid.Parent = model

		table.insert(testBots, model)
	end
end

function Shared.testBots()
	return testBots
end

function Shared.respawnTestBots(lobbySpawn)
	for index, bot in ipairs(testBots) do
		if bot.Parent then
			Shared.resetSubjectRoundState(bot)
			bot:SetAttribute("Eliminated", false)
			bot:SetAttribute("StrongUntil", nil)
			pcall(function()
				bot:ScaleTo(1)
			end)

			local humanoid = Shared.humanoidFromSubject(bot)
			local root = Shared.rootFromSubject(bot)
			if humanoid then
				humanoid.PlatformStand = false
				humanoid.Sit = false
				humanoid.WalkSpeed = 17
				humanoid.JumpPower = 0
				humanoid.JumpHeight = 0
				humanoid.Health = humanoid.MaxHealth
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.Running)
				end)
			end
			if root then
				root.Anchored = false
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = CFrame.new(lobbySpawn + Vector3.new((index - 2.5) * 4.5, 5, 18))
			end
		end
	end
end

function Shared.characterFromSubject(subject)
	if typeof(subject) ~= "Instance" then
		return nil
	end
	if subject:IsA("Player") then
		return subject.Character
	end
	if subject:IsA("Model") then
		return subject
	end
	return nil
end

function Shared.humanoidFromSubject(subject)
	local character = Shared.characterFromSubject(subject)
	return character and character:FindFirstChildOfClass("Humanoid")
end

function Shared.rootFromSubject(subject)
	local character = Shared.characterFromSubject(subject)
	return character and character:FindFirstChild("HumanoidRootPart")
end

function Shared.setSpectating(subject, enabled)
	if typeof(subject) ~= "Instance" then
		return
	end

	subject:SetAttribute("Spectating", enabled == true)
	if enabled then
		subject:SetAttribute("RoundEliminated", true)
	end
end

function Shared.isSpectating(subject)
	return typeof(subject) == "Instance" and subject:GetAttribute("Spectating") == true
end

function Shared.isProne(subject)
	return typeof(subject) == "Instance" and subject:GetAttribute("IsProne") == true
end

function Shared.resetSubjectRoundState(subject)
	if typeof(subject) ~= "Instance" then
		return
	end

	subject:SetAttribute("RoundContestant", false)
	subject:SetAttribute("Spectating", false)
	subject:SetAttribute("RoundEliminated", false)
	subject:SetAttribute("AllowProne", false)
	subject:SetAttribute("AllowPrimaryAction", false)
	subject:SetAttribute("CurrentMinigame", nil)
	subject:SetAttribute("IsProne", false)
	Shared.setProne(subject, false)
end

function Shared.clearSubjectTools(subject)
	if typeof(subject) ~= "Instance" or not subject:IsA("Player") then
		return
	end

	for _, container in ipairs({ subject:FindFirstChildOfClass("Backpack"), subject.Character }) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") then
					item:Destroy()
				end
			end
		end
	end
end

function Shared.clearAllPlayerTools()
	for _, player in ipairs(Players:GetPlayers()) do
		Shared.clearSubjectTools(player)
	end
end

function Shared.markContestantForGame(subject, gameName, allowPrimaryAction)
	if typeof(subject) ~= "Instance" then
		return
	end

	subject:SetAttribute("RoundContestant", true)
	subject:SetAttribute("CurrentMinigame", gameName)
	subject:SetAttribute("AllowPrimaryAction", allowPrimaryAction == true)
	if subject:IsA("Player") then
		Shared.clearSubjectTools(subject)
	end
end

function Shared.alivePlayers()
	local alive = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and not Shared.isSpectating(player) then
			table.insert(alive, player)
		end
	end
	return alive
end

function Shared.aliveContestants()
	local alive = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = Shared.humanoidFromSubject(player)
		local root = Shared.rootFromSubject(player)
		if humanoid and root and humanoid.Health > 0 and player:GetAttribute("RoundContestant") == true and not Shared.isSpectating(player) then
			table.insert(alive, {
				subject = player,
				name = player.Name,
				character = player.Character,
				humanoid = humanoid,
				root = root,
				isBot = false,
			})
		end
	end

	for _, bot in ipairs(testBots) do
		local humanoid = Shared.humanoidFromSubject(bot)
		local root = Shared.rootFromSubject(bot)
		if humanoid and root and humanoid.Health > 0 and bot:GetAttribute("RoundContestant") == true and not bot:GetAttribute("Eliminated") and not Shared.isSpectating(bot) then
			table.insert(alive, {
				subject = bot,
				name = bot.Name,
				character = bot,
				humanoid = humanoid,
				root = root,
				isBot = true,
			})
		end
	end
	return alive
end

function Shared.teleportPlayers(center, radius)
	local subjects = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(subjects, player)
	end
	for _, bot in ipairs(testBots) do
		table.insert(subjects, bot)
	end

	for index, subject in ipairs(subjects) do
		Shared.resetSubjectRoundState(subject)
		Shared.markContestantForGame(subject, "Round", false)
		if subject:IsA("Player") and not subject.Character then
			if not RunService:IsRunning() then
				continue
			end
			subject.CharacterAdded:Wait()
		end
		local root = Shared.rootFromSubject(subject)
		local humanoid = Shared.humanoidFromSubject(subject)
		if root then
			local angle = (math.pi * 2 / math.max(#subjects, 1)) * index
			local offset = Vector3.new(math.cos(angle) * radius, 4, math.sin(angle) * radius)
			root.CFrame = CFrame.new(center + offset)
			root.AssemblyLinearVelocity = Vector3.zero
		end
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end
end

function Shared.eliminate(subject)
	local humanoid = Shared.humanoidFromSubject(subject)
	local root = Shared.rootFromSubject(subject)
	if subject:IsA("Model") and subject:GetAttribute("IsTestBot") then
		subject:SetAttribute("Eliminated", true)
		Shared.setSpectating(subject, true)
		if root then
			root.CFrame = CFrame.new(root.Position - Vector3.new(0, 80, 0))
		end
		return
	end
	if subject:IsA("Player") then
		Shared.setSpectating(subject, true)
	end
	if humanoid then
		humanoid.Health = 0
	end
end

function Shared.roundShouldContinue(roundEnd)
	local alive = Shared.aliveContestants()
	return os.clock() < roundEnd and #alive > 0 and #alive > 1
end

function Shared.awardSurvivors(gameName, announce)
	local survivors = Shared.aliveContestants()
	if #survivors == 0 then
		announce(gameName .. " ended with no winner")
	elseif #survivors == 1 then
		announce(survivors[1].name .. " wins " .. gameName .. "!")
	else
		announce(#survivors .. " players survived " .. gameName)
	end
	task.wait(4)
end

function Shared.getStrengthMultiplier(subject)
	local untilTime = subject:GetAttribute("StrongUntil") or 0
	return if os.clock() < untilTime then 1.7 else 1
end

local function rememberScale(humanoid, scaleName)
	local scale = humanoid:FindFirstChild(scaleName)
	if not scale then
		return nil
	end

	originalScales[humanoid] = originalScales[humanoid] or {}
	if originalScales[humanoid][scaleName] == nil then
		originalScales[humanoid][scaleName] = scale.Value
	end
	return scale
end

local function applyBig(subject)
	local humanoid = Shared.humanoidFromSubject(subject)
	if not humanoid then
		return
	end

	local character = Shared.characterFromSubject(subject)
	if character and subject:IsA("Model") then
		pcall(function()
			character:ScaleTo(1.25)
		end)
	end

	for _, scaleName in ipairs({ "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale" }) do
		local scale = rememberScale(humanoid, scaleName)
		if scale then
			scale.Value *= 1.35
		end
	end

	task.delay(10, function()
		if not humanoid.Parent then
			return
		end
		for _, scaleName in ipairs({ "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale" }) do
			local scale = humanoid:FindFirstChild(scaleName)
			if scale and originalScales[humanoid] and originalScales[humanoid][scaleName] then
				scale.Value = originalScales[humanoid][scaleName]
			end
		end
	end)
end

local function applyPickup(subject, pickupType)
	local humanoid = Shared.humanoidFromSubject(subject)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if pickupType == "Speed" then
		local oldSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, 28)
		task.delay(8, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = oldSpeed
			end
		end)
	elseif pickupType == "Big" then
		applyBig(subject)
	elseif pickupType == "Strong" then
		subject:SetAttribute("StrongUntil", os.clock() + 10)
	end
end

local function makePickupVisual(parent, pickup, info)
	local icon = Shared.makePart(info.name .. "Icon", Vector3.new(2.2, 2.2, 2.2), pickup.CFrame * CFrame.new(0, 3, 0), info.color, Enum.Material.Neon, parent)
	icon.Anchored = true
	icon.CanCollide = false

	if info.name == "Speed" then
		icon.Shape = Enum.PartType.Ball
	elseif info.name == "Big" then
		icon.Size = Vector3.new(2.8, 2.8, 2.8)
	elseif info.name == "Strong" then
		icon.Shape = Enum.PartType.Ball
		icon.Size = Vector3.new(3, 3, 3)
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = info.name .. "Image"
	gui.Size = UDim2.fromOffset(150, 70)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = icon

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.15
	label.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = info.icon .. " " .. info.text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = gui

	table.insert(activePickups, icon)
	Debris:AddItem(icon, 16)
end

function Shared.makeModifierLegend(parent, origin)
	local items = {
		{ name = "Speed", color = Color3.fromRGB(40, 220, 255), text = ">> SPEED" },
		{ name = "Big", color = Color3.fromRGB(110, 255, 95), text = "[] BIG" },
		{ name = "Power", color = Color3.fromRGB(255, 95, 60), text = "!! POWER" },
	}

	for index, item in ipairs(items) do
		local position = origin + Vector3.new((index - 2) * 12, 0, 0)
		local stand = Shared.makePart(item.name .. "LegendStand", Vector3.new(7, 1, 7), CFrame.new(position), item.color, Enum.Material.Neon, parent)
		stand.Shape = Enum.PartType.Cylinder

		local icon = Shared.makePart(item.name .. "LegendIcon", Vector3.new(3, 3, 3), CFrame.new(position + Vector3.new(0, 4, 0)), item.color, Enum.Material.Neon, parent)
		icon.Shape = Enum.PartType.Ball
		icon.CanCollide = false

		local gui = Instance.new("BillboardGui")
		gui.Name = item.name .. "LegendLabel"
		gui.Size = UDim2.fromOffset(170, 70)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.AlwaysOnTop = true
		gui.Parent = icon

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 0.1
		label.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.Text = item.text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Parent = gui
	end
end

function Shared.spawnModifierPickups(parent, center, radius, count)
	local pickupTypes = {
		{ name = "Speed", color = Color3.fromRGB(40, 220, 255), text = "SPEED", icon = ">>" },
		{ name = "Big", color = Color3.fromRGB(110, 255, 95), text = "BIG", icon = "[]" },
		{ name = "Strong", color = Color3.fromRGB(255, 95, 60), text = "POWER", icon = "!!" },
	}

	count = count or #pickupTypes
	for index = 1, count do
		local info = pickupTypes[math.random(1, #pickupTypes)]
		local angle = (math.pi * 2 / count) * index + math.random()
		local pickup = Shared.makePart(info.name .. "Pickup", Vector3.new(5, 1, 5), CFrame.new(center + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)), info.color, Enum.Material.Neon, parent)
		pickup.Shape = Enum.PartType.Cylinder
		pickup:SetAttribute("PickupType", info.name)
		table.insert(activePickups, pickup)
		makePickupVisual(parent, pickup, info)

		local used = false
		pickup.Touched:Connect(function(hit)
			if used then
				return
			end
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			local subject = player
			if not subject and character and character:GetAttribute("IsTestBot") then
				subject = character
			end
			if subject then
				used = true
				applyPickup(subject, info.name)
				pickup:Destroy()
			end
		end)

		Debris:AddItem(pickup, 16)
	end
end

function Shared.setProne(subject, enabled)
	local humanoid = Shared.humanoidFromSubject(subject)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if enabled and subject:GetAttribute("AllowProne") ~= true then
		enabled = false
	end

	local character = Shared.characterFromSubject(subject)
	if enabled and not originalProneState[subject] then
		originalProneState[subject] = {
			walkSpeed = humanoid.WalkSpeed,
			hipHeight = humanoid.HipHeight,
			autoRotate = humanoid.AutoRotate,
		}
	end

	if enabled then
		local original = originalProneState[subject]
		subject:SetAttribute("IsProne", true)
		humanoid.WalkSpeed = math.min(original and original.walkSpeed or humanoid.WalkSpeed, 7)
		humanoid.HipHeight = math.max(-1.4, (original and original.hipHeight or humanoid.HipHeight) - 1.1)
		humanoid.AutoRotate = true

		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part:SetAttribute("ProneOriginalTransparency", part:GetAttribute("ProneOriginalTransparency") or part.Transparency)
				end
			end
		end
	else
		subject:SetAttribute("IsProne", false)
		local original = originalProneState[subject]
		if original then
			humanoid.WalkSpeed = original.walkSpeed
			humanoid.HipHeight = original.hipHeight
			humanoid.AutoRotate = original.autoRotate
			originalProneState[subject] = nil
		end
	end
end

function Shared.clearRoundState()
	for _, pickup in ipairs(activePickups) do
		if pickup and pickup.Parent then
			pickup:Destroy()
		end
	end
	table.clear(activePickups)

	for _, player in ipairs(Players:GetPlayers()) do
		Shared.resetSubjectRoundState(player)
		Shared.clearSubjectTools(player)
		player:SetAttribute("StrongUntil", nil)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and originalScales[humanoid] then
			for scaleName, value in pairs(originalScales[humanoid]) do
				local scale = humanoid:FindFirstChild(scaleName)
				if scale then
					scale.Value = value
				end
			end
		end
	end
	for _, bot in ipairs(testBots) do
		Shared.resetSubjectRoundState(bot)
		bot:SetAttribute("Eliminated", false)
		bot:SetAttribute("StrongUntil", nil)
		local humanoid = Shared.humanoidFromSubject(bot)
		if humanoid then
			humanoid.WalkSpeed = 17
			humanoid.JumpPower = 0
		end
		pcall(function()
			bot:ScaleTo(1)
		end)
	end
end

return Shared
