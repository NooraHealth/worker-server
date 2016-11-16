{ Educators } = require "../imports/api/collections/educators.coffee"
{ Facilities } = require "../imports/api/collections/facilities.coffee"
{ ConditionOperations } = require '../imports/api/collections/condition_operations.coffee'
{ isInt } = require "./utils"
{ getRoleName } = require "./utils"
{ getOperationRoleName } = require "./utils"

class SalesforceInterface
  @importFacilities: ->
    facilities = Meteor.call("fetchFacilitiesFromSalesforce");
    console.log facilities
    for facility in facilities
      if not Facilities.findOne { salesforce_id: facility.Id }
        Facilities.insert {
          name: facility.Name,
          salesforce_id: facility.Id,
          delivery_partner: facility.Delivery_Partner__c
        }

  @importConditionOperations: ->
    console.log "Getting condition opeartions"
    operations = Meteor.call("fetchConditionOperationsFromSalesforce");
    console.log operations
    for operation in operations
      if not ConditionOperations.findOne { salesforce_id: operation.Id }
        facility = operation.Facility__r
        ConditionOperations.insert {
          name: operation.Name,
          salesforce_id: operation.Id,
          facility_salesforce_id: operation.Facility__c
          facility_name: facility.Name
        }
        console.log ConditionOperations.find({}).fetch()

  @importEducators: ->
    records = Meteor.call("fetchEducatorsFromSalesforce")
    for record in records
      educator = record.Contact__r
      facility = record.Facility__r
      if not Educators.findOne { uniqueId: educator.Trainee_ID__c }
        console.log "importing educator" + educator.Trainee_ID__c
        phone = if isInt( educator.MobilePhone ) then parseInt(educator.MobilePhone) else null
        Educators.insert {
          last_name: educator.LastName or ""
          first_name: educator.FirstName or ""
          contact_salesforce_id: educator.Id
          department: educator.Department or ""
          salesforce_facility_id: facility.Id
          facility_role_salesforce_id: record.Id
          facility_salesforce_id: facility.Id
          facility_name: facility.Name
          phone: phone or 0
          uniqueId: educator.Trainee_ID__c
        }

  @fetchConditionOperationsFromSalesforce: ->
    console.log "Fetching condition operations"
    result = Salesforce.query "SELECT Id, Name, Facility__c, Facility__r.Name FROM Condition_Operation__c"
    return result?.response?.records

  @fetchFacilitiesFromSalesforce: ->
    result = Salesforce.query "SELECT Id, Name, Delivery_Partner__c FROM Facility__c"
    return result?.response?.records

  @fetchEducatorsFromSalesforce: ->
    # result = Salesforce.query "SELECT Id, FirstName, LastName, MobilePhone, Department, Trainee_Id__c FROM Contact WHERE Trainee_Id__c != ''"
    result = Salesforce.query "SELECT Id, Contact__c, Contact__r.id,
      Contact__r.MobilePhone, Contact__r.FirstName, Contact__r.LastName, Contact__r.Department,
      Contact__r.Trainee_Id__c, Facility__c, Facility__r.Name, Facility__r.id
      FROM Facility_Role__c WHERE Role_With_Noora_Program__c = 'Trainee'"
    return result?.response?.records

  @exportConditionOperationRoles: ( educators )->
    roles = educators.map( (educator) ->
      return educator.condition_operations
    )

    mapped = roles.map ( role )->
      return {
        educator: role.educator
        operation_role: {
          "Name" : getOperationRoleName(educator)
          "Department__c": educator.is_active,
          "Facility__c": educator.facility_salesforce_id,
          "Contact__c": educator.contact_salesforce_id,
          "RecordTypeId": "012j0000000udTH"
        }
      }

    callback = Meteor.bindEnvironment ( educator, err, ret ) ->
      if err
        console.log "Error inserting facility role into Salesforce"
        console.log err
      else
        Educators.update { _id: educator._id }, { $set: { facility_role_salesforce_id: ret.id }}

    #insert into the Salesforce database
    for role in mapped
      Salesforce.sobject("Condition_Operation_Role__c").create role.operation_role, callback.bind(this, role.educator)

  @exportFacilityRole: ( educator )->
    return new Promise (resolve, reject)->
      facilityRole = {
        "Name" : getRoleName(educator)
        "Department__c": educator.department,
        "Facility__c": educator.facility_salesforce_id,
        "Contact__c": educator.contact_salesforce_id
        "Role_With_Noora_Program__c": Meteor.settings.FACILITY_ROLE_TYPE
      }

      callback = Meteor.bindEnvironment ( err, ret ) ->
        if err
          console.log "Error inserting facility role into Salesforce"
          console.log err
          reject(err)
        else
          console.log "success creating facility role #{educator.contact_salesforce_id}"
          Educators.update { _id: educator._id }, { $set: { facility_role_salesforce_id: ret.id }}
          resolve(ret.id)

      #insert into the Salesforce database
      Salesforce.sobject("Facility_Role__c").create facilityRole, callback

  @updateFacilityRole: ( educator )->
    return new Promise (resolve, reject)->
      salesforceRole = {
        "Name" : getRoleName(educator)
        "Department__c": educator.department,
        "Id": educator.facility_role_salesforce_id,
        "Facility__c": educator.facility_salesforce_id,
        "Role_With_Noora_Program__c": Meteor.settings.FACILITY_ROLE_TYPE,
      }
      callback = Meteor.bindEnvironment ( err, ret ) ->
        if err
          console.log "Error inserting facility role into Salesforce"
          console.log err
          reject(err)
        else
          console.log "Success updating facility role"
          # Educators.update { _id: educator._id }, { $set:{ needs_update: false }}
          resolve( educator.facility_role_salesforce_id )

      #insert into the Salesforce database
      Salesforce.sobject("Facility_Role__c").update salesforceRole, "Id", callback

  @upsertEducator: ( educator )->
    return new Promise (resolve, reject)->
      facility = Facilities.findOne {
        salesforce_id: educator.facility_salesforce_id
      }
      lastName = educator.last_name
      firstName = educator.first_name
      if not lastName or lastName is ""
        lastName = educator.first_name
        firstName = ""

      salesforceContact = {
        "LastName" : lastName,
        "FirstName" : firstName,
        "MobilePhone" : educator.phone,
        "Department" : educator.department,
        "AccountId" : facility.delivery_partner,
        "Trainee_ID__c": educator.uniqueId,
        "RecordTypeId": Meteor.settings.CONTACT_RECORD_TYPE
      }

      callback = Meteor.bindEnvironment ( err, ret ) ->
        if err
          console.log "Error exporting nurse educator"
          console.log err
          reject(err)
        else
          salesforceId = ret.id
          if educator.contact_salesforce_id? and educator.contact_salesforce_id != ""
            salesforceId = educator.contact_salesforce_id
          resolve(salesforceId)

      #insert into the Salesforce database
      Salesforce.sobject("Contact").upsert salesforceContact, "Trainee_ID__c", callback

module.exports.SalesforceInterface = SalesforceInterface
