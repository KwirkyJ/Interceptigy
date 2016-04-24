local Piecewise = {}

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
    return
end

---Create a new piecewise polynomial 'object'.
Piecewise.Polynomial = function()
    local pp = {{},
                add         = addPiece,
                clearBefore = clearBefore,
                getStarts   = getStarts,
                evaluate    = evaluate,
               }
    local mt = {__call = evaluate,
                -- __eq = nil,
               }
    setmetatable(pp, mt)
    return pp
end

return Piecewise

