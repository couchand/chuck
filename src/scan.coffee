# a chuck scanner

couch = require 'felix-couchdb'

p = require '../lib/ascent-0.0.4'
chuck = require './chuck'

client = couch.createClient 5984, 'localhost'
db = client.db 'chuckdb'

class Scanner
  constructor: (@client, @environment) ->
    @environment ?= 'production'
    @timestamp = new Date()
    @classes = []

  docId: ->
    "#{@client}-#{@environment}-#{@timestamp}".toLowerCase().replace /\s/g, '-'

  scan: (name, cls) ->
    try
      @classes.push chuck.analyze p.parse cls
    catch err
      @classes.push { name: name, error: "#{err}" }

  save: (cb) ->
    db.saveDoc @docId(), @, (err, r) ->
      if err
        cb err
      else
        cb('success')

module.exports = (client, environment) ->
  new Scanner client, environment
