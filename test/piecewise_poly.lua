-- spec and unit-test for the piecewise Polynomial class/module

local piecewise = require 'source.piecewise_poly'
local luaunit = require 'luaunit.luaunit'

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
    p:add(0, {1, -2}) -- for t≤0 return (1*t - 2)
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
    assertNotEquals(p1, nil)
    assertNotEquals(p1, {})
    assertEquals(p1, p2) --, 'unique empty instances')
    
    p1:add(3, {4, 0, -0.32, 0})
    assertNotEquals(p1, p2)
    
    p2:add(3, {4, 0, -0.32, 0})
    assertEquals(p1, p2)
    assertEquals(piecewise.areEqual(p1, p2), true)
    
    p1:add(4, {3, 2})
    p2:add(4, {2, 3})
    assertNotEquals(p1, p2)
    assertEquals(piecewise.areEqual(p1, p2), false)
end



TestRoot = {}
TestRoot.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestRoot.test_empty = function(self)
    assertEquals(self.p:root(7), {}, 'empty polynomial has no root')
end
--TestRoot.test_constant = function(self)
--end
TestRoot.test_quadratic_tworoots = function(self)
    self.p:add(3, {1, -3, 2}) 
    --  x^2 - 3x + 2
    --  x=(-b +/- sqrt(b^2 - 4ac)) / 2a 
    --> (3 +/-1) / 2
    assertEquals(self.p:root(0), {1, 2})
    assertEquals(self.p:root(), self.p:root(0), 'default root of zero')
end
--TestRoot.test_quadratic_noroot = function(self)
--end
--TestRoot.test_quadratic_oneroot = function(self)
--end
--TestRoot.test_quadratic_tworoots_valueshift = function(self)
--end
--TestRoot.test_multiple_pieces = function(self)
--end
TestRoot.test_value_typecheck = function(self)
    self.p:add(math.random(10), {1,1,1})
    for _,v in ipairs({true, {}, function() return 3 end, 'string'}) do
        assertError('value must be number, was: '..type(v),
                    self.p.root, self.p, v)
    end
end


--print('==== TEST PIECEWISE POLYNOMIAL PASSED ====')
luaunit:run()

