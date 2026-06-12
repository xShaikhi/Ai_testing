local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SpectateController = {}

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local targetIndex = 1
local overlayLabel = nil

local function humanoidFromModel(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function makeOverlay()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpectateOverlay"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = localPlayer:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.04)
	label.Size = UDim2.fromOffset(430, 52)
	label.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(245, 250, 255)
	label.TextScaled = true
	label.Text = "SPECTATING"
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	overlayLabel = label
	return gui
end

local overlay = nil

local function candidateTargets()
	local targets = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player:GetAttribute("Spectating") ~= true and player:GetAttribute("RoundContestant") == true then
			local character = player.Character
			local humanoid = humanoidFromModel(character)
			if humanoid and humanoid.Health > 0 then
				table.insert(targets, {
					name = player.DisplayName or player.Name,
					humanoid = humanoid,
				})
			end
		end
	end

	local root = Workspace:FindFirstChild("CrashBashPrototype")
	local bots = root and root:FindFirstChild("TestNPCs")
	if bots then
		for _, bot in ipairs(bots:GetChildren()) do
			local humanoid = humanoidFromModel(bot)
			if humanoid and humanoid.Health > 0 and bot:GetAttribute("RoundContestant") == true and bot:GetAttribute("Eliminated") ~= true then
				table.insert(targets, {
					name = bot.Name,
					humanoid = humanoid,
				})
			end
		end
	end

	return targets
end

local function applySpectateTarget()
	if not overlay then
		overlay = makeOverlay()
	end

	local spectating = localPlayer:GetAttribute("Spectating") == true
	overlay.Enabled = spectating

	if not spectating then
		local humanoid = humanoidFromModel(localPlayer.Character)
		if humanoid then
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
		end
		return
	end

	local targets = candidateTargets()
	if #targets == 0 then
		overlayLabel.Text = "SPECTATING"
		return
	end

	targetIndex = ((targetIndex - 1) % #targets) + 1
	local target = targets[targetIndex]
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = target.humanoid
	overlayLabel.Text = "SPECTATING: " .. string.upper(target.name)
end

local function stepTarget(direction)
	if localPlayer:GetAttribute("Spectating") ~= true then
		return
	end

	local targets = candidateTargets()
	if #targets == 0 then
		return
	end

	targetIndex += direction
	if targetIndex < 1 then
		targetIndex = #targets
	elseif targetIndex > #targets then
		targetIndex = 1
	end

	applySpectateTarget()
end

function SpectateController:Init()
	overlay = makeOverlay()
end

function SpectateController:Start()
	localPlayer:GetAttributeChangedSignal("Spectating"):Connect(applySpectateTarget)
	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.2)
		applySpectateTarget()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.Left then
			stepTarget(-1)
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Right then
			stepTarget(1)
		end
	end)

	local accumulator = 0
	RunService.RenderStepped:Connect(function(deltaTime)
		accumulator += deltaTime
		if accumulator >= 0.75 then
			accumulator = 0
			applySpectateTarget()
		end
	end)
end

return SpectateController
