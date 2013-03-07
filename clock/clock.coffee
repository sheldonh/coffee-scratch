timers = require 'timers'
events = require 'events'

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

class LimitedClock extends NativeClock
  constructor: (@interval = 1000, @limit = -1) ->
    @ticks = 0

  tick: ->
    if super
      @ticks += 1
      @stop() if @ticks == @limit

exports.LimitedClock = LimitedClock

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
