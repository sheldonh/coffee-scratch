{TestClock} = require './clocks'
timers = require 'timers'
assert = require('assert')

describe 'TestClock', ->

  it 'emits "start" as you start it', (done) ->
    clock = new TestClock(0)
    clock.on 'start', -> done()
    clock.start()
    clock.stop()

  it 'emits "tick" as you start it', (done) ->
    clock = new TestClock(0)
    clock.on 'tick', -> done()
    clock.start()
    clock.stop()

  it 'emits "tick" at the clock interval', (done) ->
    clock = new TestClock(0)
    ticks = 0
    clock.on 'tick', ->
      if ++ticks == 3
        done()
    clock.start()

  it 'emits "stop" as you stop it', (done) ->
    clock = new TestClock(0)
    clock.on 'stop', -> done()
    clock.start()
    clock.stop()

  it 'stops emitting "tick" when you stop it', (done) ->
    clock = new TestClock(0)
    clock.on 'stop', ->
      clock.on 'tick', -> assert false, 'Y U NO STOP TICK?'
      timers.setTimeout (-> done()), 5
    clock.start()
    clock.stop()

  it 'does not emit "start" if already started', ->
    clock = new TestClock(0)
    starts = 0
    clock.on 'start', ->
      assert ++starts == 1, 'Y U START TWICE?'
    clock.start()
    clock.start()
    clock.stop()

  it 'does not emit "stop" if already stopped', ->
    clock = new TestClock(0)
    stops = 0
    clock.on 'stop', ->
      assert ++stops == 1, 'Y U STOP TWICE?'
    clock.start()
    clock.stop()
    clock.stop()

