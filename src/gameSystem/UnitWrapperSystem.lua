require('utils')
require('gameSystem.EntitySystem')

UnitMgr = {}
UnitMgr.DummyCaster = FourCC('h000')
---@type table<unit, UnitWrapper>
UnitMgr.Units = {}

--- register unit to lua unit
---@param unit unit
---@return UnitWrapper
UnitMgr.RegisterUnit = function(unit)
    local uw = UnitWrapper:ctor(unit)
    UnitMgr.Units[unit] = uw
    return uw;
end

UnitMgr.UnregisterUnit = function(unit)
    UnitMgr.Units[unit] = nil
end

UnitMgr.UnregisterLuaUnit = function(uw)
    UnitMgr.Units[uw.unit] = nil
end

UnitMgr.UnitRegisteredQ = function(unit)
    return UnitMgr.Units[unit] ~= nil
end

UnitMgr.RemoveUnit = function(unit)
    UnitMgr.UnregisterUnit(unit)
    RemoveUnit(unit)
end

UnitMgr.Update = function()
    for _,v in pairs(UnitMgr.Units) do
        v:Update()
    end
end

UnitMgr.DummySpellTarget = function(speller, target, abiId, level, order_string)
    local dummy = CreateUnit(GetOwningPlayer(speller), UnitMgr.DummyCaster, GetUnitX(speller), GetUnitY(speller), 0)
    UnitApplyTimedLife(dummy, FourCC('BTLF'), 1)
    ShowUnit(dummy, false)
    UnitAddAbility(dummy, abiId)
    SetUnitAbilityLevel(dummy, abiId, level)
    IssueTargetOrder(dummy, order_string, target)
end
--------------------------------------------------------------------

---@class UnitWrapper
UnitWrapper = Entity:ctor{}

UnitWrapper.Get = function(unit)
    if (UnitMgr.UnitRegisteredQ(unit)) then
        return UnitMgr.Units[unit]
    else
        return UnitMgr.RegisterUnit(unit)
    end
end

---@return UnitWrapper
function UnitWrapper:ctor(unit)
    local o = Entity:ctor()
    setmetatable(o, self)
    self.__index = self
    o.innerWidget = unit
    o.unit = unit
    o.modifiers = {}
    o.displaces = {}
    o.defaultFlyHeight = GetUnitFlyHeight(unit)
    o:InitGravityDisplace()
    o:InitCommonAbilities()
    return o
end

function UnitWrapper:InitCommonAbilities()
    if (GetUnitAbilityLevel(self.unit, CommonAbilitiy.AttackSpeed) < 1) then
        UnitAddAbility(self.unit, CommonAbilitiy.AttackSpeed)
    end
    if (GetUnitAbilityLevel(self.unit, CommonAbilitiy.MoveSpeed) < 1) then
        UnitAddAbility(self.unit, CommonAbilitiy.MoveSpeed)
    end
    self.attack_speed_ability = BlzGetUnitAbility(self.unit, CommonAbilitiy.AttackSpeed)
    self.move_speed_ability = BlzGetUnitAbility(self.unit, CommonAbilitiy.MoveSpeed)
end
function UnitWrapper:GetBonusAttackSpeed()
    return BlzGetAbilityRealLevelField(self.attack_speed_ability, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0)
end
function UnitWrapper:AddAttackSpeed(value)
    BlzSetAbilityRealLevelField(self.attack_speed_ability, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0, self:GetBonusAttackSpeed() + value)
    IncUnitAbilityLevel(self.unit, CommonAbilitiy.AttackSpeed)
    DecUnitAbilityLevel(self.unit, CommonAbilitiy.AttackSpeed)
end

function UnitWrapper:InitGravityDisplace()
    self.gravityDisplace = Displace:ctor{
        velocity = Vector3:new(nil, 0, 0, 0),
        accelerate = Vector3:new(nil, 0, 0, -GameConstants.Gravity),
        max_distance = 0,
        max_duration = 0,
        interruptible = false,
        interrupt_action = false,
    }
end

function UnitWrapper:Update()
    self:UpdateModifiers()
    self:UpdateDisplaces()
end

function UnitWrapper:EnableHeightChange()
    if (self.height_change_enabled ~= true) then
        UnitAddAbility(self.unit, FourCC('Arav'))
        UnitRemoveAbility(self.unit, FourCC('Arav'))
        self.height_change_enabled =  true
    end
