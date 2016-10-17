local debugsystems = ecs.debugsystems or {}
ecs.debugsystems = debugsystems

debugsystems.__index = debugsystems

debugsystems.profile = {}
debugsystems.onCreate = ECS_DEBUGSYSTEMS_ONCREATE or function() end
debugsystems.onParent = ECS_DEBUGSYSTEMS_ONPARENT or function() end

debugsystems.allinstances = {}

--[[
	initializesystemcount
	executesystemcount

	enable				是否启用,影响execute
	initializecost		初始化时间消耗
	executecosttotal	总执行消耗
	executecount		总执行次数
	executecostnow		最近一次执行消耗
	executecostmax		最大执行消耗
	executecostmin		最小执行消耗
]]


function debugsystems.create(pool, name)
	local o = ecs.systems.create(pool, name)
	o.toplevel = true
	setmetatable(o, debugsystems)
	if getmetatable(debugsystems) == nil then
		setmetatable(debugsystems, ecs.systems)
	end

	debugsystems.allinstances[name] = o
	debugsystems.onCreate(name)
	return o
end

function debugsystems:initialize()
	for name,child in pairs(self.children) do
		debugsystems.profile[name] = {
			enable = true,
			initializecost = -1,
			executecosttotal = 0,
			executecount = 0,
			executecostmax = 0,
			executecostmin = 99999
		}
	end

	if self.toplevel then
		debugsystems.profile[self.name] =  {
			enable = true,
			initializecost = utils.time.now(),
			executecosttotal = 0,
			executecount = 0,
			executecostmax = 0,
			executecostmin = 99999
		}
	end
	
	for _,child in ipairs(self.initializes) do
		local info = debugsystems.profile[child.name]
		info.initializecost = utils.time.now()
		child:initialize()
		info.initializecost = utils.time.now() - info.initializecost
	end

	if self.toplevel then
		debugsystems.profile[self.name].initializecost = utils.time.now() - debugsystems.profile[self.name].initializecost
	end

	debugsystems.profile[self.name].initializesystemcount = #self.initializes
	debugsystems.profile[self.name].executesystemcount = #self.executes
	self.initialized = true
end

function debugsystems:execute()
	local selfinfo = debugsystems.profile[self.name]
	if not selfinfo.enable then return end

	if self.toplevel then
		selfinfo.executecostnow = utils.time.now()
	end

	for _,child in ipairs(self.executes) do
		local info = debugsystems.profile[child.name]
		if info.enable then
			if child.observer and not child.observer.enable then
				child.observer:activate()
			end

			info.executecostnow = utils.time.now()
			child:execute()
			info.executecostnow = utils.time.now() - info.executecostnow

			info.executecosttotal = info.executecosttotal + info.executecostnow
			info.executecount = info.executecount + 1
			if info.executecostnow > info.executecostmax then info.executecostmax = info.executecostnow end
			if info.executecostnow < info.executecostmin then info.executecostmin = info.executecostnow end
		elseif child.observer and child.observer.enable then
			child.observer:deactivate()
		end
	end

	if self.toplevel then
		selfinfo.executecostnow = utils.time.now() - selfinfo.executecostnow
		selfinfo.executecosttotal = selfinfo.executecosttotal + selfinfo.executecostnow
		selfinfo.executecount = selfinfo.executecount + 1
		if selfinfo.executecostnow > selfinfo.executecostmax then selfinfo.executecostmax = selfinfo.executecostnow end
		if selfinfo.executecostnow < selfinfo.executecostmin then selfinfo.executecostmin = selfinfo.executecostnow end
	end
end


function debugsystems:addchild(child)
	local ret = ecs.systems.addchild(self, child)
	if getmetatable(child) == debugsystems then
		debugsystems.onParent(child.name, self.name)
		child.toplevel = false
	end
	return ret
end

function debugsystems:resetprofile()
	debugsystems.profile[self.name].executecosttotal = 0
	debugsystems.profile[self.name].executecount = 0
	debugsystems.profile[self.name].executecostmax = 0
	debugsystems.profile[self.name].executecostmin = 99999

	for _,system in pairs(self.executes) do
		local info = debugsystems.profile[system.name]
		info.executecosttotal = 0
		info.executecount = 0
		info.executecostmax = 0
		info.executecostmin = 99999
	end

	for _,n in pairs(self.allsystemsorder) do
		self.allsystems[n]:resetprofile()
	end
end