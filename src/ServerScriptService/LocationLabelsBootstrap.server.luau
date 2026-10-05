-- Reuses the six authored Workspace labels; never creates per-character copies.
local config = game:GetService("ReplicatedStorage"):WaitForChild("WorldSignConfig")
require(config:WaitForChild("LocationLabels")).Apply()
