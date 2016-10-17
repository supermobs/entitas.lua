local pool = ecs.pool or {}
ecs.pool = pool

pool.groupsupdatetype = {
	componentaddedorremoved = 1,
	componentreplaced = 2
}

pool.instances = {}

pool.oncreate = ECS_POOL_ONCREATE or function() end
pool.onentitycreate = ECS_POOL_ONENTITYCREATE or function() end
pool.onentitydestroy = ECS_POOL_ONENTITYDESTROY or function() end


local indexpropertycache = {}
local newindexpropertycache = {}
pool.__index = function(t, k)
	if pool[k] then return pool[k] end

	if not indexpropertycache[k] then
		local func
		local isfunction
		if string.sub(k, -6) == "entity" then
			local componentname = string.sub(k, 1, string.len(k) - 6)
			isfunction = false
			func = function(p) return p:getsingleentity(ecs.component.getcomponenttypeid(componentname)) end
		elseif string.sub(k, 1, 2) == "is" then
			local componentname = string.sub(k, 3)
			isfunction = false
			func = function(p) return p:is(ecs.component.getcomponenttypeid(componentname)) end
		elseif string.sub(k, 1, 3) == "has" then
			local componentname = string.sub(k, 4)
			isfunction = false
			func = function(p) return p:is(ecs.component.getcomponenttypeid(componentname)) end
		elseif string.sub(k, 1, 3) == "set" or string.sub(k, 1, 3) == "add" then
			local componentname = string.sub(k, 4)
			isfunction = true
			func = function(p, ...)
				local componenttypeid = ecs.component.getcomponenttypeid(componentname)
				if p:is(componenttypeid) then
					error("already has an entity with " .. componentname)
				end
				return p:createentity():add(componenttypeid, ...)
			end
		elseif string.sub(k, 1, 7) == "replace" then
			local componentname = string.sub(k, 8)
			isfunction = true
			func = function(p, ...)
				local componenttypeid = ecs.component.getcomponenttypeid(componentname)
				local entity = p:getsingleentity(componenttypeid)
				if entity ~= nil then
					return entity:replace(componenttypeid, ...)
				else
					return p:createentity():add(componenttypeid, ...)
				end
			end
		elseif string.sub(k, 1, 6) == "remove" then
			local componentname = string.sub(k, 7)
			isfunction = true
			func = function(p)
				local componenttypeid = ecs.component.getcomponenttypeid(componentname)
				p:destroyentity(p:getsingleentity(componenttypeid))
			end
		else
			isfunction = false
			func = function(p)
				local componenttypeid = ecs.component.getcomponenttypeid(k)
				return p:getsingleentity(componenttypeid)[k]
			end
		end

		indexpropertycache[k] = func and {isfunction, func} or ecs.null
	end

	local property = indexpropertycache[k]
	if property == ecs.null then return end
	if property[1] then
		return indexpropertycache[k][2]
	else
		return indexpropertycache[k][2](t)
	end
end
pool.__newindex = function(t, k, v)
	if not newindexpropertycache[k] then
		local func
		if string.sub(k, 1, 2) == "is" then
			local componentname = string.sub(k, 3)
			func = function(p, value) return p:is(ecs.component.getcomponenttypeid(componentname), value) end
		end

		newindexpropertycache[k] = func and func or ecs.null
	end

	if newindexpropertycache[k] == ecs.null then
		rawset(t, k, v)
	else
		newindexpropertycache[k](t, v)
	end
end


function pool.create(name)
	local o = {}

	o.name = name
	o.entities = {}
	o.freeentities = {}
	o.components = {}
	o.freecomponents = {}
	o.retainedentitycount = 0

	o.groups = {}
	o.groupskeyorder = {}
	o.componentaboutmatcher = {} -- componenttypeid to matcherid dict

	o.desc = "pool_" .. name

	setmetatable(o, pool)

	if pool.get(name) then
		error("there is a pool creted with the same name '" .. name .. "'")
	end
	pool.instances[name] = o

	pool.oncreate(name)
	return o
end

function pool.get(name)
	return pool.instances[name]
end

