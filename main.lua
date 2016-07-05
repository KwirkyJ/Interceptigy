-- testbed thing
-- intercept and manipulation of tracks

local entity    = require 'source.entity'
local misc      = require 'source.misclib'
local track     = require 'source.trackfactory'
local viewport  = require 'source.viewport'

local MOUSEDRAG_ZOOM_CONSTANT = 50
local WHEEL_ZOOM_CONSTANT = 10
local MAX_PIXELS_TO_INTERACT = 20

local NUMBER_OF_ENTITIES = 5

local lg      = love.graphics
local lm      = love.mouse
local random  = love.math.random
local getTime = love.timer.getTime

local es
local winx, winy
local starttime, now
local camera

local version = {love.getVersion()}
local lmb, rmb = 1, 2
if version[2] == 9 then lmb, rmb = 'l', 'r' end

local update_count = 0

local closest_e
local closest_t
local closest_d
local mouseState = "idle" --idle, drag, zoom, manip, manip-drag
local manip_e -- entity
local manip_t -- timestamp of manipulation point
local manip_x, manip_y -- projected track
local manip_err

---Flag manipulation of the closest element/entity, if applicable
local function initManip()
    manip_e = closest_e
    manip_t = closest_t
end

---Conclude element/entity manipulation
local function demanip(abort)
    if not manip_e then return end
    if not abort then
        manip_e:setTrack(manip_x, manip_y)
    end
    manip_e, manip_x, manip_y, manip_t, manip_err = nil, nil, nil, nil, nil
end

---Whether or not e_closest is 'within hot range'
local function isCloseHot()
    return closest_e and (closest_d*camera:getScale() <= MAX_PIXELS_TO_INTERACT)
end

local function newElement(colortable) 
    local px, py = random(winx), random(winy)
    local vx, vy = random(30), random(30)
    if px > winx/2 then vx = -vx end
    if py > winy/2 then vy = -vy end
    colortable = colortable or {random(0xff), random(0xff), random(0xff)}
    --return entity.new(now, px, py, vx, vy, colortable)
    local e = entity.new(now, px, py, vx, vy, colortable)
    e:setMaxAcceleration(3)
    return e
end

function love.load()
    starttime = getTime()
    now = 0
    winx, winy = lg.getDimensions()
    love.math.setRandomSeed(getTime())
    es = {}
    for i=1, NUMBER_OF_ENTITIES do
        es[i] = newElement()
    end
    camera = viewport.new(winx, winy)
    camera:setPanRate(100)
    camera:setZoomRate(2)
end

function love.keypressed(key)
    if key == 'escape' then 
        if manip_e then 
            demanip('abort')
        else
            love.event.push('quit')
        end
    end
   
    if key == ' ' or key == 'space' then -- backwards-compatibility
        for i=1, NUMBER_OF_ENTITIES do
            es[i] = newElement()
        end
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
        local wx,wy = camera:getWorldPoint(lm.getPosition())
        camera:setZoom(zl - dy / MOUSEDRAG_ZOOM_CONSTANT)
        camera:matchPointsScreenWorld(lm.getX(), lm.getY(), wx, wy)
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
            if isCloseHot() then initManip() end
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
            demanip() -- make element change course
        elseif mouseState == 'manip-drag' then
            mouseState = 'drag'
            demanip() -- make element change course
        elseif mouseState == 'zoom' then
            mouseState = 'drag'
        end
    end
end

if version[2] > 9 then
    function love.wheelmoved(x, y)
        if y ~= 0 then
            local wx,wy = camera:getWorldPoint(lm.getPosition())
            camera:setZoom(camera:getZoom() + y / WHEEL_ZOOM_CONSTANT)
            camera:matchPointsScreenWorld(lm.getX(), lm.getY(), wx, wy)
        end
    end
end

local function updateClosestEntity(mx, my, e)
    local t, d = misc.findClosest(now, mx, my, e:getRealTrack(now))
    if t then
        if (not closest_d) or (d < closest_d^2) then return e, t, d^0.5 end
    else
        local ex, ey = e:getPosition(now)
        d = ((mx(now) - ex)^2 + (my(now) - ey)^2)^0.5
        if d*camera:getScale() <= MAX_PIXELS_TO_INTERACT
        and (not closest_d or d < closest_d)
        then 
            return e, now, d
        end
    end
    return closest_e, closest_t, closest_d
end

---get x- and y-tracks going from current entity situation to (tx, ty) at time tt
local function getManipulatedTrack(e, tx, ty, tt)
    return track.adjustment(e, now, tx, ty, tt)
end

function love.update(dt)
    local mx, my, ex, ey
    now = getTime() - starttime
    update_count = update_count + 1
