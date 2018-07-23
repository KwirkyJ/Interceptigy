-- testbed thing
-- intercept and manipulation of tracks

local approach  = require 'source.approachlist'
local entity    = require 'source.entity'
local misc      = require 'source.misclib'
local track     = require 'source.trackfactory'
local viewport  = require 'source.viewport'

-- set to `true` to perform crude profiling
local _PEPPER_PROFILE = false

if _PEPPER_PROFILE then
    require 'lib.pepperfish'
    profiler = newProfiler()
end -- profiling

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
if version[2] == 9 then
    lmb, rmb = 'l', 'r'
end -- love 0.9.x

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
    e.TMP_attack_range = math.random()*30 + 10
    e:setMaxAcceleration(5*math.random() + 1)
    return e
end

function love.load()
if _PEPPER_PROFILE then
    profiler:start()
end -- profiling

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
end -- love.load()

if _PEPPER_PROFILE then
function love.quit()
    profiler:stop()
    local outfile = io.open( "profile.txt", "w+" )
    profiler:report( outfile )
    outfile:close()
end -- love.quit()
end -- profiling

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
    local mx, my
    now = getTime() - starttime
    
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

        closest_e, closest_t, closest_d = updateClosestEntity(mx, my, es[i])
        
        for j=i+1, #es do
            local e1, e2 = es[i], es[j]
            local x1, y1 = e1:getRealTrack(now)
            local x2, y2 = e2:getRealTrack(now)
            local t, d = misc.findClosest(now, x1, y1, x2, y2)
            approach.insert(approaches, t, d^0.5, e1, e2)

            -- TODO: optimize to not rebuild approach list every loop
            -- instead, rebuild only on maneuver or entity modification
        end
    end
end -- love.update()

---signify important element, 
-- drop interaction node on track,
local function highlightCloseTrack(drop_node)
    lg.setColor(0xff, 0xff, 0xff)
    local x, y = camera:getScreenPoint(closest_e:getPosition(now))
    -- lg.circle('line', x, y, 10, 12) -- circle around entity
    lg.circle('line', x, y, closest_e.TMP_attack_range * camera:getScale(), 24) -- range circle
    if drop_node then
        x, y = camera:getScreenPoint(closest_e:getPosition(
                    math.max(now, closest_t)))
        lg.circle('fill', x, y, 3, 8) -- dot on track
    end
end -- highlightCloseTrack

--@param x    world x coordinates
--@param y    worly y coordinates
--@param rgba table
--TODO: @param r radius of attack range
local function drawApproachMarker(x, y, rgba)
    lg.setColor(rgba)
    x,y = camera:getScreenPoint(x, y)
    lg.circle('fill', x, y, 4, 8)
    lg.circle('line', x, y, 12, 16)
end -- drawApproachMarker

local function drawTrackCurve(fx, fy, start, stop)
    local x1, y1
    local duration = stop - start
    local segments = math.ceil(duration / TRACK_CURVE_SEGMENT_T)
    local x, y = camera:getScreenPoint(fx(stop), fy(stop))
    local t = stop
    for _=1, segments do
        t = t - TRACK_CURVE_SEGMENT_T
        if t < start then
            t = start
        end
        x1, y1 = camera:getScreenPoint(fx(t), fy(t))
        lg.line(x, y, x1, y1)
        x,y = x1, y1
    end
end

local function drawTrackReferenceDots(fx, fy, radius, interval, start, stop)
    radius   = radius   or 2
    interval = interval or TRACK_REFERENCE_INTERVAL 
    start    = start    or now
    stop     = stop     or start + TRACK_PROJECTION_DURATION

    -- find time of first reference point
    local t = math.ceil(start)
    while true do
        if t % interval == 0 then
            break
        end
        t = t + 1
    end

    -- draw points
    local x, y
    while t < stop do
        x,y = camera:getScreenPoint(fx(t), fy(t))
        lg.circle("fill", x, y, radius, radius * 4)
        t = t + interval
    end
end -- drawTrackReferenceDots

