local piecewise    = require 'source.piecewise_poly'
local trackfactory = require 'source.trackfactory'
local luaunit      = require 'luaunit.luaunit'



TestNew = {}
TestNew.setUp = function(self)
end
TestNew.test_constant = function(self)
    local f = trackfactory.new(30, 88)
    assertEquals(f, piecewise.Polynomial({30, 88}))
    assertEquals(f(30),  88)
    assertEquals(f(333), 88)
end
TestNew.test_linear = function(self)
    local f = trackfactory.new(163, 20.5, -2.3)
    local expect = piecewise.Polynomial({163, -2.3, 20.5 - (-2.3*163)})
    assertEquals(f, expect)
end
TestNew.test_quadratic = function(self)
    local f = trackfactory.new(-5.5, 18, -4.2, 4)
    local expect = piecewise.Polynomial({-5.5, 4/2, -4.2, 18 - (-4.2)*(-5.5) - (4/2)*(-5.5)^2})
    assertEquals(f, expect)
end

TestParametric = {}
TestParametric.test_correctness = function(self)
    local expect_x = trackfactory.new(4, 5,   1, 2)
    local expect_y = trackfactory.new(4,-0.3, 6, 3)
    local actual_x, actual_y = trackfactory.newParametric(4, 5, -0.3, 1, 6, 2, 3)
    assertEquals({actual_x, actual_y}, 
                 {expect_x, expect_y})
end



luaunit:run()

