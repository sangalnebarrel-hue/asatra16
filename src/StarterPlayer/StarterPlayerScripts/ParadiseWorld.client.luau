-- DOGROTS Paradise: client side of the island remaster.
-- Each module is started in its own thread so one failing feature never stops the others.
local modules = {
	"Motion", -- Ferris wheel, lighthouse beam, boats
	"Rides", -- zipline and water slide
	"Pads", -- jump pads and trampolines
	"Night", -- night lights and neon windows
	"Fireworks", -- night fireworks shows
	"Birds", -- seagulls over the beaches
	"Hud", -- toasts and the Golden Bone hunt counter
}

for _, name in ipairs(modules) do
	local module = script:WaitForChild(name, 10)
	if module then
		task.spawn(function()
			local ok, err = pcall(function()
				require(module).Start()
			end)
			if not ok then
				warn("[Paradise] " .. name .. " failed: " .. tostring(err))
			end
		end)
	else
		warn("[Paradise] missing module " .. name)
	end
end
print("DOGROTS_PARADISE_CLIENT_READY")
