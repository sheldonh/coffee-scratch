assert = require 'assert'

class Hash
  constructor: ->
    @length = 0
    @indexMap = {}
    @keyStore = []
    @valueStore = []

  get: (k) ->
    i = @indexMap[@hashOf k]
    @valueStore[i]

  set: (k, v) ->
    key = @hashOf k
    i = @indexMap[key] or @keyStore.length
    [@indexMap[key], @keyStore[i], @valueStore[i]] = [i, k, v]
    assert @keyStore.length is @valueStore.length, 'Hash keyStore and valueStore length mismatch'
    @length = @keyStore.length

  keys: -> @keyStore

  rehash: ->
    @indexMap = {}
    @indexMap[@hashOf @keyStore[i]] = i for i in [0...@keyStore.length]

  hashOf: (o) ->
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

  it 'gives number key-value pairs as length', ->
    o = new Hash()
    assert o.length is 0
    o.set 'x', 'x'
    assert o.length is 1
    o.set 'y', 'y'
    assert o.length is 2
    o.set 'y', 'reused key'
    assert o.length is 2

  it 'gives the undefined value for an unknown key', ->
    o = new Hash()
    o.set 'x', 'y'
    assert o.get('z') is undefined

  it 'gives keys back exactly as they were entered', ->
    [{meaning: 'life'}, [0, 1, 1, 2], 'meaning', 42, null, undefined].forEach (k) ->
      o = new Hash()
      o.set k, 'some value'
      assert.deepEqual o.keys()[0], k

  it 'detects object changes on rehash', ->
    o = new Hash()
    k = {meaning: 'life'}
    o.set k, 42
    k.meaning = 'liff'
    assert o.get(k) is undefined
    o.rehash()
    assert o.length is 1
    assert o.get(k) is 42

