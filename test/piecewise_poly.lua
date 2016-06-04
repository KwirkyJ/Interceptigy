-- spec and unit-test for the piecewise Polynomial class/module

local piecewise = require 'source.piecewise_poly'
local luaunit   = require 'luaunit.luaunit'



--TODO? polynomials accept more than one variable
-- e.g.? f(x,y) = 4x^2 - 0.2x^2y + +1xy + 4xy^2 + 1/2y + 2001



TestPrepopulate = {}
TestPrepopulate.test_one_piece = function(self)
    local p = piecewise.Polynomial({4, 3, 2})
    assertNil(p(3.3), 'before first piece')
    assertEquals(p(9), 3*9 + 2)
end
TestPrepopulate.test_more_pieces = function(self)
    local p = piecewise.Polynomial({3, 2}, {-2, 5, 3, 2}, {6, 3})
    assertEquals(p:getStarts(), {-2, 3, 6})
end
TestPrepopulate.test_errors = function(self)
    assertError('supplied arguments must be tables',
                piecewise.Polynomial, 5, 1, 3)
    assertError('table must have at least two numbers (at 3)',
                piecewise.Polynomial, {0,1,2}, {4,2,1}, {5}, {5,3})
end
TestPrepopulate.test_zero = function(self)
    local p = piecewise.Polynomial({5, 0})
    assertNil(p(4))
    assertEquals(p(10), 0)
end

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
    assertError('coefficients table cannot be nil', nil,
                self.p.insert, self.p, 3)
end
TestInsertAndEvaluate.test_one_piece = function(self)
    self.p:insert(0, {1, -2})
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
TestInsertAndEvaluate.test_zero = function(self)
    self.p:insert(5, 0)
    assertNil(self.p(1))
    assertEquals(self.p(7), 0)
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
TestClearBefore.setUp = function(self)
    self.p = piecewise.Polynomial()
    self.p:insert(0,          1,-2) -- for t>=0 return (1*t - 2)
    self.p:insert(2,             8)
    self.p:insert(3, -0.5, 3, 0, 2) -- -1/2*t^3 + 3*t^2 + 0*t + 2 
end
TestClearBefore.test_clearBefore = function(self)
    self.p:clearBefore(2.2)
    assertEquals(self.p:getStarts(), {2.2, 3}, 'clearBefore should trim')
    assertEquals(self.p(2.99), 8)
    assertEquals(self.p(3), -0.5*3^3 + 3*3^2 + 2)
    assertNil(self.p(2.1999), 'undefined region before clear time')
end
TestClearBefore.test_module_call = function(self)
    piecewise.clearBefore(self.p, 2.2)
    assertEquals(self.p:getStarts(), {2.2, 3}, 'clearBefore should trim')
end



TestAreEquals = {}
TestAreEquals.test_equality = function(self)
    local p1, p2 = piecewise.Polynomial(), piecewise.Polynomial()
    assertError(piecewise.areEqual, p1, nil)
    assert(p1 ~= nil)
    
    assert(not piecewise.areEqual(p1,  {}))
    assert(p1 ~= {})
    
    assert(piecewise.areEqual(p1, p2), 'unique instances')
    assert(p1 == p2, 'metatable allows ==')
    
    p1:insert(3, 4, 0, -0.32, 0)
    assert(not piecewise.areEqual(p1, p2))
    assert(p1 ~= p2)
    
    p2:insert(3, 4, 0, -0.32, 0)
    assert(piecewise.areEqual(p1, p2))
    assert(p1 == p2)
    
    p1:insert(4, 3, 2)
    p2:insert(4, 2, 3)
    assert(not piecewise.areEqual(p1, p2))
    assert(p1 ~= p2)
end



TestInterlace = {}
TestInterlace.setUp = function(self)
    self.p1= piecewise.Polynomial()
    self.p1:insert(-1,        1,   9)
    self.p1:insert( 0,     2, 0.5, 0)
    self.p1:insert( 4, -3, 0, 3,   2)
    self.p1:insert( 9,  1, 1, 1,   1)
    
    self.p2 = piecewise.Polynomial()
    self.p2:insert( 1,     1, 0,  -4.2)
    self.p2:insert( 3, -2,-1, 0,   0.5)
    self.p2:insert( 4,             6)
