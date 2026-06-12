local ControllerLoader = {}

function ControllerLoader.Start(controllersFolder)
	for _, module in ipairs(controllersFolder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local ok, controller = pcall(require, module)

			if not ok then
				warn("[ControllerLoader] Failed to require " .. module.Name .. ": " .. tostring(controller))
				continue
			end

			if type(controller) == "table" and type(controller.Start) == "function" then
				local startOk, startErr = pcall(function()
					controller.Start()
				end)

				if not startOk then
					warn("[ControllerLoader] Failed to start " .. module.Name .. ": " .. tostring(startErr))
				else
					print("[ControllerLoader] Started " .. module.Name)
				end
			end
		end
	end
end

return ControllerLoader
