local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

ensureFolder(Workspace, "Lobby")
ensureFolder(Workspace, "ActiveMap")
local maps = ensureFolder(ServerStorage, "Maps")
local npcs = ensureFolder(ServerStorage, "NPCs")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
require(Shared:WaitForChild("Remotes"))

local builders = script.Parent:FindFirstChild("Builders")
if builders then
	local lobbyBuilder = builders:FindFirstChild("LobbyBuilder")
	if lobbyBuilder then
		require(lobbyBuilder).build(Workspace.Lobby)
	end
	local honeyMapBuilder = builders:FindFirstChild("HoneyHuntMapBuilder")
	if honeyMapBuilder then
		require(honeyMapBuilder).build(maps)
	end
	local bearBuilder = builders:FindFirstChild("BearRigBuilder")
	if bearBuilder then
		require(bearBuilder).build(npcs)
	end
end

local services = script.Parent:FindFirstChild("Services")
if services then
	local roundService = services:FindFirstChild("RoundService")
	if roundService then
		require(roundService).start()
	end
end
