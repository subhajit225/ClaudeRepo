/**
 * Test class for click-thru email alert
 * Author: Vartika Shinde
**/

@isTest
public class OppEmailTriggerHandlerTest {
   
    
    @isTest
    private static void testsentEmailOnOppStage3() {    
        Id AccPartnerRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        insert settingDisable;
        Account DistAcct = new Account(Name='testDistributer', Account_Deal_Desk_Notes__c = 'Test Notes', RecordTypeId = AccPartnerRTId);     
        Insert DistAcct;
        
        Account acct = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes', Distributor__c = DistAcct.Id);
        Insert acct;
        
        Account partnerAcct = new Account(Name='testAccount1', Account_Deal_Desk_Notes__c = 'Test Notes', Distributor__c = DistAcct.Id, Contract_Status__c = 'Signed-Active');
        insert partnerAcct;
        
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
        //insert oppr0;
        
        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        oppr.AccountId = acct.Id;
        oppr.Opportunity_Program__c = 'Conversion';
        oppr.Distributor_Lookup__c = DistAcct.Id;
        //oppr.Cloud_Partner_Led_Activity__c = 'Yes';
        //oppr.Partner_Lookup__c = partnerAcct.Id;
        oppr.StageName = '1 Discovery';
        oppr.Business_Unit__c = 'Rubrik';
        oppr.Click_Thru_Contact_Email__c = 'testabc@test.com';
        insert oppr;
        
        Test.startTest();
        try{
            TriggerManager.resetTriggerCounter('Opportunity');
            oppr.StageName = '3 Technical Validation';
            update oppr;
            TriggerManager.resetTriggerCounter('Opportunity');
            oppr.Resend_Click_Through_Email__c = true;
            update oppr;
        }catch(Exception e){
            system.debug('@@ Exception e '+e.getMessage()+' at line '+e.getLineNumber());
        }
        Test.stopTest();
        Opportunity op =[select id,Click_Through_Email_Sent__c from Opportunity where Id=:oppr.Id];
        //System.assertEquals(true, op.Click_Through_Email_Sent__c, 'Working correct');
    }

    //SAL24-443
    @isTest
    private static void testsendTradeUpEmail() {    
        //Id AccPartnerRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        Opportunity oppo = new opportunity();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Disable_Opportunity_Validation_Rules__c = true;
            insert settingDisable;
            //TriggerControls.disableQuoteTrigger = true;
            //TriggerControls.disableQuoteLineTrigger = true;
            Account acc = new Account(Name = 'Test Account');
            insert acc; 
            
            oppo.StageName = '1 Discovery';
            oppo.closeDate = System.Today() + 30;
            oppo.AccountId = acc.Id;
            oppo.Name = 'Test oppo';
            oppo.SOW_Required__c = true;
            oppo.OwnerId = listUser[0].Id;
            oppo.Click_Thru_Contact_Email__c = 'testabc@test.com';
            insert oppo;
            System.assert(oppo.Id != null);
            SBQQ__Quote__c sd = new SBQQ__Quote__c();
            sd.SBQQ__Opportunity2__c =oppo.Id;
            sd.SBQQ__Account__c = acc.Id;
            sd.sendSOWNotification__c = false;
            sd.SBQQ__Type__c = 'Renewal';
            sd.Task_Products__c='RBK-DISK-RETENTION';
            sd.LoD_refreshed_to_Subscription_Deal__c = true;//khushboo
            sd.SBQQ__Primary__c =true;
            sd.SBQQ__Status__c = 'Draft';
            sd.Trade_Up_Amounts__c = 1000;
            insert sd;
            Test.startTest();
                TriggerManager.resetTriggerCounter('Opportunity');
                oppo.SBQQ__PrimaryQuote__c = sd.Id;
                oppo.StageName = '5 Negotiate & Close';
                oppo.Accept_Conditions__c = true;  
                update oppo;
                TriggerManager.resetTriggerCounter('Opportunity');
                oppo.Resend_PDF_Addendum_Email__c = true;
                update oppo;
            Test.stopTest();
        }
        
