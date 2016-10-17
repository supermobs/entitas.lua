require "supermobs.init"

ecs.regmodule({
	"test.ecs.demo.components"
},{
	"test.ecs.demo.testsystem",
	"test.ecs.demo.initsystem",
	"test.ecs.demo.destroysystem",
	"test.ecs.demo.inputsystem",
	"test.ecs.demo.movesystem",
	"test.ecs.demo.viewsystem"
})

ecs.start()

ecs.explicit({"demo.*"})
local testpool = ecs.pool.create("test")

local ss = ecs.feature.create(testpool, "test")
-- debug
-- :addsystem(ecs.system.test.printtime)
-- :addsystem(ecs.system.test.counter)

-- debug view
-- :addsystem(ecs.system.demo.gizmos)
:add("view", ecs.system.demo.gizmos)

-- initialize
-- :addsystem(ecs.system.demo.createplayer)
-- :addsystem(ecs.system.demo.createopponents)
-- :addsystem(ecs.system.demo.createfinishline)
:add("initialize", ecs.system.demo.createplayer, ecs.system.demo.createopponents, ecs.system.demo.createfinishline)

-- input
:addsystem(ecs.system.demo.inputsystem)

-- update
:addsystem(ecs.system.demo.accelerate)
:addsystem(ecs.system.demo.move)
:addsystem(ecs.system.demo.reachedfinish)

-- render
:addsystem(ecs.system.demo.removeview)
:addsystem(ecs.system.demo.addview)
:addsystem(ecs.system.demo.renderposition)

-- destroy
:addsystem(ecs.system.demo.destroy)


ss:initialize()

UPDATE = function()
	ss:execute()
	return testpool.isgameover
end