local function drawTrack2(fx, fy, drawstart, drawstop)
    drawstart = drawstart or now
    drawstop = drawstop or drawstart + TRACK_PROJECTION_DURATION

    local first_i = nil
    local segment_starts = fx:getStarts()
    for i=1, (#segment_starts-1) do
        if  (drawstart >= segment_starts[i])
        and (drawstart < segment_starts[i+1])
        then
            first_i = i
            break
        end
    end
    first_i = first_i or #segment_starts

    local t0, t1 = drawstart, nil
    for i=first_i, #segment_starts do
        t1 = segment_starts[i+1]
        if not t1 or t1 > drawstop then
            t1 = drawstop
        end
        if fx:getDegree(t0) > 1 then
            drawTrackCurve(fx, fy, t0, t1)
        else
            local x0, y0 = camera:getScreenPoint(fx(t0), fy(t0))
            local x1, y1 = camera:getScreenPoint(fx(t1), fy(t1))
            lg.line(x0, y0, x1, y1)
        end
        if t1 == drawstop then
            break
        else
            t0 = t1
        end
    end
end -- drawTrack2()

local function drawEntity(e)
    local fx, fy = e:getRealTrack(now)
    lg.setColor(e:getColor())
    drawTrack2(fx, fy)
    if TRACK_REFERENCE_INTERVAL > 0 then
        drawTrackReferenceDots(fx, fy)
    end
    local x, y = camera:getScreenPoint(e:getPosition(now))
    lg.circle('fill', x, y, 6, 8)
end

local function drawManip()
    local c = {0xff, 0xff, 0xff}
    if manip_err then 
        c[2], c[3] = 0, 0 
    end
    lg.setColor(c)
    drawTrack2(manip_x, manip_y)
    if TRACK_REFERENCE_INTERVAL > 0 then
        drawTrackReferenceDots(manip_x, manip_y)
    end
    local sx, sy = camera:getScreenPoint(
            manip_x(manip_t), 
            manip_y(manip_t))
    lg.circle('fill', sx, sy, 4, 8) -- reference of planned track
    sx, sy = camera:getScreenPoint(manip_e:getPosition(manip_t))
    lg.circle('fill', sx, sy, 4, 8) -- reference of current track

    local e, t
    for i=1, #es do
        e = es[i]
        if e ~= manip_e then
            t = misc.findClosest(
                    now,
                    manip_x,
                    manip_y,
                    e:getRealTrack(now))
            if t and t ~= now then
                local x,y = e:getPosition(t)
                drawApproachMarker(x, y, c)
                drawApproachMarker(manip_x(t), manip_y(t), e:getColor())
            end
        end
    end
end -- drawManip()

function love.draw()
    lg.setBackgroundColor(0, 0, 0)

    lg.setColor(255,255,255)
    if isCloseHot() then 
        if not manip_e then
            --draw time in engagement envelope
            for t,d,e1,e2 in approach.getApproaches(approaches, closest_e) do
                if e2 == closest_e then
                    e1,e2 = e2,e1
                end
                local fx1, fy1 = e1:getRealTrack(now)
                local fx2, fy2 = e2:getRealTrack(now)
                local fdx, fdy = fx1:subtract(fx2), fy1:subtract(fy2)
                local fd = fdx:square():add(fdy:square())
                local t0, t1
                if d <= e2.TMP_attack_range then
                    t0, t1 = misc.findTimeBoundingValue(
                            fd,
                            e2.TMP_attack_range^2,
                            t)
                    if t0 < now then
                        t0 = now
                    end
                    lg.setLineWidth(8)
                    lg.setColor(e2:getColor())
                    drawTrack2(fx1, fy1, t0, t1)
                end

                if d < e1.TMP_attack_range then
                    t0, t1 = misc.findTimeBoundingValue(
                            fd,
                            e1.TMP_attack_range^2,
                            t)
                    if t0 < now then
                        t0 = now
                    end
                    lg.setLineWidth(4)
                    lg.setColor(e1:getColor())
                    drawTrack2(fx1, fy1, t0, t1)
                end
                lg.setLineWidth(1)
            end
        end
        highlightCloseTrack(not manip_e) -- encircle element; drop 'handle' on track if not already manipulating something
    end

    for i=1, #es do 
        drawEntity(es[i]) --draw each element and its track
    end

    if manip_e then
        drawManip()
    end

end -- love.draw()

