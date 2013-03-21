# Requires that the HTML document include these libraries:
#
#   Requires: jquery, knockout
#   Optional: jquery-ui (w/ highlight effect)

{EventEmitter} = require 'events'
store = require 'store'

$(document).ready ->

  # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
  window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  socket = io.connect("http://localhost:8000")
  send_packet = (data) -> socket.emit 'data', data

  viewModel =
    identity: ko.observable()
    members: ko.observableArray()
    messages: ko.observableArray()
    highlightEffect: (element, index, data) -> try $(element).effect 'highlight'
    input: ko.observable()
    isInputSelected: ko.observable(true)
    receiveInput: ->
      text = @input().trim()
      if match = text.match /^\/nick\s+(.+)/
        send_packet {action: 'identify', data: match[1]}
      else if text.match /^\//
        @messages.push ko.observable {action: 'error', data: "bad command: #{text}"}
      else if text.length > 0
        send_packet {action: 'say', data: text}
      @inputHistory.push @input()
      @escapeInputHistory()
    inputHistory: []
    inputHistoryIndex: 1
    inputKeyUp: (data, event) ->
      switch event.keyCode
        when 27 # Esc
          @escapeInputHistory()
        when 38 # Up arrow
          @input @inputHistory[--@inputHistoryIndex] unless @inputHistoryIndex is 0
        when 40 # Down arrow
          if @inputHistoryIndex is @inputHistory.length - 1
            @escapeInputHistory()
          else
            @input @inputHistory[++@inputHistoryIndex] unless @inputHistoryIndex is @inputHistory.length
    escapeInputHistory: ->
      @inputHistoryIndex = @inputHistory.length
      @input ''
  ko.applyBindings viewModel

  socket.on 'data', (data) ->
    # identity widget
    switch data.action
      when 'welcome'
        viewModel.identity data.data
        send_packet {action: 'identify', data: preferred} if preferred = store.get 'identity'
      when 'identify'
        if data.sender is viewModel.identity()
          viewModel.identity data.data
          store.set 'identity', viewModel.identity()

    # chatbox widget
    if ['welcome', 'connect', 'disconnect', 'identify', 'say', 'error'].indexOf(data.action) >= 0
      viewModel.messages.shift() if viewModel.messages().length >= 1000
      viewModel.messages.push data

    # identity list widget
    switch data.action
      when 'welcome' then send_packet {action: 'members'}
      when 'members' then viewModel.members(data.data)
      when 'connect' then viewModel.members.push data.sender
      when 'disconnect' then viewModel.members.remove data.sender
      when 'identify'
        if (i = viewModel.members.indexOf data.sender) >= 0
          viewModel.members.splice i, 1, data.data

