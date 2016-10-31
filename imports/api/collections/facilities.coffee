
###
# Facilities
###

{ SimpleSchema } = require "meteor/aldeed:simple-schema"

Facilities = new Mongo.Collection Meteor.settings.public.facilities_collection

FacilitiesSchema = new SimpleSchema
  name:
    type:String
  salesforce_id:
    type:String
  delivery_partner:
    type:String

Facilities.attachSchema FacilitiesSchema

module.exports.Facilities = Facilities
