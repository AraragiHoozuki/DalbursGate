package = {}
package.path = './?.lua;./?/init.lua'

local P
do
    local preloadType, preload, _errorhandler
    do
        preloadType = 'string'
        preload = load
        _errorhandler = function(msg)
            return print(msg)
        end
    end

    local _G = _G
    local package = package
    local string, table = string, table
    local error, xpcall, type, setmetatable, tostring, ipairs, load = error, xpcall, type, setmetatable, tostring,
                                                                      ipairs, load

    local _FILES = {}
    local _LOADED_MODULES = {}
    local _LOADED_FILES = {}
    local _LOADING_FILES = {}

    local function errorhandler(msg)
        if _errorhandler and msg then
            return _errorhandler(msg)
        end
    end

    local function resolvefile(module)
        module = module:gsub('[./\\]+', '/')

        for item in package.path:gmatch('[^;]+') do
            local filename = item:gsub('^%.[/\\]+', ''):gsub('%?', module)
            if _FILES[filename] then
                return filename
            end
        end
    end

    local function compilefile(filename, mode, env, level)
        local code = _FILES[filename]
        if not code then
            error(string.format('cannot open %s: No such file or directory', filename), (level or 1) + 1)
        end
        return preload(code, '@' .. filename, mode, env or _G)
    end

    --[==[
    local orgRequire = require
    ]==]--

    function require(module)
        local loaded = _LOADED_MODULES[module]
        if loaded then
            return loaded
        end

        local filename = resolvefile(module)
        if not filename then
            --[==[
            if orgRequire then
                return orgRequire(module)
            end
            ]==]--
            error(string.format('module \'%s\' not found', module), 2)
        end

        loaded = _LOADED_FILES[filename]
        if loaded then
            return loaded
        end

        if _LOADING_FILES[filename] then
            error('critical dependency', 2)
        end

        local f, err = compilefile(filename, nil, nil, 2)
        if not f then
            error(err, 2)
        end

        _LOADING_FILES[filename] = true
        local ok, ret = xpcall(f, errorhandler, module, filename)
        _LOADING_FILES[filename] = false
        if not ok then
            error()
        end

        ret = ret or true

        _LOADED_MODULES[module] = ret
        _LOADED_FILES[filename] = ret

        return ret
    end

    function loadfile(filename, mode, env)
        return compilefile(filename, mode, env, 2)
    end

    function dofile(filename)
        compilefile(filename, nil, nil, 2)()
    end

    function seterrorhandler(handler)
        if type(handler) ~= 'function' then
            error(string.format('bad argument #1 to `seterrorhandler` (function expected, got %s)', type(handler)), 2)
        end
        _errorhandler = handler
    end

    function geterrorhandler()
        return _errorhandler
    end

    -- hook for errorhandler
    do
        local function tryreturn(ok, ...)
            if ok then
                return ...
            end
        end

        local function generate(index, count)
            local args = {}
            for i = 1, count do
                table.insert(args, 'ARG' .. i)
            end
            args = table.concat(args, ',')

            local code = [[
local o, r, e = ...
return function({ARGS})
    if type(ARG{N}) == 'function' then
        local c = ARG{N}
        ARG{N} = function(...)
            return r(xpcall(c, e, ...))
        end
    end
    return o({ARGS})
end
]]
            code = code:gsub('{N}', tostring(index)):gsub('{ARGS}', args)

            return load(code)
        end

        local apis = {
            {'TimerStart', 4, 4}, {'ForGroup', 2, 2}, {'ForForce', 2, 2}, {'Condition', 1, 1}, {'Filter', 1, 1},
            {'EnumDestructablesInRect', 3, 3}, {'EnumItemsInRect', 3, 3}, {'TriggerAddAction', 2, 2},
        }

        for _, v in ipairs(apis) do
            local name, index, count = v[1], v[2], v[3]
            _G[name] = generate(index, count)(_G[name], tryreturn, errorhandler)
        end
    end

    P = setmetatable({}, {
        __newindex = function(t, k, v)
            if type(v) ~= preloadType then
                error('PRELOADED value must be ' .. preloadType)
            end
            _FILES[k] = v
        end,
        __index = function(t, k)
            error('Can`t read')
        end,
        __metatable = false,
    })
end

P['core/CoreTicker.lua'] = [[CoreTicker = {}
CoreTicker._timer = nil
CoreTicker._stamp = 0
CoreTicker.Interval = 1/60
CoreTicker.DelayedActions = {}
CoreTicker.AttachedActions = {}

function CoreTicker._tick()
    CoreTicker._stamp = CoreTicker._stamp + 1
    UnitMgr.Update()
    ProjectilMgr.Update()
    MapObjectMgr.Update()
    CoreTicker.DoDelayedActions()
    CoreTicker.DoAttachedActions()
end

function CoreTicker.RegisterDelayedAction(action, delay_time)
    local target_stamp = math.floor(CoreTicker._stamp + delay_time/CoreTicker.Interval)
    if (CoreTicker.DelayedActions[target_stamp] == nil) then
        CoreTicker.DelayedActions[target_stamp] = {}
    end
    table.insert(CoreTicker.DelayedActions[target_stamp], action)
end

function CoreTicker.DoDelayedActions()
    local actions = CoreTicker.DelayedActions[CoreTicker._stamp]
    if (actions ~= nil) then
        for _,act in ipairs(actions) do
            act()
        end
        CoreTicker.DelayedActions[CoreTicker._stamp] = nil
    end
end

function CoreTicker.AttachAction(action, interval, id)
    if (CoreTicker.AttachedActions[id] == nil) then
        CoreTicker.AttachedActions[id] = {
            func = action,
            interval = interval or CoreTicker.Interval,
            elapsed = 0
        }
    else
        print('action attach failed: same id')
    end
end

function CoreTicker.DoAttachedActions()
    for id,act in pairs(CoreTicker.AttachedActions) do
        act.elapsed = act.elapsed + CoreTicker.Interval
        if (act.elapsed > act.interval) then
            act.elapsed = act.elapsed - act.interval
            act.func(act.interval)
        end
    end
end

function CoreTicker.DetachAction(id)
    if (CoreTicker.AttachedActions[id] == nil) then
        print('action detach failed: id not found')
    else
        CoreTicker.AttachedActions[id] = nil
    end
end

function CoreTicker.RestartStamp()
    local stamp = CoreTicker._stamp
    CoreTicker._stamp = 0
    local newDelayedActions = {}
    for k,v in pairs(CoreTicker.DelayedActions) do
        newDelayedActions[k-stamp] = v
        CoreTicker.DelayedActions[k] = nil
    end
end

function CoreTicker.Init(interval)
    if (interval ~= nil and interval > 0) then CoreTicker.Interval = interval end
    CoreTicker._timer = CreateTimer()
    TimerStart(CoreTicker._timer, CoreTicker.Interval, true, CoreTicker._tick)
end]]

P['core/GameConstants.lua'] = [[GameConstants = {
    Gravity = 600
}]]

P['core/GameHelper.lua'] = [[
GameHelper = {}
GameHelper.UnitModelPathGetter = {
    _helperItem = nil,
    Init = function(self)
        self._helperItem = CreateItem(FourCC('ratf'), 0, 0)
        SetItemVisible(self._helperItem, false)
    end,
    Get = function(self, unit)
        BlzSetItemSkin(self._helperItem, GetUnitTypeId(unit))
        return BlzGetItemStringField(self._helperItem, ITEM_SF_MODEL_USED)
    end
}

GameHelper.UnitModelPathGetter:Init()]]

P['core/init.lua'] = [[require('core.GameConstants')
require('core.GameHelper')
require('core.CoreTicker')]]

P['debug/init.lua'] = [[Debug = {}]]

P['gameSystem/DamageSystem.lua'] = [=[---@class Damage
---@field source UnitWrapper
Damage = {
  amount = 0,
  atktype = 0,
  dmgtype = 0,
  eletype = 0,
  source_prjt = nil,
  control_set = nil,
  control_caption_max = nil,
  control_caption_min = 0,
  control_add_before = 0,
  control_rate = 0,
  control_scale = 1,
  control_add_after = 0
}
--[[ damage for copying
damage = Damage:ctor {
  amount = 100,
  source = caster,
  target = target,
  atktype = Damage.ATTACK_TYPE_SPELL,
  dmgtype = Damage.DAMAGE_TYPE_NORMAL,
  eletype = Damage.ELEMENT_TYPE_PIERCE
}
]]--

Damage.ATTACK_TYPE_UNKNOWN = 0
Damage.ATTACK_TYPE_MELEE = 1 --近战攻击
Damage.ATTACK_TYPE_PROJECTIL = 2 --远程攻击
Damage.ATTACK_TYPE_SPELL = 3 -- 法术攻击

Damage.DAMAGE_TYPE_NORMAL = 0 --普通伤害
Damage.DAMAGE_TYPE_DIRECT = 1 --直接伤害，不受任何减免
Damage.DAMAGE_TYPE_PURE = 2 --纯粹伤害，不受防御、抗性减免，但是可以被伤害控制效果减免
Damage.DAMAGE_TYPE_DOT = 3 -- damage over time 持续伤害
Damage.DAMAGE_TYPE_HEAL = 4 -- 治疗

Damage.ELEMENT_TYPE_NONE = 0
Damage.ELEMENT_TYPE_PIERCE = 1 --穿刺
Damage.ELEMENT_TYPE_SMASH = 2 --钝击
Damage.ELEMENT_TYPE_SLASH = 3 --斩击
Damage.ELEMENT_TYPE_THERMO = 4 --灼热
Damage.ELEMENT_TYPE_KRYO = 5 --寒冷
Damage.ELEMENT_TYPE_ELECTRIC = 6 --闪电
Damage.ELEMENT_TYPE_PSYCHIC = 7 --心灵
Damage.ELEMENT_TYPE_BIO = 8 --生命
Damage.ELEMENT_TYPE_DIVINE = 9 --神圣
Damage.ELEMENT_TYPE_ENERGIC = 10 --能量

--伤害控制效果
Damage.CONTROL_TYPE_SET = 0 --设置伤害值
Damage.CONTROL_TYPE_CAPTION_MAX = 1 --伤害上限
Damage.CONTROL_TYPE_CAPTION_MIN = 2 --伤害下限
Damage.CONTROL_TYPE_ADD_BEFORE_RATE = 3 --基础伤害数值加成
Damage.CONTROL_TYPE_RATE = 4 --基础伤害倍率加成（加法叠加）
Damage.CONTROL_TYPE_SCALE = 5 --伤害倍乘（乘法叠加）
Damage.CONTROL_TYPE_ADD_AFTER_RATE = 6 --最终伤害数值加成


Damage.ApplyDirectDamage = function(targetUnit, amount)
    local life = GetWidgetLife(targetUnit)
    SetWidgetLife(targetUnit, life - amount)
end
-------------------------------------------------------------------------------
---@return Damage
function Damage:new(o, lu_source, lu_target, amount, atktype, dmgtype, eletype)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.source = lu_source
  o.target = lu_target
  o.amount = amount
  o.amount_before_control = amount
  o.atktype = atktype or Damage.ATTACK_TYPE_UNKNOWN
  o.dmgtype = dmgtype or Damage.DAMAGE_TYPE_NORMAL
  o.eletype = eletype or Damage.ELEMENT_TYPE_NONE
  --controls
  o.control_set = nil
  o.control_caption_max = nil
  o.control_caption_min = 0
  o.control_add_before = 0
  o.control_rate = 0 --倍率、加法叠加
  o.control_scale = 1 --倍率、乘法叠加
  o.control_add_after = 0
  o.amount_before_control = o.amount
  return o
end

---@param o Damage
---@return Damage
function Damage:ctor(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.amount_before = o.amount
  return o
end

function Damage:PreApply()
  if (self.dmgtype == Damage.DAMAGE_TYPE_HEAL) then
    
  else
    self.source:OnBeforeDealDamage(self)
    self.target:OnBeforeTakeDamage(self)
  end
  
end

function Damage:Control()
  local amt = self.amount
  if (self.control_add_before ~= nil) then
    amt = amt + self.control_add_before
  end
  if (self.control_rate ~= nil) then
    amt = amt + amt*self.control_rate/100
  end
  if (self.control_scale ~= 1) then
    amt = amt*self.control_scale
  end
  if (self.control_add_after ~= nil) then
    amt = amt + self.control_add_after
  end
  if (self.control_set ~= nil) then
    amt = self.control_set
  end
  if (self.control_caption_max ~= nil) then
    amt = math.min(amt, self.control_caption_max)
  end
  if (self.control_caption_min ~= nil) then
    amt = math.max(amt, self.control_caption_min)
  end
  self.amount = amt
end

function Damage:Apply()
  if (self.dmgtype == Damage.DAMAGE_TYPE_HEAL) then
    Damage.ApplyDirectDamage(self.target.unit, -self.amount)
  else
    self.source:OnStartDealDamage(self)
    self.target:OnStartTakeDamage(self)
    Damage.ApplyDirectDamage(self.target.unit, self.amount)
    self.source:OnDealDamage(self)
    self.target:OnTakeDamage(self)
  end
  
end

function Damage:Resolve()
  self:PreApply()
  self:Control()
  self:Apply()
end

function Damage:Revoke()
  self.amount = self.amount_before
end]=]

P['gameSystem/EntitySystem.lua'] = [[require('utils')

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
end]]

P['gameSystem/LuaUnitSystem.lua'] = [[UnitMgr = {}
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
end]]

P['gameSystem/MapObjectSystem.lua'] = [[require('utils')
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
end]]

P['gameSystem/ModifierSystem.lua'] = [=[---@class Modifier
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

function Modifier:ReinitDuration(v)
    self.max_duration = v
    self.duration = v
end

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

function Modifier:OnStartTakeDamage(damage)
    if (self.settings.OnStartTakeDamage ~= nil) then self.settings.OnStartTakeDamage(self, damage) end
end

function Modifier:OnStartDealDamage(damage)
    if (self.settings.OnStartDealDamage ~= nil) then self.settings.OnStartDealDamage(self, damage) end
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
end]=]

P['gameSystem/ProjectilSystem.lua'] = [[require('utils')
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
        settings = settings
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

---@param victim UnitWrapper
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
end]]

P['gameSystem/Settings.lua'] = [[-- tags
TAG = {}
TAG.STATE = {
    BASE_STUNED = 1000,
    ENLIGHTENED = 1200,
    BIG_ENLIGHTENED = 1201,
    DEEP_SHADOW_CURSE = 1202,
    DEEP_SHADOW_CURSE_GRAND = 1203,
}
TAG.RACE = {
    DEEP_SHADOW = 2000
}
TAG.ETC = {
    STOP_ANIMATION = 9000
}

-- CommonAbilities
CommonAbilitiy = {}
CommonAbilitiy.Invisibility = FourCC('A001')
CommonAbilitiy.AttackSpeed = FourCC('A00J')
CommonAbilitiy.MoveSpeed = FourCC('A00K')
CommonAbilitiy.SightRange = FourCC('A00Q')
CommonAbilitiy.SightRangeTrigger = FourCC('A00R')
CommonAbilitiy.Sleep = FourCC('A00L')
CommonAbilitiy.SleepBuff = FourCC('BUsl')]]

P['gameSystem/UnitDisplaceSystem.lua'] = [[---@class Displace
Displace = {
    velocity = Vector3:new(nil, 0, 0, 0), -- 位移速度
    accelerate = Vector3:new(nil, 0, 0, 0), -- 位移加速度
    max_distance = 0, --位移最大距离
    max_duration = 0, --位移最大时间
    interruptible = true, -- 可否被其他位移打断
    interrupt_action = true, -- 是否打断单位动作
    efx = nil, -- 特效
    efx_interval = CoreTicker.Interval, --特效产生间隔
    Update = nil, -- update callback
    duration = 0,
    distance = 0,
    finished = false,
    finish_when_landed = false,
    OnFinished = nil,
    OnInterrupted = nil,
}
-- 多个位移叠加方法
Displace.OVERLAY_METHOD = {}
Displace.OVERLAY_METHOD.COEXIST = 0 -- 共存
Displace.OVERLAY_METHOD.STOP_EXISTINGS = 1 -- 强制停止其他位移
Displace.OVERLAY_METHOD.STOP_SELF = 2 -- 有其他位移时停止本位移
Displace.OVERLAY_METHOD.STOP_EXISTINGS_IF_FAILED_STOP_SELF = 3 -- 停止已有位移，但如果已有位移不可停止，则停止自身

function Displace:ctor(o)
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
    self.velocity.z = self.velocity.z + self.accelerate.z * CoreTicker.Interval
    self.distance = self.distance + math.sqrt(self.velocity.x * self.velocity.x + self.velocity.y * self.velocity.y) * CoreTicker.Interval
    self.duration = self.duration + CoreTicker.Interval
    self.delta_time = self.delta_time + CoreTicker.Interval
    if (self.max_distance > 0 and self.distance >= self.max_distance) or (self.max_duration > 0 and self.duration >= self.max_duration) then
        self.finished = true
    end
end

function Displace:Finish()
    self.finished = true
end

function Displace:Stop()
    self.finished = true
end]]

P['gameSystem/UnitWrapperSystem.lua'] = [[require('utils')
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
    for _, v in pairs(UnitMgr.Units) do
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

---@class UnitWrapper:Entity
UnitWrapper = Entity:ctor {}

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
    o:InitCommonStats()
    return o
end

function UnitWrapper:InitCommonAbilities()
    if (GetUnitAbilityLevel(self.unit, CommonAbilitiy.AttackSpeed) < 1) then
        UnitAddAbility(self.unit, CommonAbilitiy.AttackSpeed)
    end
    self.CommonAbilities = {}
    self.CommonAbilities.attack_speed = BlzGetUnitAbility(self.unit, CommonAbilitiy.AttackSpeed)
end

function UnitWrapper:GetBonusAttackSpeed()
    return BlzGetAbilityRealLevelField(self.CommonAbilities.attack_speed, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0)
end

function UnitWrapper:AddAttackSpeed(value)
    BlzSetAbilityRealLevelField(self.CommonAbilities.attack_speed, ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1, 0,
        self:GetBonusAttackSpeed() + value)
    IncUnitAbilityLevel(self.unit, CommonAbilitiy.AttackSpeed)
    DecUnitAbilityLevel(self.unit, CommonAbilitiy.AttackSpeed)
end

function UnitWrapper:InitCommonStats()
    self.CommonStats = {
        movespeed = GetUnitDefaultMoveSpeed(self.unit)
    }
    self.CommonStatsBonus = {
        movespeed = 0
    }
end

function UnitWrapper:UpdateCommonStats()
    self:UpdateCommonStatsBonus()
    --movespeed
    SetUnitMoveSpeed(self.unit, self.CommonStats.movespeed + (self.CommonStatsBonus.movespeed or 0))
end

function UnitWrapper:UpdateCommonStatsBonus()
    self.CommonStatsBonus = {}
    for i = #(self.modifiers), 1, -1 do
        local mod = self.modifiers[i]
        for k, v in pairs(mod.CommonStatsBonus) do
            self.CommonStatsBonus[k] = (self.CommonStatsBonus[k] or 0) + v
        end
    end
end

function UnitWrapper:AddHP(v)
    SetUnitState(self.unit, UNIT_STATE_LIFE, GetUnitState(self.unit, UNIT_STATE_LIFE) + v)
end
function UnitWrapper:AddHPRate(r)
    local hp = GetUnitState(self.unit, UNIT_STATE_LIFE)
    SetUnitState(self.unit, UNIT_STATE_LIFE, hp + hp * r/100)
end

function UnitWrapper:DeadQ()
    return IsUnitType(self.unit, UNIT_TYPE_DEAD)
end

function UnitWrapper:InitGravityDisplace()
    self.gravityDisplace = Displace:ctor {
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
    self:UpdateCommonStats()
end

function UnitWrapper:EnableHeightChange()
    if (self.height_change_enabled ~= true) then
        UnitAddAbility(self.unit, FourCC('Arav'))
        UnitRemoveAbility(self.unit, FourCC('Arav'))
        self.height_change_enabled = true
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
            if (d.finish_when_landed and z - Entity.GetLocationZ(x, y) <= self.defaultFlyHeight) then
                d:Finish()
            end
        end
    end
    local height = z - Entity.GetLocationZ(x, y)
    if height > self.defaultFlyHeight + 1 then
        x, y, z = self.gravityDisplace:Calc(x, y, z)
    else
        self.gravityDisplace.velocity.z = 0
        z = Entity.GetLocationZ(x, y) + self.defaultFlyHeight
    end
    SetUnitX(self.unit, x)
    SetUnitY(self.unit, y)
    self:EnableHeightChange()
    SetUnitFlyHeight(self.unit, z - Entity.GetLocationZ(x, y), 0)
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
    for k, v in pairs(self.modifiers) do
        if v.id == mid then
            return true
        end
    end
    return false
end

---@return Modifier|nil
function UnitWrapper:GetAffectedModifier(mid)
    for _, v in pairs(self.modifiers) do
        if v.id == mid then
            return v
        end
    end
    return nil
end

function UnitWrapper:GetAffectedModifierIndex(mid)
    for i, v in ipairs(self.modifiers) do
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
    for _, m in ipairs(self.modifiers) do
        if m.tags[tag] ~= nil then
            return true
        end
    end
    return false
end

function UnitWrapper:OnDeath()
    for _, m in pairs(self.modifiers) do
        m:OnDeath()
    end
end

function UnitWrapper:OnBeforeDealDamage(damage)
    for _, m in pairs(self.modifiers) do
        m:OnBeforeDealDamage(damage)
    end
end

function UnitWrapper:OnBeforeTakeDamage(damage)
    for _, m in pairs(self.modifiers) do
        m:OnBeforeTakeDamage(damage)
    end
end

function UnitWrapper:OnStartDealDamage(damage)
    for _, m in pairs(self.modifiers) do
        m:OnStartDealDamage(damage)
    end
end

function UnitWrapper:OnStartTakeDamage(damage)
    for _, m in pairs(self.modifiers) do
        m:OnStartTakeDamage(damage)
    end
end

function UnitWrapper:OnDealDamage(damage)
    for _, m in pairs(self.modifiers) do
        m:OnDealDamage(damage)
    end
end

function UnitWrapper:OnTakeDamage(damage)
    for _, m in pairs(self.modifiers) do
        m:OnTakeDamage(damage)
    end
end

---@return number
function UnitWrapper:GetX()
    return GetUnitX(self.unit)
end

---@return number
function UnitWrapper:GetY()
    return GetUnitY(self.unit)
end

---@param uw UnitWrapper
---@return number
function UnitWrapper:DistanceToUnit(uw)
    local dx = uw:GetX() - self:GetX()
    local dy = uw:GetY() - self:GetY()
    return math.sqrt(dx * dx + dy * dy)
end

---@return boolean
function UnitWrapper:OnDeepWaterQ()
    if self:IsModifierTypeAffected('ON_DEEP_WATER_FAKE') then return true end
    local x = self:GetX()
    local y = self:GetY()
    if not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) then
        if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            return false
        else
            return true
        end
    end
    return false
end

---@return boolean
function UnitWrapper:OnShallowWaterQ()
    if self:IsModifierTypeAffected('ON_SHALLOW_WATER_FAKE') then return true end
    local x = self:GetX()
    local y = self:GetY()
    if not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) then
        if not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
            return true
        else
            return false
        end
    end
    return false
end

---@return boolean
function UnitWrapper:OnWaterQ()
    if self:IsModifierTypeAffected('ON_SHALLOW_WATER_FAKE') or self:IsModifierTypeAffected('ON_DEEP_WATER_FAKE') then return true end
    local x = self:GetX()
    local y = self:GetY()
    if not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) then
        return true
    end
    return false
end]]

