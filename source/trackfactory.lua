local piecewise = require 'source.piecewise_poly'

local track = {}



---Create a new track (fx, fy) starting at the given time
-- @param t  starttime of track
-- @param px x-position of track at starttime
-- @param py y-position of track at starttime
-- @param vx x-veloctiy of track at starttime (default 0)
-- @param vy y-velocity of track at starttime (default 0)
-- @param ax x-acceleration of track (default 0)
-- @param ay y-acceleration of track (default 0)
-- @return Piecewise Polynomials: fx, fy
track.newParametric = function(t, px, py, vx, vy, ax, ay)
    return track.new(t, px, vx, ax), track.new(t, py, vy, ay)
end 


---Create a piecewise polynomial 'track' with certain starting conditions
-- @param t starttime
-- @param p initial position
-- @param v initial velocity (default 0)
-- @param a acceleration (default 0)
-- @return Piecewise-Polynomial instance
track.new = function(t, p, v, a)
    v = v or 0
    a = a or 0
    a = a/2
    return piecewise.Polynomial(t, a, v, (p - v*t - a*t^2) )
end


---Get the coefficients for a Polynomial tangential to the given
-- leading zeroes are culled
-- @param P Polynomial instance
-- @param t time to use for tangent (number)
-- @param a quadratic coefficient of tangent (default 0)
-- @error iff type(t) ~= number
-- @error iff Polynomial undefined at t
-- @error iff type(a) ~= number
-- @return three numbers: coefficients
track.tangentCoeffs = function(P, t, a)
    a = a or 0
    assert(type(t) == 'number', 't must be a number')
    assert(type(P) == 'table' and #P > 0 and P.getStarts, 
           'P must be a valid Polynomial')
    assert(type(a) == 'number', 'a must be a number (or nil)')
    
    local value, growth = P:evaluate(t), P:getGrowth(t)
    assert(value, 'Polynomial cannot be undefined at time '..t)
    growth = growth - 2*a*t
    value = value - a*t^2 - growth*t
    return a, growth, value
end



---Create a Polynomial tangential to the given at a certain time
-- @param P Polynomial instance
-- @param t time to use for tangent (number)
-- @param a quadratic coefficient of tangent (default 0)
-- @error iff type(t) ~= number
-- @error iff Polynomial undefined at t
-- @return Polynomial instance
track.tangent = function(P, t, a)
---[[
    assert(type(t) == 'number', 't must be a number')
    assert(type(P) == 'table' and #P > 0 and P.getStarts, 
           'P must be a valid Polynomial')
    a = a or 0
    assert(type(a) == 'number')
    local value, growth = P:evaluate(t), P:getGrowth(t)
    assert(value, 'P(t) cannot be nil')
    if a then
        local b = growth - 2*a*t
        local c = value - a*t^2 - b*t
        return piecewise.Polynomial(t, a, b, c)
    else
        return track.new(t, value, growth)
    end
--]]
--    return piecewise.Polynomial(t, track.tangentCoeffs(P, t, a))
end



return track

