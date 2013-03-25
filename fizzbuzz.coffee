divisible = (x, y) -> x % y == 0

fizzbuzz = (x) ->
  s = ''
  s += 'Fizz' if x % 3 == 0
  s += 'Buzz' if x % 5 == 0
  s = x if s.length is 0
  console.log s

fizzbuzz x for x in [1..100]
