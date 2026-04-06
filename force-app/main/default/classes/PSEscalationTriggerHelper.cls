public inherited sharing class PSEscalationTriggerHelper{
    public List<Approval.ProcessWorkitemRequest> processRequestList = new List<Approval.ProcessWorkitemRequest>();
    public static Map<Id, ProcessInstance> processInstanceMap = new Map<Id, ProcessInstance>();

    public static string AllianceRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
    public static string ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
    public static string ServiceDeliveryRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId();
    public static string OEMRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();


    //populate rejection reason from rejection comments or add error
    public void populateRejectionReason(Map<Id, DR_PS_Escalation__c> oldPsEscMap, Map<Id, DR_PS_Escalation__c> newPsEscMap){
        Map<Id, ProcessInstance> processInstanceMap = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId, Status, (SELECT Id, StepStatus, Comments
                                                                                                                        FROM Steps
                                                                                                                        WHERE StepStatus = 'Rejected'
                                                                                                                        ORDER BY CreatedDate DESC
                                                                                                                        LIMIT 1), (SELECT Id, ActorId, ProcessInstanceId
                                                                                                                                   FROM Workitems)
                                                                                    FROM ProcessInstance
                                                                                    WHERE TargetObjectId IN:newPsEscMap.keySet() AND Status = 'Rejected']);

        for (ProcessInstance pi : processInstanceMap.values()){
            ProcessInstanceStep lastStep = pi.Steps.isEmpty() ? null : pi.Steps[0];
            if (lastStep != null && !String.isBlank(lastStep.Comments)){
                newPsEscMap.get(pi.TargetObjectId).Rejection_Reason__c = lastStep.Comments;
                newPsEscMap.get(pi.TargetObjectId).Close_Date__c = System.now();
            } else{
                newPsEscMap.get(pi.TargetObjectId).addError('Please provide comments for escalation rejection');
            }
        }

        for(DR_PS_Escalation__c newRec : newPsEscMap.values()){
            DR_PS_Escalation__c oldRec = oldPsEscMap.get(newRec.Id);
            if(newRec.Status__c != oldRec.Status__c && (newRec.Status__c == 'No Action' || newRec.Status__c == 'Duplicate' || newRec.Status__c == 'Rejected') && String.isBlank(newRec.Rejection_Reason__c)){
                newRec.addError('Please provide comments for escalation rejection');
            }else if(newRec.Status__c != oldRec.Status__c && (newRec.Status__c == 'No Action' || newRec.Status__c == 'Duplicate' || newRec.Status__c == 'Rejected') && !String.isBlank(newRec.Rejection_Reason__c)){
                newRec.Close_Date__c = System.now();
            }
        }
    }

    //remove/reject escalation based on status
    public void processRecords(Map<Id, DR_PS_Escalation__c> oldPsEscMap, Map<Id, DR_PS_Escalation__c> newPsEscMap){
        Map<Id, String> recIdActionMap = new Map<Id, String>();

        for (DR_PS_Escalation__c newRec : newPsEscMap.values()){
            DR_PS_Escalation__c oldRec = oldPsEscMap.get(newRec.Id);
            if (newRec.Status__c != oldRec.Status__c && newRec.Status__c == 'More Info Required'){
                recIdActionMap.put(newRec.Id, 'Removed');
            }

            if ((newRec.Status__c == 'No Action' || newRec.Status__c == 'Duplicate' || newRec.Status__c == 'Rejected') && newRec.Status__c != oldRec.Status__c){
                recIdActionMap.put(newRec.Id, 'Reject');
            }
        }

        if (!recIdActionMap.isEmpty()){
            setApprovalActions(recIdActionMap);
        }
    }
    
    //set approval actions
    public void setApprovalActions(Map<Id, String> recIdActionMap){
        Map<Id, String> wrkItmIdActionMap = new Map<Id, String>();

        for (ProcessInstance pi : [SELECT Id, TargetObjectId, Status, (SELECT Id
                                                                       FROM Workitems)
                                   FROM ProcessInstance
                                   WHERE Id IN (SELECT ProcessInstanceId
                                                FROM ProcessInstanceWorkitem
                                                WHERE ProcessInstanceId IN:processInstanceMap.keySet() AND ActorId = :UserInfo.getUserId())]){
            if (pi.Status != 'Rejected'){
                String act = recIdActionMap.get(pi.TargetObjectId);
                for (ProcessInstanceWorkitem wrkItm : pi.Workitems){
                    wrkItmIdActionMap.put(wrkItm.Id, act);
                }
            }
        }

        for (Id pIWorkItemId : wrkItmIdActionMap.keySet()){
            Approval.ProcessWorkitemRequest workItemRequest = new Approval.ProcessWorkitemRequest();
            workItemRequest.setWorkitemId(pIWorkItemId);
            workItemRequest.setAction(wrkItmIdActionMap.get(pIWorkItemId));
            processRequestList.add(workItemRequest);
        }

        if(processRequestList != null){
            performApprovalActions();
        }
    }
    
    //Reprocess approval
    public void performApprovalActions(){
        if (!processRequestList.isEmpty()){
            Approval.process(processRequestList);
        }
    }

    //set pre approval/rejection actions
    public void onApprovalActions(Map<Id, DR_PS_Escalation__c> oldMap, Map<Id, DR_PS_Escalation__c> newMap) {
        Map<Id, DR_PS_Escalation__c> psEscMap = new Map<Id, DR_PS_Escalation__c>();

        for (DR_PS_Escalation__c rec : newMap.values()){
            if (rec.Status__c == 'Approved' && oldMap.get(rec.Id).Status__c != rec.Status__c){
                rec.Close_Date__c = System.now();
                psEscMap.put(rec.Id, rec);
            }
        }

        if (!psEscMap.isEmpty()) {
            List<DR_PS_Escalation__c> updatedRecords = [SELECT Id, Deal_Registration__c, Deal_Registration__r.Deal_Registration_Status__c, New_Opportunity__c, New_Opportunity__r.StageName, Existing_Opportunity__c, Existing_Opportunity__r.StageName, Rejection_Reason__c
                                                        FROM DR_PS_Escalation__c
                                                        WHERE Id IN :psEscMap.keySet()];

            for (DR_PS_Escalation__c rec : updatedRecords) {
                if ((rec.New_Opportunity__c != null && (rec.New_Opportunity__r.StageName == '6 PO With Channel' || rec.New_Opportunity__r.StageName == '7 Closed Won' || rec.New_Opportunity__r.StageName == '7 Closed Lost' || rec.New_Opportunity__r.StageName == '7 Closed Admin')) || (rec.Existing_Opportunity__c != null && rec.New_Opportunity__c == null && (rec.Existing_Opportunity__r.StageName == '6 PO With Channel' || rec.Existing_Opportunity__r.StageName == '7 Closed Won' || rec.Existing_Opportunity__r.StageName == '7 Closed Lost' || rec.Existing_Opportunity__r.StageName == '7 Closed Admin'))) {
                    newMap.get(rec.Id).Status__c = 'No Action';
                    newMap.get(rec.Id).Rejection_Reason__c = 'Opp in Stage 6 or 7';
                }
            }
        }
    }
  
    //after update
    public void afterApprovalActions(Map<Id, DR_PS_Escalation__c> oldMap, Map<Id, DR_PS_Escalation__c> newMap){
        Map<Id, Opportunity> oppMapToUpdate = new Map<Id, Opportunity>();
        Map<Id, Deal_Registration__c> dealRegToUpdate = new Map<Id, Deal_Registration__c>();
        Map<Id, DR_PS_Escalation__c> psEscMap = new Map<Id, DR_PS_Escalation__c>();
        Set<Id> drIds = new Set<Id>();
        Map<Id, Deal_Registration__c> drMap = new Map<Id, Deal_Registration__c>();
        try{
            for (DR_PS_Escalation__c rec : newMap.values()){
                if (rec.Status__c == 'Approved' && oldMap.get(rec.Id).Status__c != rec.Status__c){
                    psEscMap.put(rec.Id, rec);
                    drIds.add(rec.Deal_Registration__c);
                }
            }

            for (Deal_Registration__c dr : [SELECT Id, Email__c, Primary_Contact__c, RecordTypeId, Company_Name__c, Partner_Lookup__c, Partner_Rep_Email_Address__c, Partner_Rep_Phone_Number__c, Approval_Timestamp__c, Deal_Registration_Expiration__c, Name, Deal_Reg_Submitted_Date__c, Deal_Registration_Status__c, Partner_SE_Email__c, Partner_SE_Name__c, Rubrik_Complete_Edition_Reg__c, Partner_SE_Phone__c, Budget__c, Authority__c, Need__c, Purchase_Timeframe__c, Distributor_Rep_Phone_Number__c, Distributor_Secondary_Email_Address__c, Distributor__c, Sell_to_Partner__c, Dedicated_Managed_Service__c, Opportunity_Details__c, Focused_Partner__c, National_Partner__c
                                            FROM Deal_Registration__c
                                            WHERE Id IN:drIds]){
                drMap.put(dr.Id, dr);
            }

            for (DR_PS_Escalation__c rec : [SELECT Id, Deal_Registration__c, New_Opportunity__c, Existing_Opportunity__c, Deal_Initiated_Type__c, Escalation_Type__c
                                            FROM DR_PS_Escalation__c
                                            WHERE Id IN:psEscMap.keySet()]){
                Deal_Registration__c dr = drMap.get(rec.Deal_Registration__c);
                dr.Deal_Registration_Type__c = rec.Deal_Initiated_Type__c;
                if (rec.Deal_Initiated_Type__c != 'Rubrik Sourced'){
                    dr.Registration_Type__c = 'Partner Sourced';
                }

                if (rec.Escalation_Type__c == 'Dormant Opp' || rec.Escalation_Type__c == 'Incorrect Selection at Approval' || rec.Escalation_Type__c == 'Federal'){
                    dr.Opportunity__c = rec.Existing_Opportunity__c;
                    //update opp rec
                    Opportunity opp = new Opportunity(
                        Id = rec.Existing_Opportunity__c
                    );
                    opp.Deal_Registration_Type__c = rec.Deal_Initiated_Type__c;
                    opp.Deal_Registration__c = true;
                    opp.Sourcing_Partner__c = dr.Partner_Lookup__c;
                    opp.PS_Escalated_New__c = 'Manual';
                    //opp.PS_Escalated__c = true;
                    oppMapToUpdate.put(opp.Id, opp);
                }

                if (rec.Escalation_Type__c == 'Split Opp' || rec.Escalation_Type__c == 'New Opp-DR Move'){
                    Opportunity opp = new Opportunity(
                        Id = rec.New_Opportunity__c
                    );
                    opp.Deal_Registration_Type__c = rec.Deal_Initiated_Type__c;
                    opp.Deal_Registration__c = true;
                    opp.Sourcing_Partner__c = dr.Partner_Lookup__c;
                    opp.Deal_Reg_Approval_Status__c = dr.Deal_Registration_Status__c;
                    opp.Deal_Reg_Submitted_Date__c = dr.Deal_Reg_Submitted_Date__c;
                    opp.Deal_Reg_Approval_Timestamp__c = dr.Approval_Timestamp__c;
                    opp.Deal_Reg_Expiration_Date__c = dr.Deal_Registration_Expiration__c;
                    opp.Deal_Registration_Number__c = dr.Name;
                    opp.Partner_Rep_Phone_Number__c = dr.Partner_Rep_Phone_Number__c;
                    opp.Partner_Rep_Email_Address__c = dr.Partner_Rep_Email_Address__c;
                    opp.Opportunity_Details__c = dr.Opportunity_Details__c;
                    opp.PS_Escalated_New__c = 'Manual';
                  	//opp.PS_Escalated__c = true;
					dr.Opportunity__c = rec.New_Opportunity__c;

                    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
                    DealRegistrationTriggerHelper dealHelper = new DealRegistrationTriggerHelper();
                    oppMap.put(opp.Id, opp);

                    if (dr.RecordTypeId == ResellerRecordTypeId){
                        dealHelper.updateResellerInformation(new List<Deal_Registration__c>{ dr }, oppMap);
                    } else if (dr.RecordTypeId == AllianceRecordTypeId){
                        dealHelper.updateAlliancePartnerInformation(new List<Deal_Registration__c>{ dr }, oppMap);

                    } else if (dr.RecordTypeId == ServiceDeliveryRecordTypeId){
                        dealHelper.updateSDPInformation(new List<Deal_Registration__c>{ dr }, oppMap);
                    }

                    if (rec.Escalation_Type__c == 'Split Opp'){
                        Opportunity oldOpp = new Opportunity(
                            Id = rec.Existing_Opportunity__c
                        );
						dr.Opportunity__c = rec.Existing_Opportunity__c;
                        oldOpp.PS_Escalated_New__c = 'Manual';
                        oppMapToUpdate.put(oldOpp.Id, oldOpp);
                    }else{
						dr.Primary_Deal_Registration__c = true;
					}
                    DealRegistrationTriggerHelper.addCustomerContactAsOppRole(new List<Deal_Registration__c>{ dr }, oppMap);
                    oppMapToUpdate.put(opp.Id, opp);
                }

                dealRegToUpdate.put(dr.Id, dr);
            }

            update oppMapToUpdate.Values();
            update dealRegToUpdate.values();
        } catch (exception ex){
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c(
                Class__c = 'PSEscalationTriggerHelper', 
                Exception_Message__c = ex.getMessage(), 
                Functionality__c = 'afterApprovalAction'
            );
            insert errorLogRec;
        }
    }
}