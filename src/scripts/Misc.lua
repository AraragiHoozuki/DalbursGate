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
    OnCreated = function(this)
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
        local mod = caster:ApplyModifierById('SLEEPINESS_SETS_IN', target)
        -- local mod = caster:ApplyModifierById('SOUL_ABSORB_TARGET', target)
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

--[[
]]--
AbilityScripts.HELICOPTER_FALL = {
    --AbilityId = FourCC('A00P'),
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
}

AbilityScripts.SINE_BULLET = {
    --AbilityId = FourCC('A00P'),
    LINE_SPEED = 500,
    Cast = function()
        AbilityScripts.SINE_BULLET.Effect(
            UnitWrapper.Get(GetTriggerUnit()),
            GetSpellTargetX(),
            GetSpellTargetY()
        )
    end,
    Effect = function(caster, x, y)
        local origin_x = caster:GetX()
        local origin_y = caster:GetY()
        local model = AddSpecialEffect([[Effects\FrostBoltV1.mdx]], origin_x, origin_y)
        local orientation = math.atan(y - origin_y, x - origin_x)
        local distance = 0
        
        local id = GUID.generate() --生成id
        -- 将循环动作附加到主循环
        CoreTicker.AttachAction(function(interval)
            distance = distance + AbilityScripts.SINE_BULLET.LINE_SPEED * interval
            local y0 = Sin(distance*2*math.pi/300) * 200
            local x0 = distance
            local x1 = x0 * Cos(orientation) - y0 * Sin(orientation) + origin_x
            local y1 = x0 * Sin(orientation) + y0 * Cos(orientation) + origin_y
            BlzSetSpecialEffectX(model, x1)
            BlzSetSpecialEffectY(model, y1)
            --调整模型面向角度，始终朝向正弦切线方向
            BlzSetSpecialEffectYaw(model, math.atan(Cos(distance*2*math.pi/300)) + orientation)
            -- 满足条件时，结束循环
            if distance > 1500 then
                CoreTicker.DetachAction(id)
                DestroyEffect(model)
            end
        end,nil,id)
    end
}


-- 闪电风暴攻击
Master.Modifier.LIGHTNING_STORM = {
    id = 'LIGHTNING_STORM',
    icon = [[ReplaceableTextures\CommandButtons\BTNDefendStop.blp]],
    title = '闪电风暴攻击',
    description = '',
    duration = -1,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A016'),
    ---@param this Modifier
    ---@param damage Damage
    OnDealDamage = function(this, damage)
        if   damage.atktype == Damage.ATTACK_TYPE_PROJECTIL then
            local x = this.owner:GetX()
            local y = this.owner:GetY()
            local tx = damage.target:GetX()
            local ty = damage.target:GetY()
            lightning = AddLightningEx('CLPB', false,x,y, Entity.GetLocationZ(x,y)+200,tx, ty,Entity.GetLocationZ(tx, ty))
            local id = GUID.generate()
            local count = 0
            CoreTicker.AttachAction(function()
                local nx = damage.target:GetX()
                local ny = damage.target:GetY()
                local distance = math.sqrt((nx - tx) * (nx - tx) + (ny - ty) * (ny - ty))
                if distance > 25 then
                    distance = 25
                end
                local r = math.atan(ny - ty, nx - tx)
                tx = tx + distance*Cos(r)
                ty = ty + distance*Sin(r)
                MoveLightningEx(lightning, false, x, y,  Entity.GetLocationZ(x,y)+200, tx, ty, Entity.GetLocationZ(tx, ty))
                DestroyEffect(AddSpecialEffect([[Abilities\Weapons\Bolt\BoltImpact.mdl]], tx, ty))              
                DestroyEffect(AddSpecialEffect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]], tx, ty))              
                local cond = Condition(function()
                    local u = GetFilterUnit()
                    if not IsUnitType(u, UNIT_TYPE_DEAD)
                        and IsUnitEnemy(u, GetOwningPlayer(this.owner.unit)) then
                        local uw = UnitWrapper.Get(u)
                        Damage:ctor {
                            amount = 25,
                            source = this.owner,
                            target = uw,
                            atktype = Damage.ATTACK_TYPE_SPELL,
                            dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                            eletype = Damage.ELEMENT_TYPE_ELECTRIC
                        }:Resolve()
                    end
                    return false
                end)
                GroupEnumUnitsInRange(Entity.TempGroup, 
                    tx, 
                    ty, 
                    200, cond
                )
                DestroyBoolExpr(cond)
                count = count + 1
                if count >= 8 then
                    DestroyLightning(lightning)
                    CoreTicker.DetachAction(id)
                end
                
            end, 0.1, id)
        end
    end
}

