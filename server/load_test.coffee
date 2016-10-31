{ Factory } = require 'meteor/dburles:factory'
{ Educators } = require '../imports/api/collections/educators.coffee'
{ Facilities } = require '../imports/api/collections/facilities.coffee'
{ generateUniqueId } = require './uniqueIdGen.coffee'
faker = require 'faker'

facilityOne = {
  name: "Testing 3",
  salesforce_id: "a0f11000004zQ4AAAU",
  delivery_partner: "0011100001J1IGNAA3"
}

facilityTwo = {
  name: "testing 1",
  salesforce_id: "a0f11000004zQ45AAE",
  delivery_partner: "0011100001J1IGIAA3"
}

Factory.define "educator", Educators, {
  first_name: ()-> faker.name.firstName()
  last_name: ()-> faker.name.lastName()
  department: ()-> faker.lorem.words()
  phone: ()-> faker.random.number()
}

Factory.define "facility", Facilities

LoadTest = ( numEducators )->
  console.log "LOAD TESTING #{numEducators}"
  Educators.remove({})
  Facilities.remove({})

  first = Factory.create "facility", facilityOne
  second = Factory.create "facility", facilityTwo

  i = 0
  while i < numEducators
    if i < numEducators/2
      facility = first
    else
      facility = second
    educator = Factory.build "educator"
    educator.uniqueId = generateUniqueId( facility.name )
    educator.facility_name = facility.name
    educator.facility_salesforce_id = facility.salesforce_id
    Factory.create "educator", educator
    i++

  console.log Educators.find({}).fetch()
module.exports.LoadTest = LoadTest