end

function UnitWrapper:UpdateDisplaces()
    local x = GetUnitX(self.unit)
    local y = GetUnitY(self.unit)
    local z = Entity.GetUnitZ(self.unit)
    for i = #(self.displaces), 1, -1 do
        local d = self.displaces[i]
        if d.finished then
            table.remove(self.displaces, i)
        else
            if d.interrupt_action then 
                IssueImmediateOrderById(self.unit, 851972) -- stop order
            end
            x, y, z = d:Calc(x, y, z)
        end
    end
    local height = z - Entity.GetLocationZ(x,y)
    if height > self.defaultFlyHeight + 1 then
        x, y, z = self.gravityDisplace:Calc(x, y, z)
    else
        self.gravityDisplace.velocity.z = 0
        z = Entity.GetLocationZ(x,y) + self.defaultFlyHeight
    end
    SetUnitX(self.unit, x)
    SetUnitY(self.unit, y)
    self:EnableHeightChange()
    SetUnitFlyHeight(self.unit, z - Entity.GetLocationZ(x,y), 0)
end

function UnitWrapper:AddDisplace(d)
    table.insert(self.displaces, d)
end

function UnitWrapper:UpdateModifiers()
    for i = #(self.modifiers), 1, -1 do
        self.modifiers[i]:Update()
    end
end

function UnitWrapper:AcquireModifier(settings, lu_applier, bindAbility)
    local mod = Modifier.Create(self, settings, lu_applier, bindAbility)
    return self:CheckModifierReapply(mod)
end
function UnitWrapper:AcquireModifierById(mid, lu_applier, bindAbility)
    local mod = Modifier.CreateById(self, mid, lu_applier, bindAbility)
    return self:CheckModifierReapply(mod)
end

function UnitWrapper:ApplyModifier(settings, lu_target, bindAbility)
    local mod = Modifier.Create(lu_target, settings, self, bindAbility)
    return lu_target:CheckModifierReapply(mod)
end
function UnitWrapper:ApplyModifierById(mid, lu_target, bindAbility)
    local mod = Modifier.CreateById(lu_target, mid, self, bindAbility)
    return lu_target:CheckModifierReapply(mod)
end

function UnitWrapper:IsModifierTypeAffected(mid)
    for k,v in pairs(self.modifiers) do
        if v.id == mid then
            return true
        end
    end
    return false
end
function UnitWrapper:GetAffectedModifier(mid)
    for _,v in pairs(self.modifiers) do
        if v.id == mid then
            return v
        end
    end
    return nil
end
function UnitWrapper:GetAffectedModifierIndex(mid)
    for i,v in ipairs(self.modifiers) do
        if v.id == mid then
            return i
        end
    end
    return nil
end

---@param m Modifier
function UnitWrapper:CheckModifierReapply(m)
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

function UnitWrapper:AddTestModifier()
    self:AcquireModifier('MODIFIER_TEST')
end

function UnitWrapper:RemoveModifier(mod)
    local index = table.indexOf(self.modifiers, mod)
    self:RemoveModifierByIndex(index)
end
function UnitWrapper:RemoveModifierById(mid)
    local index = self:GetAffectedModifierIndex(mid)
    self:RemoveModifierByIndex(index)
end
function UnitWrapper:RemoveModifierByIndex(index)
    if index ~= nil then
        local mod = table.remove(self.modifiers, index)
        mod:OnRemoved()
    end
end

function UnitWrapper:HasTag(tag)
    for _,m in ipairs(self.modifiers) do
        if m.tags[tag] ~= nil then
            return true
        end
    end
    return false
end

function UnitWrapper:OnDeath()
    for _,m in pairs(self.modifiers) do
        m:OnDeath()
    end
end

function UnitWrapper:OnBeforeDealDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnBeforeDealDamage(damage)
    end
end
function UnitWrapper:OnBeforeTakeDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnBeforeTakeDamage(damage)
    end
end

function UnitWrapper:OnDealDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnDealDamage(damage)
    end
end

function UnitWrapper:OnTakeDamage(damage)
    for _,m in pairs(self.modifiers) do
        m:OnTakeDamage(damage)
    end
end