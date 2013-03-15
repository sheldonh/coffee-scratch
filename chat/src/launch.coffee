socket = io.connect("http://localhost:8000")

myself = null

$(document).ready ->

  chatbox = $('#chat-box')

  chatbox.display = (style, message) ->
    div = $("<div class='#{style}'>#{message}</div>")
    @prepend div
    div.effect 'highlight'

  chatbox.identify = (data) ->
    message = "<span class='sender'>#{data.sender}</sender> now identifies as <span class='data'>#{data.data}</span>"
    @display 'notice', message

  chatbox.say = (data) ->
    message = "<span class='sender'>#{data.sender}</sender>: <span class='data'>#{data.data}</span>"
    @display 'message', message

  socket.on 'data', (data) ->
    if not myself?
      if data.action is 'welcome'
        myself = data.data
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
        when 'identify'
          if data.sender is myself
            myself = data.data
            $.cookie 'identity', myself
          chatbox.identify data
        when 'say'
          chatbox.say data

