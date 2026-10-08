-- Independent check of a built place with rbx-dom (Lune): the file must parse, and the
-- Paradise content and scripts must be wired the way the runtime scripts expect.
-- Usage: lune run tools/validate_place.luau build/DOGROTS_V34.rbxl
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local Enum = roblox.Enum

local game = roblox.deserializePlace(fs.readFile(process.args[1]))
local failures = 0
local function check(ok: any, what: string)
	if not ok then
		failures += 1
		print("FAIL " .. what)
	end
end

local count = 0
for _ in game:GetDescendants() do
	count += 1
end
print("instances", count)

local district = game.Workspace:FindFirstChild("DOGROTS_District")
check(district, "Workspace.DOGROTS_District")
local paradise = district and district:FindFirstChild("40_Paradise")
check(paradise, "DOGROTS_District.40_Paradise")
if paradise then
	print("paradise instances", #paradise:GetDescendants())
	local landmarks = paradise:FindFirstChild("Landmarks")
	local wheel = landmarks and landmarks:FindFirstChild("FerrisWheel")
	check(wheel and wheel.ModelStreamingMode == Enum.ModelStreamingMode.Persistent, "Ferris wheel is Persistent")
	local gondolas = wheel and wheel:FindFirstChild("Gondolas")
	check(gondolas and #gondolas:GetChildren() == 16, "16 gondolas")
	local bones, ids = 0, {}
	local prompts, tracks, pads = 0, 0, 0
	for _, d in paradise:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("GoldenBone") then
			bones += 1
			local id = d:GetAttribute("GoldenBone")
			check(type(id) == "string" and not ids[id], "unique golden bone id " .. tostring(id))
			ids[id] = true
			local hit = d:FindFirstChild("BoneHitbox")
			check(hit and hit:IsA("BasePart") and hit.CanTouch and not hit.CanCollide and hit.Anchored, "hitbox of " .. tostring(id))
		elseif d:IsA("ProximityPrompt") and d:GetAttribute("ParadiseChest") then
			prompts += 1
			check(d.Parent and d.Parent:IsA("BasePart"), "chest prompt sits in a part")
		elseif d:IsA("Model") and d:GetAttribute("RideTrack") then
			tracks += 1
			local path = d:GetAttribute("Path")
			check(type(path) == "string" and #string.split(path, ";") >= 2, d.Name .. " has a Path")
			local prompt = d:FindFirstChild("RidePrompt", true)
			check(prompt and prompt:IsA("ProximityPrompt"), d.Name .. " has a RidePrompt")
		elseif d:IsA("BasePart") and d:GetAttribute("JumpPad") then
			pads += 1
		end
	end
	print("golden bones", bones, "chest prompts", prompts, "ride tracks", tracks, "jump pads", pads)
	check(bones >= 20, "at least 20 golden bones")
	check(prompts >= 1, "Sky Tower chest prompt")
	check(tracks >= 2, "zipline and water slide")
	check(pads >= 1, "jump pads")
end

local nav = district and district:FindFirstChild("NavigationAnchors")
if nav then
	for _, m in nav:GetChildren() do
		local t = m:FindFirstChild("Target")
		check(t and t:IsA("ObjectValue") and t.Value, "navigation target " .. m.Name)
	end
end

check(game.ReplicatedStorage:FindFirstChild("ParadiseSignal"), "ReplicatedStorage.ParadiseSignal")
local server = game.ServerScriptService:FindFirstChild("ParadiseServer")
check(server and server:IsA("Script"), "ServerScriptService.ParadiseServer")
check(game.ServerStorage:FindFirstChild("ParadiseTerrain"), "ServerStorage.ParadiseTerrain")
local client = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ParadiseWorld")
check(client and client:IsA("LocalScript"), "StarterPlayerScripts.ParadiseWorld")
for _, name in { "Motion", "Rides", "Pads", "Night", "Fireworks", "Birds", "Hud" } do
	local m = client and client:FindFirstChild(name)
	check(m and m:IsA("ModuleScript"), "ParadiseWorld." .. name)
end

if failures > 0 then
	print(failures .. " check(s) failed")
	process.exit(1)
end
print("place OK")
