local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PrimaryActionController = {}

local localPlayer = Players.LocalPlayer
local primaryRemote = nil
local lastFireAt = 0
local predictedCooldownEndsAt = 0
local actionBound = false
local PRIMARY_ACTION = "CrashBashPrimaryAction"
local POLAR_PUSH_NAME = "Polar Push"
local POLAR_PUSH_COOLDOWN = 2
local COOLDOWN_END_ATTRIBUTE = "PrimaryActionCooldownEndsAt"
local COOLDOWN_DURATION_ATTRIBUTE = "PrimaryActionCooldownDuration"

local cooldownGui = nil
local cooldownPanel = nil
local cooldownFill = nil
local cooldownStatus = nil
local cooldownCaption = nil

local function canUsePrimary()
	return localPlayer:GetAttribute("AllowPrimaryAction") == true
end

local function isPolarPush()
	return localPlayer:GetAttribute("CurrentMinigame") == POLAR_PUSH_NAME
end

local function cooldownState()
	local serverNow = workspace:GetServerTimeNow()
	local serverEndsAt = localPlayer:GetAttribute(COOLDOWN_END_ATTRIBUTE)
	local duration = localPlayer:GetAttribute(COOLDOWN_DURATION_ATTRIBUTE)
	if typeof(serverEndsAt) ~= "number" then
		serverEndsAt = 0
	end
	if typeof(duration) ~= "number" or duration <= 0 then
		duration = POLAR_PUSH_COOLDOWN
	end

	local endsAt = math.max(serverEndsAt, predictedCooldownEndsAt)
	local remaining = math.max(0, endsAt - serverNow)
	if remaining <= 0 then
		predictedCooldownEndsAt = 0
	end
	return remaining, duration
end

local function ensureCooldownGui()
	if cooldownGui then
		return
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	cooldownGui = Instance.new("ScreenGui")
	cooldownGui.Name = "PrimaryActionCooldownGui"
	cooldownGui.ResetOnSpawn = false
	cooldownGui.IgnoreGuiInset = true
	cooldownGui.Enabled = false
	cooldownGui.Parent = playerGui

	cooldownPanel = Instance.new("Frame")
	cooldownPanel.Name = "CooldownPanel"
	cooldownPanel.AnchorPoint = Vector2.new(1, 1)
	cooldownPanel.Position = UDim2.new(1, -24, 1, -156)
	cooldownPanel.Size = UDim2.fromOffset(156, 54)
	cooldownPanel.BackgroundColor3 = Color3.fromRGB(12, 20, 28)
	cooldownPanel.BackgroundTransparency = 0.12
	cooldownPanel.BorderSizePixel = 0
	cooldownPanel.Parent = cooldownGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 8)
	panelCorner.Parent = cooldownPanel

	local stroke = Instance.new("UIStroke")
	stroke.Name = "ReadyStroke"
	stroke.Color = Color3.fromRGB(110, 230, 255)
	stroke.Transparency = 0.25
	stroke.Thickness = 1.5
	stroke.Parent = cooldownPanel

	cooldownCaption = Instance.new("TextLabel")
	cooldownCaption.Name = "Caption"
	cooldownCaption.BackgroundTransparency = 1
	cooldownCaption.Position = UDim2.fromOffset(12, 6)
	cooldownCaption.Size = UDim2.new(1, -24, 0, 18)
	cooldownCaption.Font = Enum.Font.GothamBold
	cooldownCaption.Text = "PUSH"
	cooldownCaption.TextColor3 = Color3.fromRGB(230, 248, 255)
	cooldownCaption.TextSize = 14
	cooldownCaption.TextXAlignment = Enum.TextXAlignment.Left
	cooldownCaption.Parent = cooldownPanel

	cooldownStatus = Instance.new("TextLabel")
	cooldownStatus.Name = "Status"
	cooldownStatus.BackgroundTransparency = 1
	cooldownStatus.Position = UDim2.new(1, -70, 0, 6)
	cooldownStatus.Size = UDim2.fromOffset(58, 18)
	cooldownStatus.Font = Enum.Font.GothamBold
	cooldownStatus.Text = "READY"
	cooldownStatus.TextColor3 = Color3.fromRGB(95, 255, 170)
	cooldownStatus.TextSize = 12
	cooldownStatus.TextXAlignment = Enum.TextXAlignment.Right
	cooldownStatus.Parent = cooldownPanel

	local barBack = Instance.new("Frame")
	barBack.Name = "BarBack"
	barBack.Position = UDim2.fromOffset(12, 33)
	barBack.Size = UDim2.new(1, -24, 0, 9)
	barBack.BackgroundColor3 = Color3.fromRGB(35, 53, 66)
	barBack.BorderSizePixel = 0
	barBack.Parent = cooldownPanel

	local barBackCorner = Instance.new("UICorner")
	barBackCorner.CornerRadius = UDim.new(1, 0)
	barBackCorner.Parent = barBack

	cooldownFill = Instance.new("Frame")
	cooldownFill.Name = "Fill"
	cooldownFill.Size = UDim2.fromScale(1, 1)
	cooldownFill.BackgroundColor3 = Color3.fromRGB(95, 255, 170)
	cooldownFill.BorderSizePixel = 0
	cooldownFill.Parent = barBack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = cooldownFill
