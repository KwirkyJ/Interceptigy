---Test suite for the Polynomial 'module'
---Requires LuaUnit

local luaunit = require 'luaunit.luaunit'
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
TestInstantiation.test_error_empty = function(self)
    assert(false, 'TODO')
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



luaunit:run(arg)

