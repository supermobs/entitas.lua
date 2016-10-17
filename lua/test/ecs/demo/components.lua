-- 资源
ecs.component.regist("demo.resource", "name")
-- 显示对象
ecs.component.regist("demo.view", "gameobject")

-- 终点线标识
ecs.component.registsingle("demo.finishline")

-- 位置
ecs.component.regist("demo.position", "x", "y", "z")
-- 移动
ecs.component.regist("demo.move", "speed", "maxspeed")
-- 可执行加速
ecs.component.regist("demo.acceleratable")
-- 正在加速标识
ecs.component.registsingle("demo.accelerating")

-- 删除标识
ecs.component.regist("demo.destroy")

-- 回合计数
ecs.component.registsingle("demo.round", "num")
-- 游戏结束标志
ecs.component.registsingle("demo.gameover")