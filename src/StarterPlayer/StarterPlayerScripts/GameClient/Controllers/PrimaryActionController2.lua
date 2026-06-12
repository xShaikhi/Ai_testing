local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PrimaryActionController = {}

local player = Players.LocalPlayer

local debounce = false
local DEBOUNCE_TIME = 0.08

local primaryActionRemote = nil

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

	print("[PrimaryActionController] Firing PrimaryAction for:", currentMinigame)
	remote:FireServer(currentMinigame)

	task.delay(DEBOUNCE_TIME, function()
		debounce = false
	end)
end

function PrimaryActionController.Start()
	getPrimaryActionRemote()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end

		if ACTION_KEYS[input.KeyCode] or ACTION_MOUSE[input.UserInputType] then
			firePrimaryAction()
		end
	end)

	print("[PrimaryActionController] Ready")
end

return PrimaryActionController
