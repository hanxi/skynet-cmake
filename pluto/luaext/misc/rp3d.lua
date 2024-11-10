local rp3d = require "rp3d.core"
local math3d_adapter = require "math3d.adapter"

local function shape_interning(shape)
	local all_shapes = {}

	local world_mt = rp3d.collision_world_mt

	local heightfield_idx = 1

	function world_mt:new_shape(typename, ...)
		local value
		if typename ~= "heightfield" then
			-- interning shapes
			local key = table.concat ({ typename, ... } , ":")
			value = all_shapes[key]
			if value then
				return value
			end
			value = shape[typename](...)
			all_shapes[key] = value
		else
			local function generate_heightfield_name()
				local name = "__heightfield"
				while true do
					if all_shapes[name] == nil then
						break
					end
					name = name .. heightfield_idx
					heightfield_idx = heightfield_idx + 1
				end
				return name
			end
			value = shape.heightfield(...)
			local key = generate_heightfield_name()
			all_shapes[key] = value
		end
		return value
	end
end

function rp3d.init(logger)
	if logger then
		rp3d.logger(logger)
	end
	local world_mt = rp3d.collision_world_mt

	world_mt.__index = world_mt

	world_mt.body_create 	= math3d_adapter.format(world_mt.body_create, "vq", 2)
	world_mt.set_transform 	= math3d_adapter.format(world_mt.set_transform, "vq", 3)
	world_mt.get_aabb 		= math3d_adapter.getter(world_mt.get_aabb, "vv")
	world_mt.add_shape 		= math3d_adapter.vector(world_mt.add_shape, 4)

	local shape = {
		sphere = rp3d.create_sphere,
		box = rp3d.create_box,
		capsule = rp3d.create_capsule,
		heightfield	= math3d_adapter.vector(rp3d.create_heightfield, 7),
	}
	shape_interning(shape)

	local rayfilter 		= math3d_adapter.vector(rp3d.rayfilter, 1)
	local raycast 			= math3d_adapter.getter(world_mt.raycast, "vv")

	function world_mt.raycast(world, p0, p1, maskbits)
		p0,p1 = rayfilter(p0,p1)
		local hit, body, pos, norm = raycast(world, p0, p1, maskbits or 0)
		if hit then
			return pos, norm, body
		end
	end
end

return rp3d


-- local math3d = require "math3d"
-- local rp3d = require "misc.rp3d"

-- rp3d.init() -- init math adapter, shape interning

-- local w = rp3d.create_world {
-- 	worldName = "world",
-- 	persistentContactDistanceThreshold = 0.03,
-- 	defaultFrictionCoefficient = 0.3,
-- 	defaultBounciness = 0.5,
-- 	restitutionVelocityThreshold = 1.0,
-- 	defaultRollingRestistance = 0,
-- 	isSleepingEnabled = true,
-- 	defaultVelocitySolverNbIterations = 10,
-- 	defaultPositionSolverNbIterations = 5,
-- 	defaultTimeBeforeSleep = 1.0,
-- 	defaultSleepLinearVelocity = 0.02,
-- 	defaultSleepAngularVelocity = 3.0 * (math.pi / 180),
-- 	nbMaxContactManifolds = 3,
-- 	cosAngleSimilarContactManifold = 0.95,
-- }

-- local pos = math3d.vector()	-- (0,0,0,1)
-- local ori = math3d.quaternion(0, 0, 0, 1)

-- local object = w:body_create(pos, ori)
-- w:set_transform(object, pos, ori)

-- local sphere = w:new_shape("sphere", 10)
-- w:add_shape(object, sphere)
-- local p, o = w:get_aabb(object)
-- print(math3d.tostring(p))
-- print(math3d.tostring(o))

-- local object2 = w:body_create(math3d.vector(10,10,10), ori)
-- local box = w:new_shape("box", 10)	-- rad / can also be (10,20,30)
-- w:add_shape(object2, box)
-- local capsule = w:new_shape("capsule", 10, 20)	-- rad/height
-- w:add_shape(object2, capsule, math3d.vector(0,20,0))

-- local p, o = w:get_aabb(object2)
-- print(math3d.tostring(p))
-- print(math3d.tostring(o))


-- print(w:test_overlap(object))	-- test all layer

-- print("Object:", object)
-- print("Object2:", object2)

-- local hit, norm, body = w:raycast(math3d.vector(100,100,100), math3d.vector(0,0,0))
-- if hit then
-- 	print("Hit position", math3d.tostring(hit))
-- 	print("Hit normal", math3d.tostring(norm))
-- 	print("Hit body", body)
-- end

-- local hit, norm, body = w:raycast(math3d.vector(100,100,100), math3d.vector(0,0,0), object)
-- if hit then
-- 	print("Hit sphere position", math3d.tostring(hit))
-- 	print("Hit sphere normal", math3d.tostring(norm))
-- 	print("Hit body", body)
-- end

-- w:body_destroy(object)
-- w:body_destroy(object2)

-- -- heightfield
-- do
-- 	local heightfield = math3d.ref(
-- 		math3d.matrix(
-- 			0, 0, 0, 0,
-- 			0, 0, 0, 0,
-- 			0, 0, 0, 0,
-- 			0, 0, 0, 0))

-- 	local height_scaling = 1
-- 	local scaling = math3d.vector(1, 1, 2, 0)
-- 	local hf_shape = w:new_shape("heightfield", 4, 4, 0, 1, heightfield.p, height_scaling, scaling)

-- 	local hf_obj = w:body_create(math3d.vector(0, 0, 0, 1), math3d.quaternion(0, 0, 0, 1))
-- 	w:add_shape(hf_obj, hf_shape)

-- 	local h, n = w:raycast(math3d.vector(0, 1, 0, 1), math3d.vector(0, -1, 0, 1))
-- 	if h then
-- 		print(string.format("height field shape hitted, point:%s, normal:%s", math3d.tostring(h), math3d.tostring(n)))
-- 	end
-- 	w:body_destroy(hf_obj)
-- end
