fs = require 'fs'

web_request_handler = (req, res) ->
  url = if req.url is '/' then '/index.html' else req.url
  # Directory traversal vulnerability
  fs.readFile "#{__dirname}/../#{url}", (error, data) ->
    if not error
      res.writeHead(200)
      res.end data
    else
      res.writeHead 500
      console.log "error reading", url, error
      res.end "error reading #{url}"

web_server = require('http').createServer web_request_handler
io = require('socket.io').listen web_server

io.sockets.on 'connection', (socket) ->
  console.log 'client', socket.id, 'connected'
  socket.emit 'data', {action: 'welcome', sender: null, data: {id: socket.id}}
  socket.on 'data', (data) ->
    console.log 'client', socket.id, 'sent', data
    socket.emit 'data', {action: data.action, sender: data.sender, data: data.data}

web_server.listen(8000)
