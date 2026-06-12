--[[
  NeonRobotWorld MapBuilder
  Procedurally builds the entire hub map at runtime.
  All zones radiate from the Central Spawn Plaza.
--]]

local RunService = game:GetService("RunService")

-- ─────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function v3(x, y, z)  return Vector3.new(x, y, z) end
local function cf(x, y, z)  return CFrame.new(x, y, z) end

local COLORS = {
	electricBlue  = rgb(0,   120, 255),
	cyan          = rgb(0,   240, 255),
	purple        = rgb(130,  0,  255),
	pink          = rgb(255,  0,  180),
	orange        = rgb(255, 140,   0),
	white         = rgb(255, 255, 255),
	gold          = rgb(255, 200,   0),
	green         = rgb(0,   255, 100),
	darkBase      = rgb(8,    5,   20),
	darkPlate     = rgb(15,  10,  35),
	midGrey       = rgb(40,  30,  70),
}

local map = Instance.new("Folder")
map.Name = "NeonRobotWorld"
map.Parent = workspace

-- Zone folders
local function zoneFolder(name)
	local f = Instance.new("Folder"); f.Name = name; f.Parent = map; return f
end

-- ─────────────────────────────────────────────
-- PART FACTORY
-- ─────────────────────────────────────────────
local function makePart(parent, props)
	local p = Instance.new("Part")
	p.Anchored   = true
	p.CastShadow = props.shadow or false
	p.Name       = props.name   or "Part"
	p.Size       = props.size   or v3(4,4,4)
	p.CFrame     = props.cframe or cf(0,0,0)
	p.Color      = props.color  or COLORS.darkBase
	p.Material   = props.material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.neon then
		p.Material = Enum.Material.Neon
	end
	if props.reflectance then
		p.Reflectance = props.reflectance
	end
	p.Parent = parent
	return p
end

-- Wedge factory
local function makeWedge(parent, props)
	local p = Instance.new("WedgePart")
	p.Anchored = true; p.CastShadow = false
	p.Name = props.name or "Wedge"
	p.Size = props.size or v3(4,4,4)
	p.CFrame = props.cframe or cf(0,0,0)
	p.Color = props.color or COLORS.darkBase
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- SurfaceGui label
local function addLabel(part, text, color, fontSize)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(800, 200)
	local lbl = Instance.new("TextLabel", sg)
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or COLORS.cyan
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextStrokeTransparency = 0.4
	lbl.TextStrokeColor3 = rgb(0,0,0)
	sg.Parent = part
	return sg
end

