local luaunit = require 'luaunit.luaunit'
local camera = require 'source.camera'

TestGetWorldPoint = {}
TestGetWorldPoint.setUp = function(self)
    camera:reset(0,0, 800,600, 0, 1) -- x,y, w,h, r, s
end
TestGetWorldPoint.test_defaults = function(self)
    assertEquals({camera:getDimensions()}, {800,600})
    assertEquals({camera:getPosition()}, {0, 0})
    assertEquals(camera:getRotation(), 0)
    assertEquals(camera:getScale(), 0)
    assertEquals({camera:getWorldPoint(0, 0)}, {0, 0})
end

luaunit:run()

