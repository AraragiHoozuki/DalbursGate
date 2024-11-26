Master.Modifier.DAGONS_BLESS = {
    id = 'DAGONS_BLESS',
    icon = [[ReplaceableTextures\CommandButtons\BTNDagonAdvocate_DagonsBless.dds]],
    title = '达贡的加护',
    description =
    '在浅水中移动速度上升50，每秒回复$HPRegenPercentPerSecondLow$%的生命|n在深水中移动速度上升150，每秒回复$HPRegenPercentPerSecondHigh$%的生命',
    duration = -1,
    interval = 0.1,
    remove_on_death = false,
    Effects = {},
    LevelValues = {
        HPRegenPercentPerSecondLow = { 0.25 },
        HPRegenPercentPerSecondHigh = { 1 }

    },
    ---@param this Modifier
    Update = function(this)
        this.CommonStatsBonus.movespeed = 0
        if this.owner:OnShallowWaterQ() then
            this.CommonStatsBonus.movespeed = 50
            this.owner:AddHPRate(this:LV('HPRegenPercentPerSecondLow') * this.interval)
        elseif this.owner:OnDeepWaterQ() then
            this.CommonStatsBonus.movespeed = 150
            this.owner:AddHPRate(this:LV('HPRegenPercentPerSecondHigh') * this.interval)
        else
            if this.CustomValues.OnWaterEffect ~= nil then
                DestroyEffect(this.CustomValues.OnWaterEffect)
                this.CustomValues.OnWaterEffect = nil
            end
        end
    end
}

Master.Modifier.OCEANUS_STRIKE = {
    id = 'OCEANUS_STRIKE',
    icon = [[ReplaceableTextures\CommandButtons\BTNScepterOfMastery.blp]],
    title = '海皇杖',
    description = '当前充能@Charge@点（最多500点，在深水时每秒获得50点充能，浅水时25点，其他情况下15点）|n造成近战攻击伤害时，若充能在100点以上，则消耗100点充能，额外造成100点寒冷伤害和1秒眩晕，同时对周围敌人造成50点伤害',
    duration = -1,
    interval = 1,
    remove_on_death = false,
    Effects = {},
    OnAcquired = function(this)
        this.CustomValues.Charge = 0
        this.CustomValues.WeaponEffect = nil
    end,
    ---@param this Modifier
    Update = function(this)
        if this.owner:OnShallowWaterQ() then
            this.CustomValues.Charge = this.CustomValues.Charge + 25
        elseif this.owner:OnDeepWaterQ() then
            this.CustomValues.Charge = this.CustomValues.Charge + 50
        else
            this.CustomValues.Charge = this.CustomValues.Charge + 15
        end
        if this.CustomValues.Charge > 500 then
            this.CustomValues.Charge = 500
        end
        if this.CustomValues.Charge >= 100 and this.CustomValues.WeaponEffect == nil then
            this.CustomValues.WeaponEffect = AddSpecialEffectTarget([[Effects\FrostBoltV1.mdx]], this.owner.unit,
                'weapon')
        end
    end,
    ---@param this Modifier
    OnDealDamage = function(this, damage)
        if this.CustomValues.Charge >= 100 and damage.atktype == Damage.ATTACK_TYPE_MELEE then
            DestroyEffect(AddSpecialEffect([[Effects/IceWarStomp.mdx]], damage.target:GetX(), damage.target:GetY()))
            this.CustomValues.Charge = this.CustomValues.Charge - 100
            local mdf = this.owner:ApplyModifierById('STUN', damage.target, this.ability)
            mdf:ReinitDuration(1)
            Damage:ctor {
                amount = 100,
                source = this.owner,
                target = damage.target,
                atktype = Damage.ATTACK_TYPE_SPELL,
                dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                eletype = Damage.ELEMENT_TYPE_KRYO
            }:Resolve()
            local cond = Condition(function()
                local u = GetFilterUnit()
                if not IsUnitType(u, UNIT_TYPE_DEAD)
                    and u ~= damage.target.unit
                    and IsUnitEnemy(u, GetOwningPlayer(this.owner.unit)) then
                    Damage:ctor {
                        amount = 50,
                        source = this.owner,
                        target = UnitWrapper.Get(u),
                        atktype = Damage.ATTACK_TYPE_SPELL,
                        dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                        eletype = Damage.ELEMENT_TYPE_KRYO
                    }:Resolve()
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, damage.target:GetX(), damage.target:GetY(), 250, cond)
            DestroyBoolExpr(cond)
            if this.CustomValues.Charge < 100 then
                DestroyEffect(this.CustomValues.WeaponEffect)
                this.CustomValues.WeaponEffect = nil
            end
        end
    end
}

