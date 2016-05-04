---Map two coordinate systems to one another
-- 
-- Conversion module mapping a 'viewport' onto a region of 'world space';
-- supports zooming and panning in addition to basic setters.

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
    --return self.x + x, self.y + y
    return self.x + x / self.scale, 
           self.y + y / self.scale
end

viewport.getScreenPoint = function(self, x, y)
    return (x-self.x) * self.scale, (y-self.y) * self.scale
end

viewport.getCenter = function(self)
    return self.x + self.width  / 2 / self.scale, 
           self.y + self.height / 2 / self.scale
end

viewport.setCenter = function(self, x, y)
    self.x, self.y = x - self.width  / 2 / self.scale, 
                     y - self.height / 2 / self.scale
end

viewport.getBounds = function(self)
    return self.x, 
           self.y, 
           self.x + self.width  / self.scale, 
           self.y + self.height / self.scale
end

viewport.update = function(self, dt)
    if self.transDMag then
        local mag = dt * self.panRate
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
    if self.zoomDelta then
        local powerDelta, cenx, ceny = self.zoomRate * dt
        cenx, ceny = self:getCenter()
        if self.zoomDelta < 0 then
            powerDelta = -powerDelta
        end
        if math.abs(self.zoomDelta) <= math.abs(powerDelta) then
            self:setZoom(self.zoomPower + self.zoomDelta)
            self.zoomDelta = false
        else
            self:setZoom(self.zoomPower + powerDelta)
            self.zoomDelta = self.zoomDelta - powerDelta
        end
        if self.zoomCenter then self:setCenter(cenx, ceny) end
        if not zoomDelta then zoomCenter = false end
    end
end

viewport.getPanRate = function(self)
    return self.panRate
end

viewport.setPanRate = function(self, delta_units)
    self.panRate = delta_units
end

viewport.pan = function(self, dx, dy)
    self.transDX, self.transDY = dx, dy
    self.transDTheta, self.transDMag = atan(dy, dx), (dx^2 + dy^2)^0.5
end

viewport.getScale = function(self)
    return self.scale
end

---Find what power of BASE near-equates target
local function exponent_solve(base, target)
    local x, range = 0, 1
    while math.abs(base^x - target) > 1e-13 do
        if target < (base^(x - range)) then
            x, range = x-range, range*2
        elseif target > (base^(x + range)) then
            x, range = x+range, range*2
        else
            range = range / 2
        end
    end
    return x
end

viewport.setScale = function(self, s, where)
    local cenx, ceny 
    if where == 'center' then
        cenx, ceny = self:getCenter()
    end
    self.scale = s
    self.zoomPower = exponent_solve(self.zoomBase, s)
    if cenx then self:setCenter(cenx, ceny) end
end

viewport.getZoom = function(self)
    return self.zoomPower
end

viewport.setZoom = function(self, z, where)
    local cenx, ceny
    if where == 'center' then
        cenx, ceny = self:getCenter()
    end
    self.zoomPower = z
    self.scale = self.zoomBase ^ z
    if cenx then self:setCenter(cenx, ceny) end
end

viewport.getZoomBase = function(self)
    return self.zoomBase
end

viewport.setZoomBase = function(self, b)
    -- maintains current scaling and position
    self.zoomPower = exponent_solve(b, self:getScale())
    self.zoomBase = b
    self.scale = self.zoomBase ^ self.zoomPower
end

viewport.getZoomRate = function(self)
    return self.zoomRate
end

viewport.setZoomRate = function(self, r)
    self.zoomRate = r
end

viewport.zoom = function(self, delta, where)
    if where == 'center' then
        self.zoomCenter = true
    end
    self.zoomDelta = delta
end

viewport.new = function(width, height)
    return {x         = 0,
            y         = 0,
            width     = width,
            height    = height,
            scale     = 1,
            panRate   = 1,
            zoomBase  = 2,
            zoomPower = 0,
            zoomRate  = 1, -- whatever that means
            getDimensions  = viewport.getDimensions,
            getBounds      = viewport.getBounds,
            getPosition    = viewport.getPosition,
            setPosition    = viewport.setPosition,
            getWorldPoint  = viewport.getWorldPoint,
            getScreenPoint = viewport.getScreenPoint,
            getCenter      = viewport.getCenter,
            setCenter      = viewport.setCenter,
            update         = viewport.update,
            pan            = viewport.pan,
            getPanRate     = viewport.getPanRate,
            setPanRate     = viewport.setPanRate,
            getScale       = viewport.getScale,
            setScale       = viewport.setScale,
            getZoom        = viewport.getZoom,
            setZoom        = viewport.setZoom,
            getZoomBase    = viewport.getZoomBase,
            setZoomBase    = viewport.setZoomBase,
            getZoomRate    = viewport.getZoomRate,
            setZoomRate    = viewport.setZoomRate,
            zoom           = viewport.zoom,
           }
end

return viewport

