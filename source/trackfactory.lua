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
    p = p - t*v
    return piecewise.Polynomial({t, a, v, p})
end



--track.append = function()
--end

--track.tangent = function()
--end



return track

