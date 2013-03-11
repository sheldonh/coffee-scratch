{EventEmitter} = require 'events'
net = require 'net'
carrier = require 'carrier'

server = net.createServer()
server.on 'listening', ->
  console.log "Listening on", @address()

class Service extends EventEmitter
  constructor: -> @clients = []

  connect: (client) ->
    @write "#{client.address} connected"
    @clients.push client

    client.carrier.on 'line', (line) =>
      switch line
        when ".quit"
          @disconnect client
        else
          @write line, client

  disconnect: (client) ->
    @clients = @clients.filter (c) -> c isnt client
    client.socket.end()
    @write "#{client.address} disconnected"

  write: (message, sender = null) ->
    for client in @clients
      client.socket.write "#{message}\r\n" unless sender is client

service = new Service()

server.on 'connection', (socket) ->
  address = "#{socket.remoteAddress}:#{socket.remotePort}"
  client = {carrier: carrier.carry(socket), socket: socket, address: address}
  service.connect client

server.listen 8000
