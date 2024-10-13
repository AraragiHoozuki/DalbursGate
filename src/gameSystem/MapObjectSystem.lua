require('utils')
require('gameSystem.EntitySystem')

MapObjectMgr = {}
---@type table<string, MapObject>
MapObjectMgr.Instances = {}

MapObjectMgr.Update = function()
    for k,obj in pairs(MapObjectMgr.Instances) do
        if obj ~= nil then
            obj:Update()
            if (obj.finished == true) then
                MapObjectMgr.Instances[k] = nil
                obj:Destroy()
            end
        end
	end
end



--------------------------------------------------------
---@class MapObject
MapObject = Entity:ctor{
    z = 0,
    yaw = 0,
}

MapObject.Create = function(lu_creator, position, model, duration, awake_handlers)
    local obj = MapObject:new(nil, lu_creator, position, model, duration, awake_handlers)
    MapObjectMgr.Objects[obj.uuid] = obj
    return obj
end

---@return MapObject
function MapObject:ctor(o)
    local o = Entity:ctor(o)
    setmetatable(o, self)
    self.__index = self
    local z = Entity.GetLocationZ(o.x, o.y) + o.z
    o.position:MoveTo(o.x,o.y,z)
    o:CreateModel(o.model_path)
    MapObjectMgr.Instances[o.uuid] = o
    o.awake_handlers = o.awake_handlers or {}
    o.update_handlers = o.update_handlers or {}
    o.remove_handlers = o.remove_handlers or {}
    o:Awake()
    return o
end

---@return MapObject
function MapObject:new(x, y, z, yaw, model_path, duration, awake_handler)
    local o = Entity:ctor(nil)
    setmetatable(o, self)
    self.__index = self
    o.yaw = yaw
    o.awake_handlers = {awake_handler}
    o.update_handlers = {}
    o.remove_handlers = {}
    z = Entity.GetLocationZ(x, y) + z
    o.position:MoveTo(x,y,z)
    o:CreateModel(model_path)
    o.duration = duration
    MapObjectMgr.Instances[o.uuid] = o
    o:Awake()
    return o
end

function MapObject:AddUpdateHandler(func, interval)
    interval = interval or CoreTicker.Interval
    table.insert(self.update_handlers, {
        func = func, 
        interval = interval,
        elapsed_time = 0
    })
end
function MapObject:AddDestroyHandler(func)
    if (func ~= nil) then
        table.insert(self.remove_handlers, func)
    end
end

function MapObject:CreateModel(path)
    if (path ~= nil) then
        self.model = AddSpecialEffect(path, self.position.x, self.position.y)
        BlzSetSpecialEffectZ(self.model, self.position.z)
        BlzSetSpecialEffectYaw(self.model, self.yaw)
    end
end
function MapObject:ScaleModel(scale)
    scale = scale or 1
    if (self.model ~= nil) then
        BlzSetSpecialEffectScale(self.model, scale)
    end
end
function MapObject:Update()
    for _,h in pairs(self.update_handlers) do
        h.elapsed_time = h.elapsed_time + CoreTicker.Interval
        if (h.elapsed_time > h.interval) then
            h.elapsed_time = h.elapsed_time - h.interval
            h.func(self, h.interval)
        end
    end
    if (self.duration ~= -1) then
        self.duration = self.duration - CoreTicker.Interval
        if (self.duration < 0) then
            self.finished = true
        end
    end
end
function MapObject:Awake()
    for _,h in pairs(self.awake_handlers) do
        h(self)
    end
end
function MapObject:Destroy()
    if (self.model ~= nil) then
        DestroyEffect(self.model)
    end
    for _,h in pairs(self.remove_handlers) do
        h(self)
    end
end