local ControllerLoader = {}

function ControllerLoader.load(folder)
	local controllers = {}
	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local controller = require(module)
			controller.Name = controller.Name or module.Name
			table.insert(controllers, controller)
		end
	end

	table.sort(controllers, function(left, right)
		return left.Name < right.Name
	end)

	for _, controller in ipairs(controllers) do
		if type(controller.Init) == "function" then
			controller:Init()
		end
	end

	for _, controller in ipairs(controllers) do
		if type(controller.Start) == "function" then
			task.spawn(function()
				controller:Start()
			end)
		end
	end

	return controllers
end

return ControllerLoader
