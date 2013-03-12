Chat = require './chat'
assert = require('assert')

# TODO most of these tests need to call done() to prove that we actually
# got the event we use to make assertions.

describe 'Chat.Service', ->

  service = sender = receiver = null

  beforeEach ->
    service = new Chat.Service()
    service.connect (sender = new Chat.Client("bill"))
    service.connect (receiver = new Chat.Client("ted"))

  it 'broadcasts a message from one client to all clients', ->
    receiver.on 'receive', (received) -> assert received.action is 'say' and received.data is 'Hi!'
    sender.send {action: 'say', data: 'Hi!'}

  it 'brands the sender id into broadcast messages', ->
    receiver.on 'receive', (received) -> assert received.sender is sender.id
    sender.send {action: 'say', data: 'Hi!', sender: 'liar'}

  it 'rejects unknown actions from broadcast messages', ->
    receiver.on 'receive', (received) -> assert received.action isnt 'illegal'
    sender.send {action: 'illegal', data: 'data'}

  it 'excludes sender from broadcast', ->
    sender.on 'receive', -> assert null, 'sender received own message'
    sender.send {action: 'say', data: 'Hi!'}

  it 'accounces new clients connecting', ->
    new_client = new Chat.Client('bundy')
    receiver.on 'receive', (received) -> assert.equal received.sender, new_client.id
    service.connect new_client

  it 'does not send the connection announcement to the connecting client', ->
    new_client = new Chat.Client('bundy')
    new_client.on 'receive', -> assert null, 'announcement sent to connecting client'
    service.connect new_client

  it 'announces clients disconnecting', ->
    receiver.on 'receive', (received) -> assert.equal received.sender, sender.id
    service.disconnect sender
