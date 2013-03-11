{EventEmitter} = require 'events'
net = require 'net'
carrier = require 'carrier'

server = net.createServer()
server.on 'listening', ->
  console.log "Listening on", @address()

class Service extends EventEmitter
  constructor: -> @clients = []

  connect: (client) ->
    @notify "#{client.name} connected"
    @clients.push client
    client.on 'nick', (nick, previous) => @notify "#{previous} renamed to #{nick}", client
    client.on 'line', (line) => @send line, client
    client.on 'disconnect', => @disconnect client

  disconnect: (client) ->
    client.removeAllListeners 'disconnect'
    client.removeAllListeners 'line'
    client.removeAllListeners 'nick'
    @clients = @clients.filter (c) -> c isnt client
    @notify "#{client.name} disconnected"

  broadcast: (prefix, message, excluded_client) ->
    for client in @clients
      client.send "#{prefix} #{message}" unless client is excluded_client

  send: (message, sender) ->
    @broadcast "#{sender.name}:", message, sender

  notify: (message, excluded_client) ->
    @broadcast '>>>', message, excluded_client

service = new Service()

class Client extends EventEmitter
  constructor: (@socket) ->
    @carrier = carrier.carry(socket)
    @name = "#{socket.remoteAddress}:#{socket.remotePort}"

    @carrier.on 'line', (line) => @receive line
    @socket.on 'close', => @disconnect()

  receive: (line) ->
    if line == '.quit'
      @disconnect()
    else if (nick_command = /^.nick\s+(\S+)$/.exec line)?
      @nick nick_command[1]
    else
      @emit 'line', line

  nick: (name) ->
    @emit 'nick', name, @name
    @name = name

  send: (message) ->
    @socket.write "#{message}\r\n"

  disconnect: ->
    @emit 'disconnect'
    @socket.removeListener 'close', => @disconnect()
    @socket.end()

server.on 'connection', (socket) ->
  service.connect new Client(socket)

server.listen 8000
