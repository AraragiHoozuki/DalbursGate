AbilityScripts = {}
AbilityScripts.AddAbilityWithIntrinsecModifier = function(u, abilityId)
    UnitAddAbility(u, abilityId)
    if AbilityIntrinsecModDict[abilityId] ~= nil then
        for _,mid in ipairs(AbilitySystem.IntrinsecModifiers[abilityId]) do
            LuaUnit.Get(u):AcquireModifierById(mid, LuaUnit.Get(u), abilityId)
        end
        
    end
end
AbilityCastDict = {
    [FourCC('A005')] = 'SHADOW_DRAIN',
    [FourCC('A008')] = 'SHADOW_CONVERT',
    [FourCC('A007')] = 'SHADOW_COMMAND',
    [FourCC('A00D')] = 'INFERNAL_METEOR',
    [FourCC('A00E')] = 'ASTER_CAPT',
    [FourCC('A00F')] = 'ASTER_CAPT_RECAST',
    [FourCC('A00G')] = 'CHARGE_ELECTRON',
}
AbilityIntrinsecModDict = {
    -- 至暗无光
    [FourCC('A000')] = {'DEEP_SHADOW_CURSE_PROVIDER','DEEP_SHADOW_CREATURE', 'DEEP_SHADOW_CURSE_GRAND_PROVIDER'},
    -- 发光 500
    [FourCC('A002')] = {'ENLIGHTENED_PROVIDER'},
    -- 幽影生物
    [FourCC('A006')] = {'DEEP_SHADOW_CREATURE'},

    [FourCC('A00A')] = {'PUSH_FIST'},
    [FourCC('A00B')] = {'STORM_FORCE_FIELD'},
    [FourCC('A00C')] = {'INFERNAL_FLAME'},
}


--------------------------------------------------------------
--------------------------------------------------------------

require('scripts.Misc')
require('scripts.DeepShadow')
require('scripts.ElectronLord')

do -- Ability Cast Trigger
    local trigger = CreateTrigger()
    local cond = Condition(function()
        local code_name = GetSpellAbilityId()
        if (AbilityCastDict[code_name] ~= nil) then
            AbilityScripts[AbilityCastDict[code_name]].Cast()
        end
        return false
    end)
    TriggerRegisterAnyUnitEventBJ(trigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    TriggerAddCondition(trigger, cond)
end

do -- Intrinsec Modifier Trigger
    local trigger = CreateTrigger()
    local cond = Condition(function()
        local learnedSkillId = GetLearnedSkill()
        if (AbilityIntrinsecModDict[learnedSkillId] ~= nil and GetLearnedSkillLevel() == 1) then
            local lu = LuaUnit.Get(GetLearningUnit())
            for _,mid in ipairs(AbilityIntrinsecModDict[learnedSkillId]) do
                lu:AcquireModifierById(mid, lu, learnedSkillId)
            end
        end
        return false
    end)
    TriggerRegisterAnyUnitEventBJ(trigger, EVENT_PLAYER_HERO_SKILL)
    TriggerAddCondition(trigger, cond)

    local trigger2 = CreateTrigger()
    local cond2 = Condition(function()
        local unit = GetEnteringUnit()
        for aid,mids in pairs(AbilityIntrinsecModDict) do
            if (GetUnitAbilityLevel(unit, aid) > 0) then
                for _,mid in ipairs(mids) do
                    LuaUnit.Get(unit):AcquireModifierById(mid, LuaUnit.Get(unit), aid)
                end
            end
        end
        return false
    end)
    TriggerRegisterEnterRectSimple(trigger2, GetPlayableMapRect())
    TriggerAddCondition(trigger2, cond2)
end