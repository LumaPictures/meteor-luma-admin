class @AdminController extends PageController
  onBeforeAction: -> super
  data: -> super
  waitOn: -> return Luma.Collection.subscribe Luma.Router.collection
  onAfterAction: -> super
  action: -> super