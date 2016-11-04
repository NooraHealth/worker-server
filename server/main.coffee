{ Meteor } = require 'meteor/meteor';
{ Educators } = require '../imports/api/collections/educators.coffee'
{ Facilities } = require '../imports/api/collections/facilities.coffee'
# { LoadTest } = require './load_test.coffee'

Meteor.startup ()->
  console.log ("Startup!")
  result = Salesforce.login Meteor.settings.SF_USER, Meteor.settings.SF_PASS, Meteor.settings.SF_TOKEN
  console.log result

  exportNurseEducators = ->
    educators = Educators.find( {
      contact_salesforce_id: "",
    }).fetch()
    if educators.length > 0
      Meteor.call("upsertEducators", educators)

  exportFacilityRoles = ->
    educators = Educators.find({
      facility_role_salesforce_id: "",
      contact_salesforce_id: { $ne: "" },
      facility_salesforce_id: { $ne: "" },
    }).fetch()
    if educators.length > 0
      console.log "EXPORTING FACILITY ROLES"
      Meteor.call("exportFacilityRoles", educators)

  updateEducatorRecords = ->
    educators = Educators.find({
      needs_update: true
    }).fetch()
    if educators.length > 0
      Meteor.call "upsertEducators", educators
      Meteor.call "updateFacilityRoles", educators

  importFacilities = ->
    console.log "IMPORTING FACILITIES"
    Meteor.call "importFacilities"

  importEducators = ->
    console.log "IMPORTING THE EDUCATORS"
    Meteor.call "importEducators"

  # Meteor.setInterval importEducators, 100000
  # Meteor.setInterval importFacilities, 100000
  Meteor.setInterval exportFacilityRoles, 10000
  Meteor.setInterval exportNurseEducators, 10000
  Meteor.setInterval updateEducatorRecords, 10000
