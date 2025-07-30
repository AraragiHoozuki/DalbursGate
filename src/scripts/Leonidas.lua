Master.Modifier.NO_FEAR_AURA = {
    id = 'NO_FEAR_AURA',
    icon = [[ReplaceableTextures\PassiveButtons\PASBTNCommand.blp]],
    title = '无畏光环',
    description = '对周围$Range$范围内的队友施加无畏光环效果，其死亡时对周围$EffectRange$范围内的友军单位赋予【无畏】效果，持续$Duration$秒，重复赋予时叠加层数并刷新持续时间。\n无畏：攻击速度+30%，每增加1层，再加15%攻击速度，达到5层时，获得在无畏效果期间受到任何伤害都不会死亡的效果。',
    duration = -1,
    interval = 0.9,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    BindAbility = FourCC('A013'),
    Effects = { {
        model = [[Abilities\Spells\Orc\CommandAura\CommandAura.mdl]],
        attach_point = 'origin'
    } },
    LevelValues = {
        Range = { 900 },
        EffectRange = {300},
        Duration = {6},
    },
    hidden = true,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitAlly(unit, GetOwningPlayer(this.owner.unit)) then
                this.owner:ApplyModifier(Master.Modifier.NO_FEAR_AURA_EFFECT, UnitWrapper.Get(unit))
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        DestroyBoolExpr(cond)
    end
}

Master.Modifier.NO_FEAR_AURA_EFFECT= {
    id = 'NO_FEAR_AURA_EFFECT',
    icon = [[ReplaceableTextures\PassiveButtons\PASBTNCommand.blp]],
    title = '无畏光环效果',
    description = '死亡时对周围300范围内的友军单位赋予【无畏】效果，持续6秒，重复赋予时叠加层数并刷新持续时间。\n无畏：攻击速度+30%，每增加1层，再加15%攻击速度，达到5层时，获得在无畏效果期间受到任何伤害都不会死亡的效果。',
    duration = 1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    BindAbility = FourCC('A013'),
    Effects = { {
        model = [[Abilities\Spells\Other\GeneralAuraTarget\GeneralAuraTarget.mdl]],
        attach_point = 'origin'
    } },
    LevelValues = {
        Range = Master.Modifier.NO_FEAR_AURA.LevelValues.EffectRange,
    },
    ---@param this Modifier
    OnDeath = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitAlly(unit, GetOwningPlayer(this.owner.unit)) then
                this.owner:ApplyModifier(Master.Modifier.NO_FEAR_AURA_ACTIVATED_EFFECT, UnitWrapper.Get(unit))
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        DestroyBoolExpr(cond)
        DestroyEffect(AddSpecialEffect([[Abilities\Spells\Undead\UnholyFrenzyAOE\UnholyFrenzyAOETarget.mdl]], GetUnitX(this.owner.unit), GetUnitY(this.owner.unit)))
    end
}

Master.Modifier.NO_FEAR_AURA_ACTIVATED_EFFECT= {
    id = 'NO_FEAR_AURA_ACTIVATED_EFFECT',
    icon = [[ReplaceableTextures\PassiveButtons\PASBTNCommand.blp]],
    title = '无畏',
    description = '攻击速度+30%，每增加1层，再加15%攻击速度，达到5层时，获得在无畏效果期间受到任何伤害都不会死亡的效果。',
    duration = 6,
    interval = 1,
    max_stack = 5,
    reapply_mode = Modifier.REAPPLY_MODE.STACK_AND_REFRESH,
    BindAbility = FourCC('A013'),
    Effects = { {
        model = [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]],
        attach_point = 'hands'
    } },
    LevelValues = {
        EffectRange = Master.Modifier.NO_FEAR_AURA.LevelValues.EffectRange,
        Duration = Master.Modifier.NO_FEAR_AURA.LevelValues.Duration,
    },
    ---@param this Modifier
    OnAcquired = function(this)
        this.owner:AddAttackSpeed(0.3)
        this.CustomValues.BonusAttackSpeed = 0.30
    end,
    OnStack = function(this, stack)
        this.owner:AddAttackSpeed(- this.CustomValues.BonusAttackSpeed)
        this.owner:AddAttackSpeed(0.15 + 0.15 * stack)
        this.CustomValues.BonusAttackSpeed = 0.15 + 0.15 * stack
    end,
    OnRemoved = function(this)
        this.owner:AddAttackSpeed(- this.CustomValues.BonusAttackSpeed)
        this.CustomValues.BonusAttackSpeed = 0
    end,
    OnStartTakeDamage = function(this, damage)
        if (this.stack >= 5 and damage.amount>=GetWidgetLife(this.owner.unit)) then
            damage.amount = GetWidgetLife(this.owner.unit) - 1
        end
    end,
}

