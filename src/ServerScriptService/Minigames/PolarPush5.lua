local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = require(script.Parent.Shared)
local PolarPushModels = require(script.Parent.PolarPushModels)

local PolarPush = {}
PolarPush.__index = PolarPush

local MAP_MODEL_NAME = "PolarPushMap"
local WORKSPACE_MAP_ALIASES = {
	MAP_MODEL_NAME,
	"IceSpikes_Roblox",
	"IceSpikes",
	"iceapiked",
	"IceApiked",
}
local BREAKABLE_WALLS_FOLDER_NAME = "BreakableWalls"
local SPAWNS_FOLDER_NAME = "Spawns"
local CENTER_PART_NAME = "Center"
local MODIFIER_CENTER_PART_NAME = "ModifierCenter"
local BREAKABLE_BORDER_NAME_PATTERNS = {
	"icespike",
	"iceborder",
	"breakablewall",
	"breakableborder",
}

local PUSH_DURATION = 0.58
local PUSH_COOLDOWN = 2
local PUSH_SPEED = 54
local PUSH_HEIGHT = 5
local PUSH_AFTER_SPEED = 14
local PUSH_HITBOX_OFFSET = -4.2
local PUSH_HITBOX_RADIUS = 13.25
local PUSH_HEAD_HITBOX_OFFSET = -4.2
local PUSH_TARGET_POWER = 118
local PUSH_SPEED_POWER_BONUS_CAP = 0.45
local PRIMARY_COOLDOWN_END_ATTRIBUTE = "PrimaryActionCooldownEndsAt"
local PRIMARY_COOLDOWN_DURATION_ATTRIBUTE = "PrimaryActionCooldownDuration"
local WALL_HIT_RANGE = 12

local COLLISION_DISTANCE = 7.2
local WALL_MAX_HEALTH = 2
local MODIFIER_INTERVAL = 12
local MODIFIER_RADIUS = 38
local FALL_Y_OFFSET = -12
local FALL_RADIUS_BUFFER = 12
local MIN_WORKSPACE_RADIUS = 50
local TARGET_WORKSPACE_RADIUS = 50
local GROUND_STABILIZE_RAY_UP = 3
local GROUND_STABILIZE_RAY_DOWN = 14
local GROUND_STABILIZE_PADDING = 0.15
local ICE_PHYSICS = PhysicalProperties.new(0.7, 0.004, 0.16, 0.01, 1)
local ICE_SPIKES_SOURCE_ASSET = "C:\\Users\\mr7am\\OneDrive\\Documents\\Roblox_map\\Aset\\IceSpikes\\IceSpikes_Roblox.blend"
local ICE_BORDER_SOURCE_ASSET = "C:\\Users\\mr7am\\OneDrive\\Documents\\Roblox_map\\Aset\\IceBorder_Roblox.blend"
local ICE_BORDER_SOURCE_RADIUS = 9.9956
local ICE_BORDER_SEGMENTS = {
	{ name = "IceBorder_01", angle = 0.00298, height = 3.87669 },
	{ name = "IceBorder_02", angle = -0.31428, height = 3.67253 },
	{ name = "IceBorder_03", angle = -0.62345, height = 3.87707 },
	{ name = "IceBorder_04", angle = -0.94334, height = 2.90882 },
	{ name = "IceBorder_05", angle = -1.25622, height = 3.81969 },
	{ name = "IceBorder_06", angle = -1.57828, height = 3.87670 },
	{ name = "IceBorder_07", angle = -1.88530, height = 3.92828 },
	{ name = "IceBorder_08", angle = -2.19795, height = 3.11745 },
	{ name = "IceBorder_09", angle = -2.51329, height = 3.29898 },
	{ name = "IceBorder_10", angle = -2.82253, height = 3.45405 },
	{ name = "IceBorder_11", angle = 3.14004, height = 3.85354 },
	{ name = "IceBorder_12", angle = 2.82716, height = 3.11356 },
	{ name = "IceBorder_13", angle = 2.51440, height = 3.68717 },
	{ name = "IceBorder_14", angle = 2.19702, height = 3.75040 },
	{ name = "IceBorder_15", angle = 1.87993, height = 3.40198 },
	{ name = "IceBorder_16", angle = 1.57172, height = 3.60278 },
	{ name = "IceBorder_17", angle = 1.25959, height = 3.15590 },
	{ name = "IceBorder_18", angle = 0.94607, height = 3.17009 },
	{ name = "IceBorder_19", angle = 0.63403, height = 3.88882 },
	{ name = "IceBorder_20", angle = 0.31437, height = 3.57199 },
}
local ICE_SLIDE_MAX_SPEED = 24
local ICE_SLIDE_ACCELERATION = 38
local ICE_SLIDE_DRAG = 0.16
local ICE_SLIDE_STOP_SPEED = 0.05
local ICE_SLIDE_PUSH_MEMORY = 0.72
local MOMENTUM_INTERVAL = 0.2
local MOMENTUM_SPEED_STEP = 3.2
local MOMENTUM_MAX_BONUS = 46
local MOMENTUM_MIN_MOVE = 0.12
local MOMENTUM_BLOCK_DURATION = 0.75
local DEATH_WATER_TOUCH_HEIGHT = 6

-- Visual tuning for the bigger ice arena.
local ICE_FLOOR_COLOR = Color3.fromRGB(90, 230, 255)
local ICE_TILE_COLOR = Color3.fromRGB(145, 235, 255)
local ICE_SPIKE_COLOR = Color3.fromRGB(185, 242, 255)
local ICE_BORDER_COLOR = Color3.fromRGB(225, 252, 255)
local ICE_CRACK_COLOR = Color3.fromRGB(80, 170, 255)
local DARK_WATER_COLOR = Color3.fromRGB(4, 15, 34)

local function normalizedName(name)
	return string.lower((name or ""):gsub("[^%w]", ""))
end

function PolarPush.new(context)
	local self = setmetatable({}, PolarPush)
	self.name = "Polar Push"
	self.context = context
	self.origin = context.config.Arenas.PolarPush
	self.radius = TARGET_WORKSPACE_RADIUS
	self.eliminationRadius = self.radius + FALL_RADIUS_BUFFER
	self.edgeParts = {}
	self.edgePartSet = {}
	self.deathWaterParts = {}
	self.deathWaterConnections = {}
	self.spawnPoints = {}
	self.lastPushAt = {}
	self.slideVelocity = {}
	self.walkMomentum = {}
	self.lastMomentumAt = {}
	self.momentumBlockedUntil = {}
	self.botMoveState = {}
	self.wallTouchConnections = {}
	self.workspaceMap = nil
	local existingFolder = context.rootFolder:FindFirstChild("PolarPush")
	if existingFolder and existingFolder:IsA("Folder") then
		self.folder = existingFolder
		self.folder:SetAttribute("PreservedExistingPolarMap", true)
	else
		self.folder = Instance.new("Folder")
		self.folder.Name = "PolarPush"
		self.folder.Parent = context.rootFolder
	end
	local ok, err = xpcall(function()
		self:build()
	end, debug.traceback)

	if not ok then
		warn("[PolarPush] Build failed, using safe prototype fallback: " .. tostring(err))
		table.clear(self.edgeParts)
		table.clear(self.edgePartSet)
		table.clear(self.deathWaterParts)
		table.clear(self.spawnPoints)
		self.workspaceMap = nil
		local fallbackOk, fallbackErr = xpcall(function()
			self:buildPrototypeMap()
			self:registerWorkspaceDeathWater()
			self:updateStudioZoomFocus()
			Shared.makeBillboard("PolarPushSign", "Polar Push: push players, break ice walls", self.origin + Vector3.new(0, 10, -42), self.folder)
		end, debug.traceback)
		if not fallbackOk then
			warn("[PolarPush] Safe prototype fallback also failed: " .. tostring(fallbackErr))
		end
	end

	return self
