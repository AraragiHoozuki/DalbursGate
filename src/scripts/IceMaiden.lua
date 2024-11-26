Master.Modifier.FREEZING_REALM = {
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
}
