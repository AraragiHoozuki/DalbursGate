require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')

CoreTicker.Init()


local v = CreateUnit(Player(0), FourCC('U000'), 0, 90, 293)
local z = CreateUnit(Player(0), FourCC('Ulic'), 0, 90, 293)
local z = CreateUnit(Player(0), FourCC('ebal'), 0, 90, 293)
local z = CreateUnit(Player(0), FourCC('hdhw'), 0, 90, 293)
local z = CreateUnit(Player(0), FourCC('ufro'), 0, 90, 293)
UnitAddAbility(v, AbilityScripts.BOUNCING_INFERNAL.AbilityId)
UnitAddAbility(v, AbilityScripts.SPAWN_TEST_UNITS.AbilityId)
UnitAddAbility(v, AbilityScripts.SPACE_CUT_CIRCLE.AbilityId)

