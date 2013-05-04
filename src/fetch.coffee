# fetch files from sfdc

force = require '../lib/force-0.1.0.min.js'

class Fetcher
  constructor: (creds, cb) ->
    that = @
    force.connect( creds ).then (conn) ->
      that.conn = conn
      cb()

  getClasses: (cb) ->
    @conn.query('SELECT Name, Body FROM ApexClass').then cb

module.exports = (creds, cb) ->
  new Fetcher creds, cb
