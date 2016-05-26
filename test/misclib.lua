local luaunit = require 'luaunit.luaunit'
local misclib = require 'source.misclib'

--TODO: rename function and module names
--TODO: more test cases to verify

TestBurnframe = {}
TestBurnframe.test_thing = function(self)
    local p0_x, p0_y, v0_x, v0_y, dx, dy, dt = 80, 20,0.5, 1.0, -25, -10, 50
    local ax, ay = misclib.find_burnframe(v0_x, v0_y, dx, dy, dt)
    -- kinematic eqn 1 : 
    -- d == vt + 1/2at^2
    -- d - vt == 1/2at^2
    -- (d - vt)*2/t^2 == a
    assertEquals(ax, (dx - v0_x*dt)*2/dt^2)
    assertEquals(ay, (dy - v0_y*dt)*2/dt^2)
end



-- f1(t0)  = p0
-- f'1(t0) = v0
-- f1(ta)  = f2(ta)
-- f'1(ta) = f'2(ta)
-- f2(t1)  = p1
--
-- f1  = 1/2*a*t^2 + b*t + c
-- f'1 = a*t + b
-- f2  = d*t + e
-- f'2 = d
--
-- b = v0 - a*t0              -- f'1(t0) == v0
-- c = p0 - 1/2*a*t0^2 - b*t0 -- f1(t0)  == p0
-- d = a*ta + b               -- f'2(ta) == f'1(ta)
-- e = p1 - d*t1              -- f2(t1)  == p1
--
-- d*ta + e == 1/2*a*ta^2 + b*ta + c   -- f1(ta) == f2(ta)
-- SOLVE FOR ta
-- (a*ta + b)*ta + (p1-(a*ta + b)*t1) == 1/2*a*ta^2 + b*ta + c -- expand e, d
-- a*ta^2 + b*ta + p1 - a*ta*t1 - b*t1 == 1/2*a*ta^2 + b*ta + c -- DPMOA
-- 1/2*a*ta^2 + b*ta + p1 - a*ta*t1 - b*t1 == b*ta + c -- subract 1/2*a*ta^2 from both sides
-- 1/2*a*ta^2 + p1 - a*ta*t1 - b*t1 == c --subtract b*ta from both sides
-- 1/2*a*ta^2 - a*t1*ta + p1 - b*t1 - c == 0 -- subract c from both sides; reorder
-- (1/2*a)*ta^2 + (-a*t1)*ta + (p1 - b*ta - c) == 0 -- show quadratic
-- ta = (-(-a*t1) [+/-] ((-a*t1)^2 - 4*(1/2*a)(p1 - b*t1 - c))^0.5) / (2*(1/2*a)) -- quadratic formula
TestBurnpoint = {}
TestBurnpoint.test_thing = function(self)
    local a_max = 0.05
    local dx, dy, D = -25, -10, (725)^0.5 -- D = ((-25)^2 + (-10)^2)^0.5
    
    local ax, ay = dx*a_max/D, dy*a_max/D
    local t0, p0_x, p0_y, v0_x, v0_y, t1, p1_x, p1_y = 300, 80, 20, 0.5, 1.0, 350, 80, 60
    local ta, bx, cx, dx, ex, by, cy, dy, ey = misclib.find_burnpoint(t0, p0_x, p0_y, v0_x, v0_y, ax, ay, t1, p1_x, p1_y)
    assertEquals(ta, (ax*t1 + ((-ax*t1)^2 - 2*ax*(p1_x-bx*t1-cx))^0.5) / ax) -- 312.27776466627...
    
    assertEquals(bx, v0_x - ax*t0)
    assertEquals(cx, p0_x - 1/2*ax*t0^2 - bx*t0)
    assertEquals(dx, ax*ta + bx)
    assertEquals(ex, p1_x - dx*t1)
    
    assertEquals(by, v0_y - ay*t0)
    assertEquals(cy, p0_y - 1/2*ay*t0^2 - by*t0)
    assertEquals(dy, ay*ta + by)
    assertEquals(ey, p1_y - dy*t1)
end

luaunit:run(arg)