--        print(now)
--        print(updatecount, now)
    
    closest_e, closest_t, closest_d = nil, nil, nil
    mx, my = track.newParametric(now, camera:getWorldPoint(lm:getPosition()))
    
    for i=1, #es do
        if manip_e and es[i].id == manip_e.id then
            if manip_t <= now then 
                demanip('abort')
            else
                local tx, ty = camera:getWorldPoint(lm.getPosition())
                manip_x, manip_y, manip_err = getManipulatedTrack(es[i], tx, ty, manip_t)
            end
        end

--        ex, ey = es[i]:getPosition(now)
        closest_e, closest_t, closest_d = updateClosestEntity(mx, my, es[i])
    end
end

local function drawTrack(fx, fy, rgb)
    local x, y, x1, y1, t
    lg.setColor(rgb)
    x, y = camera:getScreenPoint(fx(now), fy(now))
    local starts = fx:getStarts()
    if #starts > 1 and now < starts[2] then
        local burnstop = starts[2]
        for i=1, 20 do
            t = i/20 * (burnstop-now) + now
            x1, y1 = camera:getScreenPoint(fx(t), fy(t))
            lg.line(x,y, x1, y1)
            x,y = x1, y1
        end
        -- draw the burn-end
        x,y = camera:getScreenPoint(fx(burnstop), fy(burnstop))
        lg.circle('line', x,y, 6, 4)
    end
    x1, y1 = camera:getScreenPoint(fx(now+1000), fy(now+1000))
    lg.line(x,y, x1, y1)
    --t = math.ceil(now)
    --for count = 1, 1000 do
    --    -- draw reference points
    --    x, y = camera:getScreenPoint(fx(t), fy(t))
    --    if  x >= 0 and x <= winx 
    --    and y >= 0 and y <= winy 
    --    then
    --        lg.circle('line', x, y, 3, 8)
    --    end
    --    t = t+1
    --end
end

---signify important element, 
-- drop interaction node on track, 
-- and draw 'intercepts'
local function highlightCloseTrack()
    local t = math.max(now, closest_t)
    x, y = camera:getScreenPoint(closest_e:getPosition(t))
    lg.circle('fill', x, y, 3, 8) -- dot on track
    x, y = camera:getScreenPoint(closest_e:getPosition(now))
    lg.circle('line', x, y, 10, 12) -- circle around entity
end

local function drawInterceptPair(t, fx, fy, fc, tx, ty, tc, highlight)
    --TODO: scale circle size with 'weapons range'?
    local x, y
    lg.setColor(tc)
    x,y = camera:getScreenPoint(tx(t), ty(t))
    lg.circle('fill', x, y, 4, 8)
    lg.circle('line', x, y, 12, 16)
    lg.setColor(fc)
    x,y = camera:getScreenPoint(fx(t), fy(t))
    lg.circle('fill', x, y, 4, 8)
    lg.circle('line', x, y, 12, 16)
end

local function drawIntercepts(e)
    local fx, fy = e:getRealTrack(now)
    for _,target in ipairs(es) do
      if entity ~= target then 
        --TODO: projected track of 'other's', real tracks of 'own'
        --local tx, ty = target:getProjectedTrack(now)
        local tx, ty = target:getProjectedTrack(now, 'tangent')
        local t = misc.findClosest(now, fx, fy, tx, ty)
        if t and t ~= now then
            --TODO: highlight if mouse is close to one of these
            local highlight = false
            drawInterceptPair(t, fx, fy, e:getColor(),
                                 tx, ty, target:getColor(), highlight)
        end
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
        drawTrack(e[1], e[2], e[3])
        if e:getTInt() then
            lg.setColor(0xff, 0xff, 0xff)
        end
        local sx, sy = camera:getScreenPoint(e:getPosition(now))
        lg.circle('fill', sx, sy, 6, 8)
    end
    
    lg.setColor(0xff, 0xff, 0xff)
    
    if isCloseHot() then 
        highlightCloseTrack() 
        drawIntercepts(closest_e)
    end
    if manip_e then
        local c = {0xff, 0xff, 0xff}
        if manip_err then 
            c[2], c[3] = 0, 0 
        end
        lg.setColor(c)
        local mx, my = manip_x(manip_t), manip_y(manip_t)
        lg.print(manip_t, 10, 10)
        lg.print(mx, 10, 20)
        lg.print(my, 10, 30)
        drawTrack(manip_x, manip_y, c) 
        local sx, sy = camera:getScreenPoint(mx, my)
        lg.circle('line', sx, sy, 9, 8)
        sx, sy = camera:getScreenPoint(manip_e:getPosition(manip_t))
        lg.circle('fill', sx, sy, 4, 8)
    end
end

