# # admin

# ###### admin.created()
Template.admin.created = -> return

# ###### admin.rendered()
Template.admin.rendered = -> return

# ###### admin.destroyed()
Template.admin.destroyed = -> return

# ###### admin.events()
Template.admin.events
  "change #collections-filter": ( event, template ) ->
    collections = Session.get "admin:collections"
    query = collections.query
    key = "_id"
    if _.isArray( event.val ) and event.val.length > 0
      $in = []
      event.val.forEach ( val ) -> $in.push val
      filter = {}
      filter[ key ] = if query[ key ] and query[ key ].$in then query[ key ] else {}
      filter[ key ].$in = $in
      _.extend( query, filter )
    else delete query[ key ] if query[ key ]
    collections.query = query
    Session.set "admin:collections", collections

  "click .previous": ( event, template ) ->
    return false if $( event.target ).parent().hasClass( "disabled" )
    collections = Session.get "#{ @route }:collections"
    collections.options.skip = collections.options.skip - collections.options.limit
    Session.set "#{ @route }:collections", collections

  "click .next": ( event, template ) ->
    return false if $( event.target ).parent().hasClass( "disabled" )
    collections = Session.get "#{ @route }:collections"
    collections.options.skip = collections.options.limit + collections.options.skip
    Session.set "#{ @route }:collections", collections

# ##### admin.helpers()
Template.admin.helpers
  collections: ->
    collections = Session.get("#{ @route }:collections" )
    return Luma.Admin.collections.find collections.query

  collections_filter:
      id: "collections-filter"
      multiple: "multiple"
      options:
        width: "100%"
        allowClear: true
        placeholder: "Seach Collections..."
      selected: []

  firstPage: ->
    options = Session.get("#{ @route }:collections" )?.options
    return true unless options.skip - options.limit >= 0

  lastPage: ->
    options = Session.get("#{ @route }:collections" )?.options
    next_page = options.skip + options.limit
    return true if next_page >= Luma.Collection.getCount("admin_collections")