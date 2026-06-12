-- Main round controller. Each minigame lives in ServerScriptService/Minigames.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = require(script.Parent.Minigames.Shared)
local ColorDrop = require(script.Parent.Minigames.ColorDrop)
local ArenaBrawl = require(script.Parent.Minigames.ArenaBrawl)
local PolarPush = require(script.Parent.Minigames.PolarPush)
local LaserJump = require(script.Parent.Minigames.LaserJump)
local BearHunt = require(script.Parent.Minigames.BearHunt)

local CONFIG = {
	Intermission = 10,
	RoundDuration = 70,
	MinPlayers = 1,
	TestBotCount = 4,
	HubSpawn = Vector3.new(0, 8, 0),
	SpectatorSpawn = Vector3.new(0, 34, 0),
	-- Player (re)spawn point at the central Neon Robot World safe plaza.
	PlayerSpawn = Vector3.new(0, 7, 0),
	-- Practice NPC base spot in the quest hub, clear of player spawn and portal triggers.
	NpcSpawn = Vector3.new(-12, 7, 102),
	Arenas = {
		ColorDrop = Vector3.new(-1600, 72, 0),
		ArenaBrawl = Vector3.new(0, 72, 1600),
		PolarPush = Vector3.new(1600, 72, 0),
		LaserJump = Vector3.new(0, 72, -1600),
		BearHunt = Vector3.new(-1600, 72, 1600),
	},
}

Shared.ensureRemotes()
Shared.bindMovementRemotes()

