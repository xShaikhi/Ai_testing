local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = require(script.Parent.Shared)

local PolarPushModels = {}

local OPTIONS = {
	modelFolderName = "PolarBearModels",
	modelName = "PlayerBear",
	workspaceModelName = "PlayerBear",
	modelAliases = {
		"PlayerBear",
		"PolarBear_Roblox",
		"PolarBear",
		"polar-bears",
		"Polarbear_hd",
		"PreviewBear",
	},
	workspaceFallbackName = "PreviewBear",

	primaryPartName = "Body",
	saddlePointName = "SaddlePoint",

	xOffset = 0,
	yOffset = 0.65,
	zOffset = 0.3,
	modelPitch = 0,
	modelYaw = 180,
	modelRoll = 0,
	modelTargetSize = 7.0,

	-- saddleTargetOffset.Y lowers the bear vs the rider so the rider sits ON the
	-- saddle instead of sinking into the body. playerHipHeightAdd then lifts the
	-- whole rider+bear assembly so the bear's paws rest on the ice floor.
	saddleTargetOffset = CFrame.new(0, -0.9, -0.1),

	playerWalkSpeed = 13,
	playerHipHeightAdd = 3.0,
	-- Practice NPCs use a custom rig that stands a touch lower than a real avatar,
	-- so their mounted bears need a little extra lift (players are unaffected).
	botHipHeightExtra = 1.2,

	riderFootSideOffset = 4.35,
	riderFootHeightOffset = -0.42,
	riderFootForwardOffset = 0.55,
	riderHipSideShift = 0.72,
	riderHipLift = -0.04,
}

local BEAR_PALETTE = {
	body = Color3.fromRGB(245, 253, 255),
	belly = Color3.fromRGB(218, 244, 255),
	shadow = Color3.fromRGB(190, 226, 238),
	paw = Color3.fromRGB(38, 54, 66),
	nose = Color3.fromRGB(16, 20, 26),
	eye = Color3.fromRGB(8, 12, 18),
	earInner = Color3.fromRGB(170, 220, 235),
	neonCyan = Color3.fromRGB(55, 225, 255),
}

local function firstBasePart(instance)
	if instance:IsA("BasePart") then
		return instance
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local function largestBasePart(instance)
	local bestPart = nil
	local bestVolume = -math.huge
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local size = descendant.Size
			local volume = size.X * size.Y * size.Z
			if volume > bestVolume then
				bestPart = descendant
				bestVolume = volume
			end
		end
	end
	return bestPart
end

