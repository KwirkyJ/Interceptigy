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
misclib.findRequiredAccel = function(v0_x, v0_y, dx, dy, dt) 
    -- kinematic eqn:
    -- d = v0*dt + 0.5*a*dt^2
    -- a = (d - v0*dt) / (dt^2 / 2)
    --   = (d-v0*dt)*(2/dt^2)
    local K = 2 / dt^2
    local ax, ay = (dx - v0_x*dt)*K, (dy - v0_y*dt)*K
    return ax, ay, (ax^2 + ay^2)^0.5
end



---find the polynomial components and merge-point for boost-coast to target
-- destination at destination time given fixed acceleration.
-- @param t0   start time of acceleration
-- @param p0_x x-position at t0
-- @param p0_y y-position at t0
-- @param v0_x x-veloctiy at t0
-- @param v0_y y-position at t0
-- @param ax   acceleration in x-axis
-- @param ay   acceleration in y-axis
-- @param t1   time of target position
-- @param p1_x target x-position
-- @param p1_y target y-position
-- @return ta (end of acceleration)
--         bx, cx, dx, ex (first and zeroth factor for f1x and f2x)
--         by, cy, dy, ey (same for fny)
misclib.find_burnpoint = function(t0, p0_x, p0_y, v0_x, v0_y, 
                                  ax, ay, t1, p1_x, p1_y)
    local ta, bx,cx,dx,ex, by,cy,dy,ey
    bx = v0_x - ax*t0
    cx = p0_x - 1/2*ax*t0^2 - bx*t0
    
    -- 'candidate' times for acceleration-end
    local ta_a = (ax*t1 + ((-ax*t1)^2 - 2*ax*(p1_x-bx*t1-cx))^0.5) / ax
    local ta_b = (ax*t1 - ((-ax*t1)^2 - 2*ax*(p1_x-bx*t1-cx))^0.5) / ax
    
    for _,t in ipairs({ta_a, ta_b}) do -- t <=> ta
        if t > t0 and t < t1 then
            ta = t
            local d = ax*ta + bx
            local e = p1_x - d*t1
            ta,dx,ex = t,d,e
        end
        assert(ta, 'ta cannot be nil; acceleration beyond allowed time')
    end
    by = v0_y - ay*t0
    cy = p0_y - 1/2*ay*t0^2 - by*t0
    dy = ay*ta + by
    ey = p1_y - dy*t1

    return ta, bx,cx,dx,ex, by,cy,dy,ey
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
    --assert(a and b and c, 'polynomial must be quadratic')
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
    error('no valid burn cutoff found')
end



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

