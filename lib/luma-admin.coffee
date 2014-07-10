# Admin
# =====
class Admin

  @_max_docs_to_explore: 100

  @_collections:
    collections: new Meteor.Collection "collections"

  @_user_is_admin: ( userId ) -> return true

  @addCollection: ( collection ) ->
    return unless Meteor.isServer
    return if collection._name of @_collections

    name = collection._name
    methods = {}
    methods[ "#{name}_insert" ] = (doc) ->
      check doc, Object
      return unless Admin._user_is_admin @userId
      collection.insert(doc)

    methods[ "#{name}_update" ] = (id, update_dict) ->
      check id, Match.Any
      check update_dict, Object
      return unless Admin._user_is_admin @userId
      if collection.findOne(id)
        collection.update(id, update_dict)
      else
        id = collection.findOne(new Meteor.Collection.ObjectID(id))
        collection.update(id, update_dict)

    methods[ "#{name}_delete" ] = (id) ->
      check id, Match.Any
      return unless Admin._user_is_admin @userId
      if collection.findOne(id)
        collection.remove(id)
      else
        id = collection.findOne(new Meteor.Collection.ObjectID(id))
        collection.remove(id)

    Meteor.methods methods

    Meteor.publish name, (sort, filter, limit, unknown_arg) ->
      check sort, Match.Optional(Object)
      check filter, Match.Optional(Object)
      check limit, Match.Optional(Number)
      check unknown_arg, Match.Any
      return unless Admin._user_is_admin @userId
      try
        collection.find(filter, sort: sort, limit: limit)
      catch e
        console.log e

    collection.find().observe
      _suppress_initial: true  # fixes houston for large initial datasets
      added: (document) ->
        Admin._collections.collections.update {name},
          $inc: {count: 1},
          $addToSet: fields: $each: Admin._get_fields([document])
      removed: (document) -> Admin._collections.collections.update {name}, {$inc: {count: -1}}

    fields = Admin._get_fields_from_collection(collection)
    c = Admin._collections.collections.findOne {name}
    count = collection.find().count()
    if c
      Admin._collections.collections.update c._id, {$set: {count, fields}}
    else
      Admin._collections.collections.insert {name, count, fields}
    Admin._collections[ name ] = collection

  @_get_fields_from_collection: (collection) ->
    # TODO(AMK) randomly sample the documents in question
    Admin._get_fields(collection.find().fetch())

  @_get_fields: (documents) ->
    key_to_type = {_id: 'ObjectId'}

    find_fields = (document, prefix='') ->
      for key, value of _.omit(document, '_id')
        if typeof value is 'object'

          # handle dates like strings
          if value instanceof Date
            full_path_key = "#{prefix}#{key}"
            key_to_type[full_path_key] = "Date"

            # recurse into sub documents
          else
            find_fields value, "#{prefix}#{key}."
        else if typeof value isnt 'function'
          full_path_key = "#{prefix}#{key}"
          key_to_type[full_path_key] = typeof value

    for document in documents[ ..Admin._max_docs_to_explore ]
      find_fields document

    (name: key, type: value for key, value of key_to_type)

  @_get_field_names = (documents) ->
    _.pluck(Admin._get_fields(documents), 'name')
