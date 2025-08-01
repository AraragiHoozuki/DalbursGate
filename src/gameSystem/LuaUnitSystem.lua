

UnitMgr = {}
UnitMgr.DummyCaster = FourCC('n000')
---@type table<unit, LuaUnit>
UnitMgr.LuaUnits = {}

--- register unit to lua unit
---@param unit unit
---@return UnitWrapper
UnitMgr.RegisterUnit = function(unit)
    local lu = LuaUnit:new(nil, unit)
    UnitMgr.LuaUnits[unit] = lu
    return lu;
end

UnitMgr.UnregisterUnit = function(unit)
    UnitMgr.LuaUnits[unit] = nil
end

UnitMgr.UnregisterLuaUnit = function(lu)
    UnitMgr.LuaUnits[lu.unit] = nil
end

UnitMgr.IsUnitRegistered = function(unit)
    return UnitMgr.LuaUnits[unit] ~= nil
end

UnitMgr.RemoveUnit = function(unit)
    UnitMgr.UnregisterUnit(unit)
    RemoveUnit(unit)
end

UnitMgr.Update = function()
    for _,v in pairs(UnitMgr.LuaUnits) do
        v:Update()
    end
end

UnitMgr.DummySpellTarget = function(speller, target, abiId, level, order_string)
    print(speller, target)
    local dummy = CreateUnit(GetOwningPlayer(speller), UnitMgr.DummyCaster, GetUnitX(speller), GetUnitY(speller), 0)
    UnitApplyTimedLife(dummy, FourCC('BTLF'), 1)
    --ShowUnit(dummy, false)
    UnitAddAbility(dummy, abiId)
    SetUnitAbilityLevel(dummy, abiId, level)
    IssueTargetOrder(dummy, order_string, target)
end

----------------------------------------------------------

---@class LuaUnit
---@field unit Unit
---@field modifiers table<number, Modifier>
---@field displaces table<number, Displace>
LuaUnit = {}

--- @return LuaUnit
LuaUnit.Get = function(unit)
    if (UnitMgr.IsUnitRegistered(unit)) then
        return UnitMgr.LuaUnits[unit]
    else
        return UnitMgr.RegisterUnit(unit)
    end
end

---@param o table
---@param unit Unit
function LuaUnit:new(o, unit)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.uuid = GUID.generate()
    o.unit = unit
    o.modifiers = {}
    o.displaces = {}
    o.hitHistory = {}
    o.atk_spd_modify = 0
    o.default_atk_interval = BlzGetUnitWeaponRealField(o.unit, UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0)
    return o
end

function LuaUnit:AttackSpeedModify(value_pct)
    self.atk_spd_modify = self.atk_spd_modify + value_pct
    local value = self.atk_spd_modify/100
    local interval_new = self.default_atk_interval/(1+value)
    BlzSetUnitWeaponRealField(self.unit, UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, interval_new)
end

function LuaUnit:Update()
    self:UpdateModifiers()
    self:UpdateDisplaces()
end

function LuaUnit:UpdateDisplaces()
    if (#(self.displaces)) == 0 then return end
    local x = GetUnitX(self.unit)
    local y = GetUnitY(self.unit)
    for i = #(self.displaces), 1, -1 do
        local d = self.displaces[i]
        if d.finished then
            table.remove(self.displaces, i)
        else
            if d.interrupt_action then 
                IssueImmediateOrderById(self.unit, 851972) -- stop order
            end
            x, y = d:Calc(x, y, 0)
        end
    end
    SetUnitX(self.unit, x)
    SetUnitY(self.unit, y)
end

function LuaUnit:AddDisplace(d)
    table.insert(self.displaces, d)
end

function LuaUnit:UpdateModifiers()
    for i = #(self.modifiers), 1, -1 do
        self.modifiers[i]:Update()
    end
end

function LuaUnit:AcquireModifier(settings, lu_applier, bindAbility)
    local mod = Modifier.Create(self, settings, lu_applier, bindAbility)
    return self:CheckModifierReapply(mod)
end
function LuaUnit:AcquireModifierById(mid, lu_applier, bindAbility)
    local mod = Modifier.CreateById(self, mid, lu_applier, bindAbility)
    return self:CheckModifierReapply(mod)
end

function LuaUnit:ApplyModifier(settings, lu_target, bindAbility)
    local mod = Modifier.Create(lu_target, settings, self, bindAbility)
    return lu_target:CheckModifierReapply(mod)
end
function LuaUnit:ApplyModifierById(mid, lu_target, bindAbility)
    local mod = Modifier.CreateById(lu_target, mid, self, bindAbility)
    return lu_target:CheckModifierReapply(mod)
end

function LuaUnit:IsModifierTypeAffected(mid)
    for k,v in pairs(self.modifiers) do
        if v.id == mid then
            return true
        end
    end
    return false
end
function LuaUnit:GetAffectedModifier(mid)
    for _,v in pairs(self.modifiers) do
        if v.id == mid then
            return v
        end
    end
    return nil
end
function LuaUnit:GetAffectedModifierIndex(mid)
    for i,v in ipairs(self.modifiers) do
        if v.id == mid then
            return i
        end
    end
    return nil
end

---@param m Modifier
function LuaUnit:CheckModifierReapply(m)
    local mod = self:GetAffectedModifier(m.id)
    if mod ~= nil then
        if m.reapply_mode == Modifier.REAPPLY_MODE.NO then
            return nil
        elseif m.reapply_mode == Modifier.REAPPLY_MODE.STACK then
            mod:AddStack(m.stack, false)
            return nil
        elseif m.reapply_mode == Modifier.REAPPLY_MODE.REFRESH then
            mod:Refresh()
            return nil
        elseif m.reapply_mode == Modifier.REAPPLY_MODE.STACK_AND_REFRESH then
            mod:AddStack(m.stack, true)
            return nil
        elseif m.reapply_mode == Modifier.REAPPLY_MODE.COEXIST then
            table.insert(self.modifiers, m)
            m:OnAcquired()
            return m
        elseif m.reapply_mode == Modifier.REAPPLY_MODE.REMOVE_OLD then
            mod:Remove()
            table.insert(self.modifiers, m)
            m:OnAcquired()
            return m
        end
    else
        table.insert(self.modifiers, m)
        m:OnAcquired()
        return m
    end
end

function LuaUnit:AddTestModifier()
    self:AcquireModifier('MODIFIER_TEST')
end

function LuaUnit:RemoveModifier(mod)
    local index = table.indexOf(self.modifiers, mod)
    self:RemoveModifierByIndex(index)
end
function LuaUnit:RemoveModifierById(mid)
    local index = self:GetAffectedModifierIndex(mid)
    self:RemoveModifierByIndex(index)
end
function LuaUnit:RemoveModifierByIndex(index)
    if index ~= nil then
        local mod = table.remove(self.modifiers, index)
        mod:OnRemoved()
    end
end

function LuaUnit:HasTag(tag)
    for _,m in ipairs(self.modifiers) do
        if m.tags[tag] ~= nil then
            return true
        end
    end
    return false
end

function LuaUnit:OnDeath()
    for _,m in pairs(self.modifiers) do
        m:OnDeath()
    end
end

function LuaUnit:OnBeforeDealDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnBeforeDealDamage(damage)
    end
end
function LuaUnit:OnBeforeTakeDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnBeforeTakeDamage(damage)
    end
end

function LuaUnit:OnDealDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnDealDamage(damage)
    end
end

function LuaUnit:OnTakeDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnTakeDamage(damage)
    end
end