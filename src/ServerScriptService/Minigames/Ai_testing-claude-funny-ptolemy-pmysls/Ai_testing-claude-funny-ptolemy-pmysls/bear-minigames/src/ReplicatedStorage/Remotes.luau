local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "BearRemotes"

local REMOTE_NAMES = {
	"RoundState",
	"Timer",
	"Objective",
	"BearWarning",
	"CoinUpdate",
	"ResultScreen",
}

local Remotes = {}

local function getFolder()
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
			for _, name in ipairs(REMOTE_NAMES) do
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = folder
			end
		end
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

function Remotes.get(name)
	local folder = getFolder()
	if RunService:IsServer() then
		return folder:FindFirstChild(name)
	end
	return folder:WaitForChild(name)
end

return Remotes