end

local function updateCooldownUi()
	ensureCooldownGui()

	local visible = canUsePrimary() and isPolarPush()
	cooldownGui.Enabled = visible
	if not visible then
		return
	end

	local remaining, duration = cooldownState()
	local ready = remaining <= 0
	local progress = if ready then 1 else math.clamp(1 - (remaining / duration), 0, 1)

	cooldownFill.Size = UDim2.fromScale(progress, 1)
	cooldownFill.BackgroundColor3 = if ready then Color3.fromRGB(95, 255, 170) else Color3.fromRGB(90, 190, 255)
	cooldownStatus.Text = if ready then "READY" else string.format("%.1fs", remaining)
	cooldownStatus.TextColor3 = if ready then Color3.fromRGB(95, 255, 170) else Color3.fromRGB(190, 235, 255)
	cooldownCaption.TextColor3 = if ready then Color3.fromRGB(235, 255, 245) else Color3.fromRGB(220, 240, 255)
end

local function primaryCoolingDown()
	if not isPolarPush() then
		return false
	end

	local remaining = cooldownState()
	return remaining > 0.03
end

local function firePrimary()
	if not primaryRemote or not canUsePrimary() then
		return
	end
	if primaryCoolingDown() then
		updateCooldownUi()
		return
	end

	local now = os.clock()
	if now - lastFireAt < 0.08 then
		return
	end
	lastFireAt = now

	primaryRemote:FireServer(localPlayer:GetAttribute("CurrentMinigame"))
	if isPolarPush() then
		predictedCooldownEndsAt = workspace:GetServerTimeNow() + POLAR_PUSH_COOLDOWN
		updateCooldownUi()
	end
end

local function handlePrimaryAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		firePrimary()
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

local function updateActionBinding()
	if canUsePrimary() and not actionBound then
		ContextActionService:BindAction(PRIMARY_ACTION, handlePrimaryAction, true, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonX)
		ContextActionService:SetTitle(PRIMARY_ACTION, "Hit")
		ContextActionService:SetPosition(PRIMARY_ACTION, UDim2.new(1, -118, 1, -112))
		actionBound = true
	elseif not canUsePrimary() and actionBound then
		ContextActionService:UnbindAction(PRIMARY_ACTION)
		actionBound = false
	end
	updateCooldownUi()
end

function PrimaryActionController:Init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local combat = remotes:WaitForChild("Combat")
	primaryRemote = combat:WaitForChild("PrimaryAction")
end

function PrimaryActionController:Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			firePrimary()
		end
	end)

	localPlayer:GetAttributeChangedSignal("AllowPrimaryAction"):Connect(updateActionBinding)
	localPlayer:GetAttributeChangedSignal("CurrentMinigame"):Connect(updateActionBinding)
	localPlayer:GetAttributeChangedSignal(COOLDOWN_END_ATTRIBUTE):Connect(updateCooldownUi)
	localPlayer:GetAttributeChangedSignal(COOLDOWN_DURATION_ATTRIBUTE):Connect(updateCooldownUi)
	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.2)
		updateActionBinding()
	end)
	RunService.RenderStepped:Connect(updateCooldownUi)
	updateActionBinding()
end

return PrimaryActionController
