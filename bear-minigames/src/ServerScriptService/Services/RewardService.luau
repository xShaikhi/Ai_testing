local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local RewardService = {}

local function ensureLeaderstats(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	local coins = stats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = stats
	end
	local wins = stats:FindFirstChild("Wins")
	if not wins then
		wins = Instance.new("IntValue")
		wins.Name = "Wins"
		wins.Parent = stats
	end
	return stats
end

function RewardService.init()
	Players.PlayerAdded:Connect(ensureLeaderstats)
	for _, player in ipairs(Players:GetPlayers()) do
		ensureLeaderstats(player)
	end
end

function RewardService.addCoins(player, amount)
	local stats = ensureLeaderstats(player)
	local coins = stats.Coins
	coins.Value = coins.Value + amount
	Remotes.get("CoinUpdate"):FireClient(player, coins.Value, amount)
end

function RewardService.addWin(player)
	local stats = ensureLeaderstats(player)
	stats.Wins.Value = stats.Wins.Value + 1
end

function RewardService.getCoins(player)
	local stats = ensureLeaderstats(player)
	return stats.Coins.Value
end

return RewardService
