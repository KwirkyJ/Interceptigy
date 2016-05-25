-- testbed thing
-- intercept and manipulation of tracks

local piecewise = require 'source.piecewise_poly'
local viewport  = require 'source.viewport'

local MOUSEDRAG_ZOOM_CONSTANT = 50
local WHEEL_ZOOM_CONSTANT = 10

local lg      = love.graphics
local lk      = love.keyboard
local lm      = love.mouse
local random  = love.math.random
local getTime = love.timer.getTime

local es
local winx, winy
local starttime, time_elapsed
local camera

local version = {love.getVersion()}
local lmb, rmb = 1, 2
if version[2] == 9 then lmb, rmb = 'l', 'r' end
local element_being_manipulated -- {element, t}
local element_closest -- {element, t, distance}
local element_idstore = 0
local movingCamera = "none" -- "drag", "zoom"

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
    fx = piecewise.Polynomial({time_elapsed, vx, startx - vx*time_elapsed})
    fy = piecewise.Polynomial({time_elapsed, vy, starty - vy*time_elapsed})
    element_idstore = element_idstore + 1
    return {[1] = fx,
            [2] = fy,
            [3] = colortable or {random(0xff), random(0xff), random(0xff)},
            ['id'] = element_idstore,
            ['getPosition'] = element_get_position,
           }
end

local function find_closest_path(fx, fy)
    element_closest = {}
    local dx, dy, t, fd, d
    for i, e in ipairs(es) do
        dx, dy = fx:subtract(e[1]), fy:subtract(e[2])--TODO: e:getPositionFunctions()
        fd = piecewise.add(dx:square(), dy:square()):getDerivative()
        t = time_elapsed
        for _, r in ipairs(fd:getRoots(0)) do
            if r > t then t = r; break end
        end
        d = dx(t)^2 + dy(t)^2--fd(t)
        if not element_closest[1] 
        or d < element_closest[3]
        then element_closest = {e, t, d}
        end
    end
    element_closest[3] = element_closest[3] ^ 0.5
end

function love.load()
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
    if movingCamera == 'drag' then
        local scale = camera:getScale()
        camera:setPosition(-dx / scale, -dy / scale, true)
    elseif movingCamera == 'zoom' then
        local zl = camera:getZoom()
        camera:setZoom(zl - dy / MOUSEDRAG_ZOOM_CONSTANT, 'center')
    else -- no camera manip
        local wx, wy = camera:getWorldPoint(x, y)
        find_closest_path(piecewise.Polynomial({time_elapsed, wx}),
                          piecewise.Polynomial({time_elapsed, wy}))
    end
end

function love.mousepressed(x, y, button)
    if button == rmb then
        movingCamera = 'drag'
    elseif button == lmb then
        if movingCamera == 'drag' then
            movingCamera = 'zoom'
        end
    end
end

function love.mousereleased(x, y, button)
    if button == rmb then
        movingCamera = 'none'
    elseif button == lmb then
        if movingCamera == 'zoom' then
            movingCamera = 'drag'
        end
    end
end

if version[2] > 9 then
  function love.wheelmoved(x, y)
      --if x > 0 then print('wheel x > 0')
      --elseif x < 0 then print('wheel x < 0')
      --end
      if y ~= 0 then
          camera:setZoom(camera:getZoom() + y / WHEEL_ZOOM_CONSTANT, 'center')
      end
  end
end

function love.update(dt)
    time_elapsed = getTime() - starttime
    for i=1, #es do
        local ex, ey = es[i]:getPosition(time_elapsed)
        if 0 > ex or ex > winx or 0 > ey or ey > winy then
            es[i] = new_element()
        else es[i][1]:clearBefore(time_elapsed)
             es[i][2]:clearBefore(time_elapsed)
        end
    end
end

function love.draw()
    lg.setBackgroundColor(0, 0, 0)
    lg.setColor(0xff, 0, 0)
    local x, y, dx, dy
    x,y = camera:getScreenPoint(10, 10)
    dx, dy = (winx-20)*camera:getScale(), (winy-20)*camera:getScale()
    lg.rectangle('line', x, y, dx, dy)
    x,y = camera:getScreenPoint(0, 0)
    dx, dy = winx*camera:getScale(), winy*camera:getScale()
    lg.rectangle('line', x, y, dx, dy)
    for _,e in ipairs(es) do
         x,  y = camera:getScreenPoint(e:getPosition(time_elapsed))
        dx, dy = camera:getScreenPoint(e:getPosition(time_elapsed+1000))
        lg.setColor(e[3])
        lg.line(x, y, dx, dy)
        lg.circle('fill', x, y, 6, 8)
        
        -- draw 'reference points' along track at equal time intervals
        -- TODO: scale predicted nodes interval about 'camera zoom'
        local t = math.ceil(time_elapsed)
        for count = 1, 1000 do
            x,y = e:getPosition(t)
            x,y = camera:getScreenPoint(x,y)
            if  x >= 0 and x <= winx 
            and y >= 0 and y <= winy 
            then
                lg.circle('line', x, y, 3, 8)
            end
            t = t + 1
        end
    end

    --draw path highlight of point closest to cursor
    if not element_closest 
    or element_closest[3] * camera:getScale() > 20 
    then 
        return 
    end
    lg.setColor(0xff, 0xff, 0xff)
    local special_e, special_t = element_closest[1], element_closest[2]
    x, y = special_e:getPosition(special_t)
    if x and y then
        x, y = camera:getScreenPoint(x, y)
        lg.circle('fill', x, y, 3, 8)
    end
    --x, y = lm.getPosition()
    --lg.circle('fill', x, y, 3, 8)
end

