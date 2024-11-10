---@diagnostic disable: need-check-nil, undefined-field
local logging = require 'logging.core'
local is_windows = true -- logging.is_windows()

local impl = {}

local logger = nil

function impl.init()
    if is_windows then
        local console = require 'logging.console'
        logger = console()
    else
        local syslog = require 'logging.syslog'
        logger = syslog({
            ident = 'skynet',
        })
    end
end

function impl.reopen()
end

function impl.close()
end

function impl.set_level(level)
    logger:setLevel(level)
end

function impl.log(level, message)
    logger:log(level, message)
end

return impl
