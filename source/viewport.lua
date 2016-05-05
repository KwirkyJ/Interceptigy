---Map two coordinate systems to one another
-- 
-- Conversion module mapping a 'viewport' onto a region of 'world space';
-- supports zooming and panning in addition to basic setters.

local atan = math.atan2 or math.atan



local viewport = {_VERSION = '0.1.0'}

---Get the canonical dimensions of the viewport
viewport.getDimensions = function(self)
    return self.width, self.height
end

---Get the world position of the upper-left corner of the viewport
viewport.getPosition = function(self)
    return self.x, self.y
end

---Set the world position of the viewport's upper-left corner
viewport.setPosition = function(self, x, y, delta)
    if delta then
        self.x, self.y = self.x + x, self.y + y
    else
        self.x, self.y = x, y
    end
end

---Get the world point corresponding to the given screen coordinates
viewport.getWorldPoint = function(self, x, y)
    --return self.x + x, self.y + y
    return self.x + x / self.scale, 
           self.y + y / self.scale
end

---Get the screen point corresponding to the given world coordinates
viewport.getScreenPoint = function(self, x, y)
    return (x-self.x) * self.scale, (y-self.y) * self.scale
end

---Get the world point corresponding to the viewport's center
viewport.getCenter = function(self)
    return self.x + self.width  / 2 / self.scale, 
           self.y + self.height / 2 / self.scale
end

---Position the screen such that its center lies on the given world point
viewport.setCenter = function(self, x, y)
    self.x, self.y = x - self.width  / 2 / self.scale, 
                     y - self.height / 2 / self.scale
end

---Get the world points in order; min-x, min-y, max-x, max-y; of the viewport
viewport.getBounds = function(self)
    return self.x, 
           self.y, 
           self.x + self.width  / self.scale, 
           self.y + self.height / self.scale
end

---Transform the viewport in accordance with elapsed time (zoom, pan, -rotate-)
viewport.update = function(self, dt)
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
    if self.transDMag then
        local mag = dt * self.panRate
        local dx, dy = mag * math.cos(self.transDTheta) / self.scale,
                       mag * math.sin(self.transDTheta) / self.scale
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

---Get the rate, screen points per second, of panning in updates
viewport.getPanRate = function(self)
    return self.panRate
end

---Set the rate, screen points per second, of paning in updates
viewport.setPanRate = function(self, delta_units)
    self.panRate = delta_units
end

---Queue a translation of the viewport by the given (world) distances
--TODO: ? flag/toggle world or screen distances
viewport.pan = function(self, dx, dy)
    self.transDX, self.transDY = dx, dy
    self.transDTheta, self.transDMag = atan(dy, dx), (dx^2 + dy^2)^0.5
end

---Get the current scale of the viewport
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

---Set the scale of the viewport - adjusts zoomPower as closely as possible; 
-- can scale relative to center (default ULC)
viewport.setScale = function(self, s, where)
    local cenx, ceny 
    if where == 'center' then
        cenx, ceny = self:getCenter()
    end
    self.scale = s
    self.zoomPower = exponent_solve(self.zoomBase, s)
    if cenx then self:setCenter(cenx, ceny) end
end

---Get the zoomPower of the viewport (scale = zoomBase ^ zoomPower)
viewport.getZoom = function(self)
    return self.zoomPower
end

---Set zoomPower to a given value; can scale relative to center (default ULC)
viewport.setZoom = function(self, z, where)
    local cenx, ceny
    if where == 'center' then
        cenx, ceny = self:getCenter()
    end
    self.zoomPower = z
    self.scale = self.zoomBase ^ z
    if cenx then self:setCenter(cenx, ceny) end
end

---Get the base of the zoom logarithm
viewport.getZoomBase = function(self)
    return self.zoomBase
end

---Set the base of the zoom logarithm; will not change current scale/position
viewport.setZoomBase = function(self, b)
    self.zoomPower = exponent_solve(b, self:getScale())
    self.zoomBase = b
    self.scale = self.zoomBase ^ self.zoomPower
end

---Get the rate, in powers-per-second, of zooming in updates
viewport.getZoomRate = function(self)
    return self.zoomRate
end

---Set the rate, in powers-persecond, of zooming in updates
viewport.setZoomRate = function(self, r)
    self.zoomRate = r
end

---Queue a zoom in updates; unit given is delta from current zoom level;
-- can scale relative to center (default ULC)
--TODO: ? flag absolute instead of delta
viewport.zoom = function(self, delta, where)
    if where == 'center' then
        self.zoomCenter = true
    end
    self.zoomDelta = delta
end

---Create a new Viewport object
viewport.new = function(width, height)
    return {x         = 0,
            y         = 0,
            width     = width,
            height    = height,
            scale     = 1,
            panRate   = 1,
            zoomBase  = 2,
            zoomPower = 0,
            zoomRate  = 1,
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

