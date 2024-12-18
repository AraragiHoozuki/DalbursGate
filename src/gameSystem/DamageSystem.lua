---@class Damage
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
end