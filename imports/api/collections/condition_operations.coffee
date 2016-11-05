###
# Condition Operations
###

{ SimpleSchema } = require "meteor/aldeed:simple-schema"

ConditionOperations = new Mongo.Collection Meteor.settings.public.condition_operations_collection

ConditionOperationsSchema = new SimpleSchema
  name:
    type:String
  salesforce_id:
    type:String
  facility:
    type:String

ConditionOperations.attachSchema ConditionOperationsSchema

module.exports.ConditionOperations = ConditionOperations
