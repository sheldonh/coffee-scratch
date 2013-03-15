socket = io.connect("http://localhost:8000")

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
        return
    @display style, message

  mark_up: (css, value) -> "<span class='#{css}'>#{@escape value}</span>"

  escape: (unsafe) -> @escaper.text(unsafe).html()

  display: (style, message) ->
    div = $("<div class='#{style}'>#{message}</div>")
    @element.append div
    div.effect 'highlight'
    @element.scrollTop @element[0].scrollHeight

#class InputBox extends EventEmitter
#  constructor: (dom_id) -> @element = $(dom_id)

$(document).ready ->

  myself = null
  chatbox = new ChatBox('#chat-box')

  socket.on 'data', (data) ->
    if not myself?
      if data.action is 'welcome'
        myself = data.data
        chatbox.present data
        if preferred = $.cookie 'identity'
          socket.emit 'data', {sender: myself, action: 'identify', data: preferred}
        input = $('#chat-input')
        input.bind 'keyup', (e) ->
          if e.which is 13
            if matched = input.val().match /^\/nick\s+(\S+)/
              socket.emit 'data', {sender: myself, action: 'identify', data: matched[1]}
            else
              socket.emit 'data', {sender: myself, action: 'say', data: input.val()}
            input.val('')
        input.focus()
    else
      if data.action is 'identify' and data.sender is myself
        myself = data.data
        $.cookie 'identity', myself
      chatbox.present data

