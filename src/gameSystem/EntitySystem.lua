require('utils')

---@class Entity
Entity = { 
    position = Vector3:ctor{x=0,y=0,z=0},
    settings = {},
    innerWidget = nil,
    uuid = ''
}

Entity.tempLoc = Location(0, 0)
Entity.tempGroup = CreateGroup()
Entity.GetUnitZ = function(unit)
    local x = GetUnitX(unit)
    local y = GetUnitY(unit)
    MoveLocation(Entity.tempLoc, x, y)
    return GetLocationZ(Entity.tempLoc) + GetUnitFlyHeight(unit)
end
Entity.GetUnitHitZ = function(unit)
    return Entity.GetUnitZ(unit) + 50
end
Entity.GetLocationZ = function(x, y)
    MoveLocation(Entity.tempLoc, x, y)
    return GetLocationZ(Entity.tempLoc)
end

---@return Entity
function Entity:ctor(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.uuid = GUID.generate()
    o.position = Vector3:ctor{x=0,y=0,z=0}
    o.CustomValues = {}

    return o
end

function Entity:Awake()
end

function Entity:Update()
end

function Entity:Destroy()
end

function Entity:MoveTo(x, y, z)
    if (x ~= nil) then self.position.x = x end
    if (y ~= nil) then self.position.y = y end
    if (z ~= nil) then self.position.z = z end
end