P['gameSystem/init.lua'] = [[require('gameSystem.Settings')
require('gameSystem.DamageSystem')
require('gameSystem.UnitDisplaceSystem')
require('gameSystem.UnitWrapperSystem')
require('gameSystem.ModifierSystem')
require('gameSystem.ProjectilSystem')
require('gameSystem.MapObjectSystem')


--远程角色普攻弹道模拟、普攻伤害模拟
do
    local RangedAttackTrigger = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(RangedAttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    local cond = Condition(function()
        return IsUnitType(GetAttacker(),UNIT_TYPE_RANGED_ATTACKER) == true
    end)
    TriggerAddCondition(RangedAttackTrigger, cond)
    TriggerAddAction(RangedAttackTrigger, function()
        local u = GetAttacker()
        if (Master.DefaultAttackProjectil[GetUnitTypeId(u)]==nil) then
            local settings = {
                model = BlzGetUnitWeaponStringField(u, UNIT_WEAPON_SF_ATTACK_PROJECTILE_ART, 0),
                speed = BlzGetUnitWeaponRealField(u, UNIT_WEAPON_RF_ATTACK_PROJECTILE_SPEED, 0),
                no_gravity = false,
                hit_range = 25,
                hit_terrain = true,
                hit_other = false,
                hit_ally = true,
                hit_piercing = false,
                hit_cooldown = 1,
                track_type = Projectil.TRACK_TYPE_UNIT,
                tracking_angle = 60 * math.degree,
                turning_speed = 60 * math.degree,
                turning_speed_pitch = 3 * math.degree,
                max_flying_distance = 3000,
                offsetX = 0,
                offsetY = 60,
                offsetZ = 60,
                Hit = nil
            }
            Master.DefaultAttackProjectil[GetUnitTypeId(u)] = settings
            print('弹道初始化')
        end
        BlzSetUnitWeaponStringField(u, UNIT_WEAPON_SF_ATTACK_PROJECTILE_ART, 0,'')
        BlzSetUnitWeaponRealField(u, UNIT_WEAPON_RF_ATTACK_PROJECTILE_SPEED, 0,99999)
    end)

    
    local RangeAttackDamageTrigger = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(RangeAttackDamageTrigger, EVENT_PLAYER_UNIT_DAMAGED)
    local cond2 = Condition(function() 
        if BlzGetEventIsAttack() == true then
            local uw = UnitWrapper.Get(GetEventDamageSource())
            local target = GetTriggerUnit()
            if (Master.DefaultAttackProjectil[GetUnitTypeId(uw.unit)]~=nil) then 
                ProjectilMgr.CreateAttackProjectil(uw,target,GetEventDamage())
                BlzSetEventDamage(0)
            else
                local dmg = Damage:new(nil, uw, UnitWrapper.Get(target), GetEventDamage(), Damage.ATTACK_TYPE_MELEE)
                BlzSetEventDamage(0)
                dmg:Resolve()
            end
        end
        return false
    end)
    TriggerAddCondition(RangeAttackDamageTrigger, cond2)
end]]

P['lib/init.lua'] = [[]]

P['main.lua'] = [[require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')
require('ui')

CoreTicker.Init()

local fogM = CreateFogModifierRect(Player(0), FOG_OF_WAR_VISIBLE, GetPlayableMapRect(), true, false)
FogModifierStart(fogM)


local v = CreateUnit(Player(0), FourCC('Hjai'), 0, 90, 293)
local w = UnitWrapper.Get(v)
BlzSetUnitMaxHP(v, 3000)
SetUnitState(v, UNIT_STATE_LIFE, 3000)

local hfoo = CreateUnit(Player(0), FourCC('hfoo'), 0, 90, 293)
UnitWrapper.Get(hfoo):AcquireModifierById('PROTECTOR_TARGET', w)

local asara = CreateUnit(Player(0), FourCC('H002'), 0, 90, 293)



UnitAddAbility(v, FourCC('A003'))
UnitAddAbility(v, AbilityScripts.ICE_KNIFE.AbilityId)
UnitAddAbility(v, AbilityScripts.ICE_WALL.AbilityId)
UnitAddAbility(v, AbilityScripts.FROZEN_MAGIC_SPHERE.AbilityId)
UnitAddAbility(v, AbilityScripts.HELICOPTER_FALL.AbilityId)
AbilityScripts.AddAbilityWithIntrinsecModifier(v, Master.Modifier.FREEZING_REALM.BindAbility)

--AbilityScripts.AddAbilityWithIntrinsecModifier(red_dragon, Master.Modifier.RED_DRAGON_ENVIRONMENT.BindAbility)
UnitAddAbility(asara, FourCC('A012'))]]

P['master/MasterBase.lua'] = [[Master = {}]]

P['master/Modifiers.lua'] = [=[require('utils')
require('master.MasterBase')
require('gameSystem.ModifierSystem')

Master.Modifier = {}

Master.Modifier.SHOW_ORDER_STRING = {
    id = 'SHOW_ORDER_STRING',
    duration = -1,
    interval = 0.1,
    Effects = {{
        model = 'Abilities\\Spells\\Human\\ManaFlare\\ManaFlareTarget.mdl',
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Update = function(this)
        local id = GetUnitCurrentOrder(this.owner.unit)
        local s = OrderId2String(id)
        print(GetUnitName(this.owner.unit), ' current order: ', id, ', ', s)
    end
}
Master.Modifier.LIFE_BY_ATTACK_TIME = {
    id = 'LIFE_BY_ATTACK_TIME',
    icon = [[ReplaceableTextures\CommandButtons\BTNSelectHeroOff.blp]],
    title = '计数生命',
    description = '这个单位受到的持续伤害变为0，其他伤害变为1点',
    duration = -1,
    interval = 1,
    strength = 10,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    Effects = {},
    ---@param damage Damage
    OnBeforeTakeDamage = function(this, damage)
        if (damage.dmgtype == Damage.DAMAGE_TYPE_DOT) then
            damage.control_set = 0
        else
            damage.control_set = 1
        end
    end
}
Master.Modifier.ON_SHALLOW_WATER_FAKE = {
    id = 'ON_SHALLOW_WATER_FAKE',
    hidden = true,
    duration = 0.2,
    interval = 0.1,
    strength = 10,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {},
}
Master.Modifier.ON_DEEP_WATER_FAKE = {
    id = 'ON_DEEP_WATER_FAKE',
    hidden = true,
    duration = 0.2,
    interval = 0.1,
    strength = 10,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {},
}

Master.Modifier.STUN = {
    id = 'STUN',
    icon = [[ReplaceableTextures\CommandButtons\BTNStun.blp]],
    title = '眩晕',
    description = '这个单位眩晕了，无法行动',
    duration = 3,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.COEXIST,
    Effects = {{
        model = [[Abilities\Spells\Human\Thunderclap\ThunderclapTarget.mdl]],
        attach_point = 'overhead'
    }},
    tags = {TAG.STATE.BASE_STUNED},
    ---@param this Modifier
    OnAcquired = function(this)
        BlzPauseUnitEx(this.owner.unit, true)
        IssueImmediateOrderById(this.owner.unit, 851973)
    end,
    ---@param this Modifier
    OnRemoved = function(this)
        if (not this.owner:HasTag(TAG.STATE.BASE_STUNED)) then
            IssueImmediateOrderById(this.owner.unit, 851973)
            BlzPauseUnitEx(this.owner.unit, false)
        end
    end
}

Master.Modifier.FROZEN = {
    id = 'FROZEN',
    icon = [[ReplaceableTextures\CommandButtons\BTNFrozen.dds]],
    title = '冻结',
    description = '这个单位被冻结了，无法行动',
    duration = 3,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REMOVE_OLD,
    Effects = {{
        model = [[Effects\IceCube.mdx]],
        attach_point = 'origin'
    }},
    tags = {TAG.STATE.BASE_STUNED, TAG.ETC.STOP_ANIMATION},
    ---@param this Modifier
    OnAcquired = function(this)
        BlzPauseUnitEx(this.owner.unit, true)
        IssueImmediateOrderById(this.owner.unit, 851973)
        SetUnitTimeScale(this.owner.unit, 0)
    end,
    ---@param this Modifier
    OnRemoved = function(this)
        if (not this.owner:HasTag(TAG.STATE.BASE_STUNED)) then
            IssueImmediateOrderById(this.owner.unit, 851973)
            BlzPauseUnitEx(this.owner.unit, false)
        end
        if (not this.owner:HasTag(TAG.ETC.STOP_ANIMATION)) then
            SetUnitTimeScale(this.owner.unit, 1)
        end
    end
}]=]

P['master/Projectils.lua'] = [[require('utils')
require('master.MasterBase')
require('gameSystem.ProjectilSystem')
Master.Projectil = {}
Master.DefaultAttackProjectil = {}


Master.Projectil.Test = {
    model = 'Abilities\\Weapons\\LichMissile\\LichMissile.mdl', --子弹模型
    speed = 900, --速率
    no_gravity = true, --是否无视重力
    hit_range = 50, --命中检测范围（水平）
    hit_terrain = true, --是否命中地形（若是，子弹会被地面、高坡、悬崖等阻挡）
    hit_other = true, --是否能命中目标以外单位
    hit_ally = false, --是否能命中友军
    hit_piercing = false, --是否穿透（命中单位后继续飞行）
    hit_cooldown = 1, --同一单位命中间隔（仅对穿透弹道生效，防止同一个单位一直被判定命中）
    track_type = Projectil.TRACK_TYPE_POSITION, --追踪类型：无/追踪目标单位/追踪目标点
    tracking_angle = 60 * math.degree, --最大追踪角度（水平），当目标不在子弹前方该角度的扇形区域时，丢失追踪效果
    turning_speed = 60 * math.degree, --最大转向速度（弧度/秒）
    max_flying_distance = 1500, --最大飞行距离
    
    offsetX = 11, --发射点偏移
    offsetY = 62,
    offsetZ = 71,
    Hit = nil --命中时额外调用函数
}
Master.Projectil.Test2 = {
    model = 'Abilities\\Weapons\\SentinelMissile\\SentinelMissile.mdl', --子弹模型
    velocity = 100, --水平（XY轴）弹道速度
    velocityZ = 0, --Z轴初始速度
    velocityZMax = 9999, --最大Z轴速度绝对值
    no_gravity = true, --是否无视重力
    hit_range = 50, --命中检测范围（水平）
    hit_rangeZ = 60, --若为true,在命中判定时，会额外考虑子弹和目标的Z轴坐标
    hit_terrain = true, --是否命中地形（若是，子弹会被地面、高坡、悬崖等阻挡）
    hit_other = true, --是否能命中目标以外单位
    hit_ally = false, --是否能命中友军
    hit_piercing = false, --是否穿透（命中单位后继续飞行）
    hit_cooldown = 1, --同一单位命中间隔（仅对穿透弹道生效，防止同一个单位一直被判定命中）
    track_type = Projectil.TRACK_TYPE_POSITION, --追踪类型：无/追踪目标单位/追踪目标点
    trackZ = true, --是否Z轴追踪（根据目标高度调整子弹竖直方向速度）
    tracking_angle = 60 * math.degree, --最大追踪角度角度（水平），当目标不在子弹前方该角度的扇形区域时，丢失追踪效果
    turning_speed = 60 * math.degree, --最大转向速度（弧度/秒）
    max_flying_distance = 1500, --最大飞行距离
    offsetX = 11, --发射点偏移
    offsetY = 62,
    offsetZ = 71,
    Hit = nil --命中时额外调用函数
}]]

P['master/init.lua'] = [[require('master.MasterBase')
require('master.Modifiers')
require('master.Projectils')]]

P['scripts/101FireWork.lua'] = [=[
AbilityScripts.NATIONALDAY_FIREWORK = {
    AbilityId = FourCC('A00P'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tloc = Vector3:ctor {
            x = GetSpellTargetX(),
            y = GetSpellTargetY(),
        }
        tloc.z = Projectil.GetLocationZ(tloc.x, tloc.y) + 900
        Projectil:ctor {
            emitter = caster,
            target_position = tloc,
            settings = Master.Projectil.FIREWORK_TARGET
        }
    end
}

NATIONALDAY_FIREWORKS = {
    ---@param this Projectil
    Flower = function(this, settings)
        local d = 10
        for xyi = 0,360,30 do
            for zi = -90,90,15 do
                local tloc = Vector3:ctor {
                    x = this.position.x + d*Cos(zi*math.degree)*Cos(xyi*math.degree),
                    y = this.position.y + d*Cos(zi*math.degree)*Sin(xyi*math.degree),
                    z = this.position.z + d*Sin(zi*math.degree)
                }
                Projectil:ctor {
                    emitter = this.emitter,
                    x = this.position.x,
                    y = this.position.y,
                    z = this.position.z,
                    target_position = tloc,
                    settings = settings
                }
            end
        end 
    end,
    Spin = function(this, spinAngle, settings)
        local d = 10
        local tloc = Vector3:ctor {
            x = this.position.x + d*Cos(spinAngle),
            y = this.position.y + d*Sin(spinAngle),
            z = this.position.z
        }
        Projectil:ctor {
            emitter = this.emitter,
            x = this.position.x,
            y = this.position.y,
            z = this.position.z,
            target_position = tloc,
            settings = settings
        }
        local tloc2 = Vector3:ctor {
            x = this.position.x + d*Cos(spinAngle + math.pi),
            y = this.position.y + d*Sin(spinAngle + math.pi),
            z = this.position.z
        }
        Projectil:ctor {
            emitter = this.emitter,
            x = this.position.x,
            y = this.position.y,
            z = this.position.z,
            target_position = tloc2,
            settings = settings
        }
    end,
    Tree = function(this, settings)
        local d = 10
        for angle = 0,2*math.pi,2*math.pi/36 do
            local tloc = Vector3:ctor {
                x = this.position.x + d*Cos(angle),
                y = this.position.y + d*Sin(angle),
                z = this.position.z
            }
            Projectil:ctor {
                emitter = this.emitter,
                x = this.position.x,
                y = this.position.y,
                z = this.position.z,
                target_position = tloc,
                settings = settings
            }
        end
    end,
    Tail = function(this, model)
        local p = Projectil:ctor {
            emitter = this.emitter,
            x = this.position.x,
            y = this.position.y,
            z = this.position.z,
            settings = Master.Projectil.FIREWORK_TAIL
        }
        if (model ~= nil) then p:ChangeModel(model) end
    end
}

Master.Projectil.FIREWORK_TARGET = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]], -- 模型
    model_scale = 1, --模型缩放
    speed = 1600,  --初始速率
    no_gravity = false, --是否无视重力
    hit_range = 25, --命中监测方位
    hit_terrain = true, --是否会被地形阻挡
    hit_other = false, --是否会命中目标以外单位
    hit_ally = false, --是否会命中队友
    hit_piercing = false, --是否穿透（命中单位后是否会消失）
    hit_cooldown = 1, --同一单位命中时间间隔（对于穿透弹道，防止命中同一单位N次）
    track_type = Projectil.TRACK_TYPE_POSITION, --追踪类型（追踪点/追踪单位/无追踪）
    tracking_angle = 360 * math.degree, --追踪角度，目标不在角度范围内时，丢失追踪效果
    turning_speed = 360 * math.degree, -- 水平转向速度
    turning_speed_pitch = 360 * math.degree, -- 垂直转向速度
    max_flying_distance = 15000, --最大飞行距离
    offsetX = 0,
    offsetY = 0,
    offsetZ = 50,
    ---@param this Projectil
    OnHit = function(this) -- 命中时调用的函数
        NATIONALDAY_FIREWORKS.Flower(this,Master.Projectil.FIREWORK_SECONDARY)
    end
}

Master.Projectil.FIREWORK_SECONDARY = {
    -- 红龙 [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    -- 丛林守护者 [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    -- 绿龙 [[Abilities\Weapons\GreenDragonMissile\GreenDragonMissile.mdl]]
    -- 石像鬼 [[Abilities\Weapons\GargoyleMissile\GargoyleMissile.mdl]]
    -- 水元素 [[Abilities\Weapons\WaterElementalMissile\WaterElementalMissile.mdl]]
    model = [[Abilities\Weapons\GreenDragonMissile\GreenDragonMissile.mdl]],
    model_scale = 0.5,
    speed = 900, 
    no_gravity = false,
    hit_range = 25,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 60 * math.degree,
    max_flying_distance = 15000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    OnHit = nil,
}

Master.Projectil.FIREWORK_NO_TARGET = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    model_scale = 1,
    speed = 1200, 
    no_gravity = false,
    hit_range = 25,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 60 * math.degree,
    max_flying_distance = 3600,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 50,
    ---@param this Projectil
    OnCreate = function(this)
        this.CustomValues.SpinAngle = 0
    end,
    ---@param this Projectil
    Update = function(this, delta)
        NATIONALDAY_FIREWORKS.Spin(this, this.CustomValues.SpinAngle, Master.Projectil.FIREWORK_SECONDARY)
        --NATIONALDAY_FIREWORKS.Tree(this, Master.Projectil.FIREWORK_SECONDARY)
        this.CustomValues.SpinAngle = this.CustomValues.SpinAngle + 12*math.degree
    end
}

Master.Projectil.FIREWORK_TAIL = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    model_scale = 0.5,
    speed = 0, 
    no_gravity = false,
    hit_range = 25,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 60 * math.degree,
    max_flying_distance = 15000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    OnHit = nil,
}]=]

P['scripts/DeepShadow.lua'] = [=[require('gameSystem')
require('master')

Master.DefaultAttackProjectil[FourCC('H000')] = {
    model = [[Abilities\Weapons\BansheeMissile\BansheeMissile.mdl]],
    velocity = 900,
    velocityZ = 0,
    velocityZMax = 99999,
    no_gravity = true,
    hit_range = 50,
    hit_rangeZ = 60,
    hit_terrain = true,
    hit_other = false,
    hit_ally = true,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_UNIT,
    trackZ = true,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 60,
    offsetZ = 60,
    Hit = nil
}

Master.Modifier.DEEP_SHADOW_CREATURE = {
    id = 'DEEP_SHADOW_CREATURE',
    duration = -1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    stack = 1,
    remove_on_death = false,
    tags = {TAG.RACE.DEEP_SHADOW},
    Effects = {},
    ---@param this Modifier
    Update = function(this)
        if this.owner:IsModifierTypeAffected('DEEP_SHADOW_CURSE') then
            if not (GetUnitAbilityLevel(this.owner.unit, CommonAbilitiy.Invisibility) > 0) then
                UnitAddAbility(this.owner.unit, CommonAbilitiy.Invisibility)
            end
        elseif GetUnitAbilityLevel(this.owner.unit, CommonAbilitiy.Invisibility) > 0 then
            UnitRemoveAbility(this.owner.unit, CommonAbilitiy.Invisibility)
        end
    end
}

Master.Modifier.DEEP_SHADOW_CREATURE_TEMP = {
    id = 'DEEP_SHADOW_CREATURE_TEMP',
    duration = -1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    stack = 1,
    remove_on_death = true,
    tags = {TAG.RACE.DEEP_SHADOW},
    Effects = {},
    ---@param this Modifier
    Update = function(this)
        if this.owner:IsModifierTypeAffected('DEEP_SHADOW_CURSE') then
            if not (GetUnitAbilityLevel(this.owner.unit, CommonAbilitiy.Invisibility) > 0) then
                UnitAddAbility(this.owner.unit, CommonAbilitiy.Invisibility)
            end
        elseif GetUnitAbilityLevel(this.owner.unit, CommonAbilitiy.Invisibility) > 0 then
            UnitRemoveAbility(this.owner.unit, CommonAbilitiy.Invisibility)
        end
    end
}

Master.Modifier.DEEP_SHADOW_CURSE  = {
    id = 'DEEP_SHADOW_CURSE',
    duration = 2,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.STACK_AND_REFRESH,
    stack = 1,
    max_stack = 10,
    Effects = {{
        model = [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]],
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Update = function(this)
        if (this.owner:HasTag(TAG.STATE.ENLIGHTENED) and not this.owner:HasTag(TAG.STATE.DEEP_SHADOW_CURSE_GRAND)) or this.owner:HasTag(TAG.STATE.BIG_ENLIGHTENED) then 
            this:Remove()
            return 
        end
        this.effects_scale = this.stack * 0.2 + 1
        if (not this.owner:HasTag(TAG.RACE.DEEP_SHADOW)) then
            local life = GetWidgetLife(this.owner.unit)
            SetWidgetLife(this.owner.unit, life - 5*this.stack)
        end
    end
}

Master.Modifier.DEEP_SHADOW_CURSE_PROVIDER = {
    id = 'DEEP_SHADOW_CURSE_PROVIDER',
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A000'),
    LevelValues = {
        Range = {900,900,900,900}
    },
    Acquire = function(this) 
        this.apply_checker_group = CreateGroup()
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function() return
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and 
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_STRUCTURE)) and
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_MECHANICAL))
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        ForGroup(this.apply_checker_group, function()
            local lu = LuaUnit.Get(GetEnumUnit())
            if (not lu:HasTag(TAG.STATE.BIG_ENLIGHTENED)) and (lu:HasTag(TAG.STATE.DEEP_SHADOW_CURSE_GRAND) or (not lu:HasTag(TAG.STATE.ENLIGHTENED))) then 
                this.owner:ApplyModifier(Master.Modifier.DEEP_SHADOW_CURSE, lu, this.ability)
            end
        end)
    end,
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
    end
}

