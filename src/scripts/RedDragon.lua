Master.Modifier.RED_DRAGON_ENVIRONMENT = {
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
}
