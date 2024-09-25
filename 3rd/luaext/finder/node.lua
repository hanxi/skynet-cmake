--- The Node class.
-- The `Node` represents a cell (or a tile) on a collision map. Basically, for each single cell (tile)
-- in the collision map passed-in upon initialization, a `Node` object will be generated
-- and then cached within the `grid`.
--
-- In the following implementation, nodes can be compared using the `<` operator. The comparison is
-- made with regards of their `f` cost. From a given Node being examined, the `PathFinder` will expand the search
-- to the next neighbouring Node having the lowest `f` cost. See `core.heap` for more details.
--

--- The `Node` class.
local Node = class("Node")

-- Enables the use of operator '<' to compare nodes.
-- Will be used to sort a collection of nodes in a binary heap on the basis of their F-cost
function Node.__lt(a, b)
	return (a._f < b._f)
end

--- Inits a new `Node`
-- @class function
-- @tparam int x the x-coordinate of the Node on the collision map
-- @tparam int y the y-coordinate of the Node on the collision map
-- @treturn Node a new `Node`
-- @usage local Node = Node(3,4)
function Node:ctor(x, y)
	self._x = x
	self._y = y
	self._f = nil
	self._g = nil
	self._h = nil
	self._opened = nil
	self._parent = nil
	self._closed = nil
end

--- Clears temporary cached attributes of a `Node`.
-- Deletes the attributes cached within a given Node after a pathfinding call.
-- This function is internally used by the search algorithms, so you should not use it explicitely.
-- @class function
-- @treturn Node self (the calling `Node` itself, can be chained)
-- @usage
-- local thisNode = Node(1,2)
-- thisNode:reset()
function Node:reset()
	self._f = nil
	self._g = nil
	self._h = nil
	self._opened = nil
	self._parent = nil
	self._closed = nil
	return self
end

--- Returns x-coordinate of a `Node`
-- @class function
-- @treturn number the x-coordinate of the `Node`
-- @usage local x = Node:getX()	
function Node:getX()
	return self._x
end

--- Returns y-coordinate of a `Node`
-- @class function
-- @treturn number the y-coordinate of the `Node`	
-- @usage local y = Node:getY()		
function Node:getY()
	return self._y
end

--- Returns x and y coordinates of a `Node`
-- @class function
-- @treturn number the x-coordinate of the `Node`
-- @treturn number the y-coordinate of the `Node`
-- @usage local x, y = Node:getPos()		
function Node:getPos()
	return self._x, self._y
end

function Node:getKey()
	return string.format("%d_%d", self._x, self._y)
end

return Node
