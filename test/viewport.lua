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
    self.vp:setPanRate(100) -- 100 'screen distance units' per second
    self.vp:setPosition(-20, 0)
    assertEquals({self.vp:getBounds()}, {-20, 0, 780, 600})
    
    self.vp:pan(200, 100) -- h=223
    self.vp:update(0.5) -- half-second
    local atan = math.atan2 or math.atan
    local theta = atan(100, 200)
    local dx, dy = 50*math.cos(theta), 50*math.sin(theta)
    assertAlmostEquals(dy, 22.360679774998, 1e-10)
    assertAlmostEquals(dx, 44.721359549996, 1e-10)
    assertEquals({self.vp:getBounds()}, {dx-20, dy+0, dx+780, dy+600})
    
    self.vp:update(2.0)
    assertEquals({self.vp:getBounds()}, {180, 100, 980, 700})
end



TestScale = {}
TestScale.setUp = function(self)
    self.vp = viewport.new(500, 400)
end
TestScale.test_setScale = function(self)
    assertEquals({self.vp:getBounds()}, {0, 0, 500, 400})
    assertEquals({self.vp:getCenter()}, {250, 200})
    assertEquals( self.vp:getScale(), 1)
    assertEquals( self.vp:getZoom(), 0)
    
    self.vp:setScale(2)
    assertEquals({self.vp:getCenter()},             {125, 100})
    assertEquals({self.vp:getBounds()},             {0, 0, 250, 200})
    assertEquals({self.vp:getWorldPoint(200, 80)},  {100, 40})
    assertEquals({self.vp:getScreenPoint(200, 80)}, {400, 160})
    assertEquals( self.vp:getZoomBase(),            2)
    assertAlmostEquals( self.vp:getZoom(), 1, 1e-12)
end
TestScale.test_setScale_centered = function(self)
    assertEquals({self.vp:getBounds()}, {0, 0, 500, 400})
    assertEquals({self.vp:getCenter()}, {250, 200})
    
    self.vp:setScale(100, "center")
    assertEquals({self.vp:getCenter()},             {250, 200})
    assertEquals({self.vp:getBounds()},             {247.5, 198, 252.5, 202})
    assertEquals({self.vp:getWorldPoint(200, 80)},  {249.5, 198.8})
    assertEquals({self.vp:getScreenPoint(200, 80)}, {-4750, -11800})
    assertAlmostEquals(self.vp:getZoom(), 6.64385619, 1e-7)
    
    self.vp:setZoomBase(10) -- demonstrate base-change maintains situation
    assertAlmostEquals(self.vp:getZoom(), 2, 1e-12)
    assertEquals({self.vp:getBounds()},             {247.5, 198, 252.5, 202})
    assertEquals({self.vp:getWorldPoint(200, 80)},  {249.5, 198.8})
end
TestScale.test_setZoom = function(self)
    self.vp:setZoom(1)
    assertAlmostEquals(self.vp:getScale(), 2, 1e-12)
    assertEquals({self.vp:getCenter()},             {125, 100})
    assertEquals({self.vp:getBounds()},             {0,0, 250,200})
    assertEquals({self.vp:getWorldPoint(80, 100)},  {40, 50})
    assertEquals({self.vp:getScreenPoint(80, 100)}, {160, 200})
end
TestScale.test_setZoom_centered = function(self)
    self.vp:setZoomBase(10)
    self.vp:setZoom(-1, "center")
    assertAlmostEquals(self.vp:getScale(), 0.1, 1e-12)
    assertEquals({self.vp:getCenter()},             {250, 200})
    assertEquals({self.vp:getBounds()},             {-2250,-1800, 2750,2200})
    assertEquals({self.vp:getWorldPoint(80, 100)},  {-1450,-800})
    assertEquals({self.vp:getScreenPoint(80, 100)}, {233, 190})
end
TestScale.test_zoom = function(self)
    assertEquals(self.vp:getZoomRate(), 1) -- zoom level/s ? s/zoom level
    assertEquals(self.vp:getZoomBase(), 2) -- reaffirm default
    
    self.vp:zoom(1, "center")
    self.vp:update(0.5)
    local halfx, halfy = 500 / 2^0.5 / 2, 400 / 2^0.5 / 2 -- dim/scale/2
    assertAlmostEquals(self.vp:getScale(), 2^0.5, 1e-12)
    assertEquals({self.vp:getCenter()}, {250, 200})
    assertEquals({self.vp:getBounds()}, 
                 {250 - halfx, 200 - halfy,
                  250 + halfx, 200 + halfy})
    self.vp:update(0.6) -- dt sum == 1.1
    assertAlmostEquals(self.vp:getScale(), 2, 1e-12)
    assertAlmostEquals(self.vp:getZoom(), 1, 1e-12)
    assertEquals({self.vp:getBounds()}, {125, 100, 375, 300})
