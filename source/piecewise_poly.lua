---Module for piecewise polynomial functions.

local moretables   = require 'lib.moretables.init'
local stringbuffer = require 'lib.lua_stringbuffer.init'

local unpack = unpack or table.unpack

local piecewise = {}

---Add a new piece to the polynomial.
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
-- @return New Polynomial instance
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
piecewise.getStarts = function(P)
    local t = {}
    for i=1, #P do
        t[i] = P[i][1]
    end
    return t
end

---Find value of the polynomial at a given 'time'.
piecewise.evaluate = function(P, t)
    if not P[1] or t < P[1][1] then return nil end
    local v, coeffs = 0
    for i=#P, 1, -1 do
        if t >= P[i][1] then 
            coeffs = P[i][2]
            break
        end
    end
    for i=1, #coeffs do
        v = v * t + coeffs[i] 
    end
    return v
end

---Find the 'time(s)' at which the polynomial has the given value;
-- supports only polynomials of degree two or less.
piecewise.getRoots = function(P, v)
    v = v or 0
    assert(type(v) == 'number', 'value must be number, was: '..type(v))
    if not P[1] then return {} end
    local roots, t_start, t_stop, t, coeffs = {}
    for i=1, #P do
        t_start, coeffs, t_stop = P[i][1], P[i][2], math.huge
        if P[i+1] then t_stop = P[i+1][1] end
        --assert(type(t_start) == 'number')
        --assert(type(t_stop)  == 'number')
        --assert(type(coeffs)  == 'table')
        if #coeffs == 1 then -- constant
            if coeffs[1] == v then
                roots[#roots+1] = {t_start, t_stop}
            end
        elseif #coeffs == 2 then -- linear
            t = (v - coeffs[2]) / coeffs[1]
            if t >= t_start and t < t_stop then
                roots[#roots+1] = t
            end
        elseif #coeffs == 3 then -- quadratic
            -- x = (-b +/- (b^2 - 4ac)^0.5) / (2a)
            local a, b, c = coeffs[1], coeffs[2], coeffs[3]-v
            t = (b^2 - 4*a*c)
            if t >= 0 then
                t = t^0.5
                local t1, t2 = (-b-t)/(2*a), (t-b)/(2*a)
                if t1 == t2 then 
                    t2 = nil
                elseif t2 < t1 then 
                    t1, t2 = t2, t1 
                end
                if t_start <= t1 and t1 < t_stop then
                    roots[#roots+1] = t1
                end
                if t2 and t2 >= t_start and t2 < t_stop then
                    roots[#roots+1] = t2
                end
            end
        else 
            error('degree is higher than maximum supported')
        end
    end
    return roots
end

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
    local degree, dc, newc = #coeffs, {}
    if t then dc = 0 end
    if degree < 2 then 
        if t then dc = 0 else dc = {0} end
    else
        for i=1, degree-1 do
            newc = coeffs[i] * (degree-i)
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
piecewise.getGrowth = function(P, t)
    local t0, t1
    for i=1, #P do
        local piece = P[i]
        t0, t1 = piece[1], math.huge
        if P[i+1] then t1 = P[i+1][1] end
        if t0 <= t and t <= t1 then 
            return derivePiece(piece[2], t)
        end
    end
    return nil
end

---Get polynomial derivative of the given function (for all pieces)
-- derivative of constants is zero
piecewise.getDerivative = function(P)
    local d = piecewise.Polynomial()
    for _, piece in ipairs(P) do
        d:insert(piece[1], derivePiece(piece[2]))
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
        buffer:add('(' .. tostring(piece[1]) .. ') : ')
        for i, v in ipairs(piece[2]) do
            local sign = ' + '
            if v < 0 then sign = ' - ' end
            if empty then sign = '' end
            if empty and v < 0 then sign = '-' end
            local power = #piece[2] - i
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

---Return a table interlacing the start times of the two 'functions' 
-- with piece indices for each interval 
piecewise.interlace = function(p1, p2)
    local t = {}
    local i1, i2 = 1, 1
    local done1, done2 = i1 > #p1, i2 > #p2
    
    if done1 and not done2 then
        for i=1, #p2 do
            t[#t+1] = {p2[i][1], nil, i}
        end
        done2 = true
    elseif done2 and not done1 then
        for i=1, #p1 do
            t[#t+1] = {p1[i][1], i}
        end
        done1 = true
    end
    if done1 and done2 then return t end
    
    while not done1 or not done2 do
        local s1, s2 = p1[i1][1], p2[i2][1]
        local start = math.min(s1, s2)
        if done1 then
            start = s2
            t[#t+1] = {start, i1, i2}
        elseif done2 then
            start = s1
            t[#t+1] = {start, i1, i2}
        elseif start < p1[1][1] then -- before first piece in p1
            t[#t+1] = {p2[i2][1], nil, i2}
        elseif start < p2[1][1] then -- before first piece in p2
            t[#t+1] = {p1[i1][1], i1, nil}
        else
            if s1 > start then
                t[#t+1] = {start, i1-1, i2}
            elseif s2 > start then
                t[#t+1] = {start, i1, i2-1}
            else
                t[#t+1] = {start, i1, i2}
            end
        end
        if s1 == start then i1 = i1+1 end
        if s2 == start then i2 = i2+1 end
        
        if i1 > #p1 then done1, i1 = true, #p1 end
        if i2 > #p2 then done2, i2 = true, #p2 end
        if done1 and done2 then break end
    end
    return t
end

local function addcoeffs(c1, c2, sub)
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

local function arithmetic(p1, p2, sub)
    local s, starts = piecewise.Polynomial(), p1:interlace(p2)
    for _, batch in ipairs(starts) do
        local t, i1, i2 = batch[1], batch[2], batch[3]
        if not i1 then
-- THIS COMMENTED BLOCK RESULTED IN OVERWRITES THAT TESTS MISSED...
--TODO: determine gap that allowed for these to slip through undetected
--            local coeffs = p2[i2][2]
--            if sub then 
--                for i=1, #coeffs do coeffs[i] = -coeffs[i] end
--            end
            local coeffs = {}
            for i,v in ipairs(p2[i2][2]) do
                if sub then v = -v end
                coeffs[i] = v
            end
            s:insert(t, coeffs)
        elseif not i2 then
            s:insert(t, p1[i1][2])
        else
            s:insert(t, addcoeffs(p1[i1][2], p2[i2][2], sub))
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

---Get the function resulting from multiplying two functions together
piecewise.multiply = function(p1, p2)
    local product, starts = piecewise.Polynomial(), p1:interlace(p2)
    for i=1, #starts do
        local t, i1, i2 = starts[i][1], starts[i][2], starts[i][3]
        if not i1 then
            product:insert(t, p2[i2][2])
        elseif not i2 then
            product:insert(t, p1[i1][2])
        else
            product:insert(t, mult(p1[i1][2], p2[i2][2]))
        end
    end
    return product
end

---Alias for multipy(P, P)
piecewise.square = function(P)
    return piecewise.multiply(P, P)
end

piecewise.getDegree = function(P, t)
    if t then
        local d
        for _,piece in ipairs(P) do
            if t >= piece[1] then d = #piece[2] - 1
            else break end
        end
        return d
    else
        degrees = {}
        for i, piece in ipairs(P) do
            degrees[i] = #piece[2] - 1
        end
        return degrees
    end
end

---Create a new piecewise polynomial 'object'.
piecewise.Polynomial = function(...)
    local pp = {_isPolynomial = true,
                add           = piecewise.add,
                clearBefore   = piecewise.clearBefore,
                clone         = piecewise.clone,
                divide        = piecewise.divide,
                evaluate      = piecewise.evaluate,
                getDegree     = piecewise.getDegree,
                getDerivative = piecewise.getDerivative,
                getGrowth     = piecewise.getGrowth,
                getRoots      = piecewise.getRoots,
                getStarts     = piecewise.getStarts,
                insert        = piecewise.insert,
                insertPoly    = piecewise.insertPoly,
                interlace     = piecewise.interlace,
                multiply      = piecewise.multiply,
                subtract      = piecewise.subtract,
                square        = piecewise.square,
               }
    local mt = {__call = piecewise.evaluate,
                __eq   = piecewise.areEqual,
                __tostring = piecewise.print,
               }
    setmetatable(pp, mt)
    for i,t in ipairs({...}) do
        assert(type(t) == 'table', 'supplied arguments must be tables')
        assert(#t > 1, 'table must have at least two numbers (at '..i..')')
        local start = table.remove(t, 1)
        pp:insert(start, t)
    end
    return pp
end

return piecewise

