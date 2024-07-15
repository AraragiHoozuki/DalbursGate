require('gameSystem.DamageSystem')
require('gameSystem.LuaUnitSystem')
require('gameSystem.ModifierSystem')
require('gameSystem.ProjectilSystem')

--远程角色普攻弹道模拟
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
                velocity = BlzGetUnitWeaponRealField(u, UNIT_WEAPON_RF_ATTACK_PROJECTILE_SPEED, 0),
                velocityZ = 0,
                velocityZMax = 99999,
                no_gravity = false,
                hit_range = 50,
                hit_rangeZ = 60,
                hit_terrain = true,
                hit_other = true,
                hit_ally = false,
                hit_piercing = false,
                hit_cooldown = 1,
                track_type = Projectil.TRACK_TYPE_UNIT,
                trackZ = false,
                tracking_angle = 60 * math.degree,
                turning_speed = 60 * math.degree,
                max_flying_distance = 3000,
                offsetX = 0,
                offsetY = 60,
                offsetZ = 60,
                Hit = nil
            }
            Master.DefaultAttackProjectil[GetUnitTypeId(u)] = settings
            BlzSetUnitWeaponStringField(u, UNIT_WEAPON_SF_ATTACK_PROJECTILE_ART, 0,'')
            BlzSetUnitWeaponRealField(u, UNIT_WEAPON_RF_ATTACK_PROJECTILE_SPEED, 0,99999)
            print('弹道初始化')
        end
    end)

    local RangeAttackDamageTrigger = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(RangeAttackDamageTrigger, EVENT_PLAYER_UNIT_DAMAGED)
    local cond2 = Condition(function() 
        return BlzGetEventIsAttack() == true
    end)
    TriggerAddCondition(RangeAttackDamageTrigger, cond2)
    TriggerAddAction(RangeAttackDamageTrigger, function()
        local lu1 = LuaUnit.Get(GetEventDamageSource())
        local target = GetTriggerUnit()
        if (Master.DefaultAttackProjectil[GetUnitTypeId(lu1.unit)]~=nil) then 
            ProjectilMgr.CreateAttackProjectil(lu1,target,GetEventDamage()) 
            BlzSetEventDamage(0)
            
        else
            local dmg = Damage:new(nil, lu1, LuaUnit.Get(target), GetEventDamage(), Damage.ATTACK_TYPE_MELEE)
            BlzSetEventDamage(0)
            dmg:Resolve()
        end
    end)
end