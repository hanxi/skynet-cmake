-- https://github.com/lunarmodules/luasyslog

local logging = require "logging.core"
local lsyslog = require "lsyslog"
local log = lsyslog.log

local convert = {
    [logging.DEBUG] = lsyslog.LOG_DEBUG,
    [logging.INFO]  = lsyslog.LOG_INFO,
    [logging.WARN]  = lsyslog.LOG_WARNING,
    [logging.ERROR] = lsyslog.LOG_ERR,
    [logging.FATAL] = lsyslog.LOG_ALERT,
}

function logging.syslog(params, ...)
    params = logging.getDeprecatedParams({ "ident", "facility" }, params, ...)
    local ident = params.ident or "lua"
    local facility = params.facility or lsyslog.FACILITY_USER
    -- timestampPattern and logPattern not supported, added by syslog itself
    local logPattern = logging.buildLogPatterns(params.logPatterns, params.logPattern)
    local timestampPattern = params.timestampPattern
    local startLevel = params.logLevel or logging.defaultLevel()

    lsyslog.open(ident, facility)

    -- a pattern was provided, so return an appender that takes that into account
    -- this is less performant, hence we provide 2 different appenders
    return logging.new(function(self, level, message)
        message = logging.prepareLogMsg(logPattern, os.date(timestampPattern), level, message)
        log(convert[level], message)
        return true
    end, startLevel)
end
