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
  socket.log = (args...) -> logger.log "Client", client, args...
  socket.stopped = false

  socket.on 'data', (buffer) ->
    switch buffer.toString()
      when "shutdown\n"
        socket.log "sent shutdown command"
        server.close()
      when "quit\n"
        socket.log "sent quit command"
        socket.stopped = true
        socket.end()
      when "stop\n"
        socket.log "sent stop command"
        socket.stopped = true
      else
        socket.log "sent", buffer
        spew = (data, callback) ->
            unless socket.stopped
              socket.write data, null, ->
                  socket.setTimeout 1000, -> spew data, spew
        spew buffer, spew
        socket.stopped = false

  socket.on 'close', -> socket.log "disconnected"

  socket.on 'error', (error) -> socket.log error

  socket.log "connected"

server.on 'close', ->
  logger.log "Shutting down"

server.listen 8000
