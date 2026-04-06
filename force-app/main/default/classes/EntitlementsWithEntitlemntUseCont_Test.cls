@isTest(SeeAllData=true)
public class EntitlementsWithEntitlemntUseCont_Test {
    //for EntitlementsWithEntitlemntUseController
      static testmethod void test_method_one() {
       
        Entitlement_Use__c entuse = [select Id,serial_number__c,entitlement__r.Order_Service_Item__r.Product_Name__c, entitlement__r.StartDate, entitlement__r.EndDate, node__r.asset__r.Name,node__r.serial_number__c, node__r.chassis__r.serial_number__c from Entitlement_Use__c where entitlement__r.Account.name='TOTVS S.A.' LIMIT 1];
        
        List<Entitlement_Use__c> entuseList = new List<Entitlement_Use__c>();
        entuseList.add(entuse);
        
        Test.startTest();
        Test.setCurrentPage(Page.EntitlementsWithNodeAndAsset);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(entuseList);
        stdSetController.setSelected(entuseList);
        EntitlementsWithEntitlemntUseController cont = new EntitlementsWithEntitlemntUseController();
        List<Entitlement_Use__c> entitlementsReturned = cont.getEntitlements();
       // System.assertEquals(1, entitlementsReturned.size());
        System.assertEquals(false, cont.hasNext);
        System.assertEquals(false, cont.hasPrevious);
        cont.next();
        cont.previous();

       
        Test.stopTest();
    }
}