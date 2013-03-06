timers = require 'timers'
events = require 'events'

class Clock extends events.EventEmitter
  constructor: (@interval = 1000) ->

  tick: ->
    if @running
      @emit 'tick'
      timers.setTimeout (=> @tick()), @interval

  start: ->
    unless @running
      @emit 'start'
      @running = true
      @tick()

  stop: ->
    if @running
      @running = false
      @emit 'stop'

class LimitedClock extends Clock
  constructor: (@interval = 1000, @limit = -1) ->
    @ticks = 0

  tick: ->
    if @limit < 0 or @ticks < @limit
      super
      @ticks += 1
      if @ticks == @limit
        @stop()

exports.Clock = Clock
exports.LimitedClock = LimitedClock
