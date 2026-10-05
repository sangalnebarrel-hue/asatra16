-- Prints the conveyor odds the live code produces: runs the real Config, DogDefinitions
-- and Engine:LineOdds from src/ (other requires are stubbed) and simulates the spawner.
-- Usage: lune run tools/odds_report.luau [src] [simulated hours]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local SRC = process.args[1] or "src"
local HOURS = tonumber(process.args[2]) or 20000

-- Minimal script/require shim: a "script" is a path; Parent/child indexing walks paths.
local cache = {}
local loadModule
local function scriptAt(path)
	return setmetatable({ __path = path }, {
		__index = function(self, key)
			if key == "Parent" then
				return scriptAt((string.match(rawget(self, "__path"), "^(.*)/[^/]+$")))
			end
			return scriptAt(rawget(self, "__path") .. "/" .. key)
		end,
	})
end
local stubs = {
	["ServerScriptService/Economy/Rules"] = { Available = function() return true end, Check = function(c, m) if not c then error(m) end end },
	["ServerScriptService/Economy/Market"] = { new = function() return {} end },
}
-- Only these run for real; every other require gets a permissive stub.
local REAL = {
	["ReplicatedStorage/DogEconomy/Config"] = true, ["ReplicatedStorage/DogEconomy/DogDefinitions"] = true,
	["ServerScriptService/Economy/Config"] = true, ["ServerScriptService/Economy/DogDefinitions"] = true,
	["ServerScriptService/Economy/Engine"] = true, ["ReplicatedStorage/LuckyBlockConfig"] = true,
	["ReplicatedStorage/RewardMachineText"] = true, ["ReplicatedStorage/RewardMachineConfig"] = true,
	["ReplicatedStorage/RewardMachineOdds"] = true,
}
function loadModule(path)
	if cache[path] then return cache[path] end
	if stubs[path] then return stubs[path] end
	local file = SRC .. "/" .. path .. ".luau"
	if not REAL[path] or not fs.isFile(file) then
		cache[path] = setmetatable({}, { __index = function() return function() end end })
		return cache[path]
	end
	local env = setmetatable({
		script = scriptAt(path),
		require = function(m) return loadModule(rawget(m, "__path")) end,
		game = setmetatable({}, { __index = function(_, k)
			if k == "GetService" then
				return function(_, name) return scriptAt(name) end
			end
			return scriptAt(k)
		end }),
	}, { __index = _G })
	for _, name in { "Color3", "Vector3", "CFrame", "UDim2", "UDim", "Enum", "NumberSequence", "ColorSequence", "NumberRange", "BrickColor", "Vector2" } do
		env[name] = roblox[name]
	end
	local fn = luau.load(fs.readFile(file), { debugName = path, environment = env })
	cache[path] = fn()
	return cache[path]
end

local C = loadModule("ReplicatedStorage/DogEconomy/Config")
local D = loadModule("ReplicatedStorage/DogEconomy/DogDefinitions")
local E = loadModule("ServerScriptService/Economy/Engine")
local engine = E.new(nil, { Now = function() return 0 end, Random = math.random,
	AssetReady = function(id) return D[id] ~= nil and D[id].Available end })

local choices, total = engine:LineOdds()
local byRank, perDog = {}, {}
for _, c in choices do
	byRank[c.Rank] = (byRank[c.Rank] or 0) + c.Weight
	perDog[c.Id] = c.Weight / total
end
local Stream = loadModule("ReplicatedStorage/LuckyBlockConfig").Stream
local slotSeconds = Stream.SlotLength * (Stream.EmptySlots + 1) / Stream.Speed
local dogsPerHour = 3600 / slotSeconds * (1 - Stream.BlockChance)
print(string.format("line dogs per hour per server: %.1f (slot %.1f s, %d%% blocks)", dogsPerHour, slotSeconds, Stream.BlockChance * 100))
print("rarity        per spawn    natural mean interval")
for rank, name in C.Rarities do
	local p = (byRank[rank] or 0) / total
	local minutes = p > 0 and 60 / (dogsPerHour * p) or math.huge
	print(string.format("  %-10s %8.4f%%    %s", name, p * 100,
		p > 0 and (minutes < 120 and string.format("%.1f min", minutes) or string.format("%.1f h", minutes / 60)) or "never"))
