--- 获取字符串真实长度
---@param inputStr string
---@return number
string.mb_len = function(inputStr)
    local lenInByte = #inputStr
    local width = 0
    local i = 1
    while (i <= lenInByte) do
        local curByte = string.byte(inputStr, i)
        local byteCount = 1
        if curByte > 0 and curByte <= 127 then
            byteCount = 1 -- 1字节字符
        elseif curByte >= 192 and curByte < 223 then
            byteCount = 2 -- 双字节字符
        elseif curByte >= 224 and curByte < 239 then
            byteCount = 3 -- 汉字
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4 -- 4字节字符
        end
        i = i + byteCount -- 重置下一字节的索引
        width = width + 1 -- 字符的个数（长度）
    end
    return width
end

--- 根据值获取一个key
---@param t string
---@return string
string.vkey = function(t)
    if (type(t) == "string") then
        return t
    elseif (type(t) == "table") then
        local j = ""
        if (#t > 0) then
            for _, v in ipairs(t) do
                if (type(v) == "table") then
                    v = "_T_"
                else
                    v = tostring(v)
                end
                j = j .. v
            end
        else
            j = "_"
        end
        return j
    end
end

--- 转义
---@param s string
---@return string
string.addslashes = function(s)
    local in_char = { "\\", '"', "/", "\b", "\f", "\n", "\r", "\t" }
    local out_char = { "\\", '"', "/", "b", "f", "n", "r", "t" }
    for i, c in ipairs(in_char) do
        s = s:gsub(c, "\\" .. out_char[i])
    end
    return s
end

--- 反转义
---@param s string
---@return string
string.stripslashes = function(s)
    local in_char = { "\\", '"', "/", "b", "f", "n", "r", "t" }
    local out_char = { "\\", '"', "/", "\b", "\f", "\n", "\r", "\t" }

    for i, c in ipairs(in_char) do
        s = s:gsub("\\" .. c, out_char[i])
    end
    return s
end

--- base64编码
---@param source_str string
---@return string
string.base64Encode = function(source_str)
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local s64 = ""
    local str = source_str

    while #str > 0 do
        local bytes_num = 0
        local buf = 0

        for byte_cnt = 1, 3 do
            buf = (buf * 256)
            if #str > 0 then
                buf = buf + string.byte(str, 1, 1)
                str = string.sub(str, 2)
                bytes_num = bytes_num + 1
            end
        end

        for group_cnt = 1, (bytes_num + 1) do
            local b64char = math.fmod(math.floor(buf / 262144), 64) + 1
            s64 = s64 .. string.sub(b64chars, b64char, b64char)
            buf = buf * 64
        end

        for fill_cnt = 1, (3 - bytes_num) do
            s64 = s64 .. "="
        end
    end

    return s64
end

-- base64解码
---@param str64 string
---@return string
string.base64Decode = function(str64)
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local temp = {}
    for i = 1, 64 do
        temp[string.sub(b64chars, i, i)] = i
    end
    temp["="] = 0
    local str = ""
    for i = 1, #str64, 4 do
        if i > #str64 then
            break
        end
        local data = 0
        local str_count = 0
        for j = 0, 3 do
            local str1 = string.sub(str64, i + j, i + j)
            if not temp[str1] then
                return
            end
            if temp[str1] < 1 then
                data = data * 64
            else
                data = data * 64 + temp[str1] - 1
                str_count = str_count + 1
            end
        end
        for j = 16, 0, -8 do
            if str_count > 0 then
                str = str .. string.char(math.floor(data / math.pow(2, j)))
                data = math.mod(data, math.pow(2, j))
                str_count = str_count - 1
            end
        end
    end

    local last = tonumber(string.byte(str, string.len(str), string.len(str)))
    if last == 0 then
        str = string.sub(str, 1, string.len(str) - 1)
    end
    return str
end

--- 把字符串以分隔符打散为数组
---@param delimeter string
---@param str string
---@return table
string.explode = function(delimeter, str)
    local res = {}
    local start, start_pos, end_pos = 1, 1, 1
    while true do
        start_pos, end_pos = string.find(str, delimeter, start, true)
        if not start_pos then
            break
        end
        table.insert(res, string.sub(str, start, start_pos - 1))
        start = end_pos + 1
    end
    table.insert(res, string.sub(str, start))
    return res
end

--- 把数组以分隔符拼接回字符串
---@param delimeter string
---@param table table
---@return string
string.implode = function(delimeter, table)
    local str
    for _, v in ipairs(table) do
        if (str == nil) then
            str = v
        else
            str = str .. delimeter .. v
        end
    end
    return str
end

--- 分隔字符串
---@param str string
---@param size number 每隔[size]字符切一次
---@return string
string.split = function(str, size)
    local sp = {}
    local len = string.len(str)
    if (len <= 0) then
        return sp
    end
    size = size or 1
    local i = 1
    while (i <= len) do
        table.insert(sp, string.sub(str, i, i + size - 1))
        i = i + size
    end
    return sp
end

--- 分隔字符串(支持中文)
---@param str string
---@param size number 每隔[size]个字切一次
---@return string
string.mb_split = function(str, size)
    local sp = {}
    local lenInByte = #str
    if (lenInByte <= 0) then
        return sp
    end
    local count = 0
    local i0 = 1
    local i = 1
    while (i <= lenInByte) do
        local curByte = string.byte(str, i)
        local byteCount = 1
        if curByte > 0 and curByte <= 127 then
            byteCount = 1 -- 1字节字符
        elseif curByte >= 192 and curByte < 223 then
            byteCount = 2 -- 双字节字符
        elseif curByte >= 224 and curByte < 239 then
            byteCount = 3 -- 汉字
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4 -- 4字节字符
        end
        count = count + 1 -- 字符的个数（长度）
        i = i + byteCount -- 重置下一字节的索引
        if (count >= size) then
            table.insert(sp, string.sub(str, i0, i - 1))
            i0 = i
            count = 0
        elseif (i > lenInByte) then
            table.insert(sp, string.sub(str, i0, lenInByte))
        end
    end
    return sp
end

--- 统计某个子串出现的首位,不包含返回false
---@param str string
---@param pattern string
---@return number|boolean
string.strpos = function(str, pattern)
    if (str == nil or pattern == nil) then
        return false
    end
    local s = string.find(str, pattern, 0)
    if (type(s) == "number") then
        return s
    else
        return false
    end
end

--- 找出某个子串出现的所有位置
---@param str string
---@param pattern string
---@return table
string.findAllPos = function(str, pattern)
    if (str == nil or pattern == nil) then
        return
    end
    local s
    local e = 0
    local res = {}
    while (true) do
        s, e = string.find(str, pattern, e + 1)
        if (s == nil) then
            break
        end
        table.insert(res, { s, e })
        if (e == nil) then
            break
        end
    end
    return res
end

--- 统计某个子串出现的次数
---@param str string
---@param pattern string
---@return number
string.findCount = function(str, pattern)
    if (str == nil or pattern == nil) then
        return
    end
    local s
    local e = 0
    local qty = 0
    while (true) do
        s, e = string.find(str, pattern, e + 1)
        if (s == nil) then
            break
        end
        qty = qty + 1
        if (e == nil) then
            break
        end
    end
    return qty
end

--- 获取属性table生成key
---@private
---@param val table
---@return string
string.attrBuffKey = function(val)
    local ks = {}
    local key = string.vkey(ks)
    ks = nil
    return key
end

local randChars = {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "~", "$", "#", "@", "!", "%", "^", "&", "*", "-", "+"
}

--- 随机字符串
---@param n number
---@return string
string.random = function(n)
    n = math.floor(n or 0)
    if (n <= 0) then
        return ""
    end
    local s = ""
    for _ = 1, n do
        s = s .. randChars[math.random(1, #randChars)]
    end
    return s
end

--- 移除字符串两侧的空白字符或其他预定义字符
---@param str string
---@return string
function string.trim(str)
    local res = string.gsub(str, "^%s*(.-)%s*$", "%1")
    return res
end