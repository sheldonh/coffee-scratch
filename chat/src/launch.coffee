{EventEmitter} = require 'events'

socket = io.connect("http://localhost:8000")
send_packet = (data) -> socket.emit 'data', data

class ChatBox
  constructor: (dom_id) ->
    @element = $(dom_id)
    @escaper = $('<div>')

  present: (data) ->
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
    @element.bind 'keyup', (e) =>
      if e.which is 13
        if matched = @element.val().match /^\/nick\s+(\S+)/
          @emit 'nick', {identity: matched[1]}
        else
          @emit 'input', {message: @element.val()}
        @element.val('')

  focus: ->
    @element.focus()
    @

class ChatIdentity extends EventEmitter
  constructor: (dom_id) ->
    @element = $(dom_id)
    @identity = null

  accept: (identity, callback) ->
    @set identity
    @emit 'prefer', preferred if preferred = $.cookie 'identity'

  prefer: (identity) ->
    @set identity
    $.cookie 'identity', @identity

  set: (identity) ->
    @element.html(@identity = identity)
    @element.effect 'highlight'

  myself: -> @identity

$(document).ready ->

  identity = new ChatIdentity('#chat-identity')
  identity.on 'prefer', (preferred) -> send_packet {action: 'identify', data: preferred}

  chatbox = new ChatBox('#chat-box')

  input = new InputBox('#chat-input')
  input.on 'nick', (data) -> send_packet {action: 'identify', data: data.identity}
  input.on 'input', (data) -> send_packet {action: 'say', data: data.message}
  input.focus()

  socket.on 'data', (data) ->
    switch data.action
      when 'welcome'
        identity.accept data.data
        send_packet {action: 'members'}
      when 'identify'
        if data.action is 'identify' and data.sender is identity.myself()
          identity.prefer data.data
      when 'members'
        container = $('#chat-members')
        container.empty()
        container.append("<div class='identity'>#{member}</div>") for member in data.data when member isnt identity.myself()
    chatbox.present data

