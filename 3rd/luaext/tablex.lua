local random = math.random
local type = type
local stringx = require "stringx"

local tablex = {}

--- 过滤字典
-- @param[type=table] tbl 字典
-- @param[type=func] func 过滤函数
-- @return[type=table] 过滤后的新字典
function tablex.filter_dict(tbl, func)
    local newtbl = {}
    for k, v in pairs(tbl) do
        if func(k, v) then
            newtbl[k] = v
        end
    end
    return newtbl
end

--- 过滤列表
-- @param[type=table] list 列表
-- @param[type=func] func 过滤函数
-- @return[type=table] 过滤后的新列表
function tablex.filter(list, func)
    local new_list = {}
    for _, v in ipairs(list) do
        if func(v) then
            table.insert(new_list, v)
        end
    end
    return new_list
end

--- 从序列中找最大元素
function tablex.max(func, ...)
    if type(func) ~= "function" then
        return math.max(...)
    end
    local args = table.pack(...)
    local max
    for _, arg in ipairs(args) do
        local val = func(arg)
        if not max or val > max then
            max = val
        end
    end
    return max
end

--- 从序列中找最小元素
function tablex.min(func, ...)
    if type(func) ~= "function" then
        return math.min(...)
    end
    local args = table.pack(...)
    local min
    for _, arg in ipairs(args) do
        local val = func(arg)
        if not min or val < min then
            min = val
        end
    end
    return min
end

function tablex.map(func, ...)
    local args = table.pack(...)
    assert(#args >= 1)
    func = func or function(...)
        return { ... }
    end
    local maxn = tablex.max(function(tbl)
        return #tbl
    end, ...)
    local len = #args
    local newtbl = {}
    for i = 1, maxn do
        local list = {}
        for j = 1, len do
            table.insert(list, args[j][i])
        end
        local ret = func(table.unpack(list))
        table.insert(newtbl, ret)
    end
    return newtbl
end

--- 从表中查找符合条件的元素
-- @param[type=table] tbl 表
-- @param[type=func] func 匹配函数/值
-- @return k,v 找到的键值对
function tablex.find(tbl, func)
    local isfunc = type(func) == "function"
    for k, v in pairs(tbl) do
        if isfunc then
            if func(k, v) then
                return k, v
            end
        else
            if func == v then
                return k, v
            end
        end
    end
end

--- 获取表的所有键
-- @param[type=table] t 表
-- @return[type=table] 所有键构成的列表
function tablex.keys(t)
    local ret = {}
    for k in pairs(t) do
        table.insert(ret, k)
    end
    return ret
end

--- 获取表的所有值
-- @param[type=table] t 表
-- @return[type=table] 所有值构成的列表
function tablex.values(t)
    local ret = {}
    for _, v in pairs(t) do
        table.insert(ret, v)
    end
    return ret
end

--- 统计一个表的元素个数
-- @param[type=table] tbl 表
-- @return[type=int] 元素个数
function tablex.count(tbl)
    local cnt = 0
    for _, _ in pairs(tbl) do
        cnt = cnt + 1
    end
    return cnt
end

function tablex.shuffle(arr)
    local count = #arr
    if count <= 1 then
        return arr
    end
    if count == 2 then
        if random(1, 2) == 1 then
            arr[1], arr[2] = arr[2], arr[1]
        end
    else
        while count > 1 do
            local n = random(1, count - 1)
            arr[count], arr[n] = arr[n], arr[count]
            count = count - 1
        end
    end
    return arr
end

--- 根据键从表中获取值
-- @param[type=table] tbl 表
-- @param[type=string] attr 键
-- @return[type=any] 该键对于的值
-- @raise 分层键不存在时会报错
-- @usage local val = table.getattr(tbl,"key")
-- @usage local val = table.getattr(tbl,"k1.k2.k3")
function tablex.get_attr(tbl, attr)
    local attrs = type(attr) == "table" and attr or stringx.split(attr, ".")
    local root = tbl
    for _, v in ipairs(attrs) do
        root = root[v]
    end
    return root
end

--- 判断表中是否有键
-- @param[type=table] tbl 表
-- @param[type=string] attr 键
-- @return[type=bool] 键是否存在
-- @return[type=any] 该键对于的值
-- @usage local exist,val = table.hasattr(tbl,"key")
-- @usage local exist,val = table.hasattr(tbl,"k1.k2.k3")
function tablex.has_attr(tbl, attr)
    local attrs = type(attr) == "table" and attr or stringx.split(attr, ".")
    local root = tbl
    local len = #attrs
    for i, v in ipairs(attrs) do
        root = root[v]
        if i ~= len and type(root) ~= "table" then
            return false
        end
    end
    return true, root
end

--- 向表中设置键值对
-- @param[type=table] tbl 表
-- @param[type=string] attr 键
-- @param[type=any] val 值
-- @return[type=any] 该键对应的旧值
-- @usage table.setattr(tbl,"key",1)
-- @usage table.setattr(tbl,"k1.k2.k3","hi")
function tablex.set_attr(tbl, attr, val)
    local attrs = type(attr) == "table" and attr or stringx.split(attr, ".")
    local lastkey = table.remove(attrs)
    local root = tbl
    for _, v in ipairs(attrs) do
        if nil == root[v] then
            root[v] = {}
        end
        root = root[v]
    end
    local oldval = root[lastkey]
    root[lastkey] = val
    return oldval
end

--- 向表中删除键值对
-- @param[type=table] tbl 表
-- @param[type=string] attr 键
-- @param[type=any] val 值
-- @return[type=any] 该键对应的旧值
-- @usage table.del_attr(tbl,"key")
-- @usage table.del_attr(tbl,"k1.k2.k3")
function tablex.del_attr(tbl, attr)
    local attrs = type(attr) == "table" and attr or stringx.split(attr, ".")
    local lastkey = table.remove(attrs)
    local mod = tablex.get_attr(tbl, attrs)
    if mod == nil then
        return
    end
    local oldval = mod[lastkey]
    mod[lastkey] = nil
    return oldval
end

--- 根据键从表中获取值
-- @param[type=table] tbl 表
-- @param[type=string] attr 键
-- @return[type=any] 该键对于的值,键不存在返回nil
-- @usage local val = table.query(tbl,"key")
-- @usage local val = table.query(tbl,"k1.k2.k3")
function tablex.query(tbl, attr)
    local exist, value = tablex.has_attr(tbl, attr)
    if exist then
        return value
    else
        return nil
    end
end

return tablex
