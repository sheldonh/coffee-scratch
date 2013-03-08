Clocks = require './clocks'

clock = new Clocks.Clock(1000)
clock.on 'start', -> console.log "Started the clock"
clock.on 'stop', -> console.log "Stopped the clock"
clock.on 'tick', -> console.log "[tick]"
clock.start()

process.stdin.resume()
terminate = ->
  clock.stop()
  process.stdin.destroy()
process.stdin.on 'data', terminate
process.stdin.on 'end', terminate
