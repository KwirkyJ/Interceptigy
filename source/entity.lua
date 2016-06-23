local piecewise    = require 'source.piecewise_poly'
local trackfactory = require 'source.trackfactory'

local unpack = unpack or table.unpack

local idstore = 0

local entity = {}

---get the position of an entity at time t
-- @param E Entity instance
-- @param t time (number)
-- @return x, y (numbers)
entity.getPosition = function(E, t)
    if type(t) ~= 'number' then
        error('time index must be a number')
    end
    return E[1](t), E[2](t)
end

---get the time of interaction for entity's track, if any
-- @param E Entity instance
-- @return number or nil
entity.getTInt = function(E)
    return E.t_interact
end

---set/reset interaction time for the entity
-- @param E Entity instance
-- @param t time (number)
entity.setTInt = function(E, t)
    E.t_interact = t
end

---get a copy of the entity's color table
-- @param E Entity instance
-- @return table {number, number, number}
entity.getColor = function(E)
    return {E[3][1], E[3][2], E[3][3]}
end

---set the polynomials for the x and y position through time
-- @param E  Entity instance
-- @param fx Piecewise Polynomial instance
-- @param fy Piecewise Polynomial instance
entity.setTrack = function(E, fx, fy)
--    assert(E._isEntity)
--    assert(fx._isPolynomial)
--    assert(fy._isPolynomial)
    E[1], E[2] = fx, fy
end

---get the polynomials for this entity's position 
-- starting at first piece spanning given time
-- @param E Entity instance
-- @param t time
-- @error t less than Entity's first position time
-- @return fx, fy (Piecewise Polynomial instances)
entity.getRealTrack = function(E, t)
    local starts, x, y = E[1]:getStarts()
    assert(E:getPosition(t), 'entity has no position at given time')
    x,y = piecewise.Polynomial(), piecewise.Polynomial()
    for i, s1 in ipairs(starts) do
        local s2 = starts[i+1]
        if not s2 or t <= s2 then
            x:insert(E[1]:getPiece(s1))
            y:insert(E[2]:getPiece(s1))
        end
    end
    return x, y
end

---get the polynomials for the entity's estimated position
-- @param E Entity instance
-- @param t time
-- @param q quality of projection; String 'tangent' or 'extrapolate'
--          (default 'tangent')
-- @error type(t) not 'number'
-- @error t less than Entity's first position time
-- @error type(q) not 'string' nor 'nil'
-- @return tx, ty (Piecewise Polynomial instances)
entity.getProjectedTrack = function(E, t, q)
    assert(type(t) == 'number', 'given time must be number')
    assert(E:getPosition(t), 'entity has no position at given time')
    q = q or 'tangent'
    assert(type(q) == 'string', 'qualifier must be a string or nil')
    if q ~= 'tangent' then
        if E[1](t) then
            return piecewise.Polynomial({t, E[1]:getCoefficients(t)}),
                   piecewise.Polynomial({t, E[2]:getCoefficients(t)})
        else
            error("you have a bad problem")
        end
    else
        return trackfactory.tangent(t, E[1]), 
               trackfactory.tangent(t, E[2])
    end
end

---create a new Entity instance
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
            getColor          = entity.getColor,
            getPosition       = entity.getPosition,
            getProjectedTrack = entity.getProjectedTrack,
            getRealTrack      = entity.getRealTrack,
            getTInt           = entity.getTInt,
            setTInt           = entity.setTInt,
            setTrack          = entity.setTrack,
           }
end

return entity

