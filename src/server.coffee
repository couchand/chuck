# chuck server

fetch = require './fetch'
scan = require './scan'

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

module.exports = (client, creds, cb) ->
  s = new Server client, creds, cb#() -> s.scanAll (s) -> s
