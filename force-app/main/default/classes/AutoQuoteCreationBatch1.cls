/************************************************************************************
* @Developer : Ashwini Borse
* @Date : 19 Dec 2022
* @Description : This batch has written under Arroyo 2.0 for requirement ARY-682, to auto create quote and marked them invalid based on last modified days.
* 
**************************************************************************************/
global class AutoQuoteCreationBatch1 implements Database.Batchable<sObject>, Database.Stateful {
    /**idSet */
    Set<Id> idSet;
    /**accId */
    String accId;
    /**oppId */
    String oppId;
    /**quoteId */
    String quoteId;
    /**isExecutingBatch */
    boolean isExecutingBatch = false; 
    /**contractlst */
    List<ServiceContract> contractlst = new List<ServiceContract>();
    
    /**
    * @description Batch Job constructor for AutoQuoteCreationBatch1
    * @param idSet
    **/
    global AutoQuoteCreationBatch1(Set<Id> idSet){
            this.idSet = idSet;
       }
                
    /**
    * @description Batch Job Start for AutoQuoteCreationBatch1
    * @return query
    * @param bc
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute        
        return Database.getQueryLocator('SELECT id, name,AccountId,Contract_Renewal_Term__c FROM Opportunity WHERE id =:idSet'); 
    }
                    
    /**
    * @description Batch Job execute for AutoQuoteCreationBatch1
    * @param bc
    * @param records
    **/
    global void execute(Database.BatchableContext bc, List<Opportunity> records){
        // process each batch of records
           for(Opportunity ot: records){
               oppId = ot.Id;
               accId = ot.AccountId;
           }
           //fetch Service Contracts associated with account of opportunity.
           contractlst = serviceContractList.fetchContracts(accId,oppId);
           //if(contractlst.size() > 0){
            if(!contractlst.isEmpty()){
               String JSONString = JSON.serialize(contractlst);
               System.debug(LoggingLevel.DEBUG, JSONString);
               isExecutingBatch = true;
               //quoteId = serviceContractList.renewalContractsFromBatch(JSONString,oppId,isExecutingBatch);
               quoteId = serviceContractListFromBatch.renewalContractsFromBatch(JSONString,oppId,isExecutingBatch);
            }
    }    
                                    
    /**
    * @description Batch Job finish for AutoQuoteCreationBatch1
    * @param bc
    **/
    global void finish(Database.BatchableContext bc){
        system.debug(LoggingLevel.DEBUG, 'Empty Finish Block');
        // execute any post-processing operations        
        }
    }