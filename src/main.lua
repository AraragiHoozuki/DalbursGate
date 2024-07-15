require('utils')
require('core')
require('gameSystem')
require('master')

CoreTicker.Init()

local u = CreateUnit(Player(0), FourCC('H000'), 210, 90, 293)
local lu = LuaUnit.Get(u)

Projectil:new(nil, lu, GetUnitX(u), GetUnitY(u), 500, GetUnitFacing(u)/math.degree, Master.Projectil.Test2, nil, Vector3:new(nil,500,300,0), {})

