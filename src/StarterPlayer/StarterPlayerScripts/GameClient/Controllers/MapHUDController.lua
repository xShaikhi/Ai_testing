--[[
  MapHUDController
  Client-side: zone name popups, minimap hints, safe-zone indicator.
--]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- ── Zone data: name and rough bounds ─────────
local ZONES = {
	{name="Central Plaza",        cx=0,    cz=0,    rx=65,  rz=65,  color=Color3.fromRGB(0,240,255)},
	{name="Leaderboard District", cx=0,    cz=-140, rx=50,  rz=40,  color=Color3.fromRGB(255,200,0)},
	{name="Shop District",        cx=130,  cz=-80,  rx=55,  rz=45,  color=Color3.fromRGB(255,0,180)},
	{name="Mini-Game Zone",       cx=155,  cz=40,   rx=60,  rz=50,  color=Color3.fromRGB(0,240,255)},
	{name="Pet Egg Zone",         cx=85,   cz=145,  rx=50,  rz=45,  color=Color3.fromRGB(255,0,180)},
	{name="Quest Hub",            cx=0,    cz=145,  rx=50,  rz=40,  color=Color3.fromRGB(0,255,100)},
	{name="Upgrade Lab",          cx=-135, cz=85,   rx=50,  rz=45,  color=Color3.fromRGB(0,120,255)},
	{name="AFK Reward Park",      cx=-158, cz=0,    rx=50,  rz=45,  color=Color3.fromRGB(0,255,100)},
	{name="Daily Reward Station", cx=-55,  cz=-70,  rx=30,  rz=28,  color=Color3.fromRGB(255,200,0)},
	{name="Trading Plaza",        cx=-125, cz=-90,  rx=50,  rz=45,  color=Color3.fromRGB(255,140,0)},
	{name="Teleport Hub",         cx=0,    cz=-235, rx=45,  rz=35,  color=Color3.fromRGB(130,0,255)},
}

-- ── Build zone banner UI ──────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MapHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Zone name banner (bottom-center)
local zoneBanner = Instance.new("Frame")
zoneBanner.Name = "ZoneBanner"
zoneBanner.Size = UDim2.new(0, 300, 0, 60)
zoneBanner.Position = UDim2.new(0.5, -150, 1, -90)
zoneBanner.BackgroundColor3 = Color3.fromRGB(0,0,0)
zoneBanner.BackgroundTransparency = 0.4
zoneBanner.BorderSizePixel = 0
zoneBanner.Visible = false
zoneBanner.Parent = screenGui

local bannerCorner = Instance.new("UICorner", zoneBanner)
bannerCorner.CornerRadius = UDim.new(0, 10)

local bannerStroke = Instance.new("UIStroke", zoneBanner)
bannerStroke.Thickness = 2
bannerStroke.Color = Color3.fromRGB(0, 240, 255)

local bannerLabel = Instance.new("TextLabel", zoneBanner)
bannerLabel.Size = UDim2.new(1, 0, 1, 0)
bannerLabel.BackgroundTransparency = 1
bannerLabel.TextColor3 = Color3.fromRGB(255,255,255)
bannerLabel.Font = Enum.Font.GothamBold
bannerLabel.TextScaled = true
bannerLabel.Text = "Central Plaza"

-- Safe zone indicator (top-right)
local safeFrame = Instance.new("Frame")
safeFrame.Name = "SafeZone"
safeFrame.Size = UDim2.new(0, 140, 0, 36)
safeFrame.Position = UDim2.new(1, -150, 0, 10)
safeFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
safeFrame.BackgroundTransparency = 0.3
safeFrame.BorderSizePixel = 0
safeFrame.Visible = false
safeFrame.Parent = screenGui

Instance.new("UICorner", safeFrame).CornerRadius = UDim.new(0, 8)

local safeLabel = Instance.new("TextLabel", safeFrame)
safeLabel.Size = UDim2.new(1,0,1,0)
safeLabel.BackgroundTransparency = 1
safeLabel.TextColor3 = Color3.fromRGB(255,255,255)
safeLabel.Font = Enum.Font.GothamBold
safeLabel.TextScaled = true
safeLabel.Text = "🛡 SAFE ZONE"

-- ── Zone detection ────────────────────────────
local currentZone = nil
local SAFE_ZONES = {"Central Plaza", "AFK Reward Park", "Trading Plaza"}

local function isSafe(zoneName)
	for _, sz in ipairs(SAFE_ZONES) do
		if sz == zoneName then return true end
	end
	return false
end

local function getZoneAt(x, z)
	for _, zone in ipairs(ZONES) do
		if math.abs(x - zone.cx) <= zone.rx and math.abs(z - zone.cz) <= zone.rz then
			return zone
		end
	end
	return nil
end

local function showZoneBanner(zone)
	bannerLabel.Text = zone.name
	bannerStroke.Color = zone.color
	zoneBanner.Visible = true
	safeFrame.Visible = isSafe(zone.name)
	zoneBanner.BackgroundTransparency = 0.4
end

local function hideZoneBanner()
	zoneBanner.Visible = false
	safeFrame.Visible = false
end

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pos = root.Position
	local zone = getZoneAt(pos.X, pos.Z)
	if zone then
		if not currentZone or currentZone.name ~= zone.name then
			currentZone = zone
			showZoneBanner(zone)
		end
	else
		if currentZone then
			currentZone = nil
			hideZoneBanner()
		end
	end
end)

print("[MapHUDController] Loaded")
