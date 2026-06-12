local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LobbyBuilder = {}

local LOBBY_ORIGIN = Vector3.new(0, 200, 0)

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function tree(position, scale, parent)
	local trunk = part({
		Name = "Trunk",
		Size = Vector3.new(2, 8, 2) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 4 * scale, 0)),
		Color = Color3.fromRGB(94, 64, 39),
		Material = Enum.Material.Wood,
	}, parent)
	local leaves = part({
		Name = "Leaves",
		Size = Vector3.new(7, 9, 7) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 11 * scale, 0)),
		Color = Color3.fromRGB(32, 86, 41),
		Material = Enum.Material.Grass,
	}, parent)
	leaves.Shape = Enum.PartType.Ball
	return trunk
end

local function lantern(position, parent)
	local pole = part({
		Name = "LanternPole",
		Size = Vector3.new(0.6, 7, 0.6),
		CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0)),
		Color = Color3.fromRGB(60, 45, 30),
		Material = Enum.Material.Wood,
	}, parent)
	local lamp = part({
		Name = "LanternLamp",
		Size = Vector3.new(1.4, 1.4, 1.4),
		CFrame = CFrame.new(position + Vector3.new(0, 7.5, 0)),
		Color = Color3.fromRGB(255, 200, 90),
		Material = Enum.Material.Neon,
	}, parent)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 110)
	light.Range = 18
	light.Brightness = 1.5
	light.Parent = lamp
	return pole
end

local function campfire(position, parent)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		part({
			Name = "FireLog",
			Size = Vector3.new(4, 1, 1),
			CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, angle, 0),
			Color = Color3.fromRGB(86, 60, 38),
			Material = Enum.Material.Wood,
		}, parent)
	end
	local flame = part({
		Name = "Flame",
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)),
		Color = Color3.fromRGB(255, 120, 30),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, parent)
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 12
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 60)
	light.Range = 24
	light.Brightness = 2
	light.Parent = flame
end

local function bearDisplay(position, parent)
	local pedestal = part({
		Name = "BearPedestal",
		Size = Vector3.new(10, 2, 10),
		CFrame = CFrame.new(position + Vector3.new(0, 1, 0)),
		Color = Color3.fromRGB(120, 120, 125),
		Material = Enum.Material.Slate,
	}, parent)
	local sign = part({
		Name = "BearSign",
		Size = Vector3.new(8, 3, 0.4),
		CFrame = CFrame.new(position + Vector3.new(0, 8, -5)),
		Color = Color3.fromRGB(86, 60, 38),
		Material = Enum.Material.WoodPlanks,
	}, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BEWARE OF THE BEAR"
	label.TextScaled = true
	label.Font = Enum.Font.Bangers
	label.TextColor3 = Color3.fromRGB(255, 80, 60)
	label.Parent = gui
	return pedestal
end

function LobbyBuilder.build(lobbyFolder)
	lobbyFolder:ClearAllChildren()

	local size = Config.Lobby.Size

	local ground = part({
		Name = "LobbyGround",
		Size = Vector3.new(size, 2, size),
		CFrame = CFrame.new(LOBBY_ORIGIN),
		Color = Color3.fromRGB(58, 96, 54),
		Material = Enum.Material.Grass,
	}, lobbyFolder)

	part({
		Name = "SpawnPlatform",
		Size = Vector3.new(24, 1, 24),
		CFrame = CFrame.new(LOBBY_ORIGIN + Vector3.new(0, 1.5, 0)),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.WoodPlanks,
	}, lobbyFolder)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(LOBBY_ORIGIN + Vector3.new(0, 2.5, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(150, 110, 70)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobbyFolder

	campfire(LOBBY_ORIGIN + Vector3.new(0, 1, -25), lobbyFolder)
	bearDisplay(LOBBY_ORIGIN + Vector3.new(0, 1, 40), lobbyFolder)

	local treeRing = {
		Vector3.new(-45, 1, -45), Vector3.new(45, 1, -45),
		Vector3.new(-45, 1, 45), Vector3.new(45, 1, 45),
		Vector3.new(-50, 1, 0), Vector3.new(50, 1, 0),
		Vector3.new(0, 1, -50), Vector3.new(-25, 1, 48),
		Vector3.new(25, 1, 48), Vector3.new(-48, 1, -20),
	}
	for i, offset in ipairs(treeRing) do
		tree(LOBBY_ORIGIN + offset, 0.8 + (i % 3) * 0.25, lobbyFolder)
	end

	lantern(LOBBY_ORIGIN + Vector3.new(-14, 1, -14), lobbyFolder)
	lantern(LOBBY_ORIGIN + Vector3.new(14, 1, -14), lobbyFolder)
	lantern(LOBBY_ORIGIN + Vector3.new(-14, 1, 14), lobbyFolder)
	lantern(LOBBY_ORIGIN + Vector3.new(14, 1, 14), lobbyFolder)

	for _, side in ipairs({
		{ Vector3.new(0, 0, size / 2), Vector3.new(size, 20, 2) },
		{ Vector3.new(0, 0, -size / 2), Vector3.new(size, 20, 2) },
		{ Vector3.new(size / 2, 0, 0), Vector3.new(2, 20, size) },
		{ Vector3.new(-size / 2, 0, 0), Vector3.new(2, 20, size) },
	}) do
		part({
			Name = "LobbyWall",
			Size = side[2],
			CFrame = CFrame.new(LOBBY_ORIGIN + side[1] + Vector3.new(0, 10, 0)),
			Transparency = 1,
			CanCollide = true,
		}, lobbyFolder)
	end

	return ground
end

function LobbyBuilder.getSpawnCFrame()
	return CFrame.new(LOBBY_ORIGIN + Vector3.new(0, 6, 0))
end

return LobbyBuilder
