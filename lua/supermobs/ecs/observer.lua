local observer = ecs.observer or {}
ecs.observer = observer

observer.__index = observer
observer.eventtype = {
	added = 1,
	removed = 2,
	addedorremoved = 3,
	updated = 4
}
observer.eventmap = {
	{ecs.group.eventtype.added},
	{ecs.group.eventtype.removed},
	{ecs.group.eventtype.added, ecs.group.eventtype.removed},
	{ecs.group.eventtype.updated}
}
observer.eventmapdesc = {"added", "removed", "addedorremoved", "updated"}


function observer.create()
	local o = {}
	o.matchers = {}
	o.events = {}
	o.indexfillter = {}
	o.__index = o

	o.create = function(pool)
		local s = {}
		s.collectedcount = 0
		s.collected = {}
		s.enable = true

		s.__entityadd = function(group, entity)
			local allchange = true
			for _,indexnames in ipairs(o.indexfillter) do
				allchange = true
				for _,indexname in ipairs(indexnames) do
					allchange = allchange and (group:getentityindexvalue(indexname, entity)
						~= group:getentityindexprevalue(indexname, entity))
					if not allchange then break end
				end
				if allchange then break end
			end

			if allchange then
				observer.entityadd(s, entity)
			end
		end
		setmetatable(s, o)

		o.desc = "observer_["
		for i = 1, #o.matchers do
			local group = pool:getgroup(o.matchers[i])
			o.desc = o.desc .. group.desc .. "_" .. observer.eventmapdesc[o.events[i]] .. "]"
			for _,eventtype in ipairs(observer.eventmap[o.events[i]]) do
				group:listen(eventtype, s.__entityadd)
			end
		end

		return s
	end

	setmetatable(o, observer)
	return o
end

function observer:add(...)
	local args = {...}
	local matcher = ecs.matcher.sub(unpack(args, 1, #args-1))
	local eventtype = args[#args]
	table.insert(self.matchers, matcher)
	table.insert(self.events, eventtype)
end

function observer:addindexfillter(...)
	table.insert(self.indexfillter, {...})
end

function observer:entityadd(entity)
	if not self.enable then return end

	entity:retain(self)
	self.collectedcount = self.collectedcount + 1
	self.collected[self.collectedcount] = entity
end

function observer:clearcollected()
	for i = 1,self.collectedcount do
		self.collected[i]:release(self)
	end
	self.collectedcount = 0
end

function observer:activate()
	self.enable = true
end

function observer:deactivate()
	self.enable = false
	self:clearcollected()
end

function observer:destroy()
	self:deactivate()
	for i = 1, #self.matchers do
		local group = pool:getgroup(self.matchers[i])
		for _,eventtype in ipairs(observer.eventmap[self.events[i]]) do
			group:unlisten(eventtype, self.__entityadd)
		end
	end
end