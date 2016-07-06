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

if _VERSION ~= 'Lua 5.2' then
    error("porygon requires Lua 5.2, you're running " .. _VERSION)
end

return (function()
    local porygon = {_VERSION = '0.2'}

    local err = function(fmt, ...)
        return error(string.format(fmt, ...))
    end

    local is_a = function(x, t)
        return type(x) == t
    end

    local is_instance = function(x, tab)
        return is_a(x, 'table') and getmetatable(x) == tab
    end

    local ctor = function(fn, types)
        local klass = {}
        klass.__index = klass

        local tablify = function(t)
            if not t then
                t = {}
            elseif not is_a(t, 'table') then
                err 'invalid constructor'
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
                    err('key `%s` failed validation', k)
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
                err('invalid floating-point RGB value')
            end

            return math.floor((v * 0xf) + 0.5)
        end

        return porygon.color.rgb4(rgbto4(r), rgbto4(g), rgbto4(b))
    end

    porygon.color.rgb8 = function(r, g, b)
        local rgb8to4 = function(v)
            if not is_a(v, 'number') or v < 0 or v > 0xff then
                err('invalid 8-bit RGB value')
            else
                v = math.floor(v)
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

    function porygon.color:equals(other)
        return is_instance(other, porygon.color) and
               self.r == other.r and
               self.g == other.g and
               self.b == other.b
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
    local round_duration = function(duration)
        return math.floor((duration / 50) + 0.5) * 50
    end

    porygon.pattern = ctor(function(pattern, obj)
        pattern.interpolate = (not not obj.interpolate)
        pattern.duration = round_duration(pattern.duration)
    end, {duration = valid_duration, color = valid_color, intensity = valid_3bit})

    function porygon.pattern:equals(other)
        return is_instance(other, porygon.pattern) and
               self.duration == other.duration and
               self.intensity == other.intensity and
               self.interpolate == other.interpolate and
               self.color:equals(other.color)
    end

    porygon.packet = ctor(function(packet, obj)
        packet.patterns = {}
        packet.delay = round_duration(packet.delay)
    end, {delay = valid_duration, priority = valid_3bit})

    function porygon.packet:equals(other)
        local continue = is_instance(other, porygon.packet) and
                         self.delay == other.delay and
                         self.priority == other.priority

        if not continue or #self.patterns ~= #other.patterns then
            return false
        end

        for i=1,#self.patterns do
            if not self.patterns[i]:equals(other.patterns[i]) then
                return false
            end
        end

        return true
    end

    local m50e = function(ms)
        local ret = math.floor(ms / 50)
        if ret < 0 then
            err('provided value `%d` is too low; minimum is 0', ms)
        elseif ret > 0xff then
            err('provided value `%d` is too high; maximum is %d', ms, max_duration)
        end
        return ret
    end

    local m50d = function(m50)
        if m50 < 0 or m50 > 0xff then
            err 'provided m50 value is out of range'
        end
        return m50 * 50
    end

    local max_patterns = 31
    function porygon.packet:add(obj)
        if #self.patterns == max_patterns then
            err('too many patterns, max is %d', max_patterns)
        end
        table.insert(self.patterns, porygon.pattern.new(obj))
    end

    function porygon.packet:pack()
        -- header (4 bytes)
        -- packet[0]: time to wait for input, in m50
        -- packet[1]: 0 (unknown: seen 2 and 254)
        -- packet[2]: 0 (unknown: seen 254)
        -- packet[3]: PPPNNNNN, where P is priority; N is number of patterns
        local packet = {
            m50e(self.delay),
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
                                     bit32.lshift(bit32.extract(p.intensity, 0, 3), 4),
                                     bit32.extract(color.b, 0, 4)))
        end

        return string.char(table.unpack(packet))
    end

    porygon.packet.build = function(delay, priority, fn)
        local packet = porygon.packet.new{delay = delay, priority = priority}
        if is_a(fn, 'function') then
            fn(packet)
        end
        return packet
    end

    porygon.packet.unpack = function(message)
        if not is_a(message, 'string') then
            err('message must be a string')
        end

        local len = string.len(message)
        if len < 4 or (len - 4) % 3 ~= 0 then
            err('message length `%d` is invalid', len)
        end

        local delay = m50d(string.byte(message, 1))
        local patterns = string.byte(message, 4)
        local priority = bit32.extract(patterns, 5, 3)
        patterns = bit32.extract(patterns, 0, 5)
        if (len - 4) / 3 ~= patterns then
            err('packet has invalid length for %d %s',
                  patterns, patterns == 1 and 'pattern' or 'patterns')
        end

        local packet = porygon.packet.new{delay = delay, priority = priority}
        local idx = 5

        for i=1,patterns do
            local duration = m50d(string.byte(message, idx))
            local r = string.byte(message, idx + 1)
            local g = bit32.extract(r, 4, 4)
            r = bit32.extract(r, 0, 4)
            local b = string.byte(message, idx + 2)
            local intensity = bit32.extract(b, 4, 3)
            local interpolate = bit32.extract(b, 7) ~= 0
            b = bit32.extract(b, 0, 4)

            packet:add{
                duration = duration,
                color = porygon.color.rgb4(r, g, b),
                intensity = intensity,
                interpolate = interpolate
            }
            idx = idx + 3
        end

        return packet
    end

    return porygon
end)()
