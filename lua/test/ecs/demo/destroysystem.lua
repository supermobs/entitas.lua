ecs.system.create("demo.destroy")
:setreactiveexecute(function(self, entities, count)
	for i = 1, count do
		self.pool:destroyentity(entities[i])
	end
end)
:addtrigger(ecs.matcher.destroy.added)