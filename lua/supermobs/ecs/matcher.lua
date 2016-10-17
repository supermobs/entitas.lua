local matcher = ecs.matcher or {}
ecs.matcher = matcher

matcher.none = {
	id = -1,
	matches = function(self, entity) return false end
}
matcher.all = {
	id = -2,
	matches = function(self, entity) return entity.enable end
}

matcher.__index = matcher

local splitkey = "split"
matcher.cache = {} -- matcher的缓存
matcher.keycachenum = 1
matcher.keycache = {} -- sort之后的componettypeid列表索引

local function calculatecachekey(dictall, dictany, dictnone)
	local keycache = matcher.keycache
	local indicescount = 0

	dictall = dictall or {}
	dictany = dictany or {}
	dictnone = dictnone or {}

	for _,dict in ipairs({dictall, dictany, dictnone}) do
		local arr = {}
		for k,_ in pairs(dict) do
			table.insert(arr, k)
		end
		table.sort(arr)
		indicescount = indicescount + #arr
		table.insert(arr, splitkey)

		for _,k in ipairs(arr) do
			if not keycache[k] then
				keycache[k] = {}
			end
			keycache = keycache[k]
		end
	end
	
	if not keycache[splitkey] then
		matcher.keycachenum = matcher.keycachenum + 1
		keycache[splitkey] = matcher.keycachenum
	end

	return keycache[splitkey], indicescount
end

local function arr2dict(arr)
	local dict = nil
	if arr and #arr > 0 then
		dict = {}
		for _,k in ipairs(arr) do
			if type(k) == "table" then
				if k.indicescount ~= 1 then
					error("matcher.indices.Length must be 1")
				else
					dict[k:getoneindice()] = true
				end
			else
				dict[k] = true
			end
		end
	end
	return dict
end

local function makematcherbydict(dictall, dictany, dictnone)
	local key, indicescount = calculatecachekey(dictall, dictany, dictnone)
	if not matcher.cache[key] then
		local m = {
			allofindices = dictall or ecs.null,
			anyofindices = dictany or ecs.null,
			noneofindices = dictnone or ecs.null,
			indicescount = indicescount,
			id = key
		}
		m.added = {m, ecs.observer.eventtype.added}
		m.removed = {m, ecs.observer.eventtype.removed}
		m.addedorremoved = {m, ecs.observer.eventtype.addedorremoved}
		setmetatable(m, matcher)
		matcher.cache[key] = m
	end
	return matcher.cache[key]
end

local function makematcher(allarr, anyarr, nonearr)
	return makematcherbydict(arr2dict(allarr), arr2dict(anyarr), arr2dict(nonearr))
end

local function dict2string(dict)
	local ret = ""
	for k,_ in pairs(dict) do
		if string.len(ret) ~= 0 then ret = ret .. "," end
		ret = ret .. ecs.component.getname(k)
	end
	return ret
end

function matcher:tostring()
	local ret = self.id
	local tmp = dict2string(self.allofindices)
	if string.len(tmp) > 0 then
		ret = ret .. "all["..tmp.."]"
	end
	tmp = dict2string(self.anyofindices)
	if string.len(tmp) > 0 then
		ret = ret .. "any["..tmp.."]"
	end
	tmp = dict2string(self.noneofindices)
	if string.len(tmp) > 0 then
		ret = ret .. "none["..tmp.."]"
	end
	return ret
end

function matcher:matches(entity)
	for index,_ in pairs(self.allofindices) do
		if not entity:hascomponent(index) then
			return false
		end
	end

	if self.anyofindices ~= ecs.null then
		local has = false
		for index,_ in pairs(self.anyofindices) do
			if entity:hascomponent(index) then
				has = true
				break
			end
		end
		if not has then return false end
	end

	for index,_ in pairs(self.noneofindices) do
		if entity:hascomponent(index) then
			return false
		end
	end

	return true
end

function matcher:getoneindice()
	for k,_ in pairs(self.allofindices) do
		return k
	end
	for k,_ in pairs(self.anyofindices) do
		return k
	end
	for k,_ in pairs(self.noneofindices) do
		return k
	end
end

function matcher.allof( ... )
	return makematcher({...})
end

function matcher.anyof( ... )
	return makematcher(nil, {...})
end

function matcher.noneof( ... )
	return makematcher(nil, nil, {...})
end

function matcher.sub(...)
	local args = {...}
	if #args <= 1 then return args[1] end

	local all, any, none
	for _,v in ipairs(args) do
		for k,_ in pairs(v.allofindices) do
			all = all or {}
			all[k] = true
		end
		for k,_ in pairs(v.anyofindices) do
			any = any or {}
			any[k] = true
		end
		for k,_ in pairs(v.noneofindices) do
			none = none or {}
			none[k] = true
		end
	end

	return makematcherbydict(all, any, none)
end

function matcher.make(all, any, none)
	return makematcher(all, any, none)
end


setmetatable(matcher, {__index = function(t, k)
	local componenttypeid = ecs.component.getcomponenttypeid(k)

	local ret = rawget(t, componenttypeid)
	if not ret then
		ret = makematcher({componenttypeid})
		rawset(t, componenttypeid, ret)
	end
	return ret
end})