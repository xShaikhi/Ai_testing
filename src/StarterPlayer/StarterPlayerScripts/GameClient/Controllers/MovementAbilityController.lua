local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage:WaitForChild("GameShared"):WaitForChild("Configs"):WaitForChild("MovementConfig"))

local MovementAbilityController = {}

local localPlayer = Players.LocalPlayer
local proneRemote = nil
local proneHeld = false
local lastSentAt = 0
local lastSentState = nil
local actionBound = false
local PRONE_ACTION = "CrashBashProne"

local function getHumanoid()
	local character = localPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function canUseProne()
	return localPlayer:GetAttribute("AllowProne") == true
end

local function applyLocalProne(enabled)
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	if enabled then
		humanoid.CameraOffset = MovementConfig.Prone.ClientCameraOffset
	else
		humanoid.CameraOffset = Vector3.zero
	end
end

local function sendProne(enabled)
	if not proneRemote then
		return
	end

	if enabled and not canUseProne() then
		enabled = false
	end

	local now = os.clock()
	if lastSentState == enabled and now - lastSentAt < MovementConfig.Prone.Cooldown then
		return
	end

	lastSentAt = now
	lastSentState = enabled
	applyLocalProne(enabled)
	proneRemote:FireServer(enabled)
end

local function setProneHeld(enabled)
	proneHeld = enabled == true
	sendProne(proneHeld)
end

local function handleProneAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		setProneHeld(true)
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		setProneHeld(false)
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

local function updateActionBinding()
	if canUseProne() and not actionBound then
		ContextActionService:BindAction(PRONE_ACTION, handleProneAction, true, table.unpack(MovementConfig.Prone.KeyCodes))
		ContextActionService:SetTitle(PRONE_ACTION, "Crouch")
		ContextActionService:SetPosition(PRONE_ACTION, UDim2.new(1, -128, 1, -184))
		actionBound = true
	elseif not canUseProne() and actionBound then
		ContextActionService:UnbindAction(PRONE_ACTION)
		actionBound = false
	end
end

function MovementAbilityController:Init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local movement = remotes:WaitForChild("Movement")
	proneRemote = movement:WaitForChild("SetProne")
end

function MovementAbilityController:Start()
	-- Crouch/prone is bound to the keys in MovementConfig (C / LeftControl / ButtonB)
	-- via ContextActionService in updateActionBinding(). Mouse buttons are intentionally
	-- left free so left-click stays a clean "action" (e.g. punch) and never fights the camera.
	localPlayer:GetAttributeChangedSignal("AllowProne"):Connect(function()
		updateActionBinding()
		if not canUseProne() then
			proneHeld = false
			sendProne(false)
		elseif proneHeld then
			sendProne(true)
		end
	end)

	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.2)
		updateActionBinding()
		if proneHeld and canUseProne() then
			sendProne(true)
		else
			applyLocalProne(false)
		end
	end)

	updateActionBinding()
end

return MovementAbilityController
