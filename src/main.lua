require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')
require('ui')

CoreTicker.Init()


local fogM = CreateFogModifierRect(Player(0), FOG_OF_WAR_VISIBLE, GetPlayableMapRect(), true, false)
FogModifierStart(fogM)




--AbilityScripts.AddAbilityWithIntrinsecModifier(red_dragon, Master.Modifier.RED_DRAGON_ENVIRONMENT.BindAbility)
local asara = CreateUnit(Player(0), FourCC('H002'), 0, 90, 293)
UnitAddAbility(asara, FourCC('A012'))
UnitAddAbility(asara, FourCC('A00P'))

local lightning_tower = CreateUnit(Player(0), FourCC('h003'), 0, 90, 293)
AbilityScripts.AddAbilityWithIntrinsecModifier(lightning_tower, FourCC('A016'))
for i = 1, 10 do
    local u = CreateUnit(Player(0), FourCC('hfoo'), 0, 90, 293)
    BlzSetUnitMaxHP(u, 10)
end

local leonidas = CreateUnit(Player(0), FourCC('O002'), 0, 90, 293)
UnitAddAbility(leonidas, AbilityScripts.SLEEPINESS_SETS_IN.AbilityId)