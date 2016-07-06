-- porygon: an unofficial Pokemon Go Plus SDK
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

return (function()
    local porygon = {}

    local is_a = function(x, t)
        return type(x) == t
    end

    local is_instance = function(x, tab)
        return getmetatable(x) == tab
    end

    local ctor = function(fn, types)
        local klass = {}
        klass.__index = klass

        local tablify = function(t)
            if not t then
                t = {}
            elseif not is_a(t, 'table') then
                error 'invalid constructor'
            end

            return t
        end

        -- Turn the types into a table
        types = tablify(types)
        for k, v in pairs(types) do
            if is_a(v, 'string') then
                types[k] = function(x)
                    return is_a(x, v)
                end
            end
        end

        klass.new = function(obj)
            local ret = {}
            setmetatable(ret, klass)
            ret.__index = ret

            -- Check types
            obj = tablify(obj)
            for k, v in pairs(types) do
                if not v(obj[k]) then
                    error('key `' .. k .. '` failed validation')
                else
                    ret[k] = obj[k]
                end
            end

            -- Call the constructor
            fn(ret, obj)
            return ret
        end
        return klass
    end

    local valid_rgb = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= 0xf
    end

    porygon.color = ctor(function(color, obj)
        -- Nothing for now
    end, {r = valid_rgb, g = valid_rgb, b = valid_rgb})

    porygon.color.rgb = function(r, g, b)
        local rgbto4 = function(v)
            if not is_a(v, 'number') or v < 0.0 or v > 1.0 then
                error('invalid floating-point RGB value')
            end

            return math.floor((v * 0xf) + 0.5)
        end

        return porygon.color.rgb4(rgbto4(r), rgbto4(g), rgbto4(b))
    end

    porygon.color.rgb8 = function(r, g, b)
        local rgb8to4 = function(v)
            if not is_a(v, 'number') or v < 0 or v > 0xff then
                error('invalid 8-bit RGB value')
            end

            -- Truncate the value by taking the upper 4 bits
            local w = bit32.rshift(v, 4)

            -- Decide if we should round the higher-order bits up
            if w < 0xf then
                v = bit32.band(v, 0xf)
                if v >= 0x8 then
                    w = w + 1
                end
            end

            return w
        end

        return porygon.color.rgb4(rgb8to4(r), rgb8to4(g), rgb8to4(b))
    end

    porygon.color.rgb4 = function(r, g, b)
        return porygon.color.new{r = r, g = g, b = b}
    end

    local max_duration = 0xff * 50
    local valid_duration = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= max_duration
    end
    local valid_color = function(x)
        return is_instance(x, porygon.color)
    end
    local valid_3bit = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= 7
    end

    porygon.pattern = ctor(function(pattern, obj)
        pattern.interpolate = (not not obj.interpolate)
    end, {duration = valid_duration, color = valid_color, intensity = valid_3bit})

    porygon.packet = ctor(function(packet, obj)
        packet.patterns = {}
    end, {delay = valid_duration, priority = valid_3bit})

    local m50e = function(ms)
        local ret = math.floor(ms / 50)
        if ret < 0 then
            error('provided value `' .. tostring(ms) ..
                  '` is too low; minimum is 0')
        elseif ret > 0xff then
            error('provided value `' .. tostring(ms) ..
                 '` is too high; maximum is ' .. tostring(max_duration))
        end
        return ret
    end

    local m50d = function(m50)
        if m50 < 0 or m50 > 0xff then
            error 'provided m50 value is out of range'
        end
        return m50 * 50
    end

    local max_patterns = 31
    function porygon.packet:add(obj)
        if #self.patterns == max_patterns then
            error('too many patterns, max is ' .. tostring(max_patterns))
        end
        table.insert(self.patterns, porygon.pattern.new(obj))
    end

    function porygon.packet:serialize()
        -- header (4 bytes)
        -- packet[0]: time to wait for input, in m50
        -- packet[1]: 0 (unknown: seen 2 and 254)
        -- packet[2]: 0 (unknown: seen 254)
        -- packet[3]: PPPNNNNN, where P is priority; N is number of patterns
        local packet = {
            m50e(self.duration),
            0,
            0,
            bit32.bor(bit32.lshift(bit32.extract(self.priority, 0, 3), 5),
                      bit32.extract(#self.patterns, 0, 5))
        }

        -- patterns (3n bytes)
        -- pattern[0]: duration, in m50
        -- pattern[1]: GGGGRRRR, where G is green; R is red
        -- pattern[2]: IVVVBBBB, where I is the "fade" bit, V is vibration level,
        -- and B is blue
        for i, p in ipairs(self.patterns) do
            local color = p.color
            table.insert(packet, m50e(p.duration))
            table.insert(packet, bit32.bor(
                                     bit32.lshift(bit32.extract(color.g, 0, 4), 4),
                                     bit32.extract(color.r, 0, 4)))
            table.insert(packet, bit32.bor(
                                     bit32.lshift(p.interpolate and 1 or 0, 7),
                                     bit32.lshift(bit32.extract(p.intensity, 0, 3), 3),
                                     bit32.extract(color.b, 0, 4)))
        end

        return string.char(table.unpack(packet))
    end

    porygon.packet.build = function(delay, priority, fn)
        local packet = porygon.packet.new{delay = delay, priority = priority}
        fn(packet)
        return packet:serialize()
    end

    return porygon
end)()
