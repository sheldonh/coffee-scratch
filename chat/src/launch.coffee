{EventEmitter} = require 'events'

socket = io.connect("http://localhost:8000")
send_packet = (data) -> socket.emit 'data', data

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

class InputBox extends EventEmitter
  constructor: (dom_id) ->
    @element = $(dom_id)
    @element.bind 'keyup', (e) => @receive() if e.which is 13

  receive: ->
    text = @element.val()
    if match = text.match /^\/nick\s+(.+)/
      @emit 'nick', match[1]
    else if text.match /^\//
      @emit 'error', "bad command: #{text}"
    else
      @emit 'input', text
    @element.val('')

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
          @save_preferred_identity_in_cookie

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
    @myself = null

  receive: (data) ->
    switch data.action
      when 'welcome' then @myself = data.data
      when 'members' then @identities = data.data
      when 'connect' then @add data.sender
      when 'disconnect' then @remove data.sender
      when 'identify'
        if data.sender is @myself
          @myself = data.data
        @rename data.sender, data.data
      else
        return
    @display()

  rename: (from, to) ->
    @identities[i] = to if (i = @identities.indexOf from) >= 0

  add: (identity) -> @identities.push identity

  remove: (identity) -> @identities.splice(@identities.indexOf(identity), 1)

  display: ->
    @element.empty()
    @element.append(@mark_up identity) for identity in @identities when identity isnt @myself

  mark_up: (identity) ->
    "<div class='identity'>#{identity}</div>"

$(document).ready ->

  identity_list = new ChatIdentityList('#chat-identity-list')

  identity = new ChatIdentity('#chat-identity')
  identity.on 'prefer', (preferred) -> send_packet {action: 'identify', data: preferred}

  chatbox = new ChatBox('#chat-box')

  view = (data) ->
    component.receive data for component in [chatbox, identity, identity_list]

  socket.on 'data', (data) ->
    console.log 'received', data
    view data

  input = new InputBox('#chat-input')
  input.on 'input', (text) -> send_packet {action: 'say', data: text}
  input.on 'nick', (new_identity) -> send_packet {action: 'identify', data: new_identity}
  input.on 'error', (message) -> view {action: 'error', data: message}
  input.focus()

  send_packet {action: 'members'}
