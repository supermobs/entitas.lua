local entity = ecs.entity or {}
ecs.entity = entity

local indexpropertycache = {}
local newindexpropertycache = {}
entity.__index = function(t, k)
	if entity[k] then return entity[k] end

	local componenttypeid = ecs.component.getcomponenttypeid(k)
	if componenttypeid ~= nil then
		return t:hascomponent(componenttypeid) and t.components[componenttypeid] or nil
	else
		if not indexpropertycache[k] then
			local func
			if string.sub(k, 1, 2) == "is" then
				local componentname = string.sub(k, 3)
				func = function(e) return e:hascomponent(ecs.component.getcomponenttypeid(componentname)) end
			elseif string.sub(k, 1, 3) == "has" then
				local componentname = string.sub(k, 4)
				func = function(e) return e:hascomponent(ecs.component.getcomponenttypeid(componentname)) end
			end

			indexpropertycache[k] = func and func or ecs.null
		end

		if indexpropertycache[k] == ecs.null then return end

		return indexpropertycache[k](t)
	end
end
entity.__newindex = function(t, k, v)
	if not newindexpropertycache[k] then
		local func
		if string.sub(k, 1, 2) == "is" then
			local componentname = string.sub(k, 3)
			func = function(e, value) return e:is(ecs.component.getcomponenttypeid(componentname), value) end
		end

		newindexpropertycache[k] = func and func or ecs.null
	end

	if newindexpropertycache[k] == ecs.null then
		rawset(t, k, v)
	else
		newindexpropertycache[k](t, v)
	end
end

setmetatable(entity, {__index = function(t, k)
	if string.sub(k, 1, 3) == "add" then
		local componentname = string.sub(k, 4)
		entity[k] = function(self, ...)
			return self:add(ecs.component.getcomponenttypeid(componentname), ...)
		end
	elseif string.sub(k, 1, 6) == "remove" then
		local componentname = string.sub(k, 7)
		entity[k] = function(self)
			return self:remove(ecs.component.getcomponenttypeid(componentname))
		end
	elseif string.sub(k, 1, 7) == "replace" then
		local componentname = string.sub(k, 8)
		entity[k] = function(self, ...)
			return self:replace(ecs.component.getcomponenttypeid(componentname), ...)
		end
	elseif string.sub(k, 1, 5) == "setis" then
		local componentname = string.sub(k, 6)
		entity[k] = function(self, value)
			return self:is(ecs.component.getcomponenttypeid(componentname), value)
		end
	end
	return rawget(entity, k)
end})





--[[
entity属性
	components 拥有的component列表，id-com，kv形式
entity方法
	hascomponent(componenttypeid)
	hasanycomponent(componenttypeids[])
	hascomponents(componenttypeids[])
	addcomponent(componenttypeid, com)、removecomponent(componenttypeid)、replacecomponent(componenttypeid, com)
	destroy()
	add、remove、replace、is
--]]

function entity.create(pool)
	local o = {}
	o.pool = pool

	o.__id = -1
	o.enable = true
	o.components = {}
	o.owners = {}
	o.retaincount = 0
	
	setmetatable(o, entity)
	return o
end

function entity:add(componenttypeid, ...)
	local component = self.pool:createcomponent(componenttypeid, ...)
	return self:addcomponent(componenttypeid, component)
end

function entity:replace(componenttypeid, ...)
	local component = self.pool:createcomponent(componenttypeid, ...)
	return self:replacecomponent(componenttypeid, component)
end

function entity:remove(componenttypeid)
	return self:removecomponent(componenttypeid)
end

function entity:is(componenttypeid, value)
	local has = self:hascomponent(componenttypeid)
	if value == nil then
		return has
	elseif (not value) == has then
		return value and self:add(componenttypeid) or self:remove(componenttypeid)
	else
		return self
	end
end

function entity:addcomponent(componenttypeid, component)
	if not self.enable then
		error("EntityIsNotEnabledException, pool = " .. self.pool.name)
	end

	if self:hascomponent(componenttypeid) then
		error("EntityAlreadyHasComponentException， component = " .. ecs.component.getcomponentname(componenttypeid))
	end

	self.components[componenttypeid] = component
	self.pool:updategroups(ecs.pool.groupsupdatetype.componentaddedorremoved, self, componenttypeid, component, previouscomponent)

	return self
end

function entity:removecomponent(componenttypeid)
	if not self.enable then
		error("EntityIsNotEnabledException, pool = " .. self.poolname)
	end

	return self:replacecomponent(componenttypeid, ecs.null)
end

function entity:replacecomponent(componenttypeid, component)
	if not self:hascomponent(componenttypeid) then
		return self:addcomponent(componenttypeid, component)
	end

	local previous = self.components[componenttypeid]
	if previous == component then
		self.pool:updategroups(ecs.pool.groupsupdatetype.componentreplaced, self, componenttypeid, component, previous)
	else
		self.components[componenttypeid] = component
		self.pool:recyclecomponent(componenttypeid, previous)
		if component == ecs.null then
			self.pool:updategroups(ecs.pool.groupsupdatetype.componentaddedorremoved, self, componenttypeid, previous)
		else
			self.pool:updategroups(ecs.pool.groupsupdatetype.componentreplaced, self, componenttypeid, component, previous)
		end
	end

	return self
end

function entity:destroy()
	for k,v in pairs(self.components) do
		self:removecomponent(k)
	end
	self.enable = false
end

function entity:hascomponent(componenttypeid)
	local component = self.components[componenttypeid]
	return component ~= ecs.null and component ~= nil
end

if ECS_POOL_ONENTITYCREATE then
	function entity:release(owner)
		local removed
		for i,v in ipairs(self.owners) do
			if v == owner.desc then
				removed = table.remove(self.owners, i)
				break
			end
		end

		if not removed then
			error("release exception, entity do not retained by " .. owner.desc)
		end

		self.retaincount = self.retaincount - 1
		if self.retaincount == 0 then
			self.pool:entityreleased(self)
		end
	end

	function entity:retain(owner)
		self.retaincount = self.retaincount + 1
		table.insert(self.owners, owner.desc)
	end
else
	function entity:release(owner)
		self.retaincount = self.retaincount - 1
		if self.retaincount == 0 then
			self.pool:entityreleased(self)
		end
	end

	function entity:retain(owner)
		self.retaincount = self.retaincount + 1
	end
end