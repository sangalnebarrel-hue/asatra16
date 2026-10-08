-- DOGROTS Paradise: the ocean, beaches and seabed around the island.
-- Build() writes Terrain voxels (beaches and shallows near the island, open ocean in blocks).
-- ParadiseTerrainBoot calls it when a server starts with empty terrain; run
--   require(game.ServerStorage.ParadiseTerrain).Build()
-- from the Studio command bar once to bake the terrain into the place (the boot then skips it).
-- remaster/coast.py implements the same formulas for prop placement: keep them in sync.
local M = {}

M.SEA = -4
M.FLOOR = -40
local FOOTPRINT = {
	{ -86, -252, 86, -228 },
	{ -102, -228, 102, -204 },
	{ -138, -204, 138, -180 },
	{ -180, -180, 180, 168 },
	{ -194, 168, 194, 180 },
	{ -192, 180, 192, 516 },
	{ -216, 516, 216, 720 },
	{ -204, 720, 204, 744 },
	{ -194, 744, 194, 758 },
}
local NEAR = { -640, -720, 640, 1200 }
local FAR = 2400
local CENTER_Z = 300
local VOXEL = 4
local Y0, Y1 = -48, 0 -- voxel rows written near the island

local function smoothstep(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

function M.Nearest(x: number, z: number): (number, number, number)
	local best, bx, bz = math.huge, x, z
	for _, r in FOOTPRINT do
		local cx = math.clamp(x, r[1], r[3])
		local cz = math.clamp(z, r[2], r[4])
		local d = (x - cx) ^ 2 + (z - cz) ^ 2
		if d < best then
			best, bx, bz = d, cx, cz
		end
	end
	return math.sqrt(best), bx, bz
end

function M.BeachWeight(px: number, pz: number): number
	local w = math.min(1, smoothstep(-200, -120, pz) * 0.85 + 0.15)
	if px > 150 then
		w = math.min(w, 1 - 0.85 * smoothstep(400, 470, pz))
	end
	return w
end

local function noise(x: number, z: number): number
	return 0.9 * math.sin(x * 0.031 + z * 0.017) + 0.6 * math.sin(x * 0.013 - z * 0.027 + 1.7)
		+ 0.4 * math.sin((x + z) * 0.051 + 0.3)
end

local function beachProfile(d: number): number
	if d < 6 then
		return -0.45 - 0.25 * (d / 6)
	elseif d < 40 then
		return -0.7 - 3.6 * smoothstep(6, 40, d)
	elseif d < 120 then
		return -4.3 - 13.7 * smoothstep(40, 120, d)
	elseif d < 320 then
		return -18 - 18 * smoothstep(120, 320, d)
	end
	return -36 - 4 * smoothstep(320, 600, d)
end

local function rockProfile(d: number): number
	if d < 30 then
		return -3 - 19 * smoothstep(0, 30, d)
	elseif d < 320 then
		return -22 - 14 * smoothstep(30, 320, d)
	end
	return -36 - 4 * smoothstep(320, 600, d)
end

-- Seabed / beach height at (x, z), or nil on the island itself.
function M.Height(x: number, z: number): number?
	local d, px, pz = M.Nearest(x, z)
	if d <= 0 then
		return nil
	end
	local w = M.BeachWeight(px, pz)
	local h = beachProfile(d) * w + rockProfile(d) * (1 - w)
	return h + noise(x, z) * smoothstep(12, 40, d) * (if d < 300 then 1 else 0.5)
end

local function surface(x: number, z: number, h: number): Enum.Material
	local _, px, pz = M.Nearest(x, z)
	if M.BeachWeight(px, pz) < 0.45 and h > -26 then
		return Enum.Material.Rock
	elseif h > -20 then
		return Enum.Material.Sand
	end
	return if (math.floor(x / 64) + math.floor(z / 64)) % 3 ~= 0 then Enum.Material.Sand else Enum.Material.Ground
end

-- Paradise Lagoon: a sandy basin in the old quarry hole (the hole in the island ground).
M.LAGOON_REGION = { 40, 544, 200, 724 } -- terrain written here (x0, z0, x1, z1)
M.LAGOON_BASIN = { 60, 562, 172, 704, 26 } -- rounded rectangle x0, z0, x1, z1, corner radius
M.LAGOON_FLOOR = -11

-- Signed distance into the basin (positive inside).
function M.LagoonDepthDistance(x: number, z: number): number
	local b = M.LAGOON_BASIN
	local r = b[5]
	local cx, cz = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
	local hx, hz = (b[3] - b[1]) / 2 - r, (b[4] - b[2]) / 2 - r
	local qx, qz = math.abs(x - cx) - hx, math.abs(z - cz) - hz
	local outside = math.sqrt(math.max(qx, 0) ^ 2 + math.max(qz, 0) ^ 2) + math.min(math.max(qx, qz), 0) - r
	return -outside
end

-- Lagoon sand height (nil outside the lagoon region).
function M.LagoonHeight(x: number, z: number): number?
	local g = M.LAGOON_REGION
	if x < g[1] or x > g[3] or z < g[2] or z > g[4] then
		return nil
	end
	local s = M.LagoonDepthDistance(x, z)
	if s <= 0 then
		return -0.35
	elseif s < 7 then
		return -0.35 - 3.65 * smoothstep(0, 7, s)
	end
	return -4 + (M.LAGOON_FLOOR + 4) * smoothstep(7, 26, s) + 0.4 * math.sin(x * 0.11 + z * 0.07)
end

local function writeLagoon(terrain: Terrain)
	local g = M.LAGOON_REGION
	local ly0, ly1 = -16, 0
	local nx, nz, ny = (g[3] - g[1]) // VOXEL, (g[4] - g[2]) // VOXEL, (ly1 - ly0) // VOXEL
	local materials, occupancy = table.create(nx), table.create(nx)
	for i = 1, nx do
		local mi, oi = table.create(ny), table.create(ny)
		materials[i], occupancy[i] = mi, oi
		for j = 1, ny do
			mi[j], oi[j] = table.create(nz, Enum.Material.Air), table.create(nz, 0)
		end
		local x = g[1] + (i - 0.5) * VOXEL
		for k = 1, nz do
			local z = g[2] + (k - 0.5) * VOXEL
			local h = M.LagoonHeight(x, z) or -0.35
			for j = 1, ny do
				local y0 = ly0 + (j - 1) * VOXEL
				local y1 = y0 + VOXEL
				if h >= y1 then
					mi[j][k], oi[j][k] = Enum.Material.Sand, 1
				elseif h > y0 then
					mi[j][k], oi[j][k] = Enum.Material.Sand, math.max(0.08, (h - y0) / VOXEL)
				elseif y1 <= M.SEA then
					mi[j][k], oi[j][k] = Enum.Material.Water, 1
				end
			end
		end
	end
	local region = Region3.new(Vector3.new(g[1], ly0, g[2]), Vector3.new(g[3], ly1, g[4]))
	terrain:WriteVoxels(region, VOXEL, materials, occupancy)
end

local function writeNearChunk(terrain: Terrain, cx0: number, cz0: number, nx: number, nz: number)
	local ny = (Y1 - Y0) // VOXEL
	local materials, occupancy = table.create(nx), table.create(nx)
	local any = false
	for i = 1, nx do
		local mi, oi = table.create(ny), table.create(ny)
		materials[i], occupancy[i] = mi, oi
		for j = 1, ny do
			mi[j], oi[j] = table.create(nz, Enum.Material.Air), table.create(nz, 0)
		end
		local x = cx0 + (i - 0.5) * VOXEL
		for k = 1, nz do
			local z = cz0 + (k - 0.5) * VOXEL
			local h = M.Height(x, z)
			if h then
				any = true
				local mat = surface(x, z, h)
				for j = 1, ny do
					local y0 = Y0 + (j - 1) * VOXEL
					local y1 = y0 + VOXEL
					if h >= y1 then
						mi[j][k], oi[j][k] = mat, 1
					elseif h > y0 then
						mi[j][k], oi[j][k] = mat, math.max(0.08, (h - y0) / VOXEL)
					elseif y1 <= M.SEA then
						mi[j][k], oi[j][k] = Enum.Material.Water, 1
					end
				end
			end
		end
	end
	if any then
		local region = Region3.new(Vector3.new(cx0, Y0, cz0), Vector3.new(cx0 + nx * VOXEL, Y1, cz0 + nz * VOXEL))
		terrain:WriteVoxels(region, VOXEL, materials, occupancy)
	end
end

local function fillOcean(terrain: Terrain)
	local tile = 512
	local x0, z0, x1, z1 = -FAR, CENTER_Z - FAR, FAR, CENTER_Z + FAR
	local depth = M.SEA - M.FLOOR
	local count = 0
	for x = x0, x1 - 1, tile do
		for z = z0, z1 - 1, tile do
			-- skip tiles fully inside the near box (written voxel by voxel)
			local inside = x >= NEAR[1] and x + tile <= NEAR[3] and z >= NEAR[2] and z + tile <= NEAR[4]
			if not inside then
				-- clip against the near box: fill up to four slabs around it
				local slabs = {}
				local ax0, az0, ax1, az1 = x, z, x + tile, z + tile
				local ix0, iz0 = math.max(ax0, NEAR[1]), math.max(az0, NEAR[2])
				local ix1, iz1 = math.min(ax1, NEAR[3]), math.min(az1, NEAR[4])
				if ix0 >= ix1 or iz0 >= iz1 then
					table.insert(slabs, { ax0, az0, ax1, az1 })
				else
					if az0 < iz0 then table.insert(slabs, { ax0, az0, ax1, iz0 }) end
					if iz1 < az1 then table.insert(slabs, { ax0, iz1, ax1, az1 }) end
					if ax0 < ix0 then table.insert(slabs, { ax0, iz0, ix0, iz1 }) end
					if ix1 < ax1 then table.insert(slabs, { ix1, iz0, ax1, iz1 }) end
				end
				for _, s in slabs do
					local sx, sz = s[3] - s[1], s[4] - s[2]
					local mid = Vector3.new((s[1] + s[3]) / 2, 0, (s[2] + s[4]) / 2)
					terrain:FillBlock(CFrame.new(mid.X, M.SEA - depth / 2, mid.Z), Vector3.new(sx, depth, sz), Enum.Material.Water)
					terrain:FillBlock(CFrame.new(mid.X, M.FLOOR - 4, mid.Z), Vector3.new(sx, 8, sz), Enum.Material.Sand)
				end
				count += 1
				if count % 6 == 0 then
					task.wait()
				end
			end
		end
	end
end

function M.ApplyWaterLook(terrain: Terrain)
	terrain.WaterColor = Color3.fromRGB(34, 158, 176)
	terrain.WaterTransparency = 0.62
	terrain.WaterReflectance = 0.7
	terrain.WaterWaveSize = 0.16
	terrain.WaterWaveSpeed = 11
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(240, 218, 170))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(108, 100, 94))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(150, 130, 98))
end

function M.Build()
	local terrain = workspace.Terrain
	local started = os.clock()
	M.ApplyWaterLook(terrain)
	local chunk = 32
	local nxTotal = (NEAR[3] - NEAR[1]) // VOXEL
	local nzTotal = (NEAR[4] - NEAR[2]) // VOXEL
	local written = 0
	for i = 0, nxTotal - 1, chunk do
		for k = 0, nzTotal - 1, chunk do
			writeNearChunk(terrain, NEAR[1] + i * VOXEL, NEAR[2] + k * VOXEL, math.min(chunk, nxTotal - i), math.min(chunk, nzTotal - k))
			written += 1
			if written % 4 == 0 then
				task.wait()
			end
		end
	end
	fillOcean(terrain)
	writeLagoon(terrain)
	terrain:SetAttribute("ParadiseTerrain", 1)
	print(string.format("DOGROTS_PARADISE_TERRAIN_BUILT %.1fs", os.clock() - started))
end

return M
