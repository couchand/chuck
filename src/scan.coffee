# a chuck scanner

p = require '../lib/ascent-0.0.2'
chuck = require './chuck'

class Scanner
  constructor: (@client, @environment) ->
    @environment ?= 'production'
    @classes = []

  scan: (cls) ->
    try
      @classes.push chuck.analyze p.parse cls
    catch err
      @classes.push { name: name, error: "#{err}" }

module.exports = (client, environment) ->
  new Scanner client, environment