end

function PolarPush:findWorkspaceMap()
	local normalizedAliases = {}
	for _, alias in ipairs(WORKSPACE_MAP_ALIASES) do
		normalizedAliases[normalizedName(alias)] = true
	end

	local function matchesMapName(instance)
		if not instance or not instance:IsA("Model") then
			return false
		end
		local normalized = normalizedName(instance.Name)
		return normalizedAliases[normalized]
			or normalized:find("icespike", 1, true) ~= nil
			or normalized:find("iceapiked", 1, true) ~= nil
	end

	-- First check direct workspace models, so an imported Studio map is picked up.
	for _, child in ipairs(workspace:GetChildren()) do
		if matchesMapName(child) then
			return child
		end
	end

	-- Then check inside the PolarPush folder, so a previously moved map is reused.
	if self.folder then
		for _, child in ipairs(self.folder:GetChildren()) do
			if matchesMapName(child) then
				return child
			end
		end
		for _, descendant in ipairs(self.folder:GetDescendants()) do
			if matchesMapName(descendant) then
				return descendant
			end
		end
	end

	return nil
end

function PolarPush:workspaceMapOriginPosition()
	if not self.workspaceMap or not self.workspaceMap:IsA("Model") then
		return nil
	end

	local center = self:mapPart(CENTER_PART_NAME)
	if center then
		return center.Position
	end

	if self.workspaceMap.PrimaryPart then
		return self.workspaceMap.PrimaryPart.Position
	end

	return self.workspaceMap:GetPivot().Position
end

function PolarPush:moveWorkspaceMapToArena()
	if not self.workspaceMap or not self.workspaceMap:IsA("Model") then
		return
	end

	local targetOrigin = self.context.config.Arenas.PolarPush
	local currentOrigin = self:workspaceMapOriginPosition() or self.workspaceMap:GetPivot().Position
	local pivot = self.workspaceMap:GetPivot()
	local offset = targetOrigin - currentOrigin

	self.workspaceMap:PivotTo(pivot + offset)
	self.workspaceMap.Parent = self.folder
	self.origin = targetOrigin
end

function PolarPush:build()
	self.workspaceMap = self:findWorkspaceMap()
	table.clear(self.edgeParts)
	table.clear(self.edgePartSet)
	table.clear(self.deathWaterParts)
	table.clear(self.spawnPoints)

	if self.workspaceMap then
		self:moveWorkspaceMapToArena()
		self:bindWorkspaceMap()
	else
		self:buildPrototypeMap()
	end
	self:registerWorkspaceDeathWater()
	self:updateStudioZoomFocus()

	Shared.makeBillboard("PolarPushSign", "Polar Push: push players, break ice walls", self.origin + Vector3.new(0, 10, -42), self.folder)
end

function PolarPush:forcePaintablePart(part)
	if not part:IsA("BasePart") then
		return
	end

	part.CanQuery = true
	part.CastShadow = false
	part.Reflectance = math.max(part.Reflectance, 0.1)

	-- Do the expensive imported-asset cleanup only once per part.
	-- This keeps the color visible on MeshParts without repeating work every round.
	if part:GetAttribute("PolarPushPaintPrepared") == true then
		return
	end

	if part:IsA("MeshPart") then
		pcall(function()
			part.UsePartColor = true
		end)
		pcall(function()
			part.TextureID = ""
		end)
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("SurfaceAppearance") or child:IsA("Texture") or child:IsA("Decal") then
			pcall(function()
				child:Destroy()
			end)
		end
	end

	part:SetAttribute("PolarPushPaintPrepared", true)
end

function PolarPush:applyIcePhysics(part)
	if part:IsA("BasePart") then
		self:forcePaintablePart(part)
		if part.Material == Enum.Material.Ice then
			part.CustomPhysicalProperties = ICE_PHYSICS
		end
	end
end

function PolarPush:paintIcePart(part, forceBreakable)
	if not part:IsA("BasePart") then
		return
	end

	self:forcePaintablePart(part)

	local normalized = normalizedName(part.Name)
	local breakable = forceBreakable or self:isWorkspaceBreakableBorderPart(part)
	local floorLike = self:isWorkspaceArenaFloorPart(part)

	if self:isDeathWaterPart(part) then
		part.Material = Enum.Material.SmoothPlastic
		part.Color = DARK_WATER_COLOR
		part.Transparency = math.min(part.Transparency, 0.18)
		return
	end

	if breakable then
		part.Material = Enum.Material.Ice
		part.Color = if normalized:find("spike", 1, true) then ICE_SPIKE_COLOR else ICE_BORDER_COLOR
		part.Transparency = math.min(part.Transparency, 0.12)
		part.CustomPhysicalProperties = ICE_PHYSICS
	elseif floorLike then
		part.Material = Enum.Material.Ice
		part.Color = ICE_FLOOR_COLOR
		part.Transparency = math.min(part.Transparency, 0.06)
		part.CustomPhysicalProperties = ICE_PHYSICS
	elseif normalized:find("ice", 1, true) then
		part.Material = Enum.Material.Ice
		part.Color = ICE_TILE_COLOR
		part.Transparency = math.min(part.Transparency, 0.18)
		part.CustomPhysicalProperties = ICE_PHYSICS
	elseif normalized:find("crack", 1, true) or normalized:find("line", 1, true) then
		part.Material = Enum.Material.Neon
		part.Color = ICE_CRACK_COLOR
		part.Transparency = math.min(part.Transparency, 0.25)
	end

	part:SetAttribute("PaintedByPolarPush", true)
end

function PolarPush:paintWorkspaceMap()
	if not self.workspaceMap then
		return
	end

	for _, item in ipairs(self.workspaceMap:GetDescendants()) do
		if item:IsA("BasePart") then
			local isBreakable = self.edgePartSet[item] == true or self:isWorkspaceBreakableBorderPart(item)
			self:paintIcePart(item, isBreakable)
			if isBreakable then
				item:SetAttribute("BaseColor", item.Color)
				item:SetAttribute("BaseTransparency", item.Transparency)
			end
		end
	end

	self:updateStudioZoomFocus()
