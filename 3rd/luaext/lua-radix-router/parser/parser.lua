--- Parser path parser that parse a pattern path.
--
--

local Parser = {}

local parsers = {
  ["default"] = require "lua-radix-router.parser.style.default",
}

-- return a parser instance
function Parser.new(style)
  local parser = parsers[style]
  if not parser then
    return nil, "unknown parser style: " .. style
  end

  return parser.new()
end

return Parser
