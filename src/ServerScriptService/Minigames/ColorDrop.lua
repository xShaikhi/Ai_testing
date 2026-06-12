local TweenService = game:GetService("TweenService")

local Shared = require(script.Parent.Shared)

local ColorDrop = {}
ColorDrop.__index = ColorDrop

local COLORS = {
	{ name = "Red", color = Color3.fromRGB(255, 65, 65) },
	{ name = "Blue", color = Color3.fromRGB(55, 130, 255) },
	{ name = "Green", color = Color3.fromRGB(55, 220, 95) },
	{ name = "Yellow", color = Color3.fromRGB(255, 220, 55) },
	{ name = "Purple", color = Color3.fromRGB(175, 95, 255) },
	{ name = "Orange", color = Color3.fromRGB(255, 145, 45) },
	{ name = "Cyan", color = Color3.fromRGB(45, 235, 245) },
	{ name = "Pink", color = Color3.fromRGB(255, 95, 190) },
}

local GRID_RADIUS = 4
local TILE_SIZE = 6.4
local TILE_STEP = 7
local START_FLASH_COUNT = 3
local MIN_FLASH_COUNT = 1
local START_FLASH_TIME = 0.12
local MIN_FLASH_TIME = 0.045
local START_DROP_HOLD = 1.0
local MIN_DROP_HOLD = 0.42

local function colorByName(colorName)
	for _, info in ipairs(COLORS) do
		if info.name == colorName then
			return info.color
		end
	end
	return Color3.new(1, 1, 1)
end

local function countKeys(dictionary)
	local count = 0
	for _ in pairs(dictionary) do
		count += 1
	end
	return count
end

function ColorDrop.new(context)
	local self = setmetatable({}, ColorDrop)
	self.name = "Color Drop"
	self.context = context
	self.origin = context.config.Arenas.ColorDrop
	self.folder = Instance.new("Folder")
	self.folder.Name = "ColorDrop"
	self.folder.Parent = context.rootFolder
	self.tiles = {}
	self.colorPillars = {}
	self:build()
	return self
end

function ColorDrop:build()
	local baseSize = (GRID_RADIUS * 2 + 1) * TILE_STEP + 14
	local safetyBase = Shared.makePart("ColorDropVoidPlate", Vector3.new(baseSize + 18, 1, baseSize + 18), CFrame.new(self.origin + Vector3.new(0, -25, 0)), Color3.fromRGB(15, 17, 26), Enum.Material.Slate, self.folder)
	safetyBase.CanCollide = false

	local glass = Shared.makePart("ColorDropGlassDeck", Vector3.new(baseSize, 0.35, baseSize), CFrame.new(self.origin + Vector3.new(0, -3.45, 0)), Color3.fromRGB(90, 120, 150), Enum.Material.Glass, self.folder)
	glass.Transparency = 0.65
	glass.CanCollide = false

	local index = 1
	for x = -GRID_RADIUS, GRID_RADIUS do
		for z = -GRID_RADIUS, GRID_RADIUS do
			local info = COLORS[index]
			local position = self.origin + Vector3.new(x * TILE_STEP, -3, z * TILE_STEP)
			local tile = Shared.makePart(info.name .. "Tile", Vector3.new(TILE_SIZE, 1, TILE_SIZE), CFrame.new(position), info.color, Enum.Material.Neon, self.folder)
			tile:SetAttribute("ColorName", info.name)
			tile:SetAttribute("BaseCFrame", tile.CFrame)
			tile:SetAttribute("BaseColor", tile.Color)
			table.insert(self.tiles, tile)

			local bevel = Shared.makePart(info.name .. "TileTrim", Vector3.new(TILE_SIZE + 0.35, 0.18, TILE_SIZE + 0.35), CFrame.new(position + Vector3.new(0, -0.54, 0)), Color3.fromRGB(245, 248, 255), Enum.Material.SmoothPlastic, self.folder)
			bevel.Transparency = 0.72
			bevel.CanCollide = false

			index += 1
			if index > #COLORS then
				index = 1
			end
		end
	end

	for beaconIndex, info in ipairs(COLORS) do
		local angle = (math.pi * 2 / #COLORS) * beaconIndex
		local pillar = Shared.makePart(info.name .. "ColorBeacon", Vector3.new(3, 13, 3), CFrame.new(self.origin + Vector3.new(math.cos(angle) * 49, 2.5, math.sin(angle) * 49)), info.color, Enum.Material.Neon, self.folder)
		pillar:SetAttribute("ColorName", info.name)
		pillar.Transparency = 0.25
		table.insert(self.colorPillars, pillar)
	end

	Shared.makeBillboard("ColorDropSign", "Color Drop: move fast, flashing colors disappear", self.origin + Vector3.new(0, 12, -52), self.folder)
end

function ColorDrop:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[ColorDrop] " .. message)
end

function ColorDrop:resetTiles()
	for _, tile in ipairs(self.tiles) do
		local baseCFrame = tile:GetAttribute("BaseCFrame")
		local colorName = tile:GetAttribute("ColorName")
		tile.Color = colorByName(colorName)
		tile.Transparency = 0
		tile.CanCollide = true
		tile.Material = Enum.Material.Neon
		if typeof(baseCFrame) == "CFrame" then
			tile.CFrame = baseCFrame
		end
	end
end

function ColorDrop:pulseColorBeacons(dropNames, enabled)
	for _, pillar in ipairs(self.colorPillars) do
		local selected = dropNames[pillar:GetAttribute("ColorName")] == true
		local targetTransparency = if selected and enabled then 0 else 0.72
		local targetSize = if selected and enabled then Vector3.new(4.2, 17, 4.2) else Vector3.new(3, 13, 3)
		TweenService:Create(pillar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = targetTransparency,
			Size = targetSize,
		}):Play()
	end
