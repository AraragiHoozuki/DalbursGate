require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')

CoreTicker.Init()


local v = CreateUnit(Player(0), FourCC('U000'), 0, 90, 293)
CreateUnit(Player(0), FourCC('U000'), 0, 90, 293)

-- local z = CreateUnit(Player(1), FourCC('h000'), 0, 90, 293)

-- CreateUnit(Player(1), FourCC('h000'), -100, 0, 293)
-- CreateUnit(Player(1), FourCC('h000'), -100, 0, 293)
-- CreateUnit(Player(1), FourCC('h000'), -100, 0, 293)
-- CreateUnit(Player(1), FourCC('h000'), -100, 0, 293)
-- CreateUnit(Player(1), FourCC('h000'), -100, 0, 293)
-- CreateUnit(Player(1), FourCC('h000'), -100, 0, 293)


UnitAddAbility(v, FourCC('A003'))
UnitAddAbility(v, AbilityScripts.NATIONALDAY_FIREWORK.AbilityId)
UnitAddAbility(v, AbilityScripts.SPACE_CUT_CIRCLE.AbilityId)
UnitAddAbility(v, AbilityScripts.NEPHTIS_SOUL_LINK.AbilityId)


AbilityScripts.AddAbilityWithIntrinsecModifier(v, Master.Modifier.NEPHTIS_SOUL_CONVERT.BindAbility)