end
TestInterlace.test_interlace = function(self)
    local e12 = {{-1, 1, nil}, 
                 { 0, 2, nil}, 
                 { 1, 2, 1}, 
                 { 3, 2, 2}, 
                 { 4, 3, 3}, 
                 { 9, 4, 3}}
    local e21 = {{-1, nil, 1}, 
                 { 0, nil, 2}, 
                 { 1,   1, 2}, 
                 { 3,   2, 2}, 
                 { 4,   3, 3}, 
                 { 9,   3, 4}}
    assertEquals(piecewise.interlace(self.p1, self.p2), e12)
    assertEquals(piecewise.interlace(self.p2, self.p1), e21,
                 'order of arguments is important')
    assertEquals(self.p1:interlace(self.p2), e12)
    assertEquals(self.p2:interlace(self.p1), e21)
end
TestInterlace.test_empty = function(self)
    local p_empty = piecewise.Polynomial()
    local e1 = {{1, 1, nil}, {3, 2, nil}, {4, 3, nil}}
    local e2 = {{-1, nil, 1}, {0, nil, 2}, {4, nil, 3}, {9, nil, 4}}
    assertEquals(self.p2:interlace(p_empty), e1)
    assertEquals(p_empty:interlace(self.p1), e2)
    assertEquals(p_empty:interlace(piecewise.Polynomial()), {},
                 'interlacing two empty polynomials gives an empty table')
end
TestInterlace.test_odd_pieces = function(self)
    local pa = piecewise.Polynomial({3, 4,  130})
    local pb = piecewise.Polynomial({9,-1.5, 80})
    local expected = {{3, 1, nil}, {9, 1, 1}}
    assertEquals(pa:interlace(pb), expected)
end



TestClone = {}
TestClone.test_empty = function(self)
    local p = piecewise.Polynomial()
    assertEquals(p:clone(), p)
    assertEquals(piecewise.clone(p), p)
end
TestClone.test_nominal = function(self)
    local p = piecewise.Polynomial()
    p:insert(5, -3, 0, 0, 2)
    p:insert(143, 1, 1, -5, 3)
    p:insert(-3, 4)
    local expect = piecewise.Polynomial()
    expect:insert( -3,          4)
    expect:insert(  5,-3, 0, 0, 2)
    expect:insert(143, 1, 1,-5, 3)
    assertEquals(p:clone(), expect)
    assertEquals(piecewise.clone(p), expect)
end
TestClone.test_change = function(self)
    local p = piecewise.Polynomial({4, 5, 2, 3, 1})
    local clone = p:clone()
    assertEquals(clone, p)
    p:insert(4, 2, 7)
    assertNotEquals(clone, p, 'p has changed; clone has not')
end



TestOperations = {}
TestOperations.setUp = function(self)
    self.p1 = piecewise.Polynomial()
    self.p1:insert(0,     2, 0.5, 0)
    self.p1:insert(4, -3, 0, 3,   2)
    
    self.p2 = piecewise.Polynomial()
    self.p2:insert(1,     1, 0,  -4.2)
    self.p2:insert(3, -2,-1, 0,   0.5)
    self.p2:insert(4,             6)
end
TestOperations.test_subtract = function(self)
    local ident = self.p1:clone()
    local expected = piecewise.Polynomial()
    expected:insert(0, {    2, 0.5, 0})
    expected:insert(1, {    1, 0.5, 4.2})
    expected:insert(3, { 2, 3, 0.5,-0.5})
    expected:insert(4, {-3, 0, 3,  -4})
    assertEquals(piecewise.subtract(self.p1, self.p2), expected)
    assertEquals(self.p1:subtract(self.p2), expected)
    
    assertEquals(self.p1, ident, 'original is unmodified')
end
--TODO: TestOperations.test_subtract_errors = function(self) end
TestOperations.test_add = function(self)
    local ident = self.p2:clone()
    local expected = piecewise.Polynomial()
    expected:insert(0,     2, 0.5, 0)
    expected:insert(1,     3, 0.5,-4.2)
    expected:insert(3, -2, 1, 0.5, 0.5)
    expected:insert(4, -3, 0, 3,  8)
    assertEquals(piecewise.add(self.p1, self.p2), expected)
    assertEquals(piecewise.add(self.p2, self.p1), expected, 'commutative')
    assertEquals(self.p1:add(self.p2), expected)
    assertEquals(self.p2:add(self.p1), expected, 'commutative non-module')
    
    assertEquals(self.p2, ident, 'original is unmodified')
