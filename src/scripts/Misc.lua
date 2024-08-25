require('gameSystem')
require('master')

--虚空祝福
--[[
受到伤害时，若伤害值
--]]
Master.Modifier.VOID_BLESS = {
    id = 'VOID_BLESS',
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
    TakeDamage = function(this, damage)
    end,
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
    end
}

--推拳：近战攻击击退敌人
Master.Modifier.PUSH_FIST = {
    id = 'PUSH_FIST',
    duration = -1,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A00A'),
    LevelValues = {
        PushVelocity = {1000,1200,1400,1600},
        PushDuration = {0.3}
    },

    ---@param this Modifier
    ---@param damage Damage
    DealDamage = function(this, damage)
        if damage.atktype == Damage.ATTACK_TYPE_MELEE then
            local dx = GetUnitX(damage.target.unit) - GetUnitX(this.owner.unit)
            local dy = GetUnitY(damage.target.unit) - GetUnitY(this.owner.unit)
            local r = math.atan(dy, dx)
            local v = this:LV('PushVelocity') 
            local a = - v / this:LV('PushDuration')
            
            damage.target:AddDisplace(Displace:new{
                velocity = Vector3:new(nil, v * Cos(r), v * Sin(r), 0),
                accelerate = Vector3:new(nil, a * Cos(r), a * Sin(r), 0),
                max_distance = 0,
                max_duration = this:LV('PushDuration'),
                interruptible = true,
                interrupt_action = true,
                efx = [[Objects\Spawnmodels\Human\HumanLargeDeathExplode\HumanLargeDeathExplode.mdl]],
                efx_interval = 1,
            })
        end
    end,
}

--风暴力场：受到近战攻击时，击退对手
Master.Modifier.STORM_FORCE_FIELD = {
    id = 'STORM_FORCE_FIELD',
    duration = -1,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A00B'),
    LevelValues = {
        PushVelocity = {1000,1200,1400,1600},
        PushDuration = {0.3}
    },
    ---@param this Modifier
    ---@param damage Damage
    TakeDamage = function(this, damage)
        if damage.atktype == Damage.ATTACK_TYPE_MELEE then
            local dx = GetUnitX(damage.source.unit) - GetUnitX(this.owner.unit)
            local dy = GetUnitY(damage.source.unit) - GetUnitY(this.owner.unit)
            local r = math.atan(dy, dx)
            local v = this:LV('PushVelocity')
            local a = - v / this:LV('PushDuration')
            damage.source:AddDisplace(Displace:new{
                velocity = Vector3:new(nil, v * Cos(r), v * Sin(r), 0),
                accelerate = Vector3:new(nil, a * Cos(r), a * Sin(r), 0),
                max_distance = 0,
                max_duration = this:LV('PushDuration'),
                interruptible = true,
                interrupt_action = true,
                efx = nil,
                efx_interval = 1,
            })
            DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\Other\Tornado\TornadoElementalSmall.mdl]], this.owner.unit, 'origin'))
        end
    end,
}

--地狱之炎：对周围敌人每秒造成灼热伤害，每过3秒，伤害增加
Master.Modifier.INFERNAL_FLAME = {
    id = 'INFERNAL_FLAME',
    duration = -1,
    interval = 0.2,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {{
        model = [[Abilities\Spells\Orc\LiquidFire\Liquidfire.mdl]],
        attach_point = 'origin',
    }},
    BindAbility = FourCC('A00C'),
    LevelValues = {
        Range = {250},
    },
    ---@param this Modifier
    Acquire = function(this) 
        this.apply_checker_group = CreateGroup()
        this.apply_cond = Condition(function()
            if (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and 
            (IsUnitEnemy(GetFilterUnit(), GetOwningPlayer(this.owner.unit))) then
                local u = GetFilterUnit()
                this.owner:ApplyModifierById('INFERNAL_FLAME_TARGET', LuaUnit.Get(u), this.ability)
            end
            return false
        end)
    end,
    ---@param this Modifier
    Update = function(this)
        GroupEnumUnitsInRange(this.apply_checker_group, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), this.apply_cond)
    end,
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
        DestroyBoolExpr(this.apply_cond)
    end
}
Master.Modifier.INFERNAL_FLAME_TARGET = {
    id = 'INFERNAL_FLAME_TARGET',
    duration = 1.1,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    remove_on_death = false,
    Effects = {{
        model = [[Abilities\Spells\Human\FlameStrike\FlameStrikeDamageTarget.mdl]],
        attach_point = 'overhead'
    }},
    BindAbility = Master.Modifier.INFERNAL_FLAME.BindAbility,
    LevelValues = {
        BaseDamage = {15},
        DamagePlus = {5}
    },
    ---@param this Modifier
    Acquire = function(this) 
        this.elapsed_time = 0
        this.plus_damage = 0
    end,
    ---@param this Modifier
    Update = function(this)
        this.elapsed_time = this.elapsed_time + this.interval
        if (this.elapsed_time > 3) then
            this.elapsed_time = this.elapsed_time - 3
            this.plus_damage = this.plus_damage + this:LV('DamagePlus')
            DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\Other\Doom\DoomDeath.mdl]], this.owner.unit, 'origin'))
        end
        local damage = Damage:ctor{
            source = this.applier,
            target = this.owner,
            amount = this:LV('BaseDamage') + this.plus_damage,
            atktype = Damage.ATTACK_TYPE_SPELL,
            dmgtype = Damage.DAMAGE_TYPE_DOT,
            eletype = Damage.ELEMENT_TYPE_THERMO,
        }
        damage:Resolve()
    end
}

