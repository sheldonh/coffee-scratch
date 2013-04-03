fibonacci = (x) ->
  switch x
    when 0
      []
    when 1
      [0]
    else
      s = [0, 1]
      while x-- > 2
        s.push s[s.length - 2] + s[s.length - 1]
      s

module.exports = fibonacci
