require('utils')
require('master.MasterBase')
require('gameSystem.ModifierSystem')

Master.Modifier = {}

Master.Modifier.SHOW_ORDER_STRING = {
    id = 'SHOW_ORDER_STRING',
    duration = -1,
    interval = 0.1,
    Effects = {{
        model = 'Abilities\\Spells\\Human\\ManaFlare\\ManaFlareTarget.mdl',
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Update = function(this)
        local id = GetUnitCurrentOrder(this.owner.unit)
        local s = OrderId2String(id)
        print(GetUnitName(this.owner.unit), ' current order: ', id, ', ', s)
    end
}
Master.Modifier.LIFE_BY_ATTACK_TIME = {
    id = 'LIFE_BY_ATTACK_TIME',
    icon = [[ReplaceableTextures\CommandButtons\BTNSelectHeroOff.blp]],
    title = '计数生命',
    description = '这个单位受到的持续伤害变为0，其他伤害变为1点',
    duration = -1,
    interval = 1,
    strength = 10,
    reapply_mode = Modifier.REAPPLY_MODE.NO,
    Effects = {},
    ---@param damage Damage
    OnBeforeTakeDamage = function(this, damage)
        if (damage.dmgtype == Damage.DAMAGE_TYPE_DOT) then
            damage.control_set = 0
        else
            damage.control_set = 1
        end
    end
}
Master.Modifier.ON_SHALLOW_WATER_FAKE = {
    id = 'ON_SHALLOW_WATER_FAKE',
    hidden = true,
    duration = 0.2,
    interval = 0.1,
    strength = 10,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {},
}
Master.Modifier.ON_DEEP_WATER_FAKE = {
    id = 'ON_DEEP_WATER_FAKE',
    hidden = true,
    duration = 0.2,
    interval = 0.1,
    strength = 10,
    reapply_mode = Modifier.REAPPLY_MODE.REFRESH,
    Effects = {},
}

Master.Modifier.STUN = {
    id = 'STUN',
    icon = [[ReplaceableTextures\CommandButtons\BTNStun.blp]],
    title = '眩晕',
    description = '这个单位眩晕了，无法行动',
    duration = 3,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.COEXIST,
    Effects = {{
        model = [[Abilities\Spells\Human\Thunderclap\ThunderclapTarget.mdl]],
        attach_point = 'overhead'
    }},
    tags = {TAG.STATE.BASE_STUNED},
    ---@param this Modifier
    OnAcquired = function(this)
        BlzPauseUnitEx(this.owner.unit, true)
        IssueImmediateOrderById(this.owner.unit, 851973)
    end,
    ---@param this Modifier
    OnRemoved = function(this)
        if (not this.owner:HasTag(TAG.STATE.BASE_STUNED)) then
            IssueImmediateOrderById(this.owner.unit, 851973)
            BlzPauseUnitEx(this.owner.unit, false)
        end
    end
}

Master.Modifier.FROZEN = {
    id = 'FROZEN',
    icon = [[ReplaceableTextures\CommandButtons\BTNFrozen.dds]],
    title = '冻结',
    description = '这个单位被冻结了，无法行动',
    duration = 3,
    interval = 1,
    reapply_mode = Modifier.REAPPLY_MODE.REMOVE_OLD,
    Effects = {{
        model = [[Effects\IceCube.mdx]],
        attach_point = 'origin'
    }},
    tags = {TAG.STATE.BASE_STUNED, TAG.ETC.STOP_ANIMATION},
    ---@param this Modifier
    OnAcquired = function(this)
        BlzPauseUnitEx(this.owner.unit, true)
        IssueImmediateOrderById(this.owner.unit, 851973)
        SetUnitTimeScale(this.owner.unit, 0)
    end,
    ---@param this Modifier
    OnRemoved = function(this)
        if (not this.owner:HasTag(TAG.STATE.BASE_STUNED)) then
            IssueImmediateOrderById(this.owner.unit, 851973)
            BlzPauseUnitEx(this.owner.unit, false)
        end
        if (not this.owner:HasTag(TAG.ETC.STOP_ANIMATION)) then
            SetUnitTimeScale(this.owner.unit, 1)
        end
    end
}
