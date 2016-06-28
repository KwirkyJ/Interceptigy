local misclib   = require 'source.misclib'
local piecewise = require 'source.piecewise_poly'
local track     = require 'source.trackfactory'

local luaunit = require 'luaunit.luaunit'

--TODO: rename function and module names
--TODO: more test cases to verify

TestRequiredA = {}
TestRequiredA.test_thing = function(self)
    local p0_x, p0_y, v0_x, v0_y, dx, dy, dt = 80,20, 0.5,1.0, 45,-10, 50
    local ax, ay, req = misclib.findRequiredAcceleration(v0_x, v0_y, dx, dy, dt)
    -- kinematic eqn 1 : 
    -- d == vt + 1/2a*t^2
    -- d - vt == 1/2a*t^2
    -- (d - vt)*2 == a*t^2
    -- (d - vt)*2/t^2 == a
    assertEquals(ax, (dx - v0_x*dt)*2/dt^2) --  0.016
    assertEquals(ay, (dy - v0_y*dt)*2/dt^2) -- -0.048
    assertEquals(req, (ax^2 + ay^2)^0.5)
end



-- given:
-- f1(t)   = a*t^2 + b*t + c
-- f'1(t)  = 2*a*t + b
-- f2(t)   = d*t + e -- unknown
-- f'2(t)  = d -- unknown
--
-- relations:
-- f1(ta)  = f2(ta)
-- f'1(ta) = f'2(ta)
-- f2(t1)  = p1
--
-- d = 2*a*ta + b -- f'2(ta) == f'1(ta)
-- e = p1 - d*t1  -- f2(t1)  == p1
--
-- d*ta + e == a*ta^2 + b*ta + c   -- f1(ta) == f2(ta)
-- SOLVE FOR ta
-- (2*a*ta + b)*ta + (p1-(2*a*ta + b)*t1)  == a*ta^2 + b*ta + c -- expand e, d
-- 2*a*ta^2 + b*ta + p1 - 2*a*ta*t1 - b*t1 == a*ta^2 + b*ta + c -- DPMOA
-- a*ta^2 + b*ta + p1 - a*ta*t1 - b*t1     == b*ta + c          -- subtract a*ta^2 from both sides
-- a*ta^2 + p1 - a*ta*t1 - b*t1            == c                 -- subtract b*ta   from both sides
-- a*ta^2 + p1 - a*ta*t1 - b*t1 - c        == 0                 -- subtract c      from both sides
-- (a)*ta^2 + (-a*t1)*ta + (p1 - b*t1 - c) == 0                 -- show quadratic
-- ta = (-(-a*t1) [+/-] ((-a*t1)^2 - 4*(1/2*a)(p1 - b*t1 - c))^0.5) / (2*(1/2*a)) -- quadratic formula
TestFindBurnCutoff = {}
TestFindBurnCutoff.test_findBurnCutoff = function(self)
    local now, target_x, target_t = 88, 62.6, 200
    local curve = piecewise.Polynomial(0, -0.02, 4.72, -197.88)
    local t_cut = misclib.findBurnCutoff(curve, now, target_x, target_t)
    assertAlmostEquals(t_cut, 123.6848638866443, 1e-12)
end



TestFindClosest = {}
TestFindClosest.test_constants = function(self)
    local now = 5
    local f1x, f1y = track.newParametric(now,20,80)
    local f2x, f2y = track.newParametric(now, 0, 0)
    local t, d = misclib.findClosest(now, f1x, f1y, f2x, f2y)
    assertAlmostEquals(t, 5, 1e-12)
    assertAlmostEquals(d, (20^2 + 80^2), 1e-12, 'returned distance is squared')
end
TestFindClosest.test_const_and_line = function(self)
    local Poly = piecewise.Polynomial
    local now = 5
    local f1x, f1y = track.newParametric(now, 30, 80, 1, -0.5)
    local f2x, f2y = track.newParametric(now, 50, 50)
    local t, d = misclib.findClosest(now, f1x, f1y, f2x, f2y)
    assertAlmostEquals(t, 33, 1e-12)
    assertAlmostEquals(d, 320, 1e-12) -- distance is still squared
end
TestFindClosest.test_inputs_unaltered = function(self)
    local now = 8
    local sometime = 88
    local f1x, f1y = track.newParametric(now, 30, 80, 1, -0.5)
    local f2x, f2y = track.newParametric(now, 50, 50)
    local c1x, c2x, c1y, c2y = f1x:clone(), f2x:clone(), f1y:clone(), f2y:clone()
    local pxt = f1x(sometime)
    _ = misclib.findClosest(now + 5*math.random(), f1x, f1y, f2x, f2y)
    assertEquals(f1x, c1x)
    assertEquals(f2x, c2x)
    assertEquals(f1y, c1y)
    assertEquals(f2y, c2y)
    assertEquals(f1x:evaluate(sometime), pxt)
end
--TODO: two lines, combinations with curves



luaunit:run(arg)

