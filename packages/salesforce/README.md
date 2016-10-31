
# ( modifications )
Defining SF_LOGIN_URL in settings.json allows the user to login to https://test.salesforce.com or https://login.salesforce.com as desired ( allowing for testing using sandboxes ).

# Salesforce for Meteor (via JSforce)

This package is a slim wrapper for the awesome JSforce npm package.

We expose a global `Salesforce` object on the client and server which is a standard JSforce connection object.
Check the [JSforce documentation](https://jsforce.github.io/document/#query)

Two methods `login` and `query` are wrapped server-side in Fibers to work synchronously without callbacks.


## Usage
    // server-side, no callbacks needed

    Salesforce.login(user, pass, token); // gather these from Salesforce


    var query = "SELECT Id,Name FROM Lead";
    var result = Salesforce.query(query);


    var results = Salesforce.findAndExecute('Contact',{Email: {$in: ['billybob@bobmail.com']}}, 'Id, Email, AccountId');

    var userInfo = Salesforce.authorize('<some_code_from_oauth2_flow>');
