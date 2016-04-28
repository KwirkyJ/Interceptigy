local camera = {}

camera.reset = function(self, x, y, w, h, theta, s)
end

camera.getDimensions = function(self)
end

camera.setDimensions = function(self, w, h)
end

camera.getPosition = function(self)
end

camera.setPosition = function(self, x, y)
end

camera.getRotation = function(self)
end

camera.setRotation = function(self, theta)
end

camera.getScale = function(self)
end

camera.setScale = function(self, s)
end

--camera.setScaleLevels
--camera.setZoomBehavior
--camera.setZoomSpeed

camera.getWorldPoint = function(self, x, y)
end

camera.getScreenPoint = function(self, x, y)
end

camera.update = function(self, dt)
end

--TODO: scaling, rotating, panning

return camera

