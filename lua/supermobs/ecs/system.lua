local system = ecs.system or {}
ecs.system = system

system.__index = system
local inheritproperty = {
	initialize = "setinitialize",
	execute = "setexecute",
	reactiveexecute = "setreactiveexecute",
	ignoreselftriger = "setignoreselftriger",
	ensurematcher = "setensurematcher",
	excludematcher = "setexcludematcher",
}

function system.create(name)
	local o = {}
	o.name = name
	
	-- o.initialize = nil
	-- o.execute = nil
	-- o.execute = nil
	-- o.observer = nil
	o.ignoreselftriger = false
	o.ensurematcher = ecs.matcher.all
	o.excludematcher = ecs.matcher.none
	
	o.buffer = {}
	o.buffercount = 0
	o.hasinitialize = false
	o.hasexecute = false

	o.__index = o
	o.create = function(pool)
		local s = {}
		s.pool = pool
		if o.observer then s.observer = o.observer.create(pool) end
		setmetatable(s, o)
		return s
	end

	if utils.table.get(system, name) then
		log.w(name .. " system already exist, Covering ...")
	end

	utils.table.set(system, name, o)
	setmetatable(o, system)
	return o
end

function system:inherit(s)
	for k,v in pairs(inheritproperty) do
		local raw = rawget(s, k)
		if raw then
			self[v](self, raw)
		end
	end

	return self
end

function system:setinitialize(func)
	if self.initialize then
		local tmp = self.initialize
		self.initialize = function(...)
			tmp(...)
			func(...)
		end
	else
		self.initialize = function(...)
			func(...)
		end
	end
	self.hasinitialize = true
	return self
end

function system:setexecute(func)
	local tmp = rawget(self, "execute")
	if tmp then
		self.execute = function(...)
			tmp(...)
			func(...)
		end
	else
		self.execute = function(...)
			func(...)
		end
	end

	self.hasexecute = true
	return self
end

function system:setreactiveexecute(func)
	if self.reactiveexecute then
		self.reactiveexecute = function(buffer, count)
			tmp(buffer, count)
			func(buffer, count)
		end
	else
		self.reactiveexecute = func
	end

	self.hasexecute = true
	return self
end

function system:execute()
	if self.observer.collectedcount == 0 then return end

	for i = 1, self.observer.collectedcount do
		local e = self.observer.collected[i]
		if self.ensurematcher:matches(e) and
			not self.excludematcher:matches(e) then
			self.buffercount = self.buffercount + 1
			self.buffer[self.buffercount] = e
		end
	end

	self.observer:clearcollected()

	if self.buffercount > 0 then
		self:reactiveexecute(self.buffer, self.buffercount)
		self.buffercount = 0
		if self.ignoreselftriger then
			self.observer:clearcollected()
		end
	end
end

function system:addtrigger(...)
	if not self.observer then
		self.observer = ecs.observer.create()
	end
	local args = {...}
	if #args == 1 then
		self.observer:add(unpack(args[1]))
	else
		self.observer:add(...)
	end
	return self
end

function system:addtriggerindexfillter(...)
	if not self.observer then
		self.observer = ecs.observer.create()
	end
	self.observer:addindexfillter(...)
end

function system:setignoreselftriger()
	self.ignoreselftriger = true
	return self
end

function system:setensurematcher(matcher)
	self.ensurematcher = matcher
	return self
end

function system:setexcludematcher(matcher)
	self.excludematcher = matcher
	return self
end