timers = require 'timers'
events = require 'events'

# This is what an event-emitting clock might look like if you used
# Timers.setInterval().
#
class NativeClock extends events.EventEmitter
  constructor: (@interval = 1000) ->

  tick: ->
    @emit 'tick'

  start: ->
    unless @timer
      @emit 'start'
      @tick()
      @timer = timers.setInterval (=> @tick()), @interval

  stop: ->
    if @timer
      timers.clearInterval(@timer)
      @timer = null
      @emit 'stop'

exports.NativeClock = NativeClock

# But to really demonstrate the evented nature of nodejs, let's try it with
# only Timers.setTimeout().
#
class Clock extends events.EventEmitter
  constructor: (@interval = 1000) ->

  tick: ->
    if @running
      @emit 'tick'
      timers.setTimeout (=> @tick()), @interval

  start: ->
    unless @running
      @running = true
      @emit 'start'
      @tick()

  stop: ->
    if @running
      @running = false
      @emit 'stop'

exports.Clock = Clock

# If you wanted extend such a clock to automatically stop after a limited number
# of ticks, you could do this.
#
class LimitedClock extends NativeClock
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
class TickLimiter extends events.EventEmitter
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
