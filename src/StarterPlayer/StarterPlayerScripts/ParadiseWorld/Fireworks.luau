-- Night fireworks over the bay: every clear night a show of rockets bursts in colour over
-- the sea beside the Paw Pier and above the lagoon. Local effects only (no network traffic).
-- Shows are seeded from the server clock, so players see them at the same moments.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local M = {}

local SITES = {
	Vector3.new(-120, -4, 1010),
	Vector3.new(130, -4, 1000),
	Vector3.new(0, -4, 1150),
	Vector3.new(116, 0, 633),
	Vector3.new(-330, -4, 420),
	Vector3.new(330, -4, 120),
}
local COLORS = {
	Color3.fromRGB(255, 70, 160), Color3.fromRGB(60, 230, 255), Color3.fromRGB(255, 210, 70),
	Color3.fromRGB(150, 255, 110), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 120, 60),
	Color3.fromRGB(255, 255, 255),
}

local folder: Folder

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function rocket(origin: Vector3, apex: Vector3, color: Color3, second: Color3, rng: Random)
	local p = Instance.new("Part")
	p.Name = "Rocket"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = Vector3.new(0.6, 1.6, 0.6)
	p.Material = Enum.Material.Neon
	p.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
	p.CFrame = CFrame.new(origin)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.6, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.6, 0)
	a1.Parent = p
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.7
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 220, 160), color)
	trail.Transparency = seq(0.1, 1)
	trail.WidthScale = seq(1, 0.2)
	trail.Parent = p
	p.Parent = folder
	local duration = rng:NextNumber(1.3, 1.9)
	local started = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = math.clamp((os.clock() - started) / duration, 0, 1)
		local e = 1 - (1 - t) ^ 2
		p.CFrame = CFrame.new(origin:Lerp(apex, e))
		if t >= 1 then
			conn:Disconnect()
			p.Transparency = 1
			-- burst: big sphere of sparks, a ring of the second colour, a flash of light
			local burst = Instance.new("ParticleEmitter")
			burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			burst.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.3))
			burst.LightEmission = 1
			burst.LightInfluence = 0
			burst.Size = seq(2.2, 0.2)
			burst.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
			burst.Lifetime = NumberRange.new(1.4, 2.2)
			burst.Speed = NumberRange.new(38, 52)
			burst.SpreadAngle = Vector2.new(180, 180)
			burst.Drag = 2.2
			burst.Acceleration = Vector3.new(0, -14, 0)
			burst.Rate = 0
			burst.Parent = a0
			burst:Emit(rng:NextInteger(110, 160))
			local ring = burst:Clone()
			ring.Color = ColorSequence.new(second)
			ring.Speed = NumberRange.new(22, 26)
			ring.Size = seq(1.4, 0.1)
			ring.Parent = a0
			ring:Emit(60)
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 60
			light.Brightness = 6
			light.Shadows = false
			light.Parent = p
			task.spawn(function()
				for i = 1, 12 do
					light.Brightness = 6 * (1 - i / 12)
					task.wait(0.05)
				end
				light.Enabled = false
			end)
			local boom = Instance.new("Sound")
			boom.SoundId = "rbxasset://sounds/action_jump_land.mp3"
			boom.Volume = 0.5
			boom.PlaybackSpeed = rng:NextNumber(0.35, 0.55)
			boom.RollOffMaxDistance = 900
			boom.RollOffMinDistance = 60
			boom.Parent = p
			boom:Play()
			Debris:AddItem(p, 3.5)
		end
	end)
end

local function show(seed: number)
	local rng = Random.new(seed)
	local site = SITES[rng:NextInteger(1, #SITES)]
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - site).Magnitude > 1600 then
		return
	end
	local count = rng:NextInteger(10, 18)
	for i = 1, count do
		local c1 = COLORS[rng:NextInteger(1, #COLORS)]
		local c2 = COLORS[rng:NextInteger(1, #COLORS)]
		local origin = site + Vector3.new(rng:NextNumber(-30, 30), 0, rng:NextNumber(-30, 30))
		local apex = origin + Vector3.new(rng:NextNumber(-25, 25), rng:NextNumber(90, 150), rng:NextNumber(-25, 25))
		rocket(origin, apex, c1, c2, rng)
		task.wait(rng:NextNumber(0.15, 0.7))
	end
	-- finale: a volley
	task.wait(0.8)
	for i = 1, 6 do
		local origin = site + Vector3.new(-40 + i * 13, 0, 0)
		rocket(origin, origin + Vector3.new(0, 140, 0), COLORS[(i % #COLORS) + 1], Color3.new(1, 1, 1), rng)
	end
end

function M.Start()
	folder = Instance.new("Folder")
	folder.Name = "ParadiseFireworks"
	folder.Parent = workspace
	local state = ReplicatedStorage:WaitForChild("WorldEvents"):WaitForChild("State")
	local PERIOD = 55
	local lastSlot = -1
	while true do
		task.wait(1)
		local c = Lighting.ClockTime
		local night = c >= 19.6 or c < 4.8
		local quiet = state:GetAttribute("State") == nil or state:GetAttribute("State") == "NORMAL"
		local slot = math.floor(workspace:GetServerTimeNow() / PERIOD)
		if night and quiet and slot ~= lastSlot then
			lastSlot = slot
			task.spawn(show, slot)
		end
	end
end

return M
