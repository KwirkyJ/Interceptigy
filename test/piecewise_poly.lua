-- spec and unit-test for the piecewise Polynomial class/module

local piecewise = require 'source.piecewise_poly'
local luaunit   = require 'luaunit.luaunit'

local pp, tmp

pp = piecewise.Polynomial()
TestPolynomial = {}
TestPolynomial.test_empty = function(self)
    local p
    for i=1, 100 do
        p = piecewise.Polynomial()
        assertNil(p(i-50), 'empty polynomial should be nil')
    end
end
TestPolynomial.test_addition_errors = function(self)
    local p = piecewise.Polynomial()
    assertError('must have starting time', nil,
                p.add, p, nil, {5, 3})
    assertError('start time must be number', nil,
                p.add, p, '3', {3})
    assertError('coefficients must be table', nil,
                p.add, p, 3, '5')
    assertError('coefficients cannot be empty', nil,
                p.add, p, 3, {})
end
TestPolynomial.test_one_piece = function(self)
    local p = piecewise.Polynomial()
    p:add(0, {1, -2})
    
    assertEquals( p:getStarts(), {0}, 'confirm one piece which starts at zero')
    assertNil(p:evaluate(-1), 'pre-start should be undefined')
    assertEquals(p:evaluate(0), -2, 'f(0) -> 1*(0) + -2 -> -2')
    assertEquals(p:evaluate(5),  3, 'f(5) -> 1*(5) + -2 ->  3')
    
    assertEquals(p(5), p:evaluate(5), 'metatable call as alias for evaluate')
end
TestPolynomial.test_more_pieces = function(self)
    local p = piecewise.Polynomial()
    p:add(3, {-0.5, 3, 0, 2})
    p:add(0, {1, -2}) -- added before extant
    p:add(2.2, {8})   -- inserted between extant
    
    assertEquals(p:getStarts(), {0,2.2,3}, 'three additions should self-order')
    assertNil(p(-1), 'pre-start must be undefined')
    assertEquals(p(1), -1, 'first piece domain; 1*1 - 2')
    assertEquals(p(2.5), 8, 'inserted linear function')
    assertAlmostEquals(p(5), (-0.5*5^3 + 3*5^2 + 2), 1e-12, 'cubic')
end
TestPolynomial.test_clearBefore = function(self)
    local p = piecewise.Polynomial()
    p:add(0, {1, -2}) -- for t>=0 return (1*t - 2)
    p:add(2, {8})
    p:add(3, {-0.5, 3, 0, 2}) -- -1/2*t^3 + 3*t^2 + 0*t + 2 
    
    p:clearBefore(2.2)
    assertEquals(p:getStarts(), {2.2, 3}, 'clearBefore should trim')
    assertEquals(p(2.99), 8)
    assertEquals(p(3), -0.5*3^3 + 3*3^2 + 2)
    assertNil(p(2.1999), 'new undefined region')
end
TestPolynomial.test_equality = function(self)
    local p1, p2 = piecewise.Polynomial(), piecewise.Polynomial()
    assertError(piecewise.areEqual, p1, nil)
    assert(p1 ~= nil)
    --assert(not piecewise.areEqual(p1, nil))
    assert(not piecewise.areEqual(p1,  {}))
    assert(piecewise.areEqual(p1, p2), 'unique instances')
    assert(p1 == p2, 'metatable allows ==')
    
    p1:add(3, {4, 0, -0.32, 0})
    assert(not piecewise.areEqual(p1, p2))
    assert(p1 ~= p2)
    
    p2:add(3, {4, 0, -0.32, 0})
    assert(piecewise.areEqual(p1, p2))
    assert(p1 == p2)
    
    p1:add(4, {3, 2})
    p2:add(4, {2, 3})
    assert(p1 ~= p2)
    assert(not piecewise.areEqual(p1, p2))
end



TestRoot = {}
TestRoot.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestRoot.test_empty = function(self)
    assertEquals(self.p:root(7), {}, 'empty polynomial has no root')
