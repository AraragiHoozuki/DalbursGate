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
BlzSetUnitMaxHP(v, 3000)
SetUnitState(v, UNIT_STATE_LIFE, 3000)

local red_dragon = CreateUnit(Player(0), FourCC('Ewar'), 0, 90, 293)

local w = UnitWrapper.Get(v)

UnitAddAbility(v, FourCC('A003'))
UnitAddAbility(v, AbilityScripts.ICE_KNIFE.AbilityId)
UnitAddAbility(v, AbilityScripts.ICE_WALL.AbilityId)
AbilityScripts.AddAbilityWithIntrinsecModifier(v, Master.Modifier.NEPHTIS_SOUL_CONVERT.BindAbility)
AbilityScripts.AddAbilityWithIntrinsecModifier(v, Master.Modifier.FREEZING_REALM.BindAbility)

--AbilityScripts.AddAbilityWithIntrinsecModifier(red_dragon, Master.Modifier.RED_DRAGON_ENVIRONMENT.BindAbility)
UnitAddAbility(red_dragon, AbilityScripts.RED_DRAGON_BREATH.AbilityId)
