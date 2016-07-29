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

    local valid_number = function(x)
        return is_a(x, 'number')
    end
    local valid_normal = function(x)
        return is_a(x, 'number') and
               x >= 0.0 and x <= 1.0
    end
    local valid_8bit = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= 0xff
    end
    local valid_4bit = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= 0xf
    end
    local valid_3bit = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= 7
    end

    porygon.color = ctor(function(color, obj)
        -- Nothing for now
    end, {x = valid_number, y = valid_number, z = valid_number})

    local multiply_color = function(m, a, b, c)
        if #m ~= 9 then
            err 'invalid matrix'
        end

        return
            m[1] * a + m[2] * b + m[3] * c,
            m[4] * a + m[5] * b + m[6] * c,
            m[7] * a + m[8] * b + m[9] * c
    end

    local round_color = function(x, scale)
        return math.floor(scale * x + 0.5)
    end

    local cie1931_forward = {
        -- CIE 1931 specifies the transform in fixed-precision
        0.49000, 0.31000, 0.20000,
        0.17697, 0.81240, 0.01063,
        0.00000, 0.01000, 0.99000
    }

    local cie1931_inverse = {
        -- This transform is approximate
        0.41847, -0.15866, -0.082835,
        -0.091169, 0.25243, 0.015708,
        0.00092090, -0.0025498, 0.17860
    }

    do
        -- The forward matrix is postmultiplied by a constant, do that now
        local tmp = cie1931_forward[4]
        for i, v in ipairs(cie1931_forward) do
            cie1931_forward[i] = v / tmp
        end
    end

    porygon.color.rgb = function(r, g, b)
        if not valid_normal(r) or not valid_normal(g) or not valid_normal(b) then
            err 'invalid RGB values'
        end

        local x, y, z = multiply_color(cie1931_forward, r, g, b)
        return porygon.color.new{x = x, y = y, z = z}
    end

    porygon.color.rgb8 = function(r, g, b)
        if not valid_8bit(r) or not valid_8bit(g) or not valid_8bit(b) then
            err 'invalid 8-bit RGB values'
        end

        return porygon.color.rgb(r / 0xff, g / 0xff, b / 0xff)
    end

    porygon.color.rgb4 = function(r, g, b)
        if not valid_4bit(r) or not valid_4bit(g) or not valid_4bit(b) then
            err 'invalid 4-bit RGB values'
        end

        return porygon.color.rgb(r / 0xf, g / 0xf, b / 0xf)
    end

    function porygon.color:equals(other)
        return is_instance(other, porygon.color) and
               self.x == other.x and
               self.y == other.y and
               self.z == other.z
    end

    function porygon.color:lerp(other, ratio)
        local interp = function(a, b)
            return a + (b - a) * ratio
        end

        return porygon.color.new{
            x = interp(self.x, other.x),
            y = interp(self.y, other.y),
            z = interp(self.z, other.z)
        }
    end

    function porygon.color:to_rgb()
        return multiply_color(cie1931_inverse, self.x, self.y, self.z)
    end

    function porygon.color:to_rgb8()
        local r, g, b = self:to_rgb()
        return
            round_color(r, 0xff),
            round_color(g, 0xff),
            round_color(b, 0xff)
    end

    function porygon.color:to_rgb4()
        local r, g, b = self:to_rgb()
        return
            round_color(r, 0xf),
            round_color(g, 0xf),
            round_color(b, 0xf)
    end

    local max_duration = 0xff * 50
    local valid_duration = function(x)
        return is_a(x, 'number') and
               x >= 0 and x <= max_duration
    end
    local valid_color = function(x)
        return is_instance(x, porygon.color)
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

    porygon.control = ctor(function(control, obj)
        control.patterns = {}
        control.delay = round_duration(control.delay)
    end, {delay = valid_duration, priority = valid_3bit})

    function porygon.control:equals(other)
        local continue = is_instance(other, porygon.control) and
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
    function porygon.control:add(obj)
        if #self.patterns == max_patterns then
            err('too many patterns, max is %d', max_patterns)
        end
        table.insert(self.patterns, porygon.pattern.new(obj))
    end

    function porygon.control:pack()
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
            local r, g, b = p.color:to_rgb4()
            table.insert(packet, m50e(p.duration))
            table.insert(packet, bit32.bor(
                                     bit32.lshift(bit32.extract(g, 0, 4), 4),
                                     bit32.extract(r, 0, 4)))
            table.insert(packet, bit32.bor(
                                     bit32.lshift(p.interpolate and 1 or 0, 7),
                                     bit32.lshift(bit32.extract(p.intensity, 0, 3), 4),
                                     bit32.extract(b, 0, 4)))
        end

        return string.char(table.unpack(packet))
    end

    porygon.control.build = function(delay, priority, fn)
        local packet = porygon.control.new{delay = delay, priority = priority}
        if is_a(fn, 'function') then
            fn(packet)
        end
        return packet
    end

    porygon.control.unpack = function(message)
        if not is_a(message, 'string') then
            err('control packet must be a string')
        end

        local len = string.len(message)
        if len < 4 or (len - 4) % 3 ~= 0 then
            err('control packet length `%d` is invalid', len)
        end

        local delay = m50d(string.byte(message, 1))
        local patterns = string.byte(message, 4)
        local priority = bit32.extract(patterns, 5, 3)
        patterns = bit32.extract(patterns, 0, 5)
        if (len - 4) / 3 ~= patterns then
            err('control packet has invalid length for %d %s',
                  patterns, patterns == 1 and 'pattern' or 'patterns')
        end

        local packet = porygon.control.new{delay = delay, priority = priority}
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

    local valid_tag = function(t)
        if is_a(t, 'string') then
            local len = string.len(t)
            return len > 0 and len <= 16
        else
            return false
        end
    end

    local valid_payload = function(p)
        return is_a(p, 'string')
    end

    porygon.message = ctor(function(msg)

    end, {tag = valid_tag, payload = valid_payload})

    porygon.device = ctor(function(device)
        device:_init()
    end)

    function porygon.device:color(color)
        if not valid_color(color) then
            err 'invalid color'
        end

        self:_set_color(color)
    end

    function porygon.device:get_color()
        return self:_get_color()
    end

    function porygon.device:vibrate(level)
        if not valid_3bit(level) then
            err 'invalid vibration level'
        end

        self:_set_vibrate(level)
    end

    function porygon.device:get_vibrate()
        return self:_get_vibrate()
    end

    function porygon.device:_init()
        -- Simulated "hardware" API:
        -- start with the LEDs "off" and the motor "not vibrating"
        self.current_color = porygon.color.rgb4(0, 0, 0)
        self.current_vibrate = 0
    end

    function porygon.device:_get_color()
        -- Simulated "hardware" API
        return self.current_color
    end

    function porygon.device:_get_vibrate()
        -- Simulated "hardware" API
        return self.current_vibrate
    end

    function porygon.device:_set_color(color)
        -- Simulated "hardware" API
        self.current_color = color
    end

    function porygon.device:_set_vibrate(vibrate)
        -- Simulated "hardware" API
        self.current_vibrate = vibrate
    end

    return porygon
end)()
