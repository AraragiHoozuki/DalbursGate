---@class Displace
Displace = {
    velocity = Vector3:new(nil, 0, 0, 0), -- 位移速度
    accelerate = Vector3:new(nil, 0, 0, 0), -- 位移加速度
    max_distance = 0,
    max_duration = 0,
    interruptible = true, -- 可否被其他位移打断
    interrupt_action = true, -- 是否打断单位动作
    efx = nil, -- effects
    efx_interval = CoreTicker.Interval,
    Update = nil, -- update callback
    duration = 0,
    distance = 0,
    finished = false
}
Displace.OVERLAY_METHOD = {}
Displace.OVERLAY_METHOD.COEXIST = 0
Displace.OVERLAY_METHOD.STOP_EXISTINGS = 1
Displace.OVERLAY_METHOD.STOP_SELF = 2
-- 停止已有位移，如果已有位移不可停止，则停止自身
Displace.OVERLAY_METHOD.STOP_EXISTINGS_IF_FAILED_STOP_SELF = 3

function Displace:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.delta_time = o.efx_interval
    return o
end

function Displace:Calc(x, y, z)
    self:UpdateTimeAndDistance()
    if (self.efx ~= nil) then self:ShowEfx(x, y) end
    return x + self.velocity.x * CoreTicker.Interval,
           y + self.velocity.y * CoreTicker.Interval,
           z + self.velocity.z * CoreTicker.Interval
end

function Displace:ShowEfx(x, y)
    if self.delta_time >= self.efx_interval then
        self.delta_time = 0
        DestroyEffect(AddSpecialEffect(self.efx, x, y))
    end
end

function Displace:UpdateTimeAndDistance()
    self.velocity.x = self.velocity.x + self.accelerate.x * CoreTicker.Interval
    self.velocity.y = self.velocity.y + self.accelerate.y * CoreTicker.Interval
    self.distance = self.distance + math.sqrt(self.velocity.x * self.velocity.x + self.velocity.y * self.velocity.y) * CoreTicker.Interval
    self.duration = self.duration + CoreTicker.Interval
    self.delta_time = self.delta_time + CoreTicker.Interval
    if (self.max_distance > 0 and self.distance >= self.max_distance) or (self.max_duration > 0 and self.duration >= self.max_duration) then
        self.finished = true
    end
end

function Displace:Stop()
    self.finished = true
end