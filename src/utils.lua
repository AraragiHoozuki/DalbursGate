-- table extend

--- get key of value in table, returns nil if value is not in table
---@param tbl table
---@param value any
table.getKey = function(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return k
        end
    end
    return nil
end

--- get index of value in table, only works for number indexed table
--- return 0 if not found
table.indexOf = function(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return 0
end

--- count members of table t
table.count= function(t)
    local leng=0
    for k, v in pairs(t) do
      leng=leng+1
    end
    return leng;
end

function PrintTable(t)
    print('-------------start ', t, '----------------')
    for k, v in pairs(t) do
      print(k, ':', v)
    end
    print('--------------end----------------')
end

--- check if table contains an element
---@param table table
---@param element any
table.contains = function(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
end

-- Math 
math.degree = math.pi / 180

--- calc minimum difference of to angles(in radian)
---@param r1 number
---@param r2 number
---@return number
math.angleDiff = function(r1, r2)
    local d = r2 - r1
    --[[
    while (d > math.pi) do
        d = d - 2 * math.pi
    end
    while (d < -math.pi) do
        d = d + 2 * math.pi
    end
    ]]--
    if (d > math.pi) then d = d - 2 * math.pi
    elseif (d < - math.pi) then d = d + 2 * math.pi
    end
    return d
end

--- returns xdy of dnd rule
---@param x number
---@param y number
---@return number
math.dice = function(x, y)
    local result = 0
    for i = 1, x do
        result = result + math.random(y)
    end
    return result
end

GUID = {
    _chars = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'},
    _HexDigit = function() return GUID._chars[GetRandomInt(1,16)] end,
    generate = function()
        return GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        '-'..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        '-'..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        '-'..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        '-'..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()..
        GUID._HexDigit()
    end
}



---@class Vector2
Vector2 = {
    x=0, 
    y=0
}
---@return Vector2
function Vector2:new(o, x, y)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    return o
end
---@return Vector2
function Vector2:ctor(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Calc distance of vector2 to coordinates
---@param x number
---@param y number
---@return number
function Vector2:Distance(x, y)
    return math.sqrt((x - self.x)^2 + (y - self.y)^2)
end
--- func desc
---@param vec Vector2
function Vector2:DistanceToVector2(vec)
    return math.sqrt((vec.x - self.x)^2 + (vec.y - self.y)^2)
end

---@class Vector3
Vector3 = {x=0, y=0, z=0}

---@return Vector3
function Vector3:new(o, x, y, z)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.x = x or 0
    o.y = y or 0
    o.z = z or 0
    return o
end
---@return Vector3
function Vector3:ctor(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function Vector3:Clone()
    return Vector3:ctor{
        x = self.x,
        y = self.y,
        z = self.z
    }
end
function Vector3:MoveTo(x, y, z)
    if (x ~= nil) then self.x = x end
    if (y ~= nil) then self.y = y end
    if (z ~= nil) then self.z = z end
end
function Vector3:NormXY()
    return math.sqrt(self.x*self.x + self.y*self.y)
end
function Vector3:Norm()
    return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end
function Vector3:Distance(x, y)
    return math.sqrt((x - self.x)^2 + (y - self.y)^2)
end
function Vector3:Distance2D(x, y)
    return math.sqrt((x - self.x)^2 + (y - self.y)^2)
end
function Vector3:Distance3D(x, y, z)
    return math.sqrt((x - self.x)^2 + (y - self.y)^2 + (z - self.z)^2)
end
---@param vector Vector3
function Vector3:DistanceTo(vector)
    return self:Distance(vector.x, vector.y)
end
---@param vector Vector3
function Vector3:DistanceTo3D(vector)
    return self:Distance3D(vector.x, vector.y, vector.z)
end

function Vector3:RotateAboutXY(rad, x, y)
    local dx = self.x - x
    local dy = self.y - y
    self.x = x + dx * Cos(rad) - dy * Sin(rad)
    self.y = y + dy * Cos(rad) + dx * Sin(rad)
end