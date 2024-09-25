-- The Grid class.
-- Implementation of the `grid` class.
-- The `grid` is a implicit graph which represents the 2D
-- world map layout on which the `PathFinder` object will run.
-- During a search, the `PathFinder` object needs to save some critical values. These values are cached within each `node`
-- object, and the whole set of nodes are tight inside the `grid` object itself.

local Utils = require("finder.utils")

-- local Node = require ("node")
local Grid = class("Grid")

-- Local references
local pairs = pairs
local assert = assert
-- local coroutine = coroutine

-- Offsets for straights moves
local straightOffsets =
{
  {x = 1,  y = 0} --[[W]],
  {x = -1, y = 0}, --[[E]]
  {x = 0,  y = 1} --[[S]],
  {x = 0,  y = -1}, --[[N]]
}
-- Offsets for diagonal moves
local diagonalOffsets =
{
  {x = -1, y = -1} --[[NW]],
  {x = 1,  y = -1}, --[[NE]]
  {x = -1, y = 1} --[[SW]],
  {x = 1,  y = 1}, --[[SE]]
}

-- Inits a new `grid`
-- @class function
-- @tparam table|string map A collision map - (2D array) with consecutive indices (starting at 0 or 1)
-- or a `string` with line-break chars (<code>\n</code> or <code>\r</code>) as row delimiters.
-- later on, indexing a non-cached `node` will cause it to be created and cache within the `grid` on purpose (i.e, when needed).
-- This is a __memory-safe__ option, in case your dealing with some tight memory constraints.
-- Defaults to __false__ when omitted.
-- @treturn grid a new `grid` instance
-- @usage
-- -- A simple 3x3 grid
-- local myGrid = Grid:new({{0,0,0},{0,0,0},{0,0,0}})
-- -- A memory-safe 3x3 grid
-- myGrid = Grid('000\n000\n000', true)
function Grid:ctor(map)
  -- 校验地图
  if type(map) == 'string' then
    assert(Utils.isStrMap(map), 'Wrong argument #1. Not a valid string map')
    map = Utils.strToMap(map)
  end
  assert(Utils.isMap(map), ('Bad argument #1. Not a valid map'))
  -- 加载地图
  self._map = map
  self._nodes, self._minX, self._maxX, self._minY, self._maxY = Utils.arrayToNodes(self._map)
  self._width = (self._maxX - self._minX) + 1
  self._height = (self._maxY - self._minY) + 1
end

--- Checks if `node` at [x,y] is isWalkable
-- @usage
-- -- Always true
-- print(myGrid:isWalkable(2,3,0))
function Grid:isWalkable(x, y, walkable)
  local mask = self._map[y] and self._map[y][x] or nil
  if mask then
    if mask == walkable then
      return true
    else
      if self._eval then
        return walkable(mask)
      end
      return false
    end
  else
    return false
  end
end

--- Returns the `grid` width.
-- @class function
-- @treturn int the `grid` width
-- @usage print(myGrid:getWidth())
function Grid:getWidth()
  return self._width
end

--- Returns the `grid` height.
-- @class function
-- @treturn int the `grid` height
-- @usage print(myGrid:getHeight())
function Grid:getHeight()
  return self._height
end

--- Returns the collision map.
-- @class function
-- @treturn map the collision map (see @{Grid:new})
-- @usage local map = myGrid:getMap()
function Grid:getMap()
  return self._map
end

--- Returns the set of nodes.
-- @class function
-- @treturn {{node,...},...} an array of nodes
-- @usage local nodes = myGrid:getNodes()
function Grid:getNodes()
  return self._nodes
end

--- Returns the `grid` bounds. Returned values corresponds to the upper-left
-- and lower-right coordinates (in tile units) of the actual `grid` instance.
-- @class function
-- @treturn int the upper-left corner x-coordinate
-- @treturn int the upper-left corner y-coordinate
-- @treturn int the lower-right corner x-coordinate
-- @treturn int the lower-right corner y-coordinate
-- @usage local left_x, left_y, right_x, right_y = myGrid:getBounds()
function Grid:getBounds()
  return self._minX, self._minY, self._maxX, self._maxY
end

