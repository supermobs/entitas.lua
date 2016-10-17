local bridge = ecs.bridge or {}
ecs.bridge = bridge

local debugsystems = ecs.debugsystems
local pool = ecs.pool


function bridge.step(name)
	debugsystems.profile[name].enable = true
	debugsystems.allinstances[name]:execute()
	debugsystems.profile[name].enable = false
end

function bridge.reset(name)
	debugsystems.allinstances[name]:resetprofile()
end

function bridge.getsystemsinitializechildren(name)
	return debugsystems.allinstances[name]
		and debugsystems.allinstances[name].initializes
		or {}
end

function bridge.getsystemsexecutechildren(name)
	return debugsystems.allinstances[name]
		and debugsystems.allinstances[name].executes
		or {}
end

function bridge.isreactive(name)
	if debugsystems.allinstances[name] then
		for n,_ in ipairs(debugsystems.allinstances[name].children) do
			if bridge.isreactive(n) then return true end
		end
		return false
	else
		return utils.table.get(ecs.system, name).observer ~= nil
	end
end


function bridge.getentitiescount(poolname)
	local p = pool.get(poolname)
	return #p.entities, #p.freeentities, p.retainedentitycount
end

function bridge.createentity(poolname)
	pool.get(poolname):createentity()
end

function bridge.destroyallentities(poolname)
	local p = pool.get(poolname)
	for _,e in ipairs(p.entities) do
		if e.enable then
			p:destroyentity(e)
		end
	end
end

function bridge.getgroupinfo(poolname)
	return pool.get(poolname).groups
end

function bridge.getentitycomponentids(poolname, entityid)
	local ret = {}
	for componenttypeid, component in pairs(pool.get(poolname).entities[entityid].components) do
		if component ~= ecs.null then
			table.insert(ret, componenttypeid)
		end
	end
	return #ret, unpack(ret)
end

function bridge.getentitycomponetnpropertyvalue(poolname, entityid, componenttypeid, property)
	local component = pool.get(poolname).entities[entityid].components[componenttypeid]
	return component[property]
end

function bridge.setentitycomponetnpropertyvalue(poolname, entityid, componenttypeid, property, value)
	local entity = pool.get(poolname).entities[entityid]
	local component = entity.components[componenttypeid]
	component[property] = value
	entity:replacecomponent(componenttypeid, component)
end

function bridge.addcomponent(poolname, entityid, componenttypeid)
	local p = pool.get(poolname)
	local entity = p.entities[entityid]
	entity:addcomponent(componenttypeid, p:createcomponent(componenttypeid))
end

function bridge.removecomponent(poolname, entityid, componenttypeid)
	local entity = pool.get(poolname).entities[entityid]
	entity:removecomponent(componenttypeid)
end

function bridge.getentityowners(poolname, entityid)
	local entity = pool.get(poolname).entities[entityid]
	return #entity.owners, unpack(entity.owners)
end

function bridge.getentityretaincount(poolname, entityid)
	local entity = pool.get(poolname).entities[entityid]
	return entity.retaincount
end

function bridge.ismatch(poolname, entityid, matcherid)
	local entity = pool.get(poolname).entities[entityid]
	local matcher = ecs.matcher.cache[matcherid]
	return matcher:matches(entity)
end

function bridge.destroyentity(poolname, entityid)
	local p = pool.get(poolname)
	local entity = p.entities[entityid]
	p:destroyentity(entity)
end