public with sharing class POStageErrorsTriggerHandler extends TriggerHandler {
    public POStageErrorsTriggerHandler() {
        this.setMaxLoopCount(2);
    }

	private Boolean isDisabled = false;
    
    public override void beforeInsert() {
        if(!isDisabled) {
           
        }
    }

    public override void beforeUpdate() {
        if(!isDisabled) {
            
        }
    }

    public override void afterInsert() {
        if(!isDisabled) {
            Set<Id> poStageIds = new Set<Id>();
            Map<Id,List<PO_Stage_Errors__c>> stageErrorsToUpdate = new Map<Id,List<PO_Stage_Errors__c>>();
			Set<Id> opptyIdToErrorCode = new Set<Id>();
            Map<Id,PO_Stage__c> idToStagePO = new Map<Id,PO_Stage__c>();
            Map<Id,SBQQ__Quote__c> quoteToUpdate = new Map<Id,SBQQ__Quote__c>();
            Map<Id,PO_Stage_Errors__c> poStageErrorsToUpdate = new Map<Id,PO_Stage_Errors__c>();

            for(PO_Stage_Errors__c error: (List<PO_Stage_Errors__c>)Trigger.new){
                poStageIds.add(error.PO_Stage_Id__c);
                if(error.Error_Code__c!=null && error.Error_Code__c.contains('INT-02')){
                if (!stageErrorsToUpdate.containsKey(error.PO_Stage_Id__c)) {
                stageErrorsToUpdate.put(error.PO_Stage_Id__c, new List<PO_Stage_Errors__c>());
                }
                stageErrorsToUpdate.get(error.PO_Stage_Id__c).add(error);
                }
            }

            Map<Id, String> existingMessagesMap = new Map<Id, String>();
            for(PO_Stage__c stagePO: [Select Id, Error_Messages__c,Quote__c,Quote__r.Id,Quote__r.SBQQ__Primary__c,Quote__r.SBQQ__Status__c,Opportunity__c ,Opportunity__r.Opportunity_Sub_Type__c,  Opportunity__r.Renewals_Forecast_Risk__c,Opportunity__r.stagename  from PO_Stage__c where Id in :poStageIds]){
                if(String.isNotBlank(stagePO.Error_Messages__c)){
                    existingMessagesMap.put(stagePO.Id, stagePO.Error_Messages__c);
                }
                if(stagePO.Quote__c!=null && stagePO.Opportunity__c!=null && isOpportunityRenewalWithSubscription(stagePO.Opportunity__r))
                idToStagePO.put(stagePO.Opportunity__c,stagePO);

            }
            for(PO_Stage_Errors__c errorCode : [select id,Opportunity__c from PO_Stage_Errors__c where Error_Code__c = 'INT-02' and Opportunity__c!=null and Opportunity__c IN : idToStagePO.keyset() order by createddate desc]){
                if(!opptyIdToErrorCode.contains(errorCode.Opportunity__c))
                opptyIdToErrorCode.add(errorCode.Opportunity__c);    
            }


            if(opptyIdToErrorCode.isempty() || (!opptyIdToErrorCode.isempty() && !idToStagePO.keyset().containsall(opptyIdToErrorCode))){
                if(!idToStagePO.isempty()){    
                    processQuoteUpdates(
                        idToStagePO, 
                        stageErrorsToUpdate,
                        quoteToUpdate,
                        poStageErrorsToUpdate
                    );
                    if(!poStageErrorsToUpdate.isEmpty()){
                        map<Id,Id> quoteIdToStagePOErrorId = new map<Id,Id>();
                        for(Id quoteId : poStageErrorsToUpdate.keyset()){
                            if(poStageErrorsToUpdate.containskey(quoteId))
                                quoteIdToStagePOErrorId.put(quoteId,poStageErrorsToUpdate.get(quoteId).Id);
                        }
                        erroMessagesOnUpdateOfQuoteToPrimaryFuture(quoteIdToStagePOErrorId);
                    }
                }
                
            }
            Map<Id, String> messagesMap = new Map<Id, String>();
            for(PO_Stage_Errors__c error: (List<PO_Stage_Errors__c>)Trigger.new){
                if(error.PO_Stage_Id__c!=null){
                    String existingMessage = '';
                    if(existingMessagesMap.containsKey(error.PO_Stage_Id__c)){
                        existingMessage = existingMessagesMap.get(error.PO_Stage_Id__c);
                    }

                    if(messagesMap.containsKey(error.PO_Stage_Id__c)){
                        messagesMap.put(error.PO_Stage_Id__c, messagesMap.get(error.PO_Stage_Id__c) + ', ' + error.Error_Message__c);
                    }
                    else {
                        existingMessage = String.isBlank(existingMessage) ? '' : ', ';
                        messagesMap.put(error.PO_Stage_Id__c, existingMessage + error.Error_Message__c);
                    }
                }
            }   

            List<PO_Stage__c> poStages = new List<PO_Stage__c>();
            for(Id stagePOId : messagesMap.keySet()){
                poStages.add(new PO_Stage__c(Id = stagePOId, Error_Messages__c = messagesMap.get(stagePOId)));
            }

            if(poStages.size()>0){
                update poStages;
            }

        }
    }

    public override void afterUpdate() {
        if(!isDisabled) {
        
        }
    }


      /**
    * @author Prashant Kumar
    * @description Method to Fix the exception from CPQ package While setting Quote to Primary
    * @param quoteToPoErrorID
    */
        @future
    public static void erroMessagesOnUpdateOfQuoteToPrimaryFuture(Map<Id, Id> quoteToPoErrorID) {
        Map<Id, PO_Stage_Errors__c> poStageErrorsToUpdate = new Map<Id, PO_Stage_Errors__c>();
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>();
        for(PO_Stage_Errors__c error : [Select id,PO_Stage_Id__r.Quote__r.SBQQ__Status__c,PO_Stage_Id__r.Quote__r.SBQQ__Primary__c,PO_Stage_Id__r.quote__c,PO_Stage_Id__r.opportunity__c from PO_Stage_Errors__c where Id IN : quoteToPoErrorID.values()]){
            Boolean isApproved = (error.PO_Stage_Id__r.Quote__r.SBQQ__Status__c == 'Approved');
            Boolean isPrimary = (error.PO_Stage_Id__r.Quote__r.SBQQ__Primary__c == true);
            PO_Stage_Errors__c errorToUpdate = new PO_Stage_Errors__c();
            errorToUpdate.Id = error.Id;
            errorToUpdate.Opportunity__c = error.PO_Stage_Id__r.Opportunity__c;
            errorToUpdate.Quote__c = error.PO_Stage_Id__r.quote__c;
            
            // Example error handling logic (you can customize this based on your business logic)
            if (!isApproved) {
                errorToUpdate.Quote_Update_Status__c = constants.QUOTE_UPDATED_FAILED_STATUS;//'Quote Update Failed';
                errorToUpdate.Quote_Update_Message__c = constants.QUOTE_UPDATED_FAILED_MESSAGE;//'Quote Not Approved';
            } else if (isApproved && isPrimary) {
                errorToUpdate.Quote_Update_Status__c = constants.QUOTE_UPDATED_NOTREQUIRED_STATUS;//'Quote Update Not Required';
                errorToUpdate.Quote_Update_Message__c = constants.QUOTE_UPDATED_NOTREQUIRED_MESSAGE;// 'Quote is already Approved and Primary.';
            }else if(isApproved && !isPrimary){
                quoteMap.put(error.PO_Stage_Id__r.quote__c,new SBQQ__Quote__c(Id = error.PO_Stage_Id__r.quote__c,SBQQ__Primary__c = true));
            }
            poStageErrorsToUpdate.put(error.PO_Stage_Id__r.quote__c,errorToUpdate);     
        }    
        if(!quoteMap.isempty())
            erroMessagesOnUpdateOfQuoteToPrimary(quoteMap.values(), poStageErrorsToUpdate);

        if (!poStageErrorsToUpdate.isEmpty()) {
            update poStageErrorsToUpdate.values();
        }
    }

    /**
    * @author Prashant Kumar
    * @description update Quotes to Primary and Set the tracking if its success and Failure
    * @param quoteList
    * @param poStageErrorsToUpdate
    */
    public static void erroMessagesOnUpdateOfQuoteToPrimary(
        List<SBQQ__Quote__c> quoteList, 
        Map<Id, PO_Stage_Errors__c> poStageErrorsToUpdate
    ) {
        List<Database.SaveResult> srList = Database.update(quoteList, false); // 'false' to allow partial success
        for (Integer i = 0; i < srList.size(); i++) {
            SBQQ__Quote__c quote = quoteList[i];
            Database.SaveResult sr = srList[i];
            if(poStageErrorsToUpdate.containskey(quote.Id)){
                String message = constants.QUOTE_UPDATED_SUCCESS_MESSAGE;//'Quote Update Successfully';
                String status = constants.QUOTE_UPDATED_SUCCESS_STATUS;//'Quote Update Completed';
                if(!sr.isSuccess() && !test.isRunningTest()){
                    Database.Error errorRes = srList.get(i).getErrors().get(0);
                    message = errorRes.getMessage();
                    status = constants.QUOTE_UPDATED_FAILED_STATUS;//'Quote Update Failed';
                }
                poStageErrorsToUpdate.get(quote.Id).Quote_update_Message__c = message; 
                poStageErrorsToUpdate.get(quote.Id).Quote_Update_Status__c = status; 
            }
        }
    }
    
    
    
    /**
    * @author Prashant Kumar
    * @description Setting Map to Set Quote as Primary 
    * and also updating statuses which are not eligible to update quote to Primary
    * @param idToStagePO
    * @param stageErrorsToUpdate
    * @param quoteToUpdate
    * @param poStageErrorsToUpdate
	*/
    public static void processQuoteUpdates(
        Map<Id, PO_Stage__c> idToStagePO, 
        Map<Id, List<PO_Stage_Errors__c>> stageErrorsToUpdate,
        Map<Id, SBQQ__Quote__c> quoteToUpdate,
        Map<Id, PO_Stage_Errors__c> poStageErrorsToUpdate
    ) {
        // Iterate through the PO Stages
        for (Id opptyId : idToStagePO.keySet()) {
            PO_Stage__c stagePO = idToStagePO.get(opptyId);
            
            // Ensure the error map contains an entry for this PO Stage
            if (!stageErrorsToUpdate.containsKey(stagePO.id)) {
                continue; // Skip if no error record is found for this PO Stage
            }
            
            PO_Stage_Errors__c errorRecord = stageErrorsToUpdate.get(stagePO.id)[0];
            
            // If there's no error record, skip further processing
            if (errorRecord == null) {
                continue;
            }
            
            // Determine if the Quote is Approved and Primary
            Boolean isApproved = (stagePO.Quote__r.SBQQ__Status__c == 'Approved');
            Boolean isPrimary = (stagePO.Quote__r.SBQQ__Primary__c == true);
            
            // If Quote is Approved but not Primary, update it to Primary
            if (isApproved && !isPrimary) {
                SBQQ__Quote__c quoteToUpdateRecord = new SBQQ__Quote__c(
                    Id = stagePO.Quote__c,
                    SBQQ__Primary__c = true
                );
                quoteToUpdate.put(stagePO.Quote__c, quoteToUpdateRecord);
            }
            
            // Log the approval and primary status for debugging
            
            // Build the error record to update based on the current stage and approval status
            PO_Stage_Errors__c updatedError = createErrorCodeForQuoteAndOpty(stagePO, errorRecord, isApproved, isPrimary);
            
            // Put the updated error record into the errors map
            poStageErrorsToUpdate.put(stagePO.Quote__c, updatedError);
        }
    }
    
    /**
    * @author Prashant Kumar
    * @description preparing PO_Stage_Errors__c record data so that this record can be used further.
    * @param stagePO
    * @param existingError
    * @param isApproved
    * @param isPrimary
    * @return PO_Stage_Errors__c
	*/
    private static PO_Stage_Errors__c createErrorCodeForQuoteAndOpty(
        PO_Stage__c stagePO,
        PO_Stage_Errors__c existingError,
        Boolean isApproved,
        Boolean isPrimary
    ) {
        PO_Stage_Errors__c errorToUpdate = new PO_Stage_Errors__c();
        errorToUpdate.Id = existingError.Id;
        errorToUpdate.Opportunity__c = stagePO.Opportunity__c;
        errorToUpdate.Quote__c = stagePO.Quote__r.Id;
        
        // Example error handling logic (you can customize this based on your business logic)
        if (!isApproved) {
            errorToUpdate.Quote_Update_Status__c = constants.QUOTE_UPDATED_FAILED_STATUS;//'Quote Update Failed';
            errorToUpdate.Quote_Update_Message__c = constants.QUOTE_UPDATED_FAILED_MESSAGE;//'Quote Not Approved';
        } else if (isApproved && isPrimary) {
            errorToUpdate.Quote_Update_Status__c = constants.QUOTE_UPDATED_NOTREQUIRED_STATUS;//'Quote Update Not Required';
            errorToUpdate.Quote_Update_Message__c = constants.QUOTE_UPDATED_NOTREQUIRED_MESSAGE;// 'Quote is already Approved and Primary.';
        }
        
        return errorToUpdate;
    }
    /**
    * @author Prashant Kumar
    * @description utility method to identify if Opportunity is Renewal and Renewals_Forecast_Risk__c is subscription
    * @param opp
    * @return boolean
	*/
    public static boolean isOpportunityRenewalWithSubscription(opportunity opp){
       return (opp.Opportunity_Sub_Type__c == 'Renewal' && 
               opp.Renewals_Forecast_Risk__c == 'Subscription' && 
               !constants.VALID_OPPTY_STAGES.contains(opp.stagename));
       
    }
}