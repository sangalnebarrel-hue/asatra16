-- Ziplines and water slides: models with RideTrack = "Zipline" | "Slide", a Path attribute
-- ("x,y,z;x,y,z;...") and Speed. A ProximityPrompt named RidePrompt inside starts the ride.
-- The local character is carried along the path (the server sees it through normal
-- character replication). Press jump on a zipline to let go; on a slide jumping ends the ride.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local M = {}
local player = Players.LocalPlayer
local busy = false

local function parsePath(text: any): { Vector3 }
	local out = {}
	if type(text) ~= "string" then
		return out
	end
	for x, y, z in string.gmatch(text, "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
		table.insert(out, Vector3.new(tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number))
	end
	return out
end

local function splash(at: Vector3)
	local p = Instance.new("Part")
	p.Name = "ParadiseSplash"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(at)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(235, 250, 255))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Speed = NumberRange.new(12, 22)
	e.SpreadAngle = Vector2.new(35, 35)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(40)
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/impact_water.mp3"
	s.Volume = 0.7
	s.Parent = p
	s:Play()
	Debris:AddItem(p, 3)
end

local function ride(track: Instance)
	if busy then
		return
	end
	local kind = track:GetAttribute("RideTrack")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or humanoid.Sit then
		return
	end
	local pts = parsePath(track:GetAttribute("Path"))
	if #pts < 2 or (root.Position - pts[1]).Magnitude > 22 then
		return
	end
	busy = true
	local speed = tonumber(track:GetAttribute("Speed")) or 50
	local cum = { 0 }
	for i = 2, #pts do
		cum[i] = cum[i - 1] + (pts[i] - pts[i - 1]).Magnitude
	end
	local total = cum[#pts]
	local zipline = kind == "Zipline"
	local offset = if zipline then Vector3.new(0, -3.6, 0) else Vector3.new(0, 2.3, 0)
	if zipline then
		humanoid.PlatformStand = true
	else
		humanoid.Sit = true
	end
	-- a trolley handle on the cable, local only
	local handle
	if zipline then
		handle = Instance.new("Part")
		handle.Name = "ZipHandle"
		handle.Anchored = true
		handle.CanCollide = false
		handle.CanQuery = false
		handle.CanTouch = false
		handle.Size = Vector3.new(0.5, 3.4, 2.2)
		handle.Color = Color3.fromRGB(232, 184, 82)
		handle.Material = Enum.Material.Metal
		handle.Parent = workspace
	end
	local dist, seg = 0, 1
	local finished = false
	local conn: RBXScriptConnection
	local sitConn: RBXScriptConnection?
	local function finish(exitVelocity: Vector3?)
		if finished then
			return
		end
		finished = true
		conn:Disconnect()
		if sitConn then
			sitConn:Disconnect()
		end
		if handle then
			handle:Destroy()
		end
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		if exitVelocity and root.Parent then
			root.AssemblyLinearVelocity = exitVelocity
		end
		task.delay(0.6, function()
			busy = false
		end)
	end
	if not zipline then
		sitConn = humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
			if not humanoid.Sit and dist > 4 then
				finish(nil)
			end
		end)
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		if not root.Parent or humanoid.Health <= 0 or not character:IsDescendantOf(workspace) then
			finish(nil)
			return
		end
		local v = speed
		if zipline then
			v = speed * math.clamp(0.35 + dist / 60, 0.35, 1)
			if humanoid.Jump and dist > 6 then
				finish((pts[math.min(seg + 1, #pts)] - pts[seg]).Unit * v * 0.6)
				return
			end
		end
		dist += v * math.min(dt, 0.1)
		if dist >= total then
			local last = (pts[#pts] - pts[#pts - 1]).Unit
			if not zipline then
				splash(pts[#pts])
			end
			finish(last * v * (if zipline then 0.25 else 0.6) + Vector3.new(0, if zipline then 4 else 14, 0))
			return
		end
		while seg < #pts - 1 and cum[seg + 1] < dist do
			seg += 1
		end
		local a, b = pts[seg], pts[seg + 1]
		local t = (dist - cum[seg]) / math.max(cum[seg + 1] - cum[seg], 1e-3)
		local p = a:Lerp(b, t)
		local dir = (b - a).Unit
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude < 1e-3 then
			flat = root.CFrame.LookVector
		end
		local at = p + offset
		root.CFrame = CFrame.lookAt(at, at + flat.Unit)
		root.AssemblyLinearVelocity = dir * v
		if handle then
			handle.CFrame = CFrame.lookAt(p + Vector3.new(0, -1.2, 0), p + Vector3.new(0, -1.2, 0) + flat.Unit)
		end
	end)
end

function M.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= player or prompt.Name ~= "RidePrompt" then
			return
		end
		local track = prompt:FindFirstAncestorWhichIsA("Model")
		while track and not track:GetAttribute("RideTrack") do
			track = track.Parent and track.Parent:FindFirstAncestorWhichIsA("Model")
		end
		if track then
			ride(track)
		end
	end)
	player.CharacterAdded:Connect(function()
		busy = false
	end)
end

return M
