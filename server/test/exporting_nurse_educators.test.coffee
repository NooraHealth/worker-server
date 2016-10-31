{ Factory } = require 'meteor/dburles:factory'
{ Educators } = require '../../imports/api/collections/educators.coffee'
{ Facilities } = require '../../imports/api/collections/facilities.coffee'
{ chai } = require 'meteor/practicalmeteor:chai'
faker = require 'faker'

should = chai.should()

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
  facility_name: ()-> facilityOne.name
  facility_salesforce_id: ()-> facilityOne.salesforce_id
}

Factory.define "facility", Facilities
Factory.create "facility", facilityOne
Factory.create "facility", facilityTwo

describe "exporting nurse educators to salesforce", ->
  before ->
    console.log "BEFOREALL"

  it "should pass the first test", ->
    (true).should.equal(true)
