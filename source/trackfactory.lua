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
    p = p - v*t - a*t^2
    return piecewise.Polynomial({t, a, v, p})
end



---Create a piecewise polynomial track tangent to the given
-- @param t time to use for tangent (number)
-- @param P Polynomial instance
-- @error   iff P(t)==nil, P
-- @return Piecewise Polynomial instance
track.tangent = function(t, P)
    assert(type(t) == 'number', 't must be a number')
    assert(type(P) == 'table' and #P > 0 and P.getStarts, 'P must be a valid Polynomial')
    local p = P(t)
    assert(p, 'P(t) cannot be nil')
    return track.new(t, p, P:getGrowth(t))
end



return track

