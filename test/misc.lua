---collection of test cases for various non-module-specific purposes.

luaunit   = require 'luaunit.luaunit'

entity    = require 'source.entity'
piecewise = require 'source.piecewise_poly'
misclib   = require 'source.misclib'
track     = require 'source.trackfactory'



TestLoopMock = {}
TestLoopMock.tearDown = function(self)
    self.closest = nil
    self.entities = nil
    self.mouse = nil
    self.now = nil
end
TestLoopMock.updateThings = function(self)
    self.closest = nil
    for _,e in ipairs(self.entities) do
        local efx, efy = e[1], e[2]
        
        local mousefx, mousefy = self.mouse[1], self.mouse[2]
        assert(mousefx, 'mouse x position should exist')
        assert(mousefy, 'mouse y position should exist')
        assert(efx, 'entity x position should exist')
        assert(efy, 'entity y position should exist')
        assert(self.now)
        
        local t, d = misclib.findClosest(self.now, mousefx, mousefy, efx, efy)
        if t then
            if not self.closest 
            or d < self.closest[3] 
            then
                self.closest = {e, t, d}
            end
        else
            local ex, ey, dx, dy, d
            ex, ey = e:getPosition(now)
            dx, dy = math.abs(mx(now) - ex), math.abs(my(now) - ey)
            d = dx^2 + dy^2
            if d*camera:getScale() <= MAX_PIXELS_TO_INTERACT then
                if not self.closest or d < self.closest[3] then 
                    self.closest = {e, now, d} 
                end
            end
        end
    end
    if self.closest then self.closest[3] = self.closest[3]^0.5 end
end
TestLoopMock.test_findClosest_sign_flip = function(self)
    local x, y = 0, 0
    local mousefx, mousefy = track.newParametric(0, 30, -20) -- mouse position through time
    --entity.new(t, p0x, p0y, v0x, v0y, color)
    self.entities = {entity.new(5, 20, 5, 1,-1, {1,1,1}),
                     entity.new(5,  7,-5,-1,-1, {1,1,1})}
    self.now = 12 -- arbitrary gametime in seconds
    self.mouse = {mousefx, mousefy}
    
    -- before-loop status
    assertNil(self.closest)
    assertEquals({self.entities[1]:getPosition(self.now)}, {27, -2})
    -- x == 1*(12-5) + 20),  y == -1*(12-5) + 5)
    
    -- first loop iteration
    self:updateThings()
    
    assertEquals({self.entities[1]:getPosition(self.now)}, {12+15, -12+10},
                 'check for sign-flip')
    assertTable(self.closest, 'closest is populated with something')
    assertEquals(self.closest[1], self.entities[1])
    assertAlmostEquals(self.closest[2], 90/4, 1e-12) -- time
    assertAlmostEquals(self.closest[3], 
                       (2*(90/4)^2 - 90*(90/4) + 1125)^0.5, 
                       1e-12) -- distance
    
    -- next iteration
    self.now = 13
    
    assertEquals({self.entities[1]:getPosition(self.now)}, {28, -3},
                 'verify new position')
    
    self:updateThings()
    
    assertEquals({self.entities[1]:getPosition(self.now)}, {28, -3},
                 'check again for sign-flip')
    assertTable(self.closest)
    assertEquals(self.closest[1], self.entities[1], 'closest is populated with the same thing')
    assertAlmostEquals(self.closest[2], 90/4, 1e-12) -- time
    assertAlmostEquals(self.closest[3], (2*(90/4)^2 - 90*(90/4) + 1125)^0.5, 1e-12) -- distance
end



luaunit:run()

