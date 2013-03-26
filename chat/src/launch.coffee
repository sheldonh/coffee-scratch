# Requires that the HTML document include these libraries:
#
#   Requires: knockout
#   Optional: jquery + jquery-ui (for highlight effect)

store = require 'store'

document.addEventListener 'DOMContentLoaded', ->

  # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
  window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  socket = io.connect("http://localhost:8000")
  sendPacket = (data) -> socket.emit 'data', data

  viewModel =
    identity: ko.observable()
    members: ko.observableArray()
    messages: ko.observableArray()
    messageAdded: (element, index, data) ->
      element.parentNode.scrollTop = element.parentNode.scrollHeight
      try $(element).effect 'highlight'
    input: ko.observable()
    isInputBoxSelected: ko.observable(true)
    inputSubmitted: (form) -> ko.postbox.publish 'viewModel.inputSubmitted', text if text = @input()?.trim()
    inputKeyUp: (data, event) -> ko.postbox.publish 'viewModel.inputKeyUp', event.keyCode
  ko.applyBindings viewModel

  # Just for debugging in browser's JS console
  global.viewModel = viewModel

  userInputProtocol = ->
    inputHistory =
      elements: ko.observableArray()
      idx: ko.observable(1)
      push: (text) -> @elements.push text; @escape()
      up: -> @idx @idx() - 1 unless @idx() is 0
      down: -> @idx @idx() + 1 unless @idx() is @elements().length
      escape: -> @idx @elements().length
      currentSelection: -> if @idx() < @elements().length then @elements()[@idx()] else ''
    inputHistory.selected = ko.computed -> inputHistory.currentSelection()

    inputHistory.selected.subscribe (text) -> viewModel.input text
    ko.postbox.subscribe 'viewModel.inputSubmitted', (text) -> inputHistory.push text
    ko.postbox.subscribe 'viewModel.inputKeyUp', (keyCode) ->
      switch keyCode
        when 27 then inputHistory.escape()
        when 38 then inputHistory.up()
        when 40 then inputHistory.down()

    # This inputSubmitted subscription annoys me. It straddles user input
    # protocol and server messaging protocol. I think the sendPacket() calls
    # need to move out into serverMessagingProtocol(), and occur in response
    # to events triggered here.

    ko.postbox.subscribe 'viewModel.inputSubmitted', (text) ->
      if match = text.match /^\/nick\s+(.+)/
        sendPacket {action: 'identify', data: match[1]}
      else if text.match /^\//
        viewModel.messages.push {action: 'error', data: "Bad command: #{text}"}
      else
        sendPacket {action: 'say', data: text}
  userInputProtocol()

  serverMessagingProtocol = ->
    socket.on 'data', (data) ->
      # identity widget
      switch data.action
        when 'welcome'
          viewModel.identity data.data
          sendPacket {action: 'identify', data: preferred} if preferred = store.get 'identity'
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
        when 'welcome' then sendPacket {action: 'members'}
        when 'members' then viewModel.members(data.data)
        when 'connect' then viewModel.members.push data.sender
        when 'disconnect' then viewModel.members.remove data.sender
        when 'identify'
          if (i = viewModel.members.indexOf data.sender) >= 0
            viewModel.members.splice i, 1, data.data
  serverMessagingProtocol()

