---Module representing a 'Polynomial' object

DEFAULT_DELTA = 1e-7

local Polynomial = {default_eq_delta = DEFAULT_DELTA}



---Get the default equivalence delta (tolerance) for the module
---@return Number
Polynomial.get_eq_delta = function(self)
    return self.default_eq_delta
end

---Set the default equivalence delta for the module
---@param d Maximum allowable tolerance in difference 
---         (default DEFAULT_DELTA) (number)
Polynomial.set_eq_delta = function(self, d)
--    assert (not d or type(d) == 'number', 
--            'unallowed parameter for default delta: '..tostring(d))
    self.default_eq_delta = d or DEFULT_DELTA
end



---Create a new Polynomial 'object'
---@param var TODO new() parameter documentation
---@return Table representing a Polynomial
Polynomial.new = function(...)
    local t, P, _i_max
    t = {...}
    _i_max = 0
    if type(t[1]) == 'table' then 
        t = t[1] 
        for k,_ in pairs(t) do
            if k > _i_max then _i_max = k end
        end
    else
        -- reverse order of the vararg-generated table
        len = #t
        for i=1, len/2 do
            t[i], t[len-i+1] = t[len-i+1], t[i]
        end
        -- bump coefficients down by one index (1..n --> 0..n-1) 
        for i=0, len-1 do
            t[i] = t[i+1]
        end
        t[#t] = nil --trim repeated value at tail
        _i_max = #t
    end
    
    P = {_i_max         = _i_max,
         _is_polynomial = true,
         evaluate = Polynomial.evaluate,
         add      = Polynomial.add,
--         subtract = nil,
--         multiply = nil,
        }
    for i=0, _i_max do
        P[i] = t[i] or 0
        assert(type(P[i]) == 'number', 'non-numeric value! '.. tostring(P[i]))
    end
    local mt = {__call = Polynomial.evaluate,
                __eq   = Polynomial.are_equivalent,
                __add  = Polynomial.add,
--                __sub  = nil,
--                __mul  = nil,
                __tostring  = Polynomial.tostring,
               }
    setmetatable(P, mt)
    return P
end

---Evaluate a Polynomial at time t
---@param P Polynomial instance (table)
---@param t Time at which to evaluate (number)
---@return Number value of P(t)
Polynomial.evaluate = function(P, t)
    local v = 0
    for i = P._i_max, 0, -1 do
        v = v*t + P[i]
    end
    return v
end

---Represent as a string
---@param P Polynomial instance (table)
---@return String, e.g., "Polynomial: t^4 - 2.718t^2 + 1t +3"
Polynomial.tostring = function(P)
    local t = {"Polynomial:"}
    for i = P._i_max, 0, -1 do
        if P[i] ~= 0 then
            t[#t+1] = ' '
            if P[i] < 0 then
                t[#t+1] = '-'
            elseif #t > 3 then
                t[#t+1] = '+'
            end
            if #t > 3 then t[#t+1] = ' ' end
            t[#t+1] = math.abs(P[i])
            if i > 0 then t[#t+1] = 't' end
            if i > 1 then t[#t+1] = '^'..i end
        end
    end
    if #t == 1 then t[#t+1] = ' 0' end
    return table.concat(t)
end

---Compare two Polynomials with an optional acceptable variance
---@param a     Polynomial instance (table)
---@param b     Polynomial instance (table)
---@param delta Maximum acceptable variance in coefficients (optional) (number)
---Return True iff coefficients of a and b are equal (or within delta); 
---            else false
Polynomial.are_equivalent = function(a, b, delta)
    if not a._is_polynomial or not b._is_polynomial then return false end
    if a._i_max ~= b._i_max then return false end
    delta = delta or Polynomial.default_eq_delta
    for i=0, a._i_max do
        if math.abs(a[i] - b[i]) > delta then return false end
    end
    return true
end

---Sum the coefficients of two Polynomials; originals are not modified
---@param a Polynomial instance (table)
---@param b Polynomial instance (table)
---@return New Polynomial where coefficients of a and b have been added
Polynomial.add = function(a, b)
    local t = {}
    for i = 0, math.max(a._i_max, b._i_max) do
        t[i] = (a[i] or 0) + (b[i] or 0)
    end
    return Polynomial.new(t)
end

---Subtract the coefficients of two Polynomials
---@param a     Polynomial instance to subtract from (table)
---@param b     Polynomial instance (table)
---@return New Polynomial instance of a-b
Polynomial.subtract = function(a, b)
    return Polynomial.new()
end

---Multiply a Polynomial by a number or another Polynomial
---@param P      Polynomial instance (table)
---@param factor Polynomial instance (table) OR numer
---@return New Polynomial instance of a*b
Polynomial.multiply = function(P, factor)
    return Polynomial.new()
end

return Polynomial