        Opportunity op =[select id,PDF_Addendum_Email_Sent__c from Opportunity where Id=:oppo.Id];
        System.assertEquals(true, op.PDF_Addendum_Email_Sent__c, 'Matched');
    }
        @isTest
    private static void testsunsumedChurnEmail() {    
        //Id AccPartnerRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        Opportunity oppo = new opportunity();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Disable_Opportunity_Validation_Rules__c = true;
            insert settingDisable;
            //TriggerControls.disableQuoteTrigger = true;
            //TriggerControls.disableQuoteLineTrigger = true;
            Account acc = new Account(Name = 'Test Account',Renewal_Owner__c=listUser[0].Id);
            insert acc; 
            
            oppo.StageName = '1 Discovery';
            oppo.closeDate = System.Today() + 30;
            oppo.AccountId = acc.Id;
            oppo.Name = 'Test oppo';
            oppo.SOW_Required__c = true;
            oppo.OwnerId = listUser[0].Id;
            oppo.Click_Thru_Contact_Email__c = 'testabc@test.com';
            oppo.Opportunity_Type__c = 'New Customer';
            oppo.opportunity_sub_type__c = 'Regular';
            insert oppo;
            System.assert(oppo.Id != null);
            SBQQ__Quote__c sd = new SBQQ__Quote__c();
            sd.SBQQ__Opportunity2__c =oppo.Id;
            sd.SBQQ__Account__c = acc.Id;
            sd.sendSOWNotification__c = false;
            sd.SBQQ__Type__c = 'Renewal+Expansion';
            sd.Task_Products__c='RBK-DISK-RETENTION';
            sd.SBQQ__Primary__c =true;
            sd.LoD_refreshed_to_Subscription_Deal__c = true;//khushboo
            sd.SBQQ__Status__c = 'Draft';
            sd.Trade_Up_Amounts__c = 1000;
            insert sd;
            Test.startTest();
                TriggerManager.resetTriggerCounter('Opportunity');
                oppo.SBQQ__PrimaryQuote__c = sd.Id;
                oppo.StageName = '6 PO With Channel';
                oppo.Subsumed_Renewal_Churn_ACV__c = 200;
                
                update oppo;
            Test.stopTest();
        }
     
    }
     
    /* SAL26-549: Commented
    @isTest
    private static void testsendEmailOppRequiresUCLScaleFuture() {    
        //Id AccPartnerRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 4);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        Opportunity oppo = new opportunity();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Disable_Opportunity_Validation_Rules__c = true;
            insert settingDisable;
            //TriggerControls.disableQuoteTrigger = true;
            //TriggerControls.disableQuoteLineTrigger = true;
            Account acc = new Account(Name = 'Test Account',Renewal_Owner__c=listUser[0].Id);
            insert acc; 

            Id pricebookId = Test.getStandardPricebookId();
            oppo.StageName = '1 Discovery';
            oppo.closeDate = System.Today() + 30;
            oppo.AccountId = acc.Id;
            oppo.Name = 'Test oppo';
            oppo.SOW_Required__c = true;
            oppo.OwnerId = listUser[0].Id;
            oppo.Click_Thru_Contact_Email__c = 'testabc@test.com';
            oppo.Opportunity_Type__c = 'New Customer';
            oppo.opportunity_sub_type__c = 'Regular';
            oppo.Rubrik_Sales_Engineer__c = listUser[2].Id;
          //  oppo.Pricebook2Id = pricebookId;
            insert oppo;
            
            
        /*    Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'RS-BT-BE-SC-PE-PA',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
            Product2 prd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap); 
            prd.License_Type__c = 'Perpetual';
        	prd.Product_Subtype__c = 'E1000';
            insert prd;
            
            List<PricebookEntry> pBList = new List<PricebookEntry>();
            PricebookEntry pbeHW = new PricebookEntry();
            pbeHW.Pricebook2Id = pricebookId;
            pbeHW.Product2Id = prd.Id;
            pbeHW.UnitPrice = 1000;
            pbeHW.IsActive = true;
            pBList.add(pbeHW);
            insert pBList;
            
            opportunitylineitem oli = new opportunitylineitem(pricebookentryid=pBList[0].Id,opportunityId=oppo.Id,unitprice = 200, quantity = 1);
            flowcontroll.opportunityLineItemHandler = false;
            insert oli;*
            System.assert(oppo.Id != null);
            
            Test.startTest();
                TriggerManager.resetTriggerCounter('Opportunity');
                oppo.Rubrik_Sales_Engineer__c = listUser[3].Id;
                update oppo;
            	OppEmailTriggerHandler.getProductListUrl(oppo.Id);
            	OppEmailTriggerHandler.getEmailBody(oppo);
            Test.stopTest();
        }
     
    }*/
}