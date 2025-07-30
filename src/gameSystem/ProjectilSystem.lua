require('utils')
require('gameSystem.EntitySystem')

ProjectilMgr = {}
---@type table<string, Projectil>
ProjectilMgr.Instances = {}

ProjectilMgr.Update = function()
    for k,v in pairs(ProjectilMgr.Instances) do
        if v ~= nil then
            v:Update()
            if (v.ended == true) then
                ProjectilMgr.Instances[k] = nil
                v:Remove()
            end
        end
	end
end

ProjectilMgr.CreateAttackProjectil = function(uw_emitter, u_target, damage_value)
    local settings = Master.DefaultAttackProjectil[GetUnitTypeId(uw_emitter.unit)]

    return Projectil:ctor {
        emitter = uw_emitter,
        target_unit = u_target,
        settings = settings,
        hit_damage = Damage:ctor{
            source = uw_emitter,
            amount = damage_value,
            atktype = Damage.ATTACK_TYPE_PROJECTIL,
            dmgtype = Damage.DAMAGE_TYPE_NORMAL
        },
    }
end


---@class Projectil:Entity
Projectil = Entity:ctor{}
Projectil.tempLoc = Location(0, 0)
Projectil.tempGroup = CreateGroup()
Projectil.TRACK_TYPE_NONE = 0
Projectil.TRACK_TYPE_UNIT = 1
Projectil.TRACK_TYPE_POSITION = 2

Projectil.GetUnitZ = function(unit)
    local x = GetUnitX(unit)
    local y = GetUnitY(unit)
    MoveLocation(Projectil.tempLoc, x, y)
    return GetLocationZ(Projectil.tempLoc) + GetUnitFlyHeight(unit)
end
Projectil.GetUnitHitZ = function(unit)
    return Projectil.GetUnitZ(unit) + 50
end
Projectil.GetLocationZ = function(x, y)
    MoveLocation(Projectil.tempLoc, x, y)
    return GetLocationZ(Projectil.tempLoc)
end
---@return Projectil
function Projectil:ctor(obj)
    obj = Entity:ctor(obj)
    setmetatable(obj, self)
    self.__index = self

    local settings = obj.settings
    local speed = settings.speed
    obj.level = settings.level or 1
    obj.speed = speed
    obj.velocity = Vector3:ctor{}
    obj.no_gravity = settings.no_gravity or false
    obj.hit_range = settings.hit_range or 25
    obj.hit_range_2 = obj.hit_range * obj.hit_range
    obj.hit_terrainQ = settings.hit_terrain
    obj.hit_other = settings.hit_other == true
    obj.hit_ally = settings.hit_ally == true
    obj.hit_piercing = settings.hit_piercing == true
    obj.hit_cooldown = settings.hit_cooldown or 1
    obj.track_type = settings.track_type or Projectil.TRACK_TYPE_NONE
    obj.trackZ = settings.trackZ or false
    obj.tracking_angle = settings.tracking_angle or -1
    obj.turning_speed = settings.turning_speed or 0
    obj.turning_speed_pitch = settings.turning_speed or 0
    obj.max_flying_distance = settings.max_flying_distance or speed* 5
    obj.model_path = settings.model or 'Abilities\\Weapons\\LichMissile\\LichMissile.mdl'
    obj.update_interval = settings.update_interval or CoreTicker.Interval

    --properties
    obj.yaw = 0 --radians not degree
    obj.pitch = 0 --radians not degree angleZ
    obj.flying_time = 0
    obj.flying_distance = 0
    obj.tracking_stopped = false
    obj.hit_checker_group = CreateGroup()
    obj.delta_time = 0
    obj.can_hit = true
    obj.paused = false
    obj.ended = false

    obj:InitAttitude()
    obj:AdjustVelocity()
    obj.model = AddSpecialEffect(obj.model_path, obj.position.x, obj.position.y)
    if (settings.model_scale ~= nil) then
        BlzSetSpecialEffectScale(obj.model, settings.model_scale)
    end
    ProjectilMgr.Instances[obj.uuid] = obj
    if (settings.OnCreated ~= nil ) then
        settings.OnCreated(obj)
    end
    return obj
end
function Projectil:GetPlayer()
    return GetOwningPlayer(self.emitter.unit)
end
function Projectil:EnableHit()
    self.can_hit = true
end
function Projectil:DisableHit()
    self.can_hit = false
end
function Projectil:End()
    self.ended = true
end
function Projectil:Pause()
    self.paused = true
end
function Projectil:Unpause()
    self.paused = false
end
function Projectil:Remove()
    DestroyGroup(self.hit_checker_group)
    if (self.hideModelDeathAnimationQ == true) then
        BlzSetSpecialEffectZ(self.model, -10000)
        BlzPlaySpecialEffect()
    end
    DestroyEffect(self.model)
end
function Projectil:HasTargetQ()
    if (self.target_unit == nil and self.target_position == nil) then
        return false
    else
        return true
    end
