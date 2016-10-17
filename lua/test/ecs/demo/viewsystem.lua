ecs.explicit({"demo.*"})

-- 删除显示
ecs.system.create("demo.removeview")
:setinitialize(function(self)
	local group = self.pool:getgroup(ecs.matcher.view)
	group:listen(ecs.group.eventtype.removed, function(group, entity, componenttypeid, component)
		log.d(component.gameobject[1] .. " view destroyed")
	end)
end)
:setreactiveexecute(function(self, entities, count)
	for i = 1,count do
		entities[i]:removeview()
	end
end)
:addtrigger(ecs.matcher.resource.removed)
:addtrigger(ecs.matcher.resource, ecs.matcher.destroy, ecs.observer.eventtype.added)
:setensurematcher(ecs.matcher.view)

-- 添加显示
ecs.system.create("demo.addview")
:setreactiveexecute(function(self, entities, count)
	for i = 1,count do
		local entity = entities[i]
		local tt = {}
		tt["1"] = "string"
		tt[1] = "number"
		entity:addview({entity.resource.name, 0,function()end, test={1,2,a="asd",tt}})
	end
end)
:addtrigger(ecs.matcher.resource.added)

-- 刷新显示位置
ecs.system.create("demo.renderposition")
:setreactiveexecute(function(self, entities, count)
	for i = 1,count do
		local entity = entities[i]
		entity.view.gameobject[2] = entity.position.y
	end
end)
:addtrigger(ecs.matcher.view, ecs.matcher.position, ecs.observer.eventtype.added)
:setensurematcher(ecs.matcher.view)

-- 显示
ecs.system.create("demo.gizmos")
:setinitialize(function(self)
	self.group = self.pool:getgroup(ecs.matcher.view)
end)
:setexecute(function(self)
	if self.pool.roundentity then
		log.i("=========== Round:" .. self.pool.roundentity.round.num .. " ==========")
	end
	
	for _, entity in self.group.entities:pairs() do
		log.i(unpack(entity.view.gameobject))
	end
end)