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

porygon.test = {}

porygon.test.env2bool = function(name)
    local ret = os.getenv(name)
    if ret ~= nil then
        ret = tonumber(ret)
        if not ret or ret == 0 then
            ret = false
        else
            ret = true
        end
    else
        ret = false
    end

    return ret
end

porygon.test.dump_table = function(table, nesting)
    nesting = nesting or 0
    for k, v in pairs(table) do
        k = tostring(k)
        print(string.rep('  ', nesting) .. k .. ' => ' .. tostring(v))
        if type(v) == 'table' and string.sub(k, 1, 1) ~= '_' then
            porygon.test.dump_table(v, nesting + 1)
        end
    end
end

porygon.test.compare_tables = function(a, b)
    print('=== First table')
    porygon.test.dump_table(a)
    print('=== Second table')
    porygon.test.dump_table(b)
end

function assert_equals(a, b)
    if type(a) == 'table' and type(b) == 'table' and
        type(a.equals) == 'function' and type(b.equals) == 'function' then
        local c, d = a:equals(b), b:equals(a)
        if not c or not d then
            porygon.test.compare_tables(a, b)
        end
        assert(c)
        assert(d)
    else
        assert(a == b)
    end
end

function assert_not_equals(a, b)
    if type(a) == 'table' and type(b) == 'table' and
        type(a.equals) == 'function' and type(b.equals) == 'function' then
        local c, d = a:equals(b), b:equals(a)
        if c or d then
            porygon.test.compare_tables(a, b)
        end
        assert(not c)
        assert(not d)
    else
        assert(a ~= b)
    end
end

local verbose = porygon.test.env2bool('VERBOSE')
function assert_throws(fn)
    local status, err = pcall(fn)
    assert(not status)
    assert(type(err) == 'string')
    if verbose then
        print('caught error in assert_throws: ' .. err)
    end
end

function fail()
    assert(false)
end

local test_color = function()
    local c1 = porygon.color.new{r = 0x1, g = 0x2, b = 0x3}
    local c2 = porygon.color.new{r = 0x1, g = 0x2, b = 0x3}
    local c3 = porygon.color.new{r = 0x4, g = 0x5, b = 0x6}
    assert_equals(c1, c2)
    assert_not_equals(c1, c3)
    assert_not_equals(c2, c3)
end

local test_color_invalid = function()
    assert_throws(function()
        porygon.color.new()
    end)

    assert_throws(function()
        porygon.color.new{g = 0, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, g = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = -1, g = 0, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0x10, g = 0, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, g = -1, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, g = 0x10, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, g = 0, b = -1}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, g = 0, b = 0x10}
    end)

    assert_throws(function()
        porygon.color.new{r = 'a', g = 0, b = 0}
    end)

    assert_throws(function()
        porygon.color.new{r = 0, g = {}, b = 0}
    end)

    assert_throws(function()
        porygon.color.rgb4{r = 0, g = 0, b = nil}
    end)
end

local test_color_rgb = function()
    local prototype = porygon.color.new{r = 0x7, g = 0xf, b = 0x0}
    local rgb = porygon.color.rgb(0.4666, 1.0, 0.0)
    assert_equals(prototype, rgb)
end

