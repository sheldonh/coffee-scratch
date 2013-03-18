{EventEmitter} = require 'events'

class ChatBox
  constructor: (dom_id) ->
    @element = $(dom_id)
    @escaper = $('<div>')

  receive: (data) ->
    switch data.action
      when 'welcome'
        [style, message] = ["notice", "You have connected as #{@mark_up 'identity', data.data}. Use the /nick command to rename."]
      when 'connect'
        [style, message] = ["notice", "#{@mark_up 'identity', data.sender} has connected"]
      when 'disconnect'
        [style, message] = ["notice", "#{@mark_up 'identity', data.sender} has disconnected"]
      when 'identify'
        [style, message] = ["notice", "#{@mark_up 'identity', data.sender} now identifies as #{@mark_up 'identity', data.data}"]
      when 'say'
        [style, message] = ["message", "#{@mark_up 'identity', data.sender}: #{@mark_up 'message', data.data}"]
      when 'error'
        [style, message] = ["error", data.data]
      else
        console.log "discarding unpresentable message", data
        return
    @display style, message

  mark_up: (css, value) -> "<span class='#{css}'>#{@escape value}</span>"

  escape: (unsafe) -> @escaper.text(unsafe).html()

  display: (style, message) ->
    div = $("<div class='#{style}'>#{message}</div>")
    @element.append div
    div.effect 'highlight'
    @element.scrollTop @element[0].scrollHeight

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

class InputBox extends EventEmitter
  constructor: (dom_id) ->
    @element = $(dom_id)
    @element.bind 'keyup', (e) => @keypress_handler e
    @history = new InputHistory()
    @history.on 'select', (s) => @element.val s

    # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
    window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  keypress_handler: (e) ->
    switch e.keyCode
      when 13 then @receive()             # ENTER
      when 38 then @history.scroll_up()   # Up arrow
      when 40 then @history.scroll_down() # Down arrow
      when 27 then @history.cancel()      # Esc

  receive: ->
    text = @element.val()
    if match = text.match /^\/nick\s+(.+)/
      @emit 'nick', match[1]
    else if text.match /^\//
      @emit 'error', "bad command: #{text}"
      return
    else
      @emit 'input', text
    @history.append @element.val()
    @element.val ''

  focus: ->
    @element.focus()
    @

class ChatIdentity extends EventEmitter
  constructor: (dom_id) ->
    @element = $(dom_id)
    @myself = null

  receive: (data) ->
    switch data.action
      when 'welcome'
        @change data.data
        @prefer_identity_from_cookie()
      when 'identify'
        if data.sender is @myself
          @change data.data
          @save_preferred_identity_in_cookie()

  change: (identity) ->
    @myself = identity
    @display()

  display: ->
    @element.html(@myself)
    @element.effect 'highlight'

  prefer_identity_from_cookie: ->
    @emit 'prefer', preferred if preferred = $.cookie 'identity'

  save_preferred_identity_in_cookie: -> $.cookie 'identity', @myself

class ChatIdentityList
  constructor: (dom_id) ->
    @element = $(dom_id)
    @identities = []

  receive: (data) ->
    switch data.action
      when 'members' then @identities = data.data
      when 'connect' then @add data.sender
      when 'disconnect' then @remove data.sender
      when 'identify' then @rename data.sender, data.data
      else
        return
    @display()

  rename: (from, to) ->
    @identities[i] = to if (i = @identities.indexOf from) >= 0

  add: (identity) -> @identities.push identity

  remove: (identity) -> @identities.splice(@identities.indexOf(identity), 1)

  display: ->
    @element.empty()
    @element.append(@mark_up identity) for identity in @identities

  mark_up: (identity) ->
    "<div class='identity'>#{identity}</div>"

socket = io.connect("http://localhost:8000")

$(document).ready ->

  chatbox = new ChatBox('#chat-box')
  identity = new ChatIdentity('#chat-identity')
  identity_list = new ChatIdentityList('#chat-identity-list')
  input = new InputBox('#chat-input')

  view = (data) ->
    component.receive data for component in [chatbox, identity, identity_list]
  socket.on 'data', (data) -> view data
  input.on 'error', (message) -> view {action: 'error', data: message}

  send_packet = (data) -> socket.emit 'data', data
  identity.on 'prefer', (preferred) -> send_packet {action: 'identify', data: preferred}
  input.on 'nick', (new_identity) -> send_packet {action: 'identify', data: new_identity}
  input.on 'input', (text) -> send_packet {action: 'say', data: text}

  send_packet {action: 'members'}
  input.focus()