end
TestScale.test_setZoom_is_absolute = function(self)
    self.vp:setZoom(1)
    assertEquals({self.vp:getBounds()}, {0, 0, 250, 200})
    self.vp:setZoom(0)
    assertAlmostEquals(self.vp:getScale(), 1, 1e-12)
    assertEquals({self.vp:getBounds()}, {0, 0, 500, 400})
end
TestScale.test_zoom_is_relative = function(self)
    self.vp:setZoomBase(10)
    self.vp:setScale(10)
    assertAlmostEquals(self.vp:getZoom(), 1, 1e-12)
    assertEquals({self.vp:getBounds()}, {0,0, 50, 40})
    
    self.vp:setZoomRate(2) -- 2 'levels' per second
    self.vp:zoom(-1)
    self.vp:update(0.3)
    assertAlmostEquals(self.vp:getZoom(), 0.4, 1e-12)
    local w, h = self.vp:getWorldPoint(500, 400)
    assertAlmostEquals(w, 500/10^0.4, 1e-10) -- ~ 199.05358527675
    assertAlmostEquals(h, 400/10^0.4, 1e-10) -- ~ 159.2428682214
end
--TODO: supply a function specifying zoom behavior?


TestConcurrent = {}
TestConcurrent.setUp = function(self)
    self.vp = viewport.new(1600, 900)
end
TestConcurrent.test_pan_while_scaled = function(self)
    local x, y
    self.vp:setScale(4)
    assertEquals({self.vp:getBounds()}, {0,0, 400, 225})
    assertEquals(self.vp:getPanRate(), 1) -- screen units per second
    
    self.vp:pan(3, 4) -- h = 5
    self.vp:update(4) -- at scale of 4, takes 4 seconds to move distance of 1
    --x, y = 3/5, 4/5
    --assertEquals({self.vp:getBounds()}, {x, y, 400+x, 225+y})
    x,y,_,_ = self.vp:getBounds()
    assertAlmostEquals(x, 3/5, 1e-12)
    assertAlmostEquals(y, 4/5, 1e-12)
    
    self.vp:update(16.1) -- 5 * 4 - 4 + 0.1 : just over the time needed
    x, y = 3, 4
    assertEquals({self.vp:getBounds()}, {x, y, 400+x, 225+y})
end
TestConcurrent.test_zoom_while_translated = function(self)
    self.vp:setPosition(-1000, 100)
    assertEquals({self.vp:getBounds()},  {-1000, 100, 600, 1000})
    assertEquals( self.vp:getZoom(),     0)
    assertEquals( self.vp:getZoomBase(), 2)
    assertEquals( self.vp:getZoomRate(), 1)
    
    self.vp:zoom(1)
    self.vp:update(0.5)
    assertAlmostEquals(self.vp:getScale(), 2^0.5, 1e-12)
    assertEquals({self.vp:getBounds()}, 
                 {-1000, 100,
                  1600 / 2^0.5 - 1000, 900 / 2^0.5 + 100})
end
TestConcurrent.test_pan_and_zoom = function(self)
    local x, y, xmax, ymax
    self.vp:setPanRate(10)
    assertAlmostEquals(self.vp:getZoomRate(), 1, 1e-12)
    
    self.vp:pan(-100,0)
    self.vp:update(0.5)
    x,y = self.vp:getPosition()
    -- assertEquals({self.vp:getPosition()}, {-5, 0})
    assertAlmostEquals(x,-5, 1e-12)
    assertAlmostEquals(y, 0, 1e-12)
    
    self.vp:zoom(1, 'center')
    self.vp:update(0.5)
    assertAlmostEquals(self.vp:getScale(), 2^0.5, 1e-12)
    x, y, _, _ = self.vp:getBounds()
    assertAlmostEquals(x, (800-800/2^0.5)-(5/2^0.5)-5, 1e-12)--225.77904114483
    assertAlmostEquals(y,  450-450/2^0.5,              1e-12)
    
    self.vp:update(0.5)
    assertAlmostEquals(self.vp:getScale(), 2, 1e-12)
    x,y, xmax,ymax = self.vp:getBounds()
    assertAlmostEquals(x, 400 - 5 - 5/2^0.5 - 5/2, 1e-12)--388.96446609407
    assertAlmostEquals(y, 225, 1e-12)
    assertAlmostEquals(xmax, x + 800, 1e-12)
    assertAlmostEquals(ymax, y + 450, 1e-12)
    
    self.vp:update(9)
    assertAlmostEquals(self.vp:getScale(), 2, 1e-12)
    x,y, xmax,ymax = self.vp:getBounds()
    assertAlmostEquals(x, 400 - 5 - 5/2^0.5 - 5/2 - 10/2*9, 1e-12)
    assertAlmostEquals(y, 225, 1e-12)
    assertAlmostEquals(xmax, x + 800, 1e-12)
    assertAlmostEquals(ymax, y + 450, 1e-12)
    --
end



luaunit:run()

