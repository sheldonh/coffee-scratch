task 'build', 'Build all the things', -> build smile

task 'launch', 'Launch the server thing', -> build -> launch()

task 'watch', 'Build all the changes forever', -> watch -> build smile

task 'launch:watch', 'Build, launch and kill for all changes', ->
  build -> launch()
  watch -> build -> kill -> launch()

server_process = null
launch = ->
  record_server_process = (child) -> server_process = child
  run 'node', 'server/main.js', record_server_process, -> console.log 'server stopped'

build = (callback) -> prepare_dir 'build', -> coffee -> webify -> server callback

watch = (callback) ->
  last = new Date()
  createMonitor 'src', (monitor) ->
    for event in ['created', 'removed', 'changed']
      monitor.on event, (fn, stat) ->
        if stat.mtime > last and !!fn.match /\.(?:js|coffee|html)$/
            last = stat.mtime
            callback()

kill = (callback) ->
  server_process?.on 'close', ->
    console.log 'server killed'
    server_process = null; callback()
  server_process?.kill('SIGINT')

webify = (callback) -> prepare_dir 'web', -> vendor -> browserify -> index callback

server = (callback) -> prepare_dir 'server', -> run 'cp', 'build/main.js', 'server/', callback

prepare_dir = (dir, callback) -> destroy_dir dir, -> fs.mkdir dir, callback

destroy_dir = (dir, callback) -> run 'rm', '-rf', dir, callback

coffee = (callback) ->
  on_success glob, 'src/*.coffee', (files) ->
    run 'coffee', '-c', '-o', 'build', files, callback if files.length > 0

vendor = (callback) ->
  prepare_dir 'web/vendor', ->
    on_success glob, 'vendor/*.js', (files) ->
      run 'cp', files, 'web/vendor/', callback

browserify = (callback) ->
  run 'browserify', '-o', 'web/bundle.js', 'build/launch.js', callback

index = (callback) ->
  on_success glob, 'src/*.{css,html}', (files) ->
    run 'cp', files, 'web/', callback

on_success = (fn, args..., callback) ->
  fn args..., (err, result...) ->
    if err? then throw err else callback result...

run = (cmd, args..., on_exit) ->
  throw "run demands a callback" unless typeof on_exit is 'function'
  args = [].concat args...
  on_spawn = args.pop() if typeof args[args.length - 1] is 'function'
  on_success which, cmd, (path) ->
    console.log path, args...
    child = system path, args, on_exit
    on_spawn? child

system = (path, args, callback) ->
  log = (log_how, data) -> log_how data.toString().trim()
  child = spawn path, args
  child.stdout.on 'data', (data) -> log console.log, data
  child.stderr.on 'data', (data) -> log console.error, data
  child.on 'exit', (status) -> callback?() if status is 0
  child

smile = ->
  console.log ':-)'
  true

fs = require 'fs'
glob = require 'glob'
{spawn} = require 'child_process'
{createMonitor} = require 'watch'
which = require 'which'
