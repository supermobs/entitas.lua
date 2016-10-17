ecs.explicit({"demo.*"})

-- 加速
ecs.system.create("demo.accelerate")
:setinitialize(function(self)
	self.group = self.pool:getgroup(ecs.matcher.acceleratable, ecs.matcher.move)
end)
:addtrigger(ecs.matcher.accelerating.addedorremoved)
:setreactiveexecute(function(self, entities, count)
	local accelerate = entities[1].isaccelerating
	for _,entity in self.group.entities:pairs() do
		local speed = accelerate and entity.move.maxspeed or 0
		entity:replacemove(speed, entity.move.maxspeed)
	end
end)

-- 移动
ecs.system.create("demo.move")
:setinitialize(function(self)
	self.group = self.pool:getgroup(ecs.matcher.move, ecs.matcher.position)
end)
:setexecute(function(self)
	for _,entity in self.group.entities:pairs() do
		local pos = entity.position
		entity:replaceposition(pos.x, pos.y + entity.move.speed, pos.z)
	end
	local entity = self.pool.roundentity
	if entity then
		entity:replaceround(entity.round.num + 1)
	end
end)

-- 抵达终点
ecs.system.create("demo.reachedfinish")
:setreactiveexecute(function(self, entities, count)
	local finishlineposy = self.pool.finishlineentity.position.y
	for i = 1,count do
		local entity = entities[i]
		if entity.position.y > finishlineposy then
			log.i(entity.view.gameobject[1] .. " win !!!")
			self.pool.isgameover = true
			entity.isdestroy = true
		end
	end
end)
:addtrigger(ecs.matcher.position.added)