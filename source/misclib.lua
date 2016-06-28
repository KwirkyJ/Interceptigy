local piecewise = require 'source.piecewise_poly'

local misclib = {}

---calculate the acceleration required to adjust a position/velocty to
-- by given distance in given time; uses the first kinematic equation
-- @param v0_x y-velocity at t0
-- @param v0_y y-velocity at t0
-- @param dx   change in x-position from given to target (at t1)
-- @param dy   change in y-position from given to target (at t1)
-- @param dt   time (in seconds) between t0 and t1
-- @return ax, ay, h (numbers: x- and y-acceleration components and 
--         hypotenuse of their vectors)
misclib.findRequiredAcceleration = function(v0_x, v0_y, dx, dy, dt) 
    -- kinematic eqn:
    -- d = v0*dt + 0.5*a*dt^2
    -- a = (d - v0*dt) / (dt^2 / 2)
    --   = (d-v0*dt)*(2/dt^2)
    local K = 2 / dt^2
    local ax, ay = (dx - v0_x*dt)*K, (dy - v0_y*dt)*K
    return ax, ay, (ax^2 + ay^2)^0.5
end



---find the time where tangent of curve P arrives at value v at time t
-- @param P   Polynomial instance
-- @param now earliest possible instant of acceleration (number)
-- @param v   target value (number)
-- @param t   target time (number)
-- @error P is not quadratic
-- @return number
misclib.findBurnCutoff = function(P, now, v, t)
    local a, b, c = P:getCoefficients(t)
    assert(a and b and c, 'polynomial must be quadratic\t'..a..','..b..','..c)
    local ta, l,m,n
--  ta = (-(-2*a*t) [+/-] sqrt((-2*a*t)^2 - 4*a*(v-b*t-c))) / (2*a)
--           --l--               --l--           ---m---
--                             -------------n------------ 
    l = 2*a*t
    m = v-b*t-c
    n = l^2 - 4*a*m
    ta = (l + n^0.5) / (2*a)
    if ta >= now and ta <= t then return ta end
    ta = (l - n^0.5) / (2*a)
    if ta >= now and ta <= t then return ta end
    --error(string.format('no valid burn cutoff found\n%s now = %f  target = %f  target_time = %f', tostring(P), now, v, t))
    return now
end



---find the time and distance of closest approach between two tracks
-- @param t0  earliest valid time value in solution space
-- @param fx1 x-component of track 1 (Polynomial instance)
-- @param fy1 y-component of track 1 (Polynomial instance)
-- @param fx2 x-component of track 2 (Polynomial instance)
-- @param fy2 y-component of track 2 (Polynomial instance)
-- @return time, squared distance (numbers)
misclib.findClosest = function(t0, fx1, fy1, fx2, fy2)
    local dx, dy, t, fd
    assert(fx1, 'fx1 must not be nil')
    assert(fx2, 'fx2 must not be nil')
    assert(fy1, 'fy1 must not be nil')
    assert(fy2, 'fy2 must not be nil')
    dx, dy = fx1:subtract(fx2), fy1:subtract(fy2)
    fd = piecewise.add(dx:square(), dy:square()):getDerivative()
    t = t0
    local roots = fd:getRoots(0)
    if #roots == 0 then return nil end
    for _,r in ipairs(roots) do
        if type(r) == 'table' then r = r[1] end
        if r > t then t=r; break end
    end
    return t, dx(t)^2 + dy(t)^2
end



return misclib

