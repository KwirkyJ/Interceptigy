-- testbed thing
-- intercept and manipulation of tracks

local entity    = require 'source.entity'
local piecewise = require 'source.piecewise_poly'
local viewport  = require 'source.viewport'

local MOUSEDRAG_ZOOM_CONSTANT = 50
local WHEEL_ZOOM_CONSTANT = 10
local MAX_PIXELS_TO_INTERACT = 20

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

local element_being_manipulated -- element-entity
local element_closest -- {element, t, distance}
local mouseState = "idle" --idle, drag, zoom, manip, manip-drag

local function new_element(colortable) 
    local px, py = random(winx), random(winy)
    local vx, vy = random(100), random(100)
    if px > winx/2 then vx = -vx end
    if py > winy/2 then vy = -vy end
    colortable = colortable or {random(0xff), random(0xff), random(0xff)}
    return entity.new(time_elapsed, px, py, vx, vy, colortable)
end

---find time and distance of closest approach between two 2d functions
local function calc_closest(f1x, f1y, f2x, f2y)
    local dx, dy, t, fd, d
    dx, dy = f1x:subtract(f2x), f1y:subtract(f2y)
    fd = piecewise.add(dx:square(), dy:square()):getDerivative()
    t = time_elapsed
    for _,r in ipairs(fd:getRoots(0)) do
        if r > t then t=r; break end
    end
    d = dx(t)^2 + dy(t)^2
    return t, d
end

---find the entity closest to (or track closest to) the current screen point
-- and store it, time, and distance in element_closest table
local function populate_closest_entity(x, y)
    element_closest = nil
    local wx, wy = camera:getWorldPoint(x, y)
    local x = piecewise.Polynomial({time_elapsed, wx}) -- mouse thu time
    local y = piecewise.Polynomial({time_elapsed, wy})
    
    local t_best, d_best, e_best = time_elapsed, math.huge, nil
    for _,e in ipairs(es) do
        local t, d = calc_closest(x,y, e[1], e[2])
        if d < d_best then
            t_best, d_best, e_best = t, d, e
        end
    end
    if e_best then
        element_closest = {e_best, t_best, d_best^0.5}
    end
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
    if mouseState == 'drag' or mouseState == 'manip-drag' then
        local scale = camera:getScale()
        camera:setPosition(-dx / scale, -dy / scale, true)
    elseif mouseState == 'zoom' then
        local zl  = camera:getZoom()
        local x,y = camera:getWorldPoint(lm.getPosition())
        camera:setZoom(zl - dy / MOUSEDRAG_ZOOM_CONSTANT)
        camera:matchPointsScreenWorld(lm.getX(), lm.getY(), x, y)
    else -- idle
        populate_closest_entity(x, y)
    end
    if mouseState == 'manip' 
    or mouseState == 'manip-drag' 
    and entity_being_manipulated then
        -- manipulate entity
    end
end

function love.mousepressed(x, y, button)
    if button == rmb then
        if mouseState == 'idle' then
            mouseState = 'drag'
        elseif mouseState == 'manip' then
            mouseState = 'manip-drag'
        end
    elseif button == lmb then
        if mouseState == 'drag' then
            mouseState = 'zoom'
        else
            mouseState = 'manip'
            local e, t, d = element_closest[1], 
                            element_closest[2], 
                            element_closest[3]
            if d * camera:getScale() <= MAX_PIXELS_TO_INTERACT
            then
                e:setTInt(t)
                element_being_manipulated = {e, t}
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == rmb then
        if mouseState == 'drag' then
            mouseState = 'idle'
        elseif mouseState == 'zoom' or mouseState == 'manip-drag' then
            mouseState = 'manip'
        end
    elseif button == lmb then
        if mouseState == 'manip' then
            mouseState = 'idle'
            -- make element change course
            if element_being_manipulated then
                element_being_manipulated[1]:setTInt(nil)
                element_being_manipulated = nil
            end
        elseif mouseState == 'manip-drag' then
            mouseState = 'drag'
            -- make element change course
            element_being_manipulated[1]:setTInt(nil)
            element_being_manipulated = nil
        elseif mouseState == 'zoom' then
            mouseState = 'drag'
        end
    end
end

if version[2] > 9 then
    function love.wheelmoved(x, y)
        if y ~= 0 then
            local x,y = camera:getWorldPoint(lm.getPosition())
            camera:setZoom(camera:getZoom() + y / WHEEL_ZOOM_CONSTANT)
            camera:matchPointsScreenWorld(lm.getX(), lm.getY(), x, y)
        end
    end
end

function love.update(dt)
    time_elapsed = getTime() - starttime
    for i=1, #es do
        --local t_manip = es[i]:getTInt()
        --if t_manip and t_manip < time_elapsed then
        --    es[i]:setTInt(nil)
        --    element_being_manipulated = nil
        --end
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
    local x, y, dx, dy
    
    -- draw the 'world bounds'
    lg.setColor(0xff, 0, 0)
    x,y = camera:getScreenPoint(10, 10)
    dx, dy = (winx-20)*camera:getScale(), (winy-20)*camera:getScale()
    lg.rectangle('line', x, y, dx, dy)
    x,y = camera:getScreenPoint(0, 0)
    dx, dy = winx*camera:getScale(), winy*camera:getScale()
    lg.rectangle('line', x, y, dx, dy)
    
    --draw each element and its track
    for _,e in ipairs(es) do
         x,  y = camera:getScreenPoint(e:getPosition(time_elapsed))
        dx, dy = camera:getScreenPoint(e:getPosition(time_elapsed+1000))
        lg.setColor(e[3])
        lg.line(x, y, dx, dy)
        if e:getTInt() then
            lg.setColor(255-e[3][1], 255-e[3][2], 255-e[3][3])
            lg.circle('fill', x, y, 6, 8)
            lg.setColor(e[3])
        else
            lg.circle('fill', x, y, 6, 8)
        end
        
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
    
    lg.setColor(0xff, 0xff, 0xff)
    --if element_being_manipulated then
    --    lg.print("manipulating object: "..element_being_manipulated[1].id)
    --end

    --draw path highlight of point closest to cursor
    if element_closest
    and element_closest[3] * camera:getScale() <= MAX_PIXELS_TO_INTERACT
    then
        local special_e, special_t = element_closest[1], element_closest[2]
        x, y = special_e:getPosition(special_t)
        if x and y then
            x, y = camera:getScreenPoint(x, y)
            lg.circle('fill', x, y, 3, 8)
        end
    end
    --x, y = lm.getPosition()
    --lg.circle('fill', x, y, 3, 8)
end

