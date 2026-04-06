global class OpportunityCohesityDealBatch implements Database.Batchable<sObject>{
    
    global database.QueryLocator start(Database.BatchableContext bc){
        date triggerDate = System.Today().addDays(1);
        String query = 'Select Id ,Next_Step__c,Primary_Competitor__c,Other_Primary_Competitor__c,Win_Loss_Comments__c,Cohesity_Deal__c from opportunity where LastModifiedDate = LAST_N_DAYS:1';
        system.debug('String query  =='+query );
        return database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Opportunity> scope){
        try{
            // system.debug('String scope  =='+ scope );
            if(!scope.isEmpty()){
                Boolean status = OpportunityCohesityDeal.CheckCohesityDeal(scope);
            }            
        }catch(Exception ex){
            system.debug('***OpportunityCohesityDealBatch Exception****'+ex.getMessage());
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}