---Module for piecewise polynomial functions.

local moretables = require 'lib.moretables.init'

local piecewise = {}

---Add a new piece to the polynomial.
piecewise.insert = function(P, t1, ...)
    local coeffs = {...}
    if type(coeffs[1]) == 'table' then coeffs = coeffs[1] end
    assert(type(t1) == 'number')
    assert(type(coeffs) == 'table')
    assert(#coeffs > 0)
    
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
        t_start, coeffs = P[i][1], P[i][2]
        if P[i+1] then t_stop = P[i+1][1]
        else t_stop = math.huge
        end
        --assert(type(t_start) == 'number')
        --assert(type(t_stop)  == 'number')
        --assert(type(coeffs)  == 'table')
        if #coeffs == 1 then
            if coeffs[1] == v then
                roots[#roots+1] = {t_start, t_stop}
            end
        elseif #coeffs == 2 then
            t = (v - coeffs[2]) / coeffs[1]
            if t >= t_start and t < t_stop then
                roots[#roots+1] = t
            end
        elseif #coeffs == 3 then
            -- x = (-b +/- (b^2 + 4ac)^0.5) / (2a)
            local a, b, c = coeffs[1], coeffs[2], coeffs[3]
            c = c - v
            t = (b^2 - 4*a*c)
            if t >= 0 then
                t = t^0.5
                local t1, t2 = (-(b+t))/(2*a), (t-b)/(2*a)
                if t1 == t2 then 
                    t2 = nil
                elseif t2 < t1 then 
                    t1, t2 = t2, t1 
                end
                --t1, t2 = math.min(t1, t2), math.max(t1, t2)
                if t1 >= t_start and t1 < t_stop then
                    roots[#roots+1] = t1
                end
                if  t2
                and t2 >= t_start 
                and t2 < t_stop 
                then roots[#roots+1] = t2
                end
            end
        else 
            error('degree is higher than maximum supported')
        end
    end
    return roots
end

---Get the derivative of a piece by its coefficients
-- if no time t is provided, returns a table of new coefficients;
-- else solves resulting polynomial at time t and returns number
local function derivePiece(coeffs, t)
    local degree, dc, newc = #coeffs, {}
    if t then dc = 0 end
    if degree == 1 then 
        if not t then dc = {0} end
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
    for _,piece in ipairs(P) do
        if piece[1] < t then 
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
    if not p1.getStarts
    or not p2.getStarts
    or not moretables.alike(p1, p2)
    then 
        return false
    end
    return true
end

---return a table interlacing the start times of the two pieces
piecewise.interlace = function(p1, p2)
    local t = {}
    local i1, i2, end1, end2 = 1, 1, false, false
    while true do
        local piece1, piece2 = p1[i1], p2[i2]
        if end1 and end2 then break
        elseif not piece1 then 
            if not piece2 then break end
            i1, end1 = #p1, true
            t[#t+1] = piece2[1]
            i2 = i2+1
        elseif not piece2 then
            i2, end2 = #p2, true
            t[#t+1] = piece1[1]
            i1 = i1+1
        elseif piece1[1] < piece2[1] then
            t[#t+1] = piece1[1]
            i1 = i1+1
        elseif piece1[1] == piece2[1] then
            t[#t+1] = piece1[1]
            i1, i2 = i1+1, i2+1
        else -- piece1[1] > piece2[1]
            t[#t+1] = piece2[1]
            i2 = i2+1
        end
        end1 = end1 or i1 > #p1
        end2 = end2 or i2 > #p2
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
    local s = piecewise.Polynomial()
    local starts, i1, i2 = piecewise.interlace(p1, p2), 1, 1
    for i,t in ipairs(starts) do
        if p1[i1][1] > t and not p1(t) then
                local coeffs = p2[i2][2]
            if sub then
                for j=1, #coeffs do coeffs[j] = -coeffs[j] end
            end
            s:insert(t, coeffs)
        elseif p1[i1][1] >= t and not p2(t) then
            s:insert(t, p1[i1][2])
        else
            s:insert(t, addcoeffs(p1[i1][2], p2[i2][2], sub))
        end
        if not starts[i+1] then break end
        if p1[i1+1] and p1[i1+1][1] <= starts[i+1] then i1=i1+1 end
        if p2[i2+1] and p2[i2+1][1] <= starts[i+1] then i2=i2+1 end
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

---Get the function resulting from multiplying two functions together
piecewise.multiply = function(p1, p2)
    local product = piecewise.Polynomial()
    return product
end

---Alias for multipy(P, P)
piecewise.square = function(P)
    return piecewise.multiply(P, P)
end

---Create a new piecewise polynomial 'object'.
piecewise.Polynomial = function()
    local pp = {add           = piecewise.add,
                divide        = piecewise.divide,
                insert        = piecewise.insert,
                clearBefore   = piecewise.clearBefore,
                evaluate      = piecewise.evaluate,
                getDerivative = piecewise.getDerivative,
                getGrowth     = piecewise.getGrowth,
                getRoots      = piecewise.getRoots,
                getStarts     = piecewise.getStarts,
                interlace     = piecewise.interlace,
                multiply      = piecewise.multiply,
                subtract      = piecewise.subtract,
               }
    local mt = {__call = piecewise.evaluate,
                __eq   = piecewise.areEqual,
               }
    setmetatable(pp, mt)
    return pp
end

return piecewise

