# Admin
# =====
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

  @_checkCollection: ( collection ) ->
    throw new Error "`collection` must be a Meteor.Collection" unless collection and collection._name

  @getId: ( collection, suffix = "" ) ->
    @_checkCollection collection
    check suffix, String
    suffix = "_#{ suffix }" if suffix.length
    return "#{ @_prefix }_#{ collection._name }#{ suffix }"

  @publish: ( collection, baseQuery = {}, baseOptions = {}, suffix = "" ) ->
    @_checkCollection collection
    return unless Meteor.isServer
    id = @getId collection, suffix
    check id, String
    check baseQuery, Object
    check baseOptions, Object
    Meteor.publish id, ( query = {}, options = { limit: 10 } ) ->
      check query, Object
      check options, Object
      query = Luma.Collection._andQueries [ baseQuery, query ]
      options = _.defaults options, baseOptions
      return collection.find query, options

  @getCount: ( collection, query = {}, id ) ->
    @_checkCollection collection
    check query, Object
    check id, String
    if Meteor.isServer
      return collection.find( query ).count()
    if Meteor.isClient
      return Luma.Collection._counts.findOne( _id: id )?.count

  @publishCount: ( collection, baseQuery = {}, suffix = "" ) ->
    return unless Meteor.isServer
    @_checkCollection collection
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
            count = Luma.Collection.getCount collection, query, id
            self.changed Luma.Collection._counts, id, count: count
        removed: ->
          unless initializing
            count = Luma.Collection.getCount collection, query, id
            self.changed Luma.Collection._counts, id, count: count
      initializing = false
      count = Luma.Collection.getCount collection, query, id
      self.added Luma.Collection._counts, id, count: count
      self.ready()
      self.onStop -> handle.stop()

  @subscribe: ( collection, query = {}, options = null, subOptions = {} ) ->
    docs = subOptions.docs or true
    counts = subOptions.counts or true
    suffix = subOptions.suffix or ""
    id = @getId collection, suffix
    check id, String
    handles = []
    handles.push Meteor.subscribe id, query, options if docs
    handles.push Meteor.subscribe "#{ id }_count", query if counts
    return handles




