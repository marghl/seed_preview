local radius = tonumber(minetest.settings:get("seed_preview.radius")) or 256
local center_x = tonumber(minetest.settings:get("seed_preview.center_x")) or 0
local center_z = tonumber(minetest.settings:get("seed_preview.center_z")) or 0
local y_min = tonumber(minetest.settings:get("seed_preview.y_min")) or -32
local y_max = tonumber(minetest.settings:get("seed_preview.y_max")) or 192
local output_name = minetest.settings:get("seed_preview.output") or "preview.ppm"
local width = radius * 2 + 1
local heights = {}
local water_level = tonumber(minetest.get_mapgen_setting("water_level")) or 1

local function image_index(x, z)
	return (center_z + radius - z) * width + (x - center_x + radius) + 1
end

minetest.register_on_generated(function(minp, maxp)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	if not vm then
		return
	end
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data()
	local air = minetest.CONTENT_AIR
	local ignore = minetest.CONTENT_IGNORE

	local x_min = math.max(minp.x, center_x - radius)
	local x_max = math.min(maxp.x, center_x + radius)
	local z_min = math.max(minp.z, center_z - radius)
	local z_max = math.min(maxp.z, center_z + radius)
	for z = z_min, z_max do
		for x = x_min, x_max do
			local target = image_index(x, z)
			for y = maxp.y, minp.y, -1 do
				local content = data[area:index(x, y, z)]
				local above = data[area:index(x, y + 1, z)]
				if content ~= air and content ~= ignore and above == air then
					if not heights[target] or y > heights[target] then
						heights[target] = y
					end
					break
				end
			end
		end
	end
end)

local function terrain_color(height)
	if not height then
		return 20, 20, 20
	end
	if height <= water_level then
		local depth = math.min(80, math.max(0, water_level - height))
		return 20, 90 + math.floor(depth / 2), 175 + math.floor(depth / 3)
	end
	if height < 20 then
		return 194, 178, 128
	end
	if height < 80 then
		local shade = math.min(45, math.floor((height - 20) / 2))
		return 65 + shade, 145 - math.floor(shade / 3), 65
	end
	if height < 140 then
		local shade = math.min(70, height - 80)
		return 115 + shade, 105 + shade, 85 + shade
	end
	return 235, 238, 242
end

local function write_preview()
	local lines = {
		"P3",
		("# seed=%s mapgen=%s center=%d,%d radius=%d"):format(
			minetest.get_mapgen_setting("seed") or "?",
			minetest.get_mapgen_setting("mg_name") or "?",
			center_x,
			center_z,
			radius),
		("%d %d"):format(width, width),
		"255",
	}
	for i = 1, width * width do
		local r, g, b = terrain_color(heights[i])
		lines[#lines + 1] = ("%d %d %d"):format(r, g, b)
	end

	local path = minetest.get_worldpath() .. "/" .. output_name
	local ok = minetest.safe_file_write(path, table.concat(lines, "\n") .. "\n")
	if not ok then
		error("[seed_preview] Could not write " .. path)
	end
	minetest.log("action", "[seed_preview] Wrote " .. path)
	minetest.request_shutdown("Seed preview finished", false, 0)
end

minetest.register_on_mods_loaded(function()
	minetest.after(0, function()
		minetest.emerge_area(
			{x = center_x - radius, y = y_min, z = center_z - radius},
			{x = center_x + radius, y = y_max, z = center_z + radius},
			function(_, _, calls_remaining)
				if calls_remaining == 0 then
					minetest.after(0, write_preview)
				end
			end
		)
	end)
end)
