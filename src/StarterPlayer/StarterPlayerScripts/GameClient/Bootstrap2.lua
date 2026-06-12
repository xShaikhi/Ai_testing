local clientFolder = script.Parent

local coreFolder = clientFolder:WaitForChild("Core")
local controllersFolder = clientFolder:WaitForChild("Controllers")

local controllerLoader = require(coreFolder:WaitForChild("ControllerLoader"))

controllerLoader.Start(controllersFolder)

print("[GameClient] Bootstrap started")
