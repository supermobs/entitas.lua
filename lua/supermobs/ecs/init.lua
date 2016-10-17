ecs = ecs or {}
ecs.null = {}
ecs.debug = true

require "supermobs.ecs.pool"
require "supermobs.ecs.entity"
require "supermobs.ecs.component"
require "supermobs.ecs.matcher"
require "supermobs.ecs.group"
require "supermobs.ecs.observer"
require "supermobs.ecs.system"
require "supermobs.ecs.systems"
require "supermobs.ecs.debugsystems"
require "supermobs.ecs.bridge"

ecs.feature = ecs.debug and ecs.debugsystems or ecs.systems

-- short name for components
ecs.shorttablearray = {}
local function calculateshort(index)
	local shorttable = ecs.shorttablearray[index]
	for _,packagename in ipairs(shorttable) do
		local nameprefix = string.sub(packagename, 1, string.len(packagename) - 1)
		for _,shortname in ipairs(ecs.component.packagecomponents[packagename]) do
			if not shorttable[shortname] then
				shorttable[shortname] = nameprefix .. shortname
			end
		end
	end
end

ecs.explicit = function(shorttable)
	table.insert(ecs.shorttablearray, shorttable)
	if ecs.started then calculateshort(#ecs.shorttablearray) end

	local env = {ECS_SHORT_TABLE_INDEX = #ecs.shorttablearray}
	setmetatable(env, {__index = _G, __newindex = _G})
	setfenv(2, env)

	return #ecs.shorttablearray
end


-- init order
ecs.started = false
local componentfilesarray = {}
local systemfilesarray = {}
ecs.regmodule = function(componentfiles, systemfiles)
	table.insert(componentfilesarray, componentfiles or {})
	table.insert(systemfilesarray, systemfiles or {})
end

ecs.start = function()
	for _,files in ipairs(componentfilesarray) do
		for _,f in ipairs(files) do
			require(f)
		end
	end
	componentfilesarray = nil

	for index = 1,#ecs.shorttablearray do
		calculateshort(index)
	end
	ecs.started = true

	for _,files in ipairs(systemfilesarray) do
		for _,f in ipairs(files) do
			require(f)
		end
	end
	systemfilesarray = nil

	if ECS_INIT_EDITOR_ENTITY then ECS_INIT_EDITOR_ENTITY() end
	if ECS_INIT_EDITOR_POOL then ECS_INIT_EDITOR_POOL() end
	if ECS_INIT_EDITOR_SYSTEMS then ECS_INIT_EDITOR_SYSTEMS() end
end