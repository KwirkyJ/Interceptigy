local luaunit = require 'luaunit.luaunit'
local viewport = require 'source.viewport'



TestTranslation = {}
TestTranslation.setUp = function(self)
    self.vp = viewport.new(800,600)
end
TestTranslation.test_defaults = function(self)
    assertEquals({self.vp:getDimensions()}, {800,600})
    assertEquals({self.vp:getPosition()}, {0, 0})
    assertEquals({self.vp:getCenter()}, {400,300})
    assertEquals({self.vp:getBounds()}, {0, 0, 800, 600})
--    assertEquals( self.vp:getRotation(), 0)
    --assertEquals( self.vp:getScale(), 1)
    assertEquals({self.vp:getWorldPoint(30, 400)}, {30, 400})
    assertEquals({self.vp:getScreenPoint(30, 400)}, {30, 400})
end
TestTranslation.test_reposition_absolute = function(self)
    self.vp:setPosition(80, -100)
    assertEquals({self.vp:getDimensions()}, {800,600})
    assertEquals({self.vp:getPosition()}, {80, -100})
    assertEquals({self.vp:getCenter()}, {480,200})
    assertEquals({self.vp:getBounds()}, {80, -100, 880, 500})
    assertEquals({self.vp:getWorldPoint(30, 400)}, {110, 300})
    assertEquals({self.vp:getScreenPoint(30, 400)}, {-50, 500})
end
TestTranslation.test_reposition_delta = function(self)
    self.vp:setPosition(80, -100)
    self.vp:setPosition(-500, 15, true)
    assertEquals({self.vp:getBounds()}, {-420, -85, 380, 515})
end
TestTranslation.test_recenter = function(self)
    self.vp:setCenter(20, 20)
    assertEquals({self.vp:getPosition()}, {-380, -280})
    assertEquals({self.vp:getCenter()}, {20, 20})
    assertEquals({self.vp:getBounds()}, {-380, -280, 420, 320})
    assertEquals({self.vp:getWorldPoint(30, 400)}, {-350, 120})
    assertEquals({self.vp:getScreenPoint(30, 400)}, {410, 680})
end
TestTranslation.test_pan_rateset = function(self)
    self.vp:setPanRate(100) -- 100 'world distance units' per second
    self.vp:setPosition(-20, 0)
    self.vp:pan(200, 100)
    assertEquals({self.vp:getBounds()}, {-20, 0, 780, 600})
    
    self.vp:update(0.5) -- half-second
    local atan = math.atan2 or math.atan
    local theta = atan(100, 200)
    local dx, dy = 50*math.cos(theta), 50*math.sin(theta)
    assertAlmostEquals(dy, 22.360679774998, 1e-10)
    assertAlmostEquals(dx, 44.721359549996, 1e-10)
    assertEquals({self.vp:getBounds()}, {dx-20, dy+0, dx+780, dy+600})
end
--TODO: pan while zoomed(-ing) in/out and/or rotated(-ing)

luaunit:run()