Master.Modifier.DEEP_SHADOW_CURSE_GRAND  = {
    id = 'DEEP_SHADOW_CURSE_GRAND',
    duration = 1.1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    stack = 1,
    Effects = {},
    tags = {TAG.STATE.DEEP_SHADOW_CURSE_GRAND}, 
    ---@param this Modifier
    Update = function(this)
        if this.owner:HasTag(TAG.STATE.BIG_ENLIGHTENED) then 
            this:Remove()
            return
        end
    end
}

Master.Modifier.DEEP_SHADOW_CURSE_GRAND_PROVIDER = {
    id = 'DEEP_SHADOW_CURSE_GRAND_PROVIDER',
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A000'),
    LevelValues = {
        Range = {150,200,250,300}
    },
    Acquire = function(this) 
        this.apply_checker_group = CreateGroup()
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function() return
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and 
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_STRUCTURE)) and
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_MECHANICAL))
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        ForGroup(this.apply_checker_group, function()
            local lu = LuaUnit.Get(GetEnumUnit())
            if not lu:HasTag(TAG.STATE.BIG_ENLIGHTENED) then 
                this.owner:ApplyModifier(Master.Modifier.DEEP_SHADOW_CURSE_GRAND, lu, this.ability)
            end
        end)
    end,
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
    end
}

Master.Modifier.ENLIGHTENED = {
    id = 'ENLIGHTENED',
    duration = 3,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {{
        model = [[Abilities\Spells\Human\InnerFire\InnerFireTarget.mdl]],
        attach_point = 'overhead'
    }},
    tags = {TAG.STATE.ENLIGHTENED}
}

