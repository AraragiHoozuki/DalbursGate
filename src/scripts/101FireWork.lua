
AbilityScripts.NATIONALDAY_FIREWORK = {
    AbilityId = FourCC('A00P'),
    Cast = function()
        local caster = UnitWrapper.Get(GetTriggerUnit())
        local tloc = Vector3:ctor {
            x = GetSpellTargetX(),
            y = GetSpellTargetY(),
        }
        tloc.z = Projectil.GetLocationZ(tloc.x, tloc.y) + 900
        Projectil:ctor {
            emitter = caster,
            target_position = tloc,
            settings = Master.Projectil.FIREWORK_TARGET
        }
    end
}

NATIONALDAY_FIREWORKS = {
    ---@param this Projectil
    Flower = function(this, settings)
        local d = 10
        for xyi = 0,360,30 do
            for zi = -90,90,15 do
                local tloc = Vector3:ctor {
                    x = this.position.x + d*Cos(zi*math.degree)*Cos(xyi*math.degree),
                    y = this.position.y + d*Cos(zi*math.degree)*Sin(xyi*math.degree),
                    z = this.position.z + d*Sin(zi*math.degree)
                }
                Projectil:ctor {
                    emitter = this.emitter,
                    x = this.position.x,
                    y = this.position.y,
                    z = this.position.z,
                    target_position = tloc,
                    settings = settings
                }
            end
        end 
    end,
    Spin = function(this, spinAngle, settings)
        local d = 10
        local tloc = Vector3:ctor {
            x = this.position.x + d*Cos(spinAngle),
            y = this.position.y + d*Sin(spinAngle),
            z = this.position.z
        }
        Projectil:ctor {
            emitter = this.emitter,
            x = this.position.x,
            y = this.position.y,
            z = this.position.z,
            target_position = tloc,
            settings = settings
        }
        local tloc2 = Vector3:ctor {
            x = this.position.x + d*Cos(spinAngle + math.pi),
            y = this.position.y + d*Sin(spinAngle + math.pi),
            z = this.position.z
        }
        Projectil:ctor {
            emitter = this.emitter,
            x = this.position.x,
            y = this.position.y,
            z = this.position.z,
            target_position = tloc2,
            settings = settings
        }
    end,
    Tree = function(this, settings)
        local d = 10
        for angle = 0,2*math.pi,2*math.pi/36 do
            local tloc = Vector3:ctor {
                x = this.position.x + d*Cos(angle),
                y = this.position.y + d*Sin(angle),
                z = this.position.z
            }
            Projectil:ctor {
                emitter = this.emitter,
                x = this.position.x,
                y = this.position.y,
                z = this.position.z,
                target_position = tloc,
                settings = settings
            }
        end
    end,
    Tail = function(this, model)
        local p = Projectil:ctor {
            emitter = this.emitter,
            x = this.position.x,
            y = this.position.y,
            z = this.position.z,
            settings = Master.Projectil.FIREWORK_TAIL
        }
        if (model ~= nil) then p:ChangeModel(model) end
    end
}

Master.Projectil.FIREWORK_TARGET = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]], -- 模型
    model_scale = 1, --模型缩放
    speed = 1600,  --初始速率
    no_gravity = false, --是否无视重力
    hit_range = 25, --命中监测方位
    hit_terrain = true, --是否会被地形阻挡
    hit_other = false, --是否会命中目标以外单位
    hit_ally = false, --是否会命中队友
    hit_piercing = false, --是否穿透（命中单位后是否会消失）
    hit_cooldown = 1, --同一单位命中时间间隔（对于穿透弹道，防止命中同一单位N次）
    track_type = Projectil.TRACK_TYPE_POSITION, --追踪类型（追踪点/追踪单位/无追踪）
    tracking_angle = 360 * math.degree, --追踪角度，目标不在角度范围内时，丢失追踪效果
    turning_speed = 360 * math.degree, -- 水平转向速度
    turning_speed_pitch = 360 * math.degree, -- 垂直转向速度
    max_flying_distance = 15000, --最大飞行距离
    offsetX = 0,
    offsetY = 0,
    offsetZ = 50,
    ---@param this Projectil
    OnHit = function(this) -- 命中时调用的函数
        NATIONALDAY_FIREWORKS.Flower(this,Master.Projectil.FIREWORK_SECONDARY)
    end
}

Master.Projectil.FIREWORK_SECONDARY = {
    -- 红龙 [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    -- 丛林守护者 [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    -- 绿龙 [[Abilities\Weapons\GreenDragonMissile\GreenDragonMissile.mdl]]
    -- 石像鬼 [[Abilities\Weapons\GargoyleMissile\GargoyleMissile.mdl]]
    -- 水元素 [[Abilities\Weapons\WaterElementalMissile\WaterElementalMissile.mdl]]
    model = [[Abilities\Weapons\GreenDragonMissile\GreenDragonMissile.mdl]],
    model_scale = 0.5,
    speed = 900, 
    no_gravity = false,
    hit_range = 25,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 60 * math.degree,
    max_flying_distance = 15000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    OnHit = nil,
}

Master.Projectil.FIREWORK_NO_TARGET = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    model_scale = 1,
    speed = 1200, 
    no_gravity = false,
    hit_range = 25,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 60 * math.degree,
    max_flying_distance = 3600,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 50,
    ---@param this Projectil
    OnCreate = function(this)
        this.CustomValues.SpinAngle = 0
    end,
    ---@param this Projectil
    Update = function(this, delta)
        NATIONALDAY_FIREWORKS.Spin(this, this.CustomValues.SpinAngle, Master.Projectil.FIREWORK_SECONDARY)
        --NATIONALDAY_FIREWORKS.Tree(this, Master.Projectil.FIREWORK_SECONDARY)
        this.CustomValues.SpinAngle = this.CustomValues.SpinAngle + 12*math.degree
    end
}

Master.Projectil.FIREWORK_TAIL = {
    model = [[Abilities\Weapons\RedDragonBreath\RedDragonMissile.mdl]],
    model_scale = 0.5,
    speed = 0, 
    no_gravity = false,
    hit_range = 25,
    hit_terrain = true,
    hit_other = false,
    hit_ally = false,
    hit_piercing = false,
    hit_cooldown = 1,
    track_type = Projectil.TRACK_TYPE_NONE,
    tracking_angle = 60 * math.degree,
    turning_speed = 60 * math.degree,
    turning_speed_pitch = 60 * math.degree,
    max_flying_distance = 15000,
    offsetX = 0,
    offsetY = 0,
    offsetZ = 0,
    OnHit = nil,
}