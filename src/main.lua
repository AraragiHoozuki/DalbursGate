require('utils')
require('core')
require('gameSystem')
require('master')
require('scripts')

CoreTicker.Init()

local u = CreateUnit(Player(0), FourCC('H000'), 210, 90, 293)
local lu = LuaUnit.Get(u)
SetHeroLevel(u, 10, true)

local v = CreateUnit(Player(0), FourCC('hfoo'), 210, 90, 293)
BlzSetUnitMaxHP(v, 3000)
SetUnitState(v, UNIT_STATE_LIFE, 3000)

CreateUnit(Player(1), FourCC('hfoo'), 210, 90, 293)

Projectil:new(nil, lu, GetUnitX(u), GetUnitY(u), 500, GetUnitFacing(u)/math.degree, Master.Projectil.Test2, nil, Vector3:new(nil,500,300,0), {})

