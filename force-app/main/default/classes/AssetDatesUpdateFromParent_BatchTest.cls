@isTest
public with sharing class AssetDatesUpdateFromParent_BatchTest {
    @IsTest
    static void testAccountUpdate(){

        insert new TriggerControl__c(Name='Asset', DisableTrigger__c=false);
        
        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );

        insert acct;

        Product2 prod = new Product2(
                Name = 'X-0001',
                ProductCode = 'X-0001',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            );
        insert prod;

        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), Premium_Support_End_Date__c = System.today().addYears(1),SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = prod.Id, Accountid = acct.Id),
            new Asset(Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today().addDays(1), Premium_Support_End_Date__c = System.today().addYears(1).addDays(1), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = prod.Id, Accountid = acct.Id)

        };
        insert assets;

        assets[0].ParentId = assets[1].Id;
        update assets[0];
        
        Test.startTest();
        AssetDatesUpdateFromParent_Batch ob = new AssetDatesUpdateFromParent_Batch();
        Database.executeBatch(ob, 100);
        Test.stopTest();
        Asset ast = [Select Id, Support_Start_Date__c, Premium_Support_End_Date__c from Asset where Name = 'SN1'];
        System.assertEquals(assets[1].Support_Start_Date__c, ast.Support_Start_Date__c);
        System.assertEquals(assets[1].Premium_Support_End_Date__c, ast.Premium_Support_End_Date__c);
    }
}