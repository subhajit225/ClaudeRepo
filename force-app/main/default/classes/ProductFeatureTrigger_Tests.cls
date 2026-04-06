@isTest
public class ProductFeatureTrigger_Tests {
    
    @testSetup static void setup() {
        Product2 prod = new Product2(Name = 'Laptop X200', 
                                     Family = 'Hardware');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
		
    }


    static testMethod void testUpdatePdmFeature() {
        Product2 prod = [Select Id from product2 where Name = 'Laptop X200'];
        Product_Feature__c pdm = new Product_Feature__c();
        pdm.Product_Code__c = 'Laptop X200';
        try{
            insert pdm;
        }catch(DmlException ex){
            
        }
	    
    }

}