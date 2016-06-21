local piecewise    = require 'source.piecewise_poly'
local trackfactory = require 'source.trackfactory'

local idstore = 0

local entity = {}

---get the position of an entity at time t
-- @param e Entity instance
-- @param t time (number)
-- @return x, y (numbers)
entity.getPosition = function(e, t)
    if type(t) ~= 'number' then
        error('time index must be a number')
    end
    return e[1](t), e[2](t)
end

---get the time of interaction for entity's track, if any
-- @param e Entity instance
-- @return number or nil
entity.getTInt = function(e)
    return e.t_interact
end

---set/reset interaction time for the entity
-- @param e Entity instance
-- @param t time (number)
entity.setTInt = function(e, t)
    e.t_interact = t
end

---get a copy of the entity's color table
-- @param e Entity instance
-- @return table {number, number, number}
entity.getColor = function(e)
    return {e[3][1], e[3][2], e[3][3]}
end

---set the polynomials for the x and y position through time
-- @param E  Entity instance
-- @param fx Piecewise Polynomial instance
-- @param fy Piecewise Polynomial instance
entity.setTrack = function(E, fx, fy)
    assert(E._isEntity)
    assert(fx._isPolynomial)
    assert(fy._isPolynomial)
    E[1], E[2] = fx, fy
end

---get the polynomials for this entity's position 
-- starting at first piece spanning given time
-- @param E Entity instance
-- @param t time
-- @return fx, fy (Piecewise Polynomial instances)
entity.getRealTrack = function(E, t)
    local starts, x, y = E[1]:getStarts()
    assert(t >= starts[1], 'entity has no position at given time')
    x,y = E[1]:clone(), E[2]:clone()
    while x[2] and t > x[2][1] do
        table.remove(x, 1)
        table.remove(y, 1)
    end
    return x, y
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
-- @return Entity instance
entity.new = function(now, px, py, vx, vy, color)
    if type(px) == 'function' then -- assume is a random number generator
        local rand = px
        px = rand()
        py = rand()
        vx = rand()
        vy = rand()
        color = {rand(255), rand(255), rand(255)}
    end
    idstore = idstore + 1
    return {_isEntity = true,
            [1] = trackfactory.new(now, px, vx),
            [2] = trackfactory.new(now, py, vy),
            [3] = color,
            t_interact = nil,
            id = idstore,
            getColor     = entity.getColor,
            getPosition  = entity.getPosition,
            getRealTrack = entity.getRealTrack,
            getTInt      = entity.getTInt,
            setTInt      = entity.setTInt,
            setTrack     = entity.setTrack,
           }
end

return entity

