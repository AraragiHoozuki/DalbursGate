require('utils')
require('master.MasterBase')
require('gameSystem.ProjectilSystem')
Master.Projectil = {}
Master.DefaultAttackProjectil = {}


Master.Projectil.Test = {
    model = 'Abilities\\Weapons\\LichMissile\\LichMissile.mdl', --子弹模型
    velocity = 100, --水平（XY轴）弹道速度
    velocityZ = 0, --Z轴初始速度
    velocityZMax = 9999, --最大Z轴速度绝对值
    no_gravity = true, --是否无视重力
    hit_range = 50, --命中检测范围（水平）
    hit_rangeZ = 60, --若为true,在命中判定时，会额外考虑子弹和目标的Z轴坐标
    hit_terrain = true, --是否命中地形（若是，子弹会被地面、高坡、悬崖等阻挡）
    hit_other = true, --是否能命中目标以外单位
    hit_ally = false, --是否能命中友军
    hit_piercing = false, --是否穿透（命中单位后继续飞行）
    hit_cooldown = 1, --同一单位命中间隔（仅对穿透弹道生效，防止同一个单位一直被判定命中）
    track_type = Projectil.TRACK_TYPE_POSITION, --追踪类型：无/追踪目标单位/追踪目标点
    trackZ = true, --是否Z轴追踪（根据目标高度调整子弹竖直方向速度）
    tracking_angle = 60 * math.degree, --最大追踪角度角度（水平），当目标不在子弹前方该角度的扇形区域时，丢失追踪效果
    turning_speed = 60 * math.degree, --最大转向速度（弧度/秒）
    max_flying_distance = 1500, --最大飞行距离
    offsetX = 11, --发射点偏移
    offsetY = 62,
    offsetZ = 71,
    Hit = nil --命中时额外调用函数
}
Master.Projectil.Test2 = {
    model = 'Abilities\\Weapons\\SentinelMissile\\SentinelMissile.mdl', --子弹模型
    velocity = 100, --水平（XY轴）弹道速度
    velocityZ = 0, --Z轴初始速度
    velocityZMax = 9999, --最大Z轴速度绝对值
    no_gravity = true, --是否无视重力
    hit_range = 50, --命中检测范围（水平）
    hit_rangeZ = 60, --若为true,在命中判定时，会额外考虑子弹和目标的Z轴坐标
    hit_terrain = true, --是否命中地形（若是，子弹会被地面、高坡、悬崖等阻挡）
    hit_other = true, --是否能命中目标以外单位
    hit_ally = false, --是否能命中友军
    hit_piercing = false, --是否穿透（命中单位后继续飞行）
    hit_cooldown = 1, --同一单位命中间隔（仅对穿透弹道生效，防止同一个单位一直被判定命中）
    track_type = Projectil.TRACK_TYPE_POSITION, --追踪类型：无/追踪目标单位/追踪目标点
    trackZ = true, --是否Z轴追踪（根据目标高度调整子弹竖直方向速度）
    tracking_angle = 60 * math.degree, --最大追踪角度角度（水平），当目标不在子弹前方该角度的扇形区域时，丢失追踪效果
    turning_speed = 60 * math.degree, --最大转向速度（弧度/秒）
    max_flying_distance = 1500, --最大飞行距离
    offsetX = 11, --发射点偏移
    offsetY = 62,
    offsetZ = 71,
    Hit = nil --命中时额外调用函数
}