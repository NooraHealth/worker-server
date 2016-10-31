jsforce = Npm.require('jsforce');
Future = Npm.require('fibers/future');

connection = new jsforce.Connection({ loginUrl: Meteor.settings.SF_LOGIN_URL} );

Salesforce = connection; // export as
Salesforce._login = Meteor.wrapAsync(connection.login, connection);
Salesforce._query = Meteor.wrapAsync(connection.query, connection);
Salesforce._authorize = Meteor.wrapAsync(connection.authorize, connection);
Salesforce._create = Meteor.wrapAsync(connection.create, connection);

/**
 * Wraps async login method to sync
 * @param user
 * @param pass
 * @param token
 * @returns {*}
 */

Salesforce.login = function(username, password, securityToken) {
  var future = new Future();
  var self = this;
  self._login(username, password + securityToken, function(error, response) {
    future.return({error: error, response: response});
  });
  return future.wait();
};

/* Don't need this quite yet...we don't want this to block the client.
Salesforce.create = function(type, records, options) {
  var future = new Future();
  var self = this;

  self._create(type, records, options, function(error, response) {
    if (error) {
      future.return(error);
    } else {
      future.return(response);
    }
  });
  return future.wait();
};*/

Salesforce.findAndExecute = function(type, conditions, fields, options, sort) {
  var future = new Future();
  var self = this;

  var query = Salesforce.sobject(type).find(conditions, fields, options);
  if (sort) {
    query = query.sort(sort);
  }

  var execute = Meteor.wrapAsync(query.execute, query);

  execute(function(error, response) {
     future.return({error: error, response: response});
  });
  return future.wait();
};

/**
 * Sync wrapper for SOQL
 * @param query String
 * @returns {*}
 */
Salesforce.query = function(query) {
  var future = new Future();
  this._query(query, function(error, response) {
    future.return({error: error, response: response});
  });
  return future.wait();
};

Salesforce.authorize = function(code) {
  var future = new Future();
  var self = this;
  self._authorize(code, function(error, response) {
     future.return({error: error, response: response});
  });
  return future.wait();
};
