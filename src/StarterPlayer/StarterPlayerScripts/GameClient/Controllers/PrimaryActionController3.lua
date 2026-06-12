local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PrimaryActionController = {}

local player = Players.LocalPlayer

local debounce = false
local DEBOUNCE_TIME = 0.08

local primaryActionRemote = nil
local cooldownGui = nil
local cooldownFill = nil
local cooldownText = nil

local ACTION_KEYS = {
	[Enum.KeyCode.One] = true,
	[Enum.KeyCode.F] = true,
}

local ACTION_MOUSE = {
	[Enum.UserInputType.MouseButton1] = true,
}

local function getPrimaryActionRemote()
	if primaryActionRemote then
		return primaryActionRemote
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
	if not remotes then
		warn("[PrimaryActionController] ReplicatedStorage.Remotes was not found")
		return nil
	end

	local combat = remotes:WaitForChild("Combat", 20)
	if not combat then
		warn("[PrimaryActionController] ReplicatedStorage.Remotes.Combat was not found")
		return nil
	end

	primaryActionRemote = combat:WaitForChild("PrimaryAction", 20)
	if not primaryActionRemote then
		warn("[PrimaryActionController] PrimaryAction RemoteEvent was not found")
		return nil
	end

	return primaryActionRemote
end

local function createCooldownUi()
	if cooldownGui then
		return
	end

	local playerGui = player:WaitForChild("PlayerGui")

	cooldownGui = Instance.new("ScreenGui")
	cooldownGui.Name = "PrimaryActionCooldownGui"
	cooldownGui.ResetOnSpawn = false
	cooldownGui.IgnoreGuiInset = true
	cooldownGui.Enabled = false
	cooldownGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "CooldownFrame"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.fromScale(0.5, 0.93)
	frame.Size = UDim2.fromOffset(260, 28)
	frame.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = cooldownGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(90, 230, 255)
	stroke.Transparency = 0.15
	stroke.Parent = frame

	cooldownFill = Instance.new("Frame")
	cooldownFill.Name = "Fill"
	cooldownFill.Size = UDim2.fromScale(1, 1)
	cooldownFill.BackgroundColor3 = Color3.fromRGB(65, 220, 255)
	cooldownFill.BorderSizePixel = 0
	cooldownFill.Parent = frame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 10)
	fillCorner.Parent = cooldownFill

	cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.BackgroundTransparency = 1
	cooldownText.Size = UDim2.fromScale(1, 1)
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.TextScaled = true
	cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownText.Text = "PUSH READY"
	cooldownText.Parent = frame
end

local function canUsePrimaryAction()
	local currentMinigame = player:GetAttribute("CurrentMinigame")
	local allowPrimaryAction = player:GetAttribute("AllowPrimaryAction")

	if allowPrimaryAction ~= true then
		return false
	end

	return currentMinigame == "Arena Brawl"
		or currentMinigame == "Polar Push"
end

local function firePrimaryAction()
	if debounce then
		return
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end

	local currentMinigame = player:GetAttribute("CurrentMinigame")
	if not canUsePrimaryAction() then
		return
	end

	local remote = getPrimaryActionRemote()
	if not remote then
		return
	end

	debounce = true
	remote:FireServer(currentMinigame)

	task.delay(DEBOUNCE_TIME, function()
		debounce = false
	end)
end

local function updateCooldownUi()
	createCooldownUi()

	local currentMinigame = player:GetAttribute("CurrentMinigame")
	local allowPrimaryAction = player:GetAttribute("AllowPrimaryAction")

	if currentMinigame ~= "Polar Push" or allowPrimaryAction ~= true then
		cooldownGui.Enabled = false
		return
	end

	cooldownGui.Enabled = true

	local endsAt = player:GetAttribute("PrimaryActionCooldownEndsAt")
	local duration = player:GetAttribute("PrimaryActionCooldownDuration") or 2

	if typeof(endsAt) ~= "number" or endsAt <= 0 then
		cooldownFill.Size = UDim2.fromScale(1, 1)
		cooldownText.Text = "PUSH READY"
		return
	end

	local now = workspace:GetServerTimeNow()
	local remaining = math.max(0, endsAt - now)

	if remaining <= 0 then
		cooldownFill.Size = UDim2.fromScale(1, 1)
		cooldownText.Text = "PUSH READY"
	else
		local readyRatio = math.clamp(1 - remaining / math.max(duration, 0.01), 0, 1)
		cooldownFill.Size = UDim2.fromScale(readyRatio, 1)
		cooldownText.Text = string.format("PUSH %.1fs", remaining)
	end
end

function PrimaryActionController.Start()
	createCooldownUi()
	getPrimaryActionRemote()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end

		if ACTION_KEYS[input.KeyCode] or ACTION_MOUSE[input.UserInputType] then
			firePrimaryAction()
		end
	end)

	RunService.RenderStepped:Connect(updateCooldownUi)

	print("[PrimaryActionController] Ready")
end

return PrimaryActionController
