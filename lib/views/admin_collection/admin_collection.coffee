# # admin_collection

# ###### admin_collection.created()
Template.admin_collection.created = -> return

# ###### admin_collection.rendered()
Template.admin_collection.rendered = -> return

# ###### admin_collection.destroyed()
Template.admin_collection.destroyed = -> return

# ###### admin_collection.events()
Template.admin_collection.events
  "click .previous": ( event, template ) ->
    return false if $( event.target ).parent().hasClass "disabled"
    collections = Session.get "#{ @route }:cursor"
    return false unless collections
    collections.options.skip = collections.options.skip - collections.options.limit
    Session.set "#{ @route }:cursor", collections

  "click .next": ( event, template ) ->
    return false if $( event.target ).parent().hasClass "disabled"
    collections = Session.get "#{ @route }:cursor"
    return false unless collections
    collections.options.skip = collections.options.limit + collections.options.skip
    Session.set "#{ @route }:cursor", collections

# ##### admin_collection.helpers()
Template.admin_collection.helpers

  total_count: ->
    if @collection
      Luma.Collection.getCount @collection
    else return 0

  documents: ->
    cursor = Session.get "#{ @route }:cursor"
    collection = Luma.Admin._collections[ @collection ]
    if cursor and collection
      cursor.options.skip = 0
      return collection.find cursor.query, cursor.options

  firstPage: ->
    options = Session.get("#{ @route }:cursor" )?.options
    if options
      return true unless options.skip - options.limit >= 0

  lastPage: ->
    options = Session.get("#{ @route }:cursor" )?.options
    if options
      next_page = options.skip + options.limit
      return true if next_page >= Luma.Collection.getCount @collection