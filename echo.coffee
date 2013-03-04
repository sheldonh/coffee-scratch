net = require 'net'
server = net.createServer()

logger =
  log: (args...) ->
    escape_newlines = (s) ->
      if typeof s is 'string' then s.replace /\n/g, "\\n"
      else s
    console.log (escape_newlines s for s in args)...

server.on 'listening', ->
  logger.log "Listening on", @address()

server.on 'connection', (socket) ->
  client = socket.remoteAddress + ":" + socket.remotePort
  log_client = (args...) -> logger.log "Client", client, args...

  socket.on 'data', (buffer) ->
    switch buffer.toString()
      when "shutdown\n"
        log_client "sent shutdown command"
        server.close()
      when "quit\n"
        log_client "sent quit command"
        socket.end()
      else
        log_client "sent", buffer.toString()

  socket.on 'close', -> log_client "disconnected"

  log_client "connected"
  socket.pipe socket

server.on 'close', ->
  logger.log "Shutting down"

server.listen 8000
