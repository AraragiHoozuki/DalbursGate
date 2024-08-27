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
local v = CreateUnit(Player(0), FourCC('nwat'), 0, 90, 293)
UnitAddAbility(v, FourCC('A00E'))
UnitAddAbility(v, FourCC('A00G'))
BlzSetUnitMaxHP(v, 5000)
SetUnitState(v, UNIT_STATE_LIFE,5000)

CreateUnit(Player(0), FourCC('h000'), 210, 90, 293)
CreateUnit(Player(0), FourCC('h000'), 210, 90, 293)
CreateUnit(Player(0), FourCC('h000'), 210, 90, 293)
