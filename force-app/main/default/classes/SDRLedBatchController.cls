/*****************************************************************************************************************
@description : Batch class to find completed Inside Sales Led Meetings and associate them with open Opportunities
Developer : Rubrik Dev
Test Class : SDRLedBatchControllerTest 
Modification Logs
Developer Name          Date            Description
Rubrik Dev              06/11/2025      SAL26-486 Added logic for Existing Customer opportunity
*****************************************************************************************************************/
public class SDRLedBatchController implements Database.Batchable<SObject>, Database.Stateful {
    //SAL24-405
    public string NewCustomer = 'New Customer';
    public string existingCustomer = 'Existing Customer';
    public string salesRecordType = 'Sales Opportunity';
    public Map<Id,Event> eveMap = new Map<Id,Event>();
    public List<Custom_Error_Log__c> customErrorLogs = new List<Custom_Error_Log__c> ();
    /**
    * @description Constructor to initialize the batch process.
    * It fetches Events that are Inside Sales Led Meetings and stores them in a map.
    */
    public SDRLedBatchController(){
        for(Event evt : [select Id,StartDateTime,WhoId,WhatId,createdById from Event where type='Inside Sales Led Meeting' AND WhoId != null AND WhatId = null AND Who.Type = 'Contact' AND (Post_Meeting_Status__c ='Opportunity Sourced' OR Post_Meeting_Status__c = 'No Opportunity Sourced') AND Event_Status__c = 'Completed' AND StartDateTime = LAST_N_DAYS:180 order by StartDateTime DESC]){
            eveMap.put(evt.Id,evt);
        } 
    }
    /**
    * @description Defines the batch scope query.
    * @param batchContext The batch context.
    * @return A QueryLocator containing Opportunities to process.
    */
    public Database.queryLocator start(Database.BatchableContext batchContext){
        String queryStr = 'select Id,CreatedDate,SDR_Led__c,Credit_SDR_ISR_Meeting_link__c,SDR_Led_override__c,SDR_Led_Checked_Date__c,Opportunity_Type__c,Meeting_Id__c,OriginalLeadOwner__c from Opportunity where (Opportunity_Type__c =: newCustomer OR (Opportunity_Type__c =: existingCustomer AND (Credit_SDR_ISR_Meeting_link__c = NULL OR Credit_SDR_ISR_Meeting_link__c = \'\'))) AND SDR_Led_override__c = FALSE AND SDR_Led__c= FALSE AND isClosed = FALSE AND Meeting_Id__c = NULL AND CreatedDate = LAST_N_DAYS:90 AND RecordType.Name =:salesRecordType order by CreatedDate ASC';
        return Database.getQueryLocator(queryStr); 
    }
    /**
    * @description Processes each batch of Opportunities.
    * @param batchContext The batch context.
    * @param oppList The list of Opportunity records to process.
    */
    public void execute(Database.BatchableContext batchContext, List<Opportunity> oppList){
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        Map<Id,set<Id>> oppIdContactsMap = new Map<Id,set<Id>>();
        List<Opportunity> setSDROppList = new List<Opportunity>();
        List<Event> updateEveList = new List<Event>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>(); //SAL26-486
        Map<Id,User> usrMap = new Map<Id,User>(); //SAL26-486
        Map<Id, Id> oppVsEventCreatedByMap = new Map<Id, Id>();
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        for(Opportunity opp : oppList){
            if(string.isBlank(opp.Meeting_Id__c))
            	oppMap.put(opp.Id,opp);
        }
        for(OpportunityContactRole ocr : [select Id,ContactId,OpportunityId,Role from OpportunityContactRole where OpportunityId IN: oppMap.keyset()]){
            if(oppIdContactsMap.isEmpty() || !oppIdContactsMap.containsKey(ocr.OpportunityId)){
                oppIdContactsMap.put(ocr.OpportunityId,new Set<Id>());
            }
            oppIdContactsMap.get(ocr.OpportunityId).add(ocr.ContactId);
        }
        for(Event eve : eveMap.values()){
            for(Id oppId : oppIdContactsMap.keyset()){
                if(oppIdContactsMap.get(oppId).contains(eve.whoId) && eve.WhatId == null && !oppIdSet.contains(oppId) && 
                   oppMap.get(oppId).CreatedDate.addDays(-90) <= Date.valueOf(eve.StartDateTime) &&  Date.valueOf(eve.StartDateTime) <= oppMap.get(oppId).CreatedDate.addDays(5)){
                       eve.WhatId = oppId;
                       updateEveList.add(eve);
                       Opportunity oppToUpdate = oppMap.get(oppId);
                       if(oppToUpdate.Opportunity_Type__c == 'New Customer'){
                           Opportunity opp = new Opportunity(Id = oppId, SDR_Led__c = true, SDR_Led_Checked_Date__c = datetime.now(), Meeting_Id__c = eve.Id, OriginalLeadOwner__c = eve.CreatedById);
                           setSDROppList.add(opp);
                       }else if(oppToUpdate.Opportunity_Type__c == 'Existing Customer' && String.isBlank(oppToUpdate.Credit_SDR_ISR_Meeting_link__c)){ //SAL26-486
                           oppVsEventCreatedByMap.put(oppId,eve.CreatedById);
                           userIdSet.add(eve.CreatedById);
                           Opportunity opp = new Opportunity(Id = oppId, Credit_SDR_ISR_Meeting_link__c = eve.Id, Credit_SDR_ISR_Approval_Status__c = 'Sent for approval',Initial_Submitter_Name__c = eve.CreatedById);
                           setSDROppList.add(opp);
                       }
                       oppIdSet.add(oppId);
                   }
            }
        }
        //SAL26-486
        if(!userIdSet.isEmpty()){
            for(User u :[select Id,Name,Email from User where Id IN: userIdSet]){
                usrMap.put(u.Id,u);
            }
        }
        if(!oppVsEventCreatedByMap.isEmpty()){
            for(Opportunity opp : setSDROppList){
                if(oppVsEventCreatedByMap.containskey(opp.Id) && !String.isBlank(opp.Initial_Submitter_Name__c) && usrMap.containskey(opp.Initial_Submitter_Name__c)){
                    opp.Initial_Submitter_Email__c = usrMap.get(opp.Initial_Submitter_Name__c).Email;
                    opp.SDR_Initial_Submitter_Name__c = usrMap.get(opp.Initial_Submitter_Name__c).Name;
                }
            }
        }
        if(!updateEveList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(updateEveList,false);
            List<Custom_Error_Log__c> errorLogList1 = LogError.createDMLErrorLogWithRetrunType((List<SObject>)updateEveList, srList, 'SDRLedBatchController','SDRLedBatchController');//SAL25-717
            customErrorLogs.addAll(errorLogList1); //SAL25-717
        }
        if(!setSDROppList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(setSDROppList,false);
            List<Custom_Error_Log__c> errorLogList2 = LogError.createDMLErrorLogWithRetrunType((List<SObject>)setSDROppList, srList, 'SDRLedBatchController','SDRLedBatchController'); //SAL25-717
            customErrorLogs.addAll(errorLogList2); //SAL25-717
        }
        //SAL26-486 - START
        for (Id oppId : oppVsEventCreatedByMap.keySet()) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Created by Automation');
            req.setObjectId(oppId); 
            req.setSkipEntryCriteria(true);
            req.setSubmitterId(oppVsEventCreatedByMap.get(oppId));
            approvalRequests.add(req);
        }
        flowControll.opportunityTriggerHandler = false;
        if (!approvalRequests.isEmpty()) {
            List<Approval.ProcessResult> approvalResults = Approval.process(approvalRequests);
        }
        List<id> opptyIds = new List<Id>();
        opptyIds.addAll(oppIdSet);
        Approval.unlock(opptyIds);
        flowControll.opportunityTriggerHandler = true;
        //SAL26-486 - END
    }
    /**
    * @description Sends error notifications if any errors were logged during execution.
    * @param batchContext The batch context provided by Salesforce.
    */
    public void finish(Database.BatchableContext batchContext){
        /* Start SAL25-717 */
        if(!customErrorLogs.IsEmpty()){
            string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(customErrorLogs);
            EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                            'SDRLedBatchController salesopsbatcherror - ' + Date.today().format(),
                                            emailDetail); 
        }
        /* End SAL25-717 */
    }
}