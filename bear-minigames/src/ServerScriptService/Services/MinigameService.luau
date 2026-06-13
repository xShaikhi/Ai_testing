local MinigameService = {}

local rng = Random.new()

local function getMinigames()
	local result = {}
	local folder = script.Parent:FindFirstChild("Minigames")
	if folder then
		for _, module in ipairs(folder:GetChildren()) do
			if module:IsA("ModuleScript") then
				table.insert(result, require(module))
			end
		end
	end
	return result
end

function MinigameService.pick()
	local minigames = getMinigames()
	if #minigames == 0 then
		return nil
	end
	return minigames[rng:NextInteger(1, #minigames)]
end

return MinigameService
