
local atan = math.atan2 or math.atan

local viewport = {_VERSION = '0.1.0'}

viewport.getDimensions = function(self)
    return self.width, self.height
end

viewport.getPosition = function(self)
    return self.x, self.y
end

viewport.setPosition = function(self, x, y, delta)
    if delta then
        self.x, self.y = self.x + x, self.y + y
    else
        self.x, self.y = x, y
    end
end

viewport.getWorldPoint = function(self, x, y)
    return self.x + x, self.y + y
end

viewport.getScreenPoint = function(self, x, y)
    return x - self.x, y - self.y
end

viewport.getCenter = function(self)
    return self.x + self.width / 2, self.y + self.height / 2
end

viewport.setCenter = function(self, x, y)
    self.x, self.y = x - self.width/2, y - self.height / 2
end

viewport.getBounds = function(self)
    return self.x, self.y, self.x + self.width, self.y + self.height
end

viewport.update = function(self, dt)
    if self.transDMag then
        local mag = dt * self.panrate
        local dx, dy = mag * math.cos(self.transDTheta),
                       mag * math.sin(self.transDTheta)
        if math.abs(dx) >= math.abs(self.transDX) then
            self.x, self.y = self.x + self.transDX, self.y + self.transDY
            self.transDX, self.transDY, self.transDMag, self.transDTheta = false, false, false, false
        else
            self.x, self.y = self.x + dx, self.y + dy
            self.transDX = self.transDX - dx
            self.transDY = self.transDY - dy
        end
        
    end
end

viewport.setPanRate = function(self, delta_units)
    self.panrate = delta_units
end

viewport.pan = function(self, dx, dy)
    self.transDX, self.transDY = dx, dy
    self.transDTheta, self.transDMag = atan(dy, dx), (dx^2 + dy^2)^0.5
end

viewport.new = function(width, height)
    return {width  = width,
            height = height,
            x = 0,
            y = 0,
            getDimensions  = viewport.getDimensions,
            getBounds      = viewport.getBounds,
            getPosition    = viewport.getPosition,
            setPosition    = viewport.setPosition,
            getWorldPoint  = viewport.getWorldPoint,
            getCenter      = viewport.getCenter,
            setCenter      = viewport.setCenter,
            getScreenPoint = viewport.getScreenPoint,
            update         = viewport.update,
            pan            = viewport.pan,
            setPanRate     = viewport.setPanRate,
           }
end

return viewport