Master.DefaultAttackProjectil[FourCC('h003')] = {
    model = [[Abilities\\Weapons\\LichMissile\\LichMissile.mdl]],
    speed = 6000,
    no_gravity = true,
    hit_range = 50,
    hit_terrain = false,
    hit_other = false,
    hit_ally = true,
    hit_piercing = false,
    track_type = Projectil.TRACK_TYPE_UNIT,
    trackZ = true,
    tracking_angle = 3600 * math.degree,
    turning_speed = 3600 * math.degree,
    turning_speed_pitch = 3600 * math.degree,
    max_flying_distance = 3000,
}

-- 导弹
AbilityScripts.BALLISTIC_MISSILE = {
    AbilityId = FourCC('A00P'), -- TBD
    Cast = function()
        AbilityScripts.BALLISTIC_MISSILE.Effect(
            UnitWrapper.Get(GetTriggerUnit()),
            GetSpellTargetX(),
            GetSpellTargetY()
        )
    end,
    Effect = function(caster, tx, ty)
        local tloc = Vector3:ctor {
            x = tx,
            y = ty,
            z = 0
        }
        tloc.z = Projectil.GetLocationZ(tloc.x, tloc.y)
        Projectil:ctor {
            emitter = caster,
            x = caster:GetX(),
            y = caster:GetY(),
            z = Entity.GetUnitZ(caster.unit) + 200,
            target_position = tloc,
            settings = Master.Projectil.BALLISTIC_MISSILE
        }
    end
}
Master.Projectil.BALLISTIC_MISSILE = {
    model = [[Abilities\Weapons\CannonTowerMissile\CannonTowerMissile.mdl]],
    model_scale = 2,
    speed = 300,
    no_gravity = true,
    hit_range = 50,
    hit_terrain = true,
    hit_other = true,
    hit_ally = true,
    hit_piercing = false,
    track_type = Projectil.TRACK_TYPE_POSITION,
    tracking_angle = 120 * math.degree,
    turning_speed = 90 * math.degree,
    turning_speed_pitch = 0,
    max_flying_distance = 6000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 50,
    ---@param this Projectil
    OnCreated = function(this)
        this.pitch = 90 * math.degree
        this:AdjustVelocity()
        this.CustomValues.ChangedToStep2 = false
        this.CustomValues.ChangedToStep3 = false
    end,
    ---@param this Projectil
    CustomTrack = function(this)
        if(this.flying_time > 0.8) then
            if(this.position:DistanceTo(this.target_position) < 800) then
                if this.CustomValues.ChangedToStep3 == false then
                    this.CustomValues.ChangedToStep3 = true
                    this.turning_speed_pitch = 120 * math.degree
                    this.no_gravity = false
                end
                this:Track()
            elseif (this.CustomValues.ChangedToStep3 == false) then
                if (this.CustomValues.ChangedToStep2 == false) then
                    this.CustomValues.ChangedToStep2 = true
                    this.pitch = 0
                    this.yaw = math.atan(this.target_position.y - this.position.y, this.target_position.x - this.position.x)
                    this:AdjustVelocity()
                    local tail =AddSpecialEffect([[Abilities\Spells\Other\Doom\DoomDeath.mdl]],this.position.x, this.position.y)
                    BlzSetSpecialEffectZ(tail, this.position.z)
                    BlzSetSpecialEffectPitch(tail, 90 * math.degree)
                    BlzSetSpecialEffectRoll(tail, -this.yaw + math.pi)
                    BlzSetSpecialEffectTimeScale(tail, 3)
                    DestroyEffect(tail)
                    if (this.speed < 2000) then
                        this.speed = 2000
                        this:AdjustVelocity()
                    end
                end
            end
        else
            this.speed = this.speed + 600 * CoreTicker.Interval
            this:AdjustVelocity()
        end
    end,
    OnHit = function(this, victim)
    end,
    ---@param this Projectil
    ---@param terrainZ number
    OnHitTerrain = function(this, terrainZ)
        this:End()
    end
}