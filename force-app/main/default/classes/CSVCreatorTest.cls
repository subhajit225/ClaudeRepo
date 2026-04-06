@isTest
public class CSVCreatorTest{
    
    @isTest static void testOrderUpdateNetsuitFlag() {
        
        Map<String, Object> acMap = new Map<String, Object>();
        acMap.put('Sync_to_NetSuite__c',false);
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), acMap);
        acct.RecordTypeId= devRecordTypeId;
        insert acct;
        
        Date closeDt = System.Today()+30;
        
        Map<String,Object> opprMap = new Map<String,Object>();
        opprMap.put('Name', 'testing DIEtestsalesforce 4/6/2015');
        opprMap.put('AccountId',acct.Id);
        opprMap.put('StageName','4 Business Justification');
        opprMap.put('CloseDate',closeDt);
        opprMap.put('Lead_Email_Hidden__c','');
        opprMap.put('partner_lookup__c',acct.id);
        opprMap.put('Alliance_Partner_Name__c','Amazon');
        opprMap.put('Alliance_Source_Type__c','Alliance Initiated Deal');
        opprMap.put('Installation_Assigned_To__c','FE Install');
        
        opportunity oppr = (opportunity) ShGl_TestFactory.createSObject(new Opportunity(), opprMap);
        oppr.StageName = '1 Discovery';
        insert oppr;
        
        Map<String,Object> shippingAddressMap = new Map<String,Object>();
        shippingAddressMap.put('Account__c',acct.Id);
        shippingAddressMap.put('Name','Test 1');
        shippingAddressMap.put('Shipping_State__c','CA');
        shippingAddressMap.put('Shipping_Country__c','United States');
        
        shipping_Address__c sAddr = (shipping_Address__c) ShGl_TestFactory.createSObject(new shipping_Address__c(), shippingAddressMap);
        insert sAddr;
        Test.startTest();
        
        Map<String,Object> orderMap = new Map<String,object>();
        orderMap.put('AccountId', acct.Id);
        orderMap.put('OpportunityId',oppr.Id);
        orderMap.put('Shipping_Address_Label__c',saddr.Name);
        
        Order od = (Order) ShGl_TestFactory.createSObject(new Order(), orderMap);
        insert od;
        
        String testStr = 'Order ID,Order Number,Fulfilled in QTR,Current Est Ship Date,Est Delivery Date \n'+od.ID+','+
            '10012,1,10/19/2022,10/25/2022 \n';
        
        CSVCreator.CSVObject obj =  CSVCreator.getCSVObject(testStr);
        
        List<Order> lstOrder = obj.lstOrders ;
        Map<String,List<String>> mapOrder = obj.mapIdValues ;
        
        CSVCreator.saveOrderDetails(lstOrder,mapOrder); 
        
        Test.stopTest();   
        
    }
}