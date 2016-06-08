-- testbed thing
-- intercept and manipulation of tracks

local entity    = require 'source.entity'
local misc      = require 'source.misclib'
local piecewise = require 'source.piecewise_poly'
local track     = require 'source.trackfactory'
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
local starttime, now
local camera

local version = {love.getVersion()}
local lmb, rmb = 1, 2
if version[2] == 9 then lmb, rmb = 'l', 'r' end

local e_manip -- element-entity
local e_close -- {element, t, distance}
local mouseState = "idle" --idle, drag, zoom, manip, manip-drag
local manip_path -- {fx, fy}
local manip_ref -- {x, y, t}

---Flag manipulation of the closest element/entity, if applicable
local function initManip()
    local e, t = e_close[1], e_close[2]
    e:setTInt(t)
    e_manip = e
end

---Conclude element/entity manipulation
local function demanip(abort)
    if not e_manip then return end
    e_manip:setTInt(nil)
    --if not abort then
    --end
    e_manip = nil
end

---Whether or not e_closest is 'within hot range'
local function isCloseHot()
    return (e_close ~= nil) and (e_close[3]*camera:getScale() <= MAX_PIXELS_TO_INTERACT)
end

local function newElement(colortable) 
    local px, py = random(winx), random(winy)
    local vx, vy = random(30), random(30)
    if px > winx/2 then vx = -vx end
    if py > winy/2 then vy = -vy end
    colortable = colortable or {random(0xff), random(0xff), random(0xff)}
    return entity.new(now, px, py, vx, vy, colortable)
end

local function updateClosestEntity(mx, my, e)
    local fx, fy, t_best, d_best, best
    fx, fy = e[1], e[2]
    _ = misc.findClosest(now, mx, my, fx, fy)
    
    -- second call is a horrible hack to avoid sign-inversion in update (cause unknown)
    -- does this mean that this findClosest is using inverted values??
    t_best, d_best = misc.findClosest(now, mx, my, fx, fy)
    
    best = e_close
    if t_best and ((not best) or (d_best < best[3]^2)) then
        assert(d_best, "t_best and not d_best")
        best = {e, t_best, d_best^0.5}
    end
    return best
end

function love.load()
    starttime = getTime()
    now = 0
    winx, winy = lg.getDimensions()
    love.math.setRandomSeed(getTime())
    es = {newElement(), newElement()}
    camera = viewport.new(winx, winy)
    camera:setPanRate(100)
    camera:setZoomRate(2)
end

function love.keypressed(key)
    if key == 'escape' then 
        love.event.push('quit')
    end
   
    if key == ' ' or key == 'space' then -- backwards-compatibility
        es = {newElement(), newElement()}
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
    if mouseState == 'manip' 
    or mouseState == 'manip-drag' 
    and e_manip then
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
            -- make element change course
            if e_manip then demanip() end
        elseif mouseState == 'manip-drag' then
            mouseState = 'drag'
            -- make element change course
            if e_manip then demanip() end
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

local function updateManipRef()
    manip_ref = nil
    if isCloseHot() then
        local t = e_close[2]
        local x, y = e_close[1]:getPosition(t) -- t < now ==> nil, nil
        manip_ref = {x, y, t}
    end
end

local upcount = 0
local lastfx1, lastfy1
function love.update(dt)
    local mx, my, ex, ey
    now = getTime() - starttime
    --upcount = upcount + 1
    --if upcount > 20 then love.event.push('quit') end
--        print(upcount, now)
    
    e_close = nil
    mx, my = camera:getWorldPoint(lm:getPosition())
    mx, my = track.new(now, mx, my)
    
    for i=1, #es do
        local t_manip = es[i]:getTInt()
--        if t_manip then assert(es[i].id == e_manip.id) end
        if t_manip and t_manip < now then demanip('abort') end
        
        e_close = updateClosestEntity(mx, my, es[i])
        ex, ey = es[i]:getPosition(now)
--            print(ex, ey)
        if ex < 0 or winx < ex 
        or ey < 0 or winy < ey 
        then
        --    es[i] = newElement()
        --else es[i][1]:clearBefore(now)
        --     es[i][2]:clearBefore(now)
        end
        if i == 1 then lastfx1, lastfy1 = es[1][1]:clone(), es[1][2]:clone() end
    end
    updateManipRef()
--        print()
end

local function drawTrack(fx, fy, rgb) --TODO: curved segments
    local x, y, x1, y1, t
    lg.setColor(rgb)
    x,  y = camera:getScreenPoint(fx(now), fy(now))
    x1, y1 = camera:getScreenPoint(fx(now+1000), fy(now+1000))
    lg.line(x,y, x1, y1)
    t = math.ceil(now)
    for count = 1, 1000 do
        x, y = camera:getScreenPoint(fx(t), fy(t))
        if  x >= 0 and x <= winx 
        and y >= 0 and y <= winy 
        then
            lg.circle('line', x, y, 3, 8)
        end
        t = t + 1
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
        local x, y = camera:getScreenPoint(e:getPosition(now))
        lg.circle('fill', x, y, 6, 8)
    end
    
    lg.setColor(0xff, 0xff, 0xff)
    --if e_manip then
    --    lg.print("manipulating object: "..e_manip.id)
    --end

    -- draw path highlight of point closest to cursor
    -- and highlight the element itself
    if isCloseHot() then
        assert(manip_ref)
        x, y = manip_ref[1], manip_ref[2]
        if x and y then
            x, y = camera:getScreenPoint(x, y) -- dot on track
            lg.circle('fill', x, y, 3, 8)
        end
        x, y = camera:getScreenPoint(e_close[1]:getPosition(now))
        lg.circle('line', x, y, 10, 12) -- circle around entity
    end
    
    --if e_close ~= nil then
    --    assert(e_close[1], 'close element does not exist')
    --    assert(e_close[2], 'clost time does not exist')
    --    local x1, y1 = camera:getScreenPoint(e_close[1]:getPosition(e_close[2]))
    --    local x2, y2 = lm.getPosition()
    --    lg.setColor(0xff, 0xff, 0xff)
    --    lg.line(x1, y1, x2, y2)
    --end
end

