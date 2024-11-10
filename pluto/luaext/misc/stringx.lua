local stringx = {}

local NON_WHITECHARS_PAT = "%S+"
--- 根据分割符，将字符串拆分成字符串列表
-- @param[type=string] str 字符串
-- @param[type=string,opt] pat 拆分模式,默认按空白字符拆分
-- @param[type=int,opt=-1] maxsplit 最大拆分次数,不指定或为-1则不受限制
-- @return[type=table] 拆分后的字符串列表
-- @usage
-- local str = "a.b.c"
-- local list = string.split(str,".",1)  -- {"a","b"}
-- local list = string.split(str,".")    -- {"a","b","c"}
function stringx.split(str, pat, maxsplit)
    pat = pat and string.format("[^%s]+", pat) or NON_WHITECHARS_PAT
    maxsplit = maxsplit or -1
    local ret = {}
    local i = 0
    for s in string.gmatch(str, pat) do
        if not (maxsplit == -1 or i <= maxsplit) then
            break
        end
        table.insert(ret, s)
        i = i + 1
    end
    return ret
end

function stringx.urlencodechar(char)
    return string.format("%%%02X", string.byte(char))
end

function stringx.urldecodechar(hexchar)
    return string.char(tonumber(hexchar, 16))
end

function stringx.urlencode(str, patten, space2plus)
    patten = patten or "([^%w%.%- ])"
    str = string.gsub(str, patten, stringx.urlencodechar)
    if space2plus then
        str = string.gsub(str, " ", "+")
    end
    return str
end

function stringx.urldecode(str, plus2space)
    if plus2space then
        str = string.gsub(str, "+", " ")
    end
    str = string.gsub(str, "%%(%x%x)", stringx.urldecodechar)
    return str
end

return stringx
