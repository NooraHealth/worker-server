
###
# Educator
###

{ SimpleSchema } = require "meteor/aldeed:simple-schema"

Educators = new Mongo.Collection Meteor.settings.public.educators_collection

EducatorsSchema = new SimpleSchema
  last_name:
    type: String
    defaultValue: ""
  first_name:
    type: String
    defaultValue: ""
  department:
    type: String
    defaultValue: ""
  facility_salesforce_id:
    type: String
    defaultValue: ""
    optional: true
  facility_role_salesforce_id:
    type: String
    defaultValue: ""
    optional: true
  contact_salesforce_id:
    type: String
    defaultValue: ""
    optional: true
  facility_name:
    type: String
    defaultValue: ""
    optional: true
  phone:
    type: Number
    defaultValue: ""
    optional: true
  processing:
    type: Boolean
    optional: true
    defaultValue: false
  uniqueId:
    type: String
    label: "Unique Id"
    optional: true

Educators.attachSchema EducatorsSchema

module.exports.Educators = Educators
module.exports.EducatorsSchema = EducatorsSchema
