trigger PO_RequestMain on Partner_Onboarding_Request__c (before insert,after insert,before update,after update) {

    List<Partner_Onboarding_Request__c> PartRegList = new List<Partner_Onboarding_Request__c>();
    List<Partner_Onboarding_Request__c> finalPartRegList = new List<Partner_Onboarding_Request__c>();
    List<Partner_Onboarding_Request__c> rejectionPartRegList = new List<Partner_Onboarding_Request__c>();
    List<Partner_Onboarding_Request__c> lstPOR = new List<Partner_Onboarding_Request__c>();
    List<Id> recallApprovalList = new List<Id>();
    Map<Id,Partner_Onboarding_Request__c> approvedDistSDMap = new Map<Id,Partner_Onboarding_Request__c>();
    Map<String,List<PatchManager__c>> patchMap = new Map<String,List<PatchManager__c>>();
    List<String> pobIdList = new List<String>();

    if(flowcontroll.POBTriggerHandler){
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            if(PC_319InsightWebServiceCallOut.stoprecurssion == false){
                PO_Request_Service.fieldEditRestriction((Map<Id, Partner_Onboarding_Request__c>)Trigger.oldMap, (List<Partner_Onboarding_Request__c>)Trigger.New);
            }
        }
        if(trigger.isBefore && trigger.isInsert){
            for(Partner_Onboarding_Request__c PO_Request : Trigger.new){
                lstPOR.add(PO_Request);
                if(PatchManager.ROUTE_ON_INSERT_PARTNER){
                    patchMap = PatchManager.getPatchMap(lstPOR, PatchManager.PARTNER_ONBOARDING);
                    PatchManager.assignPartner(patchMap, PO_Request);
                }else{
                    PO_Request.OwnerId = label.POB_Exception_UserId;
                }
                lstPOR.clear();
            }
        }

        if((trigger.isAfter || trigger.isBefore) && trigger.isUpdate){
            Id DistRecTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Distributor').getRecordTypeId();
            Id SDRecordTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();
            Id ResellerRecordTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            List<Partner_Onboarding_Request__c> pobAttachmentList = new List<Partner_Onboarding_Request__c>();

            for(Partner_Onboarding_Request__c PO_Request : Trigger.New){
                Partner_Onboarding_Request__c oldPR = Trigger.oldMap.get(PO_Request.Id);
                if(trigger.isAfter){
                    pobIdList.clear();
                    if(PC_319InsightWebServiceCallOut.stoprecurssion == false || PO_Request.Partner_Onboarding_Status__c == 'Approved'){
                        if(PO_Request.PartnerType__c == 'Reseller' || PO_Request.PartnerType__c == 'MSP-Reseller' || (PO_Request.RecordTypeId != null && PO_Request.RecordTypeId == ResellerRecordTypeId)){
                            String patchManagerArea = PO_Request.PatchManager_s_Area__c ;
                            Boolean isManagerApprovalNeeded = false;
                            if(PO_Request.Country__c == 'United States'){
                                isManagerApprovalNeeded = true;
                            }
                            //PRIT25-542
							if(oldPR.OwnerId != PO_Request.OwnerId && PO_Request.Partner_Onboarding_Status__c  == 'Pending'){
								recallApprovalList.add(PO_Request.Id);
							}
                            if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L1 Approved' && !isManagerApprovalNeeded){
                                pobIdList.add(PO_Request.Id);
                            }
                            if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L2 Approved' && isManagerApprovalNeeded){
                                pobIdList.add(PO_Request.Id);
                            }
                            if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c  == 'Approved'){
                                PartRegList.add(PO_Request);
                            }
                            /*if(oldPR.Partner_Onboarding_Status__c  != PO_Request.Partner_Onboarding_Status__c && (PO_Request.PartnerType__c == 'MSP-Reseller' && PO_Request.Partner_Onboarding_Status__c  == 'L2 Approved')){
                                finalPartRegList.add(PO_Request);
                            }*/
                        }else if(PO_Request.RecordTypeId == DistRecTypeId || PO_Request.RecordTypeId == SDRecordTypeId){
                            if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && ((PO_Request.Partner_Onboarding_Status__c == 'L3 Approved' && PO_Request.RecordTypeId == DistRecTypeId) || (PO_Request.Partner_Onboarding_Status__c == 'L2 Approved' && PO_Request.RecordTypeId == SDRecordTypeId))){
                                pobIdList.add(PO_Request.Id);
                            }
                            if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'Approved'){
                                approvedDistSDMap.put(PO_Request.Id,PO_Request);
                            }
                        }
                    }
                }
                if(trigger.isBefore){
                    if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c  == 'Rejected'){
                        rejectionPartRegList.add(PO_Request);
                    }
                    if(PO_Request.RecordTypeId == DistRecTypeId){
                        if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L2 Approved'  && string.isBlank(PO_Request.Credit_Limit__c)){
                            PO_Request.addError(System.label.Credit_Limit_is_mandatory_to_Approve_record);
                        }
                        if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L3 Approved'  && !PO_Request.Tax_Certificates_received__c){
                            PO_Request.addError(System.label.Tax_Certificates_received_must_be_checked_to_Approve_record);
                        }
                    }
                    if(PO_Request.RecordTypeId == SDRecordTypeId){
                        if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L2 Approved'  && !PO_Request.Tax_Certificates_received__c){
                            PO_Request.addError(System.label.Tax_Certificates_received_must_be_checked_to_Approve_record);
                        }
                    }
                    if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && ((PO_Request.RecordTypeId == DistRecTypeId && PO_Request.Partner_Onboarding_Status__c == 'L5 Approved') || (PO_Request.RecordTypeId == SDRecordTypeId && PO_Request.Partner_Onboarding_Status__c == 'L4 Approved'))){
                        pobAttachmentList.add(PO_Request);
                    }
                }
            }

            if(!pobIdList.isEmpty()){
                PC_319InsightWebServiceCallOut.mainRequest(pobIdList);
            }
            //PRIT25-542
			if(!recallApprovalList.isEmpty()){
				PO_Request_Service.recallApprovalProcess(recallApprovalList);
			}
            if(!PartRegList.isEmpty()){
                PO_Request_Service.convertPRtoContact(PartRegList);
            }
            /*if(!finalPartRegList.isEmpty()) {
                PO_Request_Service.setflagpartnerMsp(finalPartRegList);
            }*/
            if(!rejectionPartRegList.isEmpty()){
                PO_Request_Service.setComments(rejectionPartRegList);
            }
            if(!approvedDistSDMap.isEmpty()){
                PO_Request_Service.createAccountDistSD(approvedDistSDMap);
            }
            if(!pobAttachmentList.isEmpty()){
                PO_Request_Service.validateAttachment(pobAttachmentList);
            }
        }
    }
}