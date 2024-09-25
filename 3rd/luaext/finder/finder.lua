--- The PathFinder class

--
-- Implementation of the `PathFinder` class.

-- Dependencies
local Utils = require("finder.utils")
local Heuristic = require("finder.heuristics")

-- Internalization
-- local tb_insert, tb_remove = table.insert, table.remove
-- local floor = math.floor
local pairs = pairs
local assert = assert
local type = type
-- local setmetatable, getmetatable = setmetatable, getmetatable

--- Finders (search algorithms implemented). Refers to the search algorithms actually implemented in Jumper.
--
-- <li>[A*](http://en.wikipedia.org/wiki/A*_search_algorithm)</li>
-- <li>[Dijkstra](http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm)</li>
-- <li>[Theta Astar](http://aigamedev.com/open/tutorials/theta-star-any-angle-paths/)</li>
-- <li>[BFS](http://en.wikipedia.org/wiki/Breadth-first_search)</li>
-- <li>[DFS](http://en.wikipedia.org/wiki/Depth-first_search)</li>
-- <li>[JPS](http://harablog.wordpress.com/2011/09/07/jump-point-search/)</li>
-- @finder Finders
local Finders = {
  ['JPS'] = require("sdk.decision.pathFinder.jps"),
}

--- The `PathFinder` class.
-- @class function
-- @tparam grid grid a `grid`
-- @tparam[opt] string finderName the name of the `Finder` (search algorithm) to be used for search.
-- Defaults to `ASTAR` when not given.
-- @tparam[optchain] string|int|func walkable the value for __walkable__ nodes.
-- If this parameter is a function, it should be prototyped as __f(value)__, returning a boolean:
-- __true__ when value matches a __walkable__ `node`, __false__ otherwise.
-- @treturn PathFinder a new `PathFinder` instance
-- @usage
-- -- Example one
-- local finder = PathFinder.new(myGrid, 'ASTAR', 0)
-- -- Example two
-- local function walkable(value)
--   return value > 0
-- end
-- local finder = PathFinder.new(myGrid, 'JPS', walkable)

local PathFinder = class("PathFinder")

function PathFinder:ctor(grid, walkable, finderName)
  -- Will keep track of all nodes expanded during the search to easily reset their properties for the next pathfinding call
  self.toClear = {}
  self:setGrid(grid)
  self:setFinder(finderName or 'JPS')
  self:setWalkable(walkable)
  self:setHeuristic("EUCLIDIAN") --CARDINTCARD
end

--- Sets the `grid`. Defines the given `grid` as the one on which the `PathFinder` will perform the search.
-- @class function
-- @tparam grid grid a `grid`
-- @treturn PathFinder self (the calling `PathFinder` itself, can be chained)
-- @usage myFinder:setGrid(myGrid)
function PathFinder:setGrid(grid)
  -- assert(Utils.inherits(grid, Grid), 'Wrong argument #1. Expected a \'grid\' object')
  self._grid = grid
  self._grid._eval = self._walkable and type(self._walkable) == 'function'
  return self
end

--- Returns the `grid`. This is a reference to the actual `grid` used by the `PathFinder`.
-- @class function
-- @treturn grid the `grid`
-- @usage local myGrid = myFinder:getGrid()
function PathFinder:getGrid()
  return self._grid
end

--- Sets the __walkable__ value or function.
-- @class function
-- @tparam string|int|func walkable the value for walkable nodes.
-- @treturn PathFinder self (the calling `PathFinder` itself, can be chained)
-- @usage
-- -- Value '0' is walkable
-- myFinder:setWalkable(0)
--
-- -- Any value greater than 0 is walkable
-- myFinder:setWalkable(function(n)
--   return n>0
-- end
function PathFinder:setWalkable(walkable)
  self._walkable = walkable
  self._grid._eval = (type(self._walkable) == 'function')
end

--- Gets the __walkable__ value or function.
-- @class function
-- @treturn string|int|func the `walkable` value or function
-- @usage local walkable = myFinder:getWalkable()
function PathFinder:getWalkable()
  return self._walkable
end

--- Defines the `finder`. It refers to the search algorithm used by the `PathFinder`.
-- @class function
-- @tparam string finderName the name of the `finder` to be used for further searches.
-- @treturn PathFinder self (the calling `PathFinder` itself, can be chained)
-- @usage
-- --To use Breadth-First-Search
-- myFinder:setFinder('BFS')
function PathFinder:setFinder(finderName)
  assert(Finders[finderName], 'Not a valid finder name!')
  self._finder = finderName
  return self
end

--- Returns the name of the `finder` being used.
-- @class function
-- @treturn string the name of the `finder` to be used for further searches.
-- @usage local finderName = myFinder:getFinder()
function PathFinder:getFinder()
  return self._finder
end

--- Sets a heuristic. This is a function internally used by the `PathFinder` to find the optimal path during a search.
-- Use @{PathFinder:getHeuristics} to get the list of all available `heuristics`. One can also define
-- his own `heuristic` function.
-- @class function
-- @tparam func|string heuristic `heuristic` function, prototyped as __f(dx,dy)__ or as a `string`.
-- @treturn PathFinder self (the calling `PathFinder` itself, can be chained)
-- @see PathFinder:getHeuristics
-- @see core.heuristics
-- @usage myFinder:setHeuristic('MANHATTAN')
function PathFinder:setHeuristic(heuristic)
  assert(Heuristic[heuristic] or (type(heuristic) == 'function'), 'Not a valid heuristic!')
  self._heuristic = Heuristic[heuristic] or heuristic
  return self
end

--- Returns the `heuristic` used. Returns the function itself.
-- @class function
-- @treturn func the `heuristic` function being used by the `PathFinder`
-- @see core.heuristics
-- @usage local h = myFinder:getHeuristic()
function PathFinder:getHeuristic()
  return self._heuristic
end

--- Calculates a `path`. Returns the `path` from location __[startX, startY]__ to location __[endX, endY]__.
-- Both locations must exist on the collision map. The starting location can be unwalkable.
-- @class function
-- @tparam int startX the x-coordinate for the starting location
-- @tparam int startY the y-coordinate for the starting location
-- @tparam int endX the x-coordinate for the goal location
-- @tparam int endY the y-coordinate for the goal location
-- @treturn path a path (array of nodes) when found, otherwise nil
-- @usage local path = myFinder:getPath(1,1,5,5)
function PathFinder:getPath(startX, startY, endX, endY)
  self:reset()
  local startNode = self._grid:getNodeAt(startX, startY)
  local endNode = self._grid:getNodeAt(endX, endY)
  --
  if not startNode or not endNode then
    return
  end
  --
  if not self._grid:isWalkable(endX, endY, self:getWalkable()) then
    return
  end
  --
  local lastNode = Finders[self._finder]:getPath(self, startNode, endNode, self.toClear)
  if lastNode then
    return Utils.traceBackPath(self, lastNode, startNode)
  end
end

function PathFinder:hasPath(startX, startY, endX, endY)
  local path = self:getPath(startX, startY, endX, endY)
  return path and true or false
end

--- Resets the `PathFinder`. This function is called internally between successive pathfinding calls, so you should not
-- use it explicitely, unless under specific circumstances.
-- @class function
-- @treturn PathFinder self (the calling `PathFinder` itself, can be chained)
-- @usage local path, len = myFinder:getPath(1,1,5,5)
function PathFinder:reset()
  for node, _ in pairs(self.toClear) do
    node:reset()
  end
  self.toClear = {}
  return self
end

-- Returns PathFinder class
return PathFinder
