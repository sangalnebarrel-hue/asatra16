-- Jump pads and trampolines: parts with a JumpPad attribute (upward speed, studs/s) and an
-- optional PadForward (speed along the pad's LookVector). Standing on one launches the local
-- character (client-owned physics, so it feels instant).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local M = {}
local player = Players.LocalPlayer
local pads: { [BasePart]: boolean } = {}
local cooldown = 0

local function add(o: Instance)
	if o:IsA("BasePart") and o:GetAttribute("JumpPad") then
		pads[o] = true
	end
end

local function burst(pad: BasePart)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, pad.Size.Y / 2, 0)
	a.Parent = pad
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(pad.Color:Lerp(Color3.new(1, 1, 1), 0.4))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(10, 18)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Rate = 0
	e.Parent = a
	e:Emit(24)
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/action_jump.mp3"
	s.Volume = 0.8
	s.PlaybackSpeed = 0.8
	s.Parent = a
	s:Play()
	task.delay(1.5, function()
		a:Destroy()
	end)
end

function M.Start()
	local map = workspace:WaitForChild("DOGROTS_District")
	for _, d in ipairs(map:GetDescendants()) do
		add(d)
	end
	map.DescendantAdded:Connect(add)
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or humanoid.Sit or os.clock() < cooldown then
			return
		end
		local pos = root.Position
		for pad in pairs(pads) do
			if not pad.Parent then
				pads[pad] = nil
				continue
			end
			local rel = pad.CFrame:PointToObjectSpace(pos)
			local half = pad.Size / 2
			if math.abs(rel.X) <= half.X + 0.6 and math.abs(rel.Z) <= half.Z + 0.6 and rel.Y > half.Y - 0.5 and rel.Y < half.Y + 4.2 then
				local up = tonumber(pad:GetAttribute("JumpPad")) or 90
				local forward = tonumber(pad:GetAttribute("PadForward")) or 0
				local v = root.AssemblyLinearVelocity
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				root.AssemblyLinearVelocity = Vector3.new(v.X * 0.4, up, v.Z * 0.4) + pad.CFrame.LookVector * forward
				cooldown = os.clock() + 0.7
				burst(pad)
				break
			end
		end
	end)
end

return M
