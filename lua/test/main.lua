require "supermobs.init"

local tests = {
	{--1
		pack = "ecs.demo",
		name = "命令行随机赛车",
		desc = "命令行随机赛车",
		run = function() require "test.ecs.demo.main" end
	}
}

-- if #arg > 0 then
-- 	tests[tonumber(arg[1])].run()
-- else
-- 	return tests
-- end

tests[1].run()