Master.Modifier.ENLIGHTENED_PROVIDER = {
    id = 'ENLIGHTENED_PROVIDER',
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A002'),
    LevelValues = {
        Range = {500,500,500,500}
    },
    Acquire = function(this) 
        this.apply_checker_group = CreateGroup()
    end,
    Update = function(this)
        local cond = Condition(function() return
            (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and (not IsUnitType(GetFilterUnit(), UNIT_TYPE_STRUCTURE))
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        ForGroup(this.apply_checker_group, function()
            local u = GetEnumUnit()
            this.owner:ApplyModifier(Master.Modifier.ENLIGHTENED, LuaUnit.Get(u), this.ability)
        end)
    end,
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
    end
}

-- 暗影汲取
AbilityScripts.SHADOW_DRAIN = {
    AbilityId = FourCC('A005'),
    Cast = function()
        local caster = LuaUnit.Get(GetTriggerUnit())
        local target = GetSpellTargetUnit()
        local level = GetUnitAbilityLevel(caster.unit, AbilityScripts.SHADOW_DRAIN.AbilityId)
        local prjt = ProjectilMgr.CreateProjectilById('SHADOW_DRAIN', caster, target, pos, {})
        prjt:SetXYZ(GetUnitX(target), GetUnitY(target))
        prjt:SetTarget(caster.unit)
        local drain_value = 60 * level
        if (LuaUnit.Get(target):IsModifierTypeAffected('DEEP_SHADOW_CURSE')) then
            drain_value = drain_value * 2
        end
        local dmg = Damage:new(nil, caster, LuaUnit.Get(target), drain_value,
        Damage.ATTACK_TYPE_SPELL,Damage.DAMAGE_TYPE_NORMAL,Damage.ELEMENT_TYPE_BIO)
        dmg:Resolve()
        prjt.TempValues.drain_value = drain_value
    end
}

Master.Projectil.SHADOW_DRAIN = {
    model = [[Abilities\Spells\Undead\DarkSummoning\DarkSummonMissile.mdl]],
    velocity = 800,
    velocityZ = 0,
    velocityZMax = 99999,
    no_gravity = true,
    hit_range = 50,
    hit_rangeZ = 60,
    hit_terrain = false,
    hit_other = false,
    hit_ally = true,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_UNIT,
    trackZ = true,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 60,
    LevelValues = {},
    ---@param this Projectil
    ---@param victim LuaUnit
    Hit = function(this, victim)
        local heal = Damage:new(nil, victim, victim, this.TempValues.drain_value, 
        nil, Damage.DAMAGE_TYPE_HEAL, nil)
        heal:Resolve()
    end
}

-- 幽影转化
--[[
当对敌方单位使用时，若目标生命值小于其幽影诅咒层数*20/30/40/50，
则直接杀死目标单位，并在其位置召唤一个幽影仆从；否则对目标造成相应的伤害
对友军单位使用时，使友军单位临时变成幽影生物（死亡时失效）
--]]
AbilityScripts.SHADOW_CONVERT = {
    AbilityId = FourCC('A008'),
    ThresholdLifePerStack = {20, 30, 40, 50},
    Cast = function()
        local u = GetTriggerUnit()
        local v = GetSpellTargetUnit()
        local level = GetUnitAbilityLevel(u, AbilityScripts.SHADOW_CONVERT.AbilityId)
        if (IsUnitEnemy(v, GetOwningPlayer(u))) then
            local mod = LuaUnit.Get(v):GetAffectedModifier('DEEP_SHADOW_CURSE')
            local count
            if (mod ~= nil) then count = mod.stack 
            else count = 0 end
            local life = GetUnitState(v, UNIT_STATE_LIFE)
            if (life <= count * AbilityScripts.SHADOW_CONVERT.ThresholdLifePerStack[level]) then
                KillUnit(v)
                CreateUnit(GetOwningPlayer(u), FourCC('h001'), GetUnitX(v), GetUnitY(v), 0)
            else
                local dmg = Damage:new(nil, LuaUnit.Get(u), LuaUnit.Get(v), 
                count * AbilityScripts.SHADOW_CONVERT.ThresholdLifePerStack[level], 
                Damage.ATTACK_TYPE_SPELL, Damage.DAMAGE_TYPE_NORMAL, Damage.ELEMENT_TYPE_BIO)
                dmg:Resolve()
            end
        else
            -- set temp shadow
            LuaUnit.Get(v):AcquireModifierById('DEEP_SHADOW_CREATURE_TEMP')
        end
    end
}

-- 幽影统领
--[[
清空周围所有单位的幽影诅咒效果，每有1层，为自己提高1点全属性
--]]

AbilityScripts.SHADOW_COMMAND = {
    AbilityId = FourCC('A007'),
    Cast = function()
        local caster = LuaUnit.Get(GetTriggerUnit())
        local cond = Condition(function()
            local u = LuaUnit.Get(GetFilterUnit())
            return u ~= caster and u:IsModifierTypeAffected('DEEP_SHADOW_CURSE')
        end)
        local g = CreateGroup()
        GroupEnumUnitsInRange(g, GetUnitX(caster.unit), GetUnitY(caster.unit), 900, cond)
        ForGroup(g, function()
            local u = LuaUnit.Get(GetEnumUnit())
            local prjt = ProjectilMgr.CreateProjectilById('SHADOW_COMMAND', caster, u.unit, nil, {})
            prjt:SetXYZ(GetUnitX(u.unit), GetUnitY(u.unit))
            prjt:SetTarget(caster.unit)
            local mod = u:GetAffectedModifier('DEEP_SHADOW_CURSE')
            prjt.TempValues.stack = mod.stack
            mod:Remove()
        end)
        DestroyGroup(g)
    end
}

Master.Projectil.SHADOW_COMMAND = {
    model = [[Abilities\Weapons\AvengerMissile\AvengerMissile.mdl]],
    velocity = 800,
    velocityZ = 0,
    velocityZMax = 99999,
    no_gravity = true,
    hit_range = 50,
    hit_rangeZ = 60,
    hit_terrain = false,
    hit_other = false,
    hit_ally = true,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_UNIT,
    trackZ = true,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 60,
    LevelValues = {},
    ---@param this Projectil
    ---@param victim LuaUnit
    Hit = function(this, victim)
        local mod = victim:GetAffectedModifier('SHADOW_COMMAND')
        if mod ~= nil then
            mod:AddStack(this.TempValues.stack)
        else
            victim:AcquireModifierById('SHADOW_COMMAND', victim, FourCC('A007'))
            victim:GetAffectedModifier('SHADOW_COMMAND'):AddStack(this.TempValues.stack)
        end
    end
}

Master.Modifier.SHADOW_COMMAND = {
    id = 'SHADOW_COMMAND',
    duration = 15,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.STACK,
    stack = 1,
    max_stack = 999,
    Effects = {{
        model = [[Abilities\Spells\Undead\Darksummoning\DarkSummonTarget.mdl]],
        attach_point = 'origin'
    }},
    BindAbility = FourCC('A007'),
    LevelValues = {
        Range = {500,500,500,500}
    },
    Acquire = function(this) 
        UnitAddAbility(this.owner.unit, FourCC('A009'))
    end,
    Update = function(this)
        local a = BlzGetUnitAbility(this.owner.unit, FourCC('A009'))
        IncUnitAbilityLevel(this.owner.unit, FourCC('A009'))
        BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_STRENGTH_BONUS_ISTR, 0, this.stack)
        BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_INTELLIGENCE_BONUS, 0, this.stack)
        BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_AGILITY_BONUS, 0, this.stack)
        DecUnitAbilityLevel(this.owner.unit, FourCC('A009'))
    end,
    Remove = function(this)
        UnitRemoveAbility(this.owner.unit, FourCC('A009'))
    end
}]=]

P['scripts/ElectronLord.lua'] = [=[require('gameSystem')
require('master')

-- 带电
Master.Modifier.ELECTRON_CHARGED = {
    id = 'ELECTRON_CHARGED',
    duration = 30,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    stack = 1,
    remove_on_death = true,
    tags = {},
    Effects = {{
        model = [[Abilities\Weapons\FarseerMissile\FarseerMissile.mdl]],
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Acquire = function(this)
        this.is_positive_charge = true
        this.lightnings = {}
        this.max_distance = 600
        this.apply_checker_group = CreateGroup()
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function() 
            local lu = LuaUnit.Get(GetFilterUnit())
            if (lu.unit == this.owner.unit) then return false end
            if (lu:IsModifierTypeAffected('ELECTRON_CHARGED')) then
                if (this.lightnings[lu.uuid] == nil) then
                    this.lightnings[lu.uuid] = {
                        rival = lu
                    }
                    if (lu:GetAffectedModifier('ELECTRON_CHARGED').is_positive_charge == this.is_positive_charge) then
                        this.lightnings[lu.uuid].lightning = AddLightningEx('CLPB', false, 
                            GetUnitX(this.owner.unit), 
                            GetUnitY(this.owner.unit), 
                            0,
                            GetUnitX(lu.unit), 
                            GetUnitY(lu.unit),
                            0
                        )
                    else
                        this.lightnings[lu.uuid].lightning = AddLightningEx('AFOD', false, 
                            GetUnitX(this.owner.unit), 
                            GetUnitY(this.owner.unit), 
                            0,
                            GetUnitX(lu.unit), 
                            GetUnitY(lu.unit),
                            0
                        )
                    end
                    
                end
            end
            return false
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, 
            GetUnitX(this.owner.unit), 
            GetUnitY(this.owner.unit), 
            this.max_distance, cond
        )
        DestroyBoolExpr(cond)
        for uuid,l in pairs(this.lightnings) do
            local x = GetUnitX(this.owner.unit)
            local y = GetUnitY(this.owner.unit)
            local rx = GetUnitX(l.rival.unit)
            local ry = GetUnitY(l.rival.unit)
            local r = math.atan(ry-y, rx-x)
            local d = math.sqrt((rx-x)*(rx-x) + (ry-y)*(ry-y))
            local v = 30000 / d
            local modi = l.rival:GetAffectedModifier('ELECTRON_CHARGED')
            if (d > this.max_distance or modi == nil) then
                DestroyLightning(l.lightning)
                this.lightnings[uuid] = nil
            else
                if (modi.is_positive_charge ~= this.is_positive_charge) then
                    v = -v
                    if ( d < 100) then
                        DestroyEffect(AddSpecialEffect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]], rx, ry))
                        modi:Remove()
                        this:Remove()
                    end
                end
                --DestroyLightning(l.lightning)
                --l.lightning = AddLightningEx('FORK', false, x, y, 50, rx, ry, 50)
                MoveLightningEx(l.lightning, false, x, y, GetUnitFlyHeight(this.owner.unit) + 100, 
                    rx, ry, GetUnitFlyHeight(l.rival.unit) + 100)
                l.rival:AddDisplace(Displace:new{
                    velocity = Vector3:new(nil, v * Cos(r), v * Sin(r), 0),
                    accelerate = Vector3:new(nil, 0, 0, 0),
                    max_distance = 30,
                    max_duration = 0.1,
                    interruptible = true,
                    interrupt_action = false,
                    efx = [[Abilities\Weapons\FarseerMissile\FarseerMissile.mdl]],
                    efx_interval = 0.1,
                })
            end
        end
    end,
    --@param this Modifier
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
        for uuid,l in pairs(this.lightnings) do
            DestroyLightning(l.lightning)
            this.lightnings[uuid] = nil
        end
    end
}

-- 充电
--[[充电：使一个单位随机带上正电或者负电，
带电的单位距离在600以内时，
若带电不同，会有红色闪电连接并互相吸引，
带电相同，则有蓝色闪电连接并互相排斥，
距离越近吸引or排斥效果越强，
带电不同的单位距离小于100时会放电并清除带电效果]]
AbilityScripts.CHARGE_ELECTRON = {
    AbilityId = FourCC('A00G'),
    Cast = function()
        local caster = LuaUnit.Get(GetTriggerUnit())
        local target = LuaUnit.Get(GetSpellTargetUnit())
        local modi = caster:ApplyModifierById('ELECTRON_CHARGED', target, AbilityScripts.CHARGE_ELECTRON.AbilityId)
        if math.random(1,100) > 50 and modi ~= nil then
            modi.is_positive_charge = false
            DestroyEffect(modi.effects[1])
            modi.effects[1] = AddSpecialEffectTarget([[Abilities\Weapons\VengeanceMissile\VengeanceMissile.mdl]], 
            target.unit, 'overhead')
        end
    end
}]=]

P['scripts/IceMaiden.lua'] = [=[Master.Modifier.FREEZING_REALM = {
    id = 'FREEZING_REALM',
    icon = [[ReplaceableTextures\PassiveButtons\PASBTNFreezingBreath.blp]],
    title = '极寒领域',
    description = '对周围$Range$范围内的单位施加「极寒」效果',
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    BindAbility = FourCC('A00U'),
    Effects = { {
        model = [[Effects\FrostAura.mdx]],
        attach_point = 'origin'
    } },
    LevelValues = {
        Range = { 900 }
    },
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitEnemy(unit, GetOwningPlayer(this.owner.unit))
                and not UnitWrapper.Get(unit):IsModifierTypeAffected('FROZEN')
                and not UnitWrapper.Get(unit):IsModifierTypeAffected('FREEZING_REALM_IMMUNE') then
                this.owner:ApplyModifier(Master.Modifier.FREEZING_REALM_TARGET, UnitWrapper.Get(unit))
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'),
            cond)
        DestroyBoolExpr(cond)
    end
}

Master.Modifier.FREEZING_REALM_TARGET = {
    id = 'FREEZING_REALM_TARGET',
    icon = [[ReplaceableTextures\CommandButtons\BTNFreezingBreath.blp]],
    title = '极寒',
    description = '这个单位受到极寒影响，移动速度降低@MoveSpeedDown@点。当移动速度在$FrozenThreshold$以下时，会解除本状态并被冻结$FrozenTime$秒。',
    duration = 1.1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    BindAbility = FourCC('A00U'),
    Effects = { {
        model = [[Abilities\Spells\Other\FrostDamage\FrostDamage.mdl]],
        attach_point = 'overhead'
    } },
    LevelValues = {
        MaxMoveSpeedDown = { 400 },
        MoveSpeedDownPerSecond = { 200 },
        Range = { 900 },
        FrozenThreshold = { 25 },
        FrozenTime = { 1 }
    },
    ---@param this Modifier
    Update = function(this)
        local dx = GetUnitX(this.owner.unit) - GetUnitX(this.applier.unit)
        local dy = GetUnitY(this.owner.unit) - GetUnitY(this.applier.unit)
        local dis = math.sqrt(dx * dx + dy * dy)
        local rate = 1 - dis / this:LV('Range')
        if rate < 0 then rate = 0 end
        local down = this:LV('MoveSpeedDownPerSecond') * rate * this.interval
        this.CommonStatsBonus.movespeed = (this.CommonStatsBonus.movespeed or 0) - down
        this.CustomValues.MoveSpeedDown = -this.CommonStatsBonus.movespeed
        if (GetUnitMoveSpeed(this.owner.unit) <= this:LV('FrozenThreshold')) then
            local mod = this.owner:AcquireModifierById('FROZEN', this.applier, Master.Modifier.FREEZING_REALM
                .BindAbility)
            if (mod ~= nil) then
                mod.max_duration = this:LV('FrozenTime')
                mod.duration = this:LV('FrozenTime')
                this:Remove()
            end
        end
    end
}

AbilityScripts.ICE_KNIFE = {
    AbilityId = FourCC('A00V'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local target = GetSpellTargetUnit()
        Projectil:ctor {
            emitter = caster,
            target_unit = target,
            settings = Master.Projectil.ICE_KNIFE,
            hit_damage = Damage:ctor {
                amount = 100,
                source = caster,
                atktype = Damage.ATTACK_TYPE_SPELL,
                dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                eletype = Damage.ELEMENT_TYPE_PIERCE
            }
        }
    end
}

Master.Projectil.ICE_KNIFE = {
    model = [[Abilities\Weapons\LichMissile\LichMissile.mdl]],
    model_scale = 1,
    speed = 1600,
    no_gravity = false,
    hit_range = 30,
    hit_terrain = true,
    hit_other = true,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_UNIT,
    tracking_angle = 120 * math.degree,
    turning_speed = 120 * math.degree,
    turning_speed_pitch = 5 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 50,
    offsetZ = 50,
    ---@param this Projectil
    OnHit = function(this)
        DestroyEffect(AddSpecialEffect([[Abilities\Spells\Undead\FrostNova\FrostNovaTarget.mdl]], this.position.x,
            this.position.y))
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and IsUnitEnemy(unit, this:GetPlayer()) then
                local damage = Damage:ctor {
                    source = this.emitter,
                    target = UnitWrapper.Get(unit),
                    amount = 75,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                    eletype = Damage.ELEMENT_TYPE_KRYO
                }
                damage:Resolve()
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, this.position.x, this.position.y, 225, cond)
        DestroyBoolExpr(cond)
    end,
    OnHitTerrain = function(this)
        this.settings.OnHit(this)
        this:End()
    end
}

AbilityScripts.ICE_WALL = {
    AbilityId = FourCC('A00W'),
    ICE_BLOCK_DISTANCE = 64,
    MAX_ICE_BLOCK_NUM = 20,
    DURATION = 30,
    PUSH_SPPED = 1500,
    PUSH_DURATION = 0.3,
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        if not caster:IsModifierTypeAffected('ICE_WALL_FIRST_CAST') then
            AbilityScripts.ICE_WALL.CastFirst()
        else
            AbilityScripts.ICE_WALL.CastEnd()
        end
    end,
    CastFirst = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local mod = caster:AcquireModifier(Master.Modifier.ICE_WALL_FIRST_CAST, caster, AbilityScripts.ICE_WALL
            .AbilityId)
        if mod then
            mod.CustomValues.IceWallFirstPos = Vector3:ctor {
                x = GetSpellTargetX(),
                y = GetSpellTargetY(),
            }
            CoreTicker.RegisterDelayedAction(function()
                BlzEndUnitAbilityCooldown(caster.unit, AbilityScripts.ICE_WALL.AbilityId)
            end, CoreTicker.Interval)
        end
    end,
    CastEnd = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local mod = caster:GetAffectedModifier('ICE_WALL_FIRST_CAST')
        if mod then
            local first_pos = mod.CustomValues.IceWallFirstPos
            local end_x = GetSpellTargetX()
            local end_y = GetSpellTargetY()
            local angle = math.atan(end_y - first_pos.y, end_x - first_pos.x)
            local x = first_pos.x
            local y = first_pos.y
            local dis = first_pos:Distance2D(end_x, end_y)
            local num = 0
            repeat
                x = x + AbilityScripts.ICE_WALL.ICE_BLOCK_DISTANCE * Cos(angle)
                y = y + AbilityScripts.ICE_WALL.ICE_BLOCK_DISTANCE * Sin(angle)
                local v = AbilityScripts.ICE_WALL.PUSH_SPPED
                local a = -v / AbilityScripts.ICE_WALL.PUSH_DURATION
                local cond = Condition(function()
                    local u = GetFilterUnit()
                    local push_angle = math.atan(GetUnitY(u) - y, GetUnitX(u) - x)
                    UnitWrapper.Get(u):AddDisplace(Displace:ctor {
                        velocity = Vector3:new(nil, v * Cos(push_angle), v * Sin(push_angle), 0),
                        accelerate = Vector3:new(nil, a * Cos(push_angle), a * Sin(push_angle), 0),
                        max_distance = 0,
                        max_duration = AbilityScripts.ICE_WALL.PUSH_DURATION,
                        interruptible = true,
                        interrupt_action = false,
                        efx = [[Abilities\Weapons\FrostWyrmMissile\FrostWyrmMissile.mdl]],
                        efx_interval = 0.1,
                    })
                    return false
                end)
                GroupEnumUnitsInRange(Entity.tempGroup, x, y, 64, cond)
                DestroyBoolExpr(cond)
                local mo = MapObject:ctor {
                    x = x, y = y, z = 0,
                    duration = AbilityScripts.ICE_WALL.DURATION,
                    model_path = [[Abilities\Spells\Undead\FreezingBreath\FreezingBreathTargetArt.mdl]],
                    creator = caster,
                    awake_handlers = {
                        function(this)
                            this.CustomValues.PathBlocker = CreateDestructable(FourCC('YTfb'), x, y, 0, 1, 0)
                            BlzSetSpecialEffectTimeScale(this.model, 3)
                        end
                    },
                    remove_handlers = {
                        function(this)
                            --BlzSetSpecialEffectZ(this.model, -10000)
                            RemoveDestructable(this.CustomValues.PathBlocker)
                        end
                    }
                }
                mo:AddUpdateHandler(function(this)
                    local cold_cond = Condition(function()
                        local u = GetFilterUnit()
                        if IsUnitEnemy(u, GetOwningPlayer(this.creator.unit))
                            and not IsUnitType(u, UNIT_TYPE_DEAD) then
                            UnitWrapper.Get(u):AcquireModifierById('ICE_WALL_CHILLINESS', this.creator)
                        end
                        return false
                    end)
                    GroupEnumUnitsInRange(Entity.tempGroup, this.position.x, this.position.y, 128, cold_cond)
                    DestroyBoolExpr(cold_cond)
                    DestroyEffect(AddSpecialEffect([[Abilities\Spells\Undead\FreezingBreath\FreezingBreathMissile.mdl]],
                        this.position.x, this.position.y))
                end, 1)
                num = num + 1
            until num >= AbilityScripts.ICE_WALL.MAX_ICE_BLOCK_NUM or AbilityScripts.ICE_WALL.ICE_BLOCK_DISTANCE * num > dis
            mod:Remove()
        end
    end
}

Master.Modifier.ICE_WALL_FIRST_CAST = {
    id = 'ICE_WALL_FIRST_CAST',
    hidden = true,
    duration = -1,
    interval = 999,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    BindAbility = AbilityScripts.ICE_WALL.AbilityId,
    Effects = {},
}

Master.Modifier.ICE_WALL_CHILLINESS = {
    id = 'ICE_WALL_CHILLINESS',
    icon = [[ReplaceableTextures\CommandButtons\BTNGlacier.blp]],
    title = '寒气',
    description = '这个单位受寒气影响，移动速度降低50, 受到的寒冷伤害增加25%',
    duration = 2,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    BindAbility = AbilityScripts.ICE_WALL.AbilityId,
    Effects = {},
    OnAcquired = function(this)
        this.CommonStatsBonus.movespeed = -50
    end,
    ---@param damage Damage
    OnBeforeTakeDamage = function(this, damage)
        if damage.eletype == Damage.ELEMENT_TYPE_KRYO then
            damage.control_rate = damage.control_rate + 25
        end
    end
}

AbilityScripts.FROZEN_MAGIC_SPHERE = {
    AbilityId = FourCC('A00X'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tx = GetSpellTargetX()
        local ty = GetSpellTargetY()
        local orb = CreateUnit(GetOwningPlayer(caster.unit), FourCC('o001'), tx, ty, 0)
        UnitWrapper.Get(orb):AcquireModifier(Master.Modifier.FROZEN_MAGIC_SPHERE_EFFECTS, caster,
            AbilityScripts.FROZEN_MAGIC_SPHERE.AbilityId)
        UnitApplyTimedLife(orb, FourCC('BTLF'), 60)
    end
}

Master.Modifier.FROZEN_MAGIC_SPHERE_EFFECTS = {
    id = 'FROZEN_MAGIC_SPHERE_EFFECTS',
    icon = [[ReplaceableTextures\CommandButtons\BTNOrbOfFrost.blp]],
    title = '冰封法球',
    description = [[给予周围敌人冰封效果：移动速度降低50，被冻结时，冻结时间延长1秒。
    受到伤害时放出一道冲击，周围350范围内的敌方单位有50%的概率被冻结0.3秒。]],
    duration = -1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    BindAbility = AbilityScripts.FROZEN_MAGIC_SPHERE.AbilityId,
    Effects = {},
    LevelValues = {
        Range = { 900 }
    },
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitEnemy(unit, GetOwningPlayer(this.owner.unit)) 
                and not UnitWrapper.Get(unit):IsModifierTypeAffected('FROZEN')then
                this.owner:ApplyModifier(Master.Modifier.FROZEN_MAGIC_SPHERE_EXTEND_FROZEN, UnitWrapper.Get(unit))
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'),
            cond)
        DestroyBoolExpr(cond)
    end,
     ---@param damage Damage
     OnTakeDamage = function(this, damage)
        if damage.amount ~= 0 then
            local cond = Condition(function()
                local unit = GetFilterUnit()
                if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                    and IsUnitEnemy(unit, GetOwningPlayer(this.owner.unit)) 
                    and math.random(1,100) <= 50 then
                    local frz = this.owner:ApplyModifier(Master.Modifier.FROZEN, UnitWrapper.Get(unit))
                    frz.max_duration = 0.3
                    frz.duration = 0.3
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), 350, cond)
            DestroyBoolExpr(cond)
            DestroyEffect(AddSpecialEffect([[Effects\FrostNova.mdx]], this.owner:GetX(), this.owner:GetY()))
        end
    end
}

