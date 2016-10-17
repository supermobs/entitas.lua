local stringutils = {}

function stringutils.split(s, p)
    if s == nil or string.len(s) == 0 then return {} end

    local result = {}
    while true do
        local pos,endp = string.find(s, p)
        if not pos then
            result[#result + 1] = s
            break
        end
        local sub_str = string.sub(s, 1, pos - 1)
        result[#result + 1] = sub_str
        s = string.sub(s, endp + 1)
    end
    return result
end

return stringutils