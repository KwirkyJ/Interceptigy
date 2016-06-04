local piecewise = require 'source.piecewise_poly'

local misclib = {}

---calculate the acceleration required to adjust a position/velocty to
-- by given distance in given time.
-- Uses the first kinematic equation.
-- @param v0_x y-velocity at t0
-- @param v0_y y-velocity at t0
-- @param dx   change in x-position from given to target (at t1)
-- @param dy   change in y-position from given to target (at t1)
-- @param dt   time (in seconds) between t0 and t1
-- @return ax, ay; x and y acceleration components
misclib.find_burnframe = function(v0_x, v0_y, dx, dy, dt)
    local K = 2 / dt^2
    return (dx - v0_x*dt)*K, (dy - v0_y*dt)*K
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
--TODO: move to piecewise_poly; get acceleration curves &c.
    local ta, bx,cx,dx,ex, by,cy,dy,ey
    bx = v0_x - ax*t0
    cx = p0_x - 1/2*ax*t0^2 - bx*t0
    
    local ta_a = (ax*t1 + ((-ax*t1)^2 - 2*ax*(p1_x-bx*t1-cx))^0.5) / ax
    local ta_b = (ax*t1 - ((-ax*t1)^2 - 2*ax*(p1_x-bx*t1-cx))^0.5) / ax
    
--    local var_d = math.huge -- 'mismatch' between derivatives
    -- ta,dx,ex = nil, nil, nil
    for _,t in ipairs({ta_a, ta_b}) do -- t <=> ta
        if t > t0 and t < t1 then
            ta = t
            d = ax*ta + bx
            e = p1_x - d*t1
--            local d_f, d_d -- f2(ta)-f1(ta), f'2(ta)-f'2(ta)
--            d_f = (d*ta + e) - (1/2*ax*ta^2 + bx*ta + cx)
--            d_d = d - (ax*ta + bx)
--            --print(string.format("ta==%f : df == %f, dd == %f", 
--                                  ta, d_f, d_d))
--            --assert(d_f < 1e-10)
--            if d_d < var_d then 
                var_d = d_d
                ta,dx,ex = t,d,e
--            end
        end
        assert(ta, 'ta cannot be nil; acceleration beyond allowed time')
    end
    by = v0_y - ay*t0
    cy = p0_y - 1/2*ay*t0^2 - by*t0
    dy = ay*ta + by
    ey = p1_y - dy*t1

    return ta, bx,cx,dx,ex, by,cy,dy,ey
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

