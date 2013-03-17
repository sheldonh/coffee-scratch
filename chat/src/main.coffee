fs = require 'fs'

web_request_handler = (req, res) ->
  url = if req.url is '/' then '/index.html' else req.url
  # Directory traversal vulnerability
  fs.readFile "#{__dirname}/../#{url}", (error, data) ->
    if not error
      res.writeHead(200, {'Content-Type': 'text/html'})
      res.end data
    else
      res.writeHead 404
      res.end "Object not found: #{url}"

web_server = require('http').createServer web_request_handler
io = require('socket.io').listen web_server, {log: false}

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

  receive: (id, data, reply, broadcast) ->
    data = {sender: @sender_identity(id), action: data.action, data: data.data}
    switch data.action
      when 'identify'
        unless @identities[data.data]?
          @identities[data.data] = id
          delete @identities[data.sender]
          broadcast data
      when 'say'
        broadcast data
      when 'members'
        reply {action: 'members', data: Object.keys @identities}

  sender_identity: (id) ->
    (x for x of @identities when @identities[x] is id)[0]

service = new Service()

io.sockets.on 'connection', (socket) ->
  service.connect socket.id, (initial_identity) ->
    socket.emit 'data', {action: 'welcome', data: initial_identity}
    socket.broadcast.emit 'data', {sender: initial_identity, action: 'connect'}

  socket.on 'data', (data) ->
    broadcast = (accepted) -> io.sockets.emit 'data', accepted
    reply = (response) -> socket.emit 'data', response
    service.receive socket.id, data, reply, broadcast

  socket.on 'disconnect', -> service.disconnect socket.id, (parting_identity) ->
    io.sockets.emit 'data', {sender: parting_identity, action: 'disconnect'}

web_server.listen(8000)
