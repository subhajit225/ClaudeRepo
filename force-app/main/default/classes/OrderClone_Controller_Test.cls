@isTest
public class OrderClone_Controller_Test {
    
    public static testMethod void testOrderCloneRecord() {
        
        Map<String, Object>  acMap = new Map<String, Object> {
            'Name' => 'Test',
                'Sync_to_NetSuite__c' => false,
                'ShippingCountryCode' => 'US'
                };
                    
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();     
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), acMap);
        acct.RecordTypeId= devRecordTypeId;
        insert acct;
        Date closeDt = System.Today()+30;
        
        Map<String, Object>  opprMap = new Map<String, Object> {
            'Name'=> 'testing DIEtestsalesforce 4/6/2015' , 
                'AccountId' => acct.Id,
                'StageName' => '4 Business Justification',
                'CloseDate' => closeDt, 
                'Lead_Email_Hidden__c' => '', 
                'partner_lookup__c' => acct.id, 
                'Alliance_Partner_Name__c' => 'Amazon', 
                'Alliance_Source_Type__c' => 'Alliance Initiated Deal', 
                'Installation_Assigned_To__c' => 'FE Install'
                };
        opportunity oppr = (opportunity) ShGl_TestFactory.createSObject(new Opportunity(), opprMap);
        oppr.StageName = '1 Discovery';
        insert oppr;
        
        
        Map<String, Object>  shippingAddressMap = new Map<String, Object> {
            'Account__c' => acct.Id,
                'Name'=>'Test 1',
                'Shipping_State__c' => 'CA',
                'Shipping_Country__c' => 'United States'
                };
        shipping_Address__c sAddr = (shipping_Address__c) ShGl_TestFactory.createSObject(new shipping_Address__c(), shippingAddressMap);
        insert sAddr;
        
        Map<String, Object>  orderMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'OpportunityId' => oppr.Id               
                };
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), orderMap);
        insert ord;
        
        Test.startTest();
        	OrderClone_Controller.createClonedRecord(ord.id);
        Test.stopTest();
    }
}