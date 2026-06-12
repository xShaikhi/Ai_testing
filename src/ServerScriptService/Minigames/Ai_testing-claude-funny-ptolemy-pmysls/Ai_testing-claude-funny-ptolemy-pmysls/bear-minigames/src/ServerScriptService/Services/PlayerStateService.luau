local Players = game:GetService("Players")

local PlayerStateService = {}

local states = {}
local deathConnections = {}

PlayerStateService.LOBBY = "Lobby"
PlayerStateService.ALIVE = "Alive"
PlayerStateService.CAUGHT = "Caught"
PlayerStateService.ESCAPED = "Escaped"

function PlayerStateService.init()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		if deathConnections[player] then
			deathConnections[player]:Disconnect()
			deathConnections[player] = nil
		end
	end)
end

function PlayerStateService.set(player, state)
	states[player] = state
end

function PlayerStateService.get(player)
	return states[player] or PlayerStateService.LOBBY
end

function PlayerStateService.setAll(state)
	for _, player in ipairs(Players:GetPlayers()) do
		states[player] = state
	end
end

function PlayerStateService.getWithState(state)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerStateService.get(player) == state then
			table.insert(result, player)
		end
	end
	return result
end

function PlayerStateService.getAlive()
	return PlayerStateService.getWithState(PlayerStateService.ALIVE)
end

function PlayerStateService.watchDeaths()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if deathConnections[player] then
				deathConnections[player]:Disconnect()
			end
			deathConnections[player] = humanoid.Died:Connect(function()
				if PlayerStateService.get(player) == PlayerStateService.ALIVE then
					PlayerStateService.set(player, PlayerStateService.CAUGHT)
				end
			end)
		end
	end
end

function PlayerStateService.stopWatching()
	for player, connection in pairs(deathConnections) do
		connection:Disconnect()
		deathConnections[player] = nil
	end
end

return PlayerStateService