end

function ColorDrop:dropColors(dropNames)
	for _, tile in ipairs(self.tiles) do
		if dropNames[tile:GetAttribute("ColorName")] then
			tile.CanCollide = false
			TweenService:Create(tile, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Transparency = 1,
				CFrame = tile.CFrame * CFrame.new(0, -7, 0),
			}):Play()
		end
	end
end

function ColorDrop:isOverDroppedTile(root, dropNames)
	for _, tile in ipairs(self.tiles) do
		if dropNames[tile:GetAttribute("ColorName")] then
			local baseCFrame = tile:GetAttribute("BaseCFrame")
			local position = if typeof(baseCFrame) == "CFrame" then baseCFrame.Position else tile.Position
			local delta = root.Position - position
			if math.abs(delta.X) <= TILE_SIZE * 0.48 and math.abs(delta.Z) <= TILE_SIZE * 0.48 and root.Position.Y > position.Y then
				return true
			end
		end
	end
	return false
end

function ColorDrop:moveBotsToSafeTiles(dropNames)
	local safeTiles = {}
	for _, tile in ipairs(self.tiles) do
		if not dropNames[tile:GetAttribute("ColorName")] then
			table.insert(safeTiles, tile)
		end
	end

	for _, bot in ipairs(Shared.testBots()) do
		local humanoid = Shared.humanoidFromSubject(bot)
		if humanoid and humanoid.Health > 0 and #safeTiles > 0 and not bot:GetAttribute("Eliminated") then
			local tile = safeTiles[math.random(1, #safeTiles)]
			local baseCFrame = tile:GetAttribute("BaseCFrame")
			local position = if typeof(baseCFrame) == "CFrame" then baseCFrame.Position else tile.Position
			humanoid:MoveTo(position + Vector3.new(0, 3, 0))
		end
	end
end

function ColorDrop:chooseDropNames(cycle)
	local dropCount = math.clamp(3 + math.floor(cycle / 2), 3, 7)
	local dropNames = {}
	while countKeys(dropNames) < dropCount do
		local info = COLORS[math.random(1, #COLORS)]
		dropNames[info.name] = true
	end
	return dropNames
end

function ColorDrop:run()
	self:resetTiles()
	Shared.teleportPlayers(self.origin + Vector3.new(0, 4, 0), 22)
	task.wait(0.45)

	local cycle = 0
	local roundEnd = os.clock() + self.context.config.RoundDuration
	while Shared.roundShouldContinue(roundEnd) do
		cycle += 1
		local dropNames = self:chooseDropNames(cycle)
		local names = {}
		for name in pairs(dropNames) do
			table.insert(names, name)
		end

		local flashCount = math.max(MIN_FLASH_COUNT, START_FLASH_COUNT - math.floor(cycle / 5))
		local flashTime = math.max(MIN_FLASH_TIME, START_FLASH_TIME - cycle * 0.006)
		self:announce("Color Drop: " .. table.concat(names, " + "))

		for flash = 1, flashCount do
			self:moveBotsToSafeTiles(dropNames)
			local warningOn = flash % 2 == 1
			self:pulseColorBeacons(dropNames, warningOn)
			for _, tile in ipairs(self.tiles) do
				if dropNames[tile:GetAttribute("ColorName")] then
					local baseColor = colorByName(tile:GetAttribute("ColorName"))
					local targetColor = if warningOn then Color3.fromRGB(255, 255, 255) else baseColor
					local targetTransparency = if warningOn then 0.08 else 0.42
					TweenService:Create(tile, TweenInfo.new(flashTime * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Color = targetColor,
						Transparency = targetTransparency,
					}):Play()
				end
			end
			task.wait(flashTime)
		end

		self:dropColors(dropNames)

		local dropEnd = os.clock() + math.max(MIN_DROP_HOLD, START_DROP_HOLD - cycle * 0.035)
		while os.clock() < dropEnd do
			for _, contestant in ipairs(Shared.aliveContestants()) do
				if contestant.root then
					if self:isOverDroppedTile(contestant.root, dropNames) or contestant.root.Position.Y < self.origin.Y - 8 then
						Shared.eliminate(contestant.subject)
					end
				end
			end
			task.wait(0.08)
		end

		self:resetTiles()
		self:pulseColorBeacons({}, false)
		if cycle % 2 == 0 then
			Shared.spawnModifierPickups(self.folder, self.origin + Vector3.new(0, 1, 0), 26, 1)
		end
		task.wait(math.max(0.08, 0.28 - cycle * 0.012))
	end

	self:resetTiles()
	Shared.awardSurvivors(self.name, function(message)
		self:announce(message)
	end)
end

return ColorDrop
