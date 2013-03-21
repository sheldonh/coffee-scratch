# Requires that the HTML document include these libraries:
#
#   Requires: jquery, knockout
#   Optional: jquery-ui (w/ highlight effect)

{EventEmitter} = require 'events'
store = require 'store'

class ViewModel extends EventEmitter
  constructor: (properties) ->
    @[p] = properties[p] for p of properties

$(document).ready ->

  # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
  window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  socket = io.connect("http://localhost:8000")
  send_packet = (data) -> socket.emit 'data', data

  viewModelDefinition =
    identity: ko.observable()
    members: ko.observableArray()
    messages: ko.observableArray()
    highlightEffect: (element, index, data) -> try $(element).effect 'highlight'
    input: ko.observable()
    isInputSelected: ko.observable(true)
    receiveInput: -> @emit 'input', @input().trim(); false
    inputKeyUp: (data, event) ->
      switch event.keyCode
        when 27 then @emit 'key:esc'
        when 38 then @emit 'key:uparrow'
        when 40 then @emit 'key:downarrow'
  viewModel = new ViewModel viewModelDefinition
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
  inputHistory.selected = ko.computed ->
    if inputHistory.idx() < inputHistory.elements().length
      inputHistory.elements()[inputHistory.idx()]

  viewModel.on 'input', (text) -> inputHistory.push text
  viewModel.on 'key:esc', -> inputHistory.escape()
  viewModel.on 'key:uparrow', -> inputHistory.up()
  viewModel.on 'key:downarrow', -> inputHistory.down()
  inputHistory.selected.subscribe (text) -> viewModel.input text

  viewModel.on 'input', (text) ->
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

