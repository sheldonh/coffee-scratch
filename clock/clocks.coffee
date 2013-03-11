Timers = require 'timers'
{EventEmitter} = require 'events'

# To really explore the evented nature of nodejs, let's try to build a clock
# using only Timers.setTimeout(). Otherwise, we just end up using
# Timers.setInterval().
#

class Clock extends EventEmitter
  constructor: (@interval = 1000) ->

  tick: ->
    if @running
      @emit 'tick'
      Timers.setTimeout (=> @tick()), @interval

  start: ->
    unless @running
      @emit 'start'
      @running = true
      @tick()

  stop: ->
    if @running
      @running = false
      @emit 'stop'

exports.Clock = Clock

# If you wanted extend such a clock to automatically stop after a limited number
# of ticks, you could do this.
#
class LimitedClock extends Clock
  constructor: (@interval = 1000, @limit = -1) ->
    @ticks = 0

  tick: ->
    if super
      @ticks += 1
      @stop() if @ticks == @limit

exports.LimitedClock = LimitedClock

# But composition would let you limit any kind of clock without having to
# choose your implementation at compile time. So...
#
class TickLimiter extends EventEmitter
  constructor: (@clock, @limit = -1) ->
    @ticks = 0
    @propagate_events @clock, 'start', 'stop', 'tick'
    @clock.on 'tick', => @use_up_a_tick()

  use_up_a_tick: ->
    @ticks += 1
    @clock.stop() if @ticks == @limit

  start: -> @clock.start()

  stop: -> @clock.stop()

  propagate_events: (origin, events...) ->
    for event in events
      do (event) => origin.on event, (args...) => @emit event, args...

exports.TickLimiter = TickLimiter

