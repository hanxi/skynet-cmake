-- 一些有用的参考例子
-- https://github.com/cloudwu/luareload
-- https://github.com/jinq0123/hotfix
-- https://github.com/sealindx/lua-hotfix

local reloader = {}

local fixfname_tb
local locals

local collect_uv

local format = string.format

local function printE(...)
    print("[fixhot] ", ...)
end

local weak = { __mode = "kv" }
local catch_package = setmetatable({}, weak)


local function tsplit(str, reps)
    local result = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        table.insert(result, w)
    end)
    return result
end

local dump_env = {}
for k, v in pairs(_ENV) do
    dump_env[k] = v
end

local function prev_loader_module()
    for k, v in pairs(package.loaded) do
        catch_package[v] = k
    end
end


local function findloader(name, env, extra)
    local f = io.open(name, "r")
    assert(f, name .. " file is not exit")
    local str = f:read("*a")
    f:close()
    if extra then
        str = extra .. str
    end
    return str, load(str, name, "bt", env)
end

local function getupvalues(f, uvf, uvt, unique, fname)
    local i = 1
    while true do
        local name, value = debug.getupvalue(f, i)
        if name == nil then
            return
        end

        if name ~= "_ENV" and not dump_env[name] then
            local t = type(value)
            if not unique[name] then
                unique[name] = true

                if t == "function" and not uvf[name] then
                    uvf[name] = { func = { { f, i } }, value = value }
                    getupvalues(value, uvf, uvt, unique, name)
                elseif t == "table" and not uvt[name] then
                    uvt[name] = { func = { { f, i } }, value = value }
                    if not catch_package[value] then
                        collect_uv(name, value, uvf, uvt, false)
                    end
                else
                    -- value is basic type, and save it in uvt
                    -- like local a = 12
                    if not uvt[name] then
                        uvt[name] = { func = { { f, i } } }
                    end
                end
            else
                if t == "function" then
                    -- 当一个模块中出现两个相同函数名时，看看是否存在二义性，是否唯一
                    if uvf[name].value and reloader.ambiguity then
                        if uvf[name].value ~= value then
                            error(format("%s ambiguity reference(%s) now value: %s, old value: %s",
                                fname or "", name, value, uvf[name].value))
                        end
                    end

                    local func = uvf[name].func
                    func[#func + 1] = { f, i }
                elseif t == "table" then
                    local func = uvt[name].func
                    if func then
                        func[#func + 1] = { f, i }
                    end
                end
            end
        end

        i = i + 1
    end
end

collect_uv = function(tname, tb, uvf, uvt, ismodule)
    assert(tname)

    local unique = {}

    if ismodule and not uvt[tname] then
        uvt[tname] = { value = tb }
    end

    for k, v in pairs(tb) do
        if type(v) == "function" then
            local key = format("%s.%s", tname, k)
            uvf[key] = { func = {}, value = v }
            getupvalues(v, uvf, uvt, unique, k)
        end
    end

    -- add metatable support
    local mt = getmetatable(tb) or {}
    local mtbase = mt.__index
    if mtbase and type(mtbase) == "table" then
        collect_uv(tname, mtbase, uvf, uvt, ismodule)
    end
end

local function push_new_func_upvalues(of, ot, f)
    local i = 1
    while true do
        local name, value = debug.getupvalue(f, i)
        if name == nil then
            return
        end

        if not value then
            local detail = of[name] or ot[name]
            if detail then
                local func = detail.func
                if func then
                    debug.upvaluejoin(f, i, func[1][1], func[1][2])
                elseif ot[name].value then
                    debug.setupvalue(f, i, detail.value)
                end
            else
                error(format("Its value(%s) could not be found in the old module", name))
            end
        else
            if type(value) == "function" then
                push_new_func_upvalues(of, ot, value)
            end
        end
        i = i + 1
    end
end

local function patch_local_func(of, ot, fname, f)
    local function tmpf()
        local up = f
    end

    local detail = of[fname] or ot[fname]
    if detail then
        local func = detail.func
        if func then
            for k = 1, #func do
                debug.upvaluejoin(func[k][1], func[k][2], tmpf, 1)
            end
        end
    end
end

local function is_table_func(fname)
    if string.find(fname, "%.") then
        return true
    end
    return false
end

local function patch_func(t, k, f)
    local of = t.__of
    local ot = t.__ot
    local check = t.__check

    assert(type(f) == "function", format("hotfix %s failed, it's type is not function", k))

    if of[k] then
        push_new_func_upvalues(of, ot, f)

        if not check then
            patch_local_func(of, ot, k, f)
        end

        if is_table_func(k) then
            local keys = tsplit(k, ".")
            local tb_func = ot[keys[1]]
            local vt = tb_func.value

            assert(vt, format("1. hotfix failed, invalid function %s", k))

            if not check then
                vt[keys[2]] = f
            end
        end
    else
        if not is_table_func(k) then -- 方法名不能是一个表里面的方法
            local vt = ot.__module.value

            if vt[k] then
                push_new_func_upvalues(of, ot, f)

                if not check then
                    patch_local_func(of, ot, k, f)
                    vt[k] = f
                end
            else
                error("2, hotfix failed, invalid function " .. k)
            end
        else
            error("3. hotfix failed, invalid function " .. k)
        end
    end
end

local function load_new_module(module, uvf, uvt, check)
    local _env = _ENV

    local function global_write(t, k, v)
        local oldv = _env[k]
        if oldv then
            if type(v) == "function" then
                push_new_func_upvalues(uvf, uvt, v)
            end

            if not check then
                _env[k] = v
            end
        else
            error("forbid added a new global function " .. k)
        end
    end

    local _u = { __of = uvf, __ot = uvt, __check = check }
    local _U = setmetatable(_u, { __newindex = patch_func })
    local function hotfix_func(fname, func)
        patch_func(_U, fname, func)
    end

    local global_mt = { __index = _ENV, __newindex = global_write }
    local env = setmetatable({ FIX = _U, fix = hotfix_func }, global_mt) -- 读写全局变量，直接作用在旧的模块中，提高效率
    local _, func, err = findloader(module, env)
    if func then
        local ok, perr = pcall(func)

        _U.__of = nil
        _U.__ot = nil
        setmetatable(_U, nil)
        global_mt.__newindex = _ENV

        assert(ok, format("error: pcall new module(%s) failed: %s", module, perr))
    else
        error(format("load file %s error: %s", module, err))
    end
end

local function cache_func_name(t, fname, f)
    assert(type(f) == "function")

    local of = t.__of
    local ot = t.__ot

    local function collect_locals(func)
        if not func then
            return
        end

        local i = 1
        while true do
            local name, value = debug.getupvalue(func, i)
            if name == nil then
                return
            end

            if name ~= "_ENV" and not dump_env[name] then
                if not locals[name] then
                    locals[name] = true
                    locals[#locals + 1] = format("local %s\n", name)
                end
            end

            if type(value) == "function" then
                if not locals[name] then
                    locals[name] = true
                    collect_locals(value)
                end
            end
            i = i + 1
        end
    end

    if of[fname] and of[fname].value then
        local func = of[fname].value
        collect_locals(func)
    end

    if not ot.__module then
        return
    end

    local mf = ot.__module.value[fname]
    if mf and type(mf) == "function" then
        collect_locals(mf)
    end
end

local function wrap_locals(module, content)
    local file = io.open(module, "r+")
    local gsub = string.gsub
    local remove = table.remove
    local insert = table.insert

    if not file then
        error("can not read the file: " .. module)
    end

    if #locals > 0 then
        local lose = {}

        for i = 1, #locals do
            local v = locals[i]
            gsub(content, v, function(has)
                if has then
                    insert(lose, locals[i])
                end
            end)
        end

        for i = 1, #lose do
            local v = lose[i]
            for j = 1, #locals do
                if locals[j] == v then
                    remove(locals, j)
                    break
                end
            end
        end

        local extra = table.concat(locals, "")
        content = extra .. content
    end

    if #locals > 0 then
        io.output(file)
        io.write(content)
    end
    io.close(file)
end

local function _init(module, uvf, uvt)
    fixfname_tb = {}
    locals = {}

    local _u = { __of = uvf, __ot = uvt }
    local _U = setmetatable(_u, { __newindex = cache_func_name })
    local function hotfix_func(fname, func)
        cache_func_name(_U, fname, func)
    end

    local c, f, err = findloader(module, { FIX = _U, fix = hotfix_func })
    assert(f, err)

    local ok, err = pcall(f)
    assert(ok, err)

    wrap_locals(module, c)
    locals = nil
end

local function reload_module(list, check)
    for _, info in ipairs(list) do
        local oldmodule = info[1]
        local newpath = info[2]
        local uvf, uvt = {}, {}

        if oldmodule and newpath then
            assert(type(oldmodule) == "table")

            collect_uv("__module", oldmodule, uvf, uvt, true)
            if check then
                _init(newpath, uvf, uvt)
            end

            load_new_module(newpath, uvf, uvt, check)
        end
    end
end

function reloader.module(list)
    prev_loader_module()

    local ok, err = pcall(reload_module, list, true)
    if ok then
        ok, err = pcall(reload_module, list)
        if not ok then
            printE("reloader.module failed:", err)
        end
    else
        printE("reloader.module error:", err)
    end
    -- collectgarbage("collect")
end

-- check function is unique
reloader.ambiguity = true

return reloader
