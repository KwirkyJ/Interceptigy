-- testbed thing
-- intercept and manipulation of tracks

local piecewise = require 'source.piecewise_poly'
local viewport  = require 'source.viewport'

local MOUSEDRAG_ZOOM_CONSTANT = 50

local lg      = love.graphics
local lk      = love.keyboard
local lm      = love.mouse
local random  = love.math.random
local getTime = love.timer.getTime

local es
local winx, winy
local starttime, time_elapsed
local camera
local version

local function element_get_position(self, t)
    assert(type(t) == 'number')
    return self[1](t), self[2](t)
end

local function new_element(colortable)
    local startx, starty, vx, vy, fx, fy
    startx, starty = random(winx), random(winy)
    vx, vy = random(100), random(100)
    --if random() > 0.5 then vx = -vx end
    --if random() > 0.5 then vy = -vy end
    if startx > winx/2 then vx = -vx end
    if starty > winy/2 then vy = -vy end
    fx, fy = piecewise.Polynomial(), piecewise.Polynomial()
    fx:add(time_elapsed, {vx, startx - vx*time_elapsed})
    fy:add(time_elapsed, {vy, starty - vy*time_elapsed})
    return {[1] = fx,
            [2] = fy,
            [3] = colortable or {random(0xff), random(0xff), random(0xff)},
            ['getPosition'] = element_get_position,
           }
end

function love.load()
    local j, n, r, c = love.getVersion()
    version = {major = j, minor = n, revision = r, codename = c}
    starttime = getTime()
    time_elapsed = 0
    winx, winy = lg.getDimensions()
    love.math.setRandomSeed(getTime())
    es = {new_element(), new_element()}
    camera = viewport.new(winx, winy)
    camera:setPanRate(100)
    camera:setZoomRate(2)
end

function love.keypressed(key)
    if key == 'escape' then love.event.push('quit') end
   
    if key == ' ' or key == 'space' then -- backwards-compatibility
        es = {new_element(), new_element()}
        camera:setScale(1)
        camera:setPosition(0, 0)
    end
end

function love.mousemoved(x, y, dx, dy)
    --if version.minor == 9 then
    if lm.isDown('r') or lm.isDown(2) then -- TODO: check 0.9/0.10 compatability?
        if lm.isDown('l') or lm.isDown(1) then
            local zl = camera:getZoom()
            camera:setZoom(zl - dy / MOUSEDRAG_ZOOM_CONSTANT, 'center')
        else
            local x, y = camera:getPosition()
            local scale = camera:getScale()
            camera:setPosition(-dx / scale, -dy / scale, true)
        end
    end
    -- lm.isDown(1) -? left-click?
    -- lm.isDown(2) -> right-click?
end

function love.update(dt)
    time_elapsed = getTime() - starttime
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
        --x, y = e:getPosition(time_elapsed)
        --dx, dy = e:getPosition(time_elapsed+1000)
         x,  y = camera:getScreenPoint(e:getPosition(time_elapsed))
        dx, dy = camera:getScreenPoint(e:getPosition(time_elapsed+1000))
        lg.setColor(e[3])
        lg.line(x, y, dx, dy)
        lg.circle('fill', x, y, 6, 8)
        -- TODO: scale predicted nodes interval about 'camera zoom'
        local firstreftime = math.ceil(time_elapsed) 
        local t, count = firstreftime, 0
        --firstreftime = firstreftime + (10 - (firstreftime % 10))
        while true do
            if count > 1000 then break end
            x,y = e:getPosition(t)
            x,y = camera:getScreenPoint(x,y)
            if  x >= 0 and x <= winx 
            and y >= 0 and y <= winy 
            then
                lg.circle('line', x, y, 3, 8)
            end
            t, count = t+1, count+1
        end
    end
end

