AbilityScripts = {}
AbilityScripts.AddAbilityWithIntrinsecModifier = function(u, abilityId)
    UnitAddAbility(u, abilityId)
    if AbilityIntrinsecModDict[abilityId] ~= nil then
        for _,mid in ipairs(AbilitySystem.IntrinsecModifiers[abilityId]) do
            UnitWrapper.Get(u):AcquireModifierById(mid, UnitWrapper.Get(u), abilityId)
        end
        
    end
end
AbilityCastDict = {
    [FourCC('A00D')] = 'BOUNCING_INFERNAL',
    [FourCC('A00I')] = 'SPAWN_TEST_UNITS',
    [FourCC('A00M')] = 'SLEEPINESS_SETS_IN',
    [FourCC('A00N')] = 'SPACE_CUT_CIRCLE',
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
    [FourCC('AUav')] = {'BLOOD_THIRST_AURA'},
}


--------------------------------------------------------------
--------------------------------------------------------------

require('scripts.Misc')

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
            local uw = UnitWrapper.Get(GetLearningUnit())
            for _,mid in ipairs(AbilityIntrinsecModDict[learnedSkillId]) do
                uw:AcquireModifierById(mid, uw, learnedSkillId)
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
                    UnitWrapper.Get(unit):AcquireModifierById(mid, UnitWrapper.Get(unit), aid)
                end
            end
        end
        return false
    end)
    TriggerRegisterEnterRectSimple(trigger2, GetPlayableMapRect())
    TriggerAddCondition(trigger2, cond2)
end

AbilityScripts.SPAWN_TEST_UNITS = {
    AbilityId = FourCC('A00I'),
    RandomUnitPool = {
        FourCC('hfoo'),FourCC('hkni'),FourCC('hmpr'),FourCC('hmtt'),FourCC('ogru'),FourCC('otau')
    },
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local angle = GetUnitFacing(caster.unit)
        local x = GetUnitX(caster.unit) + 1500*CosBJ(angle)
        local y = GetUnitY(caster.unit) + 1500*SinBJ(angle)
        for i=10,1,-1 do
            local id = AbilityScripts.SPAWN_TEST_UNITS.RandomUnitPool[math.random(1,#AbilityScripts.SPAWN_TEST_UNITS.RandomUnitPool)]
            CreateUnit(Player(1), id, x, y, 293)
        end
    end
}