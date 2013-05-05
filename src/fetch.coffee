# fetch files from sfdc

promise = require 'node-promise'
force = require '../lib/force-0.1.0.js'

class Fetcher
  constructor: (creds, cb) ->
    that = @
    that.containerName = "f#{new Date().getTime()}"
    that.containerName = that.containerName.substr 0, 8
    force.connect( creds ).then (conn) ->
      that.conn = conn
      cb()

  getClasses: (cb) ->
    @conn.query('SELECT Id, Name, Body FROM ApexClass WHERE NamespacePrefix = NULL').then cb

  createContainer: ->
    that = @
    @conn.tooling.insert('MetadataContainer', {
      'Name': @containerName
    }).then (id) -> that.setContainerId id

  setContainerId: (id) ->
    throw "unable to create!" unless id?
    @containerId = id

  createJunction: (cls) ->
    @conn.tooling.insert('ApexClassMember', {
      'MetadataContainerId': @containerId
      'ContentEntityId': cls.Id
      'Body': cls.Body
    }).then (id) -> throw "unable to create junction" unless id?

  createJunctions: (classes) ->
    promise.allOrNone (@createJunction cls for cls in classes)

  validateContainer: ->
    @conn.tooling.deploy @containerId, yes

  queryContainer: ->
    @conn.tooling.query "SELECT Id, SymbolTable FROM ApexClassMember WHERE MetadataContainerId = '#{@containerId}'"

  deleteContainer: ->
    @conn.tooling.destroy 'MetadataContainer', @containerId

  getSymbolTables: (cb) ->
    that = @
    @getClasses (classes) ->
      that.createContainer()
        .then(-> that.createJunctions classes)
        .then(-> that.validateContainer())
        .then(-> that.queryContainer())
        .then (symbolTables) ->
          that.deleteContainer().then -> cb symbolTables

module.exports = (creds, cb) ->
  new Fetcher creds, cb
