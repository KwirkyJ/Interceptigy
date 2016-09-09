---Module representing a 'Polynomial' object



local Polynomial = {}

---Create a new Polynomial 'object'
---@param var 
---@return Table representing a Polynomial
Polynomial.new = function(...)
    local p = {}
    p._is_polynomial = true
    local mt = {__call = Polynomial.evaluate,
                __eq   = Polynomial.are_equivalent,
                __add  = nil,
                __sub  = nil,
                __mult = nil}
    setmetatable(p, mt)
end

---Evaluate a Polynomial at time t
---@param poly Polynomial instance (table)
---@param t    Time at which to evaluate (number)
---@return Number value of P(t)
Polynomial.evaluate = function(poly, t)
end

---Represent as a string
---@param poly Polynomial instance (table)
---@return String, e.g., "t^4 - 2.718t^2 + 1"
Polynomial.tostring = function(poly)
end

---Compare two Polynomials with an optional acceptable variance
---@param a     Polynomial instance (table)
---@param b     Polynomial instance (table)
---@param delta Maximum acceptable variance in coefficients (optional) (number)
---Return True iff coefficients of a and b are equal (or within delta); 
---            else false
Polynomial.are_equivalent = function(a, b, delta)
end

---Sum the coefficients of two Polynomials
---@param a     Polynomial instance (table)
---@param b     Polynomial instance (table)
---@return New Polynomial instance of a+b
Polynomial.add = function(a, b)
end

---Subtract the coefficients of two Polynomials
---@param a     Polynomial instance to subtract from (table)
---@param b     Polynomial instance (table)
---@return New Polynomial instance of a-b
Polynomial.subtract = function(a, b)
end

---Multiply a Polynomial by a number or another Polynomial
---@param poly   Polynomial instance (table)
---@param factor Polynomial instance (table) OR numer
---@return New Polynomial instance of a*b
Polynomial.multiply = function(poly, factor)
end

return Polynomial

