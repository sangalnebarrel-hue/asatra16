-- Local animation of the Paradise landmarks (every client computes the same pose from the
-- server clock, so everyone sees the same wheel position):
--   Motion = "FerrisWheel"    model spins around its pivot's Z axis (AngularSpeed rad/s)
--   Motion = "Gondola"        orbits Hub (Vector3) around world Z at AngularSpeed, staying level
--   Motion = "LighthouseBeam" spins around Y
--   Motion = "Bob"            moored boat: gentle roll and heave (Phase)
--   Motion = "Cruise"         sails a circle around Center at Radius (Speed studs/s, Phase)
--   Motion = "Spin"           turns around Y and floats up and down (Golden Bones)
-- Parts are moved with BulkMoveTo from their rest offsets; streamed-in parts join on the fly.
local RunService = game:GetService("RunService")

local M = {}

type Rig = {
	model: Model,
	kind: string,
	rest: CFrame,
	parts: { BasePart },
	offsets: { CFrame },
	index: { [BasePart]: number },
	speed: number,
	phase: number,
	radius: number,
	center: Vector3,
}

local rigs: { [Model]: Rig } = {}
local KINDS = { FerrisWheel = true, Gondola = true, LighthouseBeam = true, Bob = true, Cruise = true, Spin = true }
-- beyond `far` studs a rig updates every third frame, beyond `stop` it holds still
local RANGE = {
	FerrisWheel = { far = 450, stop = 2600 },
	Gondola = { far = 450, stop = 2600 },
	LighthouseBeam = { far = 500, stop = 2600 },
	Cruise = { far = 600, stop = 3000 },
	Bob = { far = 250, stop = 700 },
	Spin = { far = 120, stop = 320 },
}

local function collect(model: Instance, rest: CFrame, parts: { BasePart }, offsets: { CFrame }, index: { [BasePart]: number }?)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and (not index or not index[d]) then
			table.insert(parts, d)
			table.insert(offsets, rest:ToObjectSpace(d.CFrame))
			if index then
				index[d] = #parts
			end
		end
	end
end

local function register(model: Instance)
	if not model:IsA("Model") or rigs[model] then
		return
	end
	local kind = model:GetAttribute("Motion")
	if type(kind) ~= "string" or not KINDS[kind] then
		return
	end
	local rest = model:GetPivot()
	local rig: Rig = {
		model = model,
		kind = kind,
		rest = rest,
		parts = {},
		offsets = {},
		index = {},
		speed = tonumber(model:GetAttribute("AngularSpeed") or model:GetAttribute("Speed")) or 0.1,
		phase = tonumber(model:GetAttribute("Phase")) or 0,
		radius = tonumber(model:GetAttribute("Radius")) or 0,
		center = (model:GetAttribute("Center") :: Vector3?) or (model:GetAttribute("Hub") :: Vector3?) or rest.Position,
	}
	collect(model, rest, rig.parts, rig.offsets, rig.index)
	rigs[model] = rig
	-- parts that stream in later join with their rest offset
	model.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and not rig.index[d] then
			table.insert(rig.parts, d)
			table.insert(rig.offsets, rig.rest:ToObjectSpace(d.CFrame))
			rig.index[d] = #rig.parts
		end
	end)
end

local function poseOf(rig: Rig, t: number): CFrame
	local k = rig.kind
	if k == "FerrisWheel" then
		return rig.rest * CFrame.Angles(0, 0, (t * rig.speed) % (2 * math.pi))
	elseif k == "Gondola" then
		local a = (t * rig.speed) % (2 * math.pi)
		local center = rig.center + CFrame.Angles(0, 0, a):VectorToWorldSpace(rig.rest.Position - rig.center)
		return CFrame.new(center) * rig.rest.Rotation
	elseif k == "LighthouseBeam" then
		return rig.rest * CFrame.Angles(0, (t * rig.speed) % (2 * math.pi), 0)
	elseif k == "Spin" then
		return rig.rest * CFrame.new(0, math.sin(t * 2 + rig.phase) * 0.6, 0) * CFrame.Angles(0, (t * rig.speed) % (2 * math.pi), 0)
	elseif k == "Bob" then
		local p = rig.phase
		return rig.rest * CFrame.new(0, math.sin(t * 0.9 + p) * 0.35, 0) * CFrame.Angles(math.sin(t * 0.7 + p) * 0.04, 0, math.sin(t * 0.8 + p * 2) * 0.06)
	elseif k == "Cruise" then
		-- angle along the circle; the boat faces its direction of travel
		local w = rig.speed / math.max(rig.radius, 1)
		local a = t * w + rig.phase
		local c = rig.center
		local pos = Vector3.new(c.X + math.cos(a) * rig.radius, rig.rest.Position.Y + math.sin(t * 0.9 + rig.phase) * 0.3, c.Z + math.sin(a) * rig.radius)
		local dir = Vector3.new(-math.sin(a), 0, math.cos(a))
		return CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, 0, math.sin(t * 0.8 + rig.phase) * 0.07)
	end
	return rig.rest
end

local partsBuf: { BasePart } = {}
local cfBuf: { CFrame } = {}

local function push(part: BasePart, cf: CFrame)
	if part.Parent then
		table.insert(partsBuf, part)
		table.insert(cfBuf, cf)
	end
end

function M.Start()
	local map = workspace:WaitForChild("DOGROTS_District")
	for _, d in ipairs(map:GetDescendants()) do
		register(d)
	end
	map.DescendantAdded:Connect(function(d)
		if d:IsA("Model") and d:GetAttribute("Motion") then
			task.defer(register, d)
		end
	end)
	local frame = 0
	RunService.Heartbeat:Connect(function()
		frame += 1
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local eye = camera.CFrame.Position
		local t = workspace:GetServerTimeNow()
		table.clear(partsBuf)
		table.clear(cfBuf)
		for model, rig in pairs(rigs) do
			if not model.Parent then
				rigs[model] = nil
				continue
			end
			local range = RANGE[rig.kind]
			local dist = if rig.kind == "Cruise" then (rig.center - eye).Magnitude - rig.radius else (rig.rest.Position - eye).Magnitude
			-- far away: update less often (still visible on the horizon), or not at all
			if dist > range.stop or (dist > range.far and frame % 3 ~= 0) then
				continue
			end
			local pose = poseOf(rig, t)
			for i, part in ipairs(rig.parts) do
				push(part, pose * rig.offsets[i])
			end
		end
		if #partsBuf > 0 then
			workspace:BulkMoveTo(partsBuf, cfBuf, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return M
