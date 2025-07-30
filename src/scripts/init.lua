AbilityScripts = {}
AbilityScripts.AddAbilityWithIntrinsecModifier = function(u, abilityId)
    UnitAddAbility(u, abilityId)
    if AbilityIntrinsecModDict[abilityId] ~= nil then
        for _,mid in ipairs(AbilityIntrinsecModDict[abilityId]) do
            UnitWrapper.Get(u):AcquireModifierById(mid, UnitWrapper.Get(u), abilityId)
        end
        
    end
end
AbilityCastDict = {
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
    [FourCC('A00O')] = {'NEPHTIS_SOUL_CONVERT'},
    [FourCC('A00S')] = {'RED_DRAGON_ENVIRONMENT'},
    [FourCC('A00U')] = {'FREEZING_REALM'},
    [FourCC('A00Y')] = {'LIFE_BY_ATTACK_TIME'},
    [FourCC('A00Z')] = {'DAGONS_BLESS', 'OCEANUS_STRIKE'},
    [FourCC('AUav')] = {'BLOOD_THIRST_AURA'},
    [FourCC('A013')] = {'NO_FEAR_AURA'},
    [FourCC('A014')] = {'LEONIDAS_LEGACY'},
    [FourCC('A016')] = {'LIGHTNING_STORM'},
}


--------------------------------------------------------------
--------------------------------------------------------------

require('scripts.Misc')
require('scripts.Nephtis')
require('scripts.RedDragon')
--require('scripts.101FireWork')
require('scripts.IceMaiden')
require('scripts.NagaQueen')
require('scripts.Leonidas')

do -- Ability Cast Trigger
    local trigger = CreateTrigger()
    local cond = Condition(function()
        local code_name = GetSpellAbilityId()
        if (AbilityCastDict[code_name] ~= nil) then
            AbilityScripts[AbilityCastDict[code_name]].Cast()
        else
            for id,script in pairs(AbilityScripts) do
                if (type(script) == 'table' and script.AbilityId == code_name) then
                    AbilityCastDict[code_name] = id
                    script.Cast()
                    return false
                end
            end
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
        FourCC('hfoo'),FourCC('hkni'),FourCC('hmpr'),FourCC('hmtt'),FourCC('ogru'),FourCC('otau'),FourCC('owyv')
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