end
print("secrets on the line:")
local secrets = {}
for id, p in perDog do if D[id].Rank == 6 then table.insert(secrets, id) end end
table.sort(secrets, function(a, b) return perDog[a] > perDog[b] end)
for _, id in secrets do
	print(string.format("  %-14s %9.5f%%  1 in %8.0f dogs  ~%.1f h per server", id, perDog[id] * 100, 1 / perDog[id], 1 / (dogsPerHour * perDog[id])))
end
for id, d in D do
	if d.Rank == 6 and not perDog[id] then print("  (not on the line) " .. id .. " · " .. d.Acquisition) end
end

-- Invariants (the same ones BalanceQATests checks in Studio).
local sum = 0
for _, w in C.Weights do sum += w end
assert(math.abs(sum - 100) < 1e-9, "line weights must sum to 100")
assert(C.LineGuarantee[6] == nil, "secrets are never guaranteed")
for id, d in D do
	if d.Rank == 6 and d.CanSpawnOnLine then
		assert(d.LineWeight >= D.TheDog.LineWeight, "THE DOG must be the rarest secret: " .. id)
		assert(d.LinePrice and d.LinePrice >= C.Prices[6], "secret line price: " .. id)
	end
end
assert(not D.LongDog.CanSpawnOnLine and not D.Aurion.CanSpawnOnLine, "exclusives stay off the tongue")
for _ = 1, 20000 do assert(D[engine:Choose(5)].Rank < 6, "token rolls never mint a secret") end
print("invariants: ok")

-- The real Engine:Choose must reproduce LineOdds (checked on a sample).
local SAMPLE = 200000
local seen = {}
for _ = 1, SAMPLE do
	local id = engine:Choose()
	seen[D[id].Rank] = (seen[D[id].Rank] or 0) + 1
end
print(string.format("Engine:Choose sample of %d:", SAMPLE))
for rank, name in C.Rarities do
	local expected = (byRank[rank] or 0) / total
	print(string.format("  %-10s %8.4f%% (expected %8.4f%%)", name, 100 * (seen[rank] or 0) / SAMPLE, expected * 100))
end

-- Spawner simulation with the guarantee timers (DogLineSpawner choose()), drawing from
-- the same cumulative table Engine:Choose walks.
local function draw()
	local roll = math.random() * total
	local lo, hi = 1, #choices
	while lo < hi do
		local mid = (lo + hi) // 2
		if roll < choices[mid].Ceiling then hi = mid else lo = mid + 1 end
	end
	return choices[lo].Id
end
local guarantee = C.LineGuarantee or {}
local now, lastRank, counts, forced = 0, {}, {}, {}
local dogInterval = 3600 / dogsPerHour
local spawns = math.floor(HOURS * dogsPerHour)
for _ = 1, spawns do
	now += dogInterval
	local id = draw()
	local rolled = D[id].Rank
	local wasForced = nil
	for rank = 6, 1, -1 do
		local every = guarantee[rank]
		if every then
			lastRank[rank] = lastRank[rank] or now
			-- Same rule as DogLineSpawner choose(): only a lower roll is replaced.
			if now - lastRank[rank] >= every and rolled < rank then id = engine:ChooseRank(rank) or id; wasForced = rank; break end
		end
	end
	local rank = D[id].Rank
	lastRank[rank] = now
	counts[rank] = (counts[rank] or 0) + 1
	if wasForced == rank then forced[rank] = (forced[rank] or 0) + 1 end
end
local labels = {}
for r, sec in guarantee do table.insert(labels, C.Rarities[r] .. "=" .. sec .. "s") end
table.sort(labels)
print(string.format("simulated %d h of one server, guarantees %s:", HOURS, table.concat(labels, ", ")))
for rank, name in C.Rarities do
	local n = counts[rank] or 0
	if n > 0 then
		print(string.format("  %-10s every %8.1f min  (%4.1f%% forced by the guarantee)", name, HOURS * 60 / n, 100 * (forced[rank] or 0) / n))
	end
end
