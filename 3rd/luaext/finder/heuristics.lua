--- Heuristic functions for search algorithms.
-- A <a href="http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html">distance Heuristic</a>
-- provides an *estimate of the optimal distance cost* from a given location to a target.
-- As such, it guides the PathFinder to the goal, helping it to decide which route is the best.
--
-- This script holds the definition of some built-in heuristics available through jumper.
--
-- Distance functions are internally used by the `PathFinder` to evaluate the optimal path
-- from the start location to the goal. These functions share the same prototype:
--     local function myHeuristic(nodeA, nodeB)
--       -- function body
--     end
-- Jumper features some built-in distance heuristics, namely `MANHATTAN`, `EUCLIDIAN`, `DIAGONAL`, `CARDINTCARD`.
-- You can also supply your own Heuristic function, following the same template as above.

local Heuristics = {}

-- Local references
local abs = math.abs
local sqrt = math.sqrt
local sqrt2 = sqrt(2)
local max, min = math.max, math.min

--- Manhattan distance.
-- This Heuristic is the default one being used by the `PathFinder` object.
-- Evaluates as <code>distance = |dx|+|dy|</code>
-- @class function
-- @tparam node nodeA a node
-- @tparam node nodeB another node
-- @treturn number the distance from __nodeA__ to __nodeB__
function Heuristics.MANHATTAN(nodeA, nodeB)
	local dx = abs(nodeA._x - nodeB._x)
	local dy = abs(nodeA._y - nodeB._y)
	return (dx + dy)
end

--- Euclidian distance.
-- Evaluates as <code>distance = squareRoot(dx*dx+dy*dy)</code>
-- @class function
-- @tparam node nodeA a node
-- @tparam node nodeB another node
-- @treturn number the distance from __nodeA__ to __nodeB__
function Heuristics.EUCLIDIAN(nodeA, nodeB)
	local dx = nodeA._x - nodeB._x
	local dy = nodeA._y - nodeB._y
	return sqrt(dx * dx + dy * dy)
end

--- Pow Euclidian distance.
-- Evaluates as <code>distance = squareRoot(dx*dx+dy*dy)</code>
-- @class function
-- @tparam node nodeA a node
-- @tparam node nodeB another node
-- @treturn number the distance from __nodeA__ to __nodeB__
function Heuristics.POWEUCLIDIAN(nodeA, nodeB)
	local dx = nodeA._x - nodeB._x
	local dy = nodeA._y - nodeB._y
	return dx * dx + dy * dy
end

--- Diagonal distance.
-- Evaluates as <code>distance = max(|dx|, abs|dy|)</code>
-- @class function
-- @tparam node nodeA a node
-- @tparam node nodeB another node
-- @treturn number the distance from __nodeA__ to __nodeB__
function Heuristics.DIAGONAL(nodeA, nodeB)
	local dx = abs(nodeA._x - nodeB._x)
	local dy = abs(nodeA._y - nodeB._y)
	return max(dx, dy)
end

--- Cardinal/Intercardinal distance.
-- Evaluates as <code>distance = min(dx, dy)*squareRoot(2) + max(dx, dy) - min(dx, dy)</code>
-- @class function
-- @tparam node nodeA a node
-- @tparam node nodeB another node
-- @treturn number the distance from __nodeA__ to __nodeB__
function Heuristics.CARDINTCARD(nodeA, nodeB)
	local dx = abs(nodeA._x - nodeB._x)
	local dy = abs(nodeA._y - nodeB._y)
	return min(dx, dy) * sqrt2 + max(dx, dy) - min(dx, dy)
end

--- BFS distance.
-- Evaluates as <code>distance = 0</code>
-- @class function
-- @tparam node nodeA a node
-- @tparam node nodeB another node
-- @treturn number the distance from __nodeA__ to __nodeB__
function Heuristics.BFS(nodeA, nodeB)
	return 0
end

return Heuristics