local function createPart(parent, name, size, cframe, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function createMotor(name, part0, part1, c0, c1)
	local existing = part0:FindFirstChild(name)
	if existing and existing:IsA("Motor6D") then
		return existing
	end

	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1 or CFrame.identity
	motor.Parent = part0
	return motor
end

local function createWeld(name, part0, part1)
	local existing = part0:FindFirstChild(name)
	if existing and existing:IsA("WeldConstraint") then
		return existing
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = name
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
	return weld
end

local function makeLimb(model, body, sideName, sideSign, zName, zOffset)
	local upper = createPart(model, sideName .. zName .. "UpperLeg", Vector3.new(1.05, 2.25, 1.15), body.CFrame * CFrame.new(sideSign * 2.15, -2.05, zOffset), Color3.fromRGB(238, 247, 248), Enum.Material.SmoothPlastic)
	local lower = createPart(model, sideName .. zName .. "LowerLeg", Vector3.new(0.95, 1.95, 1.05), body.CFrame * CFrame.new(sideSign * 2.15, -3.95, zOffset + 0.05), Color3.fromRGB(230, 242, 244), Enum.Material.SmoothPlastic)
	local paw = createPart(model, sideName .. zName .. "Paw", Vector3.new(1.45, 0.58, 2.05), body.CFrame * CFrame.new(sideSign * 2.15, -5.1, zOffset - 0.38), Color3.fromRGB(218, 230, 232), Enum.Material.SmoothPlastic)

	createMotor("BodyTo" .. sideName .. zName .. "UpperLeg", body, upper, CFrame.new(sideSign * 2.15, -1.1, zOffset), CFrame.new(0, 1.08, 0))
	createMotor(sideName .. zName .. "Knee", upper, lower, CFrame.new(0, -1.05, 0), CFrame.new(0, 0.85, 0))
	createMotor(sideName .. zName .. "Ankle", lower, paw, CFrame.new(0, -0.85, -0.1), CFrame.new(0, 0.12, 0.5))
end

local function createProceduralBearTemplate()
	local folder = ServerStorage:FindFirstChild(OPTIONS.modelFolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = OPTIONS.modelFolderName
		folder.Parent = ServerStorage
	end

	local existing = folder:FindFirstChild(OPTIONS.modelName)
	if existing then
		return existing
	end

	local model = Instance.new("Model")
	model.Name = OPTIONS.modelName
	model:SetAttribute("GeneratedRig", true)
	model:SetAttribute("RigRoot", "Body")
	model.Parent = folder

	local body = createPart(model, "Body", Vector3.new(5.35, 3.1, 8.4), CFrame.new(0, 0, 0), Color3.fromRGB(248, 253, 253), Enum.Material.SmoothPlastic)
	body.Anchored = true
	body:SetAttribute("RideCenter", true)
	model.PrimaryPart = body

	local saddle = Instance.new("Attachment")
	saddle.Name = OPTIONS.saddlePointName
	saddle.CFrame = CFrame.new(0, 1.95, 0.15)
	saddle.Parent = body

	local neck = createPart(model, "Neck", Vector3.new(2.5, 2.1, 1.5), body.CFrame * CFrame.new(0, 0.45, -4.55), Color3.fromRGB(246, 252, 252), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local head = createPart(model, "Head", Vector3.new(3.25, 2.55, 3.1), body.CFrame * CFrame.new(0, 0.85, -5.85), Color3.fromRGB(250, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local snout = createPart(model, "Snout", Vector3.new(2.1, 1.15, 1.6), body.CFrame * CFrame.new(0, 0.45, -7.25), Color3.fromRGB(235, 242, 243), Enum.Material.SmoothPlastic)
	local nose = createPart(model, "Nose", Vector3.new(1.05, 0.45, 0.3), body.CFrame * CFrame.new(0, 0.56, -8.18), Color3.fromRGB(25, 28, 32), Enum.Material.SmoothPlastic)
	local leftEar = createPart(model, "LeftEar", Vector3.new(0.85, 0.85, 0.7), body.CFrame * CFrame.new(-1.15, 1.95, -5.95), Color3.fromRGB(242, 249, 249), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local rightEar = createPart(model, "RightEar", Vector3.new(0.85, 0.85, 0.7), body.CFrame * CFrame.new(1.15, 1.95, -5.95), Color3.fromRGB(242, 249, 249), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local leftEye = createPart(model, "LeftEye", Vector3.new(0.28, 0.28, 0.2), body.CFrame * CFrame.new(-0.72, 1.1, -7.22), Color3.fromRGB(15, 18, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local rightEye = createPart(model, "RightEye", Vector3.new(0.28, 0.28, 0.2), body.CFrame * CFrame.new(0.72, 1.1, -7.22), Color3.fromRGB(15, 18, 22), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local rump = createPart(model, "RumpMass", Vector3.new(5.0, 2.7, 2.6), body.CFrame * CFrame.new(0, -0.05, 3.55), Color3.fromRGB(240, 249, 250), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local tail = createPart(model, "Tail", Vector3.new(0.8, 0.7, 0.75), body.CFrame * CFrame.new(0, 0.1, 4.65), Color3.fromRGB(235, 246, 247), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

	createMotor("BodyToNeck", body, neck, CFrame.new(0, 0.45, -3.9), CFrame.new(0, 0, 0.55))
	createMotor("NeckToHead", neck, head, CFrame.new(0, 0.25, -0.85), CFrame.new(0, 0, 0.95))
	createWeld("HeadToSnout", head, snout)
	createWeld("SnoutToNose", snout, nose)
	createWeld("HeadToLeftEar", head, leftEar)
	createWeld("HeadToRightEar", head, rightEar)
	createWeld("HeadToLeftEye", head, leftEye)
	createWeld("HeadToRightEye", head, rightEye)
	createMotor("BodyToRumpMass", body, rump, CFrame.new(0, -0.05, 3.05), CFrame.new(0, 0, -0.4))
	createWeld("RumpToTail", rump, tail)

	makeLimb(model, body, "Left", -1, "Front", -2.75)
	makeLimb(model, body, "Right", 1, "Front", -2.75)
	makeLimb(model, body, "Left", -1, "Back", 2.75)
	makeLimb(model, body, "Right", 1, "Back", 2.75)

	local skeleton = Instance.new("Folder")
	skeleton.Name = "Skeleton"
	skeleton.Parent = model

	for _, data in ipairs({
		{ "Spine", Vector3.new(0, 0, 0) },
		{ "Saddle", Vector3.new(0, 1.95, 0.15) },
		{ "HeadJoint", Vector3.new(0, 0.5, -4.5) },
		{ "LeftFrontShoulder", Vector3.new(-2.15, -1.1, -2.75) },
		{ "RightFrontShoulder", Vector3.new(2.15, -1.1, -2.75) },
		{ "LeftBackHip", Vector3.new(-2.15, -1.1, 2.75) },
		{ "RightBackHip", Vector3.new(2.15, -1.1, 2.75) },
	}) do
		local attachment = Instance.new("Attachment")
		attachment.Name = data[1]
		attachment.Position = data[2]
		attachment.Parent = body
	end

	local animationController = Instance.new("AnimationController")
	animationController.Name = "BearAnimationController"
	animationController.Parent = model

	local animator = Instance.new("Animator")
	animator.Name = "Animator"
	animator.Parent = animationController

	local scriptsFolder = Instance.new("Folder")
	scriptsFolder.Name = "ModelScripts"
	scriptsFolder.Parent = model

	local runtimeNote = Instance.new("StringValue")
	runtimeNote.Name = "BearRigRuntime"
	runtimeNote.Value = "Animated by ServerScriptService.Minigames.PolarPushModels. Body is the ride center and all major limbs use Motor6D skeleton joints."
	runtimeNote.Parent = scriptsFolder

	return model
end

local function normalizeName(name)
	return string.lower((name or ""):gsub("[^%w]", ""))
end

local function isBearName(name)
	local normalized = normalizeName(name)
	if normalized:find("bear") or normalized:find("polarbear") then
		return true
	end

	for _, alias in ipairs(OPTIONS.modelAliases) do
		if normalized == normalizeName(alias) then
			return true
		end
	end

	return false
end

local function resolveBearTemplate(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") or instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Folder") then
		local direct = instance:FindFirstChild(OPTIONS.modelName)
		local resolved = resolveBearTemplate(direct)
		if resolved then
			return resolved
		end

		for _, alias in ipairs(OPTIONS.modelAliases) do
			local aliased = instance:FindFirstChild(alias)
			resolved = resolveBearTemplate(aliased)
			if resolved then
				return resolved
			end
		end

		for _, child in ipairs(instance:GetChildren()) do
			if isBearName(child.Name) then
				resolved = resolveBearTemplate(child)
				if resolved then
					return resolved
				end
			end
		end

		local nestedPart = firstBasePart(instance)
		if nestedPart then
			return nestedPart:FindFirstAncestorOfClass("Model") or nestedPart
		end
	end

	return nil
end

local function findBearIn(container)
	if not container then
		return nil
	end

	for _, alias in ipairs(OPTIONS.modelAliases) do
		local found = container:FindFirstChild(alias, true)
		local resolved = resolveBearTemplate(found)
		if resolved then
			return resolved
		end
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if isBearName(descendant.Name) then
			local resolved = resolveBearTemplate(descendant)
			if resolved then
				return resolved
			end
		end
	end

	return resolveBearTemplate(container)
end

local function findWorkspaceBearTemplate()
	for _, alias in ipairs(OPTIONS.modelAliases) do
		local found = workspace:FindFirstChild(alias, true)
		local resolved = resolveBearTemplate(found)
		if resolved and not resolved:FindFirstAncestor("PolarPush") and resolved.Name ~= "MountedPolarBear" then
			return resolved
		end
	end

	for _, descendant in ipairs(workspace:GetDescendants()) do
		if isBearName(descendant.Name) and not descendant:FindFirstAncestor("PolarPush") and descendant.Name ~= "MountedPolarBear" then
			local resolved = resolveBearTemplate(descendant)
			if resolved then
				return resolved
			end
		end
	end

	return nil
end

local function findBearTemplate()
	local workspaceExactBear = workspace:FindFirstChild(OPTIONS.workspaceModelName)
	if workspaceExactBear then
		return workspaceExactBear
	end

	local serverFolder = ServerStorage:FindFirstChild(OPTIONS.modelFolderName)
	local serverBear = findBearIn(serverFolder)
	if serverBear then
		return serverBear
	end

	local replicatedFolder = ReplicatedStorage:FindFirstChild(OPTIONS.modelFolderName)
	local replicatedBear = findBearIn(replicatedFolder)
	if replicatedBear then
		return replicatedBear
	end

	local storageBear = findBearIn(ServerStorage)
	if storageBear then
		return storageBear
	end

	local replicatedStorageBear = findBearIn(ReplicatedStorage)
	if replicatedStorageBear then
		return replicatedStorageBear
	end

	local workspaceBear = workspace:FindFirstChild(OPTIONS.workspaceFallbackName)
	if workspaceBear then
		return workspaceBear
	end

	local workspaceAliasedBear = findWorkspaceBearTemplate()
	if workspaceAliasedBear then
		return workspaceAliasedBear
	end

	return createProceduralBearTemplate()
end

local function partNamed(model, name)
	local instance = model:FindFirstChild(name, true)
	if instance and instance:IsA("BasePart") then
		return instance
	end
	return nil
end

local function ensureBodyPart(model)
	local body = partNamed(model, OPTIONS.primaryPartName)
	if body then
		model.PrimaryPart = body
		return body
	end

	body = model.PrimaryPart or largestBasePart(model) or firstBasePart(model)
	if body then
		body.Name = OPTIONS.primaryPartName
		model.PrimaryPart = body
	end
	return body
end

local function motorFromCurrent(name, part0, part1)
	if not part0 or not part1 then
		return nil
	end

	return createMotor(name, part0, part1, part0.CFrame:ToObjectSpace(part1.CFrame), CFrame.identity)
end

local function weldFromCurrent(name, part0, part1)
	if not part0 or not part1 then
		return nil
	end

	return createWeld(name, part0, part1)
end

local function ensureAttachment(parent, name, position)
	if not parent or parent:FindFirstChild(name) then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = position
	attachment.Parent = parent
end

local function ensureImportedBearRig(model)
	if not model:IsA("Model") or model:GetAttribute("GeneratedRig") then
		return
	end

	local body = ensureBodyPart(model)
	if not body then
		return
	end

	model.PrimaryPart = body
	body:SetAttribute("RideCenter", true)

	local saddle = body:FindFirstChild(OPTIONS.saddlePointName)
	if not saddle then
		saddle = Instance.new("Attachment")
		saddle.Name = OPTIONS.saddlePointName
		saddle.CFrame = CFrame.new(0, math.max(1.8, body.Size.Y * 0.58), 0.1)
		saddle.Parent = body
	end

	local skeleton = model:FindFirstChild("Skeleton")
	if not skeleton then
		skeleton = Instance.new("Folder")
		skeleton.Name = "Skeleton"
		skeleton.Parent = model
	end

	ensureAttachment(body, "Spine", Vector3.new(0, 0, 0))
	ensureAttachment(body, "Saddle", Vector3.new(0, math.max(1.8, body.Size.Y * 0.58), 0.1))
	ensureAttachment(body, "HeadJoint", Vector3.new(0, body.Size.Y * 0.18, -body.Size.Z * 0.5))
	ensureAttachment(body, "LeftFrontShoulder", Vector3.new(-body.Size.X * 0.32, -body.Size.Y * 0.28, -body.Size.Z * 0.35))
	ensureAttachment(body, "RightFrontShoulder", Vector3.new(body.Size.X * 0.32, -body.Size.Y * 0.28, -body.Size.Z * 0.35))
	ensureAttachment(body, "LeftBackHip", Vector3.new(-body.Size.X * 0.32, -body.Size.Y * 0.28, body.Size.Z * 0.35))
	ensureAttachment(body, "RightBackHip", Vector3.new(body.Size.X * 0.32, -body.Size.Y * 0.28, body.Size.Z * 0.35))

	local head = partNamed(model, "Head")
	motorFromCurrent("BodyToNeck", body, head)
	weldFromCurrent("HeadToSnout", head, partNamed(model, "Snout"))
	weldFromCurrent("SnoutToNose", partNamed(model, "Snout"), partNamed(model, "Nose"))
	weldFromCurrent("HeadToLeftEye", head, partNamed(model, "EyeL"))
	weldFromCurrent("HeadToRightEye", head, partNamed(model, "EyeR"))
	weldFromCurrent("HeadToLeftEar", head, partNamed(model, "EarL"))
	weldFromCurrent("HeadToRightEar", head, partNamed(model, "EarR"))
	weldFromCurrent("HeadToLeftEarInner", head, partNamed(model, "EarLin"))
	weldFromCurrent("HeadToRightEarInner", head, partNamed(model, "EarRin"))
	weldFromCurrent("BodyToTail", body, partNamed(model, "Tail"))

	motorFromCurrent("BodyToLeftFrontUpperLeg", body, partNamed(model, "LegFL"))
	motorFromCurrent("LeftFrontKnee", partNamed(model, "LegFL"), partNamed(model, "Paw_LegFL"))
	motorFromCurrent("BodyToRightFrontUpperLeg", body, partNamed(model, "LegFR"))
	motorFromCurrent("RightFrontKnee", partNamed(model, "LegFR"), partNamed(model, "Paw_LegFR"))
	motorFromCurrent("BodyToLeftBackUpperLeg", body, partNamed(model, "LegBL"))
	motorFromCurrent("LeftBackKnee", partNamed(model, "LegBL"), partNamed(model, "Paw_LegBL"))
	motorFromCurrent("BodyToRightBackUpperLeg", body, partNamed(model, "LegBR"))
	motorFromCurrent("RightBackKnee", partNamed(model, "LegBR"), partNamed(model, "Paw_LegBR"))

	local scriptsFolder = model:FindFirstChild("ModelScripts")
	if not scriptsFolder then
		scriptsFolder = Instance.new("Folder")
		scriptsFolder.Name = "ModelScripts"
		scriptsFolder.Parent = model
	end

	local runtimeNote = scriptsFolder:FindFirstChild("BearRigRuntime")
	if not runtimeNote then
		runtimeNote = Instance.new("StringValue")
		runtimeNote.Name = "BearRigRuntime"
		runtimeNote.Parent = scriptsFolder
	end
	runtimeNote.Value = "Imported PreviewBear rigged at runtime. Body is the ride center; legs are Motor6D animated and head/details are connected."
end

local function mountRotation()
	return CFrame.Angles(math.rad(OPTIONS.modelPitch), math.rad(OPTIONS.modelYaw), math.rad(OPTIONS.modelRoll))
end

local function mountOffset()
	return CFrame.new(OPTIONS.xOffset, OPTIONS.yOffset, OPTIONS.zOffset) * mountRotation()
end

local function cframeOf(instance)
	if instance:IsA("Attachment") then
		return instance.WorldCFrame
	end
	if instance:IsA("BasePart") then
		return instance.CFrame
	end
	return nil
end

local function findSaddlePoint(visual)
	local direct = visual:FindFirstChild(OPTIONS.saddlePointName, true)
	if direct and (direct:IsA("Attachment") or direct:IsA("BasePart")) then
		return direct
	end
	return nil
end

local function visualPivotToAnchorOffset(visual, anchor)
	if not visual:IsA("Model") then
		return CFrame.identity
	end

	local pivot = visual:GetPivot()
	local anchorCFrame = anchor and cframeOf(anchor)
	if anchorCFrame then
		return pivot:ToObjectSpace(anchorCFrame)
	end

	local boundsCFrame = visual:GetBoundingBox()
	return pivot:ToObjectSpace(boundsCFrame)
end

local function setVisualAnchorCFrame(visual, anchorCFrame, pivotToAnchor)
	if visual:IsA("Model") then
		visual:PivotTo(anchorCFrame * pivotToAnchor:Inverse())
	elseif visual:IsA("BasePart") then
		visual.CFrame = anchorCFrame
	end
end

local function createBearMountMotor(root, body)
	local existing = root:FindFirstChild("PolarBearMountMotor")
	if existing then
		existing:Destroy()
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "PolarBearMountMotor"
	motor.Part0 = root
	motor.Part1 = body
	motor.C0 = root.CFrame:ToObjectSpace(body.CFrame)
	motor.C1 = CFrame.identity
	motor.Parent = root
	return motor
end

local function scaleOffsetCFrame(cframe, scale)
	local rotationOnly = cframe - cframe.Position
	return CFrame.new(cframe.Position * scale) * rotationOnly
end

local function scaleModelGeometry(model, scale)
	local pivot = model:GetPivot()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local relative = pivot:ToObjectSpace(descendant.CFrame)
			descendant.Size *= scale
			descendant.CFrame = pivot * scaleOffsetCFrame(relative, scale)
		elseif descendant:IsA("Attachment") then
			descendant.Position *= scale
		elseif descendant:IsA("Motor6D") then
			descendant.C0 = scaleOffsetCFrame(descendant.C0, scale)
			descendant.C1 = scaleOffsetCFrame(descendant.C1, scale)
		end
	end
end

local function scaleVisualToTargetSize(visual)
	if visual:GetAttribute("UseExactWorkspaceBearVisual") == true then
		return
	end

	if not visual:IsA("Model") then
		if visual:IsA("BasePart") then
			local biggestAxis = math.max(visual.Size.X, visual.Size.Y, visual.Size.Z)
			if biggestAxis > 0 then
				visual.Size *= OPTIONS.modelTargetSize / biggestAxis
			end
		end
		return
	end

	local _, size = visual:GetBoundingBox()
	local biggestAxis = math.max(size.X, size.Y, size.Z)
	if biggestAxis <= 0 then
		return
	end

	scaleModelGeometry(visual, OPTIONS.modelTargetSize / biggestAxis)

	ensureImportedBearRig(visual)
end

local function prepareBearVisual(visual)
	local primary = nil
	if visual:IsA("Model") then
		ensureImportedBearRig(visual)
		primary = visual:FindFirstChild(OPTIONS.primaryPartName, true) or visual.PrimaryPart or largestBasePart(visual) or firstBasePart(visual)
		if primary then
			primary.Name = OPTIONS.primaryPartName
			visual.PrimaryPart = primary
		end
	else
		primary = firstBasePart(visual)
	end

	if not primary then
		return nil
	end

	scaleVisualToTargetSize(visual)
	if visual:IsA("Model") then
		ensureImportedBearRig(visual)
		primary = visual:FindFirstChild(OPTIONS.primaryPartName, true) or visual.PrimaryPart or primary
		visual.PrimaryPart = primary
	end

	local function configureDescendant(descendant)
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		elseif descendant:IsA("Humanoid") then
			descendant.WalkSpeed = 0
			descendant.JumpPower = 0
			descendant.JumpHeight = 0
			descendant.AutoRotate = false
		end
	end

	configureDescendant(visual)
	for _, descendant in ipairs(visual:GetDescendants()) do
		configureDescendant(descendant)
	end

	return primary
end

local function motorMap(model)
	local motors = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			motors[descendant.Name] = {
				motor = descendant,
				baseC0 = descendant.C0,
			}
		end
	end
	return motors
end

local function setMotorEntry(entry, transform)
	if entry and entry.motor and entry.motor.Parent then
		entry.motor.Transform = CFrame.identity
		entry.motor.C0 = entry.baseC0 * transform
	end
end

local function setMotor(motors, name, transform)
	setMotorEntry(motors[name], transform)
end

local function restoreMotorMap(motors)
	if not motors then
		return
	end

	for _, entry in pairs(motors) do
		if entry.motor and entry.motor.Parent then
			entry.motor.Transform = CFrame.identity
			entry.motor.C0 = entry.baseC0
		end
	end
end

local function pushMotionFromAttributes(instance, now)
	local pushUntil = instance:GetAttribute("PolarPushingUntil")
	if typeof(pushUntil) ~= "number" or now >= pushUntil then
		return 0, 0
	end

	local pushStartedAt = instance:GetAttribute("PolarPushStartedAt")
	if typeof(pushStartedAt) ~= "number" then
		return 0.65, 0.35
	end

	local duration = math.max(0.05, pushUntil - pushStartedAt)
	local progress = math.clamp((now - pushStartedAt) / duration, 0, 1)
	local attack = math.clamp(progress / 0.16, 0, 1)
	local release = 1 - math.clamp((progress - 0.72) / 0.28, 0, 1)
	return attack * release, progress
end

local function pushAlphaFromAttributes(instance, now)
	local alpha = pushMotionFromAttributes(instance, now)
	return alpha
end

local function pushJumpCurve(progress)
	return math.sin(math.clamp(progress, 0, 1) * math.pi)
end

local function startBearAnimator(model, mountMotor, root)
	if not model:IsA("Model") then
		return nil
	end

	local body = model:FindFirstChild("Body", true)
	if not body or not body:IsA("BasePart") then
		return nil
	end

	local motors = motorMap(model)
	local mountMotorEntry = mountMotor and {
		motor = mountMotor,
		baseC0 = mountMotor.C0,
	} or nil
	local trackedPart = root or body
	local previousPosition = trackedPart.Position
	local phase = 0

	return RunService.Heartbeat:Connect(function(deltaTime)
		if not model.Parent or not body.Parent then
			return
		end

		local trackedPosition = if trackedPart and trackedPart.Parent then trackedPart.Position else body.Position
		local delta = trackedPosition - previousPosition
		previousPosition = trackedPosition

		local now = os.clock()
		local pushAlpha, pushProgress = pushMotionFromAttributes(model, now)
		local jumpCurve = pushJumpCurve(pushProgress)
		local pushCycle = math.sin(pushProgress * math.pi * 2)
		local speed = if deltaTime > 0 then delta.Magnitude / deltaTime else 0
		local stride = math.clamp(speed / 13, 0, 1)
		local animatedStride = math.max(stride, pushAlpha * 0.55)
		local idle = 1 - stride
		phase += deltaTime * (3.2 + animatedStride * 12.5 + pushAlpha * 7.5)

		local a = math.sin(phase)
		local b = math.sin(phase + math.pi)
		local headSway = math.sin(phase * 0.5)
		local breathe = math.sin(phase * 0.75) * 0.035
		local pushShake = math.sin(phase * 2.35) * pushAlpha
		local pushHop = jumpCurve * 1.35 + pushAlpha * 0.32
		local bodyBob = math.abs(a) * animatedStride * 0.14 + breathe * idle + pushHop
		local bodyLean = -pushAlpha * 18 + a * animatedStride * 2.2

		setMotorEntry(mountMotorEntry, CFrame.new(0, bodyBob, pushAlpha * 0.95 + jumpCurve * 0.45) * CFrame.Angles(math.rad(bodyLean), 0, math.rad(a * animatedStride * 2.6 + pushShake * 2.4)))

		setMotor(motors, "BodyToNeck", CFrame.Angles(math.rad(2 + headSway * 3.5 - pushAlpha * 18), math.rad(headSway * 4 + pushShake * 1.6), 0))
		setMotor(motors, "NeckToHead", CFrame.Angles(math.rad(-1 + a * 3 * animatedStride + idle * 1.5 - pushAlpha * 17), math.rad(headSway * 2.5), 0))
		setMotor(motors, "BodyToRumpMass", CFrame.new(0, pushHop * 0.28, -pushAlpha * 0.18) * CFrame.Angles(math.rad(-a * 2.2 * animatedStride + pushAlpha * 14), 0, math.rad(a * 2.4 * animatedStride + pushShake * 2.2)))

		setMotor(motors, "BodyToLeftFrontUpperLeg", CFrame.new(0, breathe - pushAlpha * 0.18, -pushAlpha * 0.2) * CFrame.Angles(a * 0.82 * animatedStride - pushAlpha * 1.28 + pushCycle * 0.18, 0, math.rad(-4 - pushAlpha * 5)))
		setMotor(motors, "LeftFrontKnee", CFrame.Angles(math.max(0, -a) * 1.05 * animatedStride + pushAlpha * 1.45, 0, 0))
		setMotor(motors, "LeftFrontAnkle", CFrame.Angles(-math.max(0, a) * 0.5 * animatedStride - pushAlpha * 0.64, 0, 0))

		setMotor(motors, "BodyToRightFrontUpperLeg", CFrame.new(0, -breathe - pushAlpha * 0.18, -pushAlpha * 0.2) * CFrame.Angles(b * 0.82 * animatedStride - pushAlpha * 1.28 - pushCycle * 0.18, 0, math.rad(4 + pushAlpha * 5)))
		setMotor(motors, "RightFrontKnee", CFrame.Angles(math.max(0, -b) * 1.05 * animatedStride + pushAlpha * 1.45, 0, 0))
		setMotor(motors, "RightFrontAnkle", CFrame.Angles(-math.max(0, b) * 0.5 * animatedStride - pushAlpha * 0.64, 0, 0))

		local leftBackLift = math.max(0, -b) * animatedStride * 0.24 + pushAlpha * 0.58
		local rightBackLift = math.max(0, -a) * animatedStride * 0.24 + pushAlpha * 0.58

		setMotor(motors, "BodyToLeftBackUpperLeg", CFrame.new(0, -breathe + leftBackLift, pushAlpha * 0.18) * CFrame.Angles(b * 0.84 * animatedStride + pushAlpha * 1.55 - pushCycle * 0.18, 0, math.rad(-4)))
		setMotor(motors, "LeftBackKnee", CFrame.Angles(math.max(0, -b) * 1.05 * animatedStride + pushAlpha * 1.5, 0, 0))
		setMotor(motors, "LeftBackAnkle", CFrame.Angles(-math.max(0, b) * 0.5 * animatedStride + pushAlpha * 0.54, 0, 0))

		setMotor(motors, "BodyToRightBackUpperLeg", CFrame.new(0, breathe + rightBackLift, pushAlpha * 0.18) * CFrame.Angles(a * 0.84 * animatedStride + pushAlpha * 1.55 + pushCycle * 0.18, 0, math.rad(4)))
		setMotor(motors, "RightBackKnee", CFrame.Angles(math.max(0, -a) * 1.05 * animatedStride + pushAlpha * 1.5, 0, 0))
		setMotor(motors, "RightBackAnkle", CFrame.Angles(-math.max(0, a) * 0.5 * animatedStride + pushAlpha * 0.54, 0, 0))
	end)
end

local function characterMotorMap(character)
	local motors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			motors[descendant.Name] = {
				motor = descendant,
				baseC0 = descendant.C0,
			}
		end
	end
	return motors
end

local function stopCurrentTracks(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.1)
	end
end

local function createRiderTarget(parent, name)
	local target = Instance.new("Part")
	target.Name = name
	target.Size = Vector3.new(0.35, 0.35, 0.35)
	target.Transparency = 1
	target.Anchored = false
	target.CanCollide = false
	target.CanTouch = false
	target.CanQuery = false
	target.Massless = true
	target.Parent = parent
	return target
end

local function weldTargetTo(target, part)
	if not target or not part then
		return
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = target.Name .. "Weld"
	weld.Part0 = target
	weld.Part1 = part
	weld.Parent = target
end

local function firstCharacterPart(character, names)
	for _, name in ipairs(names) do
		local part = partNamed(character, name)
		if part then
			return part
		end
	end
	return nil
end

local function createRiderIk(humanoid, name, chainRoot, endEffector, target)
	if not humanoid or not chainRoot or not endEffector or not target or chainRoot == endEffector then
		return nil
	end

	local ok, control = pcall(function()
		local ik = Instance.new("IKControl")
		ik.Name = name
		ik.Type = Enum.IKControlType.Position
		ik.ChainRoot = chainRoot
		ik.EndEffector = endEffector
		ik.Target = target
		ik.Weight = 1
		ik.SmoothTime = 0
		ik.Enabled = true
		ik.Parent = humanoid
		return ik
	end)

	if ok then
		return control
	end
	return nil
end

local function startRiderRig(character, humanoid, bear, root)
	local body = bear and bear:FindFirstChild("Body", true)
	local head = bear and bear:FindFirstChild("Head", true)
	if not body or not body:IsA("BasePart") or not head or not head:IsA("BasePart") then
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = "PolarRiderRig"
	folder.Parent = character

	local leftHandTarget = createRiderTarget(folder, "LeftHandNeckTarget")
	local rightHandTarget = createRiderTarget(folder, "RightHandNeckTarget")
	local leftFootTarget = createRiderTarget(folder, "LeftFootSideTarget")
	local rightFootTarget = createRiderTarget(folder, "RightFootSideTarget")

	local controls = {}
	local function addControl(control)
		if control then
			table.insert(controls, control)
		end
	end

	addControl(createRiderIk(humanoid, "PolarLeftHandGripIK", firstCharacterPart(character, { "LeftUpperArm" }), firstCharacterPart(character, { "LeftHand", "LeftLowerArm" }), leftHandTarget))
	addControl(createRiderIk(humanoid, "PolarRightHandGripIK", firstCharacterPart(character, { "RightUpperArm" }), firstCharacterPart(character, { "RightHand", "RightLowerArm" }), rightHandTarget))
	addControl(createRiderIk(humanoid, "PolarLeftLegSideIK", firstCharacterPart(character, { "LeftUpperLeg" }), firstCharacterPart(character, { "LeftFoot", "LeftLowerLeg" }), leftFootTarget))
	addControl(createRiderIk(humanoid, "PolarRightLegSideIK", firstCharacterPart(character, { "RightUpperLeg" }), firstCharacterPart(character, { "RightFoot", "RightLowerLeg" }), rightFootTarget))

	local function targetCFrame(position, forward, up)
		return CFrame.lookAt(position, position + forward, up)
	end

	local function updateTargets()
		if not body.Parent or not head.Parent or not root.Parent then
			return
		end

		local forward = head.Position - body.Position
		if forward.Magnitude < 0.1 then
			forward = root.CFrame.LookVector
		else
			forward = forward.Unit
		end

		local right = root.CFrame.RightVector
		local up = Vector3.yAxis
		local neckCenter = body.Position:Lerp(head.Position, 0.55) + up * -0.6 + forward * 0.5
		local sideCenter = body.Position + forward * OPTIONS.riderFootForwardOffset + up * OPTIONS.riderFootHeightOffset

		leftHandTarget.CFrame = targetCFrame(neckCenter - right * 0.78, forward, up)
		rightHandTarget.CFrame = targetCFrame(neckCenter + right * 0.78, forward, up)
		leftFootTarget.CFrame = targetCFrame(sideCenter - right * OPTIONS.riderFootSideOffset, forward, up)
		rightFootTarget.CFrame = targetCFrame(sideCenter + right * OPTIONS.riderFootSideOffset, forward, up)
	end

	updateTargets()
	weldTargetTo(leftHandTarget, head)
	weldTargetTo(rightHandTarget, head)
	weldTargetTo(leftFootTarget, body)
	weldTargetTo(rightFootTarget, body)
	character:SetAttribute("PolarRiderRigged", true)

	return {
		folder = folder,
		connection = nil,
		controls = controls,
	}
end

local function stopRiderRig(rig, character)
	if rig and rig.connection and rig.connection.Connected then
		rig.connection:Disconnect()
	end
	if rig and rig.controls then
		for _, control in ipairs(rig.controls) do
			if control and control.Parent then
				control:Destroy()
			end
		end
	end
	if rig and rig.folder then
		rig.folder:Destroy()
	end
	if character and character.Parent then
		character:SetAttribute("PolarRiderRigged", nil)
	end
end

local function startRiderPose(character, humanoid)
	local motors = characterMotorMap(character)
	stopCurrentTracks(humanoid)

	local phase = 0
	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not character.Parent or not humanoid.Parent then
			return
		end

		phase += deltaTime * 5
		local breathe = math.sin(phase) * 0.025
		local pushAlpha, pushProgress = pushMotionFromAttributes(character, os.clock())
		local riderHop = pushJumpCurve(pushProgress) * 1.08 + pushAlpha * 0.24
		local rootPose = CFrame.new(0, 0.12 + breathe * 0.25 + riderHop, -0.22 - pushAlpha * 0.2)
			* CFrame.Angles(math.rad(-9 - pushAlpha * 10), 0, 0)

		setMotor(motors, "Root", rootPose)
		setMotor(motors, "RootJoint", rootPose)
		setMotor(motors, "Waist", CFrame.Angles(math.rad(16 + pushAlpha * 8), 0, 0))
		setMotor(motors, "Neck", CFrame.Angles(math.rad(-5 + pushAlpha * 2), 0, 0))

		local leftHipPose = CFrame.new(-OPTIONS.riderHipSideShift, OPTIONS.riderHipLift, 0.08) * CFrame.Angles(math.rad(-68), 0, math.rad(-68))
		local rightHipPose = CFrame.new(OPTIONS.riderHipSideShift, OPTIONS.riderHipLift, 0.08) * CFrame.Angles(math.rad(-68), 0, math.rad(68))
		setMotor(motors, "LeftHip", leftHipPose)
		setMotor(motors, "RightHip", rightHipPose)
		setMotor(motors, "Left Hip", leftHipPose)
		setMotor(motors, "Right Hip", rightHipPose)
		setMotor(motors, "LeftKnee", CFrame.Angles(math.rad(92), 0, math.rad(-12)))
		setMotor(motors, "RightKnee", CFrame.Angles(math.rad(92), 0, math.rad(12)))
		setMotor(motors, "LeftAnkle", CFrame.Angles(math.rad(-12), 0, math.rad(-32)))
		setMotor(motors, "RightAnkle", CFrame.Angles(math.rad(-12), 0, math.rad(32)))

		setMotor(motors, "LeftShoulder", CFrame.Angles(math.rad(-68 - pushAlpha * 6), math.rad(-20), math.rad(-28)))
		setMotor(motors, "RightShoulder", CFrame.Angles(math.rad(-68 - pushAlpha * 6), math.rad(20), math.rad(28)))
		setMotor(motors, "Left Shoulder", CFrame.Angles(math.rad(-68 - pushAlpha * 6), math.rad(-20), math.rad(-28)))
		setMotor(motors, "Right Shoulder", CFrame.Angles(math.rad(-68 - pushAlpha * 6), math.rad(20), math.rad(28)))
		setMotor(motors, "LeftElbow", CFrame.Angles(math.rad(-78 - pushAlpha * 8), 0, math.rad(-6)))
		setMotor(motors, "RightElbow", CFrame.Angles(math.rad(-78 - pushAlpha * 8), 0, math.rad(6)))
		setMotor(motors, "LeftWrist", CFrame.Angles(math.rad(-8), math.rad(-12), math.rad(-16)))
		setMotor(motors, "RightWrist", CFrame.Angles(math.rad(-8), math.rad(12), math.rad(16)))
	end)
	return connection, motors
end

local function clearMotorTransforms(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			descendant.Transform = CFrame.identity
		end
	end
end

local function paintBearVisual(visual)
	local function paintPart(part)
		local name = string.lower(part.Name or "")
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = math.min(part.Transparency, 0.02)
		part.Reflectance = math.max(part.Reflectance, 0.08)
		part.CastShadow = false

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

		if name:find("nose") then
			part.Color = BEAR_PALETTE.nose
		elseif name:find("eye") then
			part.Color = BEAR_PALETTE.eye
		elseif name:find("paw") or name:find("claw") or name:find("foot") then
			part.Color = BEAR_PALETTE.paw
		elseif name:find("earin") or name:find("inner") then
			part.Color = BEAR_PALETTE.earInner
		elseif name:find("belly") or name:find("chest") then
			part.Color = BEAR_PALETTE.belly
		elseif name:find("leg") then
			part.Color = BEAR_PALETTE.shadow
		elseif name:find("snout") or name:find("neck") then
			part.Color = BEAR_PALETTE.belly
		elseif name:find("saddle") or name:find("strap") then
			part.Color = BEAR_PALETTE.neonCyan
			part.Material = Enum.Material.Neon
		else
			part.Color = BEAR_PALETTE.body
		end
	end

	if visual:IsA("BasePart") then
		paintPart(visual)
		return
	end

	for _, descendant in ipairs(visual:GetDescendants()) do
		if descendant:IsA("BasePart") then
			paintPart(descendant)
		end
	end

end

function PolarPushModels.attach(subject, parent)
	local root = Shared.rootFromSubject(subject)
	local humanoid = Shared.humanoidFromSubject(subject)
	local character = Shared.characterFromSubject(subject)
	if not root or not humanoid or not character then
		return nil
	end

	local template = findBearTemplate()
	if not template then
		warn("[PolarPushModels] No bear model found or generated")
		return nil
	end

	local mountFolder = Instance.new("Folder")
	mountFolder.Name = subject.Name .. "_PolarBearMount"
	mountFolder.Parent = parent

	local bear = template:Clone()
	bear.Name = "MountedPolarBear"
	bear.Parent = mountFolder
	bear:SetAttribute("MountFacingYawDegrees", OPTIONS.modelYaw)
	bear:SetAttribute("BodyIsRideCenter", true)
	if template:IsDescendantOf(workspace) then
		bear:SetAttribute("UseExactWorkspaceBearVisual", true)
		bear:SetAttribute("ExactWorkspaceTemplatePath", template:GetFullName())
	end

	local primary = prepareBearVisual(bear)
	if not primary then
		mountFolder:Destroy()
		warn("[PolarPushModels] Bear model has no BasePart")
		return nil
	end

	paintBearVisual(bear)

	local saddlePoint = findSaddlePoint(bear)
	local pivotToAnchor = visualPivotToAnchorOffset(bear, saddlePoint)
	local hasSaddlePoint = saddlePoint ~= nil
	if not hasSaddlePoint then
		warn("[PolarPushModels] Add a SaddlePoint attachment inside Body for perfect centered riding")
	end

	local oldWalkSpeed = humanoid.WalkSpeed
	local oldJumpPower = humanoid.JumpPower
	local oldJumpHeight = humanoid.JumpHeight
	local oldHipHeight = humanoid.HipHeight
	local oldAutoJump = humanoid.AutoJumpEnabled
	local oldAutoRotate = humanoid.AutoRotate

	local animateScript = character:FindFirstChild("Animate")
	local oldAnimateDisabled = nil
	if animateScript and animateScript:IsA("LocalScript") then
		oldAnimateDisabled = animateScript.Disabled
		animateScript.Disabled = true
	end

	humanoid.WalkSpeed = OPTIONS.playerWalkSpeed
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	local hipExtra = subject:GetAttribute("IsTestBot") and OPTIONS.botHipHeightExtra or 0
	humanoid.HipHeight = oldHipHeight + OPTIONS.playerHipHeightAdd + hipExtra
	humanoid.AutoJumpEnabled = false
	humanoid.AutoRotate = true
	character:SetAttribute("PolarMountedOnBear", true)

	local function targetAnchorCFrame()
		if hasSaddlePoint then
			return (root.CFrame * OPTIONS.saddleTargetOffset) * mountRotation()
		end
		return root.CFrame * mountOffset()
	end

	setVisualAnchorCFrame(bear, targetAnchorCFrame(), pivotToAnchor)
	local mountMotor = createBearMountMotor(root, primary)
	local riderRig = startRiderRig(character, humanoid, bear, root)
	local riderPoseConnection, riderMotorMap = startRiderPose(character, humanoid)
	local bearAnimationConnection = startBearAnimator(bear, mountMotor, root)

	return {
		folder = mountFolder,
		bear = bear,
		saddlePoint = saddlePoint,
		pivotToAnchor = pivotToAnchor,
		mountMotor = mountMotor,
		riderRig = riderRig,
		bearAnimationConnection = bearAnimationConnection,
		riderPoseConnection = riderPoseConnection,
		riderMotorMap = riderMotorMap,
		humanoid = humanoid,
		character = character,
		oldWalkSpeed = oldWalkSpeed,
		oldJumpPower = oldJumpPower,
		oldJumpHeight = oldJumpHeight,
		oldHipHeight = oldHipHeight,
		oldAutoJump = oldAutoJump,
		oldAutoRotate = oldAutoRotate,
		animateScript = animateScript,
		oldAnimateDisabled = oldAnimateDisabled,
	}
end

function PolarPushModels.setPushState(mount, pushUntil, pushStartedAt)
	if not mount then
		return
	end

	local startedAt = pushStartedAt or os.clock()
	if mount.bear and mount.bear.Parent then
		mount.bear:SetAttribute("PolarPushingUntil", pushUntil)
		mount.bear:SetAttribute("PolarPushStartedAt", startedAt)
	end
	if mount.character and mount.character.Parent then
		mount.character:SetAttribute("PolarPushingUntil", pushUntil)
		mount.character:SetAttribute("PolarPushStartedAt", startedAt)
	end
end

function PolarPushModels.detach(mount)
	if not mount then
		return
	end

	if mount.connection and mount.connection.Connected then
		mount.connection:Disconnect()
	end

	if mount.bearAnimationConnection and mount.bearAnimationConnection.Connected then
		mount.bearAnimationConnection:Disconnect()
	end

	if mount.riderPoseConnection and mount.riderPoseConnection.Connected then
		mount.riderPoseConnection:Disconnect()
	end

	stopRiderRig(mount.riderRig, mount.character)

	if mount.mountMotor and mount.mountMotor.Parent then
		mount.mountMotor:Destroy()
	end

	if mount.character and mount.character.Parent then
		restoreMotorMap(mount.riderMotorMap)
		clearMotorTransforms(mount.character)
		mount.character:SetAttribute("PolarMountedOnBear", nil)
		mount.character:SetAttribute("PolarPushingUntil", nil)
		mount.character:SetAttribute("PolarPushStartedAt", nil)
	end

	if mount.humanoid and mount.humanoid.Parent then
		mount.humanoid.WalkSpeed = mount.oldWalkSpeed
		mount.humanoid.JumpPower = mount.oldJumpPower
		mount.humanoid.JumpHeight = mount.oldJumpHeight
		mount.humanoid.HipHeight = mount.oldHipHeight
		mount.humanoid.AutoJumpEnabled = mount.oldAutoJump
		mount.humanoid.AutoRotate = mount.oldAutoRotate
	end

	if mount.animateScript and mount.oldAnimateDisabled ~= nil then
		mount.animateScript.Disabled = mount.oldAnimateDisabled
	end

	if mount.folder then
		mount.folder:Destroy()
	end
end

function PolarPushModels.detachAll(mounts)
	for _, mount in pairs(mounts) do
		PolarPushModels.detach(mount)
	end
	table.clear(mounts)
end

function PolarPushModels.options()
	return OPTIONS
end

return PolarPushModels
