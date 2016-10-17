ecs.explicit({"demo.*"})

-- 创建玩家
ecs.system.create("demo.createplayer")
:setinitialize(function(self)
	self.pool:createentity()
		:addresource("MainPlayer")
		:addposition(0, 0, 0)
        :addmove(0, 0.2)
		:setisacceleratable(true)
end)

-- 创建对手
ecs.system.create("demo.createopponents")
:setinitialize(function(self)
	for i = 1,3 do
        local speed = math.random() * 0.5 + 0.1;
        self.pool:createentity()
        	:addresource("Opponent"..i)
        	:addposition(i, 0, 0)
            :addmove(speed, speed)
	end
end)

-- 创建终点线
ecs.system.create("demo.createfinishline")
:setinitialize(function(self)
	self.pool:createentity()
		:setisfinishline(true)
		:addresource("finishline")
		:addposition(9, 999, 0)

	self.pool:createentity()
		:addround(0)
end)