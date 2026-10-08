-- Syntax check with Luau's compiler: lune run tools/luau_syntax.luau FILE...
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local bad = 0
for _, path in process.args do
	local ok, err = pcall(luau.compile, fs.readFile(path))
	if not ok then
		bad += 1
		print("SYNTAX " .. path .. ": " .. tostring(err))
	end
end
print(string.format("checked %d files, %d with syntax errors", #process.args, bad))
process.exit(bad > 0 and 1 or 0)
