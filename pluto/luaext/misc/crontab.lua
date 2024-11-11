-- https://github.com/logiceditor-com/lua-crontab

-- "*","*","*","*","*","*", data
--  ^   ^   ^   ^   ^   ^     ^
--  |   |   |   |   |   |     |
--  |   |   |   |   |   |     +----- custom data, optional
--  |   |   |   |   |   +----------- day of week (1 - 27) (1-7 周一至周日, 11-17 单周周一至周日, 21-27 双周周一至周日)
--  |   |   |   |   +--------------- month (1 - 12)
--  |   |   |   +------------------- day of month (1 - 31)
--  |   |   +----------------------- hour (0 - 23)
--  |   +--------------------------- min (0 - 59)
--  +------------------------------- sec (0 - 59)
-- Cron table is a bit complex thing, but we support only few things
-- (see http://en.wikipedia.org/wiki/CRON_expression for full description)
--
-- +-----------------------------------------------------+
-- |    FIELD     |     VALUES      | SPECIAL CHARACTERS |
-- +--------------+-----------------+--------------------+
-- | Seconds      | 0-59            |       , - *        |
-- | Minutes      | 0-59            |       , - *        |
-- | Hours        | 0-23            |       , - *        |
-- | Day of month | 1-31            |       , - *        |
-- | Month        | 1-12            |       , - *        |
-- | Day of week  | 1-27            |       , - *        |
-- +-----------------------------------------------------+
--
local timex = require("misc.timex")

local Crontab = {}

local parase_cache = {}

local MAX_TIMESTAMP = 2 ^ 31 - 1
local MAX_ITERATIONS = MAX_TIMESTAMP

--- 取下一次触发时间点
---@param start_timestamp number 开始的时间戳
---@param string_cron string 符合 cron 的时间格式的字符串
---@return number 下次触发的时间
function Crontab.next_time(start_timestamp, string_cron)
    assert(type(string_cron) == "string", "cron next time raw_cron_data err")
    local parase = Crontab.get_parase(string_cron)
    return parase:get_next_occurrence(start_timestamp)
end

--- 取触发的时间列表
---@param start_timestamp number 开始的时间戳
---@param string_cron string 符合 cron 的时间格式的字符串
---@param loop_count number 连续取多少次
---@return table 接下来 loop_count 次触发的时间列表
function Crontab.loop_next_time(start_timestamp, string_cron, loop_count)
    assert(type(string_cron) == "string", "cron next time string_cron err")

    local ret = {}
    local parase = Crontab.get_parase(string_cron)
    for i = 1, loop_count or 1 do
        start_timestamp = parase:get_next_occurrence(start_timestamp)
        table.insert(ret, start_timestamp)
    end
    return ret
end

--- 获取解析器
---@param string_cron string cron规则的字符串
function Crontab.get_parase(string_cron)
    local parase = parase_cache[string_cron]
    if not parase then
        local cron_data = Crontab.make_raw_cron_data_from_string(string_cron)
        local cron_properties = assert(Crontab.make_cron_properties(cron_data))
        parase = assert(Crontab.make_next_occurrence_getter(cron_properties))
        parase_cache[string_cron] = parase
    end
    return parase
end

function Crontab.unpack_timestamp(timestamp)
    timestamp = timestamp or timex.now()
    local t = os.date("*t", timestamp)
    return t.year, t.month, t.day, t.hour, t.min, t.sec
end

function Crontab.make_time_table(dom, mon, y, h, m, s)
    return {
        day = dom,
        month = mon,
        year = y,
        hour = h,
        min = m,
        sec = s
    }
end

function Crontab.get_days_in_month(year, month)
    local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local d = days_in_month[month]

    if month == 2 and (year % 4 == 0 or year % 100 == 0 or year % 400 == 0) then
        d = 29
    end

    return d
end

function Crontab.make_cron_properties(raw_cron_data)
    return Crontab.make_cron_properties_from_hash(raw_cron_data)
end

function Crontab.make_cron_properties_from_hash(data)
    return {
        seconds = Crontab.load_date_field(data.s, Crontab.make_string_to_number_converter(0, 59), 0, 59),
        minutes = Crontab.load_date_field(data.m, Crontab.make_string_to_number_converter(0, 59), 0, 59),
        hours = Crontab.load_date_field(data.h, Crontab.make_string_to_number_converter(0, 23), 0, 23),
        days = Crontab.load_date_field(data.dom, Crontab.make_string_to_number_converter(1, 31), 1, 31),
        months = Crontab.load_date_field(data.mon, Crontab.make_string_to_number_converter(1, 12), 1, 12),
        days_of_week = Crontab.load_date_field(data.dow, Crontab.make_string_to_number_converter(1, 27), 1, 27), -- 支持单双周
        data = data.data
    }
end

function Crontab.load_date_field(field_data, value_extractor, minv, maxv)
    if field_data == nil or field_data == "*" then
        return nil
    elseif type(field_data) == "number" then
        return Crontab.load_single_value(tostring(field_data), value_extractor)
    elseif field_data:find("/") then
        return Crontab.load_repeated(field_data, value_extractor, minv, maxv)
    elseif field_data:find(",") then
        return Crontab.load_array(field_data, value_extractor)
    end

    return Crontab.load_single_value(field_data, value_extractor)
end

function Crontab.load_single_value(data, value_extractor)
    if data:find("-") then
        return Crontab.load_interval(data, value_extractor)
    end

    local value = value_extractor(data)
    if not value then
        error("load_single_value: can't parse cron property: `" .. data .. "'")
    end

    return value
end

function Crontab.load_interval(data, value_extractor)
    local start_s, end_s = data:match("(%w+)%-(%w+)")
    if not start_s or not end_s then
        error("load_interval: can't parse cron property: `" .. data .. "'")
    end

    local start_v, end_v = value_extractor(start_s), value_extractor(end_s)
    if not start_v then
        error("load_interval: can't extract value: `" .. start_s .. "'")
    elseif not end_v then
        error("load_interval: can't extract value: `" .. end_s .. "'")
    end

    if start_v > end_v then
        error("load_interval: invalid interval: " .. start_v .. " > " .. end_v)
    end

    local values = {}
    for i = start_v, end_v do
        values[#values + 1] = i
    end
    return values
end

function Crontab.load_repeated(data, value_extractor, minv, maxv)
    local values = {}

    for start, step in data:gmatch('(.[^/]*)/(.*)') do
        local start_value
        if start == '*' then
            start_value = minv
        else
            start_value = Crontab.load_single_value(start, value_extractor)
        end

        if not type(start_value) == "number" and not type(start_value) == "table" then
            error("load_repeated: can't process start value type: `" .. type(start) .. "'")
        end

        local step_value = tonumber(step)

        if not type(step_value) == "number" then
            error("load_repeated: can't process step value type: `" .. type(step) .. "'")
        end
        if not (step_value > 0 and step_value <= maxv) then
            error("load_repeated: can't process step value: `" .. tostring(step) .. "'")
        end

        if type(start_value) == "number" then
            local length = maxv - minv + 1
            if start_value > minv then
                local steps = math.floor((start_value - minv) / step_value)
                start_value = start_value - steps * step_value
            end
            for value = start_value, length - 1, step_value do
                values[#values + 1] = ((value - minv) % length) + minv
            end
        else
            for i = 1, #start_value, step_value do
                values[#values + 1] = start_value[i]
            end
        end

        if #values == 1 then
            values = values[1]
        end
    end

    return values
end

function Crontab.load_array(data, value_extractor)
    local values = {}

    for v in data:gmatch("(.[^,]*),*") do
        local value = Crontab.load_single_value(v, value_extractor)

        if type(value) == "number" then
            values[#values + 1] = value
        elseif type(value) == "table" then
            for i = 1, #value do
                values[#values + 1] = value[i]
            end
        else
            error("load_array: can't process value type: `" .. type(value) .. "'")
        end
    end

    table.sort(values)
    return values
end

function Crontab.make_string_to_number_converter(minv, maxv)
    assert(minv <= maxv)
    return function(v)
        local n = tonumber(v)
        if not n then
            error('not a number: ' .. v)
        end
        if n < minv then
            error('too small value: ' .. n)
        end
        if n > maxv then
            error('too big value: ' .. n)
        end
        return n
    end
end

function Crontab.make_raw_cron_data_from_string(cron_rule_string, data)
    local seconds, minutes, hours, days, months, days_of_week = cron_rule_string:match(
        "%s*(.[^%s]*)%s*(.[^%s]*)%s*(.[^%s]*)%s*(.[^%s]*)%s*(.[^%s]*)%s*(.[^%s]*)%s*")

    return {
        s = seconds,
        m = minutes,
        h = hours,
        dom = days,
        mon = months,
        dow = days_of_week,

        data = data
    }
end

function Crontab.load_cron_property(value, minv, maxv)
    if type(value) == "number" then
        return Crontab.make_enumerator_from_interval(value, value)
    elseif type(value) == "table" then
        return Crontab.make_enumerator_from_set(value)
    end
    return Crontab.make_enumerator_from_interval(minv, maxv)
end

function Crontab.make_enumerator_from_interval(first, last)
    local values = {}
    for i = first, last do
        values[#values + 1] = i
    end
    return Crontab.make_enumerator_from_set(values)
end

function Crontab.make_enumerator_from_set(values)
    local next_values
    do
        next_values = {}
        local curr_index = 1
        for i = values[1], values[#values] do
            if i > values[curr_index] then
                curr_index = curr_index + 1
            end
            assert(i <= values[curr_index])
            next_values[i] = values[curr_index]
        end
    end
    return {
        get_first = function(self)
            return self.min_value_
        end,
        get_next = function(self, value)
            if value <= self.min_value_ then
                return self.min_value_
            end
            if value > self.max_value_ then
                return nil
            end
            return assert(self.next_values_[value])
        end,
        contains = function(self, value)
            return value >= self.min_value_ and value <= self.max_value_ and self.next_values_[value] == value
        end,
        --
        values_ = values,
        min_value_ = values[1],
        max_value_ = values[#values],
        next_values_ = next_values
    }
end

local function get_next_occurrence(self, base_time)
    return self:get_next_occurrence_till(base_time, MAX_TIMESTAMP)
end

local function get_next_occurrence_till(self, base_timestamp, end_timestamp)
    end_timestamp = end_timestamp or MAX_TIMESTAMP

    local SECONDS = self.seconds_
    local MINUTES = self.minutes_
    local HOURS = self.hours_
    local DAYS = self.days_
    local MONTHS = self.months_
    local DAYS_OF_WEEK = self.days_of_week_

    local enumerator_array = Crontab.make_enumerator_array(SECONDS, MINUTES, HOURS, DAYS, MONTHS)

    local baseYear, baseMonth, baseDay, baseHour, baseMinute, baseSecond = Crontab.unpack_timestamp(base_timestamp)

    local endYear, endMonth, endDay = Crontab.unpack_timestamp(end_timestamp)

    local year = baseYear
    local month = baseMonth
    local day = baseDay
    local hour = baseHour
    local minute = baseMinute
    local second = baseSecond + 1

    -- Second
    second = SECONDS:get_next(second)
    if not second then
        second = enumerator_array:get_first_till(SECONDS)
        minute = minute + 1
    end

    -- Minute
    minute = MINUTES:get_next(minute)
    if not minute then
        second, minute = enumerator_array:get_first_till(MINUTES)
        hour = hour + 1
    elseif minute > baseMinute then
        second = enumerator_array:get_first_till(SECONDS)
    end

    -- Hour
    hour = HOURS:get_next(hour)
    if not hour then
        second, minute, hour = enumerator_array:get_first_till(HOURS)
        day = day + 1
    elseif hour > baseHour then
        second, minute = enumerator_array:get_first_till(MINUTES)
    end

    -- Day
    day = DAYS:get_next(day)

    local iterations = 0
    while true and iterations < MAX_ITERATIONS do
        iterations = iterations + 1
        if not day then
            second, minute, hour, day = enumerator_array:get_first_till(DAYS)
            month = month + 1
        elseif day > baseDay then
            second, minute, hour = enumerator_array:get_first_till(HOURS)
        end

        -- Month
        month = MONTHS:get_next(month)
        if not month then
            second, minute, hour, day, month = enumerator_array:get_first_till(MONTHS)
            year = year + 1
        elseif month > baseMonth then
            second, minute, hour, day = enumerator_array:get_first_till(DAYS)
        end

        local dateChanged = day ~= baseDay or month ~= baseMonth or year ~= baseYear

        if day > 28 and dateChanged and day > Crontab.get_days_in_month(year, month) then
            if year >= endYear and month >= endMonth and day >= endDay then
                return false
            end
            ---@diagnostic disable-next-line: cast-local-type
            day = nil
        else
            break
        end
    end

    if iterations >= MAX_ITERATIONS then
        return nil, "endless loop detected"
    end

    local next_timestamp = os.time(Crontab.make_time_table(day, month, year, hour, minute, second))

    if next_timestamp > end_timestamp then
        return nil, "next occurrence is after end date"
    end

    -- Day of week
    local curWeek = timex.get_week_day(next_timestamp)
    local curWeekNum = timex.get_sys_week_num(next_timestamp)
    if curWeekNum % 2 == 0 then
    ---@diagnostic disable-next-line: cast-local-type
        curWeekNum = tonumber("2" .. curWeek)
    else
    ---@diagnostic disable-next-line: cast-local-type
        curWeekNum = tonumber("1" .. curWeek)
    end

    if DAYS_OF_WEEK:contains(curWeek) or DAYS_OF_WEEK:contains(curWeekNum) then
        return next_timestamp
    end

    local new_base_timestamp = os.time(Crontab.make_time_table(day, month, year, 23, 59, 59))
    return self:get_next_occurrence(new_base_timestamp, end_timestamp)
end

function Crontab.make_next_occurrence_getter(cron_properties)
    local seconds = Crontab.load_cron_property(cron_properties.seconds, 0, 59)
    local minutes = Crontab.load_cron_property(cron_properties.minutes, 0, 59)
    local hours = Crontab.load_cron_property(cron_properties.hours, 0, 23)
    local days = Crontab.load_cron_property(cron_properties.days, 1, 31)
    local months = Crontab.load_cron_property(cron_properties.months, 1, 12)
    local days_of_week = Crontab.load_cron_property(cron_properties.days_of_week, 1, 27)

    local cron = {
        get_next_occurrence = get_next_occurrence,
        get_next_occurrence_till = get_next_occurrence_till,

        seconds_ = seconds,
        minutes_ = minutes,
        hours_ = hours,
        days_ = days,
        months_ = months,
        days_of_week_ = days_of_week
    }

    --- cron custom data from cron properties
    cron.data = cron_properties.data;
    return cron
end

function Crontab.make_enumerator_array(...)
    local get_first_till = function(self, max_enumerator)
        local values = {}
        for i = 1, #self.enumerators_ do
            local current = self.enumerators_[i]
            values[#values + 1] = current:get_first()
            if current == max_enumerator then
                break
            end
        end
        return table.unpack(values)
    end

    return {
        get_first_till = get_first_till,
        enumerators_ = { ... }
    }
end

return Crontab
