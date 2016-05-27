local luaunit = require 'luaunit.luaunit'
local entity  = require 'source.entity'



TestNew = {}
TestNew.test_specified = function(self)
    local prev = entity.get_prev_id()
    local e = entity.new(2, 50, 40, 20, 10, {0xff, 0xad, 40})
    assertNotNil(e)
    assertEquals(e.id, prev+1)
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
--TODO: getPosition at time before 'now' results in error



luaunit:run()

