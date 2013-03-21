# Requires that the HTML document include these libraries:
#
#   Requires: jquery, knockout
#   Optional: jquery-ui (w/ highlight effect)

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
    inputEvents: ko.observable()
    receiveInput: -> @input()? and @inputEvents @input().trim(); false
    keyUpEvents: ko.observable()
    inputKeyUp: (data, event) -> @keyUpEvents event.keyCode; @keyUpEvents null
  ko.applyBindings viewModel

  inputHistory =
    elements: ko.observableArray()
    idx: ko.observable(1)
    push: (text) ->
      @elements.push text
      @escape()
    up: ->
      @idx @idx() - 1 unless @idx() is 0
    down: ->
      if @idx() is @elements().length - 1
        @escape()
      else
        @idx @idx() + 1 unless @idx() is @elements().length
    escape: ->
      @idx @elements().length
    selected: -> @elements()[@idx()] if @idx() < @elements().length
  inputHistory.selectEvents = ko.computed -> inputHistory.selected()

  viewModel.inputEvents.subscribe (text) -> inputHistory.push text
  viewModel.keyUpEvents.subscribe (keyCode) ->
    switch keyCode
      when 27 then inputHistory.escape()
      when 38 then inputHistory.up()
      when 40 then inputHistory.down()
  inputHistory.selectEvents.subscribe (text) -> viewModel.input text

  viewModel.inputEvents.subscribe (text) ->
    if match = text.match /^\/nick\s+(.+)/
      send_packet {action: 'identify', data: match[1]}
    else if text.match /^\//
      viewModel.messages.push {action: 'error', data: "Bad command: #{text}"}
    else if text.length > 0
      send_packet {action: 'say', data: text}

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
      viewModel.messages.push {sender: data.sender, action: data.action, data: data.data}

    # identity list widget
    switch data.action
      when 'welcome' then send_packet {action: 'members'}
      when 'members' then viewModel.members(data.data)
      when 'connect' then viewModel.members.push data.sender
      when 'disconnect' then viewModel.members.remove data.sender
      when 'identify'
        if (i = viewModel.members.indexOf data.sender) >= 0
          viewModel.members.splice i, 1, data.data