Master.Modifier.FROZEN_MAGIC_SPHERE_EXTEND_FROZEN = {
    id = 'FROZEN_MAGIC_SPHERE_EXTEND_FROZEN',
    icon = [[ReplaceableTextures\CommandButtons\BTNOrbOfFrost.blp]],
    title = '冰封',
    description = '这个单位移动速度降低50，被冻结时，冻结时间延长1秒',
    duration = -1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    BindAbility = AbilityScripts.FROZEN_MAGIC_SPHERE.AbilityId,
    Effects = {},
    LevelValues = {
        Range = { 900 }
    },
    OnAcquired = function(this)
        this.CommonStatsBonus.movespeed = -50
    end,
    ---@param this Modifier
    Update = function(this)
        local dis = this.owner:DistanceToUnit(this.applier)
        if dis > this:LV('Range') then
            this:Remove()
            return
        end
        local frz = this.owner:GetAffectedModifier('FROZEN')
        if frz then
            frz.max_duration = frz.max_duration + 1
            frz.duration = frz.duration + 1
            this:Remove()
        end
    end
}]=]

P['scripts/Misc.lua'] = [=[require('gameSystem')
require('master')

--[[
嗜血：
造成近战普通攻击伤害时，有概率回复伤害值100%的生命。
概率 = 缺失生命百分比 * 1/1.2/1.4/1.6
]]
Master.Modifier.THIRST_OF_BLOOD = {
    id = 'THIRST_OF_BLOOD',
    duration = -1,
    interval = 99999,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    LevelValues = {
        ProbabilityPerHPRateLost = { 1, 1.2, 1.4, 1.6 },
        HPDrainRate = { 100 }
    },
    ---@param this Modifier
    ---@param damage Damage
    DealDamage = function(this, damage)
        local p = this:LV('ProbabilityPerHPRateLost') *
            (1 - GetWidgetLife(this.owner.unit) / BlzGetUnitMaxHP(this.owner.unit)) * 100
        if damage.atktype == Damage.ATTACK_TYPE_MELEE and math.random(0, 100) < p then
            local heal = Damage:ctor {
                source = this.owner,
                target = this.owner,
                amount = damage.amount * this:LV('HPDrainRate') / 100,
                atktype = Damage.ATTACK_TYPE_UNKNOWN,
                dmgtype = Damage.DAMAGE_TYPE_HEAL,
                eletype = Damage.ELEMENT_TYPE_NONE,
            }
            heal:Resolve()
        end
    end
}

AbilityScripts.BOUNCING_INFERNAL = {
    AbilityId = FourCC('A00D'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tloc = Vector3:ctor {
            x = GetSpellTargetX(),
            y = GetSpellTargetY(),
            z = 0
        }
        tloc.z = Projectil.GetLocationZ(tloc.x, tloc.y)
        Projectil:ctor {
            emitter = caster,
            target_position = tloc,
            settings = Master.Projectil.BOUNCING_INFERNAL
        }
        local uuid = GUID.generate()

        -- local pitch = math.pi/2
        -- local x = GetUnitX(caster.unit)
        -- local y =  GetUnitY(caster.unit)
        -- local dx = GetSpellTargetX()-x
        -- local dy = GetSpellTargetY()-y
        -- local dis = math.sqrt(dx*dx + dy*dy)
        -- local h = dis
        -- local model = AddSpecialEffect([[Abilities\Spells\Human\StormBolt\StormBoltMissile.mdl]], x, y)
        -- local yaw = math.atan(dy, dx)
        -- local uuid = GUID.generate()
        -- BlzSetSpecialEffectScale(model, 2)
        -- BlzSetSpecialEffectYaw(model, yaw)
        -- BlzSetSpecialEffectZ(model, Projectil.GetLocationZ(x,y) + h)
        -- CoreTicker.AttachAction(function(interval)
        --     pitch = pitch - 270 * math.degree * interval
        --     local xy_dis = h * Cos(pitch)
        --     local new_x = x + xy_dis * Cos(yaw)
        --     local new_y = y + xy_dis * Sin(yaw)
        --     local new_z = Projectil.GetLocationZ(x,y) + h * Sin(pitch)
        --     BlzSetSpecialEffectPosition(model, new_x, new_y, new_z)
        --     BlzSetSpecialEffectPitch(model, -pitch)
        --     if (new_z < Projectil.GetLocationZ(new_x, new_y)) then
        --         DestroyEffect(model)
        --         DestroyEffect(AddSpecialEffect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]], new_x, new_y))
        --         CoreTicker.DetachAction(uuid)
        --     end
        -- end, CoreTicker.Interval, uuid)
    end
}
Master.Projectil.BOUNCING_INFERNAL = {
    model = [[Abilities\Weapons\DemonHunterMissile\DemonHunterMissile.mdl]],
    model_scale = 2,
    speed = 750,
    no_gravity = false,
    hit_range = 50,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 10 * math.degree,
    max_flying_distance = 1500,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 50,
    OnCreate = function(this)
        this.CustomValues.BounceCount = 0
    end,
    OnHit = nil,
    ---@param this Projectil
    ---@param terrainZ number
    OnHitTerrain = function(this, terrainZ)
        this.position.z = terrainZ
        this.speed = this.speed * 0.8
        this.pitch = -this.pitch
        this:AdjustVelocity()
        DestroyEffect(AddSpecialEffect([[Abilities\Spells\Orc\WarStomp\WarStompCaster.mdl]], this.position.x,
            this.position.y))
        this.CustomValues.BounceCount = this.CustomValues.BounceCount + 1
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and IsUnitEnemy(unit, this:GetPlayer()) then
                local damage = Damage:ctor {
                    source = this.emitter,
                    target = UnitWrapper.Get(unit),
                    amount = 100,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                    eletype = Damage.ELEMENT_TYPE_THERMO
                }
                damage:Resolve()
                local dx = GetUnitX(damage.target.unit) - this.position.x
                local dy = GetUnitY(damage.target.unit) - this.position.y
                local r = math.atan(dy, dx)
                local v = 1200
                local a = -v / 0.4
                UnitWrapper.Get(unit):AddDisplace(Displace:ctor {
                    velocity = Vector3:new(nil, v * Cos(r), v * Sin(r), 0),
                    accelerate = Vector3:new(nil, a * Cos(r), a * Sin(r), 0),
                    max_distance = 0,
                    max_duration = 0.4,
                    interruptible = true,
                    interrupt_action = true,
                    efx = [[Abilities\Weapons\AncientProtectorMissile\AncientProtectorMissile.mdl]],
                    efx_interval = 0.05,
                })
            end
            return false
        end)
        GroupEnumUnitsInRange(Projectil.tempGroup, this.position.x, this.position.y, 300, cond)
        DestroyBoolExpr(cond)
        -- local u = CreateUnit(GetOwningPlayer(this.emitter.unit), FourCC('n000'), this.position.x, this.position.y, this.yaw * math.degree)
        -- SetUnitAnimation(u, 'Birth')
        if (this.CustomValues.BounceCount >= 3) then
            this:End()
        end
    end
}

Master.Modifier.BLOOD_THIRST_AURA = {
    id = 'BLOOD_THIRST_AURA',
    duration = -1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('AUav'),
    LevelValues = {
        Range = { 900, 900, 900, 900 }
    },
    OnAcquired = function(this)
        this.apply_checker_group = CreateGroup()
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            if (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and
                (not IsUnitType(GetFilterUnit(), UNIT_TYPE_STRUCTURE)) and
                (not IsUnitType(GetFilterUnit(), UNIT_TYPE_MECHANICAL)) and (IsUnitAlly(GetFilterUnit(), GetOwningPlayer(this.owner.unit))) then
                local uw = UnitWrapper.Get(GetFilterUnit())
                uw:AcquireModifierById('BLOOD_THIRST_AURA_EFFECT')
            end
            return false
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit),
            this:LV('Range'), cond)
    end,
    OnRemoved = function(this)
        DestroyGroup(this.apply_checker_group)
    end
}
Master.Modifier.BLOOD_THIRST_AURA_EFFECT = {
    id = 'BLOOD_THIRST_AURA_EFFECT',
    duration = 0.2,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    remove_on_death = true,
    Effects = { {
        model = [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]],
        attach_point = 'hand left'
    } },
    BindAbility = FourCC('AUav'),
    LevelValues = {
        HPDrainRate = { 15, 25, 40, 50 }
    },
    OnAcquired = function(this)
        this.apply_checker_group = CreateGroup()
    end,
    ---@param this Modifier
    Update = function(this)
    end,
    ---@param this Modifier
    ---@param damage Damage
    OnDealDamage = function(this, damage)
        if damage.atktype == Damage.ATTACK_TYPE_MELEE then
            local heal = Damage:ctor {
                source = this.owner,
                target = this.owner,
                amount = damage.amount * this:LV('HPDrainRate') / 100,
                atktype = Damage.ATTACK_TYPE_UNKNOWN,
                dmgtype = Damage.DAMAGE_TYPE_HEAL,
                eletype = Damage.ELEMENT_TYPE_NONE,
            }
            heal:Resolve()
            DestroyEffect(AddSpecialEffect([[Abilities\Spells\Human\Heal\HealTarget.mdl]], GetUnitX(this.owner.unit),
                GetUnitY(this.owner.unit)))
        end
    end,
    OnRemoved = function(this)
        DestroyGroup(this.apply_checker_group)
    end
}

--困意袭来
AbilityScripts.SLEEPINESS_SETS_IN = {
    AbilityId = FourCC('A00M'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local target = UnitWrapper.Get(GetSpellTargetUnit())
        -- local mod = caster:ApplyModifierById('SLEEPINESS_SETS_IN', target)
        local mod = caster:ApplyModifierById('SOUL_ABSORB_TARGET', target)
    end
}

Master.Modifier.SLEEPINESS_SETS_IN = {
    id = 'SLEEPINESS_SETS_IN',
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.STACK,
    remove_on_death = true,
    max_stack = 8,
    stack = 2,
    Effects = { {
        model = [[Abilities\Spells\Other\CreepSleep\CreepSleepTarget.mdl]],
        attach_point = 'overhead'
    } },
    BindAbility = AbilityScripts.SLEEPINESS_SETS_IN.AbilityId,
    LevelValues = {
        Range = { 600 }
    },
    ---@param this Modifier
    Update = function(this)
        if (GetUnitAbilityLevel(this.owner.unit, CommonAbilitiy.SleepBuff) > 0) then
            this.CustomValues.Sleeping = true
            local cond = Condition(function()
                if (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and
                    (not IsUnitType(GetFilterUnit(), UNIT_TYPE_STRUCTURE)) and
                    (not IsUnitType(GetFilterUnit(), UNIT_TYPE_MECHANICAL)) then
                    local uw = UnitWrapper.Get(GetFilterUnit())
                    uw:AcquireModifierById('SLEEPINESS_SETS_IN', this.applier)
                end
                return false
            end)
            GroupEnumUnitsInRange(Modifier.TempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit),
                this:LV('Range'), cond)
        else
            if this.CustomValues.Sleeping == true then
                this:Remove()
            elseif this.stack >= this.max_stack then
                UnitMgr.DummySpellTarget(this.applier.unit, this.owner.unit, CommonAbilitiy.Sleep, 1, 'sleep')
                DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\Undead\Sleep\SleepSpecialArt.mdl]],
                    this.owner.unit, 'overhead'))
            end
            this:AddStack(-1)
        end
    end
}