AbilityScripts.INFERNAL_METEOR = {
    AbilityId = FourCC('A00D'),
    Cast = function()
        local u = GetTriggerUnit()
        local x = GetSpellTargetX()
        local y = GetSpellTargetY()
        local caster = LuaUnit.Get(u)
        local prjt = ProjectilMgr.CreateProjectilById('INFERNAL_METEOR', caster, nil, Vector3:new(nil, x, y), {}, 1)
        prjt:SetXYZ(GetUnitX(u), GetUnitY(u), 600)
    end
}

Master.Projectil.INFERNAL_METEOR = {
    model = [[Abilities\Weapons\DemonHunterMissile\DemonHunterMissile.mdl]],
    scale = 1,
    velocity = 900,
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
    track_type = Projectil.TRACK_TYPE_POSITION,
    trackZ = true,
    tracking_angle = 360 * math.degree,
    turning_speed = 360 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    LevelValues = {},
    ---@param this Projectil
    CustomTrack = function(this)
        if (this.flying_time < 3) then
            this.velocity = 0
            this.scale = this.scale + 3/60
            this:UpdateScale()
            this.ascending = true
        elseif this.ascending == true then
            this.ascending = false
            this.velocity = this.settings.velocity
        else
            this:TrackXY()
            this:TrackZ()
        end
    end,
    Hit = function(this)
        this:End()
    end
}


AbilityScripts.ASTER_CAPT = {
    AbilityId = FourCC('A00E'),
    Cast = function()
        local u = GetTriggerUnit()
        local x = GetUnitX(u)
        local y = GetUnitY(u)
        for _,prjt in pairs(ProjectilMgr.Projectils) do
            if ( (not prjt.paused) and IsUnitEnemy(prjt.emitter.unit, GetOwningPlayer(u)) ) then
                local dis = prjt.position:Distance(x, y)
                if (dis <= 300) then
                    prjt:Pause()
                    DestroyEffect(prjt.bullet)
                    DestroyEffect(AddSpecialEffect('Abilities\\Spells\\NightElf\\Blink\\BlinkTarget.mdl',prjt.position.x, prjt.position.y))
                    local lu = LuaUnit.Get(u)
                    local mod = Modifier.CreateById(lu, 'ASTER_CAPT_TIMER', lu)
                    lu:CheckModifierReapply(mod)
                    mod.prjt_bullet = AddSpecialEffectTarget(prjt.model, u, 'hand')
                    mod.prjt = prjt
                    UnitRemoveAbility(u, AbilityScripts.ASTER_CAPT.AbilityId)
                    UnitAddAbility(u, AbilityScripts.ASTER_CAPT_RECAST.AbilityId)
                    break
                end
            end
        end
    end
}

AbilityScripts.ASTER_CAPT_RECAST = {
    AbilityId = FourCC('A00F'),
    Cast = function()
        local u = GetTriggerUnit()
        local lu = LuaUnit.Get(u)
        local x = GetUnitX(u)
        local y = GetUnitY(u)
        local tx = GetSpellTargetX()
        local ty = GetSpellTargetY()
        local mod = lu:GetAffectedModifier('ASTER_CAPT_TIMER')
        if (mod ~= nil) then
            local prjt = mod.prjt
            local r = math.atan(ty - y, tx - x)
            prjt:SetXYZ(x + 100 * Cos(r), y + 100 * Sin(r))
            prjt.bullet = AddSpecialEffect(prjt.model, prjt.position.x, prjt.position.y)
            prjt.flying_time = 0
            prjt.flying_distance = 0
            prjt.target_unit = nil
            prjt.target_position = nil
            prjt.yaw = r
            prjt.emitter = lu
            prjt:Unpause()
            mod:Remove()
        end
    end
}

Master.Modifier.ASTER_CAPT_TIMER = {
    id = 'ASTER_CAPT_TIMER',
    duration = 5,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = true,
    Effects = {},
    LevelValues = {},
    ---@param this Modifier
    Remove = function(this)
        DestroyEffect(this.prjt_bullet)
        if (this.prjt.paused) then
            this.prjt:End()
        end
        UnitAddAbility(this.owner.unit, AbilityScripts.ASTER_CAPT.AbilityId)
        UnitRemoveAbility(this.owner.unit, AbilityScripts.ASTER_CAPT_RECAST.AbilityId)
        BlzStartUnitAbilityCooldown(this.owner.unit, AbilityScripts.ASTER_CAPT.AbilityId, 3)
    end,
}