timers = require 'timers'
clocks = require './clock'

clock = new clocks.LimitedClock(1000, 2)
clock.on 'start', -> console.log "Started the clock"
clock.on 'stop', -> console.log "Stopped the clock"
clock.on 'tick', -> console.log "[tick]"
clock.start()

timers.setTimeout (-> clock.stop()), 5000
