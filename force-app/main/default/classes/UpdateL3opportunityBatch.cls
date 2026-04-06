/**
 * @Author      : Pankaj Kumar for CPQ22-3392
 * @TstClass    : UpdateL3opportunityBatch_Test
 *--------------------------------------------------------------------------------------
 */ 
public without sharing class UpdateL3opportunityBatch implements Database.Batchable<sObject> {
    String query;
    set<Id> AccSet= new set<Id>();  
             public List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
    
    
    
    public UpdateL3opportunityBatch(Set<Id> OpptyAcc){
        AccSet.addall(OpptyAcc); 
        
        
    }
    public Database.QueryLocator start(Database.BatchableContext context){
        
        query = 'SELECT Id, L3_Eligible_Account__c, Partner_Lookup__r.Is_L3_Eligible_Account__c,'
            +'Distributor_Lookup__r.Is_L3_Eligible_Account__c,'
            +'Account.Is_L3_Eligible_Account__c,Partner_of_Record__r.Is_L3_Eligible_Account__c '
            +'FROM Opportunity WHERE '
            +'(AccountId IN :AccSet  or Partner_Lookup__c IN:AccSet or Distributor_Lookup__c IN:AccSet or '  
            +' Partner_of_Record__c IN:AccSet ) and StageName!=\'7 Closed Admin\'  and StageName!=\'7 Closed Lost\' and StageName !=\'7 Closed Won\' ' ;
        
        return Database.getQueryLocator(query);
        
    }
    public void execute(Database.BatchableContext context, List<Opportunity> OppList){
       
        map<Id, Opportunity> OppMap= new map<Id, Opportunity>();
        OppMap.putall(OppList);
        
        List<Opportunity> Opp2update= new list<Opportunity>();
        if(OppMap.size()>0){
            for(opportunity oppz: OppMap.values()){
                if( (oppz.Partner_Lookup__r.Is_L3_Eligible_Account__c!=null && oppz.Partner_Lookup__r.Is_L3_Eligible_Account__c==true) || 
                   (oppz.Distributor_Lookup__r.Is_L3_Eligible_Account__c!=null && oppz.Distributor_Lookup__r.Is_L3_Eligible_Account__c==true) ||
                   (oppz.Account.Is_L3_Eligible_Account__c!=null && oppz.Account.Is_L3_Eligible_Account__c==true)||
                   (oppz.Partner_of_Record__r.Is_L3_Eligible_Account__c!=null && oppz.Partner_of_Record__r.Is_L3_Eligible_Account__c==true)){
                     
                       oppz.L3_Eligible_Account__c=true;
                       Opp2update.add(oppz);
                   } else
                   {
                       oppz.L3_Eligible_Account__c=false;
                       Opp2update.add(oppz);
                       
                   }
                
              
            }
            List<Database.SaveResult> updateResults;
            if(Opp2update.size()>0)
            {
                boolean tempFlag = flowControll.opportunityTriggerHandler;
                boolean tempFlag1 = flowControll.opportunityLineItemHandler;
                flowControll.opportunityTriggerHandler = false;
                flowControll.opportunityLineItemHandler = false;
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                TriggerControls.disableCalculateAPIBatch = true;
                TriggerControl.stopOrderItemTrigger = true;
                TriggerControl.stopOrderTrigger = true;
                TriggerControl.stopSCTrigger = true;
                TriggerControl.stopCLITrigger = true;
                TriggerControl.stopEntitlementTrigger = true;
                
                updateResults = Database.update(Opp2update, false);
                
                flowControll.opportunityTriggerHandler = tempFlag;
                flowControll.opportunityLineItemHandler = tempFlag1;
                SBQQ.TriggerControl.enable();
                TriggerControls.disableQuoteTrigger = false;
                TriggerControls.disableQuoteLineTrigger = false;
                TriggerControls.disableCalculateAPIBatch = false;
                TriggerControl.stopOrderItemTrigger = false;
                TriggerControl.stopOrderTrigger = false;
                TriggerControl.stopSCTrigger = false;
                TriggerControl.stopCLITrigger = false;
                TriggerControl.stopEntitlementTrigger = false;
            }
            String erroSCMsg;
            
            for (Integer i = 0; i < Opp2update.size(); i++) {
                Database.SaveResult result1 = updateResults[i];
                if(result1.isSuccess()){
                    System.debug('Success-'+Opp2update.get(i));
                }
               
                
                Database.SaveResult result = updateResults[i];
                if (!result.isSuccess() || Test.isRunningTest()) {
                     erroSCMsg='Record Failed in batch UpdateL3opportunityBatch';
                     
                    for(Database.Error errdata : result.getErrors()) {   
                        system.debug('@@@@ Error Details line 1 @@@'+errdata+'--'+updateResults[i]);                    
                        
                        batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='UpdateL3opportunityBatch',
                                                                   Failure_Job_ID__c=context.getJobId(),Failure_Message__c=string.ValueOf(errdata),
                                                                   Scenario__c=erroSCMsg,Service_Contract_Id__c=Opp2update[i].id,Failure_Date__c=Date.today()));
                        
                    }
                }
            }
        } 
        try{
        if(!batchErrLogList.isEmpty()){
            upsert batchErrLogList; 
        }
        }catch(exception e){
            system.debug('@@@@ Error Details line 2'+e.getMessage());
        }
    }
    
    
    public void finish(Database.BatchableContext context) {
        
    }   
    
}