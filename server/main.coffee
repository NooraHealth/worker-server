{ Meteor } = require 'meteor/meteor';
{ SalesforceInterface } = require './methods.coffee';
{ Educators } = require '../imports/api/collections/educators.coffee'
{ Facilities } = require '../imports/api/collections/facilities.coffee'
{ ConditionOperations } = require '../imports/api/collections/condition_operations.coffee'

{ LoadTest } = require './load_test.coffee'

Meteor.startup ()->
  # LoadTest(20)
  result = Salesforce.login Meteor.settings.SF_USER, Meteor.settings.SF_PASS, Meteor.settings.SF_TOKEN

  exportToSalesforce = ( educator )->
    console.log "about to export to salesforce"
    promise = SalesforceInterface.upsertEducator(educator)
    promise.then((salesforceId )->
      educator.contact_salesforce_id = salesforceId
      Educators.update { uniqueId: educator.uniqueId }, {$set: educator }
      return SalesforceInterface.exportFacilityRole educator
    ).then(( facilityRoleSalesforceId )->
      educator.facility_role_salesforce_id = facilityRoleSalesforceId
      educator.needs_update = false
      Educators.update { uniqueId: educator.uniqueId }, {$set: educator }
      console.log "Success exporting " + educator.first_name
    ,(err) ->
      console.log "error upserting educators"
      console.log err
    )

  updateInSalesforce = ( educator )->
    promise = SalesforceInterface.upsertEducator(educator)
    promise.then((salesforceId )->
      educator.contact_salesforce_id = salesforceId
      Educators.update { uniqueId: educator.uniqueId }, {$set: educator }
      return SalesforceInterface.updateFacilityRole educator
    ).then(( facilityRoleSalesforceId )->
      educator.facility_role_salesforce_id = facilityRoleSalesforceId
      educator.needs_update = false
      Educators.update { uniqueId: educator.uniqueId }, {$set: educator }
      console.log "Success updating " + educator.first_name
    ,(err) ->
      console.log "error upserting educators"
      console.log err
    )

  exportNurseEducators = ->
    educators = Educators.find( {
      $or: [
        { contact_salesforce_id: "" },
        { contact_salesforce_id: undefined }
      ],
      needs_update: true
    }).fetch()
    console.log educators
    # console.log Educators.find({contact_salesforce_id: ""}).fetch()
    if educators.length > 0
      for educator in educators
        exportToSalesforce(educator)

  updateEducatorRecords = ->
    educators = Educators.find({
      needs_update: true
      $and: [
        { contact_salesforce_id: {$ne: ""} }
        { contact_salesforce_id: {$ne: undefined}}
      ]
    }).fetch()
    if educators.length > 0
      for educator in educators
        updateInSalesforce( educator )

  importFacilities = ->
    console.log "IMPORTING FACILITIES"
    Meteor.call "importFacilities"

  importConditionOperations = ->
    console.log "IMPORTING CONDITION OPERATIONS"
    Meteor.call "importConditionOperations"

  importEducators = ->
    console.log "IMPORTING THE EDUCATORS"
    Meteor.call "importEducators"

  console.log "Check 4"
  # importConditionOperations()
  # Meteor.setInterval importEducators, 100000
  # Meteor.setInterval importFacilities, 100000
  # Meteor.setInterval importConditionOperations, 100000
  # Meteor.setInterval exportFacilityRoles, 10000
  Meteor.setInterval exportNurseEducators, 10000
  Meteor.setInterval updateEducatorRecords, 10000