end

function PolarPush:updateStudioZoomFocus()
	local focusName = "PolarPush_ZoomFocus_SelectThis"
	local parent = self.workspaceMap or self.folder
	if not parent then
		return
	end

	local focus = parent:FindFirstChild(focusName, true)
	if not (focus and focus:IsA("BasePart")) then
		focus = Instance.new("Part")
		focus.Name = focusName
		focus.Parent = parent
	end

	local diameter = (self.radius or TARGET_WORKSPACE_RADIUS) * 2 + 28
	focus.Anchored = true
	focus.CanCollide = false
	focus.CanTouch = false
	focus.CanQuery = true
	focus.CastShadow = false
	focus.Transparency = 0.965
	focus.Material = Enum.Material.ForceField
	focus.Color = Color3.fromRGB(90, 230, 255)
	focus.Size = Vector3.new(diameter, 1, diameter)
	focus.CFrame = CFrame.new(self.origin + Vector3.new(0, -3.2, 0))
	focus:SetAttribute("Purpose", "Select this part and press F to zoom to the full Polar Push arena in Studio")

	-- Do not set this as PrimaryPart. Some imported models throw errors when
	-- their PrimaryPart is changed at runtime; selecting this part manually is enough.
end

function PolarPush:isWorkspaceArenaFloorPart(part)
	if not part:IsA("BasePart") then
		return false
	end

	local normalized = normalizedName(part.Name)
	return normalized:find("floor", 1, true) ~= nil
		or normalized:find("base", 1, true) ~= nil
		or normalized:find("arena", 1, true) ~= nil
		or normalized == "reffloor"
end

function PolarPush:configureWorkspaceArenaPart(part, forceBreakable)
	if not part:IsA("BasePart") then
		return
	end

	part.Anchored = true
	part.CanQuery = true

	if forceBreakable or self:isWorkspaceBreakableBorderPart(part) then
		part.Material = Enum.Material.Ice
		part.CanCollide = true
		part.CanTouch = false
		part:SetAttribute("SourceAsset", part:GetAttribute("SourceAsset") or ICE_SPIKES_SOURCE_ASSET)
		part:SetAttribute("BreakOnHit", true)
		part:SetAttribute("MaxHealth", part:GetAttribute("MaxHealth") or WALL_MAX_HEALTH)
		self:registerBreakableWall(part)
	elseif self:isWorkspaceArenaFloorPart(part) then
		part.Material = Enum.Material.Ice
		part.CanCollide = true
		part.CanTouch = false
		part:SetAttribute("SourceAsset", part:GetAttribute("SourceAsset") or ICE_SPIKES_SOURCE_ASSET)
		part.CustomPhysicalProperties = ICE_PHYSICS
	else
		self:applyIcePhysics(part)
	end

	self:paintIcePart(part, forceBreakable)
end

function PolarPush:isDeathWaterPart(part)
	if not part:IsA("BasePart") then
		return false
	end

	local normalizedName = string.lower((part.Name or ""):gsub("[^%w]", ""))
	return normalizedName:find("darkwater", 1, true) ~= nil
end

function PolarPush:registerDeathWater(part)
	if not part:IsA("BasePart") or self.deathWaterConnections[part] then
		return
	end

	part.CanTouch = true
	table.insert(self.deathWaterParts, part)
	self.deathWaterConnections[part] = part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end

		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local subject = Players:GetPlayerFromCharacter(character)
		if not subject then
			for _, bot in ipairs(Shared.testBots()) do
				if bot == character then
					subject = bot
					break
				end
			end
		end

		if subject and subject:GetAttribute("RoundContestant") == true then
			Shared.eliminate(subject)
		else
			humanoid.Health = 0
		end
	end)
end

function PolarPush:registerWorkspaceDeathWater()
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("BasePart") and self:isDeathWaterPart(item) then
			self:registerDeathWater(item)
		end
	end
end

function PolarPush:addBreakOnHitScript(edge)
	if not edge:IsA("BasePart") then
		return
	end

	edge.Anchored = true
	for _, existing in ipairs(edge:GetDescendants()) do
		if existing.Name == "BreakOnHit" or existing:IsA("Script") or existing:IsA("LocalScript") then
			existing:Destroy()
		end
	end

	local marker = Instance.new("BoolValue")
	marker.Name = "BreakOnHit"
	marker.Value = true
	marker.Parent = edge
end

function PolarPush:mapPart(name)
	if not self.workspaceMap then
		return nil
	end

	local instance = self.workspaceMap:FindFirstChild(name, true)
	if instance and instance:IsA("BasePart") then
		return instance
	end
	return nil
end

function PolarPush:bindWorkspaceMap()
	self.workspaceMap:SetAttribute("PolarPushArenaSource", self.workspaceMap.Name)
	if normalizedName(self.workspaceMap.Name):find("icespike", 1, true) or normalizedName(self.workspaceMap.Name):find("iceapiked", 1, true) then
		self.workspaceMap:SetAttribute("SourceAsset", self.workspaceMap:GetAttribute("SourceAsset") or ICE_SPIKES_SOURCE_ASSET)
	end

	self.origin = self.context.config.Arenas.PolarPush

	local wallsFolder = self.workspaceMap:FindFirstChild(BREAKABLE_WALLS_FOLDER_NAME, true)
	if wallsFolder then
		for _, item in ipairs(wallsFolder:GetDescendants()) do
			if item:IsA("BasePart") then
				self:configureWorkspaceArenaPart(item, true)
			end
		end
	end

	for _, item in ipairs(self.workspaceMap:GetDescendants()) do
		if item:IsA("BasePart") then
			self:configureWorkspaceArenaPart(item, false)
		end
	end

	local spawnsFolder = self.workspaceMap:FindFirstChild(SPAWNS_FOLDER_NAME, true)
	if spawnsFolder then
		for _, item in ipairs(spawnsFolder:GetDescendants()) do
			if item:IsA("BasePart") then
				table.insert(self.spawnPoints, item)
			end
		end
	end

	for _, item in ipairs(self.workspaceMap:GetDescendants()) do
		if item:IsA("BasePart") and self:isDeathWaterPart(item) then
			self:registerDeathWater(item)
		end
	end

	local inferredRadius = self:inferWorkspaceRadius()
	if inferredRadius and math.abs(inferredRadius - TARGET_WORKSPACE_RADIUS) > 0.5 then
		self:scaleWorkspaceMap(inferredRadius, TARGET_WORKSPACE_RADIUS)
		inferredRadius = self:inferWorkspaceRadius()
	end
	self:paintWorkspaceMap()
	if inferredRadius then
		self.radius = math.max(MIN_WORKSPACE_RADIUS, inferredRadius)
		self.eliminationRadius = self.radius + FALL_RADIUS_BUFFER
	end
end

