local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BearHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function label(name, props)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 0.35
	l.BackgroundColor3 = Color3.fromRGB(25, 30, 25)
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	for key, value in pairs(props) do
		l[key] = value
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = l
	l.Parent = screenGui
	return l
end

local timerLabel = label("Timer", {
	Size = UDim2.fromOffset(160, 44),
	Position = UDim2.new(0.5, -80, 0, 10),
	Text = "",
})

local stateLabel = label("State", {
	Size = UDim2.fromOffset(280, 30),
	Position = UDim2.new(0.5, -140, 0, 58),
	Text = "Waiting for players...",
	TextColor3 = Color3.fromRGB(255, 220, 150),
})

local objectiveLabel = label("Objective", {
	Size = UDim2.fromOffset(260, 34),
	Position = UDim2.new(0.5, -130, 0, 92),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 196, 50),
})
objectiveLabel.Visible = false

local coinLabel = label("Coins", {
	Size = UDim2.fromOffset(140, 36),
	Position = UDim2.new(1, -150, 0, 10),
	Text = "Coins: 0",
	TextColor3 = Color3.fromRGB(255, 220, 90),
})

local warningLabel = label("BearWarning", {
	Size = UDim2.fromOffset(240, 40),
	Position = UDim2.new(0.5, -120, 0.78, 0),
	Text = "BEAR NEARBY!",
	BackgroundColor3 = Color3.fromRGB(120, 20, 20),
	TextColor3 = Color3.fromRGB(255, 90, 70),
})
warningLabel.Visible = false

local resultFrame = Instance.new("Frame")
resultFrame.Name = "Result"
resultFrame.Size = UDim2.fromOffset(340, 150)
resultFrame.Position = UDim2.new(0.5, -170, 0.35, 0)
resultFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 25)
resultFrame.BackgroundTransparency = 0.15
resultFrame.Visible = false
resultFrame.Parent = screenGui
local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 12)
resultCorner.Parent = resultFrame

local resultTitle = Instance.new("TextLabel")
resultTitle.Size = UDim2.new(1, 0, 0, 56)
resultTitle.BackgroundTransparency = 1
resultTitle.Font = Enum.Font.Bangers
resultTitle.TextScaled = true
resultTitle.Parent = resultFrame

local resultBody = Instance.new("TextLabel")
resultBody.Size = UDim2.new(1, -20, 0, 80)
resultBody.Position = UDim2.fromOffset(10, 60)
resultBody.BackgroundTransparency = 1
resultBody.Font = Enum.Font.Gotham
resultBody.TextWrapped = true
resultBody.TextSize = 18
resultBody.TextColor3 = Color3.fromRGB(230, 230, 230)
resultBody.Parent = resultFrame

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

Remotes.get("Timer").OnClientEvent:Connect(function(remaining, context)
	timerLabel.Text = formatTime(remaining)
	if remaining <= 10 and remaining > 0 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 90, 70)
	else
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

Remotes.get("RoundState").OnClientEvent:Connect(function(state, detail)
	if state == "WaitingForPlayers" then
		stateLabel.Text = "Waiting for players..."
	elseif state == "Intermission" then
		stateLabel.Text = "Intermission"
		resultFrame.Visible = false
		objectiveLabel.Visible = false
		warningLabel.Visible = false
	elseif state == "Loading" then
		stateLabel.Text = "Loading: " .. tostring(detail)
	elseif state == "InRound" then
		stateLabel.Text = tostring(detail)
	elseif state == "RoundOver" then
		stateLabel.Text = "Round over"
		objectiveLabel.Visible = false
		warningLabel.Visible = false
	end
end)

Remotes.get("Objective").OnClientEvent:Connect(function(name, current, goal)
	objectiveLabel.Visible = true
	objectiveLabel.Text = name .. ": " .. current .. " / " .. goal
	local tween = TweenService:Create(
		objectiveLabel,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ TextColor3 = Color3.fromRGB(255, 255, 255) }
	)
	tween:Play()
end)

Remotes.get("BearWarning").OnClientEvent:Connect(function(nearby)
	warningLabel.Visible = nearby and true or false
end)

Remotes.get("CoinUpdate").OnClientEvent:Connect(function(total, delta)
	coinLabel.Text = "Coins: " .. tostring(total)
end)

Remotes.get("ResultScreen").OnClientEvent:Connect(function(won, coinsEarned, summary)
	resultFrame.Visible = true
	if won then
		resultTitle.Text = "YOU SURVIVED!"
		resultTitle.TextColor3 = Color3.fromRGB(120, 255, 140)
	else
		resultTitle.Text = "CAUGHT BY THE BEAR"
		resultTitle.TextColor3 = Color3.fromRGB(255, 90, 70)
	end
	resultBody.Text = (summary and (summary .. "\n") or "") .. "+" .. tostring(coinsEarned) .. " coins"
end)
