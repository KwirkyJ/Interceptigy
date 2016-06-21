local luaunit      = require 'luaunit.luaunit'

local entity       = require 'source.entity'
local piecewise    = require 'source.piecewise_poly'
local trackfactory = require 'source.trackfactory'



TestNew = {}
TestNew.test_specified = function(self)
    local e = entity.new(2, 50, 40, 20, 10, {0xff, 0xad, 40})
    assertNotNil(e)
    assertNumber(e.id)
    local x, y = e:getPosition(5)
    assertAlmostEquals(x, 110, 1e-12) -- (5-2)*20 + 50
    assertAlmostEquals(y,  70, 1e-12) -- (5-2)*10 + 40
end
TestNew.test_random = function(self)
    local e = entity.new(0, math.random)
    assertNotNil(e)
    assertNumber(e.id)
    assertFunction(e.getPosition)
    local x, y = e:getPosition( math.random() )
    assertNumber(x)
    assertNumber(y)
end
TestNew.test_id_increment = function(self)
    local e1, e2 = entity.new(0, math.random), entity.new(0, math.random)
    assert(e1.id < e2.id)
end



TestGetPosition = {}
TestGetPosition.test_nominal = function(self)
    local e = entity.new(30, 50, 50, 2, 1.5, {255,255,255})
    assertEquals({e:getPosition(30)}, {50, 50})
    assertEquals({e:getPosition(80)}, {(80-30)*2+50, (80-30)*1.5+50})
end
TestGetPosition.test_before = function(self)
    local e = entity.new(30, 50, 50, 2, 1.5, {255,255,255})
    assertNil(e:getPosition(20))
end
TestGetPosition.test_typecheck = function(self)
    local e = entity.new(0, math.random)
    for _, t in pairs({a='4', b=nil, c={}, d=function() return end}) do
        assertError(e.getPosition, e, t)
    end
end



--TODO: TestSetPosition = {}
--TODO: TestGetVelocity = {}
--TODO: TestSetVelocity = {}
--TODO: TestUpdate = {}



TestGetTInt = {}
TestGetTInt.test_manip = function(self)
    local e = entity.new(50, math.random)
    e:setTInt(350)
    assertEquals(e:getTInt(), 350)
    e:setTInt()
    assertNil( e:getTInt() )
end



TestGetColor = {}
TestGetColor.test = function(self)
    local e = entity.new(50, math.random)
    assertTable(e:getColor())
    assertEquals(#e:getColor(), 3)
    for _,v in ipairs(e:getColor()) do
        assertNumber(v)
        assert(v >= 0, 'color value must be >= 0')
        assert(v <= 0xff, 'color value must be <= 255 (0xff)')
    end
end



TestManipTracks = {} --TODO: error cases
TestManipTracks.setUp = function(self)
    -- e.new(t, px, py, vx, vy, color)
    self.e = entity.new(20, 17, 65, 3, -0.3, {99,99,99})
    assert(self.e:getPosition(25) == 17+3*5) -- x position
    
    local s, c = math.sin(1), math.cos(1)
    local fx, fy = trackfactory.newParametric(20, 17,65, 3,-0.3, s,c)
    assert(fx == piecewise.Polynomial({20, s/2, 3,   17 - 3*20 - s/2*20^2}))
    assert(fy == piecewise.Polynomial({20, c/2,-0.3, 65 + 0.3*20 - c/2*20^2}))
    self.curve_a, self.curve_b = fx, fy
end
TestManipTracks.test_setTrack = function(self)
    -- newParametric(t, px, py, vx, vy, ax, ay)
    local newfx, newfy = trackfactory.newParametric(8, 2, 20, 0.4, 1)
    assert(newfx == piecewise.Polynomial({8, 0.4, 2-0.4*8}), 'newfx check')
    assert(newfy == piecewise.Polynomial({8, 1,  20-1*8}), 'newfy check')
    
    self.e:setTrack(newfx, newfy)
    assertNumber(self.e:getPosition(10)) -- x position
    local x, y = self.e:getPosition(30)
    assertAlmostEquals(x, 0.4*30 +(2-3.2), 1e-12)
end
TestManipTracks.test_getRealTrack_simple = function(self)
    local exp_x = piecewise.Polynomial({20,  3,   17 - 3*20})
    local exp_y = piecewise.Polynomial({20, -0.3, 65 + 0.3*20})
    local fx, fy = self.e:getRealTrack(30)
    assertEquals({fx, fy}, {exp_x, exp_y})
end
TestManipTracks.test_getRealTrack_accelerating = function(self) 
    self.e:setTrack(self.curve_a, self.curve_b)
    local fx, fy = self.e:getRealTrack(45)
    assertEquals({fx, fy}, {self.curve_a, self.curve_b})
end
TestManipTracks.test_getRealTrack_multipiece_built = function(self)
    local fx_app = trackfactory.tangent(42, self.curve_a)
    local fy_app = trackfactory.tangent(42, self.curve_b)
    local curve_aa = piecewise.insertPoly(self.curve_a, fx_app)
    local curve_bb = piecewise.insertPoly(self.curve_b, fy_app)
    self.e:setTrack(curve_aa, curve_bb)
    assertError(self.e.getRealTrack, self.e, 15)
    assertEquals({self.e:getRealTrack(28)}, {curve_aa, curve_bb})
    assertEquals({self.e:getRealTrack(50)}, {fx_app, fy_app})
end
TestManipTracks.test_getRealTrack_time_error = function(self)
    assertError(self.e.getRealTrack, self.e, 15) -- 15 < 20
end
--TestManipTracks.test_getProjectedTrack_simple = function(self) end
--TestManipTracks.test_getProjectedTrack_multipiece = function(self) end



luaunit:run()

