local skynet = require "skynet"
require "skynet.manager"

local impl = require("service.logger.impl")

local CMD = {}

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    unpack = skynet.tostring,
    dispatch = function(_, _, level, msg)
        impl.log(level, msg)
    end
}

skynet.register_protocol {
    name = "SYSTEM",
    id = skynet.PTYPE_SYSTEM,
    unpack = function(...) return ... end,
    dispatch = function(_, source)
        -- reopen signal
        impl.reopen()
    end
}

skynet.init(function()
    impl.init()
end)

function CMD.set_level(level)
    impl.set_level(level)
end

function CMD.shutdown()
    impl.close()
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        assert(CMD[cmd])(...)
    end)
    skynet.register(".logger")
end)
