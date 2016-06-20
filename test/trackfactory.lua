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

TestTangent = {}
TestTangent.test_errors = function(self)
    local poly = piecewise.Polynomial({5, 3, 2})
    assertError('t must be a number',
                trackfactory.tangent, nil, nil)
    assertError('t must be a number',
                trackfactory.tangent, nil, poly)
    assertError('P must be a valid Polynomial',
                trackfactory.tangent, 8, function() return end)
    assertError('P must be a valid Polynomial',
                trackfactory.tangent, 8, {5, {1,2}})
    assertError('P(t) cannot be nil',
                trackfactory.tangent, 2, poly)
end
TestTangent.test_constant = function(self)
    local t1 = trackfactory.new(4, 8)
    local expect = piecewise.Polynomial({7, 8})
    assertEquals(trackfactory.tangent(7, t1), expect)
end
TestTangent.test_linear = function(self)
    local t1 = trackfactory.new(4, -8, 3)
    local expect     = piecewise.Polynomial({4, 3, -8 - 3*4})
    local expect_tan = piecewise.Polynomial({7, 3, -8 - 3*4})
    assertEquals(t1, expect)
    assertEquals(trackfactory.tangent(7, t1), expect_tan)
end
TestTangent.test_quadratic = function(self)
    local t1 = trackfactory.new(4, -8, 3, 2)
    local expect     = piecewise.Polynomial({4, 1, 3, -36})
    local expect_tan = trackfactory.new(7, 7^2 + 3*7 - 36, 2*7 + 3)
    assertEquals(t1, expect)
    assertEquals(trackfactory.tangent(7, t1), expect_tan)
end



luaunit:run()

