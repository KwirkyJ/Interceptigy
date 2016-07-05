---Module for piecewise polynomial functions.

local moretables   = require 'lib.moretables.init'
local stringbuffer = require 'lib.lua_stringbuffer.init'

local unpack = unpack or table.unpack



local function startOf(piece)  return piece[1] end
local function coeffsOf(piece) return piece[2] end

local piecewise = {}

---add a new piece to the polynomial (in-place modification)
-- places piece such that piece starttimes are in order
-- @param t1 starttime of a piece (number)
-- @param p1 coefficient of highest degree (number)
--           OR table of numbers representing coefficients 
--           higher-to-lower degree
-- @param p2 coefficient of second-highest degree (number or nil)
-- @param ... further coefficients of decreasing degree
-- @error t1 is not a number
-- @error no coefficients provided
-- @error coefficients are of inappropriate type
piecewise.insert = function(P, t1, ...)
    local coeffs = {...}
    if type(coeffs[1]) == 'table' then coeffs = coeffs[1] end
    assert(type(t1) == 'number', 'piece start time must be number')
    assert(type(coeffs) == 'table', 'coefficients must be table')
    assert(#coeffs > 0, 'coefficients cannot be empty')
    
    local n = 1
    while n <= #coeffs do
        -- verify that coefficients are numbers and trim leading zeroes (if any)
        if type(coeffs[n]) ~= 'number' then 
            error('coefficients must be numbers')
        elseif n == 1 and coeffs[n] == 0 then 
            table.remove(coeffs, 1)
        else
            n = n+1
        end
    end
    if #coeffs == 0 then coeffs = {0} end
    
    if not P[1] then
        P[1] = {t1, coeffs}
    else
        local added = false
        for i=1, #P do
            if t1 < P[i][1] then
                table.insert(P, i, {t1, coeffs})
                added = true
                break
            end
        end
        if not added then
            P[#P+1] = {t1, coeffs}
        end
    end
end

---Insert a polynomial within the given polynomial (if possible)
-- starttime clashes are not allowed, and the inserted polynomial must
-- have only one piece.
-- @param p1 Polynomial instance to be inserted into
-- @param p2 Inserted Polynomial instance
-- @error either argument is not a Polynomial instance
-- @error p2 (inserted Polynomial) is empty
-- @return Polynomial instance
piecewise.insertPoly = function(p1, p2)
    assert(type(p1) == 'table' and p1._isPolynomial)
    assert(type(p2) == 'table' and p2._isPolynomial and #p2 == 1)
    local p_out = piecewise.Polynomial()
    for _, piece1 in ipairs(p1) do
        for _, piece2 in ipairs(p2) do
            assert(piece1[1] ~= piece2[1])
        end
        p_out:insert(piece1[1], piece1[2])
    end
    p_out:insert(p2[1][1], p2[1][2])
    return p_out
end

---Make the polynomial 'start' at the given time, clearing any earlier pieces.
-- @param P Polynomial instance
-- @param t time (number)
piecewise.clearBefore = function(P, t)
    for _=1, #P do
        if not P[2] or P[2][1] > t then
            P[1][1] = t
            break
        else
            table.remove(P, 1)
        end
    end
end

---Get table of time indices for the individual pieces
-- ordered by starting time (least to greatest).
-- @param P Polynomial instance
-- @return {number, ...}
piecewise.getStarts = function(P)
    local t = {}
    for i, piece in ipairs(P) do
        t[i] = startOf(piece)
    end
    return t
end

---Find value of the polynomial at a given 'time'
-- @param P Polynomial instance
-- @param t time (number)
-- @param unbounded allow values from before given starttime (boolean)
-- @return number or nil
piecewise.evaluate = function(P, t, unbounded)
    local v, coeffs
    if not P[1] then return nil end
    if t < startOf(P[1]) then 
        if unbounded then
            v, coeffs = 0, P[1][2]
        else return nil 
        end
    else
        v, _, coeffs = 0, piecewise.getPiece(P, t)
    end
    if coeffs then
        for i=1, #coeffs do
            v = v * t + coeffs[i] 
        end
    end
    return v
end

---get the time t at which a*t + b == 0
-- @param a linear coefficient (number)
-- @param b constant (number)
-- @return number
local function getRoots1(a, b)
    return -b/a
end

---get time(s) t at which a*t^2 + b*t + c == 0
-- can be two, one, or no value(s)
-- x = (-b [+-] (b^2 - 4*a*c)^0.5) / (2*a)
-- @param a quadratic coefficient (number)
-- @param b linear coefficient (number)
-- @param c constant (number)
-- @return nil OR number OR number, number (ordered least to most)
local function getRoots2(a, b, c)
    local descriminant = b^2 - 4*a*c
    if math.abs(descriminant) < 1e-16 then -- == 0
        return -b/(2*a)
    elseif descriminant > 0 then
        descriminant, a, b = descriminant^0.5, 2*a, -b
        local t1, t2 = (b + descriminant)/a, (b - descriminant)/a
        if t1 > t2 then return t2, t1 end
        return t1, t2
    end 
end

local moretables = require 'lib.moretables.init'

---find the approximate root of a polynomial using Newton's method
-- @param P Polynomial instance
-- @param guess start search value (default 0)
-- @param iters number of iterations (default 50)
local function Newton(P, guess, iters)
    guess, iters = guess or 0, iters or 50
--    local guesses = {}
    for _=1, iters do
        local v, d = P:evaluate(guess, true), P:getGrowth(guess, true)
        if not v then error("value of P is nil!\n@ "..guess..'\t'..tostring(P)) end
        if not d then error("derivative of P is nil!\n@ "..guess..'\t'..tostring(P)..'\n'..moretables.tostring(guesses)) end
        if d == 0 then break end -- no further improvement can be made?
--        guesses[#guesses+1] = {guess, v, d}
        guess = guess - P:evaluate(guess, true) / P:getGrowth(guess, true)
        if guess == math.huge or guess == -math.huge then break end
    end
    return guess
end

---get time(s) t at which a*t^3 + b*t^2 + c*t +d == 0
-- can be three, two, or one value(s)
-- uses Newton approximation to find roots
-- @param a cubic coefficient (number)
-- @param b square coefficient (number)
-- @param c linear coefficient (number)
-- @param d constant (number)
-- @return number OR number, number, 
--         OR number, number, number (ordered least to most)
local function getRoots3(a,b,c,d)
    local t1, t2 = getRoots2(3*a, 2*b, c)
    local t_inf = getRoots1(3*a, b) -- 6*a, 2*b
    local P = piecewise.Polynomial(-math.huge, a,b,c,d)
    if not t1 then -- no direction shifts
        return Newton(P, t_inf)
    elseif not t2 then -- 'flat' at inflection point
        local guess = 10 -- offset
        if P:getGrowth(t_inf) < 0 then guess = -guess end
        return Newton(P, guess)
    else -- critical points both exist
        local ta, tb, tc = Newton(P, 2*t1 - t_inf),
                           Newton(P, t_inf),
                           Newton(P, 2*t2 - t_inf)
        if math.abs(ta-tb) < 1e-7 
        or math.abs(tb-tc) < 1e-7
        then 
            if math.abs(ta - tc) < 1e-7 then return ta 
            else return ta, tc
            end
        end
        return ta, tb, tc
    end
end

---Find the 'time(s)' at which the polynomial has the given value;
-- supports only polynomials of degree two or less.
-- @param P Polynomial instance
-- @param v value (default 0)
-- @return (table)
piecewise.getRoots = function(P, v)
    v = v or 0
    assert(type(v) == 'number', 'value must be number, was: '..type(v))
    if not P[1] then return {} end
    local roots, t, t_start, t_stop, coeffs = {}
    for i, piece in ipairs(P) do 
    --i=1, #P do local piece = P[i]
        t_start, coeffs, t_stop = startOf(piece), coeffsOf(piece), math.huge
        if P[i+1] then t_stop = startOf(P[i+1]) end
        if #coeffs == 1 then -- constant
            if coeffs[1] == v then
                roots[#roots+1] = {t_start, t_stop}
            end
        elseif #coeffs == 2 then -- linear
            t = getRoots1(coeffs[1], coeffs[2]-v)
            if t >= t_start and t < t_stop then
                roots[#roots+1] = t
            end
        elseif #coeffs == 3 then -- quadratic
            for _, t in ipairs({getRoots2(coeffs[1], coeffs[2], coeffs[3]-v)}) do
                if t_start <= t and t < t_stop then
                    roots[#roots+1] = t
                end
            end
        elseif #coeffs == 4 then --cubic
            local a, b, c, d = unpack(coeffs)
            for _,t in ipairs({getRoots3(a, b, c, d-v)}) do
                if t_start <= t and t < t_stop then
                    roots[#roots+1] = t
                end
            end
            --error('degree is higher than maximum supported')
        else 
            error('degree is higher than maximum supported')
        end
    end
    return roots
end

---Duplicate a Polynomial
-- @param P Polynomial instance
-- @return Polynomial instance
piecewise.clone = function(P)
    local c = piecewise.Polynomial()
    for i=1, #P do
        c:insert(unpack(P[i]))
    end
    return c
end

---Get the derivative of a piece by its coefficients
-- if no time t is provided, returns a table of new coefficients;
-- else solves resulting polynomial at time t and returns number
local function derivePiece(coeffs, t)
    local dc = 0
    if not t then dc = {} end
    if #coeffs < 2 then -- one or none -> constant or err
        if t then dc = 0 else dc = {0} end
    else
        local newc
        for i=1, #coeffs-1 do
            newc = coeffs[i] * (#coeffs-i)
            if t then
                dc = dc * t + newc
            else
                dc[#dc+1] = newc
            end
        end
    end
    return dc
end

---Get the instantaneous derivative at time t
piecewise.getGrowth = function(P, t, unbounded)
    local t0, t1, piece
    for i, piece in ipairs(P) do
        t0, t1 = startOf(piece), math.huge
        if P[i+1] then t1 = startOf(P[i+1]) end
        if (i==1 and t < t0 and unbounded) 
        or (t0 <= t and t <= t1) 
        then 
            return derivePiece(coeffsOf(piece), t)
        end
    end
    return nil
end

---Get polynomial derivative of the given function (for all pieces)
-- derivative of constants is zero
piecewise.getDerivative = function(P)
    local d = piecewise.Polynomial()
    for _, piece in ipairs(P) do
        d:insert(startOf(piece), derivePiece(coeffsOf(piece)))
    end
    return d
end

---Stand-in for '=='
piecewise.areEqual = function(p1, p2)
    if not p1._isPolynomial
    or not p2._isPolynomial
    or not moretables.alike(p1, p2)
    then 
        return false
    end
    return true
end

---Routine to pretty-print
piecewise.print = function(P)
    local buffer = stringbuffer.new()
    buffer:add('Polynomial:\n')
    for _, piece in ipairs(P) do
        local empty = true
        buffer:add('(' .. tostring(startOf(piece)) .. ') : ')
        for i, v in ipairs(coeffsOf(piece)) do
            local sign = ' + '
            if v < 0 then sign = ' - ' end
            if empty then sign = '' end
            if empty and v < 0 then sign = '-' end
            local power = #coeffsOf(piece) - i
            v = math.abs(v)
            buffer:add(sign .. tostring(v))
            if power > 0 then buffer:add('*t') end
            if power > 1 then buffer:add('^'..tostring(power)) end
            empty = false
        end
        buffer:add('\n')
    end
    return buffer:getString()
end



---variables for the interlace iterator closure
local _a, _b, _ai, _bi

---interlacing iterator closure
-- NOT THREAD-SAFE
local function _interlace_iter()
    local c_ai, c_bi = _ai+1, _bi+1 -- candidate indices
    local c_a, c_b = _a[c_ai], _b[c_bi] -- candidate pieces
    if not c_a and not c_b then return nil end
    if c_a then c_a = startOf(c_a) end -- pieces to values
    if c_b then c_b = startOf(c_b) end

    local t -- piece start time
    if c_a == c_b then
        t, _ai, _bi = c_a, c_ai, c_bi
    elseif not c_a  then
        t, _bi = c_b, c_bi
    elseif not c_b then
        t, _ai = c_a, c_ai
    elseif c_a < c_b then
        t, _ai = c_a, c_ai
    else
        t, _bi = c_b, c_bi
    end
    
    return t, _ai, _bi
end

---iterator generator to interlace two Polynomials
-- NOT THREAD-SAFE
-- @param a Polynomial instance
-- @param b Polynomial instance
-- @return iterator function (a closure)
local function _interlace(a, b)
    _a, _b, _ai, _bi = a, b, 0, 0
    return _interlace_iter
end

---Module wrapper for the interlacing closure generator
-- for use with the generic for which outputs three values:
-- starttime of the next piece,
-- index of polynomial 'a' at starttime, and
-- index of polynomial 'b' at starttime;
-- indices can be zero;
-- WARNING: due to the closure variables, this routine is NOT thread-safe
-- @param a Polynomial instance
-- @param b Polynomial instance
-- @return interlace iterator function
piecewise.interlace = _interlace


---routine to perform arithmetic (addition or subtraction) on
-- the supplied coefficient tables
-- @param c1 table of numbers (first coefficients)
-- @param c2 table of numbers (second coefficients)
-- @param sub boolean flag to subtract instead of add
local function arithCoeffs(c1, c2, sub)
    local subs, nxt, i1, i2 = {}, 1, 1, 1
    while #c1-i1 < #c2-i2 do -- unmatched higher-degree coeffs in f2
        if sub then 
             subs[nxt] =-c2[i2]
        else subs[nxt] = c2[i2]
        end
        i2, nxt = i2+1, nxt+1
    end
    while #c1-i1 > #c2-i2 do -- unmatched higher-degree coeffs in f1
        subs[nxt] = c1[i1]
        i1, nxt = i1+1, nxt+1
    end
    while c1[i1] do
        if sub then 
             subs[nxt] = c1[i1] - c2[i2]
        else subs[nxt] = c1[i1] + c2[i2]
        end
        i1, i2, nxt = i1+1, i2+1, nxt+1
    end
    return subs
end

---Perform addition or subtraction on Polynomials
-- @param p1 Polynomial instance
-- @param p2 Polynomial instance
-- @param sub flag to perform subtraction (defalt false/nil)
-- @return Polynomial instance
local function arithmetic(p1, p2, sub)
    local s = piecewise.Polynomial()
    for t, i1, i2 in _interlace(p1, p2) do
        local piece1, piece2, coeffs2 = p1[i1], p2[i2]
        if not piece1 then
            coeffs = {}
            for i,v in ipairs(coeffsOf(piece2)) do
                if sub then v = -v end
                coeffs[i] = v
            end
            s:insert(t, coeffs)
        elseif not piece2 then
            s:insert(t, coeffsOf(piece1))
        else
            s:insert(t, arithCoeffs(coeffsOf(piece1), 
                                    coeffsOf(piece2), sub))
        end
    end
    return s
end

---Get the function resulting from adding two functions together
piecewise.add = function(p1, p2)
    return arithmetic(p1, p2)
end

---Get the function resulting from subtracting two functions from one another
piecewise.subtract = function(p1, p2)
    return arithmetic(p1, p2, true)
end

---NOT YET DEFINED
piecewise.divide = function(p1, p2)
    error('polynomial division not yet supported')
end

---Multiply one set of coefficients by another
-- @param coeffs1 {[number[, ...]]}
-- @param coeffs2 {[number[, ...]]}
-- @return {[number[, ...]]}
local function mult(coeffs1, coeffs2)
    local product = {}
    local maxdegree = #coeffs1-1 + #coeffs2-1
    for i=1, #coeffs1 do
        for j=1, #coeffs2 do
            local degree = i+j - 1
            local p = coeffs1[i] * coeffs2[j]
            if product[degree] then 
                product[degree] = product[degree] + p
            else
                product[degree] = p
            end
        end
    end
    for i=1, maxdegree do
        product[i] = product[i] or 0
    end
    return product
end

---Get the Polynomial resulting from multiplying two Polynomials together
-- @param p1 Polynomial instance
-- @param p2 Polynomial instance
-- @return Polynomial instance
piecewise.multiply = function(p1, p2)
    local product = piecewise.Polynomial()
    for t, i1, i2 in _interlace(p1, p2) do
        if i1 == 0 then
            product:insert(t, coeffsOf(p2[i2]))
        elseif i2 == 0 then
            product:insert(t, coeffsOf(p1[i1]))
        else
            product:insert(t, mult(coeffsOf(p1[i1]), coeffsOf(p2[i2])))
        end
    end
    return product
end

---Alias for multipy(P, P)
-- @param P Polynomial instance
-- @return Polynomial instance
piecewise.square = function(P)
    return piecewise.multiply(P, P)
end

---Get the degree of a polynomial at the given time
-- @param P Polynomial instance
-- @param t time (number)
-- @error t is nil
-- @return nil iff P undefined at t; else number
piecewise.getDegree = function(P, t)
    assert(type(t) == 'number')
    local _, coeffs = P:getPiece(t)
    if coeffs then return #coeffs-1 end
end

---get the starttime and coefficients (in order) of a piece at time t
-- @param P Polynomial instance
-- @param t time (number)
-- @return nil iff P undefined at t; else t and coeffiecients
piecewise.getPiece = function(P, t)
    for i, piece in ipairs(P) do
        if t >= startOf(piece) and (not P[i+1] or t < startOf(P[i+1])) then
            return unpack(piece)
        end
    end
end

---get the coefficients of a piece at time t
-- @param P Polynomial
-- @param t time (number)
-- @return nil or coefficients
piecewise.getCoefficients = function(P, t)
    local _, coeffs = P:getPiece(t)
    if coeffs then return unpack(coeffs) end
end

---Create a new piecewise polynomial 'object'
-- can be called with variable count of numbers
-- (populates with a single piece, if possible must meet insert() criteria)
-- or can be called with variable count of tables 
-- (populates with as many pieces; contents must meet table-less insert() criteria)
-- @param ... numbers or tables of numbers
-- @error arguments do not satisfy insert() criteria
-- @return Polynomial instance
piecewise.Polynomial = function(...)
    local pp = {_isPolynomial = true,
                add           = piecewise.add,
                clearBefore   = piecewise.clearBefore,
                clone         = piecewise.clone,
                divide        = piecewise.divide,
                evaluate      = piecewise.evaluate,
                getDegree     = piecewise.getDegree,
                getDerivative = piecewise.getDerivative,
                getCoefficients = piecewise.getCoefficients,
                getGrowth     = piecewise.getGrowth,
                getPiece      = piecewise.getPiece,
                getRoots      = piecewise.getRoots,
                getStarts     = piecewise.getStarts,
                insert        = piecewise.insert,
                insertPoly    = piecewise.insertPoly,
                multiply      = piecewise.multiply,
                subtract      = piecewise.subtract,
                square        = piecewise.square,
               }
    local mt = {__call = piecewise.evaluate,
                __eq   = piecewise.areEqual,
                __tostring = piecewise.print,
               }
    setmetatable(pp, mt)
    local params = {...}
    if type(params[1]) == 'number' then
         pp:insert(...)
         return pp
    end
    for i,t in ipairs(params) do
        assert(#t > 1, 'table must have at least two numbers (at '..i..')')
        local start = table.remove(t, 1)
        pp:insert(start, t)
    end
    return pp
end

return piecewise

