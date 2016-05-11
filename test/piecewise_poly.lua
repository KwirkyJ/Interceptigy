-- spec and unit-test for the piecewise Polynomial class/module

local piecewise = require 'source.piecewise_poly'
local luaunit   = require 'luaunit.luaunit'



TestInsertAndEvaluate = {}
TestInsertAndEvaluate.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestInsertAndEvaluate.test_evaluate_empty = function(self)
    local p
    for i=1, 100 do
        p = piecewise.Polynomial()
        assertNil(p:evaluate(i-50), 'empty polynomial should be nil')
    end
end
TestInsertAndEvaluate.test_insert_errors = function(self)
    assertError('must have starting time', nil,
                self.p.insert, self.p, nil, {5, 3})
    assertError('start time must be number', nil,
                self.p.insert, self.p, '3', {3})
    assertError('coefficients must be table or only-numbers', nil,
                self.p.insert, self.p, 3, 0.2, '5', -7)
    assertError('coefficients table cannot be empty', nil,
                self.p.insert, self.p, 3, {})
end
TestInsertAndEvaluate.test_one_piece = function(self)
    self.p:insert(0, {1, -2})
    
    assertEquals(self.p:getStarts(), {0}, 
                 'confirm one piece which starts at zero')
    assertNil(self.p:evaluate(-1), 'pre-start should be undefined')
    assertEquals(self.p:evaluate(0), -2, 'f(0) -> 1*(0) + -2 -> -2')
    assertEquals(self.p:evaluate(5),  3, 'f(5) -> 1*(5) + -2 ->  3')
    
    assertEquals(self.p(5), self.p:evaluate(5), 
                'metatable call as alias for evaluate')
    assertEquals(piecewise.evaluate(self.p, 5), self.p:evaluate(5), 
                'module call to evaluate')
end
TestInsertAndEvaluate.test_insert_module_alias = function(self)
    piecewise.insert(self.p, 0, {1, 2})
    assertAlmostEquals(self.p(5), 5*1 + 2, 1e-12)
end
TestInsertAndEvaluate.test_insert_vararg_coefficients = function(self)
    self.p:insert(0, -7, 2)
    assertAlmostEquals(self.p(5), 5*(-7) + 2, 1e-12)
end
TestInsertAndEvaluate.test_more_pieces = function(self)
    self.p:insert(3,  -0.5, 3, 0, 2)
    self.p:insert(0,           1,-2) -- added before extant
    self.p:insert(2.2,            8) -- inserted between extant
    
    assertEquals(self.p:getStarts(), {0,2.2,3}, 
                 'three additions should self-order by startig time')
    assertNil(self.p(-1), 'pre-start must be undefined')
    assertEquals(self.p(1), -1, 'first piece domain; 1*1 - 2')
    assertEquals(self.p(2.5), 8, 'inserted linear function')
    assertAlmostEquals(self.p(5), (-0.5*5^3 + 3*5^2 + 2), 1e-12, 'cubic')
end

TestGetStarts = {}
TestGetStarts.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestGetStarts.test_empty = function(self)
    assertEquals(self.p:getStarts(), {}, 'empty polynomial has no starts')
    assertEquals(piecewise.getStarts(self.p), {}, 'module call')
end
TestGetStarts.test_with_pieces = function(self)
    self.p:insert(0,    3,-2)
    self.p:insert(-4.3, 3, 1)
    self.p:insert(8,       7)
    self.p:insert(5,   -3,-2)
    assertEquals(self.p:getStarts(), {-4.3,0,5,8}, 'order by starting time')
end

TestClearBefore = {}
TestClearBefore.test_clearBefore = function(self)
    local p = piecewise.Polynomial()
    p:insert(0,          1,-2) -- for t>=0 return (1*t - 2)
    p:insert(2,             8)
    p:insert(3, -0.5, 3, 0, 2) -- -1/2*t^3 + 3*t^2 + 0*t + 2 
    
    p:clearBefore(2.2)
    assertEquals(p:getStarts(), {2.2, 3}, 'clearBefore should trim')
    assertEquals(p(2.99), 8)
    assertEquals(p(3), -0.5*3^3 + 3*3^2 + 2)
    assertNil(p(2.1999), 'new undefined region')
end

TestAreEquals = {}
TestAreEquals.test_equality = function(self)
    local p1, p2 = piecewise.Polynomial(), piecewise.Polynomial()
    assertError(piecewise.areEqual, p1, nil)
    assert(p1 ~= nil)
    --assert(not piecewise.areEqual(p1, nil))
    assert(not piecewise.areEqual(p1,  {}))
    assert(piecewise.areEqual(p1, p2), 'unique instances')
    assert(p1 == p2, 'metatable allows ==')
    
    p1:insert(3, {4, 0, -0.32, 0})
    assert(not piecewise.areEqual(p1, p2))
    assert(p1 ~= p2)
    
    p2:insert(3, {4, 0, -0.32, 0})
    assert(piecewise.areEqual(p1, p2))
    assert(p1 == p2)
    
    p1:insert(4, {3, 2})
    p2:insert(4, {2, 3})
    assert(p1 ~= p2)
    assert(not piecewise.areEqual(p1, p2))
end