--- Returns neighbours. The returned value is an array of __walkable__ nodes neighbouring a given `node`.
function Grid:getNeighbours(node, walkable)
  local neighbours = {}
  for i, offset in pairs(straightOffsets) do
    local n = self:getNodeAt(node._x + offset.x, node._y + offset.y)
    if n and self:isWalkable(n._x, n._y, walkable) then
      neighbours[#neighbours + 1] = n
    end
  end
  for i, offset in pairs(diagonalOffsets) do
    local n = self:getNodeAt(node._x + offset.x, node._y + offset.y)
    if n and self:isWalkable(n._x, n._y, walkable) then
      -- default can not tunnel
      local n1 = self:getNodeAt(node._x + offset.x, node._y)
      local n2 = self:getNodeAt(node._x, node._y + offset.y)
      if (n1 and n2) and not self:isWalkable(n1._x, n1._y, walkable) and not self:isWalkable(n2._x, n2._y, walkable) then
      else
        neighbours[#neighbours + 1] = n
      end
    end
  end
  return neighbours
end

--- Grid iterator. Iterates on every single node
-- in the `grid`. Passing __lx, ly, ex, ey__ arguments will iterate
-- only on nodes inside the bounding-rectangle delimited by those given coordinates.
-- @class function
-- @tparam[opt] int lx the leftmost x-coordinate of the rectangle. Default to the `grid` leftmost x-coordinate (see @{Grid:getBounds}).
-- @tparam[optchain] int ly the topmost y-coordinate of the rectangle. Default to the `grid` topmost y-coordinate (see @{Grid:getBounds}).
-- @tparam[optchain] int ex the rightmost x-coordinate of the rectangle. Default to the `grid` rightmost x-coordinate (see @{Grid:getBounds}).
-- @tparam[optchain] int ey the bottom-most y-coordinate of the rectangle. Default to the `grid` bottom-most y-coordinate (see @{Grid:getBounds}).
-- @treturn node a `node` on the collision map, upon each iteration step
-- @treturn int the iteration count
-- @usage
-- for node, count in myGrid:iter() do
--   print(node:getX(), node:getY(), count)
-- end
function Grid:iter(lx, ly, ex, ey)
  local min_x = lx or self._minX
  local min_y = ly or self._minY
  local max_x = ex or self._maxX
  local max_y = ey or self._maxY

  local x, y = nil, min_y
  return function()
    x = not x and min_x or x + 1
    if x > max_x then
      x = min_x
      y = y + 1
    end
    if y > max_y then
      y = nil
    end
    return self._nodes[y] and self._nodes[y][x] or self:getNodeAt(x, y)
  end
end

--- Each transformation. Calls the given function on each `node` in the `grid`,
-- passing the `node` as the first argument to function __f__.
-- @class function
-- @tparam func f a function prototyped as __f(node,...)__
-- @tparam[opt] vararg ... args to be passed to function __f__
-- @treturn grid self (the calling `grid` itself, can be chained)
-- @usage
-- local function printNode(node)
--   print(node:getX(), node:getY())
-- end
-- myGrid:each(printNode)
function Grid:each(f, ...)
  for node in self:iter() do
    f(node, ...)
  end
  return self
end

--- Each (in range) transformation. Calls a function on each `node` in the range of a rectangle of cells,
-- passing the `node` as the first argument to function __f__.
-- @class function
-- @tparam int lx the leftmost x-coordinate coordinate of the rectangle
-- @tparam int ly the topmost y-coordinate of the rectangle
-- @tparam int ex the rightmost x-coordinate of the rectangle
-- @tparam int ey the bottom-most y-coordinate of the rectangle
-- @tparam func f a function prototyped as __f(node,...)__
-- @tparam[opt] vararg ... args to be passed to function __f__
-- @treturn grid self (the calling `grid` itself, can be chained)
-- @usage
-- local function printNode(node)
--   print(node:getX(), node:getY())
-- end
-- myGrid:eachRange(1,1,8,8,printNode)
function Grid:eachRange(lx, ly, ex, ey, f, ...)
  for node in self:iter(lx, ly, ex, ey) do
    f(node, ...)
  end
  return self
end

--- Map transformation.
-- Calls function __f(node,...)__ on each `node` in a given range, passing the `node` as the first arg to function __f__ and replaces
-- it with the returned value. Therefore, the function should return a `node`.
-- @class function
-- @tparam func f a function prototyped as __f(node,...)__
-- @tparam[opt] vararg ... args to be passed to function __f__
-- @treturn grid self (the calling `grid` itself, can be chained)
-- @usage
-- local function nothing(node)
--   return node
-- end
-- myGrid:imap(nothing)
function Grid:imap(f, ...)
  for node in self:iter() do
    node = f(node, ...)
  end
  return self
end

--- Map in range transformation.
-- Calls function __f(node,...)__ on each `node` in a rectangle range, passing the `node` as the first argument to the function and replaces
-- it with the returned value. Therefore, the function should return a `node`.
-- @class function
-- @tparam int lx the leftmost x-coordinate coordinate of the rectangle
-- @tparam int ly the topmost y-coordinate of the rectangle
-- @tparam int ex the rightmost x-coordinate of the rectangle
-- @tparam int ey the bottom-most y-coordinate of the rectangle
-- @tparam func f a function prototyped as __f(node,...)__
-- @tparam[opt] vararg ... args to be passed to function __f__
-- @treturn grid self (the calling `grid` itself, can be chained)
-- @usage
-- local function nothing(node)
--   return node
-- end
-- myGrid:imap(1,1,6,6,nothing)
function Grid:imapRange(lx, ly, ex, ey, f, ...)
  for node in self:iter(lx, ly, ex, ey) do
    node = f(node, ...)
  end
  return self
end

--- Returns the `node` at location [x,y].
-- @class function
-- @name Grid:getNodeAt
-- @tparam int x the x-coordinate coordinate
-- @tparam int y the y-coordinate coordinate
-- @treturn node a `node`
-- @usage local aNode = myGrid:getNodeAt(2,2)
function Grid:getNodeAt(x, y)
  return self._nodes[y] and self._nodes[y][x] or nil
end

return Grid
