socket = io.connect("http://localhost:8000")

myself = 'william'

socket.on 'data', (data) ->
  console.log 'server sent', data
  if data.sender?
    message = "<span class='sender'>#{data.sender}</sender> <span class='action'>#{data.action}</span> <span class='data'>#{data.data}</span>"
    $('#chat').prepend "<div class='message'>#{message}</div>"

socket.emit 'data', {sender: myself, action: 'identifies as', data: 'william'}

$(document).ready ->
  input = $('#chat-input')
  input.bind 'keyup', (e) ->
    if e.which is 13
      socket.emit 'data', {sender: myself, action: 'says', data: input.val()}
      input.val('')
  input.focus()

