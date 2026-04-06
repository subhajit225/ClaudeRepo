@isTest
public class PDM_PricebookEntryDumpTest {
    
    testMethod static void PDM_PricebookEntryDumpTest1() {
    
       
        
        Product2 prdHW = new product2(Name='Standalone',Product_Master_Id__c = '12732137hdhdjj8',IsActive = true);
        //Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        insert prdHW;
        Pricebook2 customPB = new Pricebook2(Name='CPQ Pricebook', isActive=true);
        insert customPB;
        
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        pBList.add(new PricebookEntry( 
        Product2Id = prdHW.Id,
        IsActive = true,
        Pricebook2Id = Test.getStandardPricebookId(),
        UnitPrice = 100));
        
        
        pBList.add(new PricebookEntry( 
        Product2Id = prdHW.Id,
        IsActive = true,
        Pricebook2Id = customPB.id,
        UnitPrice = 100));
        
        //pBList.add(pbeHW);
        
        //PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        //pbeSubs.Product2Id = prdSubs.Id;
        //pBList.add(pbeSubs);
        insert pBList;
        
        
        List < PDM_PricebookEntry_Dump__c > pfList = new List < PDM_PricebookEntry_Dump__c >();
        
        pfList.add(new PDM_PricebookEntry_Dump__c(List_Price__c=100,List_Price_Status__c=true,Product_Code__c='Standalone'));
        //pfList.add(new PDM_PricebookEntry_Dump__c(List_Price__c=100,List_Price_Status__c=true,Product_Code__c='Subscription'));
        
        insert pfList;
        
        pfList[0].List_Price__c = 50;
        pfList[0].List_Price_Status__c = false;
        update pfList;
    
    }
    
}