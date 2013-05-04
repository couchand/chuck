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
      for cls in classes when cls.Name isnt 'BatchLoadReleases'
        s.scan cls.Name, cls.Body
      cb s

module.exports = (client, creds, cb) ->
  s = new Server client, creds, () ->
    s.scanAll (s) ->
      db.saveDoc s, (err) ->
        throw err if err
        cb s