AbilityScripts.TIDAL_BURST = {
    RANGE = 300,
    RANGE_BOOSTED = 500,
    DAMAGE = 100,
    DAMAGE_BOOSTED = 200,
    BOOST_COST = 250,
    AbilityId = FourCC('A010'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tx = GetSpellTargetX()
        local ty = GetSpellTargetY()
        local efx = AddSpecialEffect([[Effects\TidalBurst.mdx]], tx, ty)
        DestroyEffect(efx)
        local cond = Condition(function()
            local u = GetFilterUnit()
            if not IsUnitType(u, UNIT_TYPE_DEAD)
                and IsUnitEnemy(u, GetOwningPlayer(caster.unit)) then
                local uw = UnitWrapper.Get(u)
                local on_water = uw:OnWaterQ()
                local v = 3000
                if on_water then v = 4000 end
                uw:AddDisplace(Displace:ctor {
                    velocity = Vector3:new(nil, 0, 0, v),
                    accelerate = Vector3:new(nil, 0, 0, -3900),
                    max_distance = 0,
                    max_duration = 0,
                    interruptible = true,
                    interrupt_action = true,
                    finish_when_landed = true
                })
                local d_amt = 100
                if on_water then d_amt = d_amt * 1.5 end
                Damage:ctor {
                    amount = d_amt,
                    source = caster,
                    target = uw,
                    atktype = Damage.ATTACK_TYPE_SPELL,
                    dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                    eletype = Damage.ELEMENT_TYPE_SMASH
                }:Resolve()
            end

            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, tx, ty, 300, cond)
        DestroyBoolExpr(cond)
    end
}

AbilityScripts.SUMMON_VORTEX = {
    AbilityId = FourCC('A011'),
    DURATION = 30,
    DURATION_BOOSTED = 60,
    ATTRACT_SPEED = 150,
    ATTRACT_SPEED_BOOSTED = 250,
    RANGE = 600,
    RANGE_BOOSTED = 900,
    BOOST_COST = 500,
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tx = GetSpellTargetX()
        local ty = GetSpellTargetY()
        AbilityScripts.SUMMON_VORTEX.Effect(caster, tx, ty)
    end,
    ---@param caster UnitWrapper
    Effect = function(caster, x, y)
        local duration, speed, range, mdfid
        local mdf = caster:GetAffectedModifier('OCEANUS_STRIKE')
        local boosted = false
        if (mdf and mdf.CustomValues.Charge >= AbilityScripts.SUMMON_VORTEX.BOOST_COST) then
            mdf.CustomValues.Charge = mdf.CustomValues.Charge - AbilityScripts.SUMMON_VORTEX.BOOST_COST
            DestroyEffect(mdf.CustomValues.WeaponEffect)
            mdf.CustomValues.WeaponEffect = nil
            duration = AbilityScripts.SUMMON_VORTEX.DURATION_BOOSTED
            speed = AbilityScripts.SUMMON_VORTEX.ATTRACT_SPEED_BOOSTED
            range = AbilityScripts.SUMMON_VORTEX.RANGE_BOOSTED
            mdfid = 'ON_DEEP_WATER_FAKE'
            boosted = true
        else
            duration = AbilityScripts.SUMMON_VORTEX.DURATION
            speed = AbilityScripts.SUMMON_VORTEX.ATTRACT_SPEED
            range = AbilityScripts.SUMMON_VORTEX.RANGE
            mdfid = 'ON_SHALLOW_WATER_FAKE'
        end
        local mo = MapObject:ctor {
            x = x, y = y, z = 0,
            duration = duration,
            model_path = [[Effects\Whirlpool.mdx]],
            creator = caster,
        }
        if boosted then
            BlzSetSpecialEffectTimeScale(mo.model, 3)
            BlzSetSpecialEffectScale(mo.model, 1.5)
        end
        local update_handler = function(this, interval)
            local cond = Condition(function()
                local u = GetFilterUnit()
                if not IsUnitType(u, UNIT_TYPE_DEAD) then
                    local uw = UnitWrapper.Get(u)
                    uw:AcquireModifierById(mdfid, this.creator.unit,
                        AbilityScripts.SUMMON_VORTEX.AbilityId)
                    if IsUnitEnemy(u, GetOwningPlayer(this.creator.unit)) then
                        local ux = uw:GetX()
                        local uy = uw:GetY()
                        local a = math.atan(this.position.y - uy, this.position.x - ux)
                        SetUnitX(u, ux + speed * Cos(a) * interval)
                        SetUnitY(u, uy + speed * Sin(a) * interval)
                    end
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, this.x, this.y, range, cond)
            DestroyBoolExpr(cond)
        end
        mo:AddUpdateHandler(update_handler)
    end
}

AbilityScripts.OCEANUS_RAGE = {
    AbilityId = FourCC('A012'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        AbilityScripts.OCEANUS_RAGE.Effect(caster)
    end,
    ---@param caster UnitWrapper
    Effect = function(caster)
        local mdf = caster:GetAffectedModifier('OCEANUS_STRIKE')
        --calc prjt start position
        local angle = (GetUnitFacing(caster.unit) + 20) * math.degree
        local dis = 120
        local start_pos = Vector3:ctor {
            x = caster:GetX() + dis * Cos(angle),
            y = caster:GetY() + dis * Sin(angle),
            z = Entity.GetUnitZ(caster.unit) + 300
        }
        local start_crystal = AddSpecialEffect([[Effects\FrostcraftCrystalSD.mdx]], start_pos.x, start_pos.y)
        BlzSetSpecialEffectZ(start_crystal, start_pos.z)

        local id = GUID.generate()
        local facing = GetUnitFacing(caster.unit)
        CoreTicker.AttachAction(function()
            for i = 1, 3, 1 do
                local t_a = (math.random(-30,30) + facing) * math.degree
                local t_d = 10
                local t_pos = Vector3:ctor {
                    x = start_pos.x + t_d * Cos(t_a),
                    y = start_pos.y + t_d * Sin(t_a),
                    z = start_pos.z + 60,
                }
                Projectil:ctor {
                    emitter = caster,
                    x = start_pos.x,
                    y = start_pos.y,
                    z = start_pos.z + 60,
                    target_position = t_pos,
                    settings = Master.Projectil.OCEANUS_RAGE_PRJT,
                    hit_damage = Damage:ctor {
                        amount = 50,
                        source = caster,
                        atktype = Damage.ATTACK_TYPE_SPELL,
                        dmgtype = Damage.DAMAGE_TYPE_NORMAL,
                        eletype = Damage.ELEMENT_TYPE_PIERCE
                    }
                }
            end
            if mdf and mdf.CustomValues.Charge > 10 then
                mdf.CustomValues.Charge = mdf.CustomValues.Charge - 10
                DestroyEffect(mdf.CustomValues.WeaponEffect)
                mdf.CustomValues.WeaponEffect = nil
            else
                IssueImmediateOrder(caster.unit, 'stop')
            end
        end, 0.1, id)
        local trig = CreateTrigger()
        TriggerRegisterUnitEvent(trig, caster.unit, EVENT_UNIT_SPELL_ENDCAST)
        local tcond
        tcond = Condition(function()
            CoreTicker.DetachAction(id)
            DestroyEffect(start_crystal)
            DestroyTrigger(trig)
            DestroyBoolExpr(tcond)
            return false
        end)
        TriggerAddCondition(trig, tcond)
    end
}

Master.Projectil.OCEANUS_RAGE_PRJT = {
    model = [[Effects\FrostBoltV1.mdx]],
    model_scale = 1,
    speed = 500,
    no_gravity = true,
    hit_range = 50,
    hit_terrain = true,
    hit_other = true,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 120 * math.degree,
    turning_speed = 160 * math.degree,
    turning_speed_pitch = 15 * math.degree,
    max_flying_distance = 3000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    ---@param this Projectil
    OnCreated = function(this) 
        this.CustomValues.TargetFound = false
    end,
    ---@param this Projectil
    Update = function(this)
        if (this.CustomValues.TargetFound == false and this.flying_time >= 1) then
            
            local cond = Condition(function()
                local u = GetFilterUnit()
                if not IsUnitType(u, UNIT_TYPE_DEAD)
                and IsUnitEnemy(u, GetOwningPlayer(this.emitter.unit)) then
                    local uw = UnitWrapper.Get(u)
                    local ta = math.atan(uw:GetY()-this.position.y, uw:GetX()-this.position.x)
                    local delta = math.angleDiff(this.yaw, ta)
                    if (delta < 120*math.degree and delta > -120*math.degree) then
                        this.target_unit = u
                        this.track_type = Projectil.TRACK_TYPE_UNIT
                        this.speed = 2000
                        this.CustomValues.TargetFound = true
                    end
                end
                return false
            end)
            GroupEnumUnitsInRange(Entity.tempGroup, this.position.x, this.position.y, 700, cond)
            DestroyBoolExpr(cond)
        end
    end,
}