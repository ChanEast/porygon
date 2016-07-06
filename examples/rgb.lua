local porygon = require('porygon')

-- This code will generate a RGB flash pattern on the device,
-- with priority 7 (highest priority).

-- TODO: Add bluetooth-layer bindings.

local str2hex = function(str)
    local str, _ = str:gsub('.', function(s)
        return string.format('%02x', string.byte(s))
    end)

    return str
end

local packet = porygon.packet.build(0, 7, function(packet)
    local r = porygon.color.rgb8(255, 0, 0)
    local g = porygon.color.rgb8(0, 255, 0)
    local b = porygon.color.rgb8(0, 0, 255)
    local colors = {r, g, b}

    for i=0,15 do
        packet:add{duration = 250, color = colors[(i % 3) + 1], intensity = i % 8}
    end
end)

-- If we had a working bluetooth LE binding, we'd send it instead of printing
-- here:
print(str2hex(packet))