local function setupLighting()
	local Lighting = game:GetService("Lighting")
	-- NOTE: Lighting.Technology is read-only from scripts; set it in Studio if desired.
	Lighting.Ambient = Color3.fromRGB(55, 78, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(62, 82, 142)
	Lighting.Brightness = 3
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.85
	Lighting.ExposureCompensation = 0.05
	Lighting.ClockTime = 20.15
	Lighting.GeographicLatitude = 24
	Lighting.ShadowSoftness = 0.35
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 1500
	Lighting.FogColor = Color3.fromRGB(72, 88, 154)

	for _, name in ipairs({ "NeonRobotAtmosphere", "NeonRobotSky", "NeonRobotBloom", "NeonRobotColor" }) do
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "NeonRobotAtmosphere"
	atmosphere.Density = 0.42
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(151, 202, 255)
	atmosphere.Decay = Color3.fromRGB(78, 48, 135)
	atmosphere.Glare = 0.42
	atmosphere.Haze = 1.25
	atmosphere.Parent = Lighting

	local sky = Instance.new("Sky")
	sky.Name = "NeonRobotSky"
	sky.SunAngularSize = 7
	sky.MoonAngularSize = 18
	sky.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "NeonRobotBloom"
	bloom.Intensity = 1.05
	bloom.Size = 36
	bloom.Threshold = 0.82
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "NeonRobotColor"
	color.Brightness = 0.03
	color.Contrast = 0.16
	color.Saturation = 0.24
	color.TintColor = Color3.fromRGB(232, 246, 255)
	color.Parent = Lighting
end

local lightingOk, lightingErr = pcall(setupLighting)
if not lightingOk then
	warn("[Minigames] Lighting setup skipped: " .. tostring(lightingErr))
end

local rootFolder = workspace:FindFirstChild("CrashBashPrototype")
if not rootFolder then
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "CrashBashPrototype"
	rootFolder.Parent = workspace
else
	rootFolder:SetAttribute("PreservedExistingRoot", true)
end

for _, childName in ipairs({ "Runtime", "World", "GiantHub", "Portals", "TestNPCs", "ColorDrop", "ArenaBrawl", "LaserJump", "BearHunt" }) do
	local child = rootFolder:FindFirstChild(childName)
	if child then
		child:Destroy()
	end
end

local runtimeFolder = Instance.new("Folder")
runtimeFolder.Name = "Runtime"
runtimeFolder.Parent = rootFolder

local statusValue = Instance.new("StringValue")
statusValue.Name = "GameStatus"
statusValue.Value = "Loading..."
statusValue.Parent = runtimeFolder

local roundRunningValue = Instance.new("BoolValue")
roundRunningValue.Name = "RoundRunning"
roundRunningValue.Value = false
roundRunningValue.Parent = runtimeFolder

local world = Instance.new("Folder")
world.Name = "World"
world.Parent = rootFolder

local lobby = Instance.new("Folder")
lobby.Name = "Portals"
lobby.Parent = rootFolder

local terrainFolder = Instance.new("Folder")
terrainFolder.Name = "ProfessionalTerrain"
terrainFolder.Parent = world

local roundRunning = false

local function setRoundRunning(enabled)
	roundRunning = enabled == true
	roundRunningValue.Value = roundRunning
end

local function announce(message)
	statusValue.Value = message
	print("[Minigames] " .. message)
end

local function makeWedge(name, size, cframe, color, material, parent)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Anchored = true
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = material or Enum.Material.Slate
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.CanCollide = false
	wedge.CanTouch = false
	wedge.CanQuery = false
	wedge.Parent = parent
	return wedge
end

local function makeCylinder(name, size, cframe, color, material, parent)
	local part = Shared.makePart(name, size, cframe, color, material, parent)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function makeMountainCluster(name, center, color, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	local random = Random.new(math.floor(math.abs(center.X) + math.abs(center.Z) + 100))
	for index = 1, 18 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(42, 92)
		local height = random:NextNumber(14, 36)
		local width = random:NextNumber(16, 34)
		local position = center + Vector3.new(math.cos(angle) * distance, -2 + height * 0.35, math.sin(angle) * distance)
		local wedge = makeWedge("TerrainRidge", Vector3.new(width, height, width * 0.75), CFrame.new(position) * CFrame.Angles(0, angle, 0), color, Enum.Material.Rock, folder)
		wedge.Color = color:Lerp(Color3.fromRGB(255, 255, 255), random:NextNumber(0, 0.12))
	end

	return folder
end

local function makeMapDome(name, center, radius, color, parent)
	local folder = Instance.new("Folder")
	folder.Name = name .. "IsolationDome"
	folder.Parent = parent

	local shell = Shared.makePart("GlassDomeShell", Vector3.new(radius * 2, radius * 1.08, radius * 2), CFrame.new(center + Vector3.new(0, radius * 0.26, 0)), color, Enum.Material.Glass, folder)
	shell.Shape = Enum.PartType.Ball
	shell.Transparency = 0.64
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false

	local ring = makeCylinder("DomeFoundationRing", Vector3.new(radius * 2.08, 0.42, radius * 2.08), CFrame.new(center + Vector3.new(0, -3.05, 0)), color, Enum.Material.Neon, folder)
	ring.Transparency = 0.22
	ring.CanCollide = false

	for index = 1, 16 do
		local angle = (math.pi * 2 / 16) * index
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local rib = Shared.makePart("DomeVerticalRib", Vector3.new(1.15, radius * 0.98, 1.15), CFrame.lookAt(center + direction * radius * 0.92 + Vector3.new(0, radius * 0.24, 0), center + Vector3.new(0, radius * 0.24, 0)), color, Enum.Material.Neon, folder)
		rib.Transparency = 0.18
		rib.CanCollide = false
	end

	for level = 1, 3 do
		local ringRadius = radius * (1 - level * 0.18)
		local band = makeCylinder("DomeEnergyBand", Vector3.new(ringRadius * 2, 0.24, ringRadius * 2), CFrame.new(center + Vector3.new(0, level * radius * 0.22, 0)), color, Enum.Material.Neon, folder)
		band.Transparency = 0.52
		band.CanCollide = false
	end

	return folder
end

local function makeIslandRim(name, center, radius, color, parent)
	local folder = Instance.new("Folder")
	folder.Name = name .. "CartoonRim"
	folder.Parent = parent

	local outer = makeCylinder("ThickIslandOutline", Vector3.new(radius * 2.12, 1.05, radius * 2.12), CFrame.new(center + Vector3.new(0, -3.95, 0)), color, Enum.Material.Neon, folder)
	outer.Transparency = 0.28
	outer.CanCollide = false

	local segmentCount = 20
	for index = 1, segmentCount do
		local angle = (math.pi * 2 / segmentCount) * index
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local bead = makeCylinder("RimBolt", Vector3.new(3.2, 1.4, 3.2), CFrame.new(center + direction * (radius + 4) + Vector3.new(0, -2.7, 0)), color, Enum.Material.Neon, folder)
		bead.Transparency = 0.18
		bead.CanCollide = false
	end
end

local function makeCartoonWorldBorder(parent)
	local borderColor = Color3.fromRGB(255, 212, 84)
	local wallColor = Color3.fromRGB(35, 42, 58)
	local half = 388

	for _, info in ipairs({
		{ name = "North", size = Vector3.new(784, 22, 8), position = Vector3.new(0, 8, -half) },
		{ name = "South", size = Vector3.new(784, 22, 8), position = Vector3.new(0, 8, half) },
		{ name = "West", size = Vector3.new(8, 22, 784), position = Vector3.new(-half, 8, 0) },
		{ name = "East", size = Vector3.new(8, 22, 784), position = Vector3.new(half, 8, 0) },
	}) do
		local wall = Shared.makePart("CartoonWorldBorder" .. info.name, info.size, CFrame.new(info.position), wallColor, Enum.Material.SmoothPlastic, parent)
		wall.CanCollide = true
		local trimSize = if info.size.X > info.size.Z then Vector3.new(info.size.X, 1.4, 2.2) else Vector3.new(2.2, 1.4, info.size.Z)
		local trim = Shared.makePart("CartoonWorldBorderTrim" .. info.name, trimSize, CFrame.new(info.position + Vector3.new(0, 11.9, 0)), borderColor, Enum.Material.Neon, parent)
		trim.CanCollide = false
	end

	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local tower = makeCylinder("CartoonBorderCornerTower", Vector3.new(22, 28, 22), CFrame.new(x * half, 12, z * half), borderColor, Enum.Material.SmoothPlastic, parent)
			tower.CanCollide = true
		end
	end
end

local function makeTerrainAccents(parent)
	local random = Random.new(711)
	local reservedCenters = {
		CONFIG.HubSpawn,
		CONFIG.Arenas.ColorDrop,
		CONFIG.Arenas.ArenaBrawl,
		CONFIG.Arenas.PolarPush,
		CONFIG.Arenas.LaserJump,
		CONFIG.Arenas.BearHunt,
	}
	for index = 1, 46 do
		local x = random:NextNumber(-330, 330)
		local z = random:NextNumber(-330, 330)
		local clearOfPlaySpaces = true
		for _, center in ipairs(reservedCenters) do
			if (Vector3.new(x, 0, z) - Vector3.new(center.X, 0, center.Z)).Magnitude < 126 then
				clearOfPlaySpaces = false
				break
			end
		end
		if clearOfPlaySpaces then
			local size = random:NextNumber(8, 20)
			local hill = makeCylinder("CartoonTerrainHill", Vector3.new(size, random:NextNumber(2.2, 5.8), size), CFrame.new(x, -3.2, z), Color3.fromRGB(54, 113, 78), Enum.Material.Grass, parent)
			hill.CanCollide = false

			if index % 3 == 0 then
				local trunk = makeCylinder("CartoonTreeTrunk", Vector3.new(1.4, 7, 1.4), CFrame.new(x, 1.2, z), Color3.fromRGB(95, 63, 42), Enum.Material.Wood, parent)
				trunk.CanCollide = false
				local crown = Shared.makePart("CartoonTreeCrown", Vector3.new(8, 8, 8), CFrame.new(x, 6.2, z), Color3.fromRGB(72, 170, 92), Enum.Material.Grass, parent)
				crown.Shape = Enum.PartType.Ball
				crown.CanCollide = false
			end
		end
	end
end

local function buildTerrain()
	makeMapDome("ColorDrop", CONFIG.Arenas.ColorDrop, 92, Color3.fromRGB(255, 95, 190), terrainFolder)
	makeMapDome("ArenaBrawl", CONFIG.Arenas.ArenaBrawl, 98, Color3.fromRGB(255, 190, 80), terrainFolder)
	makeMapDome("PolarPush", CONFIG.Arenas.PolarPush, 94, Color3.fromRGB(120, 220, 255), terrainFolder)
	makeMapDome("LaserJump", CONFIG.Arenas.LaserJump, 96, Color3.fromRGB(70, 255, 190), terrainFolder)
	makeMapDome("BearHunt", CONFIG.Arenas.BearHunt, 96, Color3.fromRGB(255, 170, 40), terrainFolder)
end

local function buildHub()
	-- Status sign above the minigame portal plaza.
	-- Returned as context.lobbySign; minigames update its .Text via :announce().
	return Shared.makeBillboard("HubStatusSign", "Choose a minigame from the hub", Vector3.new(145, 34, 28), lobby)
end

buildTerrain()
local lobbySign = buildHub()
Shared.createTestBots(rootFolder, CONFIG.NpcSpawn, CONFIG.TestBotCount)

local context = {
	config = CONFIG,
	rootFolder = rootFolder,
	runtimeFolder = runtimeFolder,
	statusValue = statusValue,
	lobbySign = lobbySign,
}

local games = {}

local function addGame(gameName, constructor)
	local ok, gameModule = xpcall(function()
		return constructor(context)
	end, debug.traceback)

	if ok and gameModule then
		table.insert(games, gameModule)
	else
		warn("[Minigames] Failed to create " .. gameName .. ": " .. tostring(gameModule))
		announce(gameName .. " failed to load. Check Output.")
	end
end

addGame("Color Drop", ColorDrop.new)
addGame("Arena Brawl", ArenaBrawl.new)
addGame("Polar Push", PolarPush.new)
addGame("Laser Jump", LaserJump.new)
addGame("Bear Hunt", BearHunt.new)

local function setLobbyText(text)
	if lobbySign then
		lobbySign.Text = text
	end
end

-- Absolute world spots aligned with the decorative Neon Robot World portal frames.
-- Order matches `games`: 1 ColorDrop, 2 ArenaBrawl, 3 PolarPush, 4 LaserJump, 5 BearHunt.
local portalPositions = {
	Vector3.new(101, 0, -10),
	Vector3.new(130, 0, -10),
	Vector3.new(159, 0, -10),
	Vector3.new(188, 0, -10),
	Vector3.new(217, 0, -10),
}

local portalColors = {
	Color3.fromRGB(255, 95, 190),
	Color3.fromRGB(255, 190, 80),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(70, 255, 190),
	Color3.fromRGB(255, 170, 40),
}

local function resetPlayersToLobby()
	Shared.clearRoundState()
	for _, player in ipairs(Players:GetPlayers()) do
		Shared.resetSubjectRoundState(player)
		Shared.clearSubjectTools(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not character or not humanoid or humanoid.Health <= 0 then
			if RunService:IsRunning() then
				player:LoadCharacter()
			end
		else
			humanoid.Health = humanoid.MaxHealth
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.JumpHeight = 7.2
			if root then
				root.CFrame = CFrame.new(CONFIG.PlayerSpawn)
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end

	Shared.respawnTestBots(CONFIG.NpcSpawn)
end

local function startGame(gameModule)
	if roundRunning then
		return
	end

	setRoundRunning(true)
	local ok, err = xpcall(function()
		resetPlayersToLobby()
		for seconds = 3, 1, -1 do
			announce(gameModule.name .. " starts in " .. seconds)
			setLobbyText(gameModule.name .. " starts in " .. seconds)
			task.wait(1)
		end

		announce(gameModule.name .. " starting")
		setLobbyText(gameModule.name .. " starting")
		gameModule:run()
	end, debug.traceback)
	if not ok then
		warn("[Minigames] " .. gameModule.name .. " failed: " .. tostring(err))
	end

	local resetOk, resetErr = pcall(resetPlayersToLobby)
	if not resetOk then
		warn("[Minigames] Lobby reset failed: " .. tostring(resetErr))
	end
	announce("Choose a minigame from the hub")
	setLobbyText("Choose a minigame from the hub")
	task.wait(1)
	setRoundRunning(false)
end

local studioStartMinigame = Instance.new("BindableFunction")
studioStartMinigame.Name = "StudioStartMinigame"
studioStartMinigame.Parent = runtimeFolder
studioStartMinigame.OnInvoke = function(gameName, duration)
	if typeof(gameName) ~= "string" or roundRunning then
		return false
	end

	for _, gameModule in ipairs(games) do
		if gameModule.name == gameName then
			task.spawn(function()
				local oldDuration = CONFIG.RoundDuration
				if typeof(duration) == "number" then
					CONFIG.RoundDuration = math.clamp(duration, 8, oldDuration)
				end
				startGame(gameModule)
				CONFIG.RoundDuration = oldDuration
			end)
			return true
		end
	end
	return false
end

local function makeGamePortal(gameModule, index)
	local padPosition = portalPositions[index]
	local pad = Shared.makePart(gameModule.name .. "PortalPad", Vector3.new(22, 0.6, 22), CFrame.new(padPosition + Vector3.new(0, 0.72, 0)), portalColors[index], Enum.Material.Neon, lobby)
	pad.Shape = Enum.PartType.Cylinder
	pad.CanCollide = true
	pad.CanTouch = true
	pad:SetAttribute("GameName", gameModule.name)
	pad:SetAttribute("SpawnLevelCenterY", CONFIG.HubSpawn.Y)

	local trigger = Shared.makeInvisibleTrigger(gameModule.name .. "PortalTrigger", Vector3.new(24, 10, 24), CFrame.new(padPosition + Vector3.new(0, 5.2, 0)), lobby)
	trigger.Shape = Enum.PartType.Cylinder
	trigger:SetAttribute("GameName", gameModule.name)

	local column = makeCylinder(gameModule.name .. "PortalColumn", Vector3.new(10, 18, 10), CFrame.new(padPosition + Vector3.new(0, 8, 0)), portalColors[index], Enum.Material.Neon, lobby)
	column.Transparency = 0.72
	column.CanCollide = false

	Shared.makeBillboard(gameModule.name .. "PadLabel", "PLAY" .. string.char(10) .. gameModule.name, padPosition + Vector3.new(0, 3, 0), lobby)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StartGamePrompt"
	prompt.ActionText = "Play"
	prompt.ObjectText = gameModule.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	local touchedAt = {}
	local function tryStartFromPlayer(player)
		if roundRunning then
			return
		end
		if not player then
			return
		end

		local now = os.clock()
		if touchedAt[player] and now - touchedAt[player] < 2 then
			return
		end
		touchedAt[player] = now

		task.spawn(startGame, gameModule)
	end

	local function tryStartFromHit(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		tryStartFromPlayer(character and Players:GetPlayerFromCharacter(character))
	end

	pad.Touched:Connect(function(hit)
		tryStartFromHit(hit)
	end)

	trigger.Touched:Connect(function(hit)
		tryStartFromHit(hit)
	end)

	prompt.Triggered:Connect(function(player)
		tryStartFromPlayer(player)
	end)
end

local function connectCharacter(player, character)
	task.wait(0.2)
	Shared.clearSubjectTools(player)
	character.ChildAdded:Connect(function(item)
		if item:IsA("Tool") then
			item:Destroy()
		end
	end)
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if root then
		if player:GetAttribute("Spectating") == true then
			root.CFrame = CFrame.new(CONFIG.SpectatorSpawn + Vector3.new(0, 4, 0))
		else
			root.CFrame = CFrame.new(CONFIG.PlayerSpawn)
		end
	end

	if humanoid then
		humanoid.Died:Connect(function()
			if roundRunning then
				Shared.setSpectating(player, true)
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Spectating", false)
	player:SetAttribute("RoundEliminated", false)
	player:SetAttribute("RoundContestant", false)
	player:SetAttribute("AllowProne", false)
	player:SetAttribute("AllowPrimaryAction", false)
	player:SetAttribute("CurrentMinigame", nil)
	player:SetAttribute("IsProne", false)
	task.defer(function()
		local backpack = player:WaitForChild("Backpack", 10)
		if backpack then
			backpack.ChildAdded:Connect(function(item)
				if item:IsA("Tool") then
					item:Destroy()
				end
			end)
		end
	end)
	player.CharacterAdded:Connect(function(character)
		connectCharacter(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 10)
		if backpack then
			backpack.ChildAdded:Connect(function(item)
				if item:IsA("Tool") then
					item:Destroy()
				end
			end)
		end
	end)
	if player.Character then
		task.spawn(connectCharacter, player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		connectCharacter(player, character)
	end)
end

for index, gameModule in ipairs(games) do
	makeGamePortal(gameModule, index)
end

resetPlayersToLobby()
announce("Choose a minigame from the hub")
setLobbyText("Choose a minigame from the hub")
