-- testbed thing
-- intercept and manipulation of tracks

local approach  = require 'source.approachlist'
local entity    = require 'source.entity'
local misc      = require 'source.misclib'
local track     = require 'source.trackfactory'
local viewport  = require 'source.viewport'

local MOUSEDRAG_ZOOM_CONSTANT = 50
local WHEEL_ZOOM_CONSTANT = 10
local MAX_PIXELS_TO_INTERACT = 20

local NUMBER_OF_ENTITIES = 5

local TRACK_PROJECTION_DURATION = 180
local TRACK_CURVE_SEGMENT_T = 0.5
local TRACK_REFERENCE_INTERVAL = 10

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

local approaches

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
    if not colortable then
        local t = {0xff, math.random(0x100)-1, math.random(0x100)-1}
        colortable = {}
        for _=1, 3 do
            colortable[#colortable+1] = table.remove(t, math.random(#t))
        end
    end
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
    local mx, my --, ex, ey
    now = getTime() - starttime
    update_count = update_count + 1
--        print(now)
--        print(updatecount, now)
    
    approaches = {}

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
        
        for j=i+1, #es do
            local e1, e2 = es[i], es[j]
            local fx, fy = e1:getRealTrack(now)
            local tx, ty = e2:getRealTrack(now)
            local t, d = misc.findClosest(now, fx, fy, tx, ty)
            approach.insert(approaches, t, d, e1, e2)
        end
    end
end

local drawTrack2 -- forward definition of function mame

---signify important element, 
-- drop interaction node on track,
local function highlightCloseTrack(drop_node)
    lg.setColor(0xff, 0xff, 0xff)
    local x, y = camera:getScreenPoint(closest_e:getPosition(now))
    lg.circle('line', x, y, 10, 12) -- circle around entity
    if drop_node then
        x, y = camera:getScreenPoint(closest_e:getPosition(
                    math.max(now, closest_t)))
        lg.circle('fill', x, y, 3, 8) -- dot on track
    end
end

--@param x    world x coordinates
--@param y    worly y coordinates
--@param rgba table
--TODO: @param r radius of attack range
local function drawApproachMarker(x, y, rgba)
    lg.setColor(rgba)
    x,y = camera:getScreenPoint(x, y)
    lg.circle('fill', x, y, 4, 8)
    lg.circle('line', x, y, 12, 16)
end

local function drawTrackCurve(fx, fy, burnstop)
    local x1, y1
    local duration = burnstop - now
    local segments = math.ceil(duration / TRACK_CURVE_SEGMENT_T)
    local x, y = camera:getScreenPoint(fx(burnstop), fy(burnstop))
    local t = burnstop
    for _=1, segments do
        t = math.max(now, t-TRACK_CURVE_SEGMENT_T)
        x1, y1 = camera:getScreenPoint(fx(t), fy(t))
        lg.line(x,y, x1,y1)
        x,y = x1, y1
    end
end

local function getBurnstop(fn, minimum)
    local starts = fn:getStarts()
    if  #starts > 1
    and minimum < starts[2]
    then
        return starts[2]
    end
end

drawTrack2 = function(fx, fy, rgb, show_burnstop)
    local x, y, x1, y1
    lg.setColor(rgb)
    local drawstop = now + TRACK_PROJECTION_DURATION

    -- draw curve (under thrust/acceleration)
    local burnstop = getBurnstop(fx, now)
    if burnstop then
        if burnstop > drawstop then
            burnstop = drawstop
        end
        drawTrackCurve(fx, fy, burnstop)
        if show_burnstop then -- draw the burn-end
            x,y = camera:getScreenPoint(fx(burnstop), fy(burnstop))
            lg.circle('line', x, y, 6, 4)
        end
    else
        burnstop = now
    end

    -- draw coast
    if burnstop ~= drawstop then
        x,y = camera:getScreenPoint(fx(burnstop), fy(burnstop))
        x1, y1 = camera:getScreenPoint(fx(drawstop), fy(drawstop))
        lg.line(x,y, x1,y1)
    end

    -- draw "constant" reference points
    if TRACK_REFERENCE_INTERVAL > 0 then
        local t = math.ceil(now)
        while true do
            if t % TRACK_REFERENCE_INTERVAL == 0 then
                break
            end
            t = t + 1
        end
        while t < drawstop do
            x,y = camera:getScreenPoint(fx(t), fy(t))
            lg.circle("fill", x, y, 2, 12)
            t = t + TRACK_REFERENCE_INTERVAL
        end
    end
end

local function drawEntity(e)
    local x, y = e:getRealTrack(now)
    drawTrack2(x, y, e:getColor())
    x, y = camera:getScreenPoint(e:getPosition(now)) -- reuse variables; why not?
    lg.circle('fill', x, y, 6, 8)
end

--local function drawWorldBounds()
--    local x, y, dx, dy
--    lg.setColor(0xff, 0, 0)
--    x,y = camera:getScreenPoint(10, 10)
--    dx, dy = (winx-20)*camera:getScale(), (winy-20)*camera:getScale()
--    lg.rectangle('line', x, y, dx, dy)
--    x,y = camera:getScreenPoint(0, 0)
--    dx, dy = winx*camera:getScale(), winy*camera:getScale()
--    lg.rectangle('line', x, y, dx, dy)
--end

local function tryDrawManip()
    if not manip_e then return end
    
    local c = {0xff, 0xff, 0xff}
    if manip_err then 
        c[2], c[3] = 0, 0 
    end
    drawTrack2(manip_x, manip_y, c, true)
    local sx, sy = camera:getScreenPoint(manip_x(manip_t), 
                                         manip_y(manip_t))
    lg.setColor(c)
    lg.circle('fill', sx, sy, 4, 8) -- reference of planned track
    sx, sy = camera:getScreenPoint(manip_e:getPosition(manip_t))
    lg.circle('fill', sx, sy, 4, 8) -- reference of current track
    
    for _,e in ipairs(es) do
         -- if e ~= e_manip then
         if e ~= manip_e then
            local t = misc.findClosest(
                    now,
                    manip_x,
                    manip_y,
                    e:getRealTrack(now))
            if t then
                local x,y = e:getPosition(t)
                drawApproachMarker(x, y, c)
                drawApproachMarker(manip_x(t), manip_y(t), e:getColor())
            end
        end
    end
end

function love.draw()
    lg.setBackgroundColor(0, 0, 0)
    
    --drawWorldBounds()
    
    for i=1, #es do 
        drawEntity(es[i]) --draw each element and its track
    end
    
    if isCloseHot() then 
        if not manip_e then
            --draw standard approach markers
            local x, y
            for t,_,e1,e2 in approach.getApproaches(approaches, closest_e) do
                x,y = e1:getPosition(t)
                drawApproachMarker(x,y, e2:getColor())
                x,y = e2:getPosition(t)
                drawApproachMarker(x,y, e1:getColor())
            end
        end
        highlightCloseTrack(not manip_e) -- encircle element; drop 'handle' on track if not already manipulating something
    end
    
    tryDrawManip()
end

