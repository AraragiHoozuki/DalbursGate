require('gameSystem')
require('master')

-- 灵魂转化
Master.Modifier.NEPHTIS_SOUL_CONVERT = {
    id = 'NEPHTIS_SOUL_CONVERT',
    duration = -1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    stack = 1,
    remove_on_death = false,
    tags = {},
    Effects = {{
        model = [[Abilities\Spells\NightElf\TargetArtLumber\TargetArtLumber.mdl]],
        attach_point  = 'origin'
    }},
    ---@param this Modifier
    Acquire = function(this)
        this.apply_checker_group = CreateGroup()
        this.CustomValues = {
            DetectRange = 1200
        }
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local u = GetFilterUnit()
            if (IsUnitType(u, UNIT_TYPE_DEAD)) then
                local p = Projectil:ctor{
                    emitter = this.owner,
                    target_unit = this.owner.unit,
                    x = GetUnitX(u),
                    y = GetUnitY(u),
                    z = 0,
                    settings = Master.Projectil.NEPHTIS_SOUL_CONVERT_PRJT
                }
                p:ChangeModel([[]])
                UnitMgr.RemoveUnit(u)
            end
            return false
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, 
            GetUnitX(this.owner.unit), 
            GetUnitY(this.owner.unit), 
            this.CustomValues.DetectRange, cond
        )
        DestroyBoolExpr(cond)
    end
}

Master.Projectil.NEPHTIS_SOUL_CONVERT_PRJT = {
    model = [[Abilities\Weapons\NecromancerMissile\NecromancerMissile.mdl]],
    scale = 1,
    velocity = 400,
    velocityZ = 0,
    velocityZMax = 99999,
    no_gravity = true,
    hit_range = 50,
    hit_rangeZ = 50,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_UNIT,
    trackZ = true,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    max_flying_distance = 99999,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    LevelValues = {},
    Hit = function(this)
        this:End()
    end
}

-- 灵魂连接
--[[
使目标与自己共享生命，当双方生命百分比不同时，
较高的一方生命值会流向较低的一方，最高每秒转移50/100/150/200点生命
]]
AbilityScripts.NEPHTIS_SOUL_LINK = {
    AbilityId = FourCC('A00H'),
    Cast = function()
        local caster = LuaUnit.Get(GetTriggerUnit())
        local target = LuaUnit.Get(GetSpellTargetUnit())
        caster:ApplyModifierById('NEPHTIS_SOUL_LINK', target, AbilityScripts.NEPHTIS_SOUL_LINK.AbilityId)
    end
}
Master.Modifier.NEPHTIS_SOUL_LINK = {
    id = 'NEPHTIS_SOUL_LINK',
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
