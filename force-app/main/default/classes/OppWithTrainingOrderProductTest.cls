@isTest
public class OppWithTrainingOrderProductTest { 
    
    @testSetup static void setup(){
         Account acc = TestDataFactory.getAccount();
        insert acc;
                
        Product2 prod2 = new Product2();
            prod2.Name= 'RBK-SVC-TRN-01';
            prod2.Product_Type__c ='Training';
            prod2.IsActive=true;
        insert prod2;
        
        PricebookEntry pe =new PricebookEntry();
          pe.IsActive= true;
          pe.UnitPrice= 22.00;
            pe.Pricebook2Id= Test.getStandardPricebookId();
            pe.Product2Id= prod2.id;
          pe.UseStandardPrice = False;
          pe.IsActive= True;
        insert pe;

         order odr = new order();
            odr.AccountId = acc.Id;
            odr.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order').getRecordTypeId();
            odr.EffectiveDate = System.today();
          odr.Pricebook2Id= Test.getStandardPricebookId();
            odr.Status = 'Draft';
        Insert odr;
        
        OrderItem ordItm = new OrderItem();        
            ordItm.OrderId = odr.Id;
            ordItm.UnitPrice= 22.00;
            ordItm.Quantity= 10;
          ordItm.PricebookEntryId = pe.id; 
        insert ordItm;
    }
    
    public static testmethod void test1(){
        list<id> oiList = new list<id>();
         order odi = [Select id from order LIMIT 1];
        
        Test.startTest();
            oiList.add(odi.Id);
            OppWithTrainingOrderProduct.relatedOpp(oiList);
        Test.stopTest();
        
    }
    
  
}