local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local placePath = process.args[1]
local outDir = process.args[2]
local game = roblox.deserializePlace(fs.readFile(placePath))
local ext = { Script = ".server.luau", LocalScript = ".client.luau", ModuleScript = ".luau" }
local function sanitize(n) return (string.gsub(n, "[^%w%._%- ]", "_")) end
-- key = path of names with sibling index disambiguation
local function segName(inst)
  local parent = inst.Parent
  local idx, count = 0, 0
  if parent then
    for _, c in parent:GetChildren() do
      if c.Name == inst.Name then
        count += 1
        if c == inst then idx = count end
      end
    end
  end
  local s = sanitize(inst.Name)
  if count > 1 then s = s .. "~" .. idx end
  return s
end
local function key(inst)
  local p = {}
  local cur = inst
  while cur and cur ~= game do table.insert(p, 1, segName(cur)) cur = cur.Parent end
  return table.concat(p, "/")
end
local manifest = {}
local n = 0
for _, d in game:GetDescendants() do
  if d:IsA("LuaSourceContainer") then
    local k = key(d)
    if not string.find(k, "^ReplicatedStorage/DogAnimationClips") then
      local file = outDir .. "/" .. k .. ext[d.ClassName]
      local dir = string.match(file, "^(.*)/[^/]*$")
      fs.writeDir(dir)
      fs.writeFile(file, d.Source)
      table.insert(manifest, d.ClassName .. "\t" .. k .. ext[d.ClassName])
      n += 1
    end
  end
end
table.sort(manifest)
fs.writeFile(outDir .. "/MANIFEST.tsv", table.concat(manifest, "\n") .. "\n")
print("extracted", n)
