class @AdminController extends PageController

  onBeforeAction: -> super

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
      manager: "Global"

  data: ->
    Deps.autorun =>
      collections = @get "collections"
      Luma.Collection.subscribe Luma.Admin.collections._name, collections.query, collections.options,
        docs: true
        counts: true
        manager: "Global"
    collections = @get "collections"
    @route.options.collections_list = Luma.Admin.collections.find().fetch()
    super
  onAfterAction: -> super
  action: -> super

class @AdminCollectionController extends PageController

  get: ( key ) -> Session.get "#{ @route.name }:#{ key }"
  set: ( key, value ) -> Session.set "#{ @route.name }:#{ key }", value

  onBeforeAction: ->
    Luma.Admin._collections[ @params._id ] ?= new Meteor.Collection @params._id
    super

  waitOn: ->
    cursor =
      options:
        sort:
          _id: 1
      query: {}
      options:
        limit: 10
        skip: 0
    @set "cursor", cursor
    return Luma.Collection.subscribe @params._id, cursor.query, cursor.options,
      docs: true
      counts: true

  data: ->
    Deps.autorun =>
      cursor = @get "cursor"
      console.log cursor
      Luma.Collection.subscribe @params._id, cursor.query, cursor.options,
        docs: true
        counts: false
    @route.options.collection = @params._id
    super

  onAfterAction: -> super

  action: -> super