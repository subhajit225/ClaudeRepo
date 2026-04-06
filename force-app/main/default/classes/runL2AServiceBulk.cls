// MKT24=281
public with sharing class runL2AServiceBulk implements Queueable, Database.AllowsCallouts{
    List<Id> leadId = new List<Id>();
    List<Boolean> runPatchManager = new List<Boolean>();

    public runL2AServiceBulk(List<Id> leadId, List<Boolean> runPatchManager) {
        this.leadId = leadId;
        this.runPatchManager = runPatchManager;
    }
    public void execute (QueueableContext context){
        Map<String, String> leadFieldToResponse = new Map<String, String>{
            'Id' => 'sourceId',
            'L2A_Confidence_Code__c' => 'matchConfidence',
            'L2A_Match_Criteria__c' => 'matchCriteria',
            'L2A_Account__c' => 'accountId',
            'L2A_Status_Message__c' => 'statusDescription'
        };
        L2AService service = new L2AService();
        List<Lead> updateLeads = new List<Lead>();
        Integer index = 0;
        List<Lead> leadRecords = [SELECT Id, Company,street,city,stateCode,PostalCode,CountryCode,country,phone,email, Campaign_Sourced_By__c, MQL__c, Winning_L2A_Account__c,Winning_L2A_System__c,OP_L2A_Account__c,L2A_Account__c,OP_Confidence_Level__c 
                            FROM Lead
                            WHERE Id IN :leadId];
        if(!leadRecords.isEmpty()){
            Map<String,Object> payload = service.getPayload(leadRecords);
            System.debug(' #runL2AService#payload :'+payload);
            Map<Id, Lead> leadMap = new Map<Id, Lead>(leadRecords);
            L2AService.ResponseWrapper response = service.callService(payload);
            System.debug(' #runL2AService#response :'+ JSON.serialize(response) );
            for(Object l2aResult : response.l2aAccount) {
            Map<String, Object> fieldValues = (Map<String, Object>) l2aResult;
                Lead leadRecord = new Lead();
                try {
                    for(String fieldName : leadFieldToResponse.keySet()){
                        if(fieldName=='L2A_Confidence_Code__c'){
                            if(!String.isBlank(String.valueOf(fieldValues.get(leadFieldToResponse.get(fieldName))))){
                                Integer ConFCode = Integer.valueOf(fieldValues.get(leadFieldToResponse.get(fieldName)));
                                leadRecord.put(fieldName,ConFCode); 
                            }
                            else leadRecord.L2A_Confidence_Code__c = null;
                        } else {
                            leadRecord.put(fieldName, fieldValues.get(leadFieldToResponse.get(fieldName)));   
                        }
                        
                    }
                    // Chnages for WinL2AAccount //
                    if(leadRecord.L2A_Confidence_Code__c!=null && leadRecord.L2A_Confidence_Code__c >=3) {
                        leadRecord.Winning_L2A_Account__c = leadRecord.L2A_Account__c;  
                    } else if(leadMap.get(leadRecord.Id).OP_Confidence_Level__c>=5) {
                        leadRecord.Winning_L2A_Account__c =leadMap.get(leadRecord.Id).OP_L2A_Account__c;
                    }
                    else 
                        leadRecord.Winning_L2A_Account__c =null;
                    
                    leadRecord.L2A_Status__c = 'Processed as service';
                    leadRecord.Last_Run_L2A_Date__c = Datetime.now();
                    leadRecord.Run_L2A__c = false;
                    if(runPatchManager[index++])
                        leadRecord.rerun_PatchManager__c = true;
                    updateLeads.add(leadRecord);
                }catch(Exception e){
                    System.debug('#runL2AService#Exception:'+e.getMessage()+' '+e.getStackTraceString());
                    leadRecord.L2A_Status__c = 'Reprocess';
                    leadRecord.L2A_Status_Message__c = e.getMessage()+' '+e.getStackTraceString();
                    leadRecord.Run_L2A__c = false;
                    updateLeads.add(leadRecord);
                }
            }
            Database.SaveResult[] srList = new List<Database.SaveResult>();
            try {
                if(!updateLeads.isEmpty())
                    srList = Database.update(updateLeads, false);
                for(Database.SaveResult sr : srList) {
                    if(!sr.isSuccess()){
                        for(Database.Error err: sr.getErrors()){
                            System.debug('Error in saving record----'+err.getStatusCode()+':'+err.getMessage());
                        }
                    }
                }
            }catch(Exception e){
                System.debug('#LeadTriggerHelper#runL2AService#Exception:'+e.getMessage()+' '+e.getStackTraceString());
            }
        }
    }
}