function PolarPush:isWorkspaceBreakableBorderPart(part)
	if not self.workspaceMap then
		return false
	end

	local cursor = part
	while cursor and cursor ~= self.workspaceMap do
		local normalized = normalizedName(cursor.Name)
		for _, pattern in ipairs(BREAKABLE_BORDER_NAME_PATTERNS) do
			if normalized:find(pattern, 1, true) then
				return true
			end
		end
		cursor = cursor.Parent
	end

	return false
end

function PolarPush:flatDistanceFromOrigin(part)
	local delta = Vector3.new(part.Position.X, self.origin.Y, part.Position.Z) - self.origin
	return delta.Magnitude
end

function PolarPush:inferWorkspaceRadius()
	if not self.workspaceMap then
		return nil
	end

	local radius = 0
	for _, edge in ipairs(self.edgeParts) do
		if edge.Parent then
			radius = math.max(radius, self:flatDistanceFromOrigin(edge))
		end
	end

	for _, spawnPart in ipairs(self.spawnPoints) do
		if spawnPart.Parent then
			radius = math.max(radius, self:flatDistanceFromOrigin(spawnPart) + 8)
		end
	end

	for _, item in ipairs(self.workspaceMap:GetDescendants()) do
		if item:IsA("BasePart") then
			local name = string.lower(item.Name)
			local isArenaSurface = name:find("floor") or name:find("base") or name:find("ice") or name:find("arena") or name:find("circle") or name:find("ring")
			local closeToArenaHeight = math.abs(item.Position.Y - self.origin.Y) <= 24
			if isArenaSurface and closeToArenaHeight then
				radius = math.max(radius, self:flatDistanceFromOrigin(item) + math.max(item.Size.X, item.Size.Z) * 0.5)
			end
		end
	end

	if radius > 0 then
		return radius
	end
	return nil
end

function PolarPush:scaleWorkspaceMap(currentRadius, targetRadius)
	if not self.workspaceMap or currentRadius <= 0 or targetRadius <= 0 then
		return
	end

	local alreadyScaledTo = self.workspaceMap:GetAttribute("PolarPushScaledRadius")
	if typeof(alreadyScaledTo) == "number" and math.abs(alreadyScaledTo - targetRadius) < 0.05 then
		return
	end

	local scale = targetRadius / currentRadius
	for _, item in ipairs(self.workspaceMap:GetDescendants()) do
		if item:IsA("BasePart") then
			local offset = item.Position - self.origin
			local scaledPosition = self.origin + Vector3.new(offset.X * scale, offset.Y, offset.Z * scale)
			item.CFrame = CFrame.new(scaledPosition) * item.CFrame.Rotation
			item.Size = Vector3.new(math.max(0.2, item.Size.X * scale), item.Size.Y, math.max(0.2, item.Size.Z * scale))
			item:SetAttribute("BaseCFrame", item.CFrame)
		elseif item:IsA("Attachment") then
			item.Position = Vector3.new(item.Position.X * scale, item.Position.Y, item.Position.Z * scale)
		end
	end

	self.workspaceMap:SetAttribute("PolarPushScaledRadius", targetRadius)
end

