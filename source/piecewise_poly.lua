---Module for piecewise polynomial functions.

local moretables = require 'lib.moretables'

local piecewise = {}

---Add a new piece to the polynomial.
local function addPiece(self, t1, coeffs)
    local pieces = self[1]
    if not pieces[1] then
        pieces[1] = {t1, coeffs}
    else
        local added = false
        for i=1, #pieces do
            if t1 < pieces[i][1] then
                table.insert(pieces, i, {t1, coeffs})
                added = true
                break
            end
        end
        if not added then
            pieces[#pieces+1] = {t1, coeffs}
        end
    end
end

---Make the polynomial 'start' at the given time, clearing any earlier pieces.
local function clearBefore(self, t)
    local pieces, newpieces = self[1], {}
    for i=#pieces, 1, -1 do
        if t <= pieces[i][1] then
            table.insert(newpieces, 1, pieces[i])
        elseif t > pieces[i][1] then
            table.insert(newpieces, 1, {t, pieces[i][2]})
            break
        end
    end
    self[1] = newpieces
end

---Get table of time indices for the individual pieces.
local function getStarts(self)
    local t = {}
    for i=1, #self[1] do
        t[i] = self[1][i][1]
    end
    return t
end

---Find value of the polynomial at a given 'time'.
local function evaluate(self, t)
    local pieces = self[1]
    if not pieces[1] or t < pieces[1][1] then return nil end
    local v, coeffs = 0
    for i=#pieces, 1, -1 do
        if t >= pieces[i][1] then 
            coeffs = pieces[i][2]
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
--TODO: define how to handle constants
local function root(self, v)
    v = v or 0
    assert(type(v) == 'number', 'value must be number, was: '..type(v))
    local roots, t_start, coeffs = {}
--    for i=1, #self[1] do
--        local t_start, coeffs = self[1][i][1], self[1][i][2]
--        --assert(type(t_start) == 'number')
--        --assert(type(coeffs) == 'table')
--        --TODO
--    end
    if self[1][1] then
        local coeffs = self[1][1][2]
        if #coeffs > 0 then
            local a, b, c = coeffs[1], coeffs[2], coeffs[3]
            roots[#roots+1] = (-b - (b^2 - 4*a*c)^0.5) / 2*a
            roots[#roots+1] = (-b + (b^2 - 4*a*c)^0.5) / 2*a
        end
    end
    return roots
end

---Stand-in for '=='
piecewise.areEqual = function(p1, p2)
    if not (type(p1[1]) == 'table')
    or not (type(p2[1]) == 'table')
    or not p1.getStarts
    or not p2.getStarts
    or not moretables.alike(p1[1], p2[1])
    then 
        return false
    end
    return true
end

---Create a new piecewise polynomial 'object'.
piecewise.Polynomial = function()
    local pp = {{},
                add         = addPiece,
                clearBefore = clearBefore,
                getStarts   = getStarts,
                evaluate    = evaluate,
                root        = root,
               }
    local mt = {__call = evaluate,
                __eq   = piecewise.areEqual,
               }
    setmetatable(pp, mt)
    return pp
end

return piecewise

