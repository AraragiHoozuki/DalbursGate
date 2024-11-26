require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')
require('ui')

CoreTicker.Init()

local fogM = CreateFogModifierRect(Player(0), FOG_OF_WAR_VISIBLE, GetPlayableMapRect(), true, false)
FogModifierStart(fogM)


local v = CreateUnit(Player(0), FourCC('Hjai'), 0, 90, 293)
local w = UnitWrapper.Get(v)
BlzSetUnitMaxHP(v, 3000)
SetUnitState(v, UNIT_STATE_LIFE, 3000)

local hfoo = CreateUnit(Player(0), FourCC('hfoo'), 0, 90, 293)
UnitWrapper.Get(hfoo):AcquireModifierById('PROTECTOR_TARGET', w)

local asara = CreateUnit(Player(0), FourCC('H002'), 0, 90, 293)



UnitAddAbility(v, FourCC('A003'))
UnitAddAbility(v, AbilityScripts.ICE_KNIFE.AbilityId)
UnitAddAbility(v, AbilityScripts.ICE_WALL.AbilityId)
UnitAddAbility(v, AbilityScripts.FROZEN_MAGIC_SPHERE.AbilityId)
UnitAddAbility(v, AbilityScripts.HELICOPTER_FALL.AbilityId)
AbilityScripts.AddAbilityWithIntrinsecModifier(v, Master.Modifier.FREEZING_REALM.BindAbility)

--AbilityScripts.AddAbilityWithIntrinsecModifier(red_dragon, Master.Modifier.RED_DRAGON_ENVIRONMENT.BindAbility)
UnitAddAbility(asara, FourCC('A012'))
