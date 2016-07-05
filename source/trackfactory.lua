local piecewise = require 'source.piecewise_poly'
local misclib   = require 'source.misclib'

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
    assert(value, 'Polynomial must be defined at time '..t)
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
    return piecewise.Polynomial(t, track.tangentCoeffs(P, t, a))
end



---get the x and y parametric components that will adjust an entity on its
-- current track to arrive at (or as close as possible to) tx, ty at time tt
-- @param E   Entity instance
-- @param now start of adjustment (number)
-- @param tx  target x value (number)
-- @param ty  target y value (number)
-- @param tt  target time (number)
-- @return x-axis Polynomial, 
--         y-axis Polynomial, 
--         boolean error flag if E cannot accelerate to arrive at tx, ty at tt
track.adjustment = function(E, now, tx, ty, tt)
    local err, fx, fy, burn_x, burn_y, a_E, a_req, ax, ay
    fx, fy = E:getRealTrack(now)
    a_E = E:getAvailableAcceleration()
--                          findRequiredAcceleration(v0x, v0y, dx, dy, dt)
    ax, ay, a_req = misclib.findRequiredAcceleration(fx:getGrowth(now), 
                        fy:getGrowth(now), tx-fx(now), ty-fy(now), tt-now)
    ax, ay = a_E * ax/a_req, a_E * ay/a_req
    burn_x = track.tangent(fx, now, ax/2) -- ax/2 -> acceleration to coefficient
    burn_y = track.tangent(fy, now, ay/2)
    if a_req >= a_E then 
        err = true
    else
        --reuse target time for end-of-burn time
        tt = misclib.findBurnCutoff(burn_x, now, tx, tt)
    end
    burn_x:insert(tt, track.tangentCoeffs(burn_x, tt))
    burn_y:insert(tt, track.tangentCoeffs(burn_y, tt))
    return burn_x, burn_y, err
end



return track

