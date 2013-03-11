{Clock} = require './clocks'
timers = require 'timers'
assert = require 'assert'

describe 'Clock', ->

  it 'emits "start" as you start it', (done) ->
    clock = new Clock(0)
    clock.on 'start', -> done()
    clock.start()
    clock.stop()

  it 'emits "tick" as you start it', (done) ->
    clock = new Clock(0)
    clock.on 'tick', -> done()
    clock.start()
    clock.stop()

  it 'emits "tick" at the clock interval', (done) ->
    clock = new Clock(0)
    ticks = 0
    clock.on 'tick', ->
      if ++ticks == 3
        done()
    clock.start()

  it 'emits "stop" as you stop it', (done) ->
    clock = new Clock(0)
    clock.on 'stop', -> done()
    clock.start()
    clock.stop()

  it 'stops emitting "tick" when you stop it', (done) ->
    clock = new Clock(0)
    clock.on 'stop', ->
      clock.on 'tick', -> assert false, 'Y U NO STOP TICK?'
      timers.setTimeout (-> done()), 5
    clock.start()
    clock.stop()

  it 'does not emit "start" if already started', ->
    clock = new Clock(0)
    starts = 0
    clock.on 'start', ->
      assert ++starts == 1, 'Y U START TWICE?'
    clock.start()
    clock.start()
    clock.stop()

  it 'does not emit "stop" if already stopped', ->
    clock = new Clock(0)
    stops = 0
    clock.on 'stop', ->
      assert ++stops == 1, 'Y U STOP TWICE?'
    clock.start()
    clock.stop()
    clock.stop()

  # If I weren't still new to nodejs and high on my own stink, I'd delete
  # this test. It doesn't pay for itself.
  it 'defaults to about a 1 second interval', (done) ->
    timer = new StopWatch()
    clock = new Clock()
    timer.start()
    clock.start()
    clock.on 'tick', ->
      timer.stop()
      assert 950 <= timer.milliseconds() <= 1050,
        "#{timer.milliseconds()}ms should be about 1000ms"
      clock.stop()
      done()

class StopWatch
  constructor: (@title) ->

  start: ->
    @started_at = process.hrtime()

  stop: ->
    @stopped_at = process.hrtime()

  hrtime_to_milliseconds: (t) ->
    t[0] * 1000 + Math.floor(t[1] / 1000000)

  milliseconds: ->
    @hrtime_to_milliseconds(@stopped_at) - @hrtime_to_milliseconds(@started_at)

  assert_elapsed: (ms, tolerance) ->
    elapsed = @milliseconds()
    title = @title or 'elapsed'
    assert ms <= elapsed <= ms + tolerance,
      "#{title} #{elapsed}ms should have been #{ms}ms (within #{tolerance}ms tolerance)"

