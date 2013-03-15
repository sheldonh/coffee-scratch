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

class Service
  constructor: ->
    @guest_counter = 0
    @identities = {}

  connect: (id, callback) ->
    identity = "guest#{++@guest_counter}"
    @identities[identity] = id
    callback identity

  disconnect: (id, callback) ->
    for candidate of @identities
      if @identities[candidate] is id
        delete @identities[candidate]
        callback candidate

  receive: (id, data, callback) ->
    if @assure_data id, data
      switch data.action
        when 'identify'
          unless @identities[data.data]?
            @identities[data.data] = id
            delete @identities[data.sender]
            callback data
        when 'say'
          callback data

  assure_data: (id, data) -> id is @identities[data.sender]

service = new Service()

io.sockets.on 'connection', (socket) ->
  service.connect socket.id, (initial_identity) ->
    socket.emit 'data', {action: 'welcome', data: initial_identity}
    socket.broadcast.emit 'data', {sender: initial_identity, action: 'connect'}

  socket.on 'data', (data) -> service.receive socket.id, data, (accepted) -> io.sockets.emit 'data', accepted

  socket.on 'disconnect', -> service.disconnect socket.id, (parting_identity) ->
    io.sockets.emit 'data', {sender: parting_identity, action: 'disconnect'}

web_server.listen(8000)
