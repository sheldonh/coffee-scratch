assert = require 'assert'
ObjectMap = require './object-map'

if typeof describe is 'function'
  describe 'ObjectMap', ->

    it 'allows objects as keys', ->
      o = new ObjectMap()
      o.set {meaning: 'life'}, 42
      assert.equal o.get({meaning: 'life'}), 42

    it 'allows arrays as keys', ->
      o = new ObjectMap()
      o.set [0, 1, 1, 2], 'fibonacci'
      assert.equal o.get([0, 1, 1, 2]), 'fibonacci'

    it 'allows strings as keys', ->
      o = new ObjectMap()
      o.set 'meaning', 'life'
      assert.equal o.get('meaning'), 'life'

    it 'allows numbers as keys', ->
      o = new ObjectMap()
      o.set 42, 'meaning'
      assert.equal o.get(42), 'meaning'

    it 'allows null as a key', ->
      o = new ObjectMap()
      o.set null, 'nullish'
      assert.equal o.get(null), 'nullish'

    it 'allows undefined as a key', ->
      o = new ObjectMap()
      o.set undefined, 'nullish'
      assert.equal o.get(undefined), 'nullish'

    it 'gives number of key-value pairs as length', ->
      o = new ObjectMap()
      assert.equal o.length, 0
      o.set 'x', 'x'
      assert.equal o.length, 1
      o.set 'y', 'y'
      assert.equal o.length, 2
      o.set 'y', 'reused key'
      assert.equal o.length, 2

    it 'gives the undefined value for an unknown key', ->
      o = new ObjectMap()
      o.set 'x', 'y'
      assert.equal o.get('z'), undefined

    it 'detects the presence of a key', ->
      o = new ObjectMap()
      assert.equal o.isSet('x'), false
      o.set('x', 'x-ray')
      assert.equal o.isSet('x'), true
      assert.equal o.isSet(undefined), false
      o.set(undefined, 'magic')
      assert.equal o.isSet(undefined), true
      o.delete(undefined)
      assert.equal o.isSet(undefined), false

    it 'resets the value of an already set key', ->
      o = new ObjectMap()
      o.set 'my', 'first'
      o.set 'my', 'last'
      assert.equal o.length, 1
      assert.equal o.get('my'), 'last'

    allTypes = [{meaning: 'life'}, [0, 1, 1, 2], 'meaning', 42, null, undefined]

    it 'gives keys back exactly as they were entered', ->
      o = new ObjectMap()
      o.set(k, "value #{k}") for k in allTypes
      assert.deepEqual o.keys(), allTypes

    it 'gives values back exactly as they were entered', ->
      o = new ObjectMap()
      o.set("key #{v}", v) for v in allTypes
      assert.deepEqual o.values(), allTypes

    it 'detects object changes on rehash', ->
      o = new ObjectMap()
      k = {meaning: 'life'}
      o.set k, 42
      o.set 'last', 'omega'
      k.meaning = 'liff'
      assert.equal o.get(k), undefined
      o.rehash()
      assert.equal o.length, 2
      assert.equal o.get(k), 42

    it 'deletes key-value pairs', ->
      o = new ObjectMap()
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
      o = new ObjectMap()
      assert.deepEqual o.set('x', 'x-ray').set('y', 'yoda').delete('x').rehash().get('y'), 'yoda'

    it 'iterates over key-value pairs', ->
      o = new ObjectMap()
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

    it 'iterates until stopped', ->
      o = new ObjectMap()
      o.set 'x', 'x-ray'
      o.set 'y', 'yoda'
      o.set 'z', 'zombie'
      seen = {}
      o.each (k, v) ->
        if k is 'z' then false else seen[k] = v
      assert.deepEqual seen, {x: 'x-ray', y: 'yoda'}

    it 'detects if at least one key-value pair passes a function', ->
      o = new ObjectMap()
      o.set 'a', 'alpha'
      o.set 'b', 'beta'
      assert.equal o.some((k, v) -> k is 'a' and v is 'alpha'), true
      assert.equal o.some((k, v) -> k is 'b' and v is 'gamma'), false
      assert.equal o.some((k, v) -> k is 'g' and v is 'beta'), false

    it 'detects if all key-value pairs pass a function', ->
      o = new ObjectMap()
      o.set 'a', 'alpha'
      o.set 'b', 'beta'
      assert.equal o.every((k, v) -> k is 'a' or k is 'b'), true
      assert.equal o.every((k, v) -> v is 'alpha' or v is 'beta'), true
      assert.equal o.every((k, v) -> k is 'a'), false

    it 'creates a new hash with all key-value pairs that pass a function', ->
      o = new ObjectMap()
      o.set 'a', 'alpha'
      o.set 'b', 'beta'
      all = o.filter (k, v) -> v.indexOf 'a' >= 0
      assert.deepEqual [all.get('a'), all.get('b')], ['alpha', 'beta']
      some = o.filter (k, v) -> k is 'b'
      assert.deepEqual [some.get('a'), some.get('b')], [undefined, 'beta']

