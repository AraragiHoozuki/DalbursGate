require('gameSystem')
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
        ProbabilityPerHPRateLost = {1, 1.2, 1.4, 1.6},
        HPDrainRate = {100}
    },
    ---@param this Modifier
    ---@param damage Damage
    DealDamage = function(this, damage)
        local p = this:LV('ProbabilityPerHPRateLost') * (1 - GetWidgetLife(this.owner.unit)/BlzGetUnitMaxHP(this.owner.unit)) * 100
        if damage.atktype == Damage.ATTACK_TYPE_MELEE and math.random(0,100) < p then
            local heal = Damage:ctor{
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
        DestroyEffect(AddSpecialEffect([[Abilities\Spells\Orc\WarStomp\WarStompCaster.mdl]], this.position.x, this.position.y))
        this.CustomValues.BounceCount = this.CustomValues.BounceCount + 1
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(GetFilterUnit(), UNIT_TYPE_DEAD)) and IsUnitEnemy(unit, this:GetPlayer()) then
                local damage = Damage:ctor{
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
                local a = - v / 0.4
                UnitWrapper.Get(unit):AddDisplace(Displace:ctor{
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
        Range = {900,900,900,900}
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
        GroupEnumUnitsInRange(this.apply_checker_group, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
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
    Effects = {{
        model = [[Abilities\Spells\Orc\Bloodlust\BloodlustTarget.mdl]],
        attach_point = 'hand left'
    }},
    BindAbility = FourCC('AUav'),
    LevelValues = {
        HPDrainRate = {15,25,40,50}
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
            local heal = Damage:ctor{
                source = this.owner,
                target = this.owner,
                amount = damage.amount * this:LV('HPDrainRate') / 100,
                atktype = Damage.ATTACK_TYPE_UNKNOWN,
                dmgtype = Damage.DAMAGE_TYPE_HEAL,
                eletype = Damage.ELEMENT_TYPE_NONE,
            }
            heal:Resolve()
            DestroyEffect(AddSpecialEffect([[Abilities\Spells\Human\Heal\HealTarget.mdl]], GetUnitX(this.owner.unit), GetUnitY(this.owner.unit)))
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
        local mod = caster:ApplyModifierById('SLEEPINESS_SETS_IN', target)
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
    Effects = {{
        model = [[Abilities\Spells\Other\CreepSleep\CreepSleepTarget.mdl]],
        attach_point = 'overhead'
    }},
    BindAbility = AbilityScripts.SLEEPINESS_SETS_IN.AbilityId,
    LevelValues = {
        Range = {600}
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
            GroupEnumUnitsInRange(Modifier.TempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'), cond)
        else
            if this.CustomValues.Sleeping == true then
                this:Remove()
            elseif this.stack >= this.max_stack then
                UnitMgr.DummySpellTarget(this.applier.unit, this.owner.unit, CommonAbilitiy.Sleep, 1, 'sleep')
                DestroyEffect(AddSpecialEffectTarget([[Abilities\Spells\Undead\Sleep\SleepSpecialArt.mdl]], this.owner.unit, 'overhead'))
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
        local front = MapObject:ctor(x0 + 100 * Cos(direction), y0 + 100 * Sin(direction), 0, direction, [[Doodads\Dungeon\Props\Forcewall\Forcewall]], AbilityScripts.SPACE_CUT_CIRCLE.Duration)
        local back = MapObject:ctor(x0 - 100 * Cos(direction), y0 - 100 * Sin(direction), 0, direction + math.pi, [[Doodads\Dungeon\Props\Forcewall\Forcewall]], AbilityScripts.SPACE_CUT_CIRCLE.Duration)
        local update = function(this)
            for _,prjt in pairs(ProjectilMgr.Instances) do
                local theta = math.atan(-this.position.y + prjt.position.y, -this.position.x + prjt.position.x)
                local dis = this.position:DistanceTo(prjt.position)
                local dy = Sin(math.angleDiff(math.pi/2, (this.yaw - theta))) * dis
                local dx = Cos(math.angleDiff(math.pi/2, (this.yaw - theta))) * dis
                if (math.abs(dx) <= 300 and math.abs(dy) <= 10 and math.abs(math.angleDiff(this.yaw + math.pi, prjt.yaw))<= math.pi/2) then
                    local eff
                    eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]], prjt.position.x, prjt.position.y)
                    DestroyEffect(eff)
                    prjt:MoveTo(prjt.position.x - 200 * Cos(this.yaw), 
                    prjt.position.y - 200 * Sin(this.yaw))
                    eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkTarget.mdl]], prjt.position.x, prjt.position.y)
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
        local mo = MapObject:ctor(x,y,10,0,[[Abilities\Spells\Orc\Voodoo\VoodooAura.mdl]],30)
        mo:ScaleModel(1.2)
        mo:AddUpdateHandler(function(this)
            for _,prjt in pairs(ProjectilMgr.Instances) do
                local d = this.position:DistanceTo(prjt.position)
                if (d<=240 and d >= 200) then
                    local p2c = math.atan(this.position.y - prjt.position.y, this.position.x-prjt.position.x)
                    local a = math.angleDiff(p2c, prjt.yaw)
                    
                    if (a<math.pi/2 and a > -math.pi/2) then
                        local eff
                        eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkCaster.mdl]], prjt.position.x, prjt.position.y)
                        BlzSetSpecialEffectZ(eff, prjt.position.z)
                        DestroyEffect(eff)
                        prjt:MoveTo(
                            prjt.position.x + (this.position.x - prjt.position.x) * 2,
                            prjt.position.y + (this.position.y - prjt.position.y) * 2
                        )
                        eff = AddSpecialEffect([[Abilities\Spells\NightElf\Blink\BlinkTarget.mdl]], prjt.position.x, prjt.position.y)
                        BlzSetSpecialEffectZ(eff, prjt.position.z)
                        DestroyEffect(eff)
                    end
                end
            end
        end)
    end
}