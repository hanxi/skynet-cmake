local skynet = require("skynet")

local timex = {}

function timex.now()
    return math.floor(skynet.time())
end

function timex.get_week_day(time)
    local weekDay = os.date("%w", time or time.now())
    return weekDay == "0" and 7 or tonumber(weekDay)
end

--- 获取时区
local _timezone = tonumber(os.date("%z", 0)) / 100
function timex.get_time_zone()
    return _timezone
end

-- 获取距 2000/1/3日 的周数 用来处理单双周的判断
---@param time integer
---@return integer
function timex.get_sys_week_num(time)
    time = time or time.now()
    -- 约定UTC 0 时区的 year = 2000,month=1,day=3,hour=0 这个时间为第一个双周的开始
    local timeZone = timex.get_time_zone() or 0
    local difTime = time - (946857600 - (timeZone * 3600)) -- 946857600(UTC0点)
    local week = math.floor(difTime / (86400 * 7))
    return week
end


return timex