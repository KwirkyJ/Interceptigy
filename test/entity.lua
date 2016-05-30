local luaunit = require 'luaunit.luaunit'
local entity  = require 'source.entity'



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
--TestGetPosition.setUp = function(self)
--    self.e = entity.new(0, math.random)
--end
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



TestGetTInt = {}
TestGetTInt.test_manip = function(self)
    local e = entity.new(50, math.random)
    e:setTInt(350)
    assertEquals(e:getTInt(), 350)
    e:setTInt()
    assertNil( e:getTInt() )
end



luaunit:run()