end
TestOperations.test_multiply = function(self)
    local ident = self.p1:clone()
    local expected = piecewise.Polynomial()
    expected:insert(0, 2, 0.5, 0)--(2x^2+0.5x+0)(nil)
    expected:insert(1, 2, 0.5, -4.2*2, -4.2*0.5, -4.2*0)--(2x^2+0.5x+0)(x^2+0x-4.2)
    expected:insert(3, 2*-2, -1*2+-2*0.5, -1*0.5, 0.5*2, 0.5*0.5, 0.5*0)
                    --(2x^2+0.5x+0)(-2x^3-1x^2+0x+0.5)
    expected:insert(4, -3*6, 0*6, 3*6, 2*6)--(-3x^3+0x^2+3x+2)(6)
    assertEquals(piecewise.multiply(self.p1, self.p2), expected)
    assertEquals(piecewise.multiply(self.p2, self.p1), expected, 'commutative')
    assertEquals(self.p1:multiply(self.p2), expected)
    assertEquals(self.p2:multiply(self.p1), expected, 'commutative non-module')
    
    assertEquals(self.p1, ident)
end
TestOperations.test_square = function(self)
    local ident = self.p1:clone()
    local expected = piecewise.Polynomial()
    expected:insert(0, 4, 2, 0.25, 0, 0)
    -- 4x^2 + 1x^3 + 1x^3 + 0.25x^2
    expected:insert(4, 9, 0, -18, -12, 9, 12, 4)
    --9x^6 + -9x^4 + -6x^3 + -9x^4 + 9x^2 + 6x + -6x^3 + 6x + 4
    assertEquals(piecewise.square(self.p1), expected)
    assertEquals(self.p1:square(), expected, 'module call')
    
    assertEquals(self.p1, ident)
end
TestOperations.test_divide = function(self)
    assertError('division is not (yet) supported', nil, 
                piecewise.divide, self.p1, self.p2)
    assertError('division is not (yet) supported', nil, 
                self.p1.divide, self.p1, self.p2)
end



TestRoot = {}
TestRoot.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestRoot.test_empty = function(self)
    assertEquals(self.p:getRoots(7), {}, 'empty polynomial has no root')
    assertEquals(piecewise.getRoots(self.p, 7), {}, 'module call')
end
TestRoot.test_constant = function(self)
    self.p:insert(-1, 4)
    assertEquals(self.p:getRoots(0), {}, 'no root at 0')
    assertEquals(self.p:getRoots(4), {{-1, math.huge}},
                 'constant match has range of roots')
end
TestRoot.test_constant_zero = function(self)
    self.p:insert(5, 0)
    assertEquals(self.p:getRoots(0), {{5, math.huge}})
    assertEquals(self.p:getRoots(1), {}, 'constant zero ~= 1')
end
TestRoot.test_constant_piece = function(self)
   self.p:insert(0,  4)
   self.p:insert(5, -3)
   assertEquals(self.p:getRoots( 4), {{0, 5}})
   assertEquals(self.p:getRoots(-3), {{5, math.huge}})
   assertEquals(self.p:getRoots( 0), {})
end
TestRoot.test_linear = function(self)
    self.p:insert(0, -0.5, 4)
    assertEquals(self.p:getRoots(), {8})
end
TestRoot.test_linear_under_domain = function(self)
    self.p:insert(10, -0.5, 4)
    assertEquals(self.p:getRoots(), {})
end
TestRoot.test_linear_over_domain = function(self)
    self.p:insert(0, -0.5, 4)
    self.p:insert(5,  3)
    assertEquals(self.p:getRoots(), {})
end
TestRoot.test_linear_pieces = function(self)
    self.p:insert(-5, 1,   3) -- root at -3
    self.p:insert( 2, 2, -22) -- root at 11
    self.p:insert(13, 0.5,-5) -- root at 10, below piece's domain
    assertEquals(self.p:getRoots(0), {-3, 11})
end
TestRoot.test_quadratic_noroot = function(self)
    self.p:insert(-3, 1, 0, 1) -- x^2 + 1
    assertEquals(self.p:getRoots(), {})
end
TestRoot.test_quadratic_oneroot = function(self)
    self.p:insert(-3, {1, 0, 0}) -- x^2
    assertEquals(self.p:getRoots(), {0})
