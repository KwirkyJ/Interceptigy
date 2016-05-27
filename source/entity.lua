local piecewise_poly = require 'source.piecewise_poly'

local entity = {}

local idstore = 0

---get the ID assigned to the last entity created
-- useful for debugging
entity.get_prev_id = function()
    return idstore
end

--- get the position of an entity at time t
entity.getPosition = function(e, t)
    return e[1](t), e[2](t)
end

---create a new entity object
-- entity.new(now, px, py, vx, vy, color)
-- entity.new(now, random) -- creates a random entity
-- @param now    current time (as interpreted by program)
-- @param px     X-position
-- @param py     Y-position
-- @param vx     X-velocity
-- @param vy     Y-velocity
-- @param color  table of three color values (RGB, each 0..255)
-- @param random random function (e.g., math.random)
-- @raturn Entity.
entity.new = function(now, px, py, vx, vy, color)
    if type(px) == 'function' then
        local rand = px
        px = rand()
        py = rand()
        vx = rand()
        vy = rand()
        color = {rand(255), rand(255), rand(255)}
    end
    idstore = idstore + 1
    return {[1] = piecewise_poly.Polynomial({now, vx, px - vx*now}),
            [2] = piecewise_poly.Polynomial({now, vy, py - vy*now}),
            [3] = color,
            ['id'] = idstore,
            ['getPosition'] = entity.getPosition,
           }
end

return entity