-- PointLight helper
local function addLight(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color or COLORS.cyan
	l.Range = range or 20
	l.Brightness = brightness or 3
	l.Parent = parent
	return l
end

-- SpotLight helper
local function addSpot(parent, color, range, brightness, angle)
	local l = Instance.new("SpotLight")
	l.Color = color or COLORS.cyan
	l.Range = range or 30
	l.Brightness = brightness or 4
	l.Angle = angle or 60
	l.Face = Enum.NormalId.Top
	l.Parent = parent
	return l
end

-- Cylinder helper (uses Part with cylinder shape)
local function makeCylinder(parent, props)
	local p = makePart(parent, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Ball helper
local function makeBall(parent, props)
	local p = makePart(parent, props)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Neon trim strip
local function neonStrip(parent, cframe, size, color)
	return makePart(parent, {
		name="NeonStrip", size=size, cframe=cframe,
		color=color, neon=true, shadow=false
	})
end

-- Neon pillar
local function neonPillar(parent, x, z, height, color)
	local y = height / 2
	makePart(parent, {
		name = "Pillar",
		size = v3(1.5, height, 1.5),
		cframe = cf(x, y, z),
		color = COLORS.darkPlate,
		material = Enum.Material.SmoothPlastic,
	})
	neonStrip(parent, cf(x, height + 0.5, z), v3(2, 1, 2), color)
	addLight(makePart(parent, {
		name="LightSource", size=v3(0.1,0.1,0.1),
		cframe=cf(x, height + 1, z), color=color, neon=true
	}), color, 18, 4)
end

-- Building block
local function makeBuilding(parent, cx, cz, w, d, h, wallColor, roofColor, label, labelColor)
	local floor = -1 -- ground at y=0, parts sit on terrain
	-- Main walls
	makePart(parent, {
		name="Building_Wall", size=v3(w, h, d),
		cframe=cf(cx, floor + h/2, cz),
		color=wallColor, material=Enum.Material.SmoothPlastic,
		reflectance=0.05, shadow=true,
	})
	-- Roof
	local roof = makePart(parent, {
		name="Building_Roof", size=v3(w+1, 1, d+1),
		cframe=cf(cx, floor+h+0.5, cz),
		color=roofColor, material=Enum.Material.SmoothPlastic,
	})
	-- Roof neon edge
	neonStrip(parent, cf(cx, floor+h+1.1, cz), v3(w+2, 0.4, 0.4), labelColor or COLORS.cyan)
	neonStrip(parent, cf(cx, floor+h+1.1, cz), v3(0.4, 0.4, d+2), labelColor or COLORS.cyan)
	-- Sign
	if label then
		local sign = makePart(parent, {
			name="Sign", size=v3(math.min(w-2,12), 3, 0.5),
			cframe=cf(cx, floor+h - 2, cz - d/2 - 0.3),
			color=COLORS.darkBase,
		})
		addLabel(sign, label, labelColor or COLORS.cyan)
	end
	-- Corner pillars
	local hw, hd = w/2, d/2
	for _, ox in ipairs({-hw+1, hw-1}) do
		for _, oz in ipairs({-hd+1, hd-1}) do
			neonPillar(parent, cx+ox, cz+oz, h, labelColor or COLORS.cyan)
		end
	end
	return roof
end

-- Pathway segment (flat strip)
local function makePath(parent, x1,z1, x2,z2, width, color)
	local mx, mz = (x1+x2)/2, (z1+z2)/2
	local dx, dz = x2-x1, z2-z1
	local len = math.sqrt(dx*dx + dz*dz)
	local angle = math.atan2(dx, dz)
	makePart(parent, {
		name="Pathway", size=v3(width, 0.5, len),
		cframe=CFrame.new(mx, 0.25, mz) * CFrame.Angles(0, angle, 0),
		color=color or COLORS.darkPlate,
		material=Enum.Material.SmoothPlastic,
	})
	-- Neon edge strips
	local offset = width/2 + 0.2
	for _, side in ipairs({-1, 1}) do
		local sx = mx + math.cos(angle + math.pi/2)*offset*side
		local sz = mz - math.sin(angle + math.pi/2)*offset*side
		neonStrip(parent, CFrame.new(sx, 0.7, sz) * CFrame.Angles(0, angle, 0),
			v3(0.3, 0.4, len), COLORS.electricBlue)
	end
end

-- ─────────────────────────────────────────────
-- GROUND BASEPLATE
-- ─────────────────────────────────────────────
local terrain = Instance.new("Part")
terrain.Anchored = true
terrain.Size = v3(600, 2, 600)
terrain.CFrame = cf(0, -1, 0)
terrain.Color = COLORS.darkBase
terrain.Material = Enum.Material.SmoothPlastic
terrain.Name = "Terrain_Ground"
terrain.TopSurface = Enum.SurfaceType.Smooth
terrain.BottomSurface = Enum.SurfaceType.Smooth
terrain.Parent = map

-- Grid pattern on ground (decorative)
for gx = -280, 280, 40 do
	neonStrip(map, cf(gx, 0.05, 0), v3(0.15, 0.1, 600), rgb(0, 40, 80))
end
for gz = -280, 280, 40 do
	neonStrip(map, cf(0, 0.05, gz), v3(600, 0.1, 0.15), rgb(0, 40, 80))
end

print("[MapBuilder] Ground created")

-- ─────────────────────────────────────────────
-- LIGHTING & ENVIRONMENT
-- ─────────────────────────────────────────────
local lighting = game:GetService("Lighting")
lighting.Ambient        = rgb(10, 5, 30)
lighting.OutdoorAmbient = rgb(20, 10, 60)
lighting.Brightness     = 0.8
lighting.ClockTime      = 0
lighting.FogEnd         = 900
lighting.FogColor       = rgb(5, 2, 20)
lighting.FogStart       = 500

local atmo = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", lighting)
atmo.Density = 0.25
atmo.Offset  = 0.05
atmo.Color   = rgb(15, 5, 45)
atmo.Decay   = rgb(5, 2, 20)
atmo.Glare   = 0.1
atmo.Haze    = 0.8

local bloom = lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", lighting)
bloom.Intensity  = 0.8
bloom.Size       = 28
bloom.Threshold  = 0.75

local cc = lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", lighting)
cc.Saturation = 0.25
cc.Contrast   = 0.08
cc.TintColor  = rgb(210, 200, 255)

local sky = lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", lighting)
sky.StarCount = 5000

print("[MapBuilder] Lighting set")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 1: CENTRAL SPAWN PLAZA  (origin 0,0,0)
-- ─────────────────────────────────────────────────────────────────────────────
local spawnZone = zoneFolder("SpawnPlaza")

-- Main circular platform (approximated with octagon rings of parts)
local function ringParts(parent, cx, cz, radius, thickness, height, y, color, mat)
	local steps = 24
	for i = 1, steps do
		local a1 = (i-1)/steps * math.pi*2
		local a2 = i/steps * math.pi*2
		local ma = (a1+a2)/2
		local px = cx + math.cos(ma) * radius
		local pz = cz + math.sin(ma) * radius
		local segLen = radius * 2 * math.sin(math.pi/steps) + 0.5
		makePart(parent, {
			name="Ring", size=v3(thickness, height, segLen),
			cframe=CFrame.new(px, y + height/2, pz) * CFrame.Angles(0, -ma, 0),
			color=color, material=mat or Enum.Material.SmoothPlastic,
		})
	end
end

-- Floor disc (solid filled circle via concentric fills)
for r = 2, 56, 8 do
	local thickness = 8
	local segCount = math.max(8, math.floor(r * math.pi / 4))
	local steps = segCount
	for i = 1, steps do
		local a = (i-0.5)/steps * math.pi*2
		local px = math.cos(a) * r
		local pz = math.sin(a) * r
		local segLen = r * 2 * math.sin(math.pi/steps) + 1
		makePart(spawnZone, {
			name="Floor", size=v3(thickness, 1, segLen),
			cframe=CFrame.new(px, 0.5, pz) * CFrame.Angles(0, -a, 0),
			color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic,
			reflectance=0.12,
		})
	end
end

-- Center fill
makePart(spawnZone, {name="FloorCenter", size=v3(16,1,16), cframe=cf(0,0.5,0),
	color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic, reflectance=0.15})

-- Outer ring glow
ringParts(spawnZone, 0,0, 56, 2, 1.5, 0.5, COLORS.cyan, Enum.Material.Neon)

-- Mid ring
ringParts(spawnZone, 0,0, 36, 1, 0.5, 0.5, COLORS.electricBlue, Enum.Material.Neon)

-- Inner ring
ringParts(spawnZone, 0,0, 18, 1, 0.5, 0.5, COLORS.purple, Enum.Material.Neon)

-- Raised border wall
ringParts(spawnZone, 0,0, 58, 3, 4, 0.5, COLORS.midGrey, Enum.Material.SmoothPlastic)
ringParts(spawnZone, 0,0, 58, 0.5, 4.5, 0.5, COLORS.cyan, Enum.Material.Neon)

-- Spawn point
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.CFrame = cf(0, 2, 0)
spawn.Size = v3(4,1,4)
spawn.Anchored = true
spawn.Color = COLORS.purple
spawn.Material = Enum.Material.Neon
spawn.TeamColor = BrickColor.new("White")
spawn.Parent = spawnZone

-- ── Energy Core Centerpiece ──────────────────
local coreZone = zoneFolder("EnergyCore")

-- Core base platform
makePart(coreZone, {name="CoreBase", size=v3(14,0.8,14), cframe=cf(0,0.9,0),
	color=COLORS.midGrey, material=Enum.Material.SmoothPlastic, reflectance=0.2})
makePart(coreZone, {name="CoreBase2", size=v3(10,0.8,10), cframe=cf(0,1.7,0),
	color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic})
makePart(coreZone, {name="CoreBase3", size=v3(7,0.8,7), cframe=cf(0,2.5,0),
	color=COLORS.midGrey, material=Enum.Material.SmoothPlastic})

-- Core column
makeCylinder(coreZone, {name="CoreColumn", size=v3(4, 18, 4), cframe=cf(0,12,0)*CFrame.Angles(0,0,math.pi/2),
	color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic})

-- Core orb
makeBall(coreZone, {name="CoreOrb", size=v3(8,8,8), cframe=cf(0,22,0),
	color=COLORS.cyan, neon=true})
addLight(makeBall(coreZone, {name="CoreOrbInner", size=v3(5,5,5),
	cframe=cf(0,22,0), color=COLORS.white, neon=true}), COLORS.cyan, 60, 8)

-- Orbiting rings (static, tilted)
for i, ang in ipairs({0, math.pi/3, 2*math.pi/3}) do
	local ringColor = i == 1 and COLORS.cyan or (i == 2 and COLORS.purple or COLORS.electricBlue)
	local tilt = CFrame.Angles(ang, ang/2, 0)
	for step = 0, 23 do
		local a = step/24 * math.pi*2
		local rv = tilt * Vector3.new(math.cos(a)*7, math.sin(a)*7, 0)
		makePart(coreZone, {name="OrbRing", size=v3(1.2,1.2,1.2),
			cframe=CFrame.new(rv.X, 22 + rv.Y, rv.Z),
			color=ringColor, neon=true})
	end
end

-- Core glow light
local glowPart = makePart(coreZone, {name="GlowSource", size=v3(0.5,0.5,0.5), cframe=cf(0,22,0), neon=true, color=COLORS.cyan})
addLight(glowPart, COLORS.cyan, 80, 6)

-- Energy beams radiating outward (4 diagonal beams)
for _, dir in ipairs({{1,1},{1,-1},{-1,1},{-1,-1}}) do
	local ex, ez = dir[1]*35, dir[2]*35
	neonStrip(coreZone, CFrame.new(ex/2, 15, ez/2) * CFrame.Angles(0, math.atan2(ex,ez), math.atan2(15, math.sqrt(ex*ex+ez*ez))),
		v3(0.5, 0.5, math.sqrt(ex*ex+225+ez*ez)), COLORS.electricBlue)
end

-- 8 decorative pillars around core
for i = 0, 7 do
	local a = i/8 * math.pi*2
	local px, pz = math.cos(a)*14, math.sin(a)*14
	local pillarColor = (i%2==0) and COLORS.cyan or COLORS.purple
	neonPillar(coreZone, px, pz, 6, pillarColor)
end

print("[MapBuilder] Spawn Plaza + Energy Core done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 2: LEADERBOARD DISTRICT  (North: 0, 0, -130)
-- ─────────────────────────────────────────────────────────────────────────────
local lbZone = zoneFolder("LeaderboardDistrict")
local LB = {cx=0, cz=-140}

-- Plaza floor
makePart(lbZone, {name="LBFloor", size=v3(90,1,70), cframe=cf(LB.cx, 0.5, LB.cz),
	color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic, reflectance=0.1})
neonStrip(lbZone, cf(LB.cx, 1.1, LB.cz-35), v3(90,0.4,0.4), COLORS.gold)
neonStrip(lbZone, cf(LB.cx, 1.1, LB.cz+35), v3(90,0.4,0.4), COLORS.gold)
neonStrip(lbZone, cf(LB.cx-45, 1.1, LB.cz), v3(0.4,0.4,70), COLORS.gold)
neonStrip(lbZone, cf(LB.cx+45, 1.1, LB.cz), v3(0.4,0.4,70), COLORS.gold)

-- Main leaderboard structure
local lbBacking = makePart(lbZone, {name="LBBacking", size=v3(50, 30, 2),
	cframe=cf(LB.cx, 16, LB.cz - 30),
	color=COLORS.darkBase, material=Enum.Material.SmoothPlastic})
-- Screen
local lbScreen = makePart(lbZone, {name="LBScreen", size=v3(46, 26, 0.5),
	cframe=cf(LB.cx, 16, LB.cz - 29.5),
	color=rgb(0, 20, 50), material=Enum.Material.Neon})
addLabel(lbScreen, "🏆 LEADERBOARD", COLORS.gold)
-- Neon border
neonStrip(lbZone, cf(LB.cx, 29.5, LB.cz-30), v3(50,0.6,0.6), COLORS.gold)
neonStrip(lbZone, cf(LB.cx, 2.5,  LB.cz-30), v3(50,0.6,0.6), COLORS.gold)
neonStrip(lbZone, cf(LB.cx-25, 16, LB.cz-30), v3(0.6,28,0.6), COLORS.gold)
neonStrip(lbZone, cf(LB.cx+25, 16, LB.cz-30), v3(0.6,28,0.6), COLORS.gold)

-- Support legs
for _, ox in ipairs({-20, 20}) do
	makePart(lbZone, {name="LBLeg", size=v3(3,16,3), cframe=cf(LB.cx+ox, 8, LB.cz-30),
		color=COLORS.midGrey, material=Enum.Material.SmoothPlastic})
end

-- Rank display panels (3 podiums)
for rank, data in ipairs({{-18, COLORS.midGrey, "#2"},{0, COLORS.gold, "#1"},{18, rgb(180,90,0), "#3"}}) do
	local ox, podColor, rankTxt = data[1], data[2], data[3]
	local podHeight = (rankTxt == "#1") and 6 or (rankTxt == "#2" and 5 or 4)
	makePart(lbZone, {name="Podium"..rank, size=v3(12, podHeight, 10),
		cframe=cf(LB.cx+ox, podHeight/2, LB.cz + 15),
		color=podColor, material=Enum.Material.SmoothPlastic, shadow=true})
	local rankSign = makePart(lbZone, {name="PodiumSign", size=v3(10,3,0.5),
		cframe=cf(LB.cx+ox, podHeight+1.5, LB.cz+10), color=COLORS.darkBase})
	addLabel(rankSign, rankTxt, podColor)
	neonStrip(lbZone, cf(LB.cx+ox, podHeight+0.6, LB.cz+15), v3(12.5,0.4,10.5), podColor)
	addLight(makePart(lbZone, {name="PodLight", size=v3(0.5,0.5,0.5),
		cframe=cf(LB.cx+ox, podHeight+2, LB.cz+15), color=podColor, neon=true}), podColor, 20, 3)
end

-- Holographic rank panels floating above screen
for i = 1, 5 do
	local panel = makePart(lbZone, {name="HoloRank"..i, size=v3(40,2,0.3),
		cframe=cf(LB.cx, 27 - i*3.5, LB.cz-28),
		color=rgb(0,30,80), material=Enum.Material.Neon})
end

-- Spotlights
for _, ox in ipairs({-30, 30}) do
	makePart(lbZone, {name="Spotlight", size=v3(3,2,3), cframe=cf(LB.cx+ox, 25, LB.cz+20),
		color=COLORS.darkBase})
	addSpot(makePart(lbZone, {name="SpotSource", size=v3(0.5,0.5,0.5),
		cframe=cf(LB.cx+ox, 25.5, LB.cz+20), color=COLORS.gold, neon=true}),
		COLORS.gold, 60, 5, 45)
end

print("[MapBuilder] Leaderboard District done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 3: SHOP DISTRICT  (NE: 130, 0, -80)
-- ─────────────────────────────────────────────────────────────────────────────
local shopZone = zoneFolder("ShopDistrict")
local SH = {cx=130, cz=-80}

-- District floor
makePart(shopZone, {name="ShopFloor", size=v3(100, 1, 80), cframe=cf(SH.cx, 0.5, SH.cz),
	color=COLORS.darkPlate, reflectance=0.12})
-- Neon border
neonStrip(shopZone, cf(SH.cx, 1.1, SH.cz-40), v3(100,0.4,0.4), COLORS.pink)
neonStrip(shopZone, cf(SH.cx, 1.1, SH.cz+40), v3(100,0.4,0.4), COLORS.pink)

-- Cosmetic Shop (left)
makeBuilding(shopZone, SH.cx-30, SH.cz-15, 34, 24, 18, COLORS.darkBase, COLORS.midGrey, "COSMETIC SHOP", COLORS.pink)

-- Upgrade Shop (right)
makeBuilding(shopZone, SH.cx+30, SH.cz-15, 34, 24, 18, COLORS.darkBase, COLORS.midGrey, "UPGRADE SHOP", COLORS.electricBlue)

-- Currency Exchange (center front)
makeBuilding(shopZone, SH.cx, SH.cz+20, 24, 18, 14, COLORS.darkBase, COLORS.midGrey, "CURRENCY EXCHANGE", COLORS.gold)

-- Decorative market stalls
for i = -1, 1 do
	local stall = makePart(shopZone, {name="Stall", size=v3(8,4,6),
		cframe=cf(SH.cx + i*28, 2.5, SH.cz+32), color=COLORS.darkBase})
	local roof = makePart(shopZone, {name="StallRoof", size=v3(9,0.5,7),
		cframe=cf(SH.cx + i*28, 4.75, SH.cz+32),
		color=(i==-1 and COLORS.pink or (i==0 and COLORS.cyan or COLORS.purple)),
		neon=false, material=Enum.Material.SmoothPlastic})
	neonStrip(shopZone, cf(SH.cx+i*28, 5.1, SH.cz+32), v3(9.2,0.3,0.3),
		(i==-1 and COLORS.pink or (i==0 and COLORS.cyan or COLORS.purple)))
end

-- Shop district entrance arch
makePart(shopZone, {name="ArchLeft", size=v3(3,10,3), cframe=cf(SH.cx-12, 5.5, SH.cz+40),
	color=COLORS.midGrey})
makePart(shopZone, {name="ArchRight", size=v3(3,10,3), cframe=cf(SH.cx+12, 5.5, SH.cz+40),
	color=COLORS.midGrey})
makePart(shopZone, {name="ArchTop", size=v3(24,2,3), cframe=cf(SH.cx, 11, SH.cz+40),
	color=COLORS.midGrey})
local archSign = makePart(shopZone, {name="ArchSign", size=v3(18,3,0.5),
	cframe=cf(SH.cx, 11, SH.cz+38.5), color=COLORS.darkBase})
addLabel(archSign, "SHOP DISTRICT", COLORS.pink)
neonStrip(shopZone, cf(SH.cx, 12.2, SH.cz+40), v3(24.5,0.5,3.5), COLORS.pink)

print("[MapBuilder] Shop District done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 4: MINI-GAME PORTAL AREA  (East: 150, 0, 30)
-- ─────────────────────────────────────────────────────────────────────────────
local portalZone = zoneFolder("MinigamePortals")
local MG = {cx=155, cz=40}

-- Plaza floor
makePart(portalZone, {name="PortalFloor", size=v3(110,1,90), cframe=cf(MG.cx, 0.5, MG.cz),
	color=COLORS.darkBase, reflectance=0.08})
-- Checkerboard neon grid
for gx = -4, 4 do
	for gz = -3, 3 do
		if (gx+gz)%2 == 0 then
			makePart(portalZone, {name="Grid", size=v3(12,0.1,12),
				cframe=cf(MG.cx+gx*13, 0.55, MG.cz+gz*13),
				color=rgb(0,20,50), material=Enum.Material.Neon})
		end
	end
end

-- Portal helper (portal frame + glowing disc)
local function makePortal(parent, cx, cz, color, label)
	-- Frame
	local frameH = 16
	makePart(parent, {name="PortalFrameL", size=v3(2,frameH,2), cframe=cf(cx-6, frameH/2, cz),
		color=COLORS.midGrey, material=Enum.Material.SmoothPlastic})
	makePart(parent, {name="PortalFrameR", size=v3(2,frameH,2), cframe=cf(cx+6, frameH/2, cz),
		color=COLORS.midGrey})
	makePart(parent, {name="PortalFrameT", size=v3(14,2,2), cframe=cf(cx, frameH, cz),
		color=COLORS.midGrey})
	-- Neon edging
	neonStrip(parent, cf(cx-6, frameH/2, cz-1.1), v3(0.4, frameH, 0.4), color)
	neonStrip(parent, cf(cx+6, frameH/2, cz-1.1), v3(0.4, frameH, 0.4), color)
	neonStrip(parent, cf(cx, frameH, cz-1.1), v3(14.5, 0.4, 0.4), color)
	-- Portal disc (glowing fill)
	makePart(parent, {name="PortalDisc", size=v3(10,14,0.4), cframe=cf(cx, frameH/2-1, cz-0.5),
		color=color, neon=true})
	-- Label
	local lbl = makePart(parent, {name="PortalLabel", size=v3(11,2.5,0.5), cframe=cf(cx, 1.5, cz-1.2),
		color=COLORS.darkBase})
	addLabel(lbl, label, color)
	-- Light
	addLight(makePart(parent, {name="PortalLight", size=v3(0.5,0.5,0.5),
		cframe=cf(cx, frameH/2, cz-2), color=color, neon=true}), color, 30, 5)
	-- Base pad
	makePart(parent, {name="PortalPad", size=v3(14,0.6,6), cframe=cf(cx, 0.8, cz+2),
		color=color, material=Enum.Material.Neon})
end

-- 4 Portals in a row
local portals = {
	{MG.cx-39, MG.cz-10, COLORS.cyan,          "COLOR DROP"},
	{MG.cx-13, MG.cz-10, COLORS.purple,         "ARENA BRAWL"},
	{MG.cx+13, MG.cz-10, COLORS.electricBlue,   "LASER JUMP"},
	{MG.cx+39, MG.cz-10, COLORS.pink,           "POLAR PUSH"},
}
for _, p in ipairs(portals) do
	makePortal(portalZone, p[1], p[2], p[3], p[4])
end

-- Arcade entrance arch
makePart(portalZone, {name="ArcadeArchL", size=v3(3,12,3), cframe=cf(MG.cx-18, 6, MG.cz+44),
	color=COLORS.midGrey})
makePart(portalZone, {name="ArcadeArchR", size=v3(3,12,3), cframe=cf(MG.cx+18, 6, MG.cz+44),
	color=COLORS.midGrey})
makePart(portalZone, {name="ArcadeArchT", size=v3(36,2.5,3), cframe=cf(MG.cx, 12.5, MG.cz+44),
	color=COLORS.midGrey})
local arcSign = makePart(portalZone, {name="ArcadeSign", size=v3(28,3.5,0.5),
	cframe=cf(MG.cx, 12.5, MG.cz+42.5), color=COLORS.darkBase})
addLabel(arcSign, "MINI-GAME ZONE", COLORS.cyan)
neonStrip(portalZone, cf(MG.cx, 14, MG.cz+44), v3(36.5,0.5,3.5), COLORS.cyan)

-- Decorative energy pillars around plaza
for i = 0, 5 do
	local a = i/6 * math.pi*2
	neonPillar(portalZone, MG.cx + math.cos(a)*48, MG.cz + math.sin(a)*40,
		8, (i%2==0 and COLORS.cyan or COLORS.purple))
end

print("[MapBuilder] Minigame Portal Area done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 5: PET EGG ZONE  (SE: 80, 0, 140)
-- ─────────────────────────────────────────────────────────────────────────────
local petZone = zoneFolder("PetEggZone")
local PE = {cx=85, cz=145}

-- Floor
makePart(petZone, {name="EggFloor", size=v3(90, 1, 80), cframe=cf(PE.cx, 0.5, PE.cz),
	color=COLORS.darkPlate, reflectance=0.1})
neonStrip(petZone, cf(PE.cx, 1.1, PE.cz-40), v3(90,0.4,0.4), COLORS.pink)
neonStrip(petZone, cf(PE.cx, 1.1, PE.cz+40), v3(90,0.4,0.4), COLORS.pink)
neonStrip(petZone, cf(PE.cx-45, 1.1, PE.cz), v3(0.4,0.4,80), COLORS.pink)
neonStrip(petZone, cf(PE.cx+45, 1.1, PE.cz), v3(0.4,0.4,80), COLORS.pink)

-- Egg machine helper
local function makeEgg(parent, cx, cz, eggColor, rarity, size)
	size = size or 1
	-- Machine body
	makePart(parent, {name="EggMachine", size=v3(8*size,10*size,8*size),
		cframe=cf(cx, 5*size, cz),
		color=COLORS.darkBase, material=Enum.Material.SmoothPlastic})
	-- Egg display (oval shape: stack of balls)
	local eggH = 12*size
	for i = 0, 7 do
		local t = i/7
		local r = math.sin(t * math.pi) * 3.5 * size
		makeBall(parent, {name="EggPart", size=v3(r*2, r*2.2, r*2),
			cframe=cf(cx, 10*size + i*1.4*size - 2, cz),
			color=eggColor, neon=true})
	end
	-- Rarity label
	local lbl = makePart(parent, {name="RarityLabel", size=v3(7*size, 2.5, 0.5),
		cframe=cf(cx, 2, cz - 4*size - 0.3), color=COLORS.darkBase})
	addLabel(lbl, rarity, eggColor)
	addLight(makePart(parent, {name="EggLight", size=v3(0.5,0.5,0.5),
		cframe=cf(cx, eggH, cz), color=eggColor, neon=true}), eggColor, 25, 4)
	-- Base pad
	makePart(parent, {name="EggPad", size=v3(9*size, 0.6, 9*size), cframe=cf(cx, 1, cz),
		color=eggColor, material=Enum.Material.Neon})
end

-- Eggs arranged in semicircle
makeEgg(petZone, PE.cx-30, PE.cz-15, COLORS.electricBlue,  "COMMON",    0.9)
makeEgg(petZone, PE.cx-12, PE.cz-20, COLORS.green,          "UNCOMMON",  1.0)
makeEgg(petZone, PE.cx+6,  PE.cz-22, COLORS.purple,         "RARE",      1.1)
makeEgg(petZone, PE.cx+24, PE.cz-18, COLORS.pink,           "EPIC",      1.25)
makeEgg(petZone, PE.cx+38, PE.cz-8,  COLORS.gold,           "LEGENDARY", 1.4)

-- Premium showcase egg (large, center-back)
makeEgg(petZone, PE.cx, PE.cz+20, COLORS.gold, "PREMIUM", 1.8)

-- Zone entrance
makePart(petZone, {name="PetArchL", size=v3(3,10,3), cframe=cf(PE.cx-12, 5, PE.cz-40),
	color=COLORS.midGrey})
makePart(petZone, {name="PetArchR", size=v3(3,10,3), cframe=cf(PE.cx+12, 5, PE.cz-40),
	color=COLORS.midGrey})
makePart(petZone, {name="PetArchT", size=v3(24,2,3), cframe=cf(PE.cx, 10.5, PE.cz-40),
	color=COLORS.midGrey})
local petSign = makePart(petZone, {name="PetSign", size=v3(20,3,0.5),
	cframe=cf(PE.cx, 10.5, PE.cz-38.5), color=COLORS.darkBase})
addLabel(petSign, "PET EGG ZONE", COLORS.pink)
neonStrip(petZone, cf(PE.cx, 11.7, PE.cz-40), v3(24.5,0.5,3.5), COLORS.pink)

print("[MapBuilder] Pet Egg Zone done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 6: QUEST HUB  (South: 0, 0, 150)
-- ─────────────────────────────────────────────────────────────────────────────
local questZone = zoneFolder("QuestHub")
local QH = {cx=0, cz=145}

-- Floor
makePart(questZone, {name="QuestFloor", size=v3(90,1,70), cframe=cf(QH.cx, 0.5, QH.cz),
	color=COLORS.darkPlate, reflectance=0.1})
neonStrip(questZone, cf(QH.cx, 1.1, QH.cz-35), v3(90,0.4,0.4), COLORS.green)
neonStrip(questZone, cf(QH.cx, 1.1, QH.cz+35), v3(90,0.4,0.4), COLORS.green)

-- Quest Hub building
makeBuilding(questZone, QH.cx, QH.cz+5, 50, 40, 20, COLORS.darkBase, COLORS.midGrey, "QUEST HUB", COLORS.green)

-- Mission boards (3 boards)
for i, data in ipairs({{-25, "DAILY QUESTS"},{0, "STORY QUESTS"},{25, "SPECIAL MISSIONS"}}) do
	local ox, lbl = data[1], data[2]
	local board = makePart(questZone, {name="MissionBoard", size=v3(16,12,1),
		cframe=cf(QH.cx+ox, 7, QH.cz-22), color=rgb(0,15,35)})
	addLabel(board, lbl, COLORS.green)
	makePart(questZone, {name="BoardStandL", size=v3(1.5,7,1.5),
		cframe=cf(QH.cx+ox-7, 3.5, QH.cz-22), color=COLORS.midGrey})
	makePart(questZone, {name="BoardStandR", size=v3(1.5,7,1.5),
		cframe=cf(QH.cx+ox+7, 3.5, QH.cz-22), color=COLORS.midGrey})
	neonStrip(questZone, cf(QH.cx+ox, 13.2, QH.cz-22), v3(16.5,0.4,0.4), COLORS.green)
end

-- Robot NPCs (placeholder humanoid rigs as parts)
local function makeRobotNPC(parent, cx, cz, color)
	-- Body
	makePart(parent, {name="NPC_Body", size=v3(4,5,2.5), cframe=cf(cx, 3.5, cz),
		color=COLORS.midGrey, material=Enum.Material.SmoothPlastic})
	-- Head
	makePart(parent, {name="NPC_Head", size=v3(3,3,3), cframe=cf(cx, 7.5, cz),
		color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic})
	-- Eyes
	neonStrip(parent, cf(cx-0.7, 7.8, cz-1.6), v3(0.8,0.5,0.3), color)
	neonStrip(parent, cf(cx+0.7, 7.8, cz-1.6), v3(0.8,0.5,0.3), color)
	-- Chest accent
	neonStrip(parent, cf(cx, 3.5, cz-1.3), v3(2,0.4,0.3), color)
	-- Legs
	makePart(parent, {name="NPC_LegL", size=v3(1.5,3,1.5), cframe=cf(cx-1.2, 0.5, cz),
		color=COLORS.midGrey})
	makePart(parent, {name="NPC_LegR", size=v3(1.5,3,1.5), cframe=cf(cx+1.2, 0.5, cz),
		color=COLORS.midGrey})
	-- Name billboard (simple sign)
	local nameSign = makePart(parent, {name="NPC_NameSign", size=v3(6,1.5,0.3),
		cframe=cf(cx, 10, cz), color=COLORS.darkBase})
	addLabel(nameSign, "QUEST BOT", color)
end

makeRobotNPC(questZone, QH.cx-28, QH.cz-25, COLORS.green)
makeRobotNPC(questZone, QH.cx, QH.cz-28, COLORS.cyan)
makeRobotNPC(questZone, QH.cx+28, QH.cz-25, COLORS.gold)

print("[MapBuilder] Quest Hub done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 7: UPGRADE LAB  (SW: -130, 0, 80)
-- ─────────────────────────────────────────────────────────────────────────────
local labZone = zoneFolder("UpgradeLab")
local UL = {cx=-135, cz=85}

-- Floor
makePart(labZone, {name="LabFloor", size=v3(90,1,80), cframe=cf(UL.cx, 0.5, UL.cz),
	color=COLORS.darkBase, reflectance=0.15})
neonStrip(labZone, cf(UL.cx, 1.1, UL.cz-40), v3(90,0.4,0.4), COLORS.electricBlue)
neonStrip(labZone, cf(UL.cx, 1.1, UL.cz+40), v3(90,0.4,0.4), COLORS.electricBlue)

-- Main lab building
makeBuilding(labZone, UL.cx, UL.cz, 60, 50, 24, COLORS.darkBase, rgb(20,20,50), "UPGRADE LAB", COLORS.electricBlue)

-- Energy reactor pillars (tall glowing towers)
for i, data in ipairs({{-22,-18,COLORS.cyan},{22,-18,COLORS.electricBlue},{-22,18,COLORS.purple},{22,18,COLORS.pink}}) do
	local ox, oz, color = data[1], data[2], data[3]
	-- Reactor column
	makeCylinder(labZone, {name="Reactor", size=v3(4,20,4),
		cframe=cf(UL.cx+ox, 11, UL.cz+oz)*CFrame.Angles(0,0,math.pi/2),
		color=COLORS.darkBase, material=Enum.Material.SmoothPlastic})
	-- Glow rings
	for rh = 2, 18, 4 do
		makeCylinder(labZone, {name="ReactorRing", size=v3(4.5,1,4.5),
			cframe=cf(UL.cx+ox, rh, UL.cz+oz)*CFrame.Angles(0,0,math.pi/2),
			color=color, neon=true})
	end
	addLight(makePart(labZone, {name="ReactorLight", size=v3(0.5,0.5,0.5),
		cframe=cf(UL.cx+ox, 21, UL.cz+oz), color=color, neon=true}), color, 30, 5)
end

-- Enhancement stations (5 workbenches)
for i = -2, 2 do
	local sx = UL.cx + i*18
	-- Table
	makePart(labZone, {name="Bench", size=v3(12,2,8), cframe=cf(sx, 2, UL.cz+28),
		color=COLORS.darkPlate, material=Enum.Material.SmoothPlastic})
	-- Hologram above table
	makePart(labZone, {name="BenchHolo", size=v3(10,0.2,6), cframe=cf(sx, 3.2, UL.cz+28),
		color=COLORS.electricBlue, neon=true})
	neonStrip(labZone, cf(sx, 2.2, UL.cz+32), v3(12.5,0.4,0.4), COLORS.electricBlue)
	-- Table legs
	for _, lx in ipairs({-4.5, 4.5}) do
		makePart(labZone, {name="BenchLeg", size=v3(1,2,1), cframe=cf(sx+lx, 1, UL.cz+28),
			color=COLORS.midGrey})
	end
end

print("[MapBuilder] Upgrade Lab done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 8: AFK REWARD PARK  (West: -155, 0, 0)
-- ─────────────────────────────────────────────────────────────────────────────
local afkZone = zoneFolder("AFKRewardPark")
local AFK = {cx=-158, cz=0}

-- Soft glowing park floor
makePart(afkZone, {name="ParkFloor", size=v3(90,1,80), cframe=cf(AFK.cx, 0.5, AFK.cz),
	color=rgb(5,10,20), reflectance=0.06})
-- Soft grid lines
for i = -4, 4 do
	neonStrip(afkZone, cf(AFK.cx, 0.6, AFK.cz+i*8), v3(90, 0.1, 0.1), rgb(0,30,60))
end

-- Neon robotic trees (glowing)
local function makeNeonTree(parent, cx, cz, color)
	-- Trunk
	makePart(parent, {name="TreeTrunk", size=v3(1.5,6,1.5),
		cframe=cf(cx, 3, cz), color=COLORS.midGrey})
	-- Trunk neon line
	neonStrip(parent, cf(cx, 3, cz-0.8), v3(0.3,6,0.3), color)
	-- Branches + glowing leaves
	for layer = 0, 2 do
		local r = 6 - layer*1.5
		local h = 7 + layer*2
		for j = 0, 5 do
			local a = j/6 * math.pi*2 + layer*0.5
			local bx = cx + math.cos(a)*r*0.7
			local bz = cz + math.sin(a)*r*0.7
			-- Branch
			neonStrip(parent, CFrame.new((cx+bx)/2, h-1, (cz+bz)/2) *
				CFrame.Angles(0, a, math.atan2(r*0.7, 2)), v3(0.5,0.5,math.sqrt((bx-cx)^2+4+(bz-cz)^2)), color)
			-- Leaf cluster
			makeBall(parent, {name="Leaf", size=v3(2.5,2.5,2.5),
				cframe=cf(bx, h, bz), color=color, neon=true})
		end
		-- Crown
		makeBall(parent, {name="Crown", size=v3(r*2, 3, r*2),
			cframe=cf(cx, h+1, cz), color=color, neon=true})
	end
	addLight(makePart(parent, {name="TreeGlow", size=v3(0.5,0.5,0.5),
		cframe=cf(cx, 12, cz), color=color, neon=true}), color, 20, 2)
end

-- Park trees
makeNeonTree(afkZone, AFK.cx-30, AFK.cz-25, COLORS.green)
makeNeonTree(afkZone, AFK.cx+20, AFK.cz-25, COLORS.cyan)
makeNeonTree(afkZone, AFK.cx-30, AFK.cz+25, COLORS.purple)
makeNeonTree(afkZone, AFK.cx+20, AFK.cz+25, COLORS.pink)
makeNeonTree(afkZone, AFK.cx-5,  AFK.cz,    COLORS.gold)

-- Energy crystals (spiky decorative gems)
local function makeCrystal(parent, cx, cz, color, h)
	local base = makePart(parent, {name="CrystalBase", size=v3(2,1,2), cframe=cf(cx, 0.5, cz), color=COLORS.darkPlate})
	for k = 0, 3 do
		local a = k/4 * math.pi*2
		local lean = 0.3
		local spike = makeWedge(parent, {
			name="CrystalSpike",
			size=v3(1.5, h or 5, 1.5),
			cframe=CFrame.new(cx+math.cos(a)*0.5, (h or 5)/2, cz+math.sin(a)*0.5) *
				CFrame.Angles(lean*math.cos(a+math.pi/2), a, lean*math.sin(a+math.pi/2)),
			color=color, neon=true,
		})
	end
	addLight(base, color, 12, 2)
end

for _, c in ipairs({{AFK.cx-18, AFK.cz-10, COLORS.cyan, 6},{AFK.cx+5, AFK.cz+15, COLORS.purple, 8},
	{AFK.cx-25, AFK.cz+5, COLORS.electricBlue, 5},{AFK.cx+15, AFK.cz-15, COLORS.pink, 7}}) do
	makeCrystal(afkZone, c[1], c[2], c[3], c[4])
end

-- AFK Reward station
makeBuilding(afkZone, AFK.cx, AFK.cz+25, 22,18,12, COLORS.darkBase, COLORS.midGrey, "AFK REWARDS", COLORS.green)

-- Passive reward terminal
makePart(afkZone, {name="RewardTerminal", size=v3(6,8,3), cframe=cf(AFK.cx, 5, AFK.cz-18),
	color=COLORS.darkBase, material=Enum.Material.SmoothPlastic})
local termScreen = makePart(afkZone, {name="TermScreen", size=v3(5,5,0.4),
	cframe=cf(AFK.cx, 5.5, AFK.cz-19.7), color=rgb(0,20,50), neon=true})
addLabel(termScreen, "IDLE BONUS\n+💎 /min", COLORS.green)
neonStrip(afkZone, cf(AFK.cx, 9.2, AFK.cz-18), v3(6.5,0.4,3.5), COLORS.green)

-- Park benches
for _, bdata in ipairs({{AFK.cx-15, AFK.cz+5},{AFK.cx+12, AFK.cz-8},{AFK.cx-8, AFK.cz+15}}) do
	local bx, bz = bdata[1], bdata[2]
	makePart(afkZone, {name="BenchSeat", size=v3(7,0.8,2), cframe=cf(bx, 1.6, bz),
		color=rgb(80,60,100), material=Enum.Material.SmoothPlastic})
	makePart(afkZone, {name="BenchBack", size=v3(7,2,0.5), cframe=cf(bx, 2.7, bz+1), color=rgb(60,45,80)})
	for _, lx in ipairs({-3, 3}) do
		makePart(afkZone, {name="BenchLeg", size=v3(0.8,1.8,2), cframe=cf(bx+lx, 0.9, bz), color=COLORS.midGrey})
	end
end

print("[MapBuilder] AFK Park done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 9: DAILY REWARD STATION  (Near spawn: -50, 0, -60)
-- ─────────────────────────────────────────────────────────────────────────────
local dailyZone = zoneFolder("DailyReward")
local DR = {cx=-55, cz=-70}

makePart(dailyZone, {name="DRFloor", size=v3(50,1,45), cframe=cf(DR.cx, 0.5, DR.cz),
	color=COLORS.darkPlate, reflectance=0.1})

-- Reward machine (large attractive terminal)
makePart(dailyZone, {name="DRMachine", size=v3(14,18,6), cframe=cf(DR.cx, 10, DR.cz-8),
	color=COLORS.darkBase})
local drScreen = makePart(dailyZone, {name="DRScreen", size=v3(12,14,0.5),
	cframe=cf(DR.cx, 10, DR.cz-11.3), color=rgb(0,15,40), neon=true})
addLabel(drScreen, "DAILY\nREWARD", COLORS.gold)
-- Gold border
neonStrip(dailyZone, cf(DR.cx, 17.5, DR.cz-8), v3(14.5,0.5,6.5), COLORS.gold)
neonStrip(dailyZone, cf(DR.cx, 1.5, DR.cz-8), v3(14.5,0.5,6.5), COLORS.gold)
neonStrip(dailyZone, cf(DR.cx-7, 10, DR.cz-8), v3(0.5,17,6.5), COLORS.gold)
neonStrip(dailyZone, cf(DR.cx+7, 10, DR.cz-8), v3(0.5,17,6.5), COLORS.gold)
-- Button
local btn = makePart(dailyZone, {name="DRButton", size=v3(5,1.5,2), cframe=cf(DR.cx, 3.5, DR.cz-11.5),
	color=COLORS.gold, neon=true})
addLight(btn, COLORS.gold, 15, 4)

-- Celebration star decorations
for i = 0, 7 do
	local a = i/8 * math.pi*2
	local sx = DR.cx + math.cos(a)*18
	local sz = DR.cz + math.sin(a)*15
	makeBall(dailyZone, {name="StarOrb", size=v3(2.5,2.5,2.5),
		cframe=cf(sx, 5 + math.sin(a)*3, sz), color=COLORS.gold, neon=true})
	addLight(makePart(dailyZone, {name="StarLight", size=v3(0.3,0.3,0.3),
		cframe=cf(sx, 5+math.sin(a)*3, sz), color=COLORS.gold, neon=true}), COLORS.gold, 12, 3)
end

print("[MapBuilder] Daily Reward done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 10: TRADING PLAZA  (NW: -120, 0, -90)
-- ─────────────────────────────────────────────────────────────────────────────
local tradeZone = zoneFolder("TradingPlaza")
local TP = {cx=-125, cz=-90}

makePart(tradeZone, {name="TradeFloor", size=v3(90,1,80), cframe=cf(TP.cx, 0.5, TP.cz),
	color=COLORS.darkPlate, reflectance=0.1})
neonStrip(tradeZone, cf(TP.cx, 1.1, TP.cz-40), v3(90,0.4,0.4), COLORS.orange)
neonStrip(tradeZone, cf(TP.cx, 1.1, TP.cz+40), v3(90,0.4,0.4), COLORS.orange)

-- Trading booths (6 booths in 2 rows)
for row = 0, 1 do
	for col = -2, 2 do
		if not (row==0 and col==0) then -- leave center open
			local bx = TP.cx + col * 22
			local bz = TP.cz + row * 25 - 12
			local boothColor = ({COLORS.cyan, COLORS.purple, COLORS.pink, COLORS.orange, COLORS.green})[((col+2+row*5)%5)+1]
			-- Booth canopy
			makePart(tradeZone, {name="BoothCanopy", size=v3(14,1,12), cframe=cf(bx, 7, bz),
				color=boothColor, material=Enum.Material.SmoothPlastic})
			neonStrip(tradeZone, cf(bx, 7.7, bz), v3(14.5,0.4,12.5), boothColor)
			-- Booth posts
			for _, ox in ipairs({-6,6}) do
				makePart(tradeZone, {name="BoothPost", size=v3(1,7,1), cframe=cf(bx+ox, 3.5, bz-4),
					color=COLORS.midGrey})
			end
			-- Counter
			makePart(tradeZone, {name="Counter", size=v3(12,2.5,2), cframe=cf(bx, 1.75, bz-3.5),
				color=COLORS.darkPlate})
			neonStrip(tradeZone, cf(bx, 3.2, bz-3.5), v3(12.5,0.3,0.3), boothColor)
		end
	end
end

-- Center fountain / meeting area
makePart(tradeZone, {name="FontainBase", size=v3(16,1,16), cframe=cf(TP.cx, 1, TP.cz),
	color=COLORS.midGrey, material=Enum.Material.SmoothPlastic})
makePart(tradeZone, {name="FontainWall", size=v3(12,2,12), cframe=cf(TP.cx, 2, TP.cz),
	color=COLORS.darkBase})
local waterRing = makeCylinder(tradeZone, {name="Water", size=v3(10,1,10),
	cframe=cf(TP.cx, 2.6, TP.cz)*CFrame.Angles(0,0,math.pi/2),
	color=COLORS.cyan, neon=true})
makeBall(tradeZone, {name="FountainOrb", size=v3(4,4,4), cframe=cf(TP.cx, 6, TP.cz),
	color=COLORS.electricBlue, neon=true})
addLight(makePart(tradeZone, {name="FountainGlow", size=v3(0.5,0.5,0.5),
	cframe=cf(TP.cx, 6, TP.cz), color=COLORS.cyan, neon=true}), COLORS.cyan, 30, 4)

-- Zone sign
local tradeArch = makeBuilding(tradeZone, TP.cx, TP.cz-38, 28, 4, 10, COLORS.darkBase, COLORS.midGrey, "TRADING PLAZA", COLORS.orange)

print("[MapBuilder] Trading Plaza done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 11: TELEPORT HUB  (Far North: 0, 0, -230)
-- ─────────────────────────────────────────────────────────────────────────────
local teleZone = zoneFolder("TeleportHub")
local TH = {cx=0, cz=-235}

makePart(teleZone, {name="TeleFloor", size=v3(80,1,60), cframe=cf(TH.cx, 0.5, TH.cz),
	color=COLORS.darkBase, reflectance=0.12})
ringParts(teleZone, TH.cx, TH.cz, 38, 2, 1.5, 0.5, COLORS.purple, Enum.Material.Neon)

-- Teleport terminals (4 fast-travel terminals)
local terminals = {
	{TH.cx-25, TH.cz, COLORS.cyan,    "WORLD 1"},
	{TH.cx-8,  TH.cz, COLORS.purple,  "WORLD 2"},
	{TH.cx+8,  TH.cz, COLORS.pink,    "WORLD 3"},
	{TH.cx+25, TH.cz, COLORS.gold,    "WORLD 4"},
}
for _, t in ipairs(terminals) do
	local tx, tz, tcolor, tlabel = t[1], t[2], t[3], t[4]
	makePart(teleZone, {name="Terminal", size=v3(8,12,4), cframe=cf(tx, 7, tz),
		color=COLORS.darkBase})
	local tScreen = makePart(teleZone, {name="TermScreen", size=v3(7,9,0.4),
		cframe=cf(tx, 7, tz-2.2), color=rgb(0,10,30), neon=true})
	addLabel(tScreen, tlabel, tcolor)
	neonStrip(teleZone, cf(tx, 13.2, tz), v3(8.5,0.5,4.5), tcolor)
	-- Base pad
	makePart(teleZone, {name="TermPad", size=v3(10,0.6,6), cframe=cf(tx, 1, tz+4),
		color=tcolor, neon=true})
	addLight(makePart(teleZone, {name="TermLight", size=v3(0.5,0.5,0.5),
		cframe=cf(tx, 14, tz), color=tcolor, neon=true}), tcolor, 20, 4)
end

-- Hub sign
local hubSign = makePart(teleZone, {name="HubSign", size=v3(40,5,1),
	cframe=cf(TH.cx, 4, TH.cz+28), color=COLORS.darkBase})
addLabel(hubSign, "TELEPORT HUB", COLORS.purple)
makePart(teleZone, {name="HubSignStandL", size=v3(1.5,4,1.5), cframe=cf(TH.cx-18, 2, TH.cz+28), color=COLORS.midGrey})
makePart(teleZone, {name="HubSignStandR", size=v3(1.5,4,1.5), cframe=cf(TH.cx+18, 2, TH.cz+28), color=COLORS.midGrey})
neonStrip(teleZone, cf(TH.cx, 6.7, TH.cz+28), v3(40.5,0.5,0.5), COLORS.purple)

print("[MapBuilder] Teleport Hub done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ZONE 12: FUTURE EXPANSION GATES  (Perimeter)
-- ─────────────────────────────────────────────────────────────────────────────
local gateZone = zoneFolder("ExpansionGates")

local function makeExpansionGate(parent, cx, cz, rotY, label)
	-- Massive gate doors
	local rot = CFrame.Angles(0, rotY, 0)
	local doorColor = COLORS.darkBase
	-- Left door
	makePart(parent, {name="GateDoorL", size=v3(20,30,3),
		cframe=CFrame.new(cx-12, 15, cz) * rot, color=doorColor,
		material=Enum.Material.SmoothPlastic, shadow=true})
	-- Right door
	makePart(parent, {name="GateDoorR", size=v3(20,30,3),
		cframe=CFrame.new(cx+12, 15, cz) * rot, color=doorColor, shadow=true})
	-- Gate frame
	makePart(parent, {name="GateFrame", size=v3(46,4,4),
		cframe=CFrame.new(cx, 31, cz) * rot, color=COLORS.midGrey})
	makePart(parent, {name="GateFrameL", size=v3(3,32,4),
		cframe=CFrame.new(cx-23, 16, cz) * rot, color=COLORS.midGrey})
	makePart(parent, {name="GateFrameR", size=v3(3,32,4),
		cframe=CFrame.new(cx+23, 16, cz) * rot, color=COLORS.midGrey})
	-- Neon edges
	neonStrip(parent, CFrame.new(cx, 33.5, cz) * rot, v3(46.5,0.5,0.5), COLORS.gold)
	neonStrip(parent, CFrame.new(cx-23, 16, cz) * rot, v3(0.5,32,0.5), COLORS.gold)
	neonStrip(parent, CFrame.new(cx+23, 16, cz) * rot, v3(0.5,32,0.5), COLORS.gold)
	-- Lock icon (neon X)
	neonStrip(parent, CFrame.new(cx, 16, cz-1.7) * rot * CFrame.Angles(0,0,math.pi/4), v3(0.8,20,0.8), rgb(255,50,50))
	neonStrip(parent, CFrame.new(cx, 16, cz-1.7) * rot * CFrame.Angles(0,0,-math.pi/4), v3(0.8,20,0.8), rgb(255,50,50))
	-- Coming soon sign
	local sign = makePart(parent, {name="GateSign", size=v3(24,4,1),
		cframe=CFrame.new(cx, 6, cz-2.2) * rot, color=COLORS.darkBase})
	addLabel(sign, "COMING SOON", COLORS.gold)
	addLight(makePart(parent, {name="GateLight", size=v3(0.5,0.5,0.5),
		cframe=CFrame.new(cx, 33, cz) * rot, color=COLORS.gold, neon=true}), COLORS.gold, 40, 3)
end

-- 4 expansion gates at map edges
makeExpansionGate(gateZone,   0, -290, 0,              "NORTH WORLD")
makeExpansionGate(gateZone, 290,    0, math.pi/2,      "EAST WORLD")
makeExpansionGate(gateZone,   0,  290, math.pi,        "SOUTH WORLD")
makeExpansionGate(gateZone, -290,   0, -math.pi/2,     "WEST WORLD")

print("[MapBuilder] Expansion Gates done")

-- ─────────────────────────────────────────────────────────────────────────────
-- PATHWAYS connecting all zones to spawn
-- ─────────────────────────────────────────────────────────────────────────────
local pathZone = zoneFolder("Pathways")

-- Spoke paths from spawn plaza edge (radius ~60) to each district
local spokes = {
	{0,  60,   0,  95,   14},  -- N to Leaderboard
	{42, 42,  95,  -50,  14},  -- NE to Shop
	{60,  0, 100,  40,   14},  -- E to Portals
	{42, -42, 60,  120,  14},  -- SE to Pet Eggs
	{0,  -60,  0,  110,  14},  -- S to Quest Hub
	{-42,-42,-100, 60,   14},  -- SW to Upgrade Lab
	{-60,  0, -120, 0,   14},  -- W to AFK Park
	{-42, 42, -90, -55,  14},  -- NW to Trading Plaza
}
for _, s in ipairs(spokes) do
	makePath(pathZone, s[1], s[2], s[3], s[4], s[5], COLORS.darkPlate)
end

-- Secondary path to Teleport Hub (northward extension)
makePath(pathZone, 0, -95, 0, -205, 14, COLORS.darkPlate)

-- Outer ring road connecting all districts
local ringPts = {
	{0, -100}, {95, -50}, {120, 40}, {60, 120},
	{0, 110}, {-100, 60}, {-120, 0}, {-90, -55}, {-40, -100}, {0,-100}
}
for i = 1, #ringPts-1 do
	local p1, p2 = ringPts[i], ringPts[i+1]
	makePath(pathZone, p1[1], p1[2], p2[1], p2[2], 10, rgb(20,15,40))
end

print("[MapBuilder] Pathways done")

-- ─────────────────────────────────────────────────────────────────────────────
-- ENVIRONMENT DETAILS: Holographic ads, ambient lights, crystals
-- ─────────────────────────────────────────────────────────────────────────────
local envZone = zoneFolder("EnvironmentDetails")

-- Holographic advertisement boards (floating billboards)
local adPositions = {
	{70, 18, -70,  0,         COLORS.pink,   "UPGRADE NOW!"},
	{-70,18,  -70, math.pi/4, COLORS.cyan,   "NEW PETS!"},
	{70, 18,  70,  0,         COLORS.gold,   "DAILY BONUS!"},
	{-70,18,  70,  0,         COLORS.purple, "TRADE HERE!"},
}
for _, ad in ipairs(adPositions) do
	local ax, ay, az, arot, acolor, atext = ad[1],ad[2],ad[3],ad[4],ad[5],ad[6]
	-- Pole
	makePart(envZone, {name="AdPole", size=v3(1,ay,1), cframe=cf(ax, ay/2, az), color=COLORS.midGrey})
	-- Board
	local board = makePart(envZone, {name="AdBoard", size=v3(18,8,0.5),
		cframe=CFrame.new(ax, ay+4, az) * CFrame.Angles(0, arot, 0), color=rgb(0,10,30)})
	addLabel(board, atext, acolor)
	neonStrip(envZone, CFrame.new(ax, ay+8.3, az), v3(18.5,0.5,0.5), acolor)
	neonStrip(envZone, CFrame.new(ax, ay-0.3, az), v3(18.5,0.5,0.5), acolor)
	addLight(makePart(envZone, {name="AdLight", size=v3(0.5,0.5,0.5),
		cframe=cf(ax, ay+9, az), color=acolor, neon=true}), acolor, 20, 3)
end

-- Ambient light orbs scattered across map
local ambientOrbs = {
	{40,-30, COLORS.cyan}, {-30, 50, COLORS.purple}, {80, 80, COLORS.pink},
	{-80,-80, COLORS.electricBlue}, {-50, -50, COLORS.green}, {60, 60, COLORS.gold},
}
for _, o in ipairs(ambientOrbs) do
	local ox, oz, oc = o[1], o[2], o[3]
	local orb = makeBall(envZone, {name="AmbientOrb", size=v3(2,2,2), cframe=cf(ox, 8, oz), color=oc, neon=true})
	addLight(orb, oc, 25, 2)
end

-- Ground energy crystals decorating empty spaces
local crystalSpots = {
	{35, 90}, {-35, 95}, {90, -30}, {-90, -30},
	{50, -90}, {-50, -85}, {100, 100}, {-100, 100},
}
for _, cs in ipairs(crystalSpots) do
	local ccolor = ({COLORS.cyan, COLORS.purple, COLORS.pink, COLORS.electricBlue, COLORS.green, COLORS.gold})[math.random(1,6)]
	makeCrystal(envZone, cs[1], cs[2], ccolor, math.random(4,9))
end

-- Animated neon sign pillars along main paths
for i = 0, 7 do
	local a = i/8 * math.pi*2
	local pr = 85
	local px, pz = math.cos(a)*pr, math.sin(a)*pr
	local pcolor = ({COLORS.cyan, COLORS.purple, COLORS.pink, COLORS.electricBlue,
		COLORS.green, COLORS.gold, COLORS.orange, COLORS.white})[i+1]
	neonPillar(envZone, px, pz, 10, pcolor)
end

print("[MapBuilder] Environment details done")

-- ─────────────────────────────────────────────────────────────────────────────
-- SPAWN LOCATION (official)
-- ─────────────────────────────────────────────────────────────────────────────
-- Already created in SpawnPlaza zone above

-- Boundary walls (low perimeter to guide players)
local boundZone = zoneFolder("Boundary")
for i = 1, 4 do
	local a = (i-1)/4 * math.pi*2 + math.pi/4
	local bx, bz = math.cos(a)*310, math.sin(a)*310
	makePart(boundZone, {name="BoundWall", size=v3(440,8,3),
		cframe=CFrame.new(bx, 4, bz) * CFrame.Angles(0, a+math.pi/2, 0),
		color=COLORS.darkBase, material=Enum.Material.SmoothPlastic})
	neonStrip(boundZone, CFrame.new(bx, 8.5, bz) * CFrame.Angles(0, a+math.pi/2, 0),
		v3(440, 0.5, 0.5), COLORS.electricBlue)
end

print("===========================================")
print("[MapBuilder] NEON ROBOT WORLD BUILD COMPLETE")
print("===========================================")
print("Zones built:")
print("  ✓ Central Spawn Plaza + Energy Core")
print("  ✓ Leaderboard District")
print("  ✓ Shop District (3 shops)")
print("  ✓ Minigame Portal Area (4 portals)")
print("  ✓ Pet Egg Zone (5+1 eggs)")
print("  ✓ Quest Hub (3 NPCs + boards)")
print("  ✓ Upgrade Lab (4 reactors)")
print("  ✓ AFK Reward Park (5 trees)")
print("  ✓ Daily Reward Station")
print("  ✓ Trading Plaza (6 booths)")
print("  ✓ Teleport Hub (4 terminals)")
print("  ✓ Future Expansion Gates (x4)")
print("  ✓ Pathways (spokes + ring road)")
print("  ✓ Environment Details")
print("  ✓ Boundary Walls")
