public class PartnerFundClaimTriggerHandler {
    public static void replaceTitle(List<PartnerFundClaim> newPFCList){
        set<Id> pfcId = new Set<id>();
        List<PartnerFundClaim> pfcList = new List<PartnerFundClaim>();
        for(PartnerFundClaim pfc : newPFCList){
            pfcId.add(pfc.Id);
        }

        if(!pfcId.isEmpty()){
            pfcList = [select Id,Title,Claim_Number__c from PartnerFundClaim  where Id IN: pfcId];
        }
        for(PartnerFundClaim pfc : pfcList){
            pfc.title = pfc.Claim_Number__c;
        }
        update pfcList; 
    }
    public static void cannotExceedApprovedAmount(List<PartnerFundClaim> newPFCList, Map<Id, PartnerFundClaim> oldPFCMap){
    	Set<Id> pfrIdSet = new Set<Id>();
        List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
        Map<string,Decimal> pfr_pfcAmountMap = new Map<string,Decimal>();
        Double amt = 0;
        
        for(PartnerFundClaim pfc :newPFCList){
            if(oldPFCMap != null && oldPFCMap.containskey(pfc.Id) && pfc.status != oldPFCMap.get(pfc.Id).status && pfc.status == 'Approved' && pfc.Amount != null){
                pfrIdSet.add(pfc.RequestId);
            }
        }
        if(!pfrIdSet.isEmpty()){
             pfrList = [select Id,Amount,TotalApprovedFcs from PartnerFundRequest where Id IN:pfrIdSet];
             for(PartnerFundRequest pfr : pfrList){
                 if(pfr.TotalApprovedFcs != null){
                     amt = pfr.Amount - pfr.TotalApprovedFcs;
                 }else{
                     amt = pfr.Amount;
                 }
                 pfr_pfcAmountMap.put(pfr.Id,amt);
             }
        }
        for(PartnerFundClaim pfc :newPFCList){
            //PRIT25-434-start
            if(pfc.status == 'Approved' && pfc.status != oldPFCMap.get(pfc.Id).status && pfc.Claim_Amount_USD__c == null){
                pfc.addError('To Approve record, please enter the details of : Claim Amount (USD)');
            }
            //PRIT25-434-end
            if(!pfr_pfcAmountMap.isEmpty() && pfr_pfcAmountMap.containsKey(pfc.RequestId) && pfr_pfcAmountMap.get(pfc.RequestId) < pfc.Amount){
                pfc.addError('Actual Cost cannot exceed Approved Amount of Partner Fund Request');
            }            
            
        }
       
    }
    
    public static void lockUnlockRecords(List<PartnerFundClaim> newPFCList, Map<Id, PartnerFundClaim> oldPFCMap){
    	List<Id> recordsToUnlock = new List<Id>();
    	List<PartnerFundClaim> recordsToLock = new List<PartnerFundClaim>();
    	for(PartnerFundClaim pfc :newPFCList){
    	    if(oldPFCMap != null && oldPFCMap.containskey(pfc.Id) && pfc.status != oldPFCMap.get(pfc.Id).status && pfc.status == 'Submitted'){
                recordsToUnlock.add(pfc.id);
            }
           
    	}
    	if(!recordsToUnlock.isEmpty())
    	    unLockRecords(recordsToUnlock);
    }
    
