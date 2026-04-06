/**
* Author       :   Saakshi Gupta
* CreatedDate  :   29th May 2020
* Description  :   This class updates the Case owner to Queue if owner is out of office based on the time of the case comment by the Customer,
*                  sends a notification to old Case owner keeping mananger in loop and adds the same email as a private case comment
* TestClass    :   Workday_GenericCaseOwnerChangeTest
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* Old Build		  ----------------------------------------------------
* CS21-3033        Vijay Kumar K R        Jan 27 2025      US ASE / FED queue and routing changes FY25
*/
public class Workday_GenericCaseOwnerChange{
    
    /**
* Author       :   Saakshi Gupta
* CreatedDate  :   29th May 2020
* Description  :   This method updates the Case owner to Queue if owner is out of office based on the time of the case comment by the Customer,
*                  sends a notification to old Case owner keeping mananger in loop and adds the same email as a private case comment
Change logs
* Shiva 	14/2/2023		CS21-1441		Added reason for rerouting to queue due to OOO
*/
    
    public static Integer openQueueThreshold = Integer.ValueOf(System.label.Open_Queue_Threshold);//CS21-1890
    
    public static void updateCaseOwnerToQueue(Map<Id, Case> caseMap, Map<Id, DateTime> caseToCreatedDate){

        List<Case> caseListToUpdate = new List<Case>();
        List<Time> startTimeList = new List<Time>();
        List<Time> endTimeList = new List<Time>();
        List<String> queueIdList = new List<String>();
        Map<String, Boolean> openTAQueueMap = new Map<String, Boolean>();
        Boolean isOwnerChanged = false;
        String oldOwnerName = '';
        String oldOwnerEmail = '';
        String newOwnerId = '';
        
        List<Case_Queue_Mapping__mdt> queueList = [SELECT Queue_Id__c, DeveloperName, Queue_End_Time__c, Queue_Start_Time__c,is_Open_Queue_TA__c FROM Case_Queue_Mapping__mdt];
        
        for(Case_Queue_Mapping__mdt eachCaseQueue : queueList) {
            List<String> splitStartTimeList = eachCaseQueue.Queue_Start_Time__c.split(':');
            Time startTime = Time.newInstance(Integer.valueOf(splitStartTimeList[0]), Integer.valueOf(splitStartTimeList[1]), Integer.valueOf(splitStartTimeList[2]), 0);
            startTimeList.add(startTime);
            
            List<String> splitEndTimeList = eachCaseQueue.Queue_End_Time__c.split(':');
            Time endTime = Time.newInstance(Integer.valueOf(splitEndTimeList[0]), Integer.valueOf(splitEndTimeList[1]), Integer.valueOf(splitEndTimeList[2]), 0);
            endTimeList.add(endTime);
            
            queueIdList.add(eachCaseQueue.Queue_Id__c);
            if(eachCaseQueue.is_Open_Queue_TA__c)
                openTAQueueMap.put(eachCaseQueue.Queue_Id__c, eachCaseQueue.is_Open_Queue_TA__c);
        }
        
        Integer timeListLength = startTimeList.size();
        // CS21-3033
        Id US_FEDERAL_TRENSFER_QUEUE_ID = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName = 'US_Federal_Transfer' Limit 1].Id;
        Id ASE_QUEUE_ID = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName = 'ASE_Transfer' Limit 1].Id;
        Set<Id> ptoAssignmentAccIdSet = new Set<Id>();
        for(Case eachCase : caseMap.values()){
            if(eachCase.AccountId != null){
                ptoAssignmentAccIdSet.add(eachCase.AccountId);
            }
        }
        
        // CS21-3033
        Map<Id, Assigned_Support_Engineer__c> aseByAccIdMap = new Map<Id, Assigned_Support_Engineer__c>();
        if(!ptoAssignmentAccIdSet.isEmpty()){
            aseByAccIdMap = getAccAssignedSupEngRecords(ptoAssignmentAccIdSet, aseByAccIdMap);
        }
        
        for(Case eachCase : caseMap.values()){
            isOwnerChanged = false;
            newOwnerId = '';
            oldOwnerName = eachCase.Owner.FirstName + ' ' + eachCase.Owner.LastName;
            oldOwnerEmail = eachCase.Owner.Email;
            
            //Assign to Igneous Support Queue if the Product Line is Igneous
            if(!String.isBlank(eachCase.Platform__c) && eachCase.Platform__c.equalsIgnoreCase(System.Label.Igneous) && !eachCase.Is_TA_Case__c){
                newOwnerId = System.Label.Igneous_Support_Queue;
                isOwnerChanged = true;
            }
            // CS21-3033 Where an account is both "Federal" and "ASE", default to the ASE queue Or For Account with ASE recod
            else if((eachCase.US_Federal_Account__c
                     && aseByAccIdMap.containskey(eachCase.AccountId))
                    || aseByAccIdMap.containskey(eachCase.AccountId)){
                        newOwnerId = ASE_QUEUE_ID;
                        isOwnerChanged = true; 
                    }
            // CS21-3033: Assign to AMER (ASE) Queue if Account is a Federal Account
            else if(eachCase.US_Federal_Account__c){
                newOwnerId = US_FEDERAL_TRENSFER_QUEUE_ID;
                isOwnerChanged = true;
            }
            
            //If Account is not a Federal Account, assign to Queue based on Case comment created Date/Time
            else {
                DateTime messageCreatedDate = caseToCreatedDate.get(eachCase.Id);
                String createdTimeInPST = messageCreatedDate.format('HH:mm:ss', 'America/Los_Angeles');
                List<String> splitCreatedTimeList = createdTimeInPST.split(':');
                Time createdTime = Time.newInstance(Integer.valueOf(splitCreatedTimeList[0]), Integer.valueOf(splitCreatedTimeList[1]), Integer.valueOf(splitCreatedTimeList[2]), 0);
                
                for(Integer i = 0; i < timeListLength; i++) {
                    if(createdTime >= startTimeList[i] && createdTime <= endTimeList[i]) {
                        if( eachCase.Is_TA_Case__c && !eachCase.Account.US_Federal_Account__c){
                            if( openTAQueueMap.containsKey(queueIdList[i])){
                                newOwnerId = queueIdList[i];
                                isOwnerChanged = true;
                                break;
                            }
                        }else{
                            if(!openTAQueueMap.containsKey(queueIdList[i])){
                                newOwnerId = queueIdList[i];
                                isOwnerChanged = true;
                                break;
                            }
                        }
                    }
                }
            }

            //If none of the above conditions satisfy, assign to Open Queue (corner scenario)
            if(!isOwnerChanged){
                newOwnerId = System.Label.OPEN_Queue;
            }
            
            //Update new Owner and old Owner details on Case
            Case newCase = new Case(Id = eachCase.Id, OwnerId = newOwnerId, Old_Owner_Name__c = oldOwnerName, Old_Owner_Email__c = oldOwnerEmail,CaseTransferType__c = 'AutoRouted - CaseOwner - OutofOffice',
                                    Automated_time_off_case_routing__c = eachCase.Automated_time_off_case_routing__c == 'Enable' ? 'Automatic' : eachCase.Automated_time_off_case_routing__c);
            caseListToUpdate.add(newCase);
        }
        
        Database.SaveResult[] saveResults = Database.update(caseListToUpdate, false);
        
        Set<Id> updatedCaseIds = new Set<Id>();
        for(Database.SaveResult eachResult : saveResults){
            if (eachResult.isSuccess()) {
                if(eachResult.getId() != null){
                    updatedCaseIds.add(eachResult.getId());
                }
            }
            else {
                for(Database.Error eachError : eachResult.getErrors()) {
                    System.debug('The following error has occurred:');
                    System.debug(eachError.getStatusCode() + ': ' + eachError.getMessage());
                    System.debug('Fields that affected this error: ' + eachError.getFields());
                }
            }
        }
        
        //Send email to old owner and add same email as Case comment only for successful case updations
        if(!updatedCaseIds.isEmpty()) {
            sendEmailToOldOwnerAfterCaseReassign(updatedCaseIds, caseMap);
        }
    }
    
    /**
    * @Method: getAccAssignedSupEngRecords 
    * Description: fetch Assigned_Support_Engineer__c record
    * @params: Map<Id, Assigned_Support_Engineer__c> nonProactiveAccIdSet
    * @return: Map<Id, Assigned_Support_Engineer__c>
    **/
    public static Map<Id, Assigned_Support_Engineer__c> getAccAssignedSupEngRecords(Set<Id> nonProactiveAccIdSet, Map<Id, Assigned_Support_Engineer__c> aseByAccIdMap){
        for(Assigned_Support_Engineer__c objAse : [SELECT Id, Account__c 
                                                   FROM Assigned_Support_Engineer__c 
                                                   WHERE Account__c IN: nonProactiveAccIdSet Limit 1]){
                                                       aseByAccIdMap.put(objAse.Account__c, objAse);
                                                   }
        return aseByAccIdMap;
    }
    
    /**
    * Author       :   Saakshi Gupta
    * CreatedDate  :   29th May 2020
    * Description  :   Prepare and send email to old owner, Owner's Manager and slack channel, informing of new comment from Customer and case reassignment
    */
    private static void sendEmailToOldOwnerAfterCaseReassign(Set<Id> updatedCaseIds, Map<Id, Case> caseMap) {
        List<String> toAddressList;
        List<String> ccAddressList;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        EmailTemplate workdayTemplate = [SELECT Id, HtmlValue, Subject, Description, DeveloperName, Body
                                         FROM EmailTemplate
                                         WHERE DeveloperName = 'Workday_Automated_Time_Off_Notification'];
        //WHERE DeveloperName = 'Workday_Support_Agent_On_Leave_Template1'];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'support@rubrik.com'];
        
        //User supportBot = [SELECT Id FROM User WHERE Username = 'bhanum@rubrik.com.sbot.rbkuat'];
        
        for(Id eachCaseId : updatedCaseIds){
            toAddressList = new List<String>();
            ccAddressList = new List<String>();
            
            Case caseRec = caseMap.get(eachCaseId);
            
            toAddressList.add(caseRec.Owner.Email);
            ccAddressList.add(System.Label.Support_Email_Address);
            
            if(!String.isBlank(caseRec.Owner_Manager_Email__c)) {
                ccAddressList.add(caseRec.Owner_Manager_Email__c);
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            /*
* The below parameter settings took me one whole day with 12 hours of continuous testing, debugging and fixing.
* Modify at your own risk! I went through multiple articles and blogs and finally achieved this. To be honest,
* this is the dumbest creation by Salesforce with no proper documentation as well. They just leave you to
* it to figure out why they did what they did
*/
            
            //So many people want to receive this email
            mail.setToAddresses(toAddressList);
            mail.setCcAddresses(ccAddressList); 
            List<String> slackEmails = new List<String>();
            slackEmails.add(System.Label.Support_Case_Transfer_Slack_Channel_Email);
            if(caseRec.Is_TA_Case__c && !caseRec.US_Federal_Account__c){
                slackEmails.add(System.Label.ta_case_transfer_SlackEmail);
            }
            mail.setBccAddresses(slackEmails);
            
            /*
* Since we want to use ccAddresses, we need to map these parameters. But to make sure the below body and subject
* paramter don't override template's body and subject, we need setTreatBodiesAsTemplate to be set to true so that
* the below parameters are treated as templates and merge fields work. Told ya! Dumb!
*/
            mail.setTemplateId(workdayTemplate.Id);
            //mail.setPlainTextBody(workdayTemplate.Body);
            //mail.setHtmlBody(workdayTemplate.htmlValue);
            //mail.setSubject(workdayTemplate.Subject);
            //mail.setTreatBodiesAsTemplate(true);
            
            //Setting WhatId as Case Id for merge fields. Very important!
            mail.setWhatId(eachCaseId);
            
            /*
* We don't want this email sent to the old owner of the case to be save as Activity history under the case
*/
            mail.setSaveAsActivity(false);
            
            /*
* TargetObjectId took my entire day because it seems it is a required paramter when Template is used but
* cannot be used together with WhatId if this is not a Contact Id. But we need WhatId otherwise merge fields
* will not work. Don't ask me the logic. Only god knows! Let me know if some day you happen to figure this
* out. For now, setting to null. I love null!
* Also setting setTreatTargetObjectAsRecipient to false so that TargetObjectId is not treated as a recipient
* because in our case it would immediately throw error since we are setting to null. You know why we have
* set it to null now.
*/
            //mail.setTargetObjectId(null);
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setTreatTargetObjectAsRecipient(false);
            
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            
            emailList.add(mail);
        }
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList, false);
        
        for(Messaging.SendEmailResult eachResult : results) {
            if(!eachResult.isSuccess()) {
                for(Messaging.SendEmailError eachError : eachResult.getErrors()) {
                    System.debug('The following error has occurred for the record : ' + eachError.getTargetObjectId());
                    System.debug(eachError.getStatusCode() + ': ' + eachError.getMessage());
                    System.debug('Fields that affected this error: ' + eachError.getFields());
                }
            }
        }
    }
}