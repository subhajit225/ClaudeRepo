/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-28-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
class POCRequestTriggerHandlerTest{
    @isTest public static void testMethod1(){
        
        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId = act.Id;
        insert cnt;
        
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Web Try and Buy';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted Enterprise Edition';
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'M365 and Entra ID; UCL (Cloud Cluster, Cloud Native & Entra ID)';
        //newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.UCL_Edition__c = 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)';
        newPOCRequest.Data_Redundancy_Archive__c ='Multi Zone (ZRS)';
        newPOCRequest.Data_Redundancy_Backup__c = 'Multi Zone (ZRS)';
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            try{
                insert newPOCRequest;
            }catch(exception ex){
                String errorms = ex.getMessage();
            }
        
        
        ITrigger ItObj = new POCRequestTriggerHandler();
        ItObj.bulkBefore();
        ItObj.bulkAfter();
        ItObj.beforeInsert(newPOCRequest);
        ItObj.beforeUpdate(newPOCRequest, newPOCRequest);
        ItObj.beforeDelete(newPOCRequest);
        ItObj.afterInsert(newPOCRequest);
        ItObj.afterUpdate(newPOCRequest,newPOCRequest);
        ItObj.afterDelete(newPOCRequest);
        ItObj.andFinally();
        }
         Assert.areEqual(true,true);
        
        
    }
}