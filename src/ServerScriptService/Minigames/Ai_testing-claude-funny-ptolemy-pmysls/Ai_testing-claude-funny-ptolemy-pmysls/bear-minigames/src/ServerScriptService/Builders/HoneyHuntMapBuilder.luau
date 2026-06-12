local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local HoneyHuntMapBuilder = {}

local MAP_NAME = "HoneyHunt_Forest"

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

local function marker(name, position, parent)
	return part({
		Name = name,
		Size = Vector3.new(2, 1, 2),
		CFrame = CFrame.new(position),
		Transparency = 1,
		CanCollide = false,
	}, parent)
end

local function tree(position, scale, parent)
	part({
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
end

local function crate(position, parent)
	part({
		Name = "Crate",
		Size = Vector3.new(4, 4, 4),
		CFrame = CFrame.new(position + Vector3.new(0, 2, 0)),
		Color = Color3.fromRGB(140, 105, 65),
		Material = Enum.Material.WoodPlanks,
	}, parent)
end

local function rock(position, scale, parent)
	local r = part({
		Name = "Rock",
		Size = Vector3.new(5, 4, 5) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 2 * scale, 0)) * CFrame.Angles(0, scale * 2, 0),
		Color = Color3.fromRGB(105, 105, 110),
		Material = Enum.Material.Slate,
	}, parent)
	return r
end

function HoneyHuntMapBuilder.build(mapsFolder)
	local existing = mapsFolder:FindFirstChild(MAP_NAME)
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Model")
	map.Name = MAP_NAME

	local size = Config.Map.Size
	local origin = Vector3.new(500, 0, 500)

	part({
		Name = "Ground",
		Size = Vector3.new(size, 2, size),
		CFrame = CFrame.new(origin),
		Color = Color3.fromRGB(52, 88, 48),
		Material = Enum.Material.Grass,
	}, map)

	for _, side in ipairs({
		{ Vector3.new(0, 0, size / 2), Vector3.new(size, Config.Map.WallHeight, 2) },
		{ Vector3.new(0, 0, -size / 2), Vector3.new(size, Config.Map.WallHeight, 2) },
		{ Vector3.new(size / 2, 0, 0), Vector3.new(2, Config.Map.WallHeight, size) },
		{ Vector3.new(-size / 2, 0, 0), Vector3.new(2, Config.Map.WallHeight, size) },
	}) do
		part({
			Name = "Boundary",
			Size = side[2],
			CFrame = CFrame.new(origin + side[1] + Vector3.new(0, Config.Map.WallHeight / 2, 0)),
			Transparency = 1,
			CanCollide = true,
		}, map)
	end

	local rng = Random.new(7)
	for _ = 1, 18 do
		local x = rng:NextNumber(-size / 2 + 12, size / 2 - 12)
		local z = rng:NextNumber(-size / 2 + 12, size / 2 - 12)
		if math.abs(x) > 18 or math.abs(z) > 18 then
			tree(origin + Vector3.new(x, 1, z), rng:NextNumber(0.7, 1.4), map)
		end
	end
	for _ = 1, 6 do
		local x = rng:NextNumber(-size / 2 + 15, size / 2 - 15)
		local z = rng:NextNumber(-size / 2 + 15, size / 2 - 15)
		crate(origin + Vector3.new(x, 1, z), map)
	end
	for _ = 1, 5 do
		local x = rng:NextNumber(-size / 2 + 15, size / 2 - 15)
		local z = rng:NextNumber(-size / 2 + 15, size / 2 - 15)
		rock(origin + Vector3.new(x, 1, z), rng:NextNumber(0.6, 1.3), map)
	end

	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		marker("PlayerSpawn", origin + Vector3.new(math.cos(angle) * 12, 2, math.sin(angle) * 12), map)
	end

	marker("BearSpawn", origin + Vector3.new(0, 2, -size / 2 + 15), map)

	for _ = 1, Config.HoneyHunt.JarsSpawned + 6 do
		local x = rng:NextNumber(-size / 2 + 10, size / 2 - 10)
		local z = rng:NextNumber(-size / 2 + 10, size / 2 - 10)
		marker("HoneySpawn", origin + Vector3.new(x, 3, z), map)
	end

	map.Parent = mapsFolder
	return map
end

return HoneyHuntMapBuilder
