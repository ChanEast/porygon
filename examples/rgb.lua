-- porygon: the unofficial Pokemon Go Plus SDK
--
-- Copyright (C) 2016 Morgan Jones
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

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

local packet = porygon.control.build(0, 7, function(packet)
    local r = porygon.color.rgb8(255, 0, 0)
    local g = porygon.color.rgb8(0, 255, 0)
    local b = porygon.color.rgb8(0, 0, 255)
    local colors = {r, g, b}

    for i=0,15 do
        packet:add{duration = 250, color = colors[(i % 3) + 1], intensity = i % 8}
    end
end):pack()

-- If we had a working bluetooth LE binding, we'd send it instead of printing
-- here:
print(str2hex(packet))
