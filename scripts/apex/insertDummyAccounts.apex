List<Account> accounts = new List<Account>();

accounts.add(new Account(
    Name = 'Pinnacle Solutions Group',
    Industry = 'Technology',
    Phone = '(415) 555-8234',
    BillingCity = 'San Francisco',
    BillingState = 'California',
    BillingCountry = 'United States',
    Website = 'https://www.pinnaclesolutionsgroup.com',
    AnnualRevenue = 12500000,
    NumberOfEmployees = 340
));

accounts.add(new Account(
    Name = 'Meridian Healthcare Partners',
    Industry = 'Healthcare',
    Phone = '(312) 555-4791',
    BillingCity = 'Chicago',
    BillingState = 'Illinois',
    BillingCountry = 'United States',
    Website = 'https://www.meridianhcp.com',
    AnnualRevenue = 8750000,
    NumberOfEmployees = 185
));

insert accounts;

for (Account acc : accounts) {
    System.debug('Inserted Account: ' + acc.Name + ' | Id: ' + acc.Id);
}
