require('gameSystem')
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