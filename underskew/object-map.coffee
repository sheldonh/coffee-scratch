class JsonKeyMaker
  constructor: -> @make undefined

  make: (o) ->
    return @lastKey if o is @lastObject
    @lastObject = o
    @lastKey = switch typeof o
      when undefined then 'undefined'
      else "#{JSON.stringify o}"

class KeyIndexMap
  constructor: (@keyMaker) ->
    @map = {}

  indexes: ->
    a = []
    a.push i for k, i of @map
    a

  get: (k) -> @map[@safeKey k]

  set: (k, i) -> @map[@safeKey k] = i

  delete: (k) -> delete @map[@safeKey k]

  safeKey: (o) -> @keyMaker.make o

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

class ObjectMap
  constructor: ->
    @length = 0
    @newKeyIndexMap = -> new KeyIndexMap(new JsonKeyMaker())
    @indexMap = @newKeyIndexMap()
    @store = new KeyValueStore()

  isSet: (k) -> @indexMap.get(k)?

  get: (k) -> @store.valueAt @indexMap.get(k)

  set: (k, v) ->
    if @isSet k
      @store.set @indexMap.get(k), k, v
    else
      @indexMap.set k, @store.append(k, v)
      @length++
    @

  delete: (k) ->
    if @isSet k
      @store.delete @indexMap.get(k)
      @indexMap.delete k
      @length--
    @

  keys: -> @store.keyStore

  values: -> @store.valueStore

  rehash: ->
    [oldindexMap, @indexMap] = [@indexMap, @newKeyIndexMap()]
    for i in oldindexMap.indexes()
      @indexMap.set @store.keyAt(i), i
    @

  dup: -> @filter -> true

  each: (fn) ->
    for i of @indexMap.indexes()
      return false if fn(@store.keyAt(i), @store.valueAt(i)) is false
    true

  forEach: (fn) ->
    @each (k, v) -> fn(k, v); true

  some: (test) ->
    !@each (k, v) -> !test(k, v)

  every: (test) ->
    !!@each (k, v) -> !!test(k, v)

  filter: (test) ->
    m = new ObjectMap()
    @forEach (k, v) -> m.set(k, v) if test(k, v)
    m

module.exports = ObjectMap
