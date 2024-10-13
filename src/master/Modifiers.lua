require('utils')
require('master.MasterBase')
require('gameSystem.ModifierSystem')

Master.Modifier = {}

Master.Modifier.TEST = {
    id = 'TEST',
    duration = -1,
    interval = 0.1,
    Effects = {{
        model = 'Abilities\\Spells\\Human\\ManaFlare\\ManaFlareTarget.mdl',
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Update = function(this)
        this.effects_scale = this.effects_scale + 0.1
    end
}

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

Master.Modifier.AUXILIARY_MOVE = {
    id = 'AUXILIARY_MOVE',
    duration = -1,
    interval = CoreTicker.Interval,
    Effects = {{
        model = 'Abilities\\Spells\\Human\\ManaFlare\\ManaFlareTarget.mdl',
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Acquire = function(this)
        this.last_pos = Vector2:new(nil, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit))
    end,
    ---@param this Modifier
    Update = function(this)
        local x = GetUnitX(this.owner.unit)
        local y = GetUnitY(this.owner.unit)
        local id = GetUnitCurrentOrder(this.owner.unit)
        local dis = this.last_pos:Distance(x, y)
        if dis > 0 and dis < 1000 * this.interval then
                print('is moving')
                --[[
                local r = math.atan(y-this.last_pos.y, x - this.last_pos.x)
                x = x + 500 * Cos(r) * this.interval
                y = y + 500 * Sin(r) * this.interval
                SetUnitX(this.owner.unit, x)
                SetUnitY(this.owner.unit, y)
                --]]
        else
            print('not moving')
        end
        this.last_pos.x = x
        this.last_pos.y = y
    end
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
    reapply_mode = Modifier.REAPPLY_MODE.COEXIST,
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
