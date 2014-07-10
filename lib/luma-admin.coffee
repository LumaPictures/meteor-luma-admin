@Luma = Luma = unless Luma then {}
# Admin
# =====
class Luma.Admin
  @collections: []

  @_addCollection: ( collection ) ->
    return if typeof collection isnt Meteor.Collection
    return if collection._name of @collections