local test_color_rgb_invalid = function()
    assert_throws(function()
        porygon.color.rgb(-1, 0, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb(2, 0, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb(0, -1, 0)
    end)

    assert_throws(function()
        porygon.color.rgb(0, 2, 0)
    end)

    assert_throws(function()
        porygon.color.rgb(0, 0, -1)
    end)

    assert_throws(function()
        porygon.color.rgb(0, 0, 2)
    end)

    assert_throws(function()
        porygon.color.rgb('a', 0, 0)
    end)

    assert_throws(function()
        porygon.color.rgb(0, {}, 0)
    end)

    assert_throws(function()
        porygon.color.rgb(0, 0, nil)
    end)
end

local test_color_rgb8 = function()
    local prototype = porygon.color.new{r = 0x8, g = 0xf, b = 0x0}
    local rgb8 = porygon.color.rgb8(0x7f, 0xfc, 0x01)
    assert_equals(prototype, rgb8)
end

local test_color_rgb8_invalid = function()
    assert_throws(function()
        porygon.color.rgb8(-1, 0, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb8(0x100, 0, 0)
    end)

    assert_throws(function()
        porygon.color.rgb8(0, -1, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb8(0, 0x100, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb8(0, 0, -1)
    end)
    
    assert_throws(function()
        porygon.color.rgb8(0, 0, 0x100)
    end)
    
    assert_throws(function()
        porygon.color.rgb8('a', 0, 0)
    end)

    assert_throws(function()
        porygon.color.rgb8(0, {}, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb8(0, 0, nil)
    end)
end

local test_color_rgb4 = function()
    local prototype = porygon.color.new{r = 0x1, g = 0x2, b = 0x3}
    local rgb4 = porygon.color.rgb4(0x1, 0x2, 0x3)
    assert_equals(prototype, rgb4)
end

local test_color_rgb4_invalid = function()
    local status, err
    assert_throws(function()
        porygon.color.rgb4(-1, 0, 0)
    end)

    assert_throws(function()
        porygon.color.rgb4(0x10, 0, 0)
    end)

    assert_throws(function()
        porygon.color.rgb4(0, -1, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb4(0, 0x10, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb4(0, 0, -1)
    end)
    
    assert_throws(function()
        porygon.color.rgb4(0, 0, 0x10)
    end)

    assert_throws(function()
        porygon.color.rgb4('a', 0, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb4(0, {}, 0)
    end)
    
    assert_throws(function()
        porygon.color.rgb4(0, 0, nil)
    end)
end

local test_pattern = function()
    local c1 = porygon.color.new{r = 0x1, g = 0x2, b = 0x3}
    local c2 = porygon.color.new{r = 0x2, g = 0x1, b = 0x3}
    local p1 = porygon.pattern.new{duration = 125, color = c1, intensity = 7}
    local p2 = porygon.pattern.new{duration = 150, color = c1, intensity = 7}
    assert_equals(p1, p2) -- should round duration up

    local p3 = porygon.pattern.new{duration = 100, color = c1, intensity = 7}
    assert_not_equals(p1, p3)

    local p4 = porygon.pattern.new{duration = 125, color = c2, intensity = 7}
    assert_not_equals(p1, p4)

    local p5 = porygon.pattern.new{duration = 125, color = c1, intensity = 6}
    assert_not_equals(p1, p5)

    local p6 = porygon.pattern.new{duration = 125, color = c1, intensity = 7, interpolate = true}
    assert_not_equals(p1, p6)
end

local test_pattern_invalid = function()
    local color = porygon.color.new{r = 0x1, g = 0x2, b = 0x3}
    assert_throws(function()
        porygon.pattern.new()
    end)
    
    assert_throws(function()
        porygon.pattern.new{color = color, intensity = 7}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 42, intensity = 7}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 42, color = color}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = -1, color = color, intensity = 0}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 100000, color = color, intensity = 0}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 42, color = 42, intensity = 0}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 42, color = {}, intensity = 0}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 42, color = {}, intensity = -1}
    end)
    
    assert_throws(function()
        porygon.pattern.new{duration = 42, color = {}, intensity = 100}
    end)
end

local test_packet = function()
    local c1 = porygon.color.new{r = 0x1, g = 0x2, b = 0x3}
    local p1 = porygon.pattern.new{duration = 125, color = c1, intensity = 7}
    local packet1 = porygon.packet.build(25, 7, function(p)
        p:add(p1)
    end)
    local packet2 = porygon.packet.build(50, 7, function(p)
        p:add(p1)
    end)
    assert(#packet1.patterns == 1)
    assert_equals(packet1, packet2)

    local packet3 = porygon.packet.build(25, 6, function(p)
        p:add(p1)
    end)
    assert_not_equals(packet1, packet3)

    local packet4 = porygon.packet.build(25, 7, function(p)
    end)
    assert_not_equals(packet1, packet4)

    local packet5 = porygon.packet.build(25, 7, function(p)
        p:add(p1)
        p:add(p1)
    end)
    assert_not_equals(packet1, packet5)
end

local test_packet_invalid = function()
    assert_throws(function()
        porygon.packet.new()
    end)

    assert_throws(function()
        porygon.packet.new{priority = 7}
    end)

    assert_throws(function()
        porygon.packet.new{delay = 42}
    end)

    assert_throws(function()
        porygon.packet.new{delay = -1, priority = 0}
    end)

    assert_throws(function()
        porygon.packet.new{delay = 100000, priority = 0}
    end)

    assert_throws(function()
        porygon.packet.new{delay = 42, priority = -1}
    end)

    assert_throws(function()
        porygon.packet.new{delay = 42, priority = 100}
    end)
end

local test_packet_add = function()
    local packet = porygon.packet.new{delay = 42, priority = 4}
    local r = porygon.color.rgb8(255, 0, 0)
    local g = porygon.color.rgb8(0, 255, 0)
    local b = porygon.color.rgb8(0, 0, 255)
    local colors = {r, g, b}

    -- Add 31 patterns
    for i=1,31 do
        packet:add{duration = 42, color = colors[(i % 3) + 1], intensity = i % 8}
    end

    -- Attempt to add #32
    assert_throws(function()
        packet:add{duration = 42, color = r, intensity = 0}
    end)
end

function round_trip(original)
    local packed = original:pack()
    local unpacked = porygon.packet.unpack(packed)
    local repacked = unpacked:pack()
    assert_equals(original, unpacked)
    assert_equals(packed, repacked)
end

local test_packet_unpack = function()
    local empty_packet = porygon.packet.unpack("\0\0\0\0")
    assert_throws(function()
        porygon.packet.unpack(nil)
    end)

    assert_throws(function()
        -- Invalid length
        porygon.packet.unpack("")
    end)

    assert_throws(function()
        -- Invalid length
        porygon.packet.unpack("\0")
    end)

    assert_throws(function()
        -- Invalid length
        porygon.packet.unpack("\0\0\0\0\0")
    end)

    assert_throws(function()
        -- Says one, has zero
        porygon.packet.unpack("\0\0\0\1")
    end)

    assert_throws(function()
        -- Says one, has two
        porygon.packet.unpack("\0\0\0\1\0\0\0\1\1\1")
    end)

    assert_throws(function()
        -- Says 31, has 32
        local packet = "\0\0\0\31"
        for i=1,32 do
            local pattern = string.char(i, i, i)
            packet = packet .. pattern
        end
        porygon.packet.unpack(packet)
    end)
end

local test_packet_round_trip_empty = function()
    local original = porygon.packet.build(25, 0)
    round_trip(original)
end

local test_packet_round_trip_full = function()
    local original = porygon.packet.build(50, 7, function(packet)
        for i=1,31 do
            packet:add{
                duration = i,
                color = porygon.color.rgb(math.random(), math.random(), math.random()),
                intensity = i % 8
            }
        end
    end)

    round_trip(original)
end

local tests = {
    {color = test_color},
    {color_invalid = test_color_invalid},
    {color_rgb = test_color_rgb},
    {color_rgb_invalid = test_color_rgb_invalid},
    {color_rgb8 = test_color_rgb8},
    {color_rgb8_invalid = test_color_rgb8_invalid},
    {color_rgb4 = test_color_rgb4},
    {color_rgb4_invalid = test_color_rgb4_invalid},
    {pattern = test_pattern},
    {pattern_invalid = test_pattern_invalid},
    {packet = test_packet},
    {packet_invalid = test_packet_invalid},
    {packet_add = test_packet_add},
    {packet_unpack = test_packet_unpack},
    {packet_round_trip_empty = test_packet_round_trip_empty},
    {packet_round_trip_full = test_packet_round_trip_full}
}

print(string.format('== porygon test harness: running %d tests', #tests))
for i, t in ipairs(tests) do
    for k, v in pairs(t) do
        io.write(string.format('test %d (%s)...', i, k))
        local status, err = pcall(v)
        if status then
            print(" ok.")
        else
            print(string.format(" failed: %s", tostring(err)))
            print('Tests halted.')
            return 1
        end
    end
end

print('== All tests passed.')
return 0
