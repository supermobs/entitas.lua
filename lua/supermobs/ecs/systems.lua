local systems = ecs.systems or {}
ecs.systems = systems

systems.__index = systems

function systems.create(pool, name)
	local o = {}
	o.name = name
	o.pool = pool

	o.children = {}
	o.initializes = {}
	o.executes = {}

	o.initialized = false
	o.hasexecute = true

	setmetatable(o, systems)
	return o
end

function systems:initialize()
	for _,s in ipairs(self.initializes) do
		s:initialize()
	end
	self.initialized = true
end

function systems:execute()
	for _,s in ipairs(self.executes) do
		s:execute()
	end
end

function systems:addchild(child)
	if self.children[child.name] then
		error("the child named " .. child.name .. " has been added!")
	end

	if self.initialized then
		error("the systems you addto is already running")
	end

	self.children[child.name] = child

	if child.hasexecute then
		table.insert(self.executes, child)
	end

	if child.hasinitialize then
		table.insert(self.initializes, child)
		self.hasinitialize = true
	end

	return self
end


function systems:addsystem(system)
	return self:addchild(system.create(self.pool))
end

function systems:add(name, ...)
	local ss = getmetatable(self).create(self.pool, name)
	for _,system in ipairs({...}) do
		ss:addsystem(system)
	end

	return self:addchild(ss)
end