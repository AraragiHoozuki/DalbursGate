require('gameSystem')
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
}
