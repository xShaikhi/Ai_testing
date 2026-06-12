--[[
  NeonRobotWorld - MapAnimations
  Animates neon elements: pulsing lights, rotating core, orbiting orbs,
  holographic flicker, and celebration effects.
  Runs server-side; visual effects replicate to all clients.
--]]

local RunService = game:GetService("RunService")
local map = workspace:WaitForChild("NeonRobotWorld", 30)
if not map then return end

-- ── Utility ──────────────────────────────────
local function lerp(a, b, t) return a + (b - a) * t end
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local COLORS = {
	cyan         = rgb(0, 240, 255),
	purple       = rgb(130, 0, 255),
	electricBlue = rgb(0, 120, 255),
	pink         = rgb(255, 0, 180),
	gold         = rgb(255, 200, 0),
	green        = rgb(0, 255, 100),
	orange       = rgb(255, 140, 0),
	white        = rgb(255, 255, 255),
}
local NEON_CYCLE = {COLORS.cyan, COLORS.purple, COLORS.electricBlue, COLORS.pink, COLORS.gold}

-- Collect by name pattern
local function findAll(folder, namePattern)
	local results = {}
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") and d.Name:find(namePattern) then
			results[#results+1] = d
		end
	end
	return results
end

-- ── Energy Core rotation (OrbRing parts) ────
local coreFolder = map:FindFirstChild("EnergyCore")
local orbRings = coreFolder and findAll(coreFolder, "OrbRing") or {}
local coreOrb  = coreFolder and coreFolder:FindFirstChild("CoreOrb") or nil
local coreOrbInner = coreFolder and coreFolder:FindFirstChild("CoreOrbInner") or nil

-- ── Portal shimmer (PortalDisc parts) ───────
local portalFolder = map:FindFirstChild("MinigamePortals")
local portalDiscs = portalFolder and findAll(portalFolder, "PortalDisc") or {}

-- ── Daily Reward button pulse ────────────────
local dailyFolder = map:FindFirstChild("DailyReward")
local drButton = dailyFolder and dailyFolder:FindFirstChild("DRButton") or nil

-- ── Fountain orb ────────────────────────────
local tradeFolder = map:FindFirstChild("TradingPlaza")
local fountainOrb = tradeFolder and tradeFolder:FindFirstChild("FountainOrb") or nil
local waterRing   = tradeFolder and tradeFolder:FindFirstChild("Water") or nil

-- ── Leaderboard hologram rows ────────────────
local lbFolder = map:FindFirstChild("LeaderboardDistrict")
local holoRows = lbFolder and findAll(lbFolder, "HoloRank") or {}

-- ── Ambient orbs float up/down ───────────────
local envFolder = map:FindFirstChild("EnvironmentDetails")
local ambientOrbs = envFolder and findAll(envFolder, "AmbientOrb") or {}
local orbBaseY = {}
for _, orb in ipairs(ambientOrbs) do
	orbBaseY[orb] = orb.CFrame.Y
end

-- ── Store original CFrames for rotation ──────
local orbRingBase = {}
for _, ring in ipairs(orbRings) do
	orbRingBase[ring] = ring.CFrame
end

-- Track time
local t0 = tick()

RunService.Heartbeat:Connect(function()
	local t = tick() - t0

	-- 1. Energy Core orb pulse
	if coreOrb then
		local pulse = 0.5 + 0.5 * math.sin(t * 2)
		coreOrb.Color = Color3.fromRGB(
			math.floor(lerp(0, 60, pulse)),
			math.floor(lerp(200, 255, pulse)),
			255
		)
	end
	if coreOrbInner then
		local p2 = 0.5 + 0.5 * math.sin(t * 2 + 1)
		coreOrbInner.Color = Color3.fromRGB(
			math.floor(lerp(200, 255, p2)),
			math.floor(lerp(200, 255, p2)),
			255
		)
	end

	-- 2. Orbit ring positions rotate
	if #orbRings > 0 then
		-- We group rings into 3 orbital planes (24 rings each = 72 total)
		local plane1Count = math.min(24, #orbRings)
		for i = 1, plane1Count do
			local ring = orbRings[i]
			if ring and ring.Parent then
				local baseAngle = (i-1)/plane1Count * math.pi*2
				local angle = baseAngle + t * 0.8
				local rx = math.cos(angle) * 7
				local ry = math.sin(angle) * 7
				ring.CFrame = CFrame.new(rx, 22 + ry, 0)
			end
		end
	end

	-- 3. Portal disc shimmer (cycle hue brightness)
	for i, disc in ipairs(portalDiscs) do
		if disc and disc.Parent then
			local shimmer = 0.7 + 0.3 * math.sin(t * 3 + i * 1.2)
			disc.Transparency = 1 - shimmer
		end
	end

	-- 4. Daily Reward button pulse (scale brightness via color)
	if drButton and drButton.Parent then
		local pulse = 0.5 + 0.5 * math.sin(t * 4)
		drButton.Color = Color3.fromRGB(
			255,
			math.floor(lerp(140, 220, pulse)),
			math.floor(lerp(0, 60, pulse))
		)
	end

	-- 5. Fountain orb color cycle
	if fountainOrb and fountainOrb.Parent then
		local idx = math.floor(t * 0.5) % #NEON_CYCLE + 1
		local nextIdx = (idx % #NEON_CYCLE) + 1
		local frac = (t * 0.5) % 1
		local c1 = NEON_CYCLE[idx]
		local c2 = NEON_CYCLE[nextIdx]
		fountainOrb.Color = Color3.new(
			lerp(c1.R, c2.R, frac),
			lerp(c1.G, c2.G, frac),
			lerp(c1.B, c2.B, frac)
		)
	end
	if waterRing and waterRing.Parent then
		waterRing.CFrame = waterRing.CFrame * CFrame.Angles(0, 0.01, 0)
	end

	-- 6. Holographic leaderboard rows flicker
	for i, row in ipairs(holoRows) do
		if row and row.Parent then
			local flicker = 0.5 + 0.5 * math.sin(t * 8 + i * 0.7)
			row.Transparency = lerp(0.6, 0.9, flicker)
		end
	end

	-- 7. Ambient orbs float
	for i, orb in ipairs(ambientOrbs) do
		if orb and orb.Parent then
			local baseY = orbBaseY[orb] or 8
			local newY = baseY + math.sin(t * 1.2 + i * 0.8) * 1.5
			orb.CFrame = CFrame.new(orb.CFrame.X, newY, orb.CFrame.Z)
		end
	end
end)

print("[MapAnimations] Running")
