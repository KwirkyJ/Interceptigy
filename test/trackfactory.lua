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

TestTangents = {}
TestTangents.test_constant = function(self)
    local p = trackfactory.new(4, 8)
    local expect = piecewise.Polynomial(7, 8)
    assertEquals(trackfactory.tangent(p, 7), expect, 'line')
    assertEquals({trackfactory.tangentCoeffs(p, 7)}, {0, 0, 8})
    local a = 0.3
    local b = -2*a*7 -- 4.2
    local c = 8-a*7^2-b*7 -- 8-14.7-29.5 = -36.2
    expect = piecewise.Polynomial(7, a, b, c)
    assertEquals(trackfactory.tangent(p, 7, 0.3), expect)
    assertEquals({trackfactory.tangentCoeffs(p, 7, 0.3)}, {a, b, c})
end
TestTangents.test_linear = function(self)
    local p = trackfactory.new(4, -8, 3)
    assertEquals(p, piecewise.Polynomial(4, 3, -8-3*4))
    local expect = piecewise.Polynomial(7, 3, -8-3*4)
    assertEquals(trackfactory.tangent(p, 7), expect)
    assertEquals({trackfactory.tangentCoeffs(p, 7)}, {0, 3, -20})
    local a = -0.5
    local b = 3 - 2*a*7 -- 3-7 = -4
    local c = (3*7-20) - b*7 - a*7^2 -- 1 + 4*7 + 0.5*47 = 53.5
    expect = piecewise.Polynomial(7, a, b, c)
    assertEquals(trackfactory.tangent(p, 7, a), expect)
    assertEquals({trackfactory.tangentCoeffs(p, 7, -0.5)}, {a, b, c})
end
TestTangents.test_quadratic = function(self)
    local p = trackfactory.new(4, -8, 3, 2)
    assertEquals(p, piecewise.Polynomial(4, 1, 3, -36))
    local expect = trackfactory.new(7, 7^2 + 3*7 - 36, 2*7 + 3)
    assertEquals(trackfactory.tangent(p, 7), expect)
    local a = 0.1
    local b = p:getGrowth(9) - 2*a*9 --(2-(2*0.1))*9 + 3
    local c = p(9) - a*9^2 - b*9
    expect = piecewise.Polynomial(9, a, b, c)
    assertEquals(trackfactory.tangent(p, 9, a), expect)
    assertEquals({trackfactory.tangentCoeffs(p, 9, a)}, {a, b, c})
end
TestTangents.test_errors = function(self)
    local poly = piecewise.Polynomial(5, 3, 2)
    assertError('t must be a number',
                trackfactory.tangent, nil, nil)
    assertError('t must be a number',
                trackfactory.tangent, poly, nil)
    assertError('P must be a valid Polynomial',
                trackfactory.tangent, function() return end, 8)
    assertError('P must be a valid Polynomial',
                trackfactory.tangent, {5, {1,2}}, 8)
    assertError('Polynomial must be defined at time 2',
                trackfactory.tangent, poly, 2)
end



luaunit:run()