--断空
AbilityScripts.SPACE_CUT_CIRCLE = {
    AbilityId = FourCC('A00N'),
    UseWallShape = true,
    Duration = 30,
    Cast = function()
        if AbilityScripts.SPACE_CUT_CIRCLE.UseWallShape == true then
            AbilityScripts.SPACE_CUT_CIRCLE.CastWallShape()
        else
            AbilityScripts.SPACE_CUT_CIRCLE.CastCircle()
        end
    end,
    CastWallShape = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local x0 = GetUnitX(caster.unit)
        local y0 = GetUnitY(caster.unit)
        local x = GetSpellTargetX()
        local y = GetSpellTargetY()
        local direction = math.atan(y - y0, x - x0)
        local front = MapObject:new(x0 + 100 * Cos(direction), y0 + 100 * Sin(direction), 0, direction,
            [[Doodads\Dungeon\Props\Forcewall\Forcewall]], AbilityScripts.SPACE_CUT_CIRCLE.Duration)
        local back = MapObject:new(x0 - 100 * Cos(direction), y0 - 100 * Sin(direction), 0, direction + math.pi,
            [[Doodads\Dungeon\Props\Forcewall\Forcewall]], AbilityScripts.SPACE_CUT_CIRCLE.Duration)
        local update = function(this)
            for _, prjt in pairs(ProjectilMgr.Instances) do
                local theta = math.atan(-this.position.y + prjt.position.y, -this.position.x + prjt.position.x)
                local dis = this.position:DistanceTo(prjt.position)
                local dy = Sin(math.angleDiff(math.pi / 2, (this.yaw - theta))) * dis
                local dx = Cos(math.angleDiff(math.pi / 2, (this.yaw - theta))) * dis
                if (math.abs(dx) <= 300 and math.abs(dy) <= 10 and math.abs(math.angleDiff(this.yaw + math.pi, prjt.yaw)) <= math.pi / 2) then
                    local eff
                    eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]], prjt.position.x,
                        prjt.position.y)
                    DestroyEffect(eff)
                    prjt:MoveTo(prjt.position.x - 200 * Cos(this.yaw),
                        prjt.position.y - 200 * Sin(this.yaw))
                    eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkTarget.mdl]], prjt.position.x,
                        prjt.position.y)
                    BlzSetSpecialEffectZ(eff, prjt.position.z)
                    DestroyEffect(eff)
                end
            end
        end
        front:AddUpdateHandler(update)
        back:AddUpdateHandler(update)
    end,
    CastCircle = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local x0 = GetUnitX(caster.unit)
        local y0 = GetUnitY(caster.unit)
        local x = GetSpellTargetX()
        local y = GetSpellTargetY()
        local mo = MapObject:ctor(x, y, 10, 0, [[Abilities\Spells\Orc\Voodoo\VoodooAura.mdl]], 30)
        mo:ScaleModel(1.2)
        mo:AddUpdateHandler(function(this)
            for _, prjt in pairs(ProjectilMgr.Instances) do
                local d = this.position:DistanceTo(prjt.position)
                if (d <= 240 and d >= 200) then
                    local p2c = math.atan(this.position.y - prjt.position.y, this.position.x - prjt.position.x)
                    local a = math.angleDiff(p2c, prjt.yaw)

                    if (a < math.pi / 2 and a > -math.pi / 2) then
                        local eff
                        eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]], prjt.position.x,
                            prjt.position.y)
                        BlzSetSpecialEffectZ(eff, prjt.position.z)
                        DestroyEffect(eff)
                        prjt:MoveTo(
                            prjt.position.x + (this.position.x - prjt.position.x) * 2,
                            prjt.position.y + (this.position.y - prjt.position.y) * 2
                        )
                        eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkTarget.mdl]], prjt.position.x,
                            prjt.position.y)
                        BlzSetSpecialEffectZ(eff, prjt.position.z)
                        DestroyEffect(eff)
                    end
                end
            end
        end)
    end
}

-- 风暴力场
Master.Modifier.STORM_FORCE_FIELD = {
    id = 'STORM_FORCE_FIELD',
    duration = -1,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A00B'),
    LevelValues = {
        PushVelocity = { 1000, 1200, 1400, 1600 },
        PushDuration = { 0.3 }
    },
    ---@param this Modifier
    ---@param damage Damage
    OnTakeDamage = function(this, damage)
        if damage.atktype == Damage.ATTACK_TYPE_MELEE then
            local dx = GetUnitX(damage.source.unit) - GetUnitX(this.owner.unit)
            local dy = GetUnitY(damage.source.unit) - GetUnitY(this.owner.unit)
            local r = math.atan(dy, dx)
            local v = this:LV('PushVelocity')
            local a = -v / this:LV('PushDuration')
            damage.source:AddDisplace(Displace:ctor {
                velocity = Vector3:new(nil, v * Cos(r), v * Sin(r), 0),
                accelerate = Vector3:new(nil, a * Cos(r), a * Sin(r), 0),
                max_distance = 0,
                max_duration = this:LV('PushDuration'),
                interruptible = true,
                interrupt_action = true,
                efx = nil,
                efx_interval = 1,
            })
            DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\NightElf\Taunt\TauntCaster.mdl]], this.owner.unit,
                'origin'))
        end
    end
}

Master.Modifier.PROTECTOR_TARGET = {
    id = 'PROTECTOR_TARGET',
    icon = [[ReplaceableTextures\CommandButtons\BTNDefendStop.blp]],
    title = '被保护',
    description = '这个单位被保护了，当受到致命伤害时（持续伤害除外），若与保护者距离在$MaxDistance$以内，则会与保护者交换位置，并将该次伤害转移给保护者，生效后此状态移除',
    duration = 180,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A00B'),
    LevelValues = {
        MaxDistance = { 600 }
    },
    ---@param this Modifier
    ---@param damage Damage
    OnStartTakeDamage = function(this, damage)
        if not this.applier:DeadQ()
            and damage.dmgtype ~= Damage.DAMAGE_TYPE_DOT
            and GetWidgetLife(this.owner.unit) < damage.amount
            and this.owner:DistanceToUnit(this.applier) <= this:LV('MaxDistance') then
            local x = this.owner:GetX()
            local y = this.owner:GetY()
            local px = this.applier:GetX()
            local py = this.applier:GetY()
            SetUnitX(this.owner.unit, px)
            SetUnitY(this.owner.unit, py)
            SetUnitX(this.applier.unit, x)
            SetUnitY(this.applier.unit, y)
            DestroyEffect(AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]], x, y))
            DestroyEffect(AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]], px, py))
            damage.target = this.applier
            this:Remove()
        end
    end
}

AbilityScripts.SOUL_ABSORB = {
    AbilityId = FourCC('A00N'),
    SOUL_MOVESEPPD = 600,
    Cast = function()
        AbilityScripts.SOUL_ABSORB.Effect(
            UnitWrapper.Get(GetTriggerUnit()),
            UnitWrapper.Get(GetSpellTargetUnit())
        )
    end,
    ---@param caster UnitWrapper
    ---@param target UnitWrapper
    Effect = function(caster, target)
        caster:ApplyModifierById('SOUL_ABSORB_TARGET', target, AbilityScripts.SOUL_ABSORB.AbilityId)
    end
}
Master.Modifier.SOUL_ABSORB_TARGET = {
    id = 'SOUL_ABSORB_TARGET',
    title = '灵魂离体',
    description = '这个单位灵魂离体了',
    duration = 30,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = true,
    Effects = {},
    LevelValues = {
        MaxSoulSpeed = { 400 },
        MaxDistance = { 1500 }
    },
    OnAcquired = function(this)
        local soul_model = GameHelper.UnitModelPathGetter:Get(this.owner.unit)
        this.CustomValues.AbsorbedSoul = AddSpecialEffect(soul_model, this.owner:GetX(), this.owner:GetY())
        BlzSetSpecialEffectAlpha(this.CustomValues.AbsorbedSoul, 100)
        this.CustomValues.AbsorbedSoulPos = Vector3:ctor {
            x = this.owner:GetX(),
            y = this.owner:GetY()
        }
    end,
    Update = function(this)
        local soul_pos       = this.CustomValues.AbsorbedSoulPos
        local d_soul_to_self = soul_pos:Distance2D(this.owner:GetX(), this.owner:GetY())
        local max_speed      = this:LV('MaxSoulSpeed')
        local max_distance   = this:LV('MaxDistance')
        local speed          = max_speed * (max_distance - d_soul_to_self) / max_distance
        if speed < 0 then speed = 0 end
        local d_soul_to_caster = soul_pos:Distance2D(this.applier:GetX(), this.applier:GetY())
        if d_soul_to_caster < 50 then
            BlzSetSpecialEffectZ(this.CustomValues.AbsorbedSoul, -10000)
            DestroyEffect(this.CustomValues.AbsorbedSoul)
            this:Remove()
            return
        end
        local a = math.atan(this.applier:GetY() - soul_pos.y, this.applier:GetX() - soul_pos.x)
        soul_pos.x = soul_pos.x + this.interval * speed * Cos(a)
        soul_pos.y = soul_pos.y + this.interval * speed * Sin(a)
        BlzSetSpecialEffectX(this.CustomValues.AbsorbedSoul, soul_pos.x)
        BlzSetSpecialEffectY(this.CustomValues.AbsorbedSoul, soul_pos.y)
    end,
}


AbilityScripts.HELICOPTER_FALL = {
    AbilityId = FourCC('A00P'),
    TURNING_SPEED = 2 * math.pi,
    FALLING_SPEED = 600,
    Cast = function()
        AbilityScripts.HELICOPTER_FALL.Effect(
            UnitWrapper.Get(GetTriggerUnit()),
            GetSpellTargetX(),
            GetSpellTargetY()
        )
    end,
    Effect = function(caster, x, y)
        local model = AddSpecialEffect([[units\human\Gyrocopter\Gyrocopter]], x, y)
        BlzSetSpecialEffectScale(model, 2)
        local terrain_z = Entity.GetLocationZ(x, y)
        local z = terrain_z + 1000
        local yaw = 0
        local id = GUID.generate()
        
        CoreTicker.AttachAction(function(interval)
            BlzSetSpecialEffectYaw(model, yaw)
            BlzSetSpecialEffectZ(model, z)
            yaw = yaw + AbilityScripts.HELICOPTER_FALL.TURNING_SPEED * interval
            z = z - AbilityScripts.HELICOPTER_FALL.FALLING_SPEED * interval
            if z < terrain_z then
                CoreTicker.DetachAction(id)
                BlzSetSpecialEffectZ(model, -10000)
                DestroyEffect(model)
                local explosion = AddSpecialEffect([[Effects/GroundExplosion.mdx]],x,y)
                BlzSetSpecialEffectScale(explosion, 3)
                DestroyEffect(explosion)
            end
        end,nil,id)
    end
}]=]

