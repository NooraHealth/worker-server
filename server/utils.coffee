
module.exports.isInt = ( val )->
  return not isNaN( parseInt(val) )

module.exports.getRoleName = ( educator )->
  return "Educator Trainee -- #{ educator.first_name } #{ educator.last_name }"

module.exports.getOperationRoleName = ( educator )->
  return "Nurse Educator -- #{ educator.first_name } #{ educator.last_name }"
