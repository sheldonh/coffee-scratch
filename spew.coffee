{EventEmitter} = require 'events'
{Clock} = require './clock/clocks'
net = require 'net'
server = net.createServer()

logger = console

carrier = require 'carrier'

server.on 'listening', ->
  logger.log "Listening on", @address()

class Service extends EventEmitter
  constructor: (@socket, @logger = console) ->
    @carrier = carrier.carry @socket
    @client = @socket.remoteAddress + ":" + @socket.remotePort
    @messages = []
    @clock = new Clock(1000)
    @clock.on 'tick', (=> @socket.write message for message in @messages)

  log: (args...) -> @logger.log "Client", @client, args...

  hush: ->
    @clock.stop()
    @messages = []

  quit: ->
    @hush()
    @socket.end()

  spam: (data) ->
    @messages.push data
    @clock.start()

server.on 'connection', (socket) ->
  socket.setMaxListeners 0
  service = new Service(socket, logger)

  service.carrier.on 'line', (line) ->
    switch line
      when "shutdown"
        service.log "sent shutdown command"
        server.close()
      when "quit"
        service.log "sent quit command"
        service.quit()
      when "stop"
        service.log "sent stop command"
        service.hush()
      else
        service.log "sent", line
        service.spam line + "\r\n"

  socket.on 'close', -> service.log "disconnected"

  socket.on 'error', (error) -> service.log error

  service.log "connected"

server.on 'close', ->
  logger.log "Shutting down"

server.listen 8000