    @Future
    public static void unLockRecords(List<id> newPFCListIds){
        //Check locked records
        
        List<PartnerFundClaim> fundClaimLockList = new List<PartnerFundClaim>();
        for(id c :newPFCListIds){
            if(Approval.isLocked(c)){
                PartnerFundClaim rec = new PartnerFundClaim();
                rec.id = c;
                fundClaimLockList.add(rec);
            }
        }
        //Unlock record
        if(!fundClaimLockList.isEmpty()){
            //Unlock records
            List<Approval.UnlockResult> ulrList = Approval.unlock(fundClaimLockList, false);
             
            // Iterate through each returned result
            for(Approval.UnlockResult  ulr : ulrList) {
                if (!ulr.isSuccess()) {
                    for(Database.Error err : ulr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Case fields that affected this error: ' + err.getFields());
                    }
                }
                
            }
        }
    }
    public static void claimAfterApproved(List<PartnerFundClaim> newPFCList, Map<Id, PartnerFundClaim> oldPFCMap){
        set<Id> pfrIdSet = new set<Id>();
         for(PartnerFundClaim pfc :newPFCList){
            if(oldPFCMap != null && oldPFCMap.containskey(pfc.Id) && pfc.status != oldPFCMap.get(pfc.Id).status && pfc.status == 'Approved'){
                pfrIdSet.add(pfc.RequestId);
            }
        }
        if(!pfrIdSet.isEmpty()){
            updatePartnerFundRequest(pfrIdSet);
        }
    }
    @future
    public static void updatePartnerFundRequest(set<Id> pfrIdSet){
        List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
        for(Id pfrId : pfrIdSet){
            PartnerFundRequest pfr = new PartnerFundRequest(Id=pfrId,Re_Calculate_Actual_Cost__c=true);
            pfrList.add(pfr);
        }
        if(!pfrList.isEmpty()){
            update pfrList; //ITMKT21-213 & 214
        }
    }
    public static void sendMailAfterApproved(List<PartnerFundClaim> newPFCList, Map<Id, PartnerFundClaim> oldPFCMap){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        List<contact> apContact = [select id from contact where email=:system.label.Invoices_Email  Limit 1];
        String[] ccAddresses = new String[] {System.Label.PCR_channelMMEmail}; //cc to Tomo 
        if(apContact.isEmpty()) return;
        EmailTemplate et=[Select id from EmailTemplate where developername= 'MDF_Claim_Approved_Email_to_AP'];
        Map<Id, List<Id>> claimWithCDLink = new Map<Id, List<Id>>();
        Map<Id, ContentVersion> CDIdWithVersion = new Map<Id, ContentVersion>();
        
        List<PartnerFundClaim> claims = new List<PartnerFundClaim>();
        List<PartnerFundClaim> claimsWithActualApproverEmpty = new List<PartnerFundClaim>();
        
        Set<Id> claimIds = new Set<Id>();
        for(PartnerFundClaim pfc :newPFCList){
            if(oldPFCMap != null && oldPFCMap.containskey(pfc.Id) && pfc.status != oldPFCMap.get(pfc.Id).status && pfc.status == 'Approved'){
                
                claims.add(pfc);
                claimIds.add(pfc.id);
                if(String.isEmpty(pfc.Actual_Approver_Name__c) ){
                    claimsWithActualApproverEmpty.add(pfc);
                    
                }
            }
        }
        if(claims.isEmpty()) return;
        system.debug('claimsWithActualApproverEmpty**'+ claimsWithActualApproverEmpty);
        system.debug('claims**'+ claims);
        if(!claimsWithActualApproverEmpty.isEmpty()){
        	List<ProcessInstance> PIList = [SELECT Id,LAstActorID, LastActor.name,TargetObjectid, Status, (SELECT Id, StepStatus, Comments FROM Steps) FROM ProcessInstance where TargetObjectId IN: claimsWithActualApproverEmpty And Status='Approved' ORDER BY CreatedDate Asc NULLS FIRST];
            //Set<PartnerFundClaim> pfcListToUpdate = new Set<PartnerFundClaim>();
            Map<id,PartnerFundClaim> idWithclaimsWithActualApproverEmpty = new Map<id,PartnerFundClaim>();
            for(ProcessInstance PIRecord : PIList){
                PartnerFundClaim pfcToUpdate = new PartnerFundClaim( id = PIRecord.TargetObjectid, Actual_Approver_Name__c = PIRecord.LastActor.name );
                for(ProcessInstanceStep step : PIRecord.Steps){
                    if(step.StepStatus == 'Approved'){
                        pfcToUpdate.Approval_Comments__c = step.Comments;
                    }
                }
            	idWithclaimsWithActualApproverEmpty.put(pfcToUpdate.id, pfcToUpdate);
            }
            if(!idWithclaimsWithActualApproverEmpty.values().isEmpty())
                update idWithclaimsWithActualApproverEmpty.values();
        }
                
        Set<Id> documentIds = new Set<Id>(); 
        List<ContentDocumentLink> cdl= new List<ContentDocumentLink>();
            if(!claimIds.isEmpty()){
               cdl = [SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:claimIds];  
            }
            
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
            if(!claimWithCDLink.containsKey(cdLink.LinkedEntityId)) 
                claimWithCDLink.put(cdLink.LinkedEntityId, new List<Id>());
            
            claimWithCDLink.get(cdLink.LinkedEntityId).add(cdLink.ContentDocumentId);

        }    
        List<ContentVersion> cv_list = new List<ContentVersion>();
            if(!documentIds.isEmpty()){
               cv_list = [select VersionData, PathOnClient, ContentDocumentId from ContentVersion where ContentDocumentId = :documentIds];
            }
            
        for(ContentVersion cv:cv_list){
        	CDIdWithVersion.put(cv.ContentDocumentId, cv);
        }
        
        for(PartnerFundClaim claim:claims){
            system.debug('claims111**'+ claims);
        	List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
            if(claimWithCDLink != null && claimWithCDLink.containsKey(claim.id) && claimWithCDLink.get(claim.id) != null){
                for(id cdLinkId:claimWithCDLink.get(claim.id)){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    
                    efa.setFileName(CDIdWithVersion.get(cdLinkId).pathOnClient); 
                    efa.setBody(CDIdWithVersion.get(cdLinkId).versionData);
                    
                    attachmentList.add(efa);
                }
            }
            Messaging.SingleEmailMessage singlemail = new Messaging.SingleEmailMessage();
                singleMail.setTemplateId(et.Id);  
                singleMail.setTargetObjectId(apContact[0].id);
                singleMail.setCcAddresses(ccAddresses);
                singleMail.setwhatId(claim.Id);            
                
                if(!attachmentList.isEmpty())
                	singlemail.setFileAttachments(attachmentList);
                emails.add(singleMail);
            
        }
        if(!emails.isEmpty() && !Test.isRunningTest())
        	Messaging.sendEmail(emails);
    }
}