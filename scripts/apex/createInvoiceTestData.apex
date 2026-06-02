Account customer = new Account(
    Name = 'Acme Corporation',
    Industry = 'Technology'
);
insert customer;

Opportunity opp = new Opportunity(
    Name = 'Acme Q2 Services',
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(45),
    Amount = 25000,
    AccountId = customer.Id
);
insert opp;

System.debug('Test Account Id: ' + customer.Id);
System.debug('Test Opportunity Id: ' + opp.Id);
System.debug('Open the Opportunity and use Generate Invoice quick action.');
