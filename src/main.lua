require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')

CoreTicker.Init()

--local u = CreateUnit(Player(0), FourCC('H000'), 210, 90, 293)
--local lu = LuaUnit.Get(u)
--SetHeroLevel(u, 10, true)

local v = CreateUnit(Player(0), FourCC('n000'), 210, 90, 293)

CreateUnit(Player(1), FourCC('hfoo'), 500, 90, 293)
