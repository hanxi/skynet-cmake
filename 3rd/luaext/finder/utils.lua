-- Various utilities for Jumper top-level modules

-- Dependencies
local Path = require ("finder.path")
local Node = require ("finder.node")

local Utils = {}

-- Local references
local lua_type = type
local pairs = pairs
local tb_insert = table.insert
local assert = assert
local floor = math.floor
local concat = table.concat
local next = next

-- Raw array items count
Utils.arraySize = function (t)
	local count = 0
	for k,v in pairs(t) do
		count = count+1
	end
	return count
end

-- Parses a string map and builds an array map
Utils.strToMap = function (str)
	local map = {}
	local w, h
	for line in str:gmatch('[^\n\r]+') do
		if line then
			w = not w and #line or w
			assert(#line == w, 'Error parsing map, rows must have the same size!')
			h = (h or 0) + 1
			map[h] = {}
			for char in line:gmatch('.') do
				map[h][#map[h]+1] = char
			end
		end
	end
	return map
end

-- -- Collects and returns the keys of a given array
-- Utils.getKeys = function (t)
-- 	local keys = {}
-- 	for k,v in pairs(t) do
-- 		keys[#keys+1] = k 
-- 	end
-- 	return keys
-- end

-- -- Calculates the bounds of a 2d array
-- Utils.getArrayBounds = function (map)
-- 	local min_x, max_x
-- 	local min_y, max_y
-- 	for y,_ in pairs(map) do
-- 		min_y = not min_y and y or (y<min_y and y or min_y)
-- 		max_y = not max_y and y or (y>max_y and y or max_y)
-- 		for x in pairs(map[y]) do
-- 			min_x = not min_x and x or (x<min_x and x or min_x)
-- 			max_x = not max_x and x or (x>max_x and x or max_x)
-- 		end
-- 	end
-- 	return min_x, max_x, min_y, max_y
-- end

-- Converts an array to a set of nodes
Utils.arrayToNodes = function (map)
	local min_x, max_x
	local min_y, max_y
	local nodes = {}
	for y,_ in pairs(map) do
		y = floor(y)
		min_y = not min_y and y or (y < min_y and y or min_y)
		max_y = not max_y and y or (y > max_y and y or max_y)
		nodes[y] = {}
		for x,_ in pairs(map[y]) do
			x = floor(x)
			min_x = not min_x and x or (x < min_x and x or min_x)
			max_x = not max_x and x or (x > max_x and x or max_x)
			nodes[y][x] = Node.new(x, y)
		end
	end
	return nodes, (min_x or 0), (max_x or 0), (min_y or 0), (max_y or 0)
end

-- Extract a path from a given start/end position
Utils.traceBackPath = function (finder, node, startNode)
	local path = Path:new()
	path._grid = finder._grid
	while true do
	  if node._parent then
	    tb_insert(path._nodes, 1, node)
	    node = node._parent
	  else
	    tb_insert(path._nodes, 1, startNode)
	    return path
	  end
	end
end

-- Is i out of range
Utils.outOfRange = function (i, low, up)
	return (i < low or i > up)
end

-- Is I an integer ?
Utils.isInteger = function (i)
	return lua_type(i) == ('number') and (floor(i) == i)
end

-- Override lua_type to return integers
Utils.type = function (v)
	return Utils.isInteger(v) and 'int' or lua_type(v)
end

-- Does the given array contents match a predicate type ?
Utils.arrayContentsMatch = function (t, ...)
	local n_count = Utils.arraySize(t)
	if n_count < 1 then
		return false
	end
	local init_count = t[0] and 0 or 1
	local n_count = (t[0] and n_count-1 or n_count)
	local types = {...}
	if types then
		---@diagnostic disable-next-line: cast-local-type
		types = concat(types)
	end
	for i = init_count, n_count, 1 do
		if not t[i] then 
			return false
		end
		if types then
			if not types:match(Utils.type(t[i])) then 
				return false
			end
		end
	end
	return true
end	

-- Checks if arg is a valid array map
Utils.isMap = function (m)
	if not Utils.arrayContentsMatch(m, 'table') then
		return false 
	end
	local lsize = Utils.arraySize(m[next(m)])
	for k, v in pairs(m) do
		if not Utils.arrayContentsMatch(m[k], 'string', 'int') then
			return false 
		end
		if Utils.arraySize(v) ~= lsize then
			return false
		end
	end
	return true
end	

-- Checks if s is a valid string map
Utils.isStrMap = function (s)
	if lua_type(s) ~= 'string' then
		return false
	end
	local w
	for row in s:gmatch('[^\n\r]+') do
		if not row then
			return false
		end
		w = w or #row
		if w ~= #row then
			return false
		end
	end
	return true
end

-- Does instance derive straight from class
Utils.derives = function (instance, class)
	return getmetatable(instance) == class
end

-- Does instance inherits from class	
Utils.inherits= function (instance, class)
	return (getmetatable(getmetatable(instance)) == class)
end

-- Is arg a boolean
Utils.isBool = function (b) 
	return (b==true or b==false)
end

-- Is arg nil ?
Utils.isNil = function (n)
	return (n == nil)
end

-- Utils.matchType = function (value, types)
-- 	return types:match(Utils.type(value))	
-- end

return Utils
