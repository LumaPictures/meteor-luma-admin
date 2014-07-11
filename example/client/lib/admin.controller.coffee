class @AdminController extends PageController

  get: ( key ) -> Session.get "#{ @route.name }:#{ key }"
  set: ( key, value ) -> Session.set "#{ @route.name }:#{ key }", value

  onBeforeAction: ->
    super

  waitOn: ->
    collections =
      selected: []
      options:
        sort:
          _id: 1
      query: {}
    @set "collections", collections
    return Luma.Collection.subscribe Luma.Admin.collections._name, collections.query, collections.options,
      docs: true
      counts: true

  data: ->
    Deps.autorun =>
      collections = @get "collections"
      Luma.Collection.subscribe Luma.Admin.collections._name, collections.query, collections.options,
        docs: true
        counts: true
    collections = @get "collections"
    @route.options.collections_list = Luma.Admin.collections.find().fetch()
    super
  onAfterAction: -> super
  action: -> super