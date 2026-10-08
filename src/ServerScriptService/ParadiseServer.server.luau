-- DOGROTS Paradise (server): the ocean terrain, the SKY TOWER reward chest and the Golden Bone
-- hunt. Rewards go through the economy transactions like world-event pickups do; progress is
-- kept in the profile under p.Paradise = {Bones = {[id] = true}, BonesComplete, TowerAt, TowerClimbs}.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Runtime = require(script.Parent.Economy.Runtime)
local R = require(script.Parent.Economy.Rules)

local map = workspace:WaitForChild("DOGROTS_District")
local signal = ReplicatedStorage:FindFirstChild("ParadiseSignal") :: RemoteEvent?
if not signal then
	local created = Instance.new("RemoteEvent")
	created.Name = "ParadiseSignal"
	created.Parent = ReplicatedStorage
	signal = created
end
local remote = signal :: RemoteEvent

local TOWER_COOLDOWN = 20 * 60
local BONE_REACH = 16

-- ---------------------------------------------------------------- terrain
task.spawn(function()
	local ok, err = pcall(function()
		local builder = require(ServerStorage:WaitForChild("ParadiseTerrain"))
		local terrain = workspace.Terrain
		if terrain:GetAttribute("ParadiseTerrain") then
			builder.ApplyWaterLook(terrain)
		else
			builder.Build()
		end
	end)
	if not ok then
		warn("[Paradise] terrain build failed: " .. tostring(err))
	end
end)

-- ---------------------------------------------------------------- helpers
local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function level(p): number
	return math.clamp(tonumber(p.Level) or 1, 1, 200)
end

local cache: { [Player]: { [string]: boolean } } = {}
local busy: { [Player]: boolean } = {}

-- ---------------------------------------------------------------- golden bones
local bones: { [string]: BasePart } = {}
local total = 0
for _, d in ipairs(map:GetDescendants()) do
	if d:IsA("Model") and type(d:GetAttribute("GoldenBone")) == "string" then
		local hit = d:FindFirstChild("BoneHitbox")
		if hit and hit:IsA("BasePart") then
			local id = d:GetAttribute("GoldenBone") :: string
			if not bones[id] then
				total += 1
			end
			bones[id] = hit
		end
	end
end

local function collect(player: Player, id: string)
	local part = bones[id]
	local found = cache[player]
	if not part or not found or found[id] or busy[player] or not Runtime.Ready(player) then
		return
	end
	local root = rootOf(player)
	if not root or (root.Position - part.Position).Magnitude > BONE_REACH then
		return
	end
	busy[player] = true
	local uid = player.UserId
	local key = "p:" .. uid
	local ok, result = Runtime.Tx:Run({ key }, function(v)
		local p = v[key]
		Runtime.Engine:Authorize(p, uid)
		p.Paradise = p.Paradise or {}
		local list = p.Paradise.Bones or {}
		p.Paradise.Bones = list
		R.Check(not list[id], "Already found")
		list[id] = true
		local count = 0
		for _ in pairs(list) do
			count += 1
		end
		local cash = 120 + 60 * level(p)
		local extra = 3
		local complete = false
		if count >= total and not p.Paradise.BonesComplete then
			p.Paradise.BonesComplete = true
			complete = true
			cash += 5000 + 1500 * level(p)
			extra += 50
		end
		R.Credit(p, cash)
		p.Bones += extra
		R.Validate(p)
		return { Count = count, Cash = cash, Bones = extra, Complete = complete }
	end, "paradisebone:" .. uid .. ":" .. id)
	busy[player] = nil
	if ok and type(result) == "table" then
		found[id] = true
		remote:FireClient(player, { Kind = "Bone", Id = id, Count = result.Count, Total = total, Cash = result.Cash, Bones = result.Bones, Complete = result.Complete })
		task.defer(function()
			if player.Parent and Runtime.Ready(player) then
				Runtime.Refresh(player)
			end
		end)
	elseif result == "Already found" then
		found[id] = true
	end
end

for id, hit in pairs(bones) do
	hit.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			collect(player, id)
		end
	end)
end

-- ---------------------------------------------------------------- sky tower chest
local function openChest(player: Player, prompt: ProximityPrompt)
	if busy[player] or not Runtime.Ready(player) then
		return
	end
	local root = rootOf(player)
	local part = prompt.Parent
	if not root or not part or not part:IsA("BasePart") or (root.Position - part.Position).Magnitude > 18 then
		return
	end
	busy[player] = true
	local uid = player.UserId
	local key = "p:" .. uid
	local now = os.time()
	local ok, result = Runtime.Tx:Run({ key }, function(v)
		local p = v[key]
		Runtime.Engine:Authorize(p, uid)
		p.Paradise = p.Paradise or {}
		local ready = (tonumber(p.Paradise.TowerAt) or 0) + TOWER_COOLDOWN
		if now < ready then
			R.Check(false, string.format("The chest refills in %d min", math.ceil((ready - now) / 60)))
		end
		p.Paradise.TowerAt = now
		p.Paradise.TowerClimbs = (tonumber(p.Paradise.TowerClimbs) or 0) + 1
		local cash = 900 + 350 * level(p)
		R.Credit(p, cash)
		p.Bones += 15
		R.Validate(p)
		return { Cash = cash, Bones = 15 }
	end, "paradisechest:" .. uid .. ":" .. now)
	busy[player] = nil
	if ok and type(result) == "table" then
		remote:FireClient(player, { Kind = "Chest", Cash = result.Cash, Bones = result.Bones })
		task.defer(function()
			if player.Parent and Runtime.Ready(player) then
				Runtime.Refresh(player)
			end
		end)
	elseif type(result) == "string" then
		remote:FireClient(player, { Kind = "Toast", Text = result })
	end
end

for _, d in ipairs(map:GetDescendants()) do
	if d:IsA("ProximityPrompt") and d:GetAttribute("ParadiseChest") then
		d.Triggered:Connect(function(player)
			openChest(player, d)
		end)
	end
end

-- ---------------------------------------------------------------- per-player state
local function load(player: Player)
	local waited = 0
	while player.Parent and not Runtime.Ready(player) and waited < 120 do
		task.wait(1)
		waited += 1
	end
	if not player.Parent or not Runtime.Ready(player) then
		return
	end
	local uid = player.UserId
	local key = "p:" .. uid
	local ok, data = Runtime.Tx:Run({ key }, function(v)
		local p = v[key]
		local P = p.Paradise or {}
		local list = {}
		for id in pairs(P.Bones or {}) do
			table.insert(list, id)
		end
		return { Bones = list, TowerAt = tonumber(P.TowerAt) or 0 }
	end, "paradiseread:" .. uid .. ":" .. os.time())
	if not ok or type(data) ~= "table" then
		return
	end
	local set = {}
	for _, id in ipairs(data.Bones) do
		set[id] = true
	end
	cache[player] = set
	remote:FireClient(player, { Kind = "State", Bones = data.Bones, Total = total, TowerReadyAt = data.TowerAt + TOWER_COOLDOWN })
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(load, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(load, player)
end
Players.PlayerRemoving:Connect(function(player)
	cache[player] = nil
	busy[player] = nil
end)

print("DOGROTS_PARADISE_SERVER_READY", total, "golden bones")
