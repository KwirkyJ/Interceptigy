-- testbed thing
-- intercept and manipulation of tracks

local piecewise = require 'source.piecewise_poly'

local lg      = love.graphics
local lk      = love.keyboard
local lm      = love.mouse
local random  = love.math.random
local getTime = love.timer.getTime

local es
local winx, winy
local starttime, time_elapsed

local function element_get_position(self, t)
    assert(type(t) == 'number')
    return self[1](t), self[2](t)
end

local function new_element(colortable)
    local startx, starty, vx, vy, fx, fy
    startx, starty = random(winx), random(winy)
    vx, vy = random(100), random(100)
    if random() > 0.5 then vx = -vx end
    if random() > 0.5 then vy = -vy end
    fx, fy = piecewise.Polynomial(), piecewise.Polynomial()
    fx:add(time_elapsed, {vx, startx - vx*time_elapsed})
    fy:add(time_elapsed, {vy, starty - vy*time_elapsed})
    return {fx,
            fy,
            colortable or {random(0xff), random(0xff), random(0xff)},
            ['getPosition'] = element_get_position,
           }
end

function love.load()
    starttime = getTime()
    time_elapsed = 0
    winx, winy = lg.getDimensions()
    love.math.setRandomSeed(getTime())
    es = {new_element(), new_element()}
end

function love.update(dt)
    time_elapsed = getTime() - starttime
    if lk.isDown('escape') then love.event.push('quit') end
    if lk.isDown('space') or lk.isDown(' ') then -- backwards-compatibility
        es = {new_element(), new_element()}
    end
    for i=1, #es do
        local ex, ey = es[i]:getPosition(time_elapsed)
        if 0 > ex or ex > winx or 0 > ey or ey > winy then
            es[i] = new_element()
        end
    end
end

function love.draw()
    lg.setBackgroundColor(0, 0, 0)
    local x, y, dx, dy
    for _,e in ipairs(es) do
        x, y = e:getPosition(time_elapsed)
        dx, dy = e:getPosition(time_elapsed+1000)
        lg.setColor(e[3])
        lg.line(x, y, dx, dy)
        lg.circle('fill', x, y, 6, 8)
        -- TODO: translate points through 'camera'
        -- TODO: scale predicted nodes interval about 'camera zoom'
        local firstreftime = math.ceil(time_elapsed) 
        local t, count = firstreftime, 0
        --firstreftime = firstreftime + (10 - (firstreftime % 10))
        while true do
            x,y = e:getPosition(t)
            if x < 0 or x > winx 
            or y < 0 or y > winy 
            or count > 100 
            then break end
            t, count = t + 1, count + 1
            lg.circle('line', x, y, 3, 8)
        end
    end
end

