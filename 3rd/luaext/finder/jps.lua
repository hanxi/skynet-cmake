-- Jump Point search algorithm

local Heap = require("finder.heap")
local Heuristics = require("finder.heuristics")

local JPS = class("JPS")

-- Internalization
local max, abs, floor = math.max, math.abs, math.floor

-- Local helpers, these routines will stay private
-- As they are internally used by the public interface

-- Resets properties of nodes expanded during a search
-- This is a lot faster than resetting all nodes
-- between consecutive pathfinding requests

--[[
  Looks for the neighbours of a given node.
  Returns its natural neighbours plus forced neighbours when the given
  node has no parent (generally occurs with the starting node).
  Otherwise, based on the direction of move from the parent, returns
  neighbours while pruning directions which will lead to symmetric paths.

  In case diagonal moves are forbidden, when the given node has no
  parent, we return straight neighbours (up, down, left and right).
  Otherwise, we add left and right node (perpendicular to the direction
  of move) in the neighbours list.
--]]
function JPS:findNeighbours(finder, node)
  if node._parent then
    local neighbours = {}
    local x, y = node._x, node._y
    -- Node have a parent, we will prune some neighbours
    -- Gets the direction of move
    local dx = (x - node._parent._x) / max(abs(x - node._parent._x), 1)
    local dy = (y - node._parent._y) / max(abs(y - node._parent._y), 1)

    -- Diagonal move case
    if dx ~= 0 and dy ~= 0 then
      local walkY, walkX

      -- Natural neighbours
      if finder._grid:isWalkable(x, y + dy, finder._walkable) then
        neighbours[#neighbours + 1] = finder._grid:getNodeAt(x, y + dy)
        walkY = true
      end
      if finder._grid:isWalkable(x + dx, y, finder._walkable) then
        neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + dx, y)
        walkX = true
      end
      if walkX or walkY then
        neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + dx, y + dy)
      end

      -- Forced neighbours
      if (not finder._grid:isWalkable(x - dx, y, finder._walkable)) and walkY then
        neighbours[#neighbours + 1] = finder._grid:getNodeAt(x - dx, y + dy)
      end
      if (not finder._grid:isWalkable(x, y - dy, finder._walkable)) and walkX then
        neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + dx, y - dy)
      end
    else
      -- Move along Y-axis case
      if dx == 0 then
        if finder._grid:isWalkable(x, y + dy, finder._walkable) then
          neighbours[#neighbours + 1] = finder._grid:getNodeAt(x, y + dy)

          -- Forced neighbours are left and right ahead along Y
          if (not finder._grid:isWalkable(x + 1, y, finder._walkable)) then
            neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + 1, y + dy)
          end
          if (not finder._grid:isWalkable(x - 1, y, finder._walkable)) then
            neighbours[#neighbours + 1] = finder._grid:getNodeAt(x - 1, y + dy)
          end
        end
      else
        -- Move along X-axis case
        if finder._grid:isWalkable(x + dx, y, finder._walkable) then
          neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + dx, y)

          -- Forced neighbours are up and down ahead along X
          if (not finder._grid:isWalkable(x, y + 1, finder._walkable)) then
            neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + dx, y + 1)
          end
          if (not finder._grid:isWalkable(x, y - 1, finder._walkable)) then
            neighbours[#neighbours + 1] = finder._grid:getNodeAt(x + dx, y - 1)
          end
        end
      end
    end
    return neighbours
  end
  -- Node do not have parent, we return all neighbouring nodes
  return finder._grid:getNeighbours(node, finder._walkable)
end

--[[
  Searches for a jump point (or a turning point) in a specific direction.
  This is a generic translation of the algorithm 2 in the paper:
    http://users.cecs.anu.edu.au/~dharabor/data/papers/harabor-grastien-aaai11.pdf
  The current expanded node is a jump point if near a forced node

  In case diagonal moves are forbidden, when lateral nodes (perpendicular to
  the direction of moves are walkable, we force them to be turning points in other
  to perform a straight move.
--]]
function JPS:jump(finder, node, parent, endNode)
  if not node then
    return
  end

  local x, y = node._x, node._y
  local dx, dy = x - parent._x, y - parent._y

  -- If the node to be examined is unwalkable, return nil
  if not finder._grid:isWalkable(x, y, finder._walkable) then
    return
  end
  -- If the node to be examined is the endNode, return this node
  if node == endNode then
    return node
  end
  -- Diagonal search case
  if dx ~= 0 and dy ~= 0 then
    -- Current node is a jump point if one of his leftside/rightside neighbours ahead is forced
    if (finder._grid:isWalkable(x - dx, y + dy, finder._walkable) and (not finder._grid:isWalkable(x - dx, y, finder._walkable))) or
        (finder._grid:isWalkable(x + dx, y - dy, finder._walkable) and (not finder._grid:isWalkable(x, y - dy, finder._walkable))) then
      return node
    end
  else
    -- Search along X-axis case
    if dx ~= 0 then
      -- Current node is a jump point if one of his upside/downside neighbours is forced
      if (finder._grid:isWalkable(x + dx, y + 1, finder._walkable) and (not finder._grid:isWalkable(x, y + 1, finder._walkable))) or
          (finder._grid:isWalkable(x + dx, y - 1, finder._walkable) and (not finder._grid:isWalkable(x, y - 1, finder._walkable))) then
        return node
      end
    else
      -- Search along Y-axis case
      -- Current node is a jump point if one of his leftside/rightside neighbours is forced
      if (finder._grid:isWalkable(x + 1, y + dy, finder._walkable) and (not finder._grid:isWalkable(x + 1, y, finder._walkable))) or
          (finder._grid:isWalkable(x - 1, y + dy, finder._walkable) and (not finder._grid:isWalkable(x - 1, y, finder._walkable))) then
        return node
      end
    end
  end

  -- Recursive horizontal/vertical search
  if dx ~= 0 and dy ~= 0 then
    if self:jump(finder, finder._grid:getNodeAt(x + dx, y), node, endNode) then
      return node
    end
    if self:jump(finder, finder._grid:getNodeAt(x, y + dy), node, endNode) then
      return node
    end
  end

  if (dx ~= 0 and finder._grid:isWalkable(x + dx, y, finder._walkable)) or (dy ~= 0 and finder._grid:isWalkable(x, y + dy, finder._walkable)) then
    return self:jump(finder, finder._grid:getNodeAt(x + dx, y + dy), node, endNode)
  end
end

--[[
  Searches for successors of a given node in the direction of each of its neighbours.
  This is a generic translation of the algorithm 1 in the paper:
    http://users.cecs.anu.edu.au/~dharabor/data/papers/harabor-grastien-aaai11.pdf

  Also, we notice that processing neighbours in a reverse order producing a natural
  looking path, as the PathFinder tends to keep heading in the same direction.
  In case a jump point was found, and this node happened to be diagonal to the
  node currently expanded in a straight mode search, we skip this jump point.
--]]
function JPS:identifySuccessors(finder, openList, node, endNode, toClear)
  -- Gets the valid neighbours of the given node
  -- Looks for a jump point in the direction of each neighbour
  local neighbours = self:findNeighbours(finder, node)
  -- Log.dump(neighbours, "jps:identifySuccessors node="..node:getKey(), 10)
  for i = #neighbours, 1, -1 do
    -- local skip = false
    local neighbour = neighbours[i]
    local jumpNode = self:jump(finder, neighbour, node, endNode)
    -- Performs regular A-star on a set of jump points
    if jumpNode then
      -- Update the jump node and move it in the closed list if it wasn't there
      if not jumpNode._closed then
        local g = node._g + Heuristics.EUCLIDIAN(jumpNode, node)
        if not jumpNode._opened or g < jumpNode._g then
          toClear[jumpNode] = true -- Records this node to reset its properties later.
          jumpNode._parent = node
          jumpNode._g = g
          if not jumpNode._h then
            jumpNode._h = finder._heuristic(jumpNode, endNode)
          end
          jumpNode._f = jumpNode._g + jumpNode._h
          if not jumpNode._opened then
            jumpNode._opened = true
            openList:push(jumpNode)
          else
            openList:heapify(jumpNode)
          end
        end
      end
    end
  end
end

-- Calculates a path.
-- Returns the path from location `<startX, startY>` to location `<endX, endY>`.
function JPS:getPath(finder, startNode, endNode, toClear)
  local openList = Heap.new()
  startNode._g = 0
  startNode._h = 0
  startNode._f = startNode._g + startNode._h
  startNode._opened = true
  openList:push(startNode)
  toClear[startNode] = true

  local node
  while not openList:empty() do
    -- Pops the lowest F-cost node, moves it in the closed list
    node = openList:pop()
    node._closed = true

    -- If the popped node is the endNode, return it
    if node == endNode then
      return node
    end

    -- otherwise, identify successors of the popped node
    self:identifySuccessors(finder, openList, node, endNode, toClear)
  end

  -- No path found, return nil
  return nil
end

return JPS
