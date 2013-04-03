# E.g.
#
#   class Cow
#     constructor: (@name) -> makeChainable @, 'moo'
#     moo: -> console.log "#{@name} moos!"
#
#   daisy = new Cow('Daisy')
#   daisy.moo().moo().moo()

makeChainable = (receiver, fs...) ->
  for f in fs
    do ->
      wrapped = receiver[f]
      receiver[f] = -> wrapped.apply receiver, arguments; receiver

module.exports = makeChainable