P['scripts/NagaQueen.lua'] = [=[Master.Modifier.DAGONS_BLESS = {
    id = 'DAGONS_BLESS',
    icon = [[ReplaceableTextures\CommandButtons\BTNDagonAdvocate_DagonsBless.dds]],
    title = '达贡的加护',
    description =
    '在浅水中移动速度上升50，每秒回复$HPRegenPercentPerSecondLow$%的生命|n在深水中移动速度上升150，每秒回复$HPRegenPercentPerSecondHigh$%的生命',
    duration = -1,
    interval = 0.1,
    remove_on_death = false,
    Effects = {},
    LevelValues = {
        HPRegenPercentPerSecondLow = { 0.25 },
        HPRegenPercentPerSecondHigh = { 1 }

    },
    ---@param this Modifier
    Update = function(this)
        this.CommonStatsBonus.movespeed = 0
        if this.owner:OnShallowWaterQ() then
            this.CommonStatsBonus.movespeed = 50
            this.owner:AddHPRate(this:LV('HPRegenPercentPerSecondLow') * this.interval)
        elseif this.owner:OnDeepWaterQ() then
            this.CommonStatsBonus.movespeed = 150
            this.owner:AddHPRate(this:LV('HPRegenPercentPerSecondHigh') * this.interval)
        else
            if this.CustomValues.OnWaterEffect ~= nil then
                DestroyEffect(this.CustomValues.OnWaterEffect)
                this.CustomValues.OnWaterEffect = nil
            end
        end
    end
}

Master.Modifier.OCEANUS_STRIKE = {
    id = 'OCEANUS_STRIKE',
    icon = [[ReplaceableTextures\CommandButtons\BTNScepterOfMastery.blp]],
    title = '海皇杖',
    description = '当前充能@Charge@点（最多500点，在深水时每秒获得50点充能，浅水时25点，其他情况下15点）|n造成近战攻击伤害时，若充能在100点以上，则消耗100点充能，额外造成100点寒冷伤害和1秒眩晕，同时对周围敌人造成50点伤害',
    duration = -1,
    interval = 1,
    remove_on_death = false,
    Effects = {},
    OnAcquired = function(this)
        this.CustomValues.Charge = 0
        this.CustomValues.WeaponEffect = nil
    end,
    ---@param this Modifier
    Update = function(this)
        if this.owner:OnShallowWaterQ() then
            this.CustomValues.Charge = this.CustomValues.Charge + 25
        elseif this.owner:OnDeepWaterQ() then
            this.CustomValues.Charge = this.CustomValues.Charge + 50
        else
            this.CustomValues.Charge = this.CustomValues.Charge + 15
        end
        if this.CustomValues.Charge > 500 then
            this.CustomValues.Charge = 500
        end
        if this.CustomValues.Charge >= 100 and this.CustomValues.WeaponEffect == nil then
            this.CustomValues.WeaponEffect = AddSpecialEffectTarget([[Effects\FrostBoltV1.mdx]], this.owner.unit,
                'weapon')
        end
    end,
    ---@param this Modifier
    OnDealDamage = function(this, damage)
        if this.CustomValues.Charge >= 100 and damage.atktype == Damage.ATTACK_TYPE_MELEE then
            DestroyEffect(AddSpecialEffect([[Effects/IceWarStomp.mdx]], damage.target:GetX(), damage.target:GetY()))
            this.CustomValues.Charge = this.CustomValues.Charge - 100
            local mdf = this.owner:ApplyModifierById('STUN', damage.target, this.ability)
            mdf:ReinitDuration(1)
            Damage:ctor {
                amount = 100,
                source = this.owner,
                target = damage.target,
                atktype = Damage.ATTACK_TYPE_SPELL,
                dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                eletype = Damage.ELEMENT_TYPE_KRYO
            }:Resolve()
            local cond = Condition(function()
                local u = GetFilterUnit()
                if not IsUnitType(u, UNIT_TYPE_DEAD)
                    and u ~= damage.target.unit
                    and IsUnitEnemy(u, GetOwningPlayer(this.owner.unit)) then
                    Damage:ctor {
                        amount = 50,
                        source = this.owner,
                        target = UnitWrapper.Get(u),
                        atktype = Damage.ATTACK_TYPE_SPELL,
                        dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                        eletype = Damage.ELEMENT_TYPE_KRYO
                    }:Resolve()
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, damage.target:GetX(), damage.target:GetY(), 250, cond)
            DestroyBoolExpr(cond)
            if this.CustomValues.Charge < 100 then
                DestroyEffect(this.CustomValues.WeaponEffect)
                this.CustomValues.WeaponEffect = nil
            end
        end
    end
}

AbilityScripts.TIDAL_BURST = {
    RANGE = 300,
    RANGE_BOOSTED = 500,
    DAMAGE = 100,
    DAMAGE_BOOSTED = 200,
    BOOST_COST = 250,
    AbilityId = FourCC('A010'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tx = GetSpellTargetX()
        local ty = GetSpellTargetY()
        local efx = AddSpecialEffect([[Effects\TidalBurst.mdx]], tx, ty)
        DestroyEffect(efx)
        local cond = Condition(function()
            local u = GetFilterUnit()
            if not IsUnitType(u, UNIT_TYPE_DEAD)
                and IsUnitEnemy(u, GetOwningPlayer(caster.unit)) then
                local uw = UnitWrapper.Get(u)
                local on_water = uw:OnWaterQ()
                local v = 3000
                if on_water then v = 4000 end
                uw:AddDisplace(Displace:ctor {
                    velocity = Vector3:new(nil, 0, 0, v),
                    accelerate = Vector3:new(nil, 0, 0, -3900),
                    max_distance = 0,
                    max_duration = 0,
                    interruptible = true,
                    interrupt_action = true,
                    finish_when_landed = true
                })
                local d_amt = 100
                if on_water then d_amt = d_amt * 1.5 end
                Damage:ctor {
                    amount = d_amt,
                    source = caster,
                    target = uw,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                    eletype = Damage.ELEMENT_TYPE_SMASH
                }:Resolve()
            end

            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, tx, ty, 300, cond)
        DestroyBoolExpr(cond)
    end
}

AbilityScripts.SUMMON_VORTEX = {
    AbilityId = FourCC('A011'),
    DURATION = 30,
    DURATION_BOOSTED = 60,
    ATTRACT_SPEED = 150,
    ATTRACT_SPEED_BOOSTED = 250,
    RANGE = 600,
    RANGE_BOOSTED = 900,
    BOOST_COST = 500,
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tx = GetSpellTargetX()
        local ty = GetSpellTargetY()
        AbilityScripts.SUMMON_VORTEX.Effect(caster, tx, ty)
    end,
    ---@param caster UnitWrapper
    Effect = function(caster, x, y)
        local duration, speed, range, mdfid
        local mdf = caster:GetAffectedModifier('OCEANUS_STRIKE')
        local boosted = false
        if (mdf and mdf.CustomValues.Charge >= AbilityScripts.SUMMON_VORTEX.BOOST_COST) then
            mdf.CustomValues.Charge = mdf.CustomValues.Charge - AbilityScripts.SUMMON_VORTEX.BOOST_COST
            DestroyEffect(mdf.CustomValues.WeaponEffect)
            mdf.CustomValues.WeaponEffect = nil
            duration = AbilityScripts.SUMMON_VORTEX.DURATION_BOOSTED
            speed = AbilityScripts.SUMMON_VORTEX.ATTRACT_SPEED_BOOSTED
            range = AbilityScripts.SUMMON_VORTEX.RANGE_BOOSTED
            mdfid = 'ON_DEEP_WATER_FAKE'
            boosted = true
        else
            duration = AbilityScripts.SUMMON_VORTEX.DURATION
            speed = AbilityScripts.SUMMON_VORTEX.ATTRACT_SPEED
            range = AbilityScripts.SUMMON_VORTEX.RANGE
            mdfid = 'ON_SHALLOW_WATER_FAKE'
        end
        local mo = MapObject:ctor {
            x = x, y = y, z = 0,
            duration = duration,
            model_path = [[Effects\Whirlpool.mdx]],
            creator = caster,
        }
        if boosted then
            BlzSetSpecialEffectTimeScale(mo.model, 3)
            BlzSetSpecialEffectScale(mo.model, 1.5)
        end
        local update_handler = function(this, interval)
            local cond = Condition(function()
                local u = GetFilterUnit()
                if not IsUnitType(u, UNIT_TYPE_DEAD) then
                    local uw = UnitWrapper.Get(u)
                    uw:AcquireModifierById(mdfid, this.creator.unit,
                        AbilityScripts.SUMMON_VORTEX.AbilityId)
                    if IsUnitEnemy(u, GetOwningPlayer(this.creator.unit)) then
                        local ux = uw:GetX()
                        local uy = uw:GetY()
                        local a = math.atan(this.position.y - uy, this.position.x - ux)
                        SetUnitX(u, ux + speed * Cos(a) * interval)
                        SetUnitY(u, uy + speed * Sin(a) * interval)
                    end
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, this.x, this.y, range, cond)
            DestroyBoolExpr(cond)
        end
        mo:AddUpdateHandler(update_handler)
    end
}

AbilityScripts.OCEANUS_RAGE = {
    AbilityId = FourCC('A012'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        AbilityScripts.OCEANUS_RAGE.Effect(caster)
    end,
    ---@param caster UnitWrapper
    Effect = function(caster)
        local mdf = caster:GetAffectedModifier('OCEANUS_STRIKE')
        --calc prjt start position
        local angle = (GetUnitFacing(caster.unit) + 20) * math.degree
        local dis = 120
        local start_pos = Vector3:ctor {
            x = caster:GetX() + dis * Cos(angle),
            y = caster:GetY() + dis * Sin(angle),
            z = Entity.GetUnitZ(caster.unit) + 300
        }
        local start_crystal = AddSpecialEffect([[Effects\FrostcraftCrystalSD.mdx]], start_pos.x, start_pos.y)
        BlzSetSpecialEffectZ(start_crystal, start_pos.z)

        local id = GUID.generate()
        local facing = GetUnitFacing(caster.unit)
        CoreTicker.AttachAction(function()
            for i = 1, 3, 1 do
                local t_a = (math.random(-30,30) + facing) * math.degree
                local t_d = 10
                local t_pos = Vector3:ctor {
                    x = start_pos.x + t_d * Cos(t_a),
                    y = start_pos.y + t_d * Sin(t_a),
                    z = start_pos.z + 60,
                }
                Projectil:ctor {
                    emitter = caster,
                    x = start_pos.x,
                    y = start_pos.y,
                    z = start_pos.z + 60,
                    target_position = t_pos,
                    settings = Master.Projectil.OCEANUS_RAGE_PRJT,
                    hit_damage = Damage:ctor {
                        amount = 50,
                        source = caster,
                        atktype = Damage.ATTACK_TYPE_SPELL,
                        dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                        eletype = Damage.ELEMENT_TYPE_PIERCE
                    }
                }
            end
            if mdf and mdf.CustomValues.Charge > 10 then
                mdf.CustomValues.Charge = mdf.CustomValues.Charge - 10
                DestroyEffect(mdf.CustomValues.WeaponEffect)
                mdf.CustomValues.WeaponEffect = nil
            else
                IssueImmediateOrder(caster.unit, 'stop')
            end
        end, 0.1, id)
        local trig = CreateTrigger()
        TriggerRegisterUnitEvent(trig, caster.unit, EVENT_UNIT_SPELL_ENDCAST)
        local tcond
        tcond = Condition(function()
            CoreTicker.DetachAction(id)
            DestroyEffect(start_crystal)
            DestroyTrigger(trig)
            DestroyBoolExpr(tcond)
            return false
        end)
        TriggerAddCondition(trig, tcond)
    end
}

Master.Projectil.OCEANUS_RAGE_PRJT = {
    model = [[Effects\FrostBoltV1.mdx]],
    model_scale = 1,
    speed = 500,
    no_gravity = true,
    hit_range = 50,
    hit_terrain = true,
    hit_other = true,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 120 * math.degree,
    turning_speed = 160 * math.degree,
    turning_speed_pitch = 15 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    ---@param this Projectil
    OnCreated = function(this) 
        this.CustomValues.TargetFound = false
    end,
    ---@param this Projectil
    Update = function(this)
        if (this.CustomValues.TargetFound == false and this.flying_time >= 1) then
            
            local cond = Condition(function()
                local u = GetFilterUnit()
                if not IsUnitType(u, UNIT_TYPE_DEAD)
                and IsUnitEnemy(u, GetOwningPlayer(this.emitter.unit)) then
                    local uw = UnitWrapper.Get(u)
                    local ta = math.atan(uw:GetY()-this.position.y, uw:GetX()-this.position.x)
                    local delta = math.angleDiff(this.yaw, ta)
                    if (delta < 120*math.degree and delta > -120*math.degree) then
                        this.target_unit = u
                        this.track_type = Projectil.TRACK_TYPE_UNIT
                        this.speed = 2000
                        this.CustomValues.TargetFound = true
                    end
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, this.position.x, this.position.y, 700, cond)
            DestroyBoolExpr(cond)
        end
    end,
}]=]

P['scripts/Nephtis.lua'] = [=[require('gameSystem')
require('master')

-- 灵魂转化
Master.Modifier.NEPHTIS_SOUL_CONVERT = {
    id = 'NEPHTIS_SOUL_CONVERT',
    icon = [[ReplaceableTextures\CommandButtons\BTNAnimateDead.blp]],
    title = [[灵魂转化]],
    description = [[当周围@DetectRange@范围内的非英雄、非机械单位死亡时，吸收它们的灵魂。]],
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    stack = 1,
    remove_on_death = false,
    tags = {},
    BindAbility = FourCC('A00O'),
    Effects = {{
        model = [[Abilities\Spells\NightElf\TargetArtLumber\TargetArtLumber.mdl]],
        attach_point  = 'origin'
    }},
    ---@param this Modifier
    OnAcquired = function(this)
        this.CustomValues.DetectRange = 1200
        this.CustomValues.Souls = {}
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local u = GetFilterUnit()
            if (IsUnitType(u, UNIT_TYPE_DEAD) and 
            (not IsUnitType(u, UNIT_TYPE_MECHANICAL)) and 
            (not IsUnitType(u, UNIT_TYPE_HERO))) then
                local p = Projectil:ctor{
                    emitter = this.owner,
                    target_unit = this.owner.unit,
                    x = GetUnitX(u),
                    y = GetUnitY(u),
                    z = 100,
                    settings = Master.Projectil.NEPHTIS_SOUL_CONVERT_PRJT
                }
                p:ChangeModel(GameHelper.UnitModelPathGetter:Get(u))
                p:HideModelDeathAnimation(true)
                BlzSetSpecialEffectAlpha(p.model, 80)
                p.CustomValues.AbsorbedSoul = {
                    name = GetUnitName(u),
                    model = GameHelper.UnitModelPathGetter:Get(u)
                }
                UnitMgr.RemoveUnit(u)
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, 
            GetUnitX(this.owner.unit), 
            GetUnitY(this.owner.unit), 
            this.CustomValues.DetectRange, cond
        )
        DestroyBoolExpr(cond)
    end
}

Master.Projectil.NEPHTIS_SOUL_CONVERT_PRJT = {
    model = [[Abilities\Weapons\NecromancerMissile\NecromancerMissile.mdl]],
    model_scale = 1,
    speed = 400,
    no_gravity = true,
    hit_range = 50,
    hit_terrain = false,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_UNIT,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    turning_speed_pitch = 360 * math.degree,
    max_flying_distance = 99999,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    LevelValues = {},
    ---@param this Projectil
    ---@param victim UnitWrapper
    OnHit = function(this, victim)
        DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\Undead\RaiseSkeletonWarrior\RaiseSkeleton.mdl]], victim.unit, 'origin'))
        local m = victim:GetAffectedModifier('NEPHTIS_SOUL_CONVERT')
        table.insert(m.CustomValues.Souls, this.CustomValues.AbsorbedSoul)
        print(this.CustomValues.AbsorbedSoul.name)
    end
}

AbilityScripts.NEPHTIS_SOUL_LINK = {
    AbilityId = FourCC('A00H'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local target = UnitWrapper.Get(GetSpellTargetUnit())
        caster:ApplyModifierById('NEPHTIS_SOUL_LINK', target, AbilityScripts.NEPHTIS_SOUL_LINK.AbilityId)
    end
}
Master.Modifier.NEPHTIS_SOUL_LINK = {
    id = 'NEPHTIS_SOUL_LINK',
    icon = [[ReplaceableTextures\CommandButtons\BTNSpiritLink.blp]],
    title = [[灵魂连接（目标）]],
    description = [[生命值会在此单位与灵魂连接的释放者之间转移，使双方生命值百分比尽量保持一致，每秒最多转移$MaxLifeTransferPerSecond$点生命]],
    duration = 30,
    interval = nil,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {{
        model = [[Abilities\Spells\NightElf\TargetArtLumber\TargetArtLumber.mdl]],
        attach_point  = 'overhead'
    }},
    LevelValues = {
        MaxLifeTransferPerSecond = {50,100,150,200},
    },
    ---@param this Modifier
    Update = function(this)
        local owner_hp = GetWidgetLife(this.owner.unit)
        local owner_hp_rate = owner_hp /BlzGetUnitMaxHP(this.owner.unit)
        local applier_hp =  GetWidgetLife(this.applier.unit)
        local applier_hp_rate = applier_hp /BlzGetUnitMaxHP(this.applier.unit)
        local max = this.interval * this:LV('MaxLifeTransferPerSecond')
        if (owner_hp_rate > applier_hp_rate) then
            SetWidgetLife(this.owner.unit, owner_hp - max)
            SetWidgetLife(this.applier.unit, applier_hp + max)
        elseif (owner_hp_rate < applier_hp_rate) then
            SetWidgetLife(this.owner.unit, owner_hp + max)
            SetWidgetLife(this.applier.unit, applier_hp - max)
        end
    end
}]=]