end
function Projectil:ChangeModel(path)
    DestroyEffect(self.model)
    self.model = AddSpecialEffect(path, self.position.x, self.position.y)
end
function Projectil:HideModelDeathAnimation(v)
    self.hideModelDeathAnimationQ = (v==true)
end

--- Tracking
function Projectil:InitAttitude()
    local settings = self.settings
    -- set start position
    local offsetX = self.offsetX or settings.offsetX or 0
    local offsetY = self.offsetY or settings.offsetY or 0
    local offsetZ = self.offsetZ or settings.offsetZ or 0
    local x = self.x or GetUnitX(self.emitter.unit)
    local y = self.y or GetUnitY(self.emitter.unit)
    local z = self.z or Entity.GetUnitZ(self.emitter.unit)
    z = z + offsetZ
    -- set start yaw pitch
    local tx,ty,tz,dx,dy,dz,yaw,pitch
    if (self.target_unit ~= nil) then
        tx = GetUnitX(self.target_unit)
        ty = GetUnitY(self.target_unit)
        tz = Projectil.GetUnitHitZ(self.target_unit)
    elseif self.target_position ~= nil then
        tx = self.target_position.x
        ty = self.target_position.y
        tz = self.target_position.z
    else
        self.position:MoveTo(x,y,z)
        self.yaw = GetUnitFacing(self.emitter.unit) / math.degree
        self.pitch = 0
        return
    end
    dx = tx - x
    dy = ty - y
    dz = tz - z
    yaw = math.atan(dy,dx)
    x = offsetY * Cos(yaw) - offsetX * Sin(yaw) + x
    y = offsetY * Sin(yaw) + offsetX * Cos(yaw) + y
    
    self.position:MoveTo(x,y,z)
    local dxy = math.sqrt(dx*dx + dy*dy)
    if (self.no_gravity == false) then
        local g = -GameConstants.Gravity
        local a = 1/(2*self.speed*self.speed)*g*dxy*dxy
        local b = dxy
        local c = a - dz
        local delta = b*b - 4*a*c
        if (delta >= 0) then
            pitch = math.atan((-b+math.sqrt(delta))/(2*a))
        else
            pitch = 45/math.degree
        end
    else
        pitch = math.atan(dz,dxy)
    end
    self.yaw = yaw
    self.pitch = pitch
end

function Projectil:CalcDeltaYaw(target_yaw)
    local angle_to_turn = math.angleDiff(self.yaw, target_yaw)
    local max_turn_angle = self.turning_speed * CoreTicker.Interval
    local delta_yaw
    if (angle_to_turn > 0) then
        delta_yaw = math.min(angle_to_turn, max_turn_angle)
    else
        delta_yaw = math.max(angle_to_turn, -max_turn_angle)
    end
    return delta_yaw
end
function Projectil:CalcDeltaPitch(target_pitch)
    local angle_to_turn = math.angleDiff(self.pitch, target_pitch)
    local max_turn_angle = self.turning_speed_pitch * CoreTicker.Interval
    local delta_pitch
    if (angle_to_turn > 0) then
        delta_pitch = math.min(angle_to_turn, max_turn_angle)
    else
        delta_pitch = math.max(angle_to_turn, -max_turn_angle)
    end
    return delta_pitch
end

function Projectil:Track()
    if (self.tracking_stopped == false and self:HasTargetQ() and self.track_type ~= Projectil.TRACK_TYPE_NONE) then
        local x, y, z
        --追踪单位
        if (self.track_type == Projectil.TRACK_TYPE_UNIT) then
            if self.target_unit ~= nil then
                x = GetUnitX(self.target_unit)
                y = GetUnitY(self.target_unit)
                z = Projectil.GetUnitHitZ(self.target_unit)
            end
        --追踪点
        elseif self.track_type == Projectil.TRACK_TYPE_POSITION then
            if self.target_position ~= nil then
                x = self.target_position.x
                y = self.target_position.y
                z = self.target_position.z
            end
        end
        local dx = x - self.position.x
        local dy = y - self.position.y
        local dz = z - self.position.z
        local target_yaw = math.atan(dy,dx)
        local target_pitch = math.atan(dz, math.sqrt(dx*dx + dy*dy))
        self.yaw = self.yaw + self:CalcDeltaYaw(target_yaw)
        self.pitch = self.pitch + self:CalcDeltaPitch(target_pitch)
        self:AdjustVelocity()
        local delta_yaw = math.angleDiff(self.yaw, target_yaw)
        if (delta_yaw > self.tracking_angle or delta_yaw < -self.tracking_angle) then
            self:Miss()
        end
    end
end

function Projectil:AdjustVelocity()
    self.velocity:MoveTo(self.speed * Cos(self.pitch) * Cos(self.yaw),self.speed * Cos(self.pitch) * Sin(self.yaw), self.speed * Sin(self.pitch))
end


