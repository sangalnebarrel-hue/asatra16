-- Writes a Rojo-style sourcemap.json for luau-lsp: the place's instance tree with
-- every script mapped to its file under src/. Usage: lune run sourcemap.luau PLACE SRC OUT
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")
local game = roblox.deserializePlace(fs.readFile(process.args[1]))
local src = process.args[2]
local ext = { Script = ".server.luau", LocalScript = ".client.luau", ModuleScript = ".luau" }
local function sanitize(n) return (string.gsub(n, "[^%w%._%- ]", "_")) end
local SKIP_DEEP = { DogTemplates = true, DogAnimationClips = true }
local function node(inst, key, depth)
  local n = { name = inst.Name, className = inst.ClassName }
  if ext[inst.ClassName] then
    local file = src .. "/" .. key .. ext[inst.ClassName]
    if fs.isFile(file) then n.filePaths = { file } end
  end
  if inst:IsA("BasePart") and depth > 2 then return n end
  if SKIP_DEEP[inst.Name] and depth > 0 then
    -- keep only the direct children
    local kids = {}
    for _, c in inst:GetChildren() do table.insert(kids, { name = c.Name, className = c.ClassName }) end
    n.children = kids
    return n
  end
  local kids = {}
  for _, c in inst:GetChildren() do
    if depth < 9 or ext[c.ClassName] then
      table.insert(kids, node(c, key == "" and sanitize(c.Name) or key .. "/" .. sanitize(c.Name), depth + 1))
    end
  end
  if #kids > 0 then n.children = kids end
  return n
end
local root = { name = "Game", className = "DataModel", children = {} }
for _, service in game:GetChildren() do
  table.insert(root.children, node(service, sanitize(service.Name), 0))
end
fs.writeFile(process.args[3], serde.encode("json", root))
-- new files that are not in the place yet are appended by the caller when needed
print("sourcemap written")
