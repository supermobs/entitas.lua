require "test.ecs.demo.components"
require "test.ecs.demo.testsystem"
require "test.ecs.demo.initsystem"
require "test.ecs.demo.destroysystem"
require "test.ecs.demo.inputsystem"
require "test.ecs.demo.movesystem"
require "test.ecs.demo.viewsystem"


local testpool = ecs.pool.create("test")

local ss = ecs.systems.create(testpool, "test")
-- debug
-- :addsystem(ecs.system.test.printtime)
-- :addsystem(ecs.system.test.counter)
-- debug view
:addsystem(ecs.system.demo.gizmos)
-- initialize
:addsystem(ecs.system.demo.createplayer)
:addsystem(ecs.system.demo.createopponents)
:addsystem(ecs.system.demo.createfinishline)
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
while not testpool.isgameover do
	-- local t = utils.time.now()
	ss:execute()
	-- while utils.time.now() - t < 0.1 do end
end

log.i("GameOver")

