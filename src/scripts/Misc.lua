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

Master.Modifier.PUSH_FIST = {
    id = 'PUSH_FIST',
    duration = -1,
    interval = 65535,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    remove_on_death = false,
    Effects = {},
    BindAbility = FourCC('A00A'),
    LevelValues = {
        PushVelocity = {1000},
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
                efx = [[Abilities\Spells\Other\Volcano\VolcanoMissile.mdl]],
                efx_interval = 1,
            })
        end
    end,
}