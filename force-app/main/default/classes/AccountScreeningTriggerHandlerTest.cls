@isTest
private class AccountScreeningTriggerHandlerTest {
    
    @TestSetup
    static void createData(){
        ShGl_TestFactoryHelper.insertTriggerControls();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Name = 'System Administrator', Disable_Opportunity_Validation_Rules__c = TRUE, Disable_SBQQ_Quote_Triggers__c = true,  Disable_Account_Triggers__c = true );
        insert disableLogic;
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);        
        act.RecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        insert act;
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
		act1.name = 'TestCallout';        
        act1.RecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        insert act1;

        opportunity oppr = TestDataFactory.getOpportunity(act);
        oppr.Name='testing DIEtestsalesforce 4/6/2015';
        oppr.partner_lookup__c=act.id;
        oppr.Installation_Assigned_To__c ='FE Install';
        insert oppr;
        
        
        
        Order od2 = new Order();
        od2.AccountId = act.Id;
        od2.OpportunityId =oppr.Id;
        od2.EffectiveDate = Date.Today();
        od2.Order_Status__c = 'Pending';
        od2.Status = 'Draft';
        od2.ShippingStreet ='Test Street';
        od2.ShippingCity ='Test City';
        od2.ShippingState ='California';
        od2.ShippingCountry ='United States';
        od2.ShippingPostalcode ='94820';
        od2.Shipping_Address_Label__c = null;
        insert od2;
        
        Account_Screening__c acctscr = new Account_Screening__c();
        acctscr.Name = act.Name;
        acctscr.Screening_Eligibility__c =true;
        acctscr.Screening_Action__c ='Start';
        acctscr.Screening_Action_Status__c ='Ready';
        acctscr.Account__c = act.Id;
        acctscr.Unique_Parent_Id__c = act.Id;
        insert acctscr;
        
         Account_Screening__c acctscr1 = new Account_Screening__c();
        acctscr1.Name = 'TestCallout';
        acctscr1.Screening_Action__c ='Stop';
        acctscr1.Screening_Action_Status__c ='Ready';
        acctscr1.GTC_Screen_Status_Message__c = 'test1';
        acctscr1.Account__c = act1.Id;
        acctscr1.Unique_Parent_Id__c = act1.Id;
        insert acctscr1;
        system.debug('acctscr1 is ' + acctscr1);
        
        
        
    }
    
    @isTest
    Static void accountScreeningUpdateLogicTest(){
        Account_Screening__c ascr =[select id,Account__c from Account_Screening__c limit 1];
        order orderRec = [select id,AccountId,Order_Status__c from Order limit 1];
        orderRec.Order_Status__c ='Pending';
        orderRec.Hold_Code__c ='';
        update orderRec;
        ascr.GTC_Screen_Status__c ='Denied Party List';
        update ascr;
        System.assertEquals(1,[Select count() from order where order_Status__c ='On Hold']);    
        
        
    }  
    
    @isTest
    Static void doCalloutIfGTCPassedForFreeTrialTest(){
        
        Account_Screening__c ascr =[select id,name,Screening_Action__c,Screening_Action_Status__c,GTC_Screen_Status_Message__c,Account__c from Account_Screening__c where name = 'TestCallout' LIMIT 1];
       system.debug('ascr is #### ' + ascr);
        ascr.Screening_Action__c = 'Start';
        ascr.Screening_Action_Status__c = 'Sent';
        ascr.GTC_Screen_Status_Message__c = 'Screening Complete';
        update ascr;
    }  
    
    
}