end
TestRoot.test_quadratic_tworoots = function(self)
    self.p:insert(-3, 1, -3, 2)
    assertEquals(self.p:getRoots(0), {1, 2})
    assertEquals(self.p:getRoots(), self.p:getRoots(0),
                 'default root of zero')
    assertEquals(piecewise.getRoots(self.p, 0), self.p:getRoots(0))
    assertEquals(piecewise.getRoots(self.p), self.p:getRoots(0),
                 'module call defaults root to zero')
end
TestRoot.test_quadratic_tworoots_valueshift = function(self)
    self.p:insert(-2, -1, 0, 0)
    assertEquals(self.p:getRoots(-2), {-2^0.5, 2^0.5})
end
TestRoot.test_quadratic_zero_x_squared = function(self)
    self.p:insert(2, 0, 0.3, -3)
    assertEquals(self.p:getRoots(), {10})
end
TestRoot.test_multiple_pieces = function(self)
    self.p:insert( 3,       2,-10)
    self.p:insert(10,           3)
    self.p:insert(12,  0,   0,  5)
    self.p:insert(20, -0.2, 0, 99)
    assertEquals(self.p:getRoots(3),
                 {6.5, 
                  {10,12},
                  480^0.5, -- ~21.9
                 })
end
TestRoot.test_cubic = function(self)
    self.p:insert(2, 3, -3, 0.667, -7.5)
    assertError('cubic is not supported', nil,
                self.p.getRoots, self.p, 0)
    assertError('cubic is not supported', nil,
                piecewise.getRoots, self.p, 0)
end
TestRoot.test_value_typecheck = function(self)
    self.p:insert(math.random(10), 1,1,1)
    for _,v in ipairs({true, {}, function() return 3 end, 'string'}) do
        assertError('value must be number, was: '..type(v),
                    piecewise.getRoots, self.p, v)
    end
end



TestDerive = {}
TestDerive.setUp = function(self)
    self.p = piecewise.Polynomial()
end
TestDerive.test_getDerivative_empty = function(self)
    assertEquals(self.p:getDerivative(), piecewise.Polynomial())
    assertEquals(piecewise.getDerivative(self.p), piecewise.Polynomial())
end
TestDerive.test_getDerivative = function(self)
    self.p:insert( 3, 5,  0, 0, 0.5, 2)
    self.p:insert(20,           3, -12)
    self.p:insert(22,              120)
    self.p:insert(30,       -4, 1,   1)
    local e = piecewise.Polynomial()
    e:insert( 3, 20, 0, 0, 0.5)
    e:insert(20,           3)
    e:insert(22,           0)
    e:insert(30,       -8, 1)
    assertEquals(self.p:getDerivative(), e)
    assertEquals(piecewise.getDerivative(self.p), e, 'module call')
    
    local ident = piecewise.Polynomial()
    ident:insert( 3, 5, 0, 0, 0.5, 2)
    ident:insert(20,          3, -12)
    ident:insert(22,             120)
    ident:insert(30,      -4, 1,   1)
    assertEquals(self.p, ident)
end
TestDerive.test_getDerivative_zero = function(self)
    self.p:insert(5, 0)
    local expected = piecewise.Polynomial({5, 0})
    assertEquals(self.p:getDerivative(), expected)
end
TestDerive.test_getGrowth_empty = function(self)
    assertNil(self.p:getGrowth(2.2))
    assertNil(piecewise.getGrowth(self.p), 'module call')
end
TestDerive.test_getGrowth = function(self)
    self.p:insert(2.5, -1.2, 8, 3)
    assertNil(self.p:getGrowth(2.2))
    assertAlmostEquals(self.p:getGrowth(6), -2.4*6 + 8, 1e-12)
    assertAlmostEquals(piecewise.getGrowth(self.p, 6), -2.4*6 + 8, 1e-12)
end
TestDerive.test_getGrowth_several = function(self)
    self.p:insert(0, 4, 2, 5)
    self.p:insert(4,    1, 1)
    self.p:insert(9,      20)
    assertNil(self.p:getGrowth(-1.5))
    assertAlmostEquals(self.p:getGrowth(3),  26, 1e-12)
    assertAlmostEquals(self.p:getGrowth(5),   1, 1e-12)
    assertAlmostEquals(self.p:getGrowth(100), 0, 1e-12)
end



luaunit:run()

