# a chuck scanner

couch = require 'felix-couchdb'

p = require '../lib/ascent-0.0.2'
chuck = require './chuck'

client = couch.createClient 5984, 'localhost'
db = client.db 'chuckdb'

toDocId = (name) ->
  name.toLowerCase().replace /\s/g, '-'

class ClientDoc
  constructor: (@name, cb) ->
    @id = toDocId @name
    @load cb

  load: (cb) ->
    t = @
    db.getDoc @id, (err, doc) ->
      if err
        t.doc =
          client: t.name
          scans: []
      else
        t.doc = doc
      cb()

  save: (cb) ->
    t = @
    db.saveDoc @id, @doc, (err, r) ->
      if err
        cb err
      else
        t.load cb

class Scanner
  constructor: (@client, @environment) ->
    @environment ?= 'production'
    @timestamp = new Date()
    @classes = []

  scan: (name, cls) ->
    try
      @classes.push chuck.analyze p.parse cls
    catch err
      @classes.push { name: name, error: "#{err}" }

  save: (cb) ->
    t = @
    m = new ClientDoc @client, ->
      m.doc.scans.unshift t
      m.save cb

module.exports = (client, environment) ->
  new Scanner client, environment
