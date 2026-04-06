@isTest
public class HoldCodeTrackingHelper_Test {

    @testSetup static void createTestData() {
        
        ShGl_TestFactoryHelper.insertCustomSettings();
        //ShGl_TestFactoryHelper.insertCustomSettings_2();
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.AccountTrigger=false;

        Opportunity oppt = TestDataFactory.getOpportunity();
        oppt.Name ='New mAWS Deal';
        oppt.Type = 'New Customer';
        oppt.Lead_Email_Hidden__c ='test123@test.com';
        Contact testCon = new Contact (LeadSource ='Channel',LastName = 'My Test Contact', AccountId =oppt.AccountId,Email='test1023@test.com',FirstName='Shadab');
        insert testCon;
        insert oppt;
 
    }
    
    
    
    static testMethod void holdCodeLogicTestMethod1() {
        //ShGl_TestFactoryHelper.insertCustomSettings();

        Account acc = [SELECT Id FROM Account limit 1];
        Opportunity opp = [select id,Hold_code__c from Opportunity where name ='New mAWS Deal' LIMIT 1];
        Test.startTest();
        Order ordr = new Order(Type='Revenue' ,  AccountId= acc.Id,OpportunityId =opp.Id,ShippingStreet ='Test Street',
            ShippingCity ='Test City',
            ShippingState ='California',
            ShippingCountry ='United States',
            ShippingPostalcode ='94820',
            EffectiveDate=system.Today(), Order_Status__c = 'Pending' );
       
        insert ordr;
        ordr.Hold_code__c= 'End Customer PO# Missing';
        update ordr;
        HoldCodeTrackingHelper.findDifference(new List<String>{'A', 'B'}, new  List<String>{'A', 'C'});
        HoldCodeTrackingHelper.releaseTrackingRecord(new List<Hold_Off_Tracking__c>{new Hold_Off_Tracking__c()});
        Test.stopTest(); 
    }

    
        
    static testMethod void holdCodeLogicTestMethod2() {
        //ShGl_TestFactoryHelper.insertCustomSettings();
        
        Account acc = [SELECT Id FROM Account limit 1];

        Test.startTest();
            Opportunity opp = [select id,Hold_code__c from Opportunity where name ='New mAWS Deal' LIMIT 1];
            opp.Hold_code__c= 'End Customer PO# Missing;Missing ship to information';
            update opp;

            //system.assertEquals(opp.hold_code__c, 'End Customer PO# Missing');

            Order ordr = new Order(Type='Revenue' ,  AccountId= acc.Id,OpportunityId =opp.Id,ShippingStreet ='Test Street',
                ShippingCity ='Test City',
                ShippingState ='California',
                ShippingCountry ='United States',
                ShippingPostalcode ='94820',
                EffectiveDate=system.Today(), Order_Status__c = 'Pending' );

        insert ordr;
        
        Order od = [ SELECT Id,Hold_Code__c FROM Order where id=:ordr.id LIMIT 1 ];
         od.Hold_code__c= 'End Customer PO# Missing;Missing ship to information';
         
        update od;
        Test.stopTest(); 
    }
      
}