---@class Modifier
---@field owner LuaUnit
---@field applier LuaUnit
Modifier = {}
Modifier.REAPPLY_MODE = {
    NO = 0,
    STACK = 1,
    REFRESH = 2,
    STACK_AND_REFRESH = 3,
    COEXIST = 4,
    REMOVE_OLD = 5
}


---@param lu_owner LuaUnit
---@param settings table
---@param lu_applier LuaUnit
---@param bindAbility number
---@return Modifier
Modifier.Create = function(lu_owner, settings, lu_applier, bindAbility)
    return Modifier:new(nil, lu_owner, settings, lu_applier, bindAbility)
end

---@param lu_owner LuaUnit
---@param mid string
---@param lu_applier LuaUnit
---@param bindAbility number
---@return Modifier
Modifier.CreateById = function(lu_owner, mid, lu_applier, bindAbility)
    local settings = Master.Modifier[mid]
    return Modifier:new(nil, lu_owner, settings, lu_applier, bindAbility)
end

---@param o table
---@param lu_owner LuaUnit
---@param settings table
---@param lu_applier LuaUnit
---@param bindAbility number
---@return Modifier
function Modifier:new(o, lu_owner, settings, lu_applier, bindAbility)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.settings = settings
    o.id = settings.id
    o.uuid = GUID.generate()
    o.ability = bindAbility or settings.BindAbility or nil
    o.applier = lu_applier or lu_owner
    o.owner = lu_owner
    o.interval = settings.interval or CoreTicker.Interval
    o.duration = settings.duration
    if settings.remove_on_death == nil then
        o.remove_on_death = true
    else
        o.remove_on_death = settings.remove_on_death
    end
    o.valid_when_death = settings.valid_when_death or false
    o.reapply_mode = settings.reapply_mode or Modifier.REAPPLY_MODE_NO
    o.stack = settings.stack or 1
    o.max_stack = settings.max_stack or 1
    o.bonitas = settings.bonitas or 0 --大于0表示正面效果，小于0表示负面效果 
    o.effects = {}
    o.effects_scale = 1
    o.delta_time = 0
    o.tags = {}
    if settings.tags then 
        for _,tag in ipairs(settings.tags) do
            o.tags[tag] = true
        end
    end
    return o
end

function Modifier:GetLevel()
    if (self.ability == nil) then
        return 1
    else
        return GetUnitAbilityLevel(self.applier.unit, self.ability)
    end
end

function Modifier:GetLevelValue(key)
    local entries = self.settings.LevelValues;
    local entry
    local value
    if (entries ~= nil) 
        then entry = entries[key] 
        else return 0 
    end
    if (entry ~= nil) 
        then value = entry[self:GetLevel()] 
        else return 0
    end
    if (value ~= nil) then
        return value
    else
        return entry[#entry]
    end
end

function Modifier:LV(key) return self:GetLevelValue(key) end

function Modifier:Refresh()
    self.duration = self.settings.duration
end

---@param value number
---@param refresh boolean
function Modifier:AddStack(value, refresh)
    if (self.stack < self.max_stack) then
        self.stack = self.stack + value
        if (self.stack > self.max_stack) then
            self.stack = self.max_stack
        end
    end
    if (refresh == true) then
        self:Refresh()
    end
end

function Modifier:Update()
    self.delta_time = self.delta_time + CoreTicker.Interval
    if (self.duration ~= -1) then
        self.duration = self.duration - CoreTicker.Interval
        if (self.duration < 0) then
            self:Remove()
        end
    end
    if (self.stack < 1) then
        self:Remove()
    end
    if (self.delta_time >= self.interval) then
        if (self.valid_when_death == true or IsUnitAliveBJ(self.owner.unit)) and (self.settings.Update ~= nil) then
            self.settings.Update(self) 
        end
        self.delta_time = self.delta_time - self.interval
    end
end

function Modifier:Remove()
    self.owner:RemoveModifier(self)
end

function Modifier:OnDeath()
    if (self.settings.Death ~= nil) then 
        self.settings.Death(self) 
    end
    if (self.remove_on_death == true) then
        self:Remove()
    end
end

function Modifier:OnAcquired()
    --create effects
    for _,v in pairs(self.settings.Effects) do
        local eff = AddSpecialEffectTarget(v.model, self.owner.unit, v.attach_point)
        if (v.scale ~= nil) then
            BlzSetSpecialEffectScale(eff, v.scale)
        end
        if (v.rgb ~= nil) then
            BlzSetSpecialEffectColor(eff, v.rgb.r, v.rgb.g, v.rgb.b)
        end
        table.insert(self.effects, eff)
    end
    if (self.settings.Acquire ~= nil) then self.settings.Acquire(self) end
end

function Modifier:OnRemoved()
    --destroy effects
    for k,v in pairs(self.effects) do
        DestroyEffect(v)
    end
    self.effects = {}
    if (self.settings.Remove ~= nil) then self.settings.Remove(self) end
end

function Modifier:OnBeforeTakeDamage(damage)
    if (self.settings.BeforeTakeDamage ~= nil) then self.settings.BeforeTakeDamage(self, damage) end
end
function Modifier:OnBeforeDealDamage(damage)
    if (self.settings.BeforeDealDamage ~= nil) then self.settings.BeforeDealDamage(self, damage) end
end

function Modifier:OnTakeDamage(damage)
    if (self.settings.TakeDamage ~= nil) then self.settings.TakeDamage(self, damage) end
end


function Modifier:OnDealDamage(damage)
    if (self.settings.DealDamage ~= nil) then self.settings.DealDamage(self, damage) end
end

