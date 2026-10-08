-- Seagulls gliding over the beaches by day (local parts, moved in bulk).
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local M = {}

type Bird = { body: BasePart, left: BasePart, right: BasePart, center: Vector3, radius: number, height: number, speed: number, phase: number }

local function part(name: string, size: Vector3, color: Color3, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

function M.Start()
	local folder = Instance.new("Folder")
	folder.Name = "ParadiseBirds"
	folder.Parent = workspace
	local rng = Random.new(7)
	local birds: { Bird } = {}
	local spots = {
		Vector3.new(-260, 0, 200), Vector3.new(-260, 0, 560), Vector3.new(260, 0, 80), Vector3.new(0, 0, 900),
		Vector3.new(-120, 0, 980), Vector3.new(250, 0, 640), Vector3.new(-240, 0, -60), Vector3.new(120, 0, 640),
	}
	for i, c in ipairs(spots) do
		for k = 1, 2 do
			local b = part("Gull", Vector3.new(0.7, 0.6, 1.8), Color3.fromRGB(248, 248, 250), folder)
			local l = part("Wing", Vector3.new(2.4, 0.12, 0.9), Color3.fromRGB(226, 230, 236), folder)
			local r = part("Wing", Vector3.new(2.4, 0.12, 0.9), Color3.fromRGB(226, 230, 236), folder)
			table.insert(birds, {
				body = b, left = l, right = r, center = c + Vector3.new(rng:NextNumber(-30, 30), 0, rng:NextNumber(-30, 30)),
				radius = rng:NextNumber(26, 60), height = rng:NextNumber(38, 70), speed = rng:NextNumber(0.18, 0.32) * (if k == 1 then 1 else -1),
				phase = rng:NextNumber(0, math.pi * 2),
			})
		end
	end
	local parts: { BasePart } = {}
	local cfs: { CFrame } = {}
	local hidden = false
	RunService.Heartbeat:Connect(function()
		local c = Lighting.ClockTime
		local day = c > 6.2 and c < 19.2
		if not day then
			if not hidden then
				hidden = true
				for _, b in ipairs(birds) do
					b.body.Transparency, b.left.Transparency, b.right.Transparency = 1, 1, 1
				end
			end
			return
		elseif hidden then
			hidden = false
			for _, b in ipairs(birds) do
				b.body.Transparency, b.left.Transparency, b.right.Transparency = 0, 0, 0
			end
		end
		local t = os.clock()
		table.clear(parts)
		table.clear(cfs)
		for _, b in ipairs(birds) do
			local a = t * b.speed + b.phase
			local pos = b.center + Vector3.new(math.cos(a) * b.radius, b.height + math.sin(t * 0.6 + b.phase) * 3, math.sin(a) * b.radius)
			local dir = Vector3.new(-math.sin(a), 0, math.cos(a)) * math.sign(b.speed)
			local bank = CFrame.Angles(0, 0, -0.35 * math.sign(b.speed))
			local cf = CFrame.lookAt(pos, pos + dir) * bank
			local flap = math.sin(t * 7 + b.phase) * 0.45
			table.insert(parts, b.body)
			table.insert(cfs, cf)
			table.insert(parts, b.left)
			table.insert(cfs, cf * CFrame.new(-0.35, 0.1, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-1.2, 0, 0))
			table.insert(parts, b.right)
			table.insert(cfs, cf * CFrame.new(0.35, 0.1, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(1.2, 0, 0))
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return M
