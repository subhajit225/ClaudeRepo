/**************************************************************
Name: CCRTriggerHelper
Description : Helper for CCRTrigger                          
Developer : Anshul 
Date : 9/2021
****************************************************************/
public with sharing class CCRTriggerHelper {
    //Commented for PRIT24-261 
    /*public static void partnerIncentiveCCRApproval(List<CCR__c> newCCRList,Map<Id,CCR__c> ccrOldMap){
        List<CCR__c> approvedPPCCRList = new List<CCR__c>();
        if(!newCCRList.isEmpty()){
            Id partnerClaimFormRecType = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Partner Claim Form').getRecordTypeId();
            for(CCR__C ccr : newCCRList){
                if(ccrOldMap!=null && ccrOldMap.get(ccr.id).User__c!=ccr.User__c && ccr.RecordTypeId.equals(partnerClaimFormRecType) && ccr.User__c.equals('Approved') && ccr.CCR_Type__c.equals('Marketing SPIFF') && ccr.Incentive__c != null){
                    approvedPPCCRList.add(ccr);
                } 
            }
        }
        
        if(!approvedPPCCRList.isEmpty()){
            createUpdateContactORLead(approvedPPCCRList);
        }
    }*/
    //Commented for PRIT24-261
    /*public static void createUpdateContactORLead(List<CCR__c> approvedPartnerCCRList){
        List<String> emailCCRList = new List<String>();
        Map<String,Contact> emailContactMap = new Map<String,Contact>();
        Map<String,Lead> emailLeadMap = new Map<String,Lead>();
        List<CampaignMember> campMemberAddList = new List<CampaignMember>();
        List<CCR__c> ccrNotMatchedList = new List<CCR__c>();
        Map<String,Lead> insertedLeadsMap = new Map<String,Lead>();
        Map<String,CCR_Partner_Incentive_Campaign_Mapping__mdt> partnerIncentiveCampaignsMap = new Map<String,CCR_Partner_Incentive_Campaign_Mapping__mdt>();

        for(CCR__c ccr : approvedPartnerCCRList){
            emailCCRList.add(ccr.Customer_Email_Address__c);
        }

        if(!emailCCRList.isEmpty()){
            for(CCR_Partner_Incentive_Campaign_Mapping__mdt ccrMDT : [SELECT Id,Campaign_ID__c,Campaign_Name__c,Partner_Incentive_Name__c,Partner_IncentiveId__c
                                                                        FROM CCR_Partner_Incentive_Campaign_Mapping__mdt
                                                                        WHERE Campaign_Status__c = 'In Progress']){
                partnerIncentiveCampaignsMap.put(ccrMDT.Partner_IncentiveId__c,ccrMDT);                                                    
            }

            for(Contact con : [SELECT Id,Name,Email
                                FROM Contact
                                WHERE isPartnerContact__c!=true 
                                AND Email IN :emailCCRList ]){
                emailContactMap.put(con.Email,con);
            }

            for(Lead ld : [SELECT Id,Name,Email
                            FROM Lead
                            WHERE Email IN :emailCCRList]){
                emailLeadMap.put(ld.Email,ld);
            }
        }
        
        for(CCR__c ccrRec : approvedPartnerCCRList){
            CampaignMember campMem = new CampaignMember();
            campMem.Status = 'Attended';
            if(!emailContactMap.isEmpty() && emailContactMap.containsKey(ccrRec.Customer_Email_Address__c)){
                campMem.ContactId = emailContactMap.get(ccrRec.Customer_Email_Address__c).Id;
                if(partnerIncentiveCampaignsMap.get(ccrRec.Incentive__c) != null){
                    campMem.CampaignId = partnerIncentiveCampaignsMap.get(ccrRec.Incentive__c).Campaign_ID__c;
                }
                campMemberAddList.add(campMem);
            }
            
            if(!emailLeadMap.isEmpty() && emailLeadMap.containsKey(ccrRec.Customer_Email_Address__c) && !emailContactMap.containsKey(ccrRec.Customer_Email_Address__c)){
                campMem.LeadId = emailLeadMap.get(ccrRec.Customer_Email_Address__c).Id;
                if(partnerIncentiveCampaignsMap.get(ccrRec.Incentive__c) != null){
                    campMem.CampaignId = partnerIncentiveCampaignsMap.get(ccrRec.Incentive__c).Campaign_ID__c;
                }
                campMemberAddList.add(campMem);
            }

            if(!emailLeadMap.containsKey(ccrRec.Customer_Email_Address__c) && !emailContactMap.containsKey(ccrRec.Customer_Email_Address__c)){
                ccrNotMatchedList.add(ccrRec);
            }                 
        }

        if(!ccrNotMatchedList.isEmpty()){
            insertedLeadsMap = createNewLead(ccrNotMatchedList);
            for(CCR__c ccrRec : ccrNotMatchedList){
                if(!insertedLeadsMap.isEmpty() && insertedLeadsMap.containsKey(ccrRec.Customer_Email_Address__c)){
                    CampaignMember campMem = new CampaignMember();
                    campMem.Status = 'Attended';
                    campMem.LeadId = insertedLeadsMap.get(ccrRec.Customer_Email_Address__c).Id;
                    if(partnerIncentiveCampaignsMap.get(ccrRec.Incentive__c) != null){
                        campMem.CampaignId = partnerIncentiveCampaignsMap.get(ccrRec.Incentive__c).Campaign_ID__c;
                    }
                    campMemberAddList.add(campMem); 
                }
            }
        }

        try{
            if(!campMemberAddList.isEmpty()){
                System.debug('campMemberAddList'+campMemberAddList);
                Insert campMemberAddList;
            } 
        }catch(Exception exp){
            System.debug('Exception occured '+exp.getMessage()+' at line '+exp.getLineNumber());
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
            errorLogRec.Class__c = 'CCRTriggerHandler';
            errorLogRec.Exception_Message__c = exp.getMessage();
            errorLogRec.Functionality__c = 'Partner Incentive Campaign Member Addition';
            Insert errorLogRec;
        }
    }*/
    //Commented for PRIT24-261
    /*public static Map<String,Lead> createNewLead(List<CCR__c> approvedPartCCRList){
        Map<String,Lead> insertedLeadMap = new Map<String,Lead>();
        List<Lead> leadToInsertList = new List<Lead>();
        Map<String, CountryWithCode__c> countryCodeStatusMap = CountryWithCode__c.getAll();
        String splitDelimiter = ' ';

        for(CCR__c ccrRec : approvedPartCCRList){
            Lead leadRec = new Lead();
            if(String.isNotBlank(ccrRec.Customer_Contact_Name__c) && ccrRec.Customer_Contact_Name__c.containsWhitespace()){
                leadRec.FirstName = ccrRec.Customer_Contact_Name__c.substringBefore(splitDelimiter);
                leadRec.LastName = ccrRec.Customer_Contact_Name__c.substringAfter(splitDelimiter);
            }else{
                leadRec.LastName = ccrRec.Customer_Contact_Name__c;
            }
            leadRec.Email = ccrRec.Customer_Email_Address__c;
            leadRec.Company = ccrRec.Customer_Company__c;
            leadRec.LeadSource = 'Partner Incentives';
            leadRec.StateCode = ccrRec.StateCode__c;
            leadRec.CountryCode = countryCodeStatusMap.get(ccrRec.Country__c).code__c;
            leadToInsertList.add(leadRec);
        }

       try{
            if(!leadToInsertList.isEmpty()){
                Insert leadToInsertList;

                for(Lead ld : leadToInsertList){
                    insertedLeadMap.put(ld.Email,ld);
                }
            }
        }catch(Exception exp){
            System.debug('Exception occured '+exp.getMessage()+' at line '+exp.getLineNumber());
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
            errorLogRec.Class__c = 'CCRTriggerHandler';
            errorLogRec.Exception_Message__c = exp.getMessage();
            errorLogRec.Functionality__c = 'Partner Incentive Lead Creation';
            Insert errorLogRec;
        }
        return insertedLeadMap;
    }*/
        //GAM-3,GAM-4 // comment for SAL25-668
    /*public static void updateOpportunityonApproval(Set<Id> oppIds){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp : [select Id,Commission_Credit_Split__c,Commission_Credit_Split_Split_screen__c,Split_Exception_CCR_is_Pending__c,(select Id,Commission_Credit_Split__c,Commission_Credit_Split_Split_screen__c from Split_Opportunities__r) from Opportunity where Id IN:oppIds]){
            opp.Commission_Credit_Split__c = opp.Commission_Credit_Split_Split_screen__c;
            opp.Split_Exception_CCR_is_Pending__c = false;
            for(Opportunity childOpp : opp.Split_Opportunities__r){
                childOpp.Commission_Credit_Split__c = childOpp.Commission_Credit_Split_Split_screen__c;
                oppList.add(childOpp);
            }
            oppList.add(opp);
        }
        if(!oppList.isEmpty()){
            flowcontroll.opportunityTriggerHandler = false;
            update oppList;
        }
    }
    //GAM-3,GAM-4
    public static void updateOpportunityonRejection(Set<Id> oppIds){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp : [select Id,Commission_Credit_Split__c,Commission_Credit_Split_Split_screen__c,Split_Exception_CCR_is_Pending__c,(select Id,Commission_Credit_Split__c,Commission_Credit_Split_Split_screen__c from Split_Opportunities__r) from Opportunity where Id IN:oppIds]){
            opp.Split_Exception_CCR_is_Pending__c = false;
            opp.Commission_Credit_Split_Split_screen__c = opp.Commission_Credit_Split__c;
            for(Opportunity childOpp : opp.Split_Opportunities__r){
                childOpp.Commission_Credit_Split_Split_screen__c = childOpp.Commission_Credit_Split__c;
                oppList.add(childOpp);
            }
            oppList.add(opp);
        }
        if(!oppList.isEmpty()){
            flowcontroll.opportunityTriggerHandler = false;
            update oppList;
        }
    }*/

    //SAL24-299
    public static void manageCCRShare(List<CCR__c> newCCRList, Map<Id,CCR__c> oldCCRMap){
        List<String> ccrUserOldNewStr = new List<String>(); 
        for(CCR__c ccr : newCCRList){
            CCR__c oldCCR = oldCCRMap != null ? oldCCRMap.get(ccr.Id) : null;
            //ccrId+'-'+OldUser+'-'+NewUser - ListString format
            if(oldCCRMap == null || (ccr.Affected_Person_Manager__c != oldCCR.Affected_Person_Manager__c)) ccrUserOldNewStr.add(ccr.Id + '-' + oldCCR?.Affected_Person_Manager__c + '-' + ccr.Affected_Person_Manager__c);
            if(oldCCRMap == null || (ccr.Affected_Person_SecondLevel_Manager__c != oldCCR.Affected_Person_SecondLevel_Manager__c)) ccrUserOldNewStr.add(ccr.Id + '-' + oldCCR?.Affected_Person_SecondLevel_Manager__c + '-' + ccr.Affected_Person_SecondLevel_Manager__c);
            if(oldCCRMap == null || (ccr.Affected_Person_ThirdLevel_Manager__c != oldCCR.Affected_Person_ThirdLevel_Manager__c)) ccrUserOldNewStr.add(ccr.Id + '-' + oldCCR?.Affected_Person_ThirdLevel_Manager__c + '-' + ccr.Affected_Person_ThirdLevel_Manager__c);
        }
        if(!ccrUserOldNewStr.isEmpty()) {
            if(System.isBatch())    manageCCRShare(ccrUserOldNewStr);
            else    manageCCRShareFuture(ccrUserOldNewStr);
        }
    }
    @future
    private static void manageCCRShareFuture(List<String> ccrUserOldNewStr) {
        manageCCRShare(ccrUserOldNewStr);
    }
    private static void manageCCRShare(List<String> ccrUserOldNewStr){
        List<CCR__Share> ccrShareToInsert = new List<CCR__Share>();
        List<CCR__Share> ccrShareToDelete = new List<CCR__Share>();
        Set<String> delccrShareKeyset = new Set<String>();
        Set<Id> delccrIdSet = new Set<Id>();
        Set<Id> delUserIdSet = new Set<Id>();
        for(String str :ccrUserOldNewStr){
            List<String> strList = str.split('-'); //ccrId+'-'+OldUser+'-'+NewUser - ListString format
            //create list of insert ccr share records 
            if(strList.size() == 3 && strList[2] != 'null'){
                ccrShareToInsert.add(new CCR__Share(
                                        ParentId = strList[0], 
                                        UserOrGroupId = strList[2], 
                                        AccessLevel = 'Edit'
                                    ));
            }
            //create list of delete ccr share records with unique key
            if(strList.size() >= 2 && strList[1] != 'null'){
                delccrIdSet.add((Id)strList[0]);
                delUserIdSet.add((Id)strList[1]);
                delccrShareKeyset.add(strList[0]+'-'+strList[1]);
            }
        }
 
        //fetch existing ccr share records to be deleted
        for(CCR__Share ccrSh : [SELECT Id, ParentId, UserOrGroupId 
                                FROM CCR__Share 
                                WHERE ParentId IN :delccrIdSet AND UserOrGroupId IN :delUserIdSet AND RowCause = 'Manual']){
            String delccrShareKey = ccrSh.ParentId + '-' + ccrSh.UserOrGroupId;
            //map with deleteCCRShare unique key and add it delete list
            if(delccrShareKeyset.contains(delccrShareKey)) ccrShareToDelete.add(ccrSh);
        }
        //insert new ccr share records
        if(!ccrShareToInsert.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(ccrShareToInsert, false);
            LogError.createDMLErrorLog((List<SObject>)ccrShareToInsert, srList, 'CCRTriggerHandler','Insert ccrShare');
        }
        //delete old ccr share records
        if(!ccrShareToDelete.isEmpty()){
            List<Database.DeleteResult> drList = Database.delete(ccrShareToDelete, false);
            LogError.deleteDMLErrorLog((List<SObject>)ccrShareToDelete, drList, 'CCRTriggerHandler','Delete ccrShare');
        }
    }
}