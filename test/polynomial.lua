---Test suite for the Polynomial 'module'
---Requires LuaUnit

local luaunit    = require 'luaunit.luaunit'
local Polynomial = require 'source.polynomial'



TestInstantiation = {}
TestInstantiation.test_proper_table = function(self)
    local t = {[3] = -2.4, 
               [1] =  2, 
               [0] = -1.5}
    local p = Polynomial.new(t)
    assertAlmostEquals(-2.4*5^3 + 2*5 - 1.5, 
                       Polynomial.evaluate(p, 5), 
                       1e-14)
end
TestInstantiation.test_proper_list = function(self)
    local p = Polynomial.new(-2.4, 0, 2, -1.5)
    assertAlmostEquals(-2.4*5^3 + 2*5 - 1.5, 
                       Polynomial.evaluate(p, 5), 
                       1e-14)
end
TestInstantiation.test_error_type = function(self)
    assert(false, 'TODO')
end
TestInstantiation.test_empty_zeroes = function(self)
    local p = Polynomial.new ()
    assertEquals (0, Polynomial.evaluate (p, 0))
    assertEquals (0, Polynomial.evaluate (p, -10))
    assertEquals (0, Polynomial.evaluate (p, 100))
end



TestArithmetic = {}
--evaluate
--add
--subtract
--multiply



TestToString = {}
TestToString.test_table_call = function(self)
    local p = Polynomial.new(-2.4, 0, 2, -1.5)
    assertEquals(Polynomial.tostring(p),
                 "Polynomial: -2.4t^3 + 2t - 1.5")
end
TestToString.test_metatable = function(self)
    local p = Polynomial.new({[2]=1.414, [1]=-9})
    assertEquals(tostring(p),
                 "Polynomial: 1.414t^2 - 9t")
end
TestToString.test_metatable_const = function(self)
    local p = Polynomial.new(8)
    assertEquals(tostring(p), 
                 "Polynomial: 8")
end
TestToString.test_zero = function(self)
    local p = Polynomial.new(0)
    assertEquals(tostring(p),
                 "Polynomial: 0")
end
--TODO: specify printing precision?

--TODO: deserialize ==> create Polynomial from a tostring(Poly) string



TestEquivalence = {}
TestEquivalence.setUp = function(self)
    self.default_delta = Polynomial:get_eq_delta()
end
TestEquivalence.tearDown = function(self)
    Polynomial:set_eq_delta(self.default_delta)
end
TestEquivalence.test_same = function(self)
    local p1 = Polynomial.new(-4, 0.25, 0, -1.11)
    local p2 = Polynomial.new{[0] = -1.11, [3] = 4*-1, [2] = 1/4}
    assert(Polynomial.are_equivalent(p1, p2), 'should be equivalent')
    assert(Polynomial.are_equivalent(p2, p1), 'equivalence is commutative')
    assert(p1 == p2, 'metatable == should be equivalent')
    assert(p2 == p1, 'metatable == should be commutative')
end
TestEquivalence.test_different_slightly = function(self)
    local p1 = Polynomial.new(-4, 0.25, 0, -1.0)
    local p2 = Polynomial.new{[0] = -1.11, [3] = 4*-1, [2] = 1/4}
    assert(not Polynomial.are_equivalent(p1, p2))
    assert(not Polynomial.are_equivalent(p2, p1))
    assert(p1 ~= p2)
    assert(p2 ~= p1)
end
TestEquivalence.test_different_very = function(self)
    local p1 = Polynomial.new(-4, 0.25, 0, -1.0)
    local p2 = Polynomial.new{[1] = 7.2, [0] = math.pi}
    assert(not Polynomial.are_equivalent(p1, p2))
    assert(not Polynomial.are_equivalent(p2, p1))
    assert(p1 ~= p2)
    assert(p2 ~= p1)
end
TestEquivalence.test_same_barely = function(self)
    local p1 = Polynomial.new(-4, 0.25, 0, -1.00001)
    local p2 = Polynomial.new{[0] = -1.0, [3] = 4*-1, [2] = 1/4}
    assert(Polynomial.are_equivalent(p1, p2, 0.0001), 'should be equivalent')
    assert(p1 ~= p2, 'metatable == uses default delta')
end
TestEquivalence.test_default_delta = function(self)
    local p1 = Polynomial.new(-4, 0.25, 0, -1.0)
    local p2 = Polynomial.new(-4, 0.25, 0, -1.000000101)
    local p3 = Polynomial.new(-4, 0.25, 0, -1.000000099)
    assert(not Polynomial.are_equivalent(p1, p2), '1e-6 > 1e-7')
    assert(Polynomial.are_equivalent(p1, p3), '99e-9 < 1e-7')
    assert(p1 ~= p2)
    assert(p1 == p3, 'default delta used by ==')
end
TestEquivalence.test_default_delta_set = function(self)
    Polynomial:set_eq_delta(0.1)
    local p1 = Polynomial.new(-4, 0.25, 0, -1.0)
    local p2 = Polynomial.new(-4, 0.25, 0, -1.095)
    assert(Polynomial.are_equivalent(p1, p2), 'default delta works')
    assert(not Polynomial.are_equivalent(p1, p2, 1e-3), 'overridden reset default delta')
    assert(p1 == p2, 'default delta used by ==')
end



luaunit:run(arg)

