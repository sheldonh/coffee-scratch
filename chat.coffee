{EventEmitter} = require 'events'

class Service
  constructor: -> @clients = []

  connect: (client) ->
    @clients.push client
    @announce_client_connect client
    client.on 'send', (message) => @on_client_send client, message

  announce_client_connect: (client) ->
    @assure_message {action: 'connect', data: client.id}, (assured) => @broadcast assured

  on_client_send: (client, message) ->
    message.sender = client.id
    @assure_message message, (assured) => @broadcast assured

  broadcast: (message, callback) ->
    for client in @clients
      client.receive message unless client.id is message.sender
    callback? message

  assure_message: (message, callback) ->
    if message.action is 'say' or message.action is 'connect'
      callback? {action: message.action, data: message.data, sender: message.sender}

exports.Service = Service

class Client extends EventEmitter
  constructor: (@id) ->

  send: (message) -> @emit 'send', message

  receive: (message) -> @emit 'receive', message

exports.Client = Client

