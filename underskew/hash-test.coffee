class Hash
  constructor: -> @h = {}

  get: (k) -> @h[@key k]

  set: (k, v) -> @h[@key k] = v

  keys: ->
    Object.keys(@h).map (o) ->
      switch o
        when 'undefined' then undefined
        else JSON.parse o

  key: (o) ->
    switch typeof o
      when undefined then 'undefined'
      else "#{JSON.stringify o}"

assert = require 'assert'

describe 'Hash', ->

  it 'allows objects as keys', ->
    o = new Hash()
    o.set {meaning: 'life'}, 42
    assert o.get({meaning: 'life'}) is 42

  it 'allows arrays as keys', ->
    o = new Hash()
    o.set [0, 1, 1, 2], 'fibonacci'
    assert o.get([0, 1, 1, 2]) is 'fibonacci'

  it 'allows strings as keys', ->
    o = new Hash()
    o.set 'meaning', 'life'
    assert o.get('meaning') is 'life'

  it 'allows numbers as keys', ->
    o = new Hash()
    o.set 42, 'meaning'
    assert o.get(42) is 'meaning'

  it 'allows null as a key', ->
    o = new Hash()
    o.set null, 'nullish'
    assert o.get(null) is 'nullish'

  it 'allows undefined as a key', ->
    o = new Hash()
    o.set undefined, 'nullish'
    assert o.get(undefined) is 'nullish'

  it 'gives the undefined value for an unknown key', ->
    o = new Hash()
    o.set 'x', 'y'
    assert o.get('z') is undefined

  it 'gives scalar keys back as they were entered', ->
    ['meaning', 42, null, undefined].forEach (k) ->
      o = new Hash()
      o.set k, 'some value'
      assert o.keys()[0] is k

  it 'gives object keys back as they were entered', ->
    o = new Hash()
    o.set {meaning: 'life'}, 'objecty'
    assert o.keys()[0]['meaning'] is 'life'

  it 'gives array keys back as they were entered', ->
    o = new Hash()
    o.set [0, 1, 1, 2], 'arrayish'
    assert o.keys()[0][0] is 0
    assert o.keys()[0][1] is 1
    assert o.keys()[0][2] is 1
    assert o.keys()[0][3] is 2

