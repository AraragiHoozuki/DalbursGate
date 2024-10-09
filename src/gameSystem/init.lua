require('gameSystem.Settings')
require('gameSystem.DamageSystem')
require('gameSystem.UnitDisplaceSystem')
require('gameSystem.UnitWrapperSystem')
require('gameSystem.ModifierSystem')
require('gameSystem.ProjectilSystem')
require('gameSystem.MapObjectSystem')


--远程角色普攻弹道模拟、普攻伤害模拟
do
    local RangedAttackTrigger = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(RangedAttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
    local cond = Condition(function()
        return IsUnitType(GetAttacker(),UNIT_TYPE_RANGED_ATTACKER) == true
    end)
    TriggerAddCondition(RangedAttackTrigger, cond)
    TriggerAddAction(RangedAttackTrigger, function()
        local u = GetAttacker()
        if (Master.DefaultAttackProjectil[GetUnitTypeId(u)]==nil) then
            local settings = {
                model = BlzGetUnitWeaponStringField(u, UNIT_WEAPON_SF_ATTACK_PROJECTILE_ART, 0),
                speed = BlzGetUnitWeaponRealField(u, UNIT_WEAPON_RF_ATTACK_PROJECTILE_SPEED, 0),
                no_gravity = false,
                hit_range = 25,
                hit_terrain = true,
                hit_other = false,
                hit_ally = true,
                hit_piercing = false,
                hit_cooldown = 1,
                track_type = Projectil.TRACK_TYPE_UNIT,
                tracking_angle = 60 * math.degree,
                turning_speed = 60 * math.degree,
                turning_speed_pitch = 3 * math.degree,
                max_flying_distance = 3000,
                offsetX = 0,
                offsetY = 60,
                offsetZ = 60,
                Hit = nil
            }
            Master.DefaultAttackProjectil[GetUnitTypeId(u)] = settings
            print('弹道初始化')
        end
        BlzSetUnitWeaponStringField(u, UNIT_WEAPON_SF_ATTACK_PROJECTILE_ART, 0,'')
        BlzSetUnitWeaponRealField(u, UNIT_WEAPON_RF_ATTACK_PROJECTILE_SPEED, 0,99999)
    end)

    
    local RangeAttackDamageTrigger = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(RangeAttackDamageTrigger, EVENT_PLAYER_UNIT_DAMAGED)
    local cond2 = Condition(function() 
        if BlzGetEventIsAttack() == true then
            local uw = UnitWrapper.Get(GetEventDamageSource())
            local target = GetTriggerUnit()
            if (Master.DefaultAttackProjectil[GetUnitTypeId(uw.unit)]~=nil) then 
                ProjectilMgr.CreateAttackProjectil(uw,target,GetEventDamage())
                BlzSetEventDamage(0)
            else
                local dmg = Damage:new(nil, uw, UnitWrapper.Get(target), GetEventDamage(), Damage.ATTACK_TYPE_MELEE)
                BlzSetEventDamage(0)
                dmg:Resolve()
            end
        end
        return false
    end)
    TriggerAddCondition(RangeAttackDamageTrigger, cond2)
end