end
TestRoot.test_constant = function(self)
    self.p:add(-1, {4})
    assertEquals(self.p:root(0), {}, 'no root at 0')
    assertEquals(self.p:root(4), {{-1, math.huge}},
                 'constant match has range of roots')
end
TestRoot.test_constant_piece = function(self)
   self.p:add(0, {4})
   self.p:add(5, {-3})
   assertEquals(self.p:root( 4), {{0, 5}})
   assertEquals(self.p:root(-3), {{5, math.huge}})
   assertEquals(self.p:root( 0), {})
end
TestRoot.test_linear = function(self)
    self.p:add(0, {-0.5, 4})
    assertEquals(self.p:root(), {8})
end
TestRoot.test_linear_under_domain = function(self)
    self.p:add(10, {-0.5, 4})
    assertEquals(self.p:root(), {})
end
TestRoot.test_linear_over_domain = function(self)
    self.p:add(0, {-0.5, 4})
    self.p:add(5, {3})
    assertEquals(self.p:root(), {})
end
TestRoot.test_linear_pieces = function(self)
    self.p:add(-5, {1,   3}) -- root at -3
    self.p:add( 2, {2, -22}) -- root at 11
    self.p:add(13, {0.5,-5}) -- root at 10, below piece's domain
    assertEquals(self.p:root(0), {-3, 11})
end
TestRoot.test_quadratic_noroot = function(self)
    self.p:add(-3, {1, 0, 1}) -- x^2 + 1
    assertEquals(self.p:root(), {})
end
TestRoot.test_quadratic_oneroot = function(self)
    self.p:add(-3, {1, 0, 0}) -- x^2
    assertEquals(self.p:root(), {0})
end
TestRoot.test_quadratic_tworoots = function(self)
    self.p:add(-3, {1, -3, 2})
    assertEquals(self.p:root(0), {1, 2})
    assertEquals(self.p:root(), self.p:root(0), 'default root of zero')
end
TestRoot.test_quadratic_tworoots_valueshift = function(self)
    self.p:add(-2, {-1, 0, 0})
    assertEquals(self.p:root(-2), {-2^0.5, 2^0.5})
end
TestRoot.test_quadratic_zero_x_squared = function(self)
    self.p:add(2, {0, 0.3, -3})
    assertEquals(self.p:root(), {10})
end
TestRoot.test_multiple_pieces = function(self)
    self.p:add( 3, {2, -10})
    self.p:add(10, {3})
    self.p:add(12, {0, 0, 5})
    self.p:add(20, {-0.2, 0, 99})
    assertEquals(self.p:root(3),
                 {6.5, 
                  {10,12},
                  480^0.5, -- ~21.9
                 })
end
TestRoot.test_cubic = function(self)
    self.p:add(2, {3, -3, 0.667, -7.5})
    assertError('cubic is not supported', nil,
                self.p.root, self.p, 0)
end
TestRoot.test_value_typecheck = function(self)
    self.p:add(math.random(10), {1,1,1})
    for _,v in ipairs({true, {}, function() return 3 end, 'string'}) do
        assertError('value must be number, was: '..type(v),
                    self.p.root, self.p, v)
    end
end

TestDerive = {}
TestDerive.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestDerive.test_empty = function(self)
    assertEquals(self.p:getDerivatives(), piecewise.Polynomial())
end
TestDerive.test_pieces = function(self)
    self.p:add( 3, {5,  0, 0, 0.5, 2})
    self.p:add(20, {          3, -12})
    self.p:add(22, {             120})
    self.p:add(30, {      -4, 1,   1})
    local e = piecewise.Polynomial()
    e:add( 3, {20, 0, 0, 0.5})
    e:add(20, {          3})
    e:add(22, {          0})
    e:add(30, {      -8, 1})
    assertEquals(self.p:getDerivatives(), e)
end



--print('==== TEST PIECEWISE POLYNOMIAL PASSED ====')
luaunit:run()

