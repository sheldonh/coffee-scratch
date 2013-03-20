# Requires that the HTML document include these libraries:
#
#   Requires: jquery, knockout
#   Optional: jquery-ui (w/ highlight effect)

{EventEmitter} = require 'events'
store = require 'store'

class ChatBox
  constructor: (@vm, @scrollback = 1000) ->

  receive: (data) ->
    if ['welcome', 'connect', 'disconnect', 'identify', 'say', 'error'].indexOf(data.action) >= 0
      @vm.messages.shift() if @vm.messages().length >= @scrollback
      @vm.messages.push ko.observable data

class InputHistory extends EventEmitter
  constructor: ->
    @history = []
    @at_history = null

  append: (input) ->
    @history.push input
    @at_history = null

  scroll_up: ->
    if @history.length > 0 and @at_history != 0
      @at_history ?= @history.length
      @at_history -= 1
      @emit 'select', @history[@at_history]

  scroll_down: ->
    if @at_history? and @at_history < @history.length - 1
      @at_history ?= -1
      @at_history += 1
      @emit 'select', @history[@at_history]
    else
      @cancel()

  cancel: ->
    @at_history = null
    @emit 'select', ''

# I think it might work quite nicely to split this into InputEditor (keypress_handler)
# and InputProcesser (receive).
class InputBox extends EventEmitter
  constructor: (@vm) ->
    # Meh. Only doing this so VM dependencies all point in one (possibly wrong) direction.
    @vm.registeredInputHistoryKeysHandler = (data, event) => @keypress_handler data, event
    @history = new InputHistory()
    @history.on 'select', (s) => vm.input s

  keypress_handler: (data, event) =>
    switch event.keyCode
      when 13 then @receive()             # ENTER
      when 38 then @history.scroll_up()   # Up arrow
      when 40 then @history.scroll_down() # Down arrow
      when 27 then @history.cancel()      # Esc

  receive: =>
    text = @vm.input().trim()
    if match = text.match /^\/nick\s+(.+)/
      @emit 'nick', match[1]
    else if text.match /^\//
      @emit 'error', "bad command: #{text}"
      return
    else if text.length > 0
      @emit 'input', text
    @history.append text
    @vm.input ''

class ChatIdentity extends EventEmitter
  constructor: (@vm) ->

  receive: (data) ->
    {sender, action, data: identity} = data
    switch action
      when 'welcome'
        @vm.identity identity
        @emit 'preference', preferred if preferred = store.get 'identity'
      when 'identify'
        if sender is @vm.identity()
          @vm.identity identity
          store.set 'identity', @vm.identity()

class ChatIdentityList extends EventEmitter
  constructor: (@vm) ->

  receive: (data) ->
    switch data.action
      when 'welcome' then @emit 'refresh'
      when 'members' then @vm.members data.data
      when 'connect' then @vm.members.push identity
      when 'disconnect' then @vm.members.remove identity
      when 'identify'
        if (i = @vm.members.indexOf data.sender) >= 0
          @vm.members.splice i, 1, data.data

$(document).ready ->

  # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
  window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  socket = io.connect("http://localhost:8000")

  viewModel =
    identity: ko.observable()
    members: ko.observableArray()
    messages: ko.observableArray()
    input: ko.observable()
    isInputSelected: ko.observable(true)
    inputHistoryKeys: (data, event) -> @registeredInputHistoryKeysHandler(data, event)
    registeredInputHistoryKeysHandler: (data, event) ->
      console.log "input box is supposed to register a key handler"; true
    highlightEffect: (element, index, data) -> try $(element).effect 'highlight'

  ko.applyBindings viewModel

  chatbox = new ChatBox(viewModel)
  identity = new ChatIdentity(viewModel)
  identity_list = new ChatIdentityList(viewModel)
  input = new InputBox(viewModel)

  view = (data) ->
    component.receive data for component in [chatbox, identity, identity_list]
  socket.on 'data', (data) -> view data
  input.on 'error', (message) -> view {action: 'error', data: message}

  send_packet = (data) -> socket.emit 'data', data
  identity_list.on 'refresh', -> send_packet {action: 'members'}
  identity.on 'preference', (preferred) -> send_packet {action: 'identify', data: preferred}
  input.on 'nick', (new_identity) -> send_packet {action: 'identify', data: new_identity}
  input.on 'input', (text) -> send_packet {action: 'say', data: text}