function pool:createentity()
	local entity
	if #self.freeentities > 0 then
		entity = table.remove(self.freeentities)
		entity.enable = true
	else
		entity = ecs.entity.create(self)
		table.insert(self.entities, entity)
		entity.__id = #self.entities
	end

	entity:retain(self)
	pool.onentitycreate(self.name, entity.__id)
	return entity
end

function pool:entityreleased(entity)
	if entity.enable then
		error("can not recycle entity " .. entity.__id)
	end
	self.retainedentitycount = self.retainedentitycount - 1
	table.insert(self.freeentities, entity)
	pool.onentitydestroy(self.name, entity.__id)
end

function pool:destroyentity(entity)
	entity:destroy()
	self.retainedentitycount = self.retainedentitycount + 1
	entity:release(self)
end

function pool:createcomponent(componenttypeid, ...)
	local componentvalues = {...}
	local componentpropertys = ecs.component.getpropertys(componenttypeid)

	if self.components[componenttypeid] == nil then
		self.components[componenttypeid] = {}
		self.freecomponents[componenttypeid] = {}
	end

	local component
	if #self.freecomponents[componenttypeid] > 0 then
		component = table.remove(self.freecomponents[componenttypeid])
	else
		component = ecs.component.create(self, componenttypeid)
		table.insert(self.components[componenttypeid], component)
		component.__id = #self.components[componenttypeid]
	end

	for i = 1,#componentpropertys do
		component[componentpropertys[i]] = componentvalues[i]
	end

	component.enable = true
	return component
end

function pool:recyclecomponent(componenttypeid, component)
	table.insert(self.freecomponents[componenttypeid], component)
end

function pool:updategroups(updatetype, entity, componenttypeid, component, previouscomponent)
	local groupdict = self.componentaboutmatcher[componenttypeid]
	if not groupdict then return end

	if updatetype == pool.groupsupdatetype.componentaddedorremoved then
		local noticelist = {}
		for _,matcherid in ipairs(self.groupskeyorder) do
			if groupdict[matcherid] then
				local noticetype = self.groups[matcherid]:handleentitysilently(entity)
				if noticetype then
					table.insert(noticelist, matcherid)
					table.insert(noticelist, noticetype)
				end
			end
		end

		for i = 1, #noticelist / 2 do
			self.groups[noticelist[i*2-1]]:noticehandler(noticelist[i*2],
				entity, componenttypeid, component, previouscomponent)
		end
	else
		for _,matcherid in ipairs(self.groupskeyorder) do
			if groupdict[matcherid] and self.groups[matcherid].entities[entity.__id] then
				self.groups[matcherid]:noticehandler(ecs.group.eventtype.removed,
					entity, componenttypeid, previouscomponent)
				self.groups[matcherid]:noticehandler(ecs.group.eventtype.added,
					entity, componenttypeid, component)
				self.groups[matcherid]:noticehandler(ecs.group.eventtype.updated,
					entity, componenttypeid, component, previouscomponent)
			end
		end
	end
end

function pool:getgroup(...)
	local matcher = ecs.matcher.sub(...)
	if not self.groups[matcher.id] then
		local group = ecs.group.create(matcher)
		for _,v in ipairs(self.entities) do
			if v.enable then
				group:handleentitysilently(v)
			end
		end

		self.groups[matcher.id] = group
		table.insert(self.groupskeyorder, matcher.id)

		for _,dict in ipairs({matcher.allofindices, matcher.anyofindices, matcher.noneofindices}) do
			for componenttypeid,_ in pairs(dict) do
				local about = self.componentaboutmatcher[componenttypeid]
				if not about then
					about = {}
					self.componentaboutmatcher[componenttypeid] = about
				end
				about[matcher.id] = true
			end
		end

	end

	return self.groups[matcher.id]
end


function pool:getsingleentity(componenttypeid)
	if not ecs.component.issingle(componenttypeid) then
		error("getsingleentity error, component " .. ecs.component.getname(componenttypeid) .. " is not single component")
	end

	return self:getgroup(ecs.matcher.allof(componenttypeid)):getsingleentity()
end

function pool:is(componenttypeid, value)
	local entity = self:getsingleentity(componenttypeid)
	if value == nil then
		return entity ~= nil
	else
		if value then
			if entity == nil then
				self:createentity():is(componenttypeid, true)
			end
		else
			if entity ~= nil then
				self:destroyentity(entity)
			end
		end
	end

	return self
end