local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementAbilityController = {}

local player = Players.LocalPlayer

local setProneRemote = nil

local PRONE_KEYS = {
	[Enum.KeyCode.C] = true,
	[Enum.KeyCode.LeftControl] = true,
}

local function getSetProneRemote()
	if setProneRemote then
		return setProneRemote
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
	if not remotes then
		warn("[MovementAbilityController] ReplicatedStorage.Remotes was not found")
		return nil
	end

	local movement = remotes:WaitForChild("Movement", 20)
	if not movement then
		warn("[MovementAbilityController] ReplicatedStorage.Remotes.Movement was not found")
		return nil
	end

	setProneRemote = movement:WaitForChild("SetProne", 20)
	if not setProneRemote then
		warn("[MovementAbilityController] SetProne RemoteEvent was not found")
		return nil
	end

	return setProneRemote
end

local function setProne(enabled)
	if UserInputService:GetFocusedTextBox() then
		return
	end

	if enabled and player:GetAttribute("AllowProne") ~= true then
		enabled = false
	end

	local remote = getSetProneRemote()
	if not remote then
		return
	end

	remote:FireServer(enabled)
end

function MovementAbilityController.Start()
	getSetProneRemote()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end

		if PRONE_KEYS[input.KeyCode] then
			setProne(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if PRONE_KEYS[input.KeyCode] then
			setProne(false)
		end
	end)

	print("[MovementAbilityController] Ready")
end

return MovementAbilityController
