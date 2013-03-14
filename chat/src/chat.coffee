{EventEmitter} = require 'events'

class Service
  constructor: -> @clients = []

  connect: (client) ->
    @clients.push client
    @announce_client_action client, 'connect'
    client.on 'send', (message) => @on_client_send client, message

  disconnect: (client) ->
    @announce_client_action client, 'disconnect'

  announce_client_action: (client, action) ->
    @assure_message {action: action, sender: client.id}, (assured) => @broadcast assured

  on_client_send: (client, message) ->
    message.sender = client.id
    @assure_message message, (assured) => @broadcast assured

  broadcast: (message, callback) ->
    for client in @clients
      client.receive message unless client.id is message.sender
    callback? message

  assure_message: (message, callback) ->
    message = @canonicalize_message message
    switch message.action
      when 'connect', 'disconnect', 'say' then callback? message
      when 'identify' then callback? message unless @clients.some (c) -> c.id is message.data

  canonicalize_message: (message) ->
    {action: message.action, data: message.data, sender: message.sender}

exports.Service = Service

class Client extends EventEmitter
  constructor: (@id) ->

  send: (message) -> @emit 'send', message

  receive: (message) -> @emit 'receive', message

exports.Client = Client

