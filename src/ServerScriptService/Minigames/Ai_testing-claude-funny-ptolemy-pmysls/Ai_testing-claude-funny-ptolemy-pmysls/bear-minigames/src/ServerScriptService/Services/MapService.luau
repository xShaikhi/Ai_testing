local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MapService = {}

local activeMap = nil

local function getActiveFolder()
	return Workspace:WaitForChild("ActiveMap")
end

function MapService.load(mapName)
	MapService.cleanup()
	local maps = ServerStorage:WaitForChild("Maps")
	local template = maps:FindFirstChild(mapName)
	if not template then
		warn("MapService: no map named " .. tostring(mapName))
		return nil
	end
	activeMap = template:Clone()
	activeMap.Parent = getActiveFolder()
	return activeMap
end

function MapService.getActive()
	return activeMap
end

function MapService.cleanup()
	if activeMap then
		activeMap:Destroy()
		activeMap = nil
	end
	getActiveFolder():ClearAllChildren()
end

function MapService.getMarkers(markerName)
	local result = {}
	if activeMap then
		for _, descendant in ipairs(activeMap:GetDescendants()) do
			if descendant.Name == markerName and descendant:IsA("BasePart") then
				table.insert(result, descendant)
			end
		end
	end
	return result
end

function MapService.teleportToMarkers(players, markerName)
	local markers = MapService.getMarkers(markerName)
	if #markers == 0 then
		warn("MapService: no markers named " .. tostring(markerName))
		return
	end
	for i, player in ipairs(players) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local marker = markers[((i - 1) % #markers) + 1]
			root.CFrame = marker.CFrame + Vector3.new(0, 4, 0)
		end
	end
end

function MapService.teleportToLobby(players, lobbyCFrame)
	for i, player in ipairs(players) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local angle = (i / 8) * math.pi * 2
			root.CFrame = lobbyCFrame + Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
		end
	end
end

return MapService
