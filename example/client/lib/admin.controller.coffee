class @AdminController extends PageController
  onBeforeAction: -> super
  waitOn: ->
    return Luma.Collection.subscribe Luma.Admin.collections._name
  data: ->
    Luma.Admin.collections.find().forEach ( collection ) ->
      Luma.Collection.subscribe collection._id
    @route.options.collections = Luma.Admin.collections.find()
    super
  onAfterAction: -> super
  action: -> super