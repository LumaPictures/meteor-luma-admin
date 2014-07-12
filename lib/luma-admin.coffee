# Admin
# =====
root = exports ? this

Luma.Subscriptions =
  Default: Meteor

  Global: new SubsManager
    cacheLimit: 9999
    expireIn: 9999

class Luma.Collection

  @_prefix: "Luma_Collection"

  @schemas:
    _counts: new SimpleSchema count: type: Number

  @_counts: if Meteor.isClient then new Meteor.Collection( "#{ @_prefix }_counts", schema: @schemas._counts ) else "#{ @_prefix }_counts"

  @_andQueries: ( queries = [] ) ->
    check queries, Array
    if queries.length
      return { $and: queries }
    else return queries

  @getCollections: ( callback ) ->
    return if Meteor.isClient
    throw new Error "`callback` must be a function." unless _.isFunction callback
    mongo_driver = MongoInternals?.defaultRemoteCollectionDriver() or Meteor._RemoteCollectionDriver
    mongo_driver.mongo.db.collections callback

  @checkCollection: ( collection ) ->
    throw new Error "`collection` must be a Meteor.Collection" unless collection and collection._name

  @getId: ( collection, suffix = "" ) ->
    @checkCollection collection if Meteor.isServer
    check collection, String if Meteor.isClient
    name = if Meteor.isServer then collection._name else collection
    check suffix, String
    suffix = "_#{ suffix }" if suffix.length
    return "#{ @_prefix }_#{ name }#{ suffix }"

  @publish: ( collection, baseQuery = {}, baseOptions = { limit: 10, skip: 0 }, subOptions = {} ) ->
    return unless Meteor.isServer
    @checkCollection collection
    check subOptions, Object
    docs = subOptions.docs or true
    counts = subOptions.counts or true
    suffix = subOptions.suffix or ""
    id = @getId collection, suffix
    check id, String
    check baseQuery, Object
    check baseOptions, Object
    Luma.Collection.publishCount collection, baseQuery, suffix if counts
    if docs
      Meteor.publish id, ( query = {}, options = { limit: 10, skip: 0 } ) ->
        check query, Object
        check options, Object
        options.skip = 0 if options.skip < 0
        query = Luma.Collection._andQueries [ baseQuery, query ]
        return collection.find query, options

  @getCount: ( collection, suffix = "", query = {} ) ->
    @checkCollection collection if Meteor.isServer
    check collection, String if Meteor.isClient
    check query, Object if Meteor.isServer
    id = @getId collection, suffix
    id = "#{ id }_count"
    check id, String
    if Meteor.isServer
      return collection.find( query ).count()
    if Meteor.isClient
      return Luma.Collection._counts.findOne( _id: id )?.count

  @publishCount: ( collection, baseQuery = {}, suffix = "" ) ->
    return unless Meteor.isServer
    @checkCollection collection
    id = @getId collection, suffix
    id = "#{ id }_count"
    check id, String
    check baseQuery, Object
    Meteor.publish id, ( query = {} ) ->
      self = @
      check query, Object
      query = Luma.Collection._andQueries [ baseQuery, query ]
      initializing = true
      handle = collection.find( query ).observeChanges
        added: ->
          unless initializing
            count = Luma.Collection.getCount collection, id, query
            self.changed Luma.Collection._counts, id, count: count
        removed: ->
          unless initializing
            count = Luma.Collection.getCount collection, id, query
            self.changed Luma.Collection._counts, id, count: count
      initializing = false
      count = Luma.Collection.getCount collection, id, query
      self.added Luma.Collection._counts, id, count: count
      self.ready()
      self.onStop -> handle.stop()

  @subscribe: ( collection, query = {}, options = {}, subOptions = {} ) ->
    check query, Object
    check options, Object
    check subOptions, Object
    docs = subOptions.docs or true
    counts = subOptions.counts or true
    manager = subOptions.manager or null
    suffix = subOptions.suffix or ""
    id = @getId collection, suffix
    check id, String
    handles = []
    if manager and Luma.Subscriptions[ manager ]
      sub = Luma.Subscriptions[ manager ]
    else sub = Luma.Subscriptions.Default
    if docs
      handles.push sub.subscribe id, query, options
    if counts
      handles.push sub.subscribe "#{ id }_count", query
    return handles

if Meteor.isClient
  UI.registerHelper "getCount", ( collection_name ) -> return Luma.Collection.getCount collection_name
    
class Luma.Admin

  @_collections: []

  @collections: new Meteor.Collection "admin_collections"

  @_ignored_prefixes: [
    'system'
    'admin'
  ]
  
  @add: ( collection, publishCallback = null ) ->
    if Meteor.isClient
      Luma.Admin._collections[ collection._name ] = collection
    if Meteor.isServer
      Luma.Collection.checkCollection collection
      @_collections[ collection._name ] = collection
      unless Luma.Admin.collections.findOne( _id: collection._name )
        Luma.Admin.collections.insert _id: collection._name
      if _.isFunction publishCallback
        publishCallback()
      else
        Luma.Collection.publish collection
        Luma.Collection.publishCount collection

  @_isCollectionSyncable: ( collection ) ->
    for prefix in Luma.Admin._ignored_prefixes
      syncable = collection.indexOf prefix
      return true if syncable is 0

  @_getSyncableCollections: ( collections ) ->
    collections = _.pluck collections, "collectionName"
    return _.reject collections, @_isCollectionSyncable

  @_setupCollections: ( collections ) ->
    for collection in collections
      unless collection of Luma.Admin._collections
        new_collection = null
        try
          new_collection = new Meteor.Collection collection
        catch e
          for key, value of root
            if collection == value?._name
              new_collection = value

        if new_collection?
          Luma.Admin._collections[ new_collection._name ] = new_collection
          unless Luma.Admin.collections.findOne( _id: new_collection._name )
            Luma.Admin.collections.insert _id: new_collection._name
          Luma.Collection.publish Luma.Admin._collections[ new_collection._name ]
        else
          console.log """
Luma.Admin: couldn't find access to the #{ collection } collection.
If you'd like to access the collection from Luma.Admin, either
(1) make sure it is available as a global (top-level namespace) within the server or
(2) add the collection manually via Luma.Admin.add
"""

  @sync: ->
    return unless Meteor.isServer
    boundSyncCollections = Meteor.bindEnvironment Luma.Admin._syncCollections
    Luma.Collection.getCollections boundSyncCollections
    Luma.Collection.publish Luma.Admin.collections

  @_syncCollections: ( unknownArg, collections ) ->
    collections = Luma.Admin._getSyncableCollections collections
    Luma.Admin._setupCollections collections









