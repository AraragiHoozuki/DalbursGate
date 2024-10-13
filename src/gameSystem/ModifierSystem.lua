---@class Modifier
---@field owner UnitWrapper
---@field applier UnitWrapper
Modifier = {}
Modifier.REAPPLY_MODE = {
    NO = 0,
    STACK = 1,
    REFRESH = 2,
    STACK_AND_REFRESH = 3,
    COEXIST = 4,
    REMOVE_OLD = 5
}
Modifier.TempGroup = CreateGroup()


---@param lu_owner UnitWrapper
---@param settings table
---@param lu_applier UnitWrapper
---@param bindAbility number
---@return Modifier
Modifier.Create = function(lu_owner, settings, lu_applier, bindAbility)
    return Modifier:new(nil, lu_owner, settings, lu_applier, bindAbility)
end

---@param lu_owner UnitWrapper
---@param mid string
---@param lu_applier UnitWrapper
---@param bindAbility number
---@return Modifier
Modifier.CreateById = function(lu_owner, mid, lu_applier, bindAbility)
    local settings = Master.Modifier[mid]
    return Modifier:new(nil, lu_owner, settings, lu_applier, bindAbility)
end

---@param o table
---@param owner UnitWrapper
---@param settings table
---@param applier UnitWrapper
---@param bindAbility number
---@return Modifier
function Modifier:new(o, owner, settings, applier, bindAbility)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.settings = settings
    o.id = settings.id
    o.uuid = GUID.generate()
    o.ability = bindAbility or settings.BindAbility or nil
    o.applier = applier or owner
    o.owner = owner
    o.interval = settings.interval or CoreTicker.Interval
    o.duration = settings.duration
    o.max_duration = settings.duration
    if settings.remove_on_death == nil then
        o.remove_on_death = true
    else
        o.remove_on_death = settings.remove_on_death
    end
    o.valid_when_death = settings.valid_when_death or false
    o.reapply_mode = settings.reapply_mode or Modifier.REAPPLY_MODE_NO
    o.stack = settings.stack or 1
    o.max_stack = settings.max_stack or 1
    o.strength = settings.strength or 0 --大于0表示正面效果，小于0表示负面效果 
    o.effects = {}
    o.effects_scale = 1
    o.delta_time = 0
    o.CustomValues = {}
    o.tags = {}
    o.hidden = (settings.hidden == true)
    o.icon = settings.icon or [[ReplaceableTextures\PassiveButtons\PASBTNStatUp.blp]]
    o.CommonStatsBonus = {}
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
    self.duration = self.max_duration
end

---@param value number
---@param refresh boolean
function Modifier:AddStack(value, refresh)
    if (self.stack < self.max_stack) then
        self.stack = self.stack + value
        if (self.stack > self.max_stack) then
            self.stack = self.max_stack
        end
        self:OnStack(value)
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

function Modifier:OnStack(value)
    if (self.settings.OnStack ~= nil) then 
        self.settings.OnStack(self, value)
    end
end

function Modifier:Remove()
    self.owner:RemoveModifier(self)
end

function Modifier:OnDeath()
    if (self.settings.OnDeath ~= nil) then 
        self.settings.OnDeath(self)
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
    if (self.settings.OnAcquired ~= nil) then self.settings.OnAcquired(self) end
end

function Modifier:OnRemoved()
    --destroy effects
    for k,v in pairs(self.effects) do
        DestroyEffect(v)
    end
    self.effects = {}
    if (self.settings.OnRemoved ~= nil) then self.settings.OnRemoved(self) end
end

function Modifier:OnBeforeTakeDamage(damage)
    if (self.settings.OnBeforeTakeDamage ~= nil) then self.settings.OnBeforeTakeDamage(self, damage) end
end
function Modifier:OnBeforeDealDamage(damage)
    if (self.settings.OnBeforeDealDamage ~= nil) then self.settings.OnBeforeDealDamage(self, damage) end
end

function Modifier:OnTakeDamage(damage)
    if (self.settings.OnTakeDamage ~= nil) then self.settings.OnTakeDamage(self, damage) end
end


function Modifier:OnDealDamage(damage)
    if (self.settings.OnDealDamage ~= nil) then self.settings.OnDealDamage(self, damage) end
end

function Modifier:IsVisible(damage)
    if (self.settings.OnDealDamage ~= nil) then self.settings.OnDealDamage(self, damage) end
end

function Modifier:GetDescription()
    local title, duration, stack, body
    title = self:GetTitle()..'|n|n'
    if (self.duration == -1) then
        duration = '∞'
    else
        duration = self.duration
        if(duration > 1) then 
            duration = math.ceil(duration)
        else
            duration =string.format("%.2f", duration)
        end
    end
    duration =  '剩余时间: '..duration..'|n'
    stack = '层数: '..self.stack..'|n'
    body = string.gsub(self.settings.description or self.id, '%$[^(%$)]+%$', function (s)
        return self:LV(string.sub(s, 2,-2))
    end)
    body = string.gsub(body, '@[^(%$)]+@', function (s)
        return self.CustomValues[string.sub(s, 2,-2)]
    end)
    return title..duration..stack..body
end

function Modifier:GetTitle()
    return self.settings.title or self.id
end