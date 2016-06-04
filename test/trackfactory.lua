local trackfactory = require 'source.trackfactory'
local luaunit      = require 'luaunit.luaunit'



TestNew = {}
TestNew.setUp = function(self)
end
TestNew.test_static = function(self)
    local t, x, y = 30, 88, 66
    local fx, fy = trackfactory.new(t, x, y)
    assertEquals({fx(t), fy(t)}, {x, y})
    t = 333
    assertEquals({fx(t), fy(t)}, {x, y})
end
TestNew.test_linear = function(self)
    local t, px, py, vx, vy = 163, 20.5, -3, 1.2, 0.4
    local fx, fy = trackfactory.new(t, px, py, vx, vy)
    assertEquals({fx(t), fy(t)}, {20.5, -3})
    t = 184 -- dt = 21
    assertAlmostEquals(20.5+(1.2*21), 45.7, 1e-12)
    
    assertAlmostEquals(fx(t), 20.5+(1.2*21), 1e-12)
    assertAlmostEquals(fy(t), -3  +(0.4*21), 1e-12)
    assertAlmostEquals(fx(t), 1.2*t -175.1, 1e-12)
    assertAlmostEquals(fy(t), 0.4*t - 68.2, 1e-12)
end



luaunit:run()