P['scripts/RedDragon.lua'] = [=[Master.Modifier.RED_DRAGON_ENVIRONMENT = {
    id = 'RED_DRAGON_ENVIRONMENT',
    hidden = true,
    duration = -1,
    interval = 3,
    Effects = {},
    remove_on_death = false,
    BindAbility = FourCC('A00S'),
    LevelValues = {
        Range = { 800 },
        EruptionDamage = { 100 },
        EruptionDamageRange = { 150 },
        MissileDamage = { 100 },
        MissileDamageRange = { 100 },
        LavaEffectRange = { 150 }
    },
    STATIC_LavaModelPaths = { [[Doodads\Dungeon\Props\LavaCracks\LavaCracks0.mdl]],
        [[Doodads\Dungeon\Props\LavaCracks\LavaCracks1.mdl]],
        [[Doodads\Dungeon\Props\LavaCracks\LavaCracks2.mdl]],
        [[Doodads\Dungeon\Props\LavaCracks\LavaCracks3.mdl]] },
    ---@param this Modifier
    Update = function(this)
        local u = this.owner.unit
        local ux = GetUnitX(u)
        local uy = GetUnitY(u)
        local d = math.random(0, this:LV('Range'))
        local rad = math.random(0, 360) * math.degree
        local spawn_pos = Vector3:ctor {
            x = ux + d * Cos(rad),
            y = uy + d * Sin(rad)
        }
        spawn_pos.z = Entity.GetLocationZ(spawn_pos.x, spawn_pos.y)

        local prepare_effect = AddSpecialEffect([[Abilities\Spells\Items\VampiricPotion\VampPotionCaster.mdl]],
            spawn_pos.x, spawn_pos.y)
        CoreTicker.RegisterDelayedAction(function()
            DestroyEffect(prepare_effect)
            -- 岩浆爆发效果
            DestroyEffect(
                AddSpecialEffect([[Abilities\Weapons\DemolisherFireMissile\DemolisherFireMissile.mdl]], spawn_pos.x,
                    spawn_pos.y))
            for i = 0, 3, 1 do
                local axy = math.random(1, 360) * math.degree
                local az = math.random(30, 90) * math.degree
                local target_position = Vector3:ctor {
                    x = spawn_pos.x + 10 * Cos(az) * Cos(axy),
                    y = spawn_pos.y + 10 * Cos(az) * Sin(axy),
                    z = spawn_pos.z + 10 * Sin(az)
                }
                local prjt = Projectil:ctor {
                    emitter = this.owner,
                    x = spawn_pos.x,
                    y = spawn_pos.y,
                    z = spawn_pos.z,
                    target_position = target_position,
                    settings = Master.Projectil.RED_DRAGON_ENVIRONMENT_VOLCANO_MISSILE
                }
                prjt.CustomValues.DamageAmount = this:LV('MissileDamage')
                prjt.CustomValues.DamageRange = this:LV('MissileDamageRange')
            end

            local cond = Condition(function()
                local unit = GetFilterUnit()
                if ((not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and Entity.GetUnitZ(unit) <= spawn_pos.z + 100) then
                    local damage = Damage:ctor {
                        source = this.owner,
                        target = UnitWrapper.Get(unit),
                        amount = this:LV('EruptionDamage'),
                        atktype = Damage.ATTACK_TYPE_SPELL,
                        dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                        eletype = Damage.ELEMENT_TYPE_THERMO
                    }
                    damage:Resolve()
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, spawn_pos.x, spawn_pos.y, this:LV('EruptionDamageRange'), cond)
            DestroyBoolExpr(cond)

            -- 岩浆地面效果
            local lava = MapObject:ctor {
                x = spawn_pos.x,
                y = spawn_pos.y,
                z = 0,
                yaw = rad,
                model_path = Master.Modifier.RED_DRAGON_ENVIRONMENT.STATIC_LavaModelPaths[math.random(1,
                    #Master.Modifier.RED_DRAGON_ENVIRONMENT.STATIC_LavaModelPaths)],
                duration = 30,
                creator = this.owner
            }
            lava:AddUpdateHandler(function(mo, interval)
                local cond = Condition(function()
                    local unit = GetFilterUnit()
                    if ((not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and GetUnitFlyHeight(unit) <= 50) then
                        UnitWrapper.Get(unit):AcquireModifier(Master.Modifier.RED_DRAGON_ENVIRONMENT_LAVA_DAMAGE,
                            mo.creator)
                    end
                    return false
                end)
                GroupEnumUnitsInRange(Entity.tempGroup, mo.position.x, mo.position.y, this:LV('LavaEffectRange'), cond)
                DestroyBoolExpr(cond)
            end, 1)
        end, 2)
    end
}
Master.Projectil.RED_DRAGON_ENVIRONMENT_VOLCANO_MISSILE = {
    model = [[Abilities\Spells\Other\Volcano\VolcanoMissile.mdl]],
    model_scale = 1,
    speed = 600,
    no_gravity = false,
    hit_range = 50,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    turning_speed_pitch = 360 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    ---@param this Projectil
    ---@param terrainZ number
    OnHitTerrain = function(this, terrainZ)
        Master.Modifier.STUN.duration = 0.5
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if ((not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and Entity.GetUnitZ(unit) <= this.position.z + 100) then
                local damage = Damage:ctor {
                    source = this.emitter,
                    target = UnitWrapper.Get(unit),
                    amount = this.CustomValues.DamageAmount,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                    eletype = Damage.ELEMENT_TYPE_THERMO
                }
                damage:Resolve()
                UnitWrapper.Get(unit):AcquireModifier(Master.Modifier.STUN, this.emitter)
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, this.position.x, this.position.y, this.CustomValues.DamageRange, cond)
        DestroyBoolExpr(cond)
        this:End()
    end
}
Master.Modifier.RED_DRAGON_ENVIRONMENT_LAVA_DAMAGE = {
    id = 'RED_DRAGON_ENVIRONMENT_LAVA_DAMAGE',
    icon = [[ReplaceableTextures\PassiveButtons\PASLavaRealm.dds]],
    title = '熔岩地表',
    description = '这个单位站在熔岩地表上，每秒受到灼热伤害',
    duration = 2,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = { {
        model = [[Abilities\Spells\Other\ImmolationRed\ImmolationRedDamage.mdl]],
        attach_point = 'overhead'
    } },
    ---@param this Modifier
    Update = function(this)
        local damage = Damage:ctor {
            source = this.applier,
            target = this.owner,
            amount = 16,
            atktype = Damage.ATTACK_TYPE_SPELL,
            dmgtype = Damage.DAMAGE_TYPE_DOT,
            eletype = Damage.ELEMENT_TYPE_THERMO
        }
        damage:Resolve()
    end
}

AbilityScripts.RED_DRAGON_BREATH = {
    AbilityId = FourCC('A00T'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local target = GetSpellTargetUnit()
        local tloc = Vector3:ctor {
            x = GetUnitX(target),
            y = GetUnitY(target),
            z = Entity.GetUnitHitZ(target)
        }
        local p = Projectil:ctor {
            emitter = caster,
            target_position = tloc,
            settings = Master.Projectil.RED_DRAGON_BREATH
        }
        p.CustomValues.DamageAmount = 200
    end
}
Master.Projectil.RED_DRAGON_BREATH = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    model_scale = 2,
    speed = 800,
    no_gravity = true,
    hit_range = 50,
    hit_terrain = true,
    hit_other = true,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    turning_speed_pitch = 360 * math.degree,
    max_flying_distance = 3200,
    offsetX = 0,
    offsetY = 120,
    offsetZ = -30,
    ---@param this Projectil
    OnHit = function(this, victim) -- 命中时调用的函数
        DestroyEffect(AddSpecialEffect([[Effects\GroundExplosion.mdx]], this.position.x, this.position.y))
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if ((not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD))) then
                local damage = Damage:ctor {
                    source = this.emitter,
                    target = UnitWrapper.Get(unit),
                    amount = this.CustomValues.DamageAmount,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                    eletype = Damage.ELEMENT_TYPE_THERMO
                }
                damage:Resolve()
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, this.position.x, this.position.y, 300, cond)
        DestroyBoolExpr(cond)
    end,
    OnHitTerrain = function(this)
        this:Hit()
    end
}]=]

P['scripts/init.lua'] = [=[AbilityScripts = {}
AbilityScripts.AddAbilityWithIntrinsecModifier = function(u, abilityId)
    UnitAddAbility(u, abilityId)
    if AbilityIntrinsecModDict[abilityId] ~= nil then
        for _,mid in ipairs(AbilityIntrinsecModDict[abilityId]) do
            UnitWrapper.Get(u):AcquireModifierById(mid, UnitWrapper.Get(u), abilityId)
        end
        
    end
end
AbilityCastDict = {
    [FourCC('A00D')] = 'BOUNCING_INFERNAL',
    [FourCC('A00I')] = 'SPAWN_TEST_UNITS',
    [FourCC('A00M')] = 'SLEEPINESS_SETS_IN',
    [FourCC('A00N')] = 'SPACE_CUT_CIRCLE',
}

AbilityIntrinsecModDict = {
    -- 至暗无光
    [FourCC('A000')] = {'DEEP_SHADOW_CURSE_PROVIDER','DEEP_SHADOW_CREATURE', 'DEEP_SHADOW_CURSE_GRAND_PROVIDER'},
    -- 发光 500
    [FourCC('A002')] = {'ENLIGHTENED_PROVIDER'},
    -- 幽影生物
    [FourCC('A006')] = {'DEEP_SHADOW_CREATURE'},

    [FourCC('A00A')] = {'PUSH_FIST'},
    [FourCC('A00B')] = {'STORM_FORCE_FIELD'},
    [FourCC('A00C')] = {'INFERNAL_FLAME'},
    [FourCC('A00O')] = {'NEPHTIS_SOUL_CONVERT'},
    [FourCC('A00S')] = {'RED_DRAGON_ENVIRONMENT'},
    [FourCC('A00U')] = {'FREEZING_REALM'},
    [FourCC('A00Y')] = {'LIFE_BY_ATTACK_TIME'},
    [FourCC('A00Z')] = {'DAGONS_BLESS', 'OCEANUS_STRIKE'},
    [FourCC('AUav')] = {'BLOOD_THIRST_AURA'},
}


--------------------------------------------------------------
--------------------------------------------------------------

require('scripts.Misc')
require('scripts.Nephtis')
require('scripts.RedDragon')
--require('scripts.101FireWork')
require('scripts.IceMaiden')
require('scripts.NagaQueen')

do -- Ability Cast Trigger
    local trigger = CreateTrigger()
    local cond = Condition(function()
        local code_name = GetSpellAbilityId()
        if (AbilityCastDict[code_name] ~= nil) then
            AbilityScripts[AbilityCastDict[code_name]].Cast()
        else
            for id,script in pairs(AbilityScripts) do
                if (type(script) == 'table' and script.AbilityId == code_name) then
                    AbilityCastDict[code_name] = id
                    script.Cast()
                    return false
                end
            end
        end
        return false
    end)
    TriggerRegisterAnyUnitEventBJ(trigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    TriggerAddCondition(trigger, cond)
end

do -- Intrinsec Modifier Trigger
    local trigger = CreateTrigger()
    local cond = Condition(function()
        local learnedSkillId = GetLearnedSkill()
        if (AbilityIntrinsecModDict[learnedSkillId] ~= nil and GetLearnedSkillLevel() == 1) then
            local uw = UnitWrapper.Get(GetLearningUnit())
            for _,mid in ipairs(AbilityIntrinsecModDict[learnedSkillId]) do
                uw:AcquireModifierById(mid, uw, learnedSkillId)
            end
        end
        return false
    end)
    TriggerRegisterAnyUnitEventBJ(trigger, EVENT_PLAYER_HERO_SKILL)
    TriggerAddCondition(trigger, cond)

    local trigger2 = CreateTrigger()
    local cond2 = Condition(function()
        local unit = GetEnteringUnit()
        for aid,mids in pairs(AbilityIntrinsecModDict) do
            if (GetUnitAbilityLevel(unit, aid) > 0) then
                for _,mid in ipairs(mids) do
                    UnitWrapper.Get(unit):AcquireModifierById(mid, UnitWrapper.Get(unit), aid)
                end
            end
        end
        return false
    end)
    TriggerRegisterEnterRectSimple(trigger2, GetPlayableMapRect())
    TriggerAddCondition(trigger2, cond2)
end

AbilityScripts.SPAWN_TEST_UNITS = {
    AbilityId = FourCC('A00I'),
    RandomUnitPool = {
        FourCC('hfoo'),FourCC('hkni'),FourCC('hmpr'),FourCC('hmtt'),FourCC('ogru'),FourCC('otau'),FourCC('owyv')
    },
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local angle = GetUnitFacing(caster.unit)
        local x = GetUnitX(caster.unit) + 1500*CosBJ(angle)
        local y = GetUnitY(caster.unit) + 1500*SinBJ(angle)
        for i=10,1,-1 do
            local id = AbilityScripts.SPAWN_TEST_UNITS.RandomUnitPool[math.random(1,#AbilityScripts.SPAWN_TEST_UNITS.RandomUnitPool)]
            CreateUnit(Player(1), id, x, y, 293)
        end
    end
}]=]

P['ui/FrameLoader.lua'] = [[FrameLoader = {
    OnLoadTimer = function ()
        for _,v in ipairs(FrameLoader) do v() end

    end
    ,OnLoadAction = function()
        TimerStart(FrameLoader.Timer, 0, false, FrameLoader.OnLoadTimer)
     end
}
function FrameLoaderAdd(func)
    if not FrameLoader.Timer then
        FrameLoader.Trigger = CreateTrigger()
        FrameLoader.Timer = CreateTimer()
        TriggerRegisterGameEvent(FrameLoader.Trigger, EVENT_GAME_LOADED)
        TriggerAddAction(FrameLoader.Trigger, FrameLoader.OnLoadAction)
    end
    table.insert(FrameLoader, func)
end]]

P['ui/HideOriginal.lua'] = [[ UI = UI or {}

 UI.HideDefaultSettings = {
    UnitInfo = false,
    BuffBar = true
}

function UI.HideUnitInfoPanels()
    local function CustomStatMoveOutOfScreen(frame)
        BlzFrameClearAllPoints(frame)
        BlzFrameSetAbsPoint(frame, FRAMEPOINT_CENTER, 3, 0)
    end
    for index = 0, 5, 1 do
        CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconBackdrop", index))
    end
    CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconHeroIcon", 6))
    CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconAllyTitle", 7))
    CustomStatMoveOutOfScreen(BlzGetFrameByName("InfoPanelIconAllyGoldIcon", 7))
end

function UI.HideBuffBar()
    -- hide buff bar
    local newParent = BlzCreateFrameByType("SIMPLEFRAME", "", BlzGetFrameByName("ConsoleUI", 0), "", 0)
    BlzFrameSetVisible(newParent, false)
    BlzFrameSetParent(BlzGetOriginFrame(ORIGIN_FRAME_UNIT_PANEL_BUFF_BAR, 0), newParent)
end



do
    if (UI.HideDefaultSettings.UnitInfo) then
        UI.HideUnitInfoPanels()
    end
    if (UI.HideDefaultSettings.BuffBar) then
        UI.HideBuffBar()
    end
end]]

P['ui/ModifierBar.lua'] = [[require('ui.UITicker')
UI = UI or {}

UI.ModifierBar = {
    Enabled = true,
    Container = nil,
    SelectedUnit = nil,
    MaxIconNum = 15,
    IconSize = 0.02,
    Icons = {},
    Tooltips = {},
    Key = 'ModifierBar'
}

UI.ModifierBar.Init = function()
    local container = BlzCreateFrameByType("FRAME", "Container", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
    UI.ModifierBar.Container = container
    for i = 1, UI.ModifierBar.MaxIconNum, 1 do
        local icon = BlzCreateFrameByType("BACKDROP", "Button", container, "", i)
        local iconHover = BlzCreateFrameByType("FRAME", "ButtonFrame", icon, "", 0)
        BlzFrameSetAllPoints(iconHover, icon)
        local tooltipBackground = BlzCreateFrame("QuestButtonBaseTemplate", icon, 0, i)
        local tooltipText = BlzCreateFrameByType("TEXT", "ModifierTooltipText", tooltipBackground, "", i)

        BlzFrameSetSize(icon, UI.ModifierBar.IconSize, UI.ModifierBar.IconSize)
        BlzFrameSetAbsPoint(icon, FRAMEPOINT_TOPLEFT, 0.24 + (i - 1) * UI.ModifierBar.IconSize, 0.16)
        BlzFrameSetTexture(icon, "ReplaceableTextures\\CommandButtons\\BTNHeroPaladin", 0, true)

        BlzFrameSetSize(tooltipText, 0.24, 0)
        BlzFrameSetPoint(tooltipBackground, FRAMEPOINT_BOTTOMLEFT, tooltipText, FRAMEPOINT_BOTTOMLEFT, -0.01, -0.01)
        BlzFrameSetPoint(tooltipBackground, FRAMEPOINT_TOPRIGHT, tooltipText, FRAMEPOINT_TOPRIGHT, 0.01, 0.01)

        BlzFrameSetTooltip(iconHover, tooltipBackground)
        BlzFrameSetPoint(tooltipText, FRAMEPOINT_BOTTOM, icon, FRAMEPOINT_TOP, 0, 0.01)
        BlzFrameSetEnable(tooltipText, false)

        UI.ModifierBar.Icons[i] = icon
        UI.ModifierBar.Tooltips[i] = tooltipText
        BlzFrameSetText(tooltipText, 'Empty')
        BlzFrameSetVisible(icon, false)
    end
    BlzFrameSetVisible(container, false)
    local updateHandler = function()
        if UI.ModifierBar.SelectedUnit == nil then return end
        local index = 1
        for _, mod in pairs(UnitWrapper.Get(UI.ModifierBar.SelectedUnit).modifiers) do
            if index <= 15 then
                if not mod.hidden then
                    BlzFrameSetVisible(UI.ModifierBar.Icons[index], true)
                    BlzFrameSetTexture(UI.ModifierBar.Icons[index], mod.icon, 0, true)
                    BlzFrameSetText(UI.ModifierBar.Tooltips[index], mod:GetDescription())
                    index = index + 1
                end
            else
                break
            end
        end
        for i = index, UI.ModifierBar.MaxIconNum, 1 do
            BlzFrameSetVisible(UI.ModifierBar.Icons[i], false)
        end
    end

    local trig = CreateTrigger()
    TriggerAddAction(trig, function()
        if (GetTriggerPlayer() == GetLocalPlayer()) then
            if (GetTriggerUnit() ~= nil) then
                BlzFrameSetVisible(container, true)
                UI.ModifierBar.SelectedUnit = GetTriggerUnit()
            else
                BlzFrameSetVisible(container, false)
                UI.ModifierBar.SelectedUnit = nil
            end
        end
    end)
    local player = 0
    repeat
        TriggerRegisterPlayerSelectionEventBJ(trig, Player(player), true)
        --TriggerRegisterPlayerSelectionEventBJ(trig, Player(index), false)
        player = player + 1
    until player == bj_MAX_PLAYER_SLOTS

    UITicker.AddHandler(UI.ModifierBar.Key, updateHandler)
end

do
    if UI.ModifierBar.Enabled == true then
        UI.ModifierBar.Init()
    end
end]]

P['ui/UITicker.lua'] = [[UITicker = {
    timer = CreateTimer(),
    interval = 1/10,
    handlers = {},
    Init = function()
        TimerStart(UITicker.timer, UITicker.interval, true, function()
            for _,h in pairs(UITicker.handlers) do
                h(UITicker.interval)
            end
        end)
    end,
    AddHandler = function(key, h)
        if (UITicker.handlers[key] == nil) then
            UITicker.handlers[key] = h
        end
    end,
    DeleteHandler = function(key)
        if (UITicker.handlers[key] ~= nil) then
            UITicker.handlers[key] = nil
        end
    end
}

do
    UITicker.Init()
end]]

P['ui/init.lua'] = [[require('ui.UITicker')
require('ui.HideOriginal')
require('ui.ModifierBar')]]

P['utils.lua'] = [=[-- table extend

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
end]=]

P['origwar3map.lua'] = [[gg_trg_Untitled_Trigger_001 = nil
gg_trg_Untitled_Trigger_001_______u = nil
gg_trg_Untitled_Trigger_001______________u = nil
gg_trg_Untitled_Trigger_001_____________________u = nil
function InitGlobals()
end

function InitCustomPlayerSlots()
SetPlayerStartLocation(Player(0), 0)
SetPlayerColor(Player(0), ConvertPlayerColor(0))
SetPlayerRacePreference(Player(0), RACE_PREF_HUMAN)
SetPlayerRaceSelectable(Player(0), true)
SetPlayerController(Player(0), MAP_CONTROL_USER)
end

function InitCustomTeams()
SetPlayerTeam(Player(0), 0)
end

function main()
SetCameraBounds(-11520.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -11776.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), -11520.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -11776.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
NewSoundEnvironment("Default")
SetAmbientDaySound("LordaeronSummerDay")
SetAmbientNightSound("LordaeronSummerNight")
SetMapMusic("Music", true, 0)
InitBlizzard()
InitGlobals()
end

function config()
SetMapName("TRIGSTR_001")
SetMapDescription("")
SetPlayers(1)
SetTeams(1)
SetGamePlacement(MAP_PLACEMENT_USE_MAP_SETTINGS)
DefineStartLocation(0, -192.0, -192.0)
InitCustomPlayerSlots()
SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
InitGenericPlayerSlots()
end]]


dofile('origwar3map.lua')
local __main = main

function main()
    xpcall(function()
        
        __main()
        
        dofile('main.lua')
    end, function(msg)
        local handler = geterrorhandler()
        if handler and msg then
            return handler(msg)
        end
    end)
end

--[==[
main()
]==]--
