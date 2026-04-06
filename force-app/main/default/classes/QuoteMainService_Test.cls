/********************************************************************************************************
* Name              : QuoteMainService_Test
* Purpose           : QuoteMainService_Test is Used for Testing QuoteMainService Class
*********************************************************************************************************/
@isTest
public class QuoteMainService_Test{
    static testMethod void testActionOnOppty(){
        testDataFactoryClass.createCustomSettings();
        
        Set<id> oppIdSet = new Set<id>();
        
        List<Account> actList = new List<Account>();
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actList.add(act);
        insert actList;
        
        Id standardPBId = test.getStandardPricebookId();
        List<opportunity> oppList =  testDataFactoryClass.createOpporunity(actList);
        oppList[0].Pricebook2Id =standardPBId;
        update oppList;
        for(opportunity opp : oppList){
            oppIdSet.add(opp.id);
        }
        
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.id,TotalPrice=2000,Quantity = 2,OpportunityID = oppList[0].Id);
        insert oppLine;
        
        Test.startTest();
        QuoteMainService.actionOnOppty(oppIdSet);
        Test.stopTest();
        
          
    }
    
    static testMethod void testControls(){
        testDataFactoryClass.createCustomSettings();
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c=true, Bypass_Pricebook_Setting_on_Quote__c=true); 
        Set<id> oppIdSet = new Set<id>();
        Test.startTest();
        QuoteMainService.actionOnOppty(oppIdSet);
        Test.stopTest();
        
          
    }
    
    static testMethod void testActionOnOpptyForException(){
        testDataFactoryClass.createCustomSettings();
        
        Test.startTest();
        try{
            QuoteMainService.actionOnOppty(null);
        }catch(Exception exp){
            System.debug('Exception = '+exp);
        }
        
        Test.stopTest();
        
          
    }
}