# chuck server

fetch = require './fetch'
scan = require './scan'
couch = require 'felix-couchdb'

client = couch.createClient 5984, 'localhost'
db = client.db 'chuckdb'

class Server
  constructor: (client, creds, cb) ->
    @scanner = scan client
    @fetcher = fetch creds, cb

  scanAll: (cb) ->
    s = @scanner
    @fetcher.getClasses (classes) ->
      for cls in classes
        s.scan cls.Name, cls.Body
      cb s

handleErr = (cb) ->
  (err) ->
    if err then cb err else cb 'success'

module.exports = (client, creds, cb) ->
  s = new Server client, creds, () ->
    s.fetcher.getSymbolTables (t) ->
      m = { client: client, classes: t }
      db.saveDoc m, handleErr(cb)
    s.scanAll (s) ->
      s.save handleErr(cb)
