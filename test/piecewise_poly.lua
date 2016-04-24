-- spec and unit-test for the Piecewise Polynomial class/module

local Piecewise = require 'source.piecewise_poly'

local pp, tmp

pp = Piecewise.Polynomial()
assert(pp(math.random(-100,100)) == nil, 'empty polynomial is nil')

pp:add(0, {1, -2}) -- for t≤0 return (1*t - 2)
tmp = pp:getStarts()
assert(#tmp == 1, 'one piece confirmed')
assert(tmp[1] == 0)

assert(pp(0) == -2)
assert(pp(5) == 5-2)
assert(pp(-2) == nil, 'pre-piece is undefined')

pp:add(3, {-0.5, 3, 0, 2}) -- -1/2*t^3 + 3*t^2 + 0*t + 2 
tmp = pp:getStarts()
assert(#tmp == 2, 'confirm two pieces')
assert(tmp[1] == 0)
assert(tmp[2] == 3)
assert(math.abs( pp(5) - (-0.5*125 + 3*25 + 2) ) < 1e-12, 
       'second piece now at work') -- 14.5
assert(pp(1) == 1-2, 'first piece still valid')
assert(pp(-2) == nil, 'pre-piece is still undefined')

pp:add(2, {8})
tmp = pp:getStarts()
assert(#tmp == 3, 'three pieces now')
assert(tmp[1] == 0 and tmp[2] == 2 and tmp[3] == 3, 'confirm insert')
assert(pp:evaluate(2.2) == 8, 'middling constant function; alias')
assert(pp(3) == -0.5*3^3 + 3*3^2 + 2, 'third piece at play again')

pp:clearBefore(2.2)
tmp = pp:getStarts()
assert(#tmp == 2, 'trim any pieces before 2')
assert(tmp[1] == 2.2 and tmp[2] == 3)
assert(pp(2.99) == 8)
assert(pp(3) == -0.5*3^3 + 3*3^2 + 2, '"third" piece at play again')
assert(pp(2.199) == nil, 'pre-trim is now undefined')

-- add piece before previous start
pp:add(0.5, {1, 0})
assert(pp(1) == 1)
assert(pp(0.4) == nil)
assert(pp(2.5) == 8)
assert(pp(3) == -0.5*3^3 + 3*3^2 + 2, '"third" piece at play again')

--TODO: test equality

print('==== TEST PIECEWISE POLYNOMIAL PASSED ====')

