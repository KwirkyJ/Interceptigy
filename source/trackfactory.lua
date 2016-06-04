local piecewise = require 'source.piecewise_poly'

local tf = {}



---Axis-independent helper routine for building a new polynomial
-- @param t starttime
-- @param p initial position
-- @param v initial velocity (default 0)
-- @param a acceleration (default 0)
-- @return Piecewise-Polynomial instance
local function newParamTrack(t, p, v, a)
    v = v or 0
    a = a or 0
    p = p - t*v
    return piecewise.Polynomial({t, a, v, p})
end 

---Create a new track (fx, fy) starting at the given time
-- @param t  starttime of track
-- @param px x-position of track at starttime
-- @param py y-position of track at starttime
-- @param vx x-veloctiy of track at starttime (default 0)
-- @param vy y-velocity of track at starttime (default 0)
-- @param ax x-acceleration of track (default 0)
-- @param ay y-acceleration of track (default 0)
-- @return Piecewise Polynomials: fx, fy
tf.new = function(t, px, py, vx, vy, ax, ay)
    return newParamTrack(t, px, vx, ax), newParamTrack(t, py, vy, ay)
end



--tf.append = function()
--end

--tf.tangent = function()
--end



return tf

