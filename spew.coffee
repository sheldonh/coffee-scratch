net = require 'net'
server = net.createServer()

logger = console

server.on 'listening', ->
  logger.log "Listening on", @address()

server.on 'connection', (socket) ->
  client =
    socket: socket
    client: socket.remoteAddress + ":" + socket.remotePort
    log: (args...) -> logger.log "Client", @client, args...
    hushed: false
    hush: -> @hushed = true
    spew: (data) ->
      unless @hushed
        socket.write data, null, =>
          socket.setTimeout 1000, => @spew data
    spam: (data) ->
      @hushed = false
      @spew data
    quit: ->
      @hushed = true
      @socket.end()

  command_from_buffer = (b) -> b.toString().replace(/\r?\n$/, '')

  socket.on 'data', (buffer) ->
    switch command_from_buffer buffer
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
        client.log "sent", buffer
        client.spam buffer

  socket.on 'close', -> client.log "disconnected"

  socket.on 'error', (error) -> client.log error

  client.log "connected"

server.on 'close', ->
  logger.log "Shutting down"

server.listen 8000