function PolarPush:buildPrototypeMap()
	if not self.folder:FindFirstChild("DarkWater") then
		local water = Shared.makePart("DarkWater", Vector3.new(126, 1, 126), CFrame.new(self.origin - Vector3.new(0, 9, 0)), DARK_WATER_COLOR, Enum.Material.SmoothPlastic, self.folder)
		self:registerDeathWater(water)
	else
		local water = self.folder:FindFirstChild("DarkWater")
		if water and water:IsA("BasePart") then
			water.Size = Vector3.new(196, 1, 196)
			water.Color = DARK_WATER_COLOR
			self:registerDeathWater(water)
		end
	end

	local base = self.folder:FindFirstChild("SolidIceBase")
	if not (base and base:IsA("BasePart")) then
		base = Shared.makePart("SolidIceBase", Vector3.new(86, 1.8, 86), CFrame.new(self.origin + Vector3.new(0, -4.25, 0)), ICE_FLOOR_COLOR, Enum.Material.Ice, self.folder)
	end
	base.CustomPhysicalProperties = ICE_PHYSICS

	local existingTiles = 0
	for _, child in ipairs(self.folder:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "IceFloorTile" then
			existingTiles += 1
			child.CustomPhysicalProperties = ICE_PHYSICS
		end
	end

	if existingTiles == 0 then
		for x = -7, 7 do
			for z = -7, 7 do
				local offset = Vector3.new(x * 6.5, -3.75, z * 6.5)
				local tile = Shared.makePart("IceFloorTile", Vector3.new(7.2, 0.45, 7.2), CFrame.new(self.origin + offset), ICE_TILE_COLOR, Enum.Material.Ice, self.folder)
				tile.CanCollide = false
				tile.CustomPhysicalProperties = ICE_PHYSICS
			end
		end
	end

	self:buildAssetIceBorder()
end

function PolarPush:buildAssetIceBorder()
	local existingBorder = self.folder:FindFirstChild("IceBorder_Roblox")
	if existingBorder then
		local wallsFolder = existingBorder:FindFirstChild(BREAKABLE_WALLS_FOLDER_NAME, true)
		local reusedWalls = 0
		if wallsFolder then
			for _, item in ipairs(wallsFolder:GetDescendants()) do
				if item:IsA("BasePart") then
					self:applyIcePhysics(item)
					item.Anchored = true
					item.CanCollide = true
					item.CanTouch = false
					item:SetAttribute("SourceAsset", item:GetAttribute("SourceAsset") or ICE_BORDER_SOURCE_ASSET)
					item:SetAttribute("BreakOnHit", true)
					item:SetAttribute("MaxHealth", item:GetAttribute("MaxHealth") or WALL_MAX_HEALTH)
					self:registerBreakableWall(item)
					reusedWalls += 1
				end
			end
		end
		if reusedWalls > 0 then
			existingBorder:SetAttribute("SourceAsset", existingBorder:GetAttribute("SourceAsset") or ICE_BORDER_SOURCE_ASSET)
			existingBorder:SetAttribute("PreservesExistingPolarMap", true)
			return
		end
		existingBorder:Destroy()
	end

	local border = Instance.new("Model")
	border.Name = "IceBorder_Roblox"
	border.Parent = self.folder
	border:SetAttribute("SourceAsset", ICE_BORDER_SOURCE_ASSET)
	border:SetAttribute("PreservesExistingPolarMap", true)

	local wallsFolder = Instance.new("Folder")
	wallsFolder.Name = BREAKABLE_WALLS_FOLDER_NAME
	wallsFolder.Parent = border

	local wallRadius = self.radius + 1.5
	local assetScale = wallRadius / ICE_BORDER_SOURCE_RADIUS
	local floorTop = self.origin.Y - 3.35
	local segmentWidth = 3.53 * assetScale
	local segmentDepth = 1.56 * assetScale

	for _, segment in ipairs(ICE_BORDER_SEGMENTS) do
		local angle = segment.angle
		local height = math.max(2.8, segment.height * assetScale)
		local position = self.origin + Vector3.new(math.cos(angle) * wallRadius, -self.origin.Y + floorTop + height / 2, math.sin(angle) * wallRadius)
		local lookTarget = Vector3.new(self.origin.X, position.Y, self.origin.Z)
		local edge = Shared.makePart(segment.name, Vector3.new(segmentWidth, height, segmentDepth), CFrame.lookAt(position, lookTarget), ICE_BORDER_COLOR, Enum.Material.Ice, wallsFolder)
		edge.Anchored = true
		edge.CanTouch = false
		edge.CustomPhysicalProperties = ICE_PHYSICS
		edge:SetAttribute("SourceAsset", ICE_BORDER_SOURCE_ASSET)
		edge:SetAttribute("BreakOnHit", true)
		edge:SetAttribute("MaxHealth", WALL_MAX_HEALTH)
		self:addBreakOnHitScript(edge)
		self:registerBreakableWall(edge)
	end
end

function PolarPush:connectBreakableWallTouch(edge)
	if not edge:IsA("BasePart") or self.wallTouchConnections[edge] then
		return
	end

	self.wallTouchConnections[edge] = edge.Touched:Connect(function(hit)
		if not edge.Parent or edge:GetAttribute("Broken") == true then
			return
		end

		if self:isWallBreakingHit(hit) then
			self:damageEdge(edge)
		end
	end)
end

function PolarPush:isWallBreakingHit(hit)
	if hit.Name == "Projectile" then
		return true
	end

	local character = hit:FindFirstAncestorOfClass("Model")
	if not character or not character:FindFirstChildWhichIsA("Humanoid") then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local now = os.clock()
	local rootPushUntil = root and root:GetAttribute("PolarPushingUntil")
	local characterPushUntil = character:GetAttribute("PolarPushingUntil")
	return (typeof(rootPushUntil) == "number" and now < rootPushUntil)
		or (typeof(characterPushUntil) == "number" and now < characterPushUntil)
end

function PolarPush:registerBreakableWall(edge)
	if self.edgePartSet[edge] then
		return
	end

	edge:SetAttribute("MaxHealth", edge:GetAttribute("MaxHealth") or WALL_MAX_HEALTH)
	edge:SetAttribute("Health", edge:GetAttribute("Health") or edge:GetAttribute("MaxHealth") or WALL_MAX_HEALTH)
	edge:SetAttribute("BaseCFrame", edge.CFrame)
	edge:SetAttribute("BaseTransparency", edge.Transparency)
	edge:SetAttribute("BaseColor", edge.Color)
	edge.Anchored = true
	edge.CanCollide = true
	edge.CanTouch = false
	self:addBreakOnHitScript(edge)
	self.edgePartSet[edge] = true
	table.insert(self.edgeParts, edge)
end

function PolarPush:announce(message)
	self.context.statusValue.Value = message
	self.context.lobbySign.Text = message
	print("[PolarPush] " .. message)
end

function PolarPush:resetEdges()
	for _, edge in ipairs(self.edgeParts) do
		if edge.Parent then
			local baseCFrame = edge:GetAttribute("BaseCFrame")
			local baseTransparency = edge:GetAttribute("BaseTransparency")
			local baseColor = edge:GetAttribute("BaseColor")

			edge:SetAttribute("Health", edge:GetAttribute("MaxHealth") or WALL_MAX_HEALTH)
			edge:SetAttribute("Broken", nil)
			edge.Anchored = true
			edge.CanCollide = true
			edge.CanTouch = false
			edge.Transparency = if typeof(baseTransparency) == "number" then baseTransparency else 0
			if typeof(baseColor) == "Color3" then
				edge.Color = baseColor
			else
				edge.Color = Color3.fromRGB(225, 250, 255)
			end
			if typeof(baseCFrame) == "CFrame" then
				edge.CFrame = baseCFrame
			end
		end
	end
end

function PolarPush:damageEdge(edge)
	if not edge or not edge.Parent or not edge.CanCollide then
		return
	end

	local health = (edge:GetAttribute("Health") or 1) - 1
	edge:SetAttribute("Health", health)
	edge.Color = Color3.fromRGB(255, 180, 180)
	edge.Transparency = 0.45
	self:playWallHitVfx(edge, health <= 0)

	if health <= 0 then
		local fallingEdge = edge:Clone()
		fallingEdge.Name = edge.Name .. "_Broken"
		local clonedBreakScript = fallingEdge:FindFirstChild("BreakOnHit")
		if clonedBreakScript then
			clonedBreakScript:Destroy()
		end
		fallingEdge.Anchored = false
		fallingEdge.CanCollide = false
		fallingEdge.CanTouch = false
		fallingEdge.CFrame = edge.CFrame
		fallingEdge.Parent = self.folder
		fallingEdge.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), math.random(6, 12), math.random(-8, 8))
		fallingEdge.AssemblyAngularVelocity = Vector3.new(math.random(-4, 4), math.random(-6, 6), math.random(-4, 4))
		Debris:AddItem(fallingEdge, 1.5)

		edge.CanCollide = false
		edge.Transparency = 1
		edge:SetAttribute("Broken", true)
		local baseCFrame = edge:GetAttribute("BaseCFrame")
		if typeof(baseCFrame) == "CFrame" then
			edge.CFrame = baseCFrame * CFrame.new(0, -12, 0)
		end
	end
end

function PolarPush:nearestEdgeInFront(root, originPosition)
	local bestEdge = nil
	local bestScore = 0
	local origin = originPosition or root.Position

	for _, edge in ipairs(self.edgeParts) do
		if edge.Parent and edge.CanCollide then
			local delta = edge.Position - origin
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local distance = flat.Magnitude
			if distance > 0.1 and distance <= WALL_HIT_RANGE then
				local score = root.CFrame.LookVector:Dot(flat.Unit)
				if score > bestScore then
					bestScore = score
					bestEdge = edge
				end
			end
		end
	end

	return bestEdge
end

function PolarPush:emitAt(name, cframe, color, count, speed, lifetime, size)
	local holder = Shared.makePart(name, Vector3.new(0.4, 0.4, 0.4), cframe, color, Enum.Material.Neon, self.folder)
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1

	local attachment = Instance.new("Attachment")
	attachment.Parent = holder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.7
	emitter.Lifetime = NumberRange.new(lifetime * 0.65, lifetime)
	emitter.Speed = NumberRange.new(speed * 0.45, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment
	emitter:Emit(count)

	Debris:AddItem(holder, lifetime + 1)
end

function PolarPush:playWallHitVfx(edge, broken)
	local color = if broken then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(120, 220, 255)
	self:emitAt("IceWallHit", edge.CFrame, color, if broken then 42 else 18, if broken then 34 else 18, 0.7, if broken then 1.4 else 0.8)

	if broken then
		for _ = 1, 8 do
			local shard = Shared.makePart("IceShard", Vector3.new(0.7, 0.25, 1.1), edge.CFrame * CFrame.new(math.random(-3, 3), math.random(-1, 2), math.random(-1, 1)), Color3.fromRGB(190, 240, 255), Enum.Material.Ice, self.folder)
			shard.Anchored = false
			shard.CanCollide = false
			shard.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), math.random(8, 20), math.random(-20, 20))
			shard.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
			Debris:AddItem(shard, 1.4)
		end
	end
