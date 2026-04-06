/********************************************************************************************************
* Name              : DownloadControllerTests 
* Purpose           : DownloadControllerTests is Used for Testing DownloadController Class
*********************************************************************************************************/
@IsTest
public class DownloadControllerTests{

    static testMethod void test_DownloadController() {
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
         Map<String, Object> prodMap = new Map<String, Object> {
            'Name' => 'Premium Support 1-Yr Prepaid, r304',
            'IsActive' => true,
            'Release_Product_Types__c' => 'Air;Edge',
            'ProductCode' => 'RBK-SVC-PREM-R304'
        };
        Product2 prod1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
        insert prod1;
        
        Map<String, Object> EntMap = new Map<String, Object> {
            'Name' => 'Test1',
            'AccountId' => act.Id,
            'StartDate' => Date.valueof(System.now().addDays(-2)),
            'Product__c' => prod1.Id,
            'EndDate' => Date.valueof(System.now().addDays(2))
        };
        
         List<Entitlement> entList = new List<Entitlement>(); 
        
       DownloadController rl = new DownloadController();
        
        rl.acctId =act.id;
        
        Entitlement Ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), EntMap);
        entList.add(Ent);
        insert entList;
        
        DownloadController.entList=entList;
        
        rl.getReleaseVDocs();
        rl.getUserReleases();
        rl.getEntitlements();
        rl.getReleaseVersions();
        rl.getReleaseDocs();
        rl.getReleaseSoftwareV();
        rl.getReleaseProductType();
    }
    
}