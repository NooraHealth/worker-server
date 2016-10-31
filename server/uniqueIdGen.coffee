
{ UniqueID } = require "../imports/api/collections/unique_id.coffee"

generateUniqueId = ( facilityName )->
    
    result = UniqueID.findOne({ _id: Meteor.settings.UNIQUE_ID_DOC_ID })
    UniqueID.update { _id: Meteor.settings.UNIQUE_ID_DOC_ID}, { $inc: { currentUniqueID: 1 }}

    getInitials = ( name )->
      words = name.split " "
      letters = words.map (word)->
        cleaned = word.replace(/[^a-zA-Z]/g, "")
        return cleaned[0]?.toUpperCase()

    initials = getInitials( facilityName )
    return initials.join("") + result.currentUniqueID


module.exports.generateUniqueId = generateUniqueId
