local Grid = require("finder.grid")
local PathFinder = require("finder.finder")

local map = {
    { 0, 1, 0, 1, 0 }, --- (1, 1) (5, 1)
    { 0, 1, 0, 1, 0 }, --- (1, 2) (5, 2)
    { 0, 1, 1, 1, 0 }, --- (1, 3) (5, 3)
    { 0, 0, 0, 0, 0 }, --- (1, 4) (5, 4)
}

-- Value for walkable tiles
local function walkable(val)
    local tbl = {
        [0] = true,
        [100] = true,
    }
    return tbl[val]
end

-- local walkable = 0
local grid = Grid.new(map)
local finder = PathFinder.new(grid, walkable, 'JPS')
local startX, startY = 1, 1
local endX, endY = 5, 1

local path = finder:getPath(startX, startY, endX, endY)
assert(path, "path is nil")
print(('Path found! Length: %.2f'):format(path:getLength()))
for node, count in path:nodes() do
    print(('Step: %d - x: %d - y: %d'):format(count, node:getX(), node:getY()))
end