Master.Modifier.LEONIDAS_LEGACY = {
    id = 'LEONIDAS_LEGACY',
    icon = [[ReplaceableTextures\PassiveButtons\PASBTNCommand.blp]],
    title = '遗志',
    description = '当自身死亡时，为周围友军恢复$HPRegenRate$%生命值。同时在原地留下一个遗志守卫，持续到自身复活。\n遗志守卫提供与单位死亡前相同的「无畏光环」效果，此外还能为范围内友军增加$InitialAtkBonus$点攻击力，每当范围内有友军死亡时，增加攻击力效果再增加$AtkBonusPerDeath$点。',
    duration = -1,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    BindAbility = FourCC('A014'),
    Effects = { },
    LevelValues = {
        HPRegenRate = { 50 },
        HPRegenRange = {900},
        InitialAtkBonus = {30},
        AtkBonusPerDeath = {10},
        SummonWardType = {FourCC('o003')}
    },
    ---@param this Modifier
    OnDeath = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitAlly(unit, GetOwningPlayer(this.owner.unit)) then
                Damage:ctor{
                    source = this.owner,
                    target = UnitWrapper.Get(unit),
                    amount = GetWidgetLife(unit) * this:LV('HPRegenRate') / 100,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_HEAL,
                    eletype = Damage.ELEMENT_TYPE_NONE,
                }:Apply()
                DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\Undead\VampiricAura\VampiricAuraTarget.mdl]], unit, 'chest'))
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('HPRegenRange'), cond)
        DestroyBoolExpr(cond)
        local ward = CreateUnit(GetOwningPlayer(this.owner.unit), this:LV('SummonWardType'), GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), 0)
        AbilityScripts.AddAbilityWithIntrinsecModifier(ward, Master.Modifier.NO_FEAR_AURA.BindAbility)
        UnitWrapper.Get(ward):AcquireModifierById('LEONIDAS_LEGACY_ATTACK_AURA', this.owner, this.ability)
    end
}

Master.Modifier.LEONIDAS_LEGACY_ATTACK_AURA = {
    id = 'LEONIDAS_LEGACY_ATTACK_AURA',
    icon = [[]],
    title = '遗志（攻击加成）',
    description = '',
    duration = -1,
    interval = 0.9,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    BindAbility = FourCC('A014'),
    Effects = { {
        model = [[Abilities\Spells\Orc\CommandAura\CommandAura.mdl]],
        attach_point = 'origin'
    } },
    LevelValues = {
        Range = { 900 },
        InitialAtkBonus = Master.Modifier.LEONIDAS_LEGACY.LevelValues.InitialAtkBonus,
        AtkBonusPerDeath = Master.Modifier.LEONIDAS_LEGACY.LevelValues.AtkBonusPerDeath,
    },
    hidden = true,
    OnAcquired = function(this)
        this.CustomValues.TotalAttackBonus = this:LV('InitialAtkBonus')
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitAlly(unit, GetOwningPlayer(this.owner.unit)) then
                this.owner:ApplyModifier(Master.Modifier.LEONIDAS_LEGACY_ATTACK_AURA_EFFECT, UnitWrapper.Get(unit), this.ability)
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        DestroyBoolExpr(cond)
    end
}

Master.Modifier.LEONIDAS_LEGACY_ATTACK_AURA_EFFECT= {
    id = 'LEONIDAS_LEGACY_ATTACK_AURA_EFFECT',
    icon = [[ReplaceableTextures\PassiveButtons\PASBTNMarkOfFire.blp]],
    title = '遗志激励',
    description = '这个单位攻击力增加@BonusAttack@点',
    duration = 1,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {},
    ---@param this Modifier
    OnAcquired = function(this)
        this.CustomValues.BonusAttack = 0
        this.CustomValues.SourceAura = this.applier:GetAffectedModifier('LEONIDAS_LEGACY_ATTACK_AURA')
    end,
    ---@param this Modifier
    OnDeath = function(this)
        
        local aura = this.CustomValues.SourceAura
        if aura ~= nil then
            aura.CustomValues.TotalAttackBonus = aura.CustomValues.TotalAttackBonus + aura:LV('AtkBonusPerDeath')
        end
    end,
    ---@param this Modifier
    Update = function(this)
        this.owner:AddAttack(-this.CustomValues.BonusAttack)
        this.CustomValues.BonusAttack = this.CustomValues.SourceAura.CustomValues.TotalAttackBonus
        this.owner:AddAttack(this.CustomValues.BonusAttack)
    end,
    ---@param this Modifier
    OnRemoved = function(this)
        this.owner:AddAttack(-this.CustomValues.BonusAttack)
        this.CustomValues.BonusAttack = 0
    end,
}