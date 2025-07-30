Master.Modifier.RESONANCE = {
    id = 'RESONANCE',
    icon = [[ReplaceableTextures\CommandButtons\BTNDagonAdvocate_DagonsBless.dds]],
    title = '共鸣',
    description =
    '同步获得周围$Range$范围内友军的共鸣技能效果',
    duration = -1,
    interval = 0.1,
    remove_on_death = false,
    tags = {TAG.SPECIAL.RESONANCE_MODIFIER},
    Effects = {},
    LevelValues = {
        Range = { 500 }
    },
    ---@param this Modifier
    Update = function(this)
        local cond = Condition(function()
            local unit = GetFilterUnit()
            if (not IsUnitType(unit, UNIT_TYPE_DEAD))
                and IsUnitAlly(unit, GetOwningPlayer(this.owner.unit)) then
                local uw = UnitWrapper.Get(unit)
                for i = #(uw.modifiers),1,-1 do
                    local mod = uw.modifiers[i]
                    if (mod.id == this.id) then
                        if (mod.owner.unit ~= this.owner.unit) then
                            for k, v in pairs(mod.effects) do
                                this:AddEffect(k, v)
                            end
                            this:Reapply()
                        end
                        return true
                    end
                end
            end
            return false
        end)
        GroupEnumUnitsInRange(Entity.tempGroup, GetUnitX(this.owner.unit), GetUnitY(this.owner.unit), this:LV('Range'),
            cond)
        DestroyBoolExpr(cond)
    end
}