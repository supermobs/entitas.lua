local component = ecs.component or {}
ecs.component = component

component.allcomponentnames = {}
component.allcomponentpropertys = {}
component.singlecomponenttypeids = {}
component.shortnamedict = {}
component.packagecomponents = {}

function component.regist(name, ...)
	if component[name] then
		error("component name " .. name .. " is duplation")
	end

	table.insert(component.allcomponentnames, name)
	table.insert(component.allcomponentpropertys, {...})

	local componenttypeid = #component.allcomponentnames
	component[name] = componenttypeid
	local shortkey = utils.table.set(component, name, componenttypeid)
	if component.shortnamedict[shortkey] == nil then
		component.shortnamedict[shortkey] = componenttypeid
	else
		component.shortnamedict[shortkey] = -1
	end

	local packagename = string.sub(name, 1, string.len(name) - string.len(shortkey)) .. "*"
	if not component.packagecomponents[packagename] then component.packagecomponents[packagename] = {} end
	table.insert(component.packagecomponents[packagename], shortkey)

	return componenttypeid
end

function component.registsingle(name, ...)
	local componenttypeid = component.regist(name, ...)
	component.singlecomponenttypeids[componenttypeid] = true
	return componenttypeid
end

function component.create(pool, name)
	return {__componenttypeid = component.getcomponenttypeid(name)}
end

function component.getpropertys(componenttypeid)
	return component.allcomponentpropertys[componenttypeid]
end

if ecs.debug then
	function component.getcomponenttypeid(name)
		local id = component[name] or component.shortnamedict[name]
		if id == -1 then
			if not pcall(function()
				id = component[ecs.shorttablearray[getfenv(5).ECS_SHORT_TABLE_INDEX][name]]
			end) then
				error("componet name " .. name .. " is not explicited")
			end
		end
		return id
	end
else
	function component.getcomponenttypeid(name)
		local id = component[name] or component.shortnamedict[name]
		if id == -1 then
			id = component[ecs.shorttablearray[getfenv(3).ECS_SHORT_TABLE_INDEX][name]]
		end
		return id
	end
end

function component.getname(componenttypeid)
	return component.allcomponentnames[componenttypeid]
end

function component.issingle(componenttypeid)
	return component.singlecomponenttypeids[componenttypeid]
end