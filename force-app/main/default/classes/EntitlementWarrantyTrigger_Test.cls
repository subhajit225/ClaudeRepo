@isTest
public class EntitlementWarrantyTrigger_Test {
    @testSetup static void setup(){
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        insert act;
        
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Product_Subtype__c = 'GO';
        insert prdHW;
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;
        
        Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prdHW.Id;
        insert ast;
        
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Amount = 100;
        opportunityObj.OppSubscriptionTermMonths__c = 12;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        system.debug('opportunityObj is ####### ' + opportunityObj);
        insert opportunityObj;
        
        Entitlement secondEnt = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        secondEnt.AccountId = act.Id;
        secondEnt.StartDate = Date.today().addDays(-365);
        secondEnt.EndDate = Date.today().addDays(365);
        secondEnt.AssetId = ast.Id;
        secondEnt.Renewable__c = true;
        secondEnt.Type = 'Phone Support';
        secondEnt.Name = 'EntitlementTriggerHelper';
        secondEnt.Product__c = prdHW.Id;
        secondEnt.Refreshed_Opportunity_Link__c = opportunityObj.Id;
        //secondEnt.ServiceContractId = serviceContract.Id;
        
        Entitlement_Warranty_Details__c ew = new Entitlement_Warranty_Details__c();
        ew.Entitlement__c = secondEnt.Id;
        insert ew;
        
        
        
        
    }
    
    
    static testMethod void testDeleteEntWarranty(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [Select Id from Profile where Name = 'Rubrik Light Administrator'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='Entitlement_Warranty_Access'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US',profileId = p.id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        
        insert u;
        PermissionSetAssignment psa = new PermissionSetAssignment
            (AssigneeId = u.id, PermissionSetId = ps.Id);
        insert psa;                  
        System.runAs(u) {
            try{
                Entitlement_Warranty_Details__c ewt = [SELECT Id FROM Entitlement_Warranty_Details__c LIMIT 1];
                system.debug('Entitlement Warranty Detail are #### ' + ewt);
                ContentVersion contentVersion = new ContentVersion(
                    Title = 'Penguins',
                    PathOnClient = 'Penguins.jpg',
                    VersionData = Blob.valueOf('Test Content'),
                    IsMajorVersion = true
                );
                insert contentVersion;    
                List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
                ContentDocument cd = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
                Delete cd;
                //Delete ewt;
            }catch(Exception e){
            }
        }
    }
    
    static testMethod void testDeleteEntWarrantyTwo(){
         try{
         Entitlement_Warranty_Details__c ewt = [SELECT Id FROM Entitlement_Warranty_Details__c LIMIT 1];
         Delete ewt; 
         }catch(Exception e){
             
         }
        
    }
    
    
    
}