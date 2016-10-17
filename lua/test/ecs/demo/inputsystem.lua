ecs.system.create("demo.inputsystem")
:setexecute(function(self)
	-- self.pool.isaccelerating = math.random() > 0.3
	self.pool:replaceaccelerating(math.random() > 0.3)
end)