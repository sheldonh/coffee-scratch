fs = require 'fs'

web_request_handler = (req, res) ->
  url = if req.url is '/' then '/index.html' else req.url
  # Directory traversal vulnerability
  fs.readFile "#{__dirname}/../#{url}", (error, data) ->
    if not error
      res.writeHead(200)
      res.end data
    else
      res.writeHead 500
      console.log "error reading", url, error
      res.end "error reading #{url}"

web_server = require('http').createServer web_request_handler
io = require('socket.io').listen web_server

guest_counter = 0
identities = {}

io.sockets.on 'connection', (socket) ->
  initial_identity = "guest#{++guest_counter}"

  console.log socket.id, 'connected with initial identity', initial_identity
  identities[initial_identity] = socket.id
  socket.emit 'data', {action: 'welcome', data: initial_identity}

  socket.on 'data', (data) ->
    if socket.id isnt identities[data.sender]
      console.log socket.id, "attempted to masquerade as", data.sender
    else
      switch data.action
        when 'identify'
          unless identities[data.data]?
            identities[data.data] = socket.id
            delete identities[data.sender]
            io.sockets.emit 'data', {action: data.action, sender: data.sender, data: data.data}
          console.log "identities:", identities
        when 'say'
          io.sockets.emit 'data', {action: data.action, sender: data.sender, data: data.data}

  socket.on 'disconnect', ->
    console.log socket.id, 'disconnected'
    for identity of identities
      delete identities[identity] if identities[identity] is socket.id

web_server.listen(8000)
