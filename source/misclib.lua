local piecewise = require 'source.piecewise_poly'

local misclib = {}

local pp_add = piecewise.add
local pp_sub = piecewise.subtract
local pp_derive = piecewise.getDerivative
local pp_roots = piecewise.getRoots
local pp_square = piecewise.square


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
end -- findRequiredAcceleration


---find the time where tangent of curve P arrives at value v at time t
-- @param P   Polynomial instance
-- @param now earliest possible instant of acceleration (number)
-- @param v   target value (number)
-- @param t   target time (number)
-- @error P is not quadratic
-- @return number
misclib.findBurnCutoff = function(P, now, v, t)
    local a, b, c = P:getCoefficients(t)
    assert(a and b and c, 'polynomial must be quadratic\t'..tostring(a)..','..tostring(b)..','..tostring(c))
    local ta, B, C, K
--  ta = (-(-2*a*t) [+/-] sqrt((-2*a*t)^2 - 4*a*(v-b*t-c))) / (2*a)
--           --B--               --B--           ---C---
--                             -------------K------------
    B = 2*a*t
    C = v-b*t-c
    K = B^2 - 4*a*C
    ta = (B + K^0.5) / (2*a)
    if  ta >= now
    and ta <= t then
        return ta
    end
    ta = (B - K^0.5) / (2*a)
    if  ta >= now
    and ta <= t then
        return ta
    end
--[[
    error(string.format(
            'no valid burn cutoff found\n%s now = %f  target = %f  target_time = %f',
            tostring(P),
            now,
            v,
            t))
--]]
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
    assert(fx1, 'fx1 must not be nil')
    assert(fx2, 'fx2 must not be nil')
    assert(fy1, 'fy1 must not be nil')
    assert(fy2, 'fy2 must not be nil')

    -- fd :: polynomial, distance (squared) to target over time
    local fd = pp_add(pp_square(pp_sub(fx1,fx2)), pp_square(pp_sub(fy1,fy2)))
    local t_closest, d_closest = t0, fd(t0)
    local roots = pp_roots(pp_derive(fd))
    local n_roots = #roots

    for i=1, n_roots do
        local t_root = roots[i]
        if type(t_root) == 'table' then
            t_root = t_root[1]
        end
        if t_root > t0 then
            local d_root = fd(t_root)
            if d_root < d_closest then
                t_closest, d_closest = t_root, d_root
            end
        end
    end
    return t_closest, d_closest
end


---Get starttime, stoptime where a function is at or below a given value.
-- Assumes function is always positive.
-- Assumes that closest_instant is at a locally-minimal instant.
--     f(closest_instant +/- small_value) > f(closest_instant)
-- @param fd              piecewise polynomial function
-- @param ceiling         target value to find function intercepts
-- @param closest_instant time of "lowest value"
-- @param iterations      how precise to make result (default 20)
--                        accuracy approximately 1/(2^n)
-- @return start, stop of interval;
--         nil if value at closest instant is below ceiling
misclib.findTimeBoundingValue = function(
        fd,
        ceiling,
        closest_instant,
        iterations)
    assert( fd._isPolynomial == true )
    local closest_distance = fd(closest_instant, true)

    if (not closest_distance) or (closest_distance > ceiling) then
        return nil
    end

    iterations = iterations or 20
    local t0 = closest_instant
    local _d
    while true do
        t0 = t0 - 1
        _d = fd(t0)
        if not _d or (_d >= ceiling) then
            break
        end
    end
    for i=1,iterations do
        local delta = 1 / 2^i
        _d = fd(t0)
        if not _d or (_d > ceiling) then
            delta = -delta
        end
        t0 = t0 - delta
    end

    local t1 = closest_instant
    while true do
        t1 = t1 + 1
        _d = fd(t1)
        if not _d or (_d >= ceiling) then
            break
        end
    end
    for i=1,iterations do
        local delta = 1 / 2^i
        _d = fd(t1)
        if not _d or (_d >= ceiling) then
            delta = -delta
        end
        t1 = t1 + delta
    end
    return t0, t1
end -- findTimeBoundingValue()



return misclib

