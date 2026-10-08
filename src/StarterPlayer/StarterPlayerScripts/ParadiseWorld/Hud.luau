-- Paradise HUD: toasts for rewards and the Golden Bone hunt counter. Found bones are hidden
-- for this player only (LocalTransparencyModifier, glow removed locally); the rest keep
-- spinning for everyone else.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local M = {}
local player = Players.LocalPlayer
local found: { [string]: boolean } = {}
local total = 0
local counter: TextLabel
local toastLabel: TextLabel
local toastStroke: UIStroke
local toastSerial = 0

local function short(n: number): string
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

local function toast(text: string, color: Color3?)
	toastSerial += 1
	local serial = toastSerial
	toastLabel.Text = text
	toastLabel.TextColor3 = color or Color3.fromRGB(255, 240, 200)
	toastLabel.Visible = true
	toastLabel.TextTransparency = 1
	toastStroke.Transparency = 1
	toastLabel.Position = UDim2.new(0.5, 0, 0, 96)
	TweenService:Create(toastLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back), { TextTransparency = 0, Position = UDim2.new(0.5, 0, 0, 110) }):Play()
	TweenService:Create(toastStroke, TweenInfo.new(0.25), { Transparency = 0.1 }):Play()
	task.delay(3.2, function()
		if serial ~= toastSerial then
			return
		end
		TweenService:Create(toastLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(toastStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end

local function refreshCounter()
	local n = 0
	for _ in pairs(found) do
		n += 1
	end
	counter.Text = string.format("🦴 GOLDEN BONES  %d / %d", n, math.max(total, n))
	counter.Visible = total > 0
end

local function hidePiece(d: Instance)
	if d:IsA("BasePart") then
		d.LocalTransparencyModifier = 1
	elseif d:IsA("ParticleEmitter") or d:IsA("Light") then
		-- removed locally: WorldDetailQuality re-enables lights and emitters it manages
		task.defer(function()
			if d.Parent then
				d:Destroy()
			end
		end)
	end
end

local function hideBone(model: Instance)
	for _, d in ipairs(model:GetDescendants()) do
		hidePiece(d)
	end
end

local function boneModel(o: Instance): Instance?
	if o:IsA("Model") and type(o:GetAttribute("GoldenBone")) == "string" then
		return o
	end
	return nil
end

local function applyFound()
	local map = workspace:FindFirstChild("DOGROTS_District")
	if not map then
		return
	end
	for _, d in ipairs(map:GetDescendants()) do
		local m = boneModel(d)
		if m and found[m:GetAttribute("GoldenBone") :: string] then
			hideBone(m)
		end
	end
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ParadiseHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 4
	gui.Parent = player:WaitForChild("PlayerGui")
	toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "Toast"
	toastLabel.AnchorPoint = Vector2.new(0.5, 0)
	toastLabel.Size = UDim2.new(0.6, 0, 0, 44)
	toastLabel.Position = UDim2.new(0.5, 0, 0, 110)
	toastLabel.BackgroundTransparency = 1
	toastLabel.TextScaled = true
	toastLabel.Font = Enum.Font.FredokaOne
	toastLabel.Visible = false
	toastLabel.Parent = gui
	toastStroke = Instance.new("UIStroke")
	toastStroke.Thickness = 3
	toastStroke.Color = Color3.fromRGB(60, 30, 70)
	toastStroke.Parent = toastLabel
	counter = Instance.new("TextLabel")
	counter.Name = "BoneCounter"
	counter.AnchorPoint = Vector2.new(1, 0.5)
	counter.Position = UDim2.new(1, -14, 0.36, 0)
	counter.Size = UDim2.new(0, 230, 0, 30)
	counter.BackgroundColor3 = Color3.fromRGB(40, 24, 56)
	counter.BackgroundTransparency = 0.25
	counter.TextColor3 = Color3.fromRGB(255, 214, 90)
	counter.TextScaled = true
	counter.Font = Enum.Font.FredokaOne
	counter.Visible = false
	counter.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = counter
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 3)
	pad.PaddingBottom = UDim.new(0, 3)
	pad.Parent = counter
end

function M.Start()
	build()
	local signal = ReplicatedStorage:WaitForChild("ParadiseSignal") :: RemoteEvent
	signal.OnClientEvent:Connect(function(msg)
		if type(msg) ~= "table" then
			return
		end
		if msg.Kind == "State" then
			total = tonumber(msg.Total) or total
			for _, id in ipairs(msg.Bones or {}) do
				found[tostring(id)] = true
			end
			refreshCounter()
			applyFound()
		elseif msg.Kind == "Bone" then
			total = tonumber(msg.Total) or total
			found[tostring(msg.Id)] = true
			refreshCounter()
			applyFound()
			local text = string.format("GOLDEN BONE %d/%d!  +$%s  +%d 🦴", msg.Count or 0, total, short(msg.Cash or 0), msg.Bones or 0)
			if msg.Complete then
				text = "ALL GOLDEN BONES FOUND! +$" .. short(msg.Cash or 0)
			end
			toast(text, Color3.fromRGB(255, 214, 90))
		elseif msg.Kind == "Chest" then
			toast(string.format("SKY TOWER CHEST!  +$%s  +%d 🦴", short(msg.Cash or 0), msg.Bones or 0), Color3.fromRGB(120, 230, 255))
		elseif msg.Kind == "Toast" and type(msg.Text) == "string" then
			toast(msg.Text, Color3.fromRGB(255, 240, 220))
		end
	end)
	-- bones streaming in later must hide too
	local map = workspace:WaitForChild("DOGROTS_District")
	map.DescendantAdded:Connect(function(d)
		if d:IsA("Model") then
			local m = boneModel(d)
			if m and found[m:GetAttribute("GoldenBone") :: string] then
				hideBone(m)
			end
		elseif d:IsA("BasePart") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			local m = d:FindFirstAncestorWhichIsA("Model")
			m = m and boneModel(m)
			if m and found[m:GetAttribute("GoldenBone") :: string] then
				hidePiece(d)
			end
		end
	end)
end

return M
