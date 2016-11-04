{ Educators } = require "../imports/api/collections/educators.coffee"
{ Facilities } = require "../imports/api/collections/facilities.coffee"
{ isInt } = require "./utils"
{ getRoleName } = require "./utils"

Meteor.methods

  "importFacilities": ->
    facilities = Meteor.call("fetchFacilitiesFromSalesforce");
    console.log facilities
    for facility in facilities
      if not Facilities.findOne { salesforce_id: facility.Id }
        Facilities.insert { name: facility.Name, salesforce_id: facility.Id, delivery_partner: facility.Delivery_Partner__c }

  "importEducators": ->
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

  "fetchFacilitiesFromSalesforce": ->
    result = Salesforce.query "SELECT Id, Name, Delivery_Partner__c FROM Facility__c"
    return result?.response?.records

  "fetchEducatorsFromSalesforce": ->
    # result = Salesforce.query "SELECT Id, FirstName, LastName, MobilePhone, Department, Trainee_Id__c FROM Contact WHERE Trainee_Id__c != ''"
    result = Salesforce.query "SELECT Id, Contact__c, Contact__r.id,
      Contact__r.MobilePhone, Contact__r.FirstName, Contact__r.LastName, Contact__r.Department,
      Contact__r.Trainee_Id__c, Facility__c, Facility__r.Name, Facility__r.id
      FROM Facility_Role__c WHERE Role_With_Noora_Program__c = 'Trainee'"
    return result?.response?.records

  "exportFacilityRoles": ( educators )->
    mapped = educators.map( (educator) ->
      return {
        educator: educator
        salesforce_role: {
          "Name" : getRoleName(educator)
          "Department__c": educator.department,
          "Facility__c": educator.facility_salesforce_id,
          "Contact__c": educator.contact_salesforce_id
          "Role_With_Noora_Program__c": Meteor.settings.FACILITY_ROLE_TYPE
        }
      }
    )

    callback = Meteor.bindEnvironment ( educator, err, ret ) ->
      if err
        console.log "Error inserting facility role into Salesforce"
        console.log err
      else
        Educators.update { _id: educator._id }, { $set: { facility_role_salesforce_id: ret.id }}

    #insert into the Salesforce database
    for role in mapped
      Salesforce.sobject("Facility_Role__c").create role.salesforce_role, callback.bind(this, role.educator)

  "updateFacilityRoles": ( educators )->
    console.log "UPDATIKNG FACLITIY ROLES"
    mapped = educators.map( (educator) ->
      return {
        educator: educator
        salesforce_role: {
          "Name" : getRoleName(educator)
          "Department__c": educator.department,
          "Id": educator.facility_role_salesforce_id,
          "Role_With_Noora_Program__c": Meteor.settings.FACILITY_ROLE_TYPE,
        }
      }
    )

    callback = Meteor.bindEnvironment ( educator, err, ret ) ->
      if err
        console.log "Error inserting facility role into Salesforce"
        console.log err
      else
        Educators.update { _id: educator._id }, { $set:{ needs_update: false }}

    #insert into the Salesforce database
    for role in mapped
      Salesforce.sobject("Facility_Role__c").update role.salesforce_role, "Id", callback.bind(this, role.educator)

  "upsertEducators": ( educators )->
    mapped = educators.map( (educator) ->
      facility = Facilities.findOne {
        salesforce_id: educator.facility_salesforce_id
      }
      lastName = educator.last_name
      firstName = educator.first_name
      if not lastName or lastName is ""
        lastName = educator.first_name
        firstName = ""

      return {
        educator: educator
        salesforce_contact: {
          "LastName" : lastName,
          "FirstName" : firstName,
          "MobilePhone" : educator.phone,
          "Department" : educator.department,
          "AccountId" : facility.delivery_partner,
          "Trainee_ID__c": educator.uniqueId,
          "RecordTypeId": Meteor.settings.CONTACT_RECORD_TYPE
        }
      }
    )

    callback = Meteor.bindEnvironment ( educator, err, ret ) ->
      if err
        console.log "Error exporting nurse educator"
        console.log err
      else
        salesforce_id = if educator.contact_salesforce_id == "" then ret.id else educator.contact_salesforce_id
        console.log "Success exporting nurseeducator #{salesforce_id}"
        Educators.update { uniqueId: educator.uniqueId }, { $set: { contact_salesforce_id: salesforce_id, needs_update: false }}

    #insert into the Salesforce database
    for educator in mapped
      console.log educator
      Salesforce.sobject("Contact").upsert educator.salesforce_contact, "Trainee_ID__c", callback.bind(this, educator.educator)
