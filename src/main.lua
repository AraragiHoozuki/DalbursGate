require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')

CoreTicker.Init()

--local u = CreateUnit(Player(0), FourCC('H000'), 210, 90, 293)
--local lu = LuaUnit.Get(u)
--SetHeroLevel(u, 10, true)

--local v = CreateUnit(Player(0), FourCC('n000'), 210, 90, 293)
local v = CreateUnit(Player(0), FourCC('U000'), 0, 90, 293)
local z = CreateUnit(Player(0), FourCC('Ulic'), 0, 90, 293)
UnitAddAbility(v, AbilityScripts.BOUNCING_INFERNAL.AbilityId)
UnitAddAbility(v, AbilityScripts.SPAWN_TEST_UNITS.AbilityId)
UnitAddAbility(v, AbilityScripts.SLEEPINESS_SETS_IN.AbilityId)

UnitWrapper.Get(v):AddAttackSpeed(-0.6)
UnitWrapper.Get(v):AddAttackSpeed(0.6)
print(UnitWrapper.Get(v):GetBonusAttackSpeed())