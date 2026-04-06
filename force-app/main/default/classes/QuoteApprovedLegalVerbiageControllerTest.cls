/*
Author : Ashwini Borse
Description : As part of POC implemented under CPQ22-4591
Date : 04/09/2024
*/
@isTest
public with sharing class QuoteApprovedLegalVerbiageControllerTest {
    public static testMethod void testLegalVerbiage(){
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        disableLogic.Name = 'System Administrator';   
        disableLogic.Disable_Opportunity_Validation_Rules__c = TRUE; 

        insert disableLogic;
//insert Account
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='TestAccount', RecordTypeId = partnerRecordTypeId);
        insert acct;
        
//insert Opportunity
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity(Name='Test Legal Verbiage' , Sell_to_Partner__c = acct.Id,  AccountId= acct.Id, StageName = '1 Discovery',
                                            CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', 
                                            Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                            Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                            Identified_Pain__c = 'Test', Champion__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                            Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now', //Alliance_HW_Partner__c = 'Cisco', 
                                            Partner_Representative__c = 'Test');
        insert oppr;
//      

        Id standardPriceBookId = Test.getStandardPricebookId();//pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'Product XY', ProductCode = 'Pro-XY', isActive = true),
            new Product2(Name = 'Product XX', ProductCode = 'Pro-XX', isActive = true),
            new Product2(Name = 'Product RCV', ProductCode = 'Pro-RCV', isActive = true, Product_Type__c = 'Cloud Vault Backup')
        };

        insert lstProducts;

        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true)
        };
        
        insert lstPricebooks;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.Id,
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
           
        insert quote;
        String recId = quote.Id;
                       
   List<Quote_Approved_Legal_Verbiage__mdt > legalList = QuoteApprovedLegalVerbiageController.getData();    
      
    
        Test.startTest();           
          QuoteApprovedLegalVerbiageController.updateQuote(legalList,recId);
        Test.stopTest();
    }
	public static testMethod void testLegalVerbiage2(){
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        disableLogic.Name = 'System Administrator';   
        disableLogic.Disable_Opportunity_Validation_Rules__c = TRUE; 

        insert disableLogic;
//insert Account
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='TestAccount', RecordTypeId = partnerRecordTypeId);
        insert acct;
        
//insert Opportunity
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity(Name='Test Legal Verbiage' , Sell_to_Partner__c = acct.Id,  AccountId= acct.Id, StageName = '1 Discovery',
                                            CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', 
                                            Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                            Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                            Identified_Pain__c = 'Test', Champion__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                            Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now', //Alliance_HW_Partner__c = 'Cisco', 
                                            Partner_Representative__c = 'Test');
        insert oppr;
//      

        Id standardPriceBookId = Test.getStandardPricebookId();//pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'Product XY', ProductCode = 'Pro-XY', isActive = true),
            new Product2(Name = 'Product XX', ProductCode = 'Pro-XX', isActive = true),
            new Product2(Name = 'Product RCV', ProductCode = 'Pro-RCV', isActive = true, Product_Type__c = 'Cloud Vault Backup')
        };

        insert lstProducts;

        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true)
        };
        
        insert lstPricebooks;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acct.Id,
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
           
        insert quote;
        String recId = quote.Id;
                       
   List<Quote_Approved_Legal_Verbiage__mdt > legalList = QuoteApprovedLegalVerbiageController.getData();    
      
    
        Test.startTest();           
          QuoteApprovedLegalVerbiageController.updateQuote(legalList,recId);
        Test.stopTest();
    }
}