assert = require 'assert'

class JsonHasher
  constructor: -> @hash undefined

  hash: (o) ->
    return @lastHash if o is @lastHashed
    @lastHashed = o
    @lastHash = switch typeof o
      when undefined then 'undefined'
      else "#{JSON.stringify o}"

class KeyValueStore
  constructor: ->
    @keyStore = []
    @valueStore = []

  keyAt: (i) -> @keyStore[i]

  valueAt: (i) -> @valueStore[i]

  set: (i, k, v) ->
    @keyStore[i] = k
    @valueStore[i] = v

  append: (k, v) ->
    i = @keyStore.length
    @keyStore.push k
    @valueStore.push v
    i

  delete: (i) ->
    delete @keyStore[i]
    delete @valueStore[i]

class Hash
  constructor: (@hasher = new JsonHasher()) ->
    @length = 0
    @indexMap = {}
    @store = new KeyValueStore()
    @[p] = @private[p] for p of @private

  isSet: (k) -> @indexOf(k)?

  get: (k) -> @store.valueAt @indexOf(k)

  set: (k, v) ->
    if @isSet k
      @store.set @indexOf(k), k, v
    else
      @append k, v
    @

  delete: (k) ->
    if @isSet k
      @store.delete @indexOf(k)
      delete @indexMap[@hashOf k]
      @length--
    @

  keys: -> @store.keyStore

  rehash: ->
    [oldIndexMap, @indexMap] = [@indexMap, {}]
    for key, i of oldIndexMap
      @indexMap[@hashOf @store.keyAt i] = i
    @

  dup: -> @filter -> true

  forEach: (fn) ->
    for key, i of @indexMap
      fn @store.keyAt(i), @store.valueAt(i)

  some: (test) ->
    for key, i of @indexMap
      return true if test @store.keyAt(i), @store.valueAt(i)
    return false

  every: (test) ->
    for key, i of @indexMap
      return false unless test @store.keyAt(i), @store.valueAt(i)
    return true

  filter: (test) ->
    h = new Hash()
    for key, i of @indexMap
      [k, v] = [@store.keyAt(i), @store.valueAt(i)]
      h.set(k, v) if test k, v
    h

  private:

    indexOf: (k) -> @indexMap[@hashOf k]

    hashOf: (o) -> @hasher.hash o

    append: (k, v) ->
      @indexMap[@hashOf k] = @store.append k, v
      @length++

if typeof describe is 'function'
  describe 'Hash', ->

    it 'allows objects as keys', ->
      o = new Hash()
      o.set {meaning: 'life'}, 42
      assert.equal o.get({meaning: 'life'}), 42

    it 'allows arrays as keys', ->
      o = new Hash()
      o.set [0, 1, 1, 2], 'fibonacci'
      assert.equal o.get([0, 1, 1, 2]), 'fibonacci'

    it 'allows strings as keys', ->
      o = new Hash()
      o.set 'meaning', 'life'
      assert.equal o.get('meaning'), 'life'

    it 'allows numbers as keys', ->
      o = new Hash()
      o.set 42, 'meaning'
      assert.equal o.get(42), 'meaning'

    it 'allows null as a key', ->
      o = new Hash()
      o.set null, 'nullish'
      assert.equal o.get(null), 'nullish'

    it 'allows undefined as a key', ->
      o = new Hash()
      o.set undefined, 'nullish'
      assert.equal o.get(undefined), 'nullish'

    it 'gives number of key-value pairs as length', ->
      o = new Hash()
      assert.equal o.length, 0
      o.set 'x', 'x'
      assert.equal o.length, 1
      o.set 'y', 'y'
      assert.equal o.length, 2
      o.set 'y', 'reused key'
      assert.equal o.length, 2

    it 'gives the undefined value for an unknown key', ->
      o = new Hash()
      o.set 'x', 'y'
      assert.equal o.get('z'), undefined

    it 'detects the presence of a key', ->
      o = new Hash()
      assert.equal o.isSet('x'), false
      o.set('x', 'x-ray')
      assert.equal o.isSet('x'), true
      assert.equal o.isSet(undefined), false
      o.set(undefined, 'magic')
      assert.equal o.isSet(undefined), true
      o.delete(undefined)
      assert.equal o.isSet(undefined), false

    it 'resets the value of an already set key', ->
      o = new Hash()
      o.set 'my', 'first'
      o.set 'my', 'last'
      assert.equal o.length, 1
      assert.equal o.get('my'), 'last'

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
      assert.equal o.get(k), undefined
      o.rehash()
      assert.equal o.length, 2
      assert.equal o.get(k), 42

    it 'deletes key-value pairs', ->
      o = new Hash()
      o.set 'x', 'x-ray'
      o.set 'y', 'yoda'
      o.set 'z', 'zombie'
      for i in [1..2]
        o.delete 'y'
        assert.equal o.length, 2
        assert.equal o.get('y'), undefined
      assert.equal o.get('z'), 'zombie'
      o.set '!', 'omega'
      assert.equal o.length, 3
      assert.equal o.get('!'), 'omega'

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

    it 'detects if at least one key-value pair passes a function', ->
      o = new Hash()
      o.set 'a', 'alpha'
      o.set 'b', 'beta'
      assert.equal o.some((k, v) -> k is 'a' and v is 'alpha'), true
      assert.equal o.some((k, v) -> k is 'b' and v is 'gamma'), false
      assert.equal o.some((k, v) -> k is 'g' and v is 'beta'), false

    it 'detects if all key-value pairs pass a function', ->
      o = new Hash()
      o.set 'a', 'alpha'
      o.set 'b', 'beta'
      assert.equal o.every((k, v) -> k is 'a' or k is 'b'), true
      assert.equal o.every((k, v) -> v is 'alpha' or v is 'beta'), true
      assert.equal o.every((k, v) -> k is 'a'), false

    it 'creates a new hash with all key-value pairs that pass a function', ->
      o = new Hash()
      o.set 'a', 'alpha'
      o.set 'b', 'beta'
      assert.deepEqual o.filter((k, v) -> v.indexOf 'a' >= 0), o
      assert.deepEqual o.filter((k, v) -> k is 'b'), new Hash().set('b', 'beta')

exports.Hash = Hash
