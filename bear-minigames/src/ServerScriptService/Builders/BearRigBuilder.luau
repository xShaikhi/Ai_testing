local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BearRigBuilder = {}

local FUR = Color3.fromRGB(82, 56, 36)
local FUR_DARK = Color3.fromRGB(60, 40, 26)
local SNOUT = Color3.fromRGB(150, 110, 75)

local function bearPart(name, size, cframe, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color or FUR
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function weld(rootPart, otherPart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = rootPart
	w.Part1 = otherPart
	w.Parent = rootPart
end

function BearRigBuilder.build(npcFolder)
	local existing = npcFolder:FindFirstChild("Bear")
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "Bear"

	local legHeight = 3.5
	local torsoHeight = 4
	local base = CFrame.new(0, 0, 0)

	local root = bearPart(
		"HumanoidRootPart",
		Vector3.new(4, 2, 2.5),
		base * CFrame.new(0, legHeight + torsoHeight / 2, 0),
		FUR,
		model
	)
	root.Transparency = 1
	root.CanCollide = true

	local torso = bearPart(
		"Torso",
		Vector3.new(5.5, torsoHeight, 3.5),
		base * CFrame.new(0, legHeight + torsoHeight / 2, 0),
		FUR,
		model
	)

	local belly = bearPart(
		"Belly",
		Vector3.new(3.2, 2.6, 0.6),
		base * CFrame.new(0, legHeight + torsoHeight / 2 - 0.4, -1.6),
		SNOUT,
		model
	)

	local headY = legHeight + torsoHeight + 1.25
	local head = bearPart("Head", Vector3.new(3.2, 2.5, 2.8), base * CFrame.new(0, headY, -0.4), FUR, model)
	local snout = bearPart("Snout", Vector3.new(1.6, 1.1, 1.2), base * CFrame.new(0, headY - 0.5, -2), SNOUT, model)
	local earL = bearPart("Ear_L", Vector3.new(0.9, 0.9, 0.6), base * CFrame.new(-1.3, headY + 1.5, -0.4), FUR_DARK, model)
	local earR = bearPart("Ear_R", Vector3.new(0.9, 0.9, 0.6), base * CFrame.new(1.3, headY + 1.5, -0.4), FUR_DARK, model)

	local eyeL = bearPart("Eye_L", Vector3.new(0.45, 0.45, 0.2), base * CFrame.new(-0.7, headY + 0.3, -1.85), Color3.fromRGB(20, 20, 20), model)
	eyeL.Material = Enum.Material.Neon
	local eyeR = bearPart("Eye_R", Vector3.new(0.45, 0.45, 0.2), base * CFrame.new(0.7, headY + 0.3, -1.85), Color3.fromRGB(20, 20, 20), model)
	eyeR.Material = Enum.Material.Neon

	local armY = legHeight + torsoHeight / 2 + 0.3
	local armL = bearPart("Arm_L", Vector3.new(1.6, 4, 1.8), base * CFrame.new(-3.5, armY, 0), FUR, model)
	local armR = bearPart("Arm_R", Vector3.new(1.6, 4, 1.8), base * CFrame.new(3.5, armY, 0), FUR, model)
	local pawL = bearPart("Paw_L", Vector3.new(1.8, 1, 2), base * CFrame.new(-3.5, armY - 2.4, -0.2), FUR_DARK, model)
	local pawR = bearPart("Paw_R", Vector3.new(1.8, 1, 2), base * CFrame.new(3.5, armY - 2.4, -0.2), FUR_DARK, model)

	local legL = bearPart("Leg_L", Vector3.new(1.9, legHeight, 2), base * CFrame.new(-1.4, legHeight / 2, 0.2), FUR, model)
	local legR = bearPart("Leg_R", Vector3.new(1.9, legHeight, 2), base * CFrame.new(1.4, legHeight / 2, 0.2), FUR, model)
	local footL = bearPart("Foot_L", Vector3.new(2, 1, 2.6), base * CFrame.new(-1.4, 0.5, -0.2), FUR_DARK, model)
	local footR = bearPart("Foot_R", Vector3.new(2, 1, 2.6), base * CFrame.new(1.4, 0.5, -0.2), FUR_DARK, model)

	for _, p in ipairs({ torso, belly, head, snout, earL, earR, eyeL, eyeR, armL, armR, pawL, pawR, legL, legR, footL, footR }) do
		weld(root, p)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = 100000
	humanoid.Health = 100000
	humanoid.WalkSpeed = Config.Bear.WalkSpeed
	humanoid.HipHeight = legHeight + torsoHeight / 2 - 1
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	local roar = Instance.new("Sound")
	roar.Name = "Roar"
	roar.SoundId = "rbxassetid://9125402735"
	roar.Volume = 1
	roar.RollOffMaxDistance = 120
	roar.Parent = root

	local swipe = Instance.new("Sound")
	swipe.Name = "Swipe"
	swipe.SoundId = "rbxassetid://9114065998"
	swipe.Volume = 0.8
	swipe.Parent = root

	model.PrimaryPart = root
	model.Parent = npcFolder
	return model
end

return BearRigBuilder
