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
  client =
    client: socket.remoteAddress + ":" + socket.remotePort
    log: (args...) -> logger.log "Client", @client, args...
    stopped: false

  process_command = (buffer) ->
    switch buffer.toString()
      when "shutdown\n"
        client.log "sent shutdown command"
        server.close()
        true
      when "quit\n"
        client.log "sent quit command"
        client.stopped = true
        socket.end()
        true
      when "stop\n"
        client.log "sent stop command"
        client.stopped = true
        true
      else false

  socket.on 'data', (buffer) ->
    if !process_command buffer
      client.log "sent", buffer
      client.stopped = false
      spew = (data, callback) ->
          unless client.stopped
            socket.write data, null, ->
                socket.setTimeout 1000, -> spew data, spew
      spew buffer, spew

  socket.on 'close', -> client.log "disconnected"

  socket.on 'error', (error) -> client.log error

  client.log "connected"

server.on 'close', ->
  logger.log "Shutting down"

server.listen 8000
