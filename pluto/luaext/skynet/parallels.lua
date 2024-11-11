local skynet = require "skynet"
----------------------------------------------
-- 处理 连续多个服务调用时完全独立的,不必等到service1 返回后才调用service2 ... 操作

local M = {}

local mt = {
    __index = M
}

local function new()
    return setmetatable({
        list = {},
        boot_co = nil,
        boot_error = nil
    }, mt)
end

-- 打印异常
local function exception(e)
    skynet.error(e)
    return e
end

function M:wakeup_waitco(err)
    if not self.boot_error then
        self.boot_error = err
    end
    local boot_co = self.boot_co
    if boot_co then
        self.boot_co = nil
        -- 唤醒一个被 skynet.sleep 或 skynet.wait 挂起的 coroutine
        skynet.wakeup(boot_co)
    end
end

function M:add(func, ...)
    local token = {}
    local list = self.list
    list[token] = true
    -- skynet.fork(func, ...) 从功能上，它等价于 skynet.timeout(0, function() func(...) end)
    -- 但是比 timeout 高效一点。因为它并不需要向框架注册一个定时器
    skynet.fork(function(...)
        token.co = coroutine.running()
        local ok, err = xpcall(func, exception, ...)
        if not ok then
            self:wakeup_waitco(err)
        else
            list[token] = nil
            if not next(list) then
                self:wakeup_waitco()
            end
        end
    end, ...)
end

function M:wait()
    assert(not self.boot_co, string.format("already in wait %s", tostring(self.boot_co)))
    self.boot_co = coroutine.running()
    if not next(self.list) then
        -- skynet.yield() 相当于 skynet.sleep(0) 交出当前服务对 CPU 的控制权
        -- 通常在你想做大量的操作，又没有机会调用阻塞 API 时，可以选择调用 yield 让系统跑的更平滑
        skynet.yield()
    else
        -- 把当前 coroutine 挂起，之后由 skynet.wakeup 唤醒。token 必须是唯一的，默认为 coroutine.running()
        skynet.wait(self.boot_co)
    end
    if self.boot_error then
        error(self.boot_error)
    end
end

return new
