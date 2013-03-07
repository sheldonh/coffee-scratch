timers = require 'timers'
clocks = require './clock'

run_clock = (c) ->
  c.on 'start', -> console.log "Started the clock"
  c.on 'stop', -> console.log "Stopped the clock"
  c.on 'tick', -> console.log "[tick]"
  c.start()

run_clock new clocks.TickLimiter(new clocks.Clock(1000), 2)

