require('gameSystem')
require('master')

-- 带电
Master.Modifier.ELECTRON_CHARGED = {
    id = 'ELECTRON_CHARGED',
    duration = 30,
    interval = 0.1,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    stack = 1,
    remove_on_death = true,
    tags = {},
    Effects = {{
        model = [[Abilities\Weapons\FarseerMissile\FarseerMissile.mdl]],
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Acquire = function(this)
        this.is_positive_charge = true
        this.lightnings = {}
        this.max_distance = 600
        this.apply_checker_group = CreateGroup()
    end,
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function() 
            local lu = LuaUnit.Get(GetFilterUnit())
            if (lu.unit == this.owner.unit) then return false end
            if (lu:IsModifierTypeAffected('ELECTRON_CHARGED')) then
                if (this.lightnings[lu.uuid] == nil) then
                    this.lightnings[lu.uuid] = {
                        rival = lu
                    }
                    if (lu:GetAffectedModifier('ELECTRON_CHARGED').is_positive_charge == this.is_positive_charge) then
                        this.lightnings[lu.uuid].lightning = AddLightningEx('CLPB', false, 
                            GetUnitX(this.owner.unit), 
                            GetUnitY(this.owner.unit), 
                            0,
                            GetUnitX(lu.unit), 
                            GetUnitY(lu.unit),
                            0
                        )
                    else
                        this.lightnings[lu.uuid].lightning = AddLightningEx('AFOD', false, 
                            GetUnitX(this.owner.unit), 
                            GetUnitY(this.owner.unit), 
                            0,
                            GetUnitX(lu.unit), 
                            GetUnitY(lu.unit),
                            0
                        )
                    end
                    
                end
            end
            return false
        end)
        GroupEnumUnitsInRange(this.apply_checker_group, 
            GetUnitX(this.owner.unit), 
            GetUnitY(this.owner.unit), 
            this.max_distance, cond
        )
        DestroyBoolExpr(cond)
        for uuid,l in pairs(this.lightnings) do
            local x = GetUnitX(this.owner.unit)
            local y = GetUnitY(this.owner.unit)
            local rx = GetUnitX(l.rival.unit)
            local ry = GetUnitY(l.rival.unit)
            local r = math.atan(ry-y, rx-x)
            local d = math.sqrt((rx-x)*(rx-x) + (ry-y)*(ry-y))
            local v = 30000 / d
            local modi = l.rival:GetAffectedModifier('ELECTRON_CHARGED')
            if (d > this.max_distance or modi == nil) then
                DestroyLightning(l.lightning)
                this.lightnings[uuid] = nil
            else
                if (modi.is_positive_charge ~= this.is_positive_charge) then
                    v = -v
                    if ( d < 100) then
                        DestroyEffect(AddSpecialEffect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]], rx, ry))
                        modi:Remove()
                        this:Remove()
                    end
                end
                --DestroyLightning(l.lightning)
                --l.lightning = AddLightningEx('FORK', false, x, y, 50, rx, ry, 50)
                MoveLightningEx(l.lightning, false, x, y, GetUnitFlyHeight(this.owner.unit) + 100, 
                    rx, ry, GetUnitFlyHeight(l.rival.unit) + 100)
                l.rival:AddDisplace(Displace:new{
                    velocity = Vector3:new(nil, v * Cos(r), v * Sin(r), 0),
                    accelerate = Vector3:new(nil, 0, 0, 0),
                    max_distance = 30,
                    max_duration = 0.1,
                    interruptible = true,
                    interrupt_action = false,
                    efx = [[Abilities\Weapons\FarseerMissile\FarseerMissile.mdl]],
                    efx_interval = 0.1,
                })
            end
        end
    end,
    --@param this Modifier
    Remove = function(this)
        DestroyGroup(this.apply_checker_group)
        for uuid,l in pairs(this.lightnings) do
            DestroyLightning(l.lightning)
            this.lightnings[uuid] = nil
        end
    end
}

-- 充电
--[[充电：使一个单位随机带上正电或者负电，
带电的单位距离在600以内时，
若带电不同，会有红色闪电连接并互相吸引，
带电相同，则有蓝色闪电连接并互相排斥，
距离越近吸引or排斥效果越强，
带电不同的单位距离小于100时会放电并清除带电效果]]
AbilityScripts.CHARGE_ELECTRON = {
    AbilityId = FourCC('A00G'),
    Cast = function()
        local caster = LuaUnit.Get(GetTriggerUnit())
        local target = LuaUnit.Get(GetSpellTargetUnit())
        local modi = caster:ApplyModifierById('ELECTRON_CHARGED', target, AbilityScripts.CHARGE_ELECTRON.AbilityId)
        if math.random(1,100) > 50 and modi ~= nil then
            modi.is_positive_charge = false
            DestroyEffect(modi.effects[1])
            modi.effects[1] = AddSpecialEffectTarget([[Abilities\Weapons\VengeanceMissile\VengeanceMissile.mdl]], 
            target.unit, 'overhead')
        end
    end
}