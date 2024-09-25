--- A light implementation of Binary heaps data structure.
-- While running a search, some search algorithms (Astar, Dijkstra, Jump Point Search) have to maintains
-- a list of nodes called __open list__. Retrieve from this list the lowest cost node can be quite slow,
-- as it normally requires to skim through the full set of nodes stored in this list. This becomes a real
-- problem especially when dozens of nodes are being processed (on large maps).
--
-- The current module implements a <a href="http://www.policyalmanac.org/games/binaryHeaps.htm">binary heap</a>
-- data structure, from which the search algorithm will instantiate an open list, and cache the nodes being
-- examined during a search. As such, retrieving the lower-cost node is faster and globally makes the search end
-- up quickly.
--
-- This module is internally used by the library on purpose.
-- It should normally not be used explicitely, yet it remains fully accessible.
-- eg2:
--         local heap = require("heap").new(function (node1, node2)
--             return node1 and node2 and node1.num < node2.num
--         end)
--         heap:push({num = 55})
--         heap:push({num = 1})
--         heap:push({num = 45})
--         print("top1=", heap:pop().num)

--- The `heap` class.
local Heap = class("Heap")

-- Local reference
local floor = math.floor

function Heap:ctor(cmp)
	self._heap = {}
	self._size = 0
	self._sort = cmp or function(a, b) return a < b end
	self._tb = {}
end

-- Percolates up
function Heap:percolateUp(index)
	if index == 1 then
		return
	end
	local pIndex
	if index <= 1 then
		return
	end
	if index % 2 == 0 then
		pIndex = index / 2
	else
		pIndex = (index - 1) / 2
	end
	if not self._sort(self._heap[pIndex], self._heap[index]) then
		self._heap[pIndex], self._heap[index] = self._heap[index], self._heap[pIndex]
		self._tb[self._heap[pIndex]] = pIndex
		self._tb[self._heap[index]] = index
		self:percolateUp(pIndex)
	end
end

-- Percolates down
function Heap:percolateDown(index)
	local lfIndex, rtIndex, minIndex
	lfIndex = 2 * index
	rtIndex = lfIndex + 1
	if rtIndex > self._size then
		if lfIndex > self._size then
			return
		else
			minIndex = lfIndex
		end
	else
		if self._sort(self._heap[lfIndex], self._heap[rtIndex]) then
			minIndex = lfIndex
		else
			minIndex = rtIndex
		end
	end
	if not self._sort(self._heap[index], self._heap[minIndex]) then
		self._heap[index], self._heap[minIndex] = self._heap[minIndex], self._heap[index]
		self._tb[self._heap[index]] = index
		self._tb[self._heap[minIndex]] = minIndex
		self:percolateDown(minIndex)
	end
end

--- Checks if a `heap` is empty
-- @class function
-- @treturn bool __true__ of no item is queued in the heap, __false__ otherwise
-- @usage
-- if myHeap:empty() then
--   print('heap is empty!')
-- end
function Heap:empty()
	return (self._size == 0)
end

function Heap:getSize()
	return self._size
end

--- Clears the `heap` (removes all items queued in the heap)
-- @class function
-- @treturn heap self (the calling `heap` itself, can be chained)
-- @usage myHeap:clear()
function Heap:clear()
	self._heap = {}
	self._size = 0
	self._tb = {}
end

--- Adds a new item in the `heap`
-- @class function
-- @tparam value item a new value to be queued in the heap
-- @treturn heap self (the calling `heap` itself, can be chained)
-- @usage
-- myHeap:push(1)
-- -- or, with chaining
-- myHeap:push(1):push(2):push(4)
function Heap:push(item)
	if item then
		self._size = self._size + 1
		self._heap[self._size] = item
		self._tb[item] = self._size
		self:percolateUp(self._size)
	end
end

--- Pops from the `heap`.
-- Removes and returns the lowest cost item (with respect to the comparison function being used) from the `heap`.
-- @class function
-- @treturn value a value previously pushed into the heap
-- @usage
-- while not myHeap:empty() do
--   local lowestValue = myHeap:pop()
--   ...
-- end
function Heap:pop()
	local root
	if self._size > 0 then
		root = self._heap[1]
		self._tb[root] = nil
		self._heap[1] = self._heap[self._size]
		self._tb[self._heap[1]] = 1
		self._heap[self._size] = nil
		self._size = self._size - 1
		if self._size > 1 then
			self:percolateDown(1)
		end
	end
	return root
end

--- Restores the `heap` property.
-- Reorders the `heap` with respect to the comparison function being used.
-- When given argument __item__ (a value existing in the `heap`), will sort from that very item in the `heap`.
-- Otherwise, the whole `heap` will be cheacked.
-- @class function
-- @tparam[opt] value item the modified value
-- @return heap self (the calling `heap` itself, can be chained)
-- @usage myHeap:heapify()
function Heap:heapify(item)
	if self._size == 0 then
		return
	end
	if item then
		-- local i
		-- for k,v in pairs(self._heap) do
		--     if v == item then
		--         i = k
		--         break
		--     end
		-- end
		local i = self:isIn(item)
		if i then
			self:percolateDown(i)
			self:percolateUp(i)
		end
		return
	end
	for i = floor(self._size / 2), 1, -1 do
		self:percolateDown(i)
	end
end

function Heap:isIn(item)
	if item then
		local i = self._tb[item]
		if i and self._heap[i] == item then
			return i
		elseif i then
			assert(string.format("heap:isIn error, i=%d", i))
		end
	end
	return nil
end

return Heap
