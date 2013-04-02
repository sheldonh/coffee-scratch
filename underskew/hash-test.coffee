assert = require 'assert'

class Hash
  constructor: ->
    @length = 0
    @indexMap = {}
    @keyStore = []
    @valueStore = []
    @[p] = @private[p] for p of @private

  isSet: (k) -> @indexMap[@hashOf k]?

  get: (k) ->
    {i} = @keyPosition k
    @valueStore[i]

  set: (k, v) ->
    {key, i} = @keyPosition k
    [@indexMap[key], @keyStore[i], @valueStore[i]] = [i, k, v]
    @updateLength()
    @

  delete: (k) ->
    {key, i} = @keyPosition k
    unless i is @length
      delete @indexMap[key]
      @keyStore.splice(i, 1)
      @valueStore.splice(i, 1)
      @updateLength()
    @

  forEach: (handler) ->
    handler @keyStore[i], @valueStore[i] for key, i of @indexMap

  keys: -> @keyStore

  rehash: ->
    @indexMap = {}
    @indexMap[@hashOf @keyStore[i]] = i for i in [0...@keyStore.length]
    @

  private:

    keyPosition: (k) ->
      key = @hashOf k
      i = @indexMap[key]
      i ?= @keyStore.length
      {key: key, i: i}

    hashOf: (o) ->
      switch typeof o
        when undefined then 'undefined'
        else "#{JSON.stringify o}"

    updateLength: ->
      assert? @keyStore.length is @valueStore.length, 'Hash keyStore and valueStore lengths must match'
      @length = @keyStore.length

if typeof describe is 'function'
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

    it 'gives number of key-value pairs as length', ->
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

    it 'detects the presence of a key', ->
      o = new Hash()
      assert o.isSet('x') is false
      o.set('x', 'x-ray')
      assert o.isSet('x') is true
      assert o.isSet(undefined) is false
      o.set(undefined, 'magic')
      assert o.isSet(undefined) is true
      o.delete(undefined)
      assert o.isSet(undefined) is false

    it 'resets the value of an already set key', ->
      o = new Hash()
      o.set 'my', 'first'
      o.set 'my', 'last'
      assert o.length is 1
      assert o.get('my') is 'last'

    it 'gives keys back exactly as they were entered', ->
      [{meaning: 'life'}, [0, 1, 1, 2], 'meaning', 42, null, undefined].forEach (k) ->
        o = new Hash()
        o.set k, 'some value'
        assert.deepEqual o.keys()[0], k

    it 'detects object changes on rehash', ->
      o = new Hash()
      k = {meaning: 'life'}
      o.set k, 42
      o.set 'last', 'omega'
      k.meaning = 'liff'
      assert o.get(k) is undefined
      o.rehash()
      assert o.length is 2
      assert o.get(k) is 42

    it 'deletes key-value pairs', ->
      o = new Hash()
      o.set 'first', 'alpha'
      o.set 'unwanted', 'beta'
      for i in [1..2]
        o.delete 'unwanted'
        assert o.length is 1
        assert o.get('key') is undefined
      o.set 'last', 'gamma'
      assert o.length is 2
      assert o.get('last') is 'gamma'

    it 'daisy-chains set(), delete() and rehash()', ->
      o = new Hash()
      assert.deepEqual o.set('x', 'x-ray').set('y', 'yoda').delete('x').rehash().get('y'), 'yoda'

    it 'iterates over key-value pairs', ->
      o = new Hash()
      seenKeys = []
      seenValues = []
      o.set {meaning: 'life'}, 42
      o.set 'x', 'x-ray'
      o.set undefined, 'magic'
      o.forEach (k, v) ->
        seenKeys.push k
        seenValues.push v
      assert.deepEqual seenKeys, [{meaning: 'life'}, 'x', undefined]
      assert.deepEqual seenValues, [42, 'x-ray', 'magic']

exports.Hash = Hash
