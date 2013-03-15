socket = io.connect("http://localhost:8000")

myself = null

$(document).ready ->

  chatbox = $('#chat-box')

  chatbox.display = (style, message) ->
    div = $("<div class='#{style}'>#{message}</div>")
    @append div
    div.effect 'highlight'
    @scrollTop @[0].scrollHeight

  chatbox.connect = (data) ->
    message = "<span class='sender'>#{@escape data.sender}</sender> has connected"
    @display 'notice', message

  chatbox.disconnect = (data) ->
    message = "<span class='sender'>#{@escape data.sender}</sender> has disconnected"
    @display 'notice', message

  chatbox.identify = (data) ->
    message = "<span class='sender'>#{@escape data.sender}</sender> now identifies as <span class='sender'>#{@escape data.data}</span>"
    @display 'notice', message

  chatbox.say = (data) ->
    message = "<span class='sender'>#{@escape data.sender}</sender>: <span class='message'>#{@escape data.data}</span>"
    @display 'message', message

  chatbox.welcome = (data) ->
    message = "You have connected as <span class='sender'>#{@escape data.data}</sender>. Use the /nick command to rename."
    @display 'notice', message

  chatbox.escape = (unsafe) -> $('<div>').text(unsafe).html()

  socket.on 'data', (data) ->
    if not myself?
      if data.action is 'welcome'
        myself = data.data
        chatbox.welcome data
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
      switch data.action
        when 'connect'
          chatbox.connect data
        when 'disconnect'
          chatbox.disconnect data
        when 'identify'
          if data.sender is myself
            myself = data.data
            $.cookie 'identity', myself
          chatbox.identify data
        when 'say'
          chatbox.say data

