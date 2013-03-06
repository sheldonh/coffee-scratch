net = require 'net'
server = net.createServer()

logger = console

carrier = require 'carrier'

server.on 'listening', ->
  logger.log "Listening on", @address()

server.on 'connection', (socket) ->
  socket.setMaxListeners 0
  client =
    socket: socket
    carrier: carrier.carry socket
    client: socket.remoteAddress + ":" + socket.remotePort
    log: (args...) -> logger.log "Client", @client, args...
    hushed: false
    hush: -> @hushed = true
    spew: (data) ->
      @socket.setTimeout 1000, =>
        unless @hushed
          @socket.write data, null, => @spew data
    spam: (data) ->
      @hushed = false
      @spew data
    quit: ->
      @hushed = true
      @socket.end()

  client.carrier.on 'line', (line) ->
    switch line
      when "shutdown"
        client.log "sent shutdown command"
        server.close()
      when "quit"
        client.log "sent quit command"
        client.quit()
      when "stop"
        client.log "sent stop command"
        client.hush()
      else
        client.log "sent", line
        client.spam line + "\r\n"

  socket.on 'close', -> client.log "disconnected"

  socket.on 'error', (error) -> client.log error

  client.log "connected"

server.on 'close', ->
  logger.log "Shutting down"

server.listen 8000
