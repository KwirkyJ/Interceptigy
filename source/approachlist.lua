---Module to hide the ugly details of storing closest-approaches of entities
local approach = {}

---Insert an approach pair into the given list
---@param list reference to 'approachlist' table;
---            modified in-place; can be empty
---@param time time of approach (number)
---@param dist distance of approach (number)
---@param e1   Entity reference, one of those in pair
---@param e2   Entity reference, the other of the pair
approach.insert = function(list, time, dist, e1, e2)
    local i = #list + 1
    list[i]   = time
    list[i+1] = dist
    list[i+2] = e1
    list[i+3] = e2
end

---Get the information of the approach-pair closest to a given location
---@param list 'approachlist' table
---@param x    x coordinate (number)
---@param y    y coordinate (number)
---@return nil iff list not empty; 
---        else approach information (time, distance, entity1, entity2)
approach.getClosestTo = function(list, x, y)
    if #list < 4 then return end
    local best_i, best_d = 1, math.huge
    local ex, ey, d
    for i=1, #list, 4 do
        for k=2, 3 do
            ex, ey = list[i+k]:getPosition(i)
            d = (x-ex)^2 + (y-ey)^2 -- no need to root for actual distance
            if d < best_d then best_d, best_i = d, i end
        end
    end
    return list[best_i], list[best_i+1], list[best_i+2], list[best_i+3]
end

---closure variables for getApproaches/_approachIter generator
local _i, _id

---iterator closure (NOT THREAD-SAFE)
local function _approachIter(list) 
    for i=_i, #list, 4 do
        assert(list[i+3])
        if (list[i+2].id == _id) or (list[i+3].id == _id) then
            _i = i+4
            return list[i], list[i+1], list[i+2], list[i+3]
        end
    end
end

---Generator that yields time, distance, entity1, and entity2 of all 
---approaches in approach list where one of the entities has the 
---same ID as the argument
---@param list   approachlist table
---@param entity Entity instance
---@return for each approach pairing where entity.id matches: time, dist, e1, e2
approach.getApproaches = function(list, entity)
    _i, _id = 1, entity.id
    return _approachIter, list
end



return approach

