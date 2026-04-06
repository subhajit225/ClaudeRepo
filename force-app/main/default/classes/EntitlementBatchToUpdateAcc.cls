/* 
 * This Batch is used to update Account records on Entitlement whose Product subtyppe is 'FEDRAMP'
 * Test Class ----- EntitlementQueueableToUpdateAccTest
 * This Batch is called from EntitlementSchedulerToUpdateAcc Schedular Class 
*/

public class EntitlementBatchToUpdateAcc implements Database.Batchable<sObject> {
    public String us_product_types = System.Label.Account_us_citizen_products;
    public List<Id> accountWithActiveEnt = new List<Id>();
    
    public Database.QueryLocator start(Database.BatchableContext context) {
         // Query for Entitlements meeting the criteria
        String query = 'SELECT AccountId, Account.US_Federal_Account__c, Product__r.Product_Subtype__c, Account.RSC_G_Support__c, Status, Account.U_S_citizen_service__c, Product__r.Product_Type__c FROM Entitlement WHERE ((Product__r.Product_Subtype__c = \'FEDRAMP\' AND Account.RSC_G_Support__c excludes(\'RSC-G\')) OR (Product__r.Product_Type__c =: us_product_types))';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<Entitlement> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        // Collect Account records to update
        for (Entitlement ent : scope) {
            if(!accountsToUpdateMap.containskey(ent.AccountId)){
                accountsToUpdateMap.put(ent.AccountId, ent.Account);
            }
            Account acc = accountsToUpdateMap.get(ent.AccountId);
            List<String> accountRSCValues = acc.RSC_G_Support__c == null? new List<String>() : acc.RSC_G_Support__c.split(';');
            List<String> accountUSCitizenValues = acc.U_S_citizen_service__c == null? new List<String>() : acc.U_S_citizen_service__c.split(';');
            if(ent.Product__r.Product_Subtype__c == 'FEDRAMP' && !accountRSCValues.contains('RSC-G')){
                acc.RSC_G_Support__c = acc.RSC_G_Support__c == null? 'RSC-G': acc.RSC_G_Support__c+';RSC-G';
                acc.US_Federal_Account__c = true;
            }
            if(ent.status == 'Active'){
                if(us_product_types.equalsIgnoreCase(ent.Product__r.Product_Type__c) && !accountUSCitizenValues.contains('Purchased')){
                acc.U_S_citizen_service__c = acc.U_S_citizen_service__c == null? 'Purchased': acc.U_S_citizen_service__c+';Purchased';
                } 
                accountWithActiveEnt.add(acc.Id);
            }
            if(!accountWithActiveEnt.contains(acc.Id) && us_product_types.equalsIgnoreCase(ent.Product__r.Product_Type__c) && accountUSCitizenValues.contains('Purchased') && ent.status != 'Active'){
                accountUSCitizenValues.remove(accountUSCitizenValues.indexOf('Purchased'));
                acc.U_S_citizen_service__c = String.join(accountUSCitizenValues, ';');
            }
            accountsToUpdateMap.put(acc.Id, acc);
        }
        
        // Update only if there are records to update
        accountsToUpdate = accountsToUpdateMap.values();
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext context) {}
}