end

function PolarPush:bearHeadFor(subject)
	local mount = self.activeMounts and self.activeMounts[subject]
	local bear = mount and mount.bear
	local head = bear and bear:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		return head
	end

	return nil
end

function PolarPush:hitboxCFrame(subject, root)
	local head = self:bearHeadFor(subject)
	if head then
		local forward = root.CFrame.LookVector
		return CFrame.lookAt(head.Position, head.Position + forward) * CFrame.new(0, -0.15, PUSH_HEAD_HITBOX_OFFSET)
	end

	return root.CFrame * CFrame.new(0, -1, PUSH_HITBOX_OFFSET)
end

function PolarPush:playPushVisual(subject, root, duration)
	local wind = Shared.makePart("PolarPushWind", Vector3.new(4.4, 0.15, 4.4), self:hitboxCFrame(subject, root) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(180, 240, 255), Enum.Material.Neon, self.folder)
	wind.Shape = Enum.PartType.Cylinder
	wind.Anchored = true
	wind.CanCollide = false
	wind.Transparency = 0.35
	Debris:AddItem(wind, duration)

	TweenService:Create(wind, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(7.5, 0.15, 7.5),
		Transparency = 1,
	}):Play()

	self:emitAt("PolarPushSnow", self:hitboxCFrame(subject, root), Color3.fromRGB(235, 250, 255), 30, 18, 0.45, 0.65)

	local endsAt = os.clock() + duration
	task.spawn(function()
		while wind.Parent and root.Parent and os.clock() < endsAt do
			wind.CFrame = self:hitboxCFrame(subject, root) * CFrame.Angles(math.rad(90), 0, 0)
			task.wait(0.03)
		end
	end)
end

function PolarPush:playWinnerAura(contestants)
	for place, contestant in ipairs(contestants) do
		if place > 3 or not contestant.root then
			continue
		end

		local attachment = Instance.new("Attachment")
		attachment.Name = "WinnerAuraAttachment"
		attachment.Parent = contestant.root

		local aura = Instance.new("ParticleEmitter")
		aura.Name = "WinnerAura"
		aura.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 210, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 95, 255)),
		})
		aura.LightEmission = 1
		aura.Lifetime = NumberRange.new(0.8, 1.2)
		aura.Rate = if place == 1 then 80 else 35
		aura.Speed = NumberRange.new(3, 7)
		aura.SpreadAngle = Vector2.new(30, 180)
		aura.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, if place == 1 then 0.9 else 0.55),
			NumberSequenceKeypoint.new(1, 0),
		})
		aura.Parent = attachment

		local light = Instance.new("PointLight")
		light.Color = if place == 1 then Color3.fromRGB(255, 220, 90) else Color3.fromRGB(80, 210, 255)
		light.Range = if place == 1 then 16 else 10
		light.Brightness = if place == 1 then 2.4 else 1.2
		light.Parent = contestant.root

		self:emitAt("WinnerFlash", contestant.root.CFrame, light.Color, if place == 1 then 70 else 30, 22, 1, if place == 1 then 1.3 else 0.8)
		Debris:AddItem(attachment, 7)
		Debris:AddItem(light, 7)
	end
end

function PolarPush:contestantSubjects()
	local subjects = {}

	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(subjects, player)
	end
	for _, bot in ipairs(Shared.testBots()) do
		table.insert(subjects, bot)
	end

	return subjects
end

function PolarPush:teleportContestants()
	if #self.spawnPoints == 0 then
		Shared.teleportPlayers(self.origin + Vector3.new(0, 4, 0), 13)
		return
	end

	local subjects = self:contestantSubjects()
	for index, subject in ipairs(subjects) do
		Shared.resetSubjectRoundState(subject)
		Shared.markContestantForGame(subject, self.name, false)
		if subject:IsA("Player") and not subject.Character then
			if not game:GetService("RunService"):IsRunning() then
				continue
			end
			subject.CharacterAdded:Wait()
		end

		local spawnPart = self.spawnPoints[((index - 1) % #self.spawnPoints) + 1]
		local root = Shared.rootFromSubject(subject)
		local humanoid = Shared.humanoidFromSubject(subject)
		if root then
			root.CFrame = spawnPart.CFrame * CFrame.new(0, 4, 0)
			root.AssemblyLinearVelocity = Vector3.zero
		end
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end
end

function PolarPush:modifierCenter()
	local modifierCenter = self:mapPart(MODIFIER_CENTER_PART_NAME)
	if modifierCenter then
		return modifierCenter.Position
	end
	return self.origin + Vector3.new(0, -4.8, 0)
end

local function flatVector(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function limitFlatVelocity(vector, maxSpeed)
	local magnitude = vector.Magnitude
	if magnitude > maxSpeed then
		return vector.Unit * maxSpeed
	end
	return vector
end

local function moveFlatToward(current, target, maxDelta)
	local delta = target - current
	local distance = delta.Magnitude
	if distance <= maxDelta or distance <= 0.001 then
		return target
	end
	return current + delta.Unit * maxDelta
end

function PolarPush:blockMomentum(subject, duration)
	if not subject then
		return
	end

	self.walkMomentum[subject] = 0
	self.lastMomentumAt[subject] = nil
	self.momentumBlockedUntil[subject] = os.clock() + (duration or MOMENTUM_BLOCK_DURATION)
end

function PolarPush:updateWalkMomentum(subject, humanoid, isPushing, now)
	if not subject then
		return 0
	end

	if isPushing then
		self:blockMomentum(subject, MOMENTUM_BLOCK_DURATION)
		return 0
	end

	local blockedUntil = self.momentumBlockedUntil[subject]
	if typeof(blockedUntil) == "number" and now < blockedUntil then
		return self.walkMomentum[subject] or 0
	end

	local moveDirection = humanoid and flatVector(humanoid.MoveDirection) or Vector3.zero
	if moveDirection.Magnitude <= MOMENTUM_MIN_MOVE then
		self.walkMomentum[subject] = 0
		self.lastMomentumAt[subject] = nil
		return 0
	end

	local lastAt = self.lastMomentumAt[subject] or now
	if now - lastAt >= MOMENTUM_INTERVAL then
		local steps = math.floor((now - lastAt) / MOMENTUM_INTERVAL)
		self.walkMomentum[subject] = math.min(MOMENTUM_MAX_BONUS, (self.walkMomentum[subject] or 0) + MOMENTUM_SPEED_STEP * steps)
		self.lastMomentumAt[subject] = lastAt + MOMENTUM_INTERVAL * steps
	elseif not self.lastMomentumAt[subject] then
		self.lastMomentumAt[subject] = now
	end

	return self.walkMomentum[subject] or 0
end

function PolarPush:pushPowerMultiplier(subject, root)
	local momentumBonus = self.walkMomentum[subject] or 0
	local flatSpeed = if root then flatVector(root.AssemblyLinearVelocity).Magnitude else 0
	local speedBonus = math.clamp((flatSpeed + momentumBonus) / 44, 0, PUSH_SPEED_POWER_BONUS_CAP)
	return 1 + speedBonus
end

function PolarPush:isPartTouchingDeathWater(part, heightPadding)
	if not part then
		return false
	end

	for _, water in ipairs(self.deathWaterParts) do
		if water.Parent then
			local localPosition = water.CFrame:PointToObjectSpace(part.Position)
			local halfSize = water.Size * 0.5
			local insideXZ = math.abs(localPosition.X) <= halfSize.X and math.abs(localPosition.Z) <= halfSize.Z
			local waterTop = water.Position.Y + halfSize.Y
			if insideXZ and part.Position.Y <= waterTop + (heightPadding or DEATH_WATER_TOUCH_HEIGHT) then
				return true
			end
		end
	end

	return false
end

function PolarPush:isContestantTouchingDeathWater(contestant)
	if self:isPartTouchingDeathWater(contestant.root, DEATH_WATER_TOUCH_HEIGHT) then
		return true
	end

	local mount = self.activeMounts and self.activeMounts[contestant.subject]
	local bear = mount and mount.bear
	if not bear then
		return false
	end

	for _, item in ipairs(bear:GetDescendants()) do
		if item:IsA("BasePart") and self:isPartTouchingDeathWater(item, 1.75) then
			return true
		end
	end

	return false
end

function PolarPush:groundBelowContestant(contestant)
	local root = contestant.root
	if not root then
		return nil
	end

	local ignore = {}
	if contestant.character then
		table.insert(ignore, contestant.character)
	end

	local mount = self.activeMounts and self.activeMounts[contestant.subject]
	if mount and mount.folder then
		table.insert(ignore, mount.folder)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = ignore
	raycastParams.IgnoreWater = false

	local origin = root.Position + Vector3.yAxis * GROUND_STABILIZE_RAY_UP
	local direction = Vector3.yAxis * -(GROUND_STABILIZE_RAY_UP + GROUND_STABILIZE_RAY_DOWN)
	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result or result.Normal.Y < 0.72 then
		return nil
	end

	if self.edgePartSet[result.Instance] then
		return nil
	end

	return result
end

function PolarPush:stabilizeContestantHeight(contestant)
	local root = contestant.root
	local humanoid = contestant.humanoid
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local ground = self:groundBelowContestant(contestant)
	if not ground then
		return
	end

	local rootHalfHeight = root.Size.Y * 0.5
	local targetY = ground.Position.Y + humanoid.HipHeight + rootHalfHeight - GROUND_STABILIZE_PADDING
	if root.Position.Y >= targetY - 0.18 then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	if velocity.Y > 2 then
		return
	end

	root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z) * root.CFrame.Rotation
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, 0), velocity.Z)
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

function PolarPush:applyIceSlide(deltaTime)
	local now = os.clock()
	for _, contestant in ipairs(Shared.aliveContestants()) do
		local subject = contestant.subject
		local root = contestant.root
		local humanoid = contestant.humanoid
		if root and humanoid and humanoid.Health > 0 and not Shared.isSpectating(subject) then
			local currentVelocity = root.AssemblyLinearVelocity
			local currentFlat = flatVector(currentVelocity)
			local slide = self.slideVelocity[subject] or currentFlat
			local pushUntil = root:GetAttribute("PolarPushingUntil")
			local isPushing = typeof(pushUntil) == "number" and now < pushUntil
			local momentumBonus = self:updateWalkMomentum(subject, humanoid, isPushing, now)

			if isPushing then
				slide = currentFlat * ICE_SLIDE_PUSH_MEMORY
			else
				local moveDirection = flatVector(humanoid.MoveDirection)
				if moveDirection.Magnitude > 0.08 then
					local target = moveDirection.Unit * (ICE_SLIDE_MAX_SPEED + momentumBonus)
					slide = moveFlatToward(slide, target, ICE_SLIDE_ACCELERATION * deltaTime)
				else
					slide *= math.max(0, 1 - ICE_SLIDE_DRAG * deltaTime)
					if slide.Magnitude < ICE_SLIDE_STOP_SPEED then
						slide = Vector3.zero
					end
				end

				slide = limitFlatVelocity(slide, ICE_SLIDE_MAX_SPEED + momentumBonus)
				root.AssemblyLinearVelocity = Vector3.new(slide.X, currentVelocity.Y, slide.Z)
			end

			self.slideVelocity[subject] = slide
		elseif subject then
			self.slideVelocity[subject] = nil
			self.walkMomentum[subject] = nil
			self.lastMomentumAt[subject] = nil
			self.momentumBlockedUntil[subject] = nil
		end
	end
end

function PolarPush:pushFrom(subject)
	local root = Shared.rootFromSubject(subject)
	local humanoid = Shared.humanoidFromSubject(subject)
	if not root or not humanoid or humanoid.Health <= 0 or Shared.isSpectating(subject) then
		return
	end

	local now = os.clock()
	local lastPush = self.lastPushAt[subject] or 0
	if now - lastPush < PUSH_COOLDOWN then
		return
	end
	self.lastPushAt[subject] = now

	local pushEndsAt = now + PUSH_DURATION
	local powerMultiplier = self:pushPowerMultiplier(subject, root)
	self:blockMomentum(subject, MOMENTUM_BLOCK_DURATION)
	subject:SetAttribute(PRIMARY_COOLDOWN_END_ATTRIBUTE, workspace:GetServerTimeNow() + PUSH_COOLDOWN)
	subject:SetAttribute(PRIMARY_COOLDOWN_DURATION_ATTRIBUTE, PUSH_COOLDOWN)
	root:SetAttribute("PolarPushingUntil", pushEndsAt)
	PolarPushModels.setPushState(self.activeMounts and self.activeMounts[subject], pushEndsAt, now)
	self:playPushVisual(subject, root, PUSH_DURATION)

	local pushDirection = root.CFrame.LookVector
	root.AssemblyLinearVelocity = pushDirection * PUSH_SPEED + Vector3.new(0, PUSH_HEIGHT, 0)

	local hitSubjects = {}
	local hitEdges = {}
	task.spawn(function()
		while root.Parent and os.clock() < pushEndsAt do
			local currentVelocity = root.AssemblyLinearVelocity
			local flatSpeed = Vector3.new(currentVelocity.X, 0, currentVelocity.Z).Magnitude
			if flatSpeed < PUSH_SPEED * 0.6 then
				root.AssemblyLinearVelocity = pushDirection * PUSH_SPEED * 0.7 + Vector3.new(0, currentVelocity.Y, 0)
			end

			local hitboxPosition = self:hitboxCFrame(subject, root).Position
			local edge = self:nearestEdgeInFront(root, hitboxPosition)
			if edge and not hitEdges[edge] then
				hitEdges[edge] = true
				self:damageEdge(edge)
			end

			for _, other in ipairs(Shared.aliveContestants()) do
				if other.subject ~= subject and other.root and not hitSubjects[other.subject] then
					local delta = other.root.Position - hitboxPosition
					local flatDelta = Vector3.new(delta.X, 0, delta.Z)
					if flatDelta.Magnitude > 0.1 and flatDelta.Magnitude <= PUSH_HITBOX_RADIUS then
						hitSubjects[other.subject] = true
						local power = PUSH_TARGET_POWER * Shared.getStrengthMultiplier(subject) * powerMultiplier
						other.root.AssemblyLinearVelocity = flatDelta.Unit * power + Vector3.new(0, 8, 0)
					end
				end
			end

			task.wait(0.04)
		end
	end)

	task.delay(PUSH_DURATION, function()
		if root.Parent then
			local currentVelocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = root.CFrame.LookVector * PUSH_AFTER_SPEED + Vector3.new(0, currentVelocity.Y, 0)
		end
	end)
end

function PolarPush:resolvePlayerCollisions()
	local contestants = Shared.aliveContestants()

	for i = 1, #contestants do
		for j = i + 1, #contestants do
			local first = contestants[i]
			local second = contestants[j]
			local firstRoot = first.root
			local secondRoot = second.root
			if firstRoot and secondRoot then
				local delta = secondRoot.Position - firstRoot.Position
				local flatDelta = Vector3.new(delta.X, 0, delta.Z)
				local distance = flatDelta.Magnitude
				if distance > 0.1 and distance <= COLLISION_DISTANCE then
					self:blockMomentum(first.subject, MOMENTUM_BLOCK_DURATION)
					self:blockMomentum(second.subject, MOMENTUM_BLOCK_DURATION)
				end
			end
		end
	end
end

function PolarPush:shouldEliminate(contestant)
	local root = contestant.root
	if self:isContestantTouchingDeathWater(contestant) then
		return true
	end

	if root.Position.Y < self.origin.Y + FALL_Y_OFFSET then
		return true
	end

	if self.workspaceMap then
		return false
	end

	local flatDistance = (Vector3.new(root.Position.X, self.origin.Y, root.Position.Z) - self.origin).Magnitude
	return flatDistance > (self.eliminationRadius or self.radius + FALL_RADIUS_BUFFER)
end

function PolarPush:run()
	self:resetEdges()
	table.clear(self.lastPushAt)
	table.clear(self.slideVelocity)
	table.clear(self.walkMomentum)
	table.clear(self.lastMomentumAt)
	table.clear(self.momentumBlockedUntil)
	table.clear(self.botMoveState)
	self:teleportContestants()

	local mounts = {}
	self.activeMounts = mounts
	task.wait(1)
	for _, contestant in ipairs(Shared.aliveContestants()) do
		mounts[contestant.subject] = PolarPushModels.attach(contestant.subject, self.folder)
		Shared.markContestantForGame(contestant.subject, self.name, true)
		contestant.subject:SetAttribute(PRIMARY_COOLDOWN_END_ATTRIBUTE, 0)
		contestant.subject:SetAttribute(PRIMARY_COOLDOWN_DURATION_ATTRIBUTE, PUSH_COOLDOWN)
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
			self:pushFrom(player)
		end)
	end)
	if not okConnection then
		warn("[PolarPush] PrimaryAction connection unavailable in this context: " .. tostring(actionConnection))
		actionConnection = nil
	end

	Shared.spawnModifierPickups(self.folder, self:modifierCenter(), MODIFIER_RADIUS, 1)

	self:announce("Polar Push: push players and break the ice walls")
	local roundEnd = os.clock() + self.context.config.RoundDuration
	local nextModifierSpawn = os.clock() + MODIFIER_INTERVAL
	local lastSlideUpdate = os.clock()

	while Shared.roundShouldContinue(roundEnd) do
		local now = os.clock()
		local deltaTime = math.clamp(now - lastSlideUpdate, 0.02, 0.18)
		lastSlideUpdate = now

		if os.clock() >= nextModifierSpawn then
			Shared.spawnModifierPickups(self.folder, self:modifierCenter(), MODIFIER_RADIUS, 1)
			nextModifierSpawn = os.clock() + MODIFIER_INTERVAL
		end

		for _, bot in ipairs(Shared.testBots()) do
			local humanoid = Shared.humanoidFromSubject(bot)
			local root = Shared.rootFromSubject(bot)
			if humanoid and root and humanoid.Health > 0 and not bot:GetAttribute("Eliminated") then
				local state = self.botMoveState[bot]
				if not state or now >= state.nextMoveAt then
					state = {
						target = self.origin + Vector3.new(math.random(-14, 14), 1, math.random(-14, 14)),
						nextMoveAt = now + math.random(14, 24) / 10,
					}
					self.botMoveState[bot] = state
				end
				humanoid:MoveTo(state.target)
				if math.random() < 0.23 then
					self:pushFrom(bot)
				end
			end
		end

		for _, contestant in ipairs(Shared.aliveContestants()) do
			if contestant.humanoid then
				contestant.humanoid.JumpPower = 0
				contestant.humanoid.JumpHeight = 0
			end
			self:stabilizeContestantHeight(contestant)
			if contestant.root and self:shouldEliminate(contestant) then
				Shared.eliminate(contestant.subject)
			end
		end

		self:applyIceSlide(deltaTime)
		self:resolvePlayerCollisions()
		for _, contestant in ipairs(Shared.aliveContestants()) do
			self:stabilizeContestantHeight(contestant)
		end
		task.wait(0.12)
	end

	local winners = Shared.aliveContestants()
	self:playWinnerAura(winners)
	if actionConnection then
		actionConnection:Disconnect()
	end
	for _, contestant in ipairs(Shared.aliveContestants()) do
		contestant.subject:SetAttribute("AllowPrimaryAction", false)
		contestant.subject:SetAttribute("CurrentMinigame", nil)
		contestant.subject:SetAttribute(PRIMARY_COOLDOWN_END_ATTRIBUTE, nil)
		contestant.subject:SetAttribute(PRIMARY_COOLDOWN_DURATION_ATTRIBUTE, nil)
	end
	Shared.clearAllPlayerTools()
	PolarPushModels.detachAll(mounts)
	self.activeMounts = nil
	self:resetEdges()

	Shared.awardSurvivors(self.name, function(message)
		self:announce(message)
	end)
end

return PolarPush