TestInterlace = {}
TestInterlace.test_interlace = function(self)
    local p1= piecewise.Polynomial()
    p1:insert(-1,        1,   9)
    p1:insert( 0,     2, 0.5, 0)
    p1:insert( 4, -3, 0, 3,   2)
    p1:insert( 9,  1, 1, 1,   1)
    local p2 = piecewise.Polynomial()
    p2:insert( 1,     1, 0,  -4.2)
    p2:insert( 3, -2,-1, 0,   0.5)
    p2:insert( 4,             6)
    local expected = {-1, 0, 1, 3, 4, 9}
    assertEquals(piecewise.interlace(p1, p2), expected)
    assertEquals(piecewise.interlace(p2, p1), expected,
                 'order of arguments is unimportant')
    assertEquals(p1:interlace(p2), expected)
    assertEquals(p2:interlace(p1), expected)
end

TestOperations = {}
TestOperations.test_subtract = function(self)
    local p1= piecewise.Polynomial()
    p1:insert(0, {    2, 0.5, 0})
    p1:insert(4, {-3, 0, 3,   2})
    local p2 = piecewise.Polynomial()
    p2:insert(1, {    1, 0,  -4.2})
    p2:insert(3, {-2,-1, 0,   0.5})
    p2:insert(4, {            6})
    local expected = piecewise.Polynomial()
    expected:insert(0, {    2, 0.5, 0})
    expected:insert(1, {    1, 0.5, 4.2})
    expected:insert(3, { 2, 3, 0.5,-0.5})
    expected:insert(4, {-3, 0, 3,  -4})
    assertEquals(piecewise.subtract(p1, p2), expected)
end



TestRoot = {}
TestRoot.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestRoot.test_empty = function(self)
    assertEquals(self.p:root(7), {}, 'empty polynomial has no root')
end
TestRoot.test_constant = function(self)
    self.p:insert(-1, {4})
    assertEquals(self.p:root(0), {}, 'no root at 0')
    assertEquals(self.p:root(4), {{-1, math.huge}},
                 'constant match has range of roots')
end
TestRoot.test_constant_piece = function(self)
   self.p:insert(0, {4})
   self.p:insert(5, {-3})
   assertEquals(self.p:root( 4), {{0, 5}})
   assertEquals(self.p:root(-3), {{5, math.huge}})
   assertEquals(self.p:root( 0), {})
end
TestRoot.test_linear = function(self)
    self.p:insert(0, {-0.5, 4})
    assertEquals(self.p:root(), {8})
end
TestRoot.test_linear_under_domain = function(self)
    self.p:insert(10, {-0.5, 4})
    assertEquals(self.p:root(), {})
end
TestRoot.test_linear_over_domain = function(self)
    self.p:insert(0, {-0.5, 4})
    self.p:insert(5, {3})
    assertEquals(self.p:root(), {})
end
TestRoot.test_linear_pieces = function(self)
    self.p:insert(-5, {1,   3}) -- root at -3
    self.p:insert( 2, {2, -22}) -- root at 11
    self.p:insert(13, {0.5,-5}) -- root at 10, below piece's domain
    assertEquals(self.p:root(0), {-3, 11})
end
TestRoot.test_quadratic_noroot = function(self)
    self.p:insert(-3, {1, 0, 1}) -- x^2 + 1
    assertEquals(self.p:root(), {})
end
TestRoot.test_quadratic_oneroot = function(self)
    self.p:insert(-3, {1, 0, 0}) -- x^2
    assertEquals(self.p:root(), {0})
end
TestRoot.test_quadratic_tworoots = function(self)
    self.p:insert(-3, {1, -3, 2})
    assertEquals(self.p:root(0), {1, 2})
    assertEquals(self.p:root(), self.p:root(0), 'default root of zero')
end
TestRoot.test_quadratic_tworoots_valueshift = function(self)
    self.p:insert(-2, {-1, 0, 0})
    assertEquals(self.p:root(-2), {-2^0.5, 2^0.5})
end
TestRoot.test_quadratic_zero_x_squared = function(self)
    self.p:insert(2, {0, 0.3, -3})
    assertEquals(self.p:root(), {10})
end
TestRoot.test_multiple_pieces = function(self)
    self.p:insert( 3, {2, -10})
    self.p:insert(10, {3})
    self.p:insert(12, {0, 0, 5})
    self.p:insert(20, {-0.2, 0, 99})
    assertEquals(self.p:root(3),
                 {6.5, 
                  {10,12},
                  480^0.5, -- ~21.9
                 })
end
TestRoot.test_cubic = function(self)
    self.p:insert(2, {3, -3, 0.667, -7.5})
    assertError('cubic is not supported', nil,
                self.p.root, self.p, 0)
end
TestRoot.test_value_typecheck = function(self)
    self.p:insert(math.random(10), {1,1,1})
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
    assertEquals(self.p:getDerivative(), piecewise.Polynomial())
end
TestDerive.test_pieces = function(self)
    self.p:insert( 3, {5,  0, 0, 0.5, 2})
    self.p:insert(20, {          3, -12})
    self.p:insert(22, {             120})
    self.p:insert(30, {      -4, 1,   1})
    local e = piecewise.Polynomial()
    e:insert( 3, {20, 0, 0, 0.5})
    e:insert(20, {          3})
    e:insert(22, {          0})
    e:insert(30, {      -8, 1})
    assertEquals(self.p:getDerivative(), e)
end
TestDerive.test_getGrowth_empty = function(self)
    assertNil(self.p:getGrowth(2.2))
end
TestDerive.test_getGrowth = function(self)
    self.p:insert(2.5, {-1.2, 8, 3})
    assertNil(self.p:getGrowth(2.2))
    assertAlmostEquals(self.p:getGrowth(6), -2.4*6 + 8, 1e-12)
end



--print('==== TEST PIECEWISE POLYNOMIAL PASSED ====')
luaunit:run()

