---Module representing a 'Polynomial' object



local Polynomial = {}



local function getMaxNumIndex(t)
    local max
    for k in pairs(t) do

    end
    return max
end

---Create a new Polynomial 'object'
---@param var TODO
---@return Table representing a Polynomial
Polynomial.new = function(...)
    local t, P, i_max
    t = {...}
--    assert(#t > 0, 'constructor parameter list cannot be empty')
    i_max = -math.huge
    if type(t[1]) == 'table' then 
        t = t[1] 
        for k,_ in pairs(t) do
            if k > i_max then i_max = k end
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
        i_max = #t
    end
    
    P = {i_max = i_max,
         _is_polynomial = true}
    for i=0, i_max do
        P[i] = t[i] or 0
        assert(type(P[i]) == 'number', 'non-numeric value! '.. tostring(P[i]))
    end
    local mt = {__call = Polynomial.evaluate,
                __eq   = Polynomial.are_equivalent,
--                __add  = nil,
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
    for i = P.i_max, 0, -1 do
        v = v*t + P[i]
    end
    return v
end

---Represent as a string
---@param P Polynomial instance (table)
---@return String, e.g., "t^4 - 2.718t^2 + 1"
Polynomial.tostring = function(P)
    local t = {"Polynomial:"}
    for i = P.i_max, 0, -1 do
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
    return table.concat(t)
end

---Compare two Polynomials with an optional acceptable variance
---@param a     Polynomial instance (table)
---@param b     Polynomial instance (table)
---@param delta Maximum acceptable variance in coefficients (optional) (number)
---Return True iff coefficients of a and b are equal (or within delta); 
---            else false
Polynomial.are_equivalent = function(a, b, delta)
    return false
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
---@param P      Polynomial instance (table)
---@param factor Polynomial instance (table) OR numer
---@return New Polynomial instance of a*b
Polynomial.multiply = function(P, factor)
end

return Polynomial

