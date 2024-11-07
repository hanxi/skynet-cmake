local logging = require 'logging.core'

function logging.syslog(ident, facility)
    local lsyslog = require 'lsyslog'

    local convert = {
        [logging.DEBUG] = lsyslog.LEVEL.DEBUG,
        [logging.INFO]  = lsyslog.LEVEL.INFO,
        [logging.WARN]  = lsyslog.LEVEL.WARNING,
        [logging.ERROR] = lsyslog.LEVEL.ERR,
        [logging.FATAL] = lsyslog.LEVEL.ALERT,
    }

    if type(ident) ~= 'string' then
        ident = 'skynet'
    end

    lsyslog.open(ident, facility or lsyslog.FACILITY.USER)

    return logging.new(function(self, level, message)
        lsyslog.log(convert[level] or lsyslog.LEVEL.ERR, message)
        return true
    end)
end

return logging.syslog

-- -- This script works only with luasyslog properly installed
-- local syslog = require 'logging.syslog'

-- -- Generate some log with the default facility
-- local logger = syslog('luasyslog1')
-- logger:debug('Debug message')
-- logger:info('Info message')

-- -- Generate some log with a specific facility
-- local lsyslog = require 'lsyslog'
-- logger = syslog('luasyslog2', lsyslog.FACILITY.CRON)
-- logger:warn('Warning message')
-- logger:error('Error message')