-- Update
function Projectil:UpdateVelocity()
    if self.no_gravity == false then
        self.velocity.z = self.velocity.z - GameConstants.Gravity * CoreTicker.Interval
        self.speed = self.velocity:Norm()
        self.pitch = math.atan(self.velocity.z, self.velocity:NormXY())
        self:AdjustVelocity()
    end
end

function Projectil:UpdateFlyingStatus()
    local x = self.velocity.x * CoreTicker.Interval + self.position.x
    local y = self.velocity.y * CoreTicker.Interval + self.position.y
    local z = self.velocity.z * CoreTicker.Interval + self.position.z
    self.position:MoveTo(x,y,z)
    self.flying_distance = self.flying_distance + self.speed * CoreTicker.Interval
    self.flying_time = self.flying_time + CoreTicker.Interval
end

function Projectil:UpdateModel()
    BlzSetSpecialEffectX(self.model, self.position.x)
    BlzSetSpecialEffectY(self.model, self.position.y)
    BlzSetSpecialEffectZ(self.model, self.position.z)
    BlzSetSpecialEffectYaw(self.model, self.yaw)
    BlzSetSpecialEffectPitch(self.model, -self.pitch)
end

function Projectil:Update()
    if (self.ended == true or self.paused == true) then return end
    
    if (self.settings.CustomTrack~=nil) then
        self.settings.CustomTrack(self)
    else
        self:Track()
    end
    self.delta_time = self.delta_time + CoreTicker.Interval
    self:UpdateVelocity()
    self:UpdateFlyingStatus()
    self:UpdateModel()
    self:CheckHit()
    if (self.settings.Update ~= nil and self.delta_time >= self.update_interval) then
        self.delta_time = self.delta_time - self.update_interval
        self.settings.Update(self, self.update_interval)
    end
    self:CheckEnd()
end

function Projectil:DistanceToUnit(unit)
    return self.position:Distance3D(GetUnitX(unit), GetUnitY(unit), Projectil.GetUnitHitZ(unit))
end


function Projectil:CheckHit()
    if (self.hit_terrainQ == true) then
        MoveLocation(Projectil.tempLoc, self.position.x, self.position.y)
        local terrainZ = GetLocationZ(Projectil.tempLoc)
        if (self.position.z  < terrainZ ) then
            if (self.settings.OnHitTerrain ~= nil) then
                self.settings.OnHitTerrain(self, terrainZ)
            else
                self:End()
            end
        end
    end
    if self.can_hit ~= true then return end
    if (self.hit_other == false) then
        self:CheckHitTarget()
    else
        local cond = Condition(function() return
            (IsUnitEnemy(GetFilterUnit(), GetOwningPlayer(self.emitter.unit)) or self.hit_ally == true) and
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and
            (self:DistanceToUnit(GetFilterUnit()) <= self.hit_range)
        end)
        GroupEnumUnitsInRange(self.hit_checker_group, self.position.x, self.position.y, self.hit_range, cond)
        DestroyBoolExpr(cond)
        local hit = FirstOfGroup(self.hit_checker_group)
        if (hit ~= nil) then
            self:Hit(UnitWrapper.Get(hit))
        else
            self:CheckHitTarget()
        end
    end
end

function Projectil:CheckHitTarget()
    if (self.track_type == Projectil.TRACK_TYPE_UNIT) then
        if self.target_unit ~= nil then
            local x = GetUnitX(self.target_unit)
            local y = GetUnitY(self.target_unit)
            local z = Projectil.GetUnitHitZ(self.target_unit)
            local distance2 = (x-self.position.x)^2+(y-self.position.y)^2 + (z-self.position.z)^2
            if (distance2 < self.hit_range_2 ) then
                self:Hit(UnitWrapper.Get(self.target_unit))
                return
            end
        end
    elseif (self.track_type == Projectil.TRACK_TYPE_POSITION) then
        if (self.target_position ~= nil) then
            local distance = self.position:Distance3D(self.target_position.x, self.target_position.y, self.target_position.z)
            if (distance < self.hit_range) then
                self:Hit(nil)
            end
        end
    end
end

---@param victim UnitWrapper|nil
function Projectil:Hit(victim)
    if victim ~= nil and self.hit_damage ~= nil then
        self.hit_damage.target = victim
        self.hit_damage.source_prjt = self
        self.hit_damage:Resolve()
    end
    -- if victim ~= nil and self.damageSettings.amount ~= 0 then
    --     local dmg = Damage:new(nil, self.emitter, victim, self.damageSettings.amount, self.damageSettings.atktype, self.damageSettings.dmgtype, self.damageSettings.eletype)
    --     dmg:Resolve()
    -- end
    if (self.settings.OnHit ~= nil) then self.settings.OnHit(self, victim) end
    if (self.hit_piercing ~= true) then self:End() end
end

function Projectil:Miss()
    self.tracking_stopped = true
end

function Projectil:CheckEnd()
    if (self.max_flying_distance > 0 and self.flying_distance > self.max_flying_distance) then
        self:End()
    end
end