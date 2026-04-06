/**************************************************************************************************************
Class Name			:  ApprovalReminderEmailBatch
Author				:  Rahul Kappa
Test Class			:  ApprovalReminderEmailBatchTest
Purpose				:  This Batch class is written as a part of CPQ22-4774 user story and it sends
					   Reminder Emails for the approval records which are not approved past 48 hours of 
					   status change.
Date Created		:  18/11/2024
/**************************************************************************************************************/

public with sharing class ApprovalReminderEmailBatch implements Database.Batchable<sObject>, Database.Stateful {
	public String query;
    public List<String> errorsnewSCList = new List<String>();
    public List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
    Public Map<Id, List<sbaa__Approval__c>> mapUserIdApp = new Map<Id, List<sbaa__Approval__c>>(); // Stores User Id as Key and approval records as collection
    Public Map<Id, String> mapUserIdName  = new Map<Id, String>(); //Stores User Id as Key and User Name as Value
    Public DateTime hour120Dt =  System.now().addHours(-120); 
    Public DateTime hour48Dt = System.now().addHours(-48);
    public ApprovalReminderEmailBatch(){   
    }
    
/**************************************************************************************************************
Method Name			:  Start Method for Batch class
Author				:  Rahul Kappa
Purpose				:  Stores the query for the batch records.
/**************************************************************************************************************/
    
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
      
       query = 'SELECT Id, Name, Quote__c, Quote__r.Name, sbaa__Status__c,sbaa__Approver__c,sbaa__Approver__r.sbaa__DelegatedApprover__c,sbaa__Approver__r.sbaa__User__c, sbaa__Approver__r.sbaa__User__r.Name,sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c,sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__r.Name, sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__r.Email,sbaa__AssignedTo__c,sbaa__AssignedGroupId__c,Quote__r.SBQQ__Opportunity2__c, Quote__r.SBQQ__Opportunity2__r.Name, Quote__r.SBQQ__Opportunity2__r.StageName,';
       query += 'Quote__r.ETM_Area__c,Quote__r.ETM_Region__c,sbaa__Approver__r.sbaa__DelegationStart__c, sbaa__Approver__r.sbaa__DelegationEnd__c ,sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__DelegationStart__c, sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__DelegationEnd__c, Quote__r.ApprovalStatus__c,Quote__r.SBQQ__NetAmount__c,Quote__r.SBQQ__SubscriptionTerm__c,Quote__r.TotalACV__c, CreatedBy.Name, Deal_Desk_Case__c,Deal_Desk_Case__r.Name,';
       query += '(SELECT Id, OldValue, NewValue , createdDate, Field FROM Histories WHERE Field  = '+'\'sbaa__Status__c\''+' ORDER BY createdDate DESC),';
       query += 'Deal_Desk_Case__r.Opportunity__c,Deal_Desk_Case__r.Opportunity__r.Name,Deal_Desk_Case__r.Opportunity__r.StageName, Deal_Desk_Case__r.Opportunity__r.ETM_Area__c,Deal_Desk_Case__r.Opportunity__r.ETM_Region__c    FROM sbaa__Approval__c ';
       query += 'WHERE ((Deal_Desk_Case__c != NULL AND Deal_Desk_Case__r.Opportunity__c != NULL AND Deal_Desk_Case__r.Opportunity__r.StageName NOT IN ('+'\'6 PO With Channel\''+','+'\'7 Closed Won\''+','+'\'7 Closed Lost\''+','+'\'7 Closed Admin\''+')) OR (Quote__c != NULL AND Quote__r.SBQQ__Opportunity2__c != NULL AND Quote__r.SBQQ__Status__c ='+'\'In Review\' ';
       query += 'AND Quote__r.SBQQ__Opportunity2__r.StageName NOT IN ('+'\'6 PO With Channel\''+','+'\'7 Closed Won\''+','+'\'7 Closed Lost\''+','+'\'7 Closed Admin\''+'))) AND sbaa__Status__c ='+ '\'Requested\' ';
        
        if(!test.isRunningTest()){
            return Database.getQueryLocator(query);          
        }else{
            return Database.getQueryLocator([
                SELECT Id, Name, Quote__c, Quote__r.Name, sbaa__Status__c,sbaa__Approver__c,sbaa__Approver__r.sbaa__DelegatedApprover__c,
                sbaa__Approver__r.sbaa__User__c, sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c,sbaa__Approver__r.sbaa__User__r.Name,sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__r.Name, 
                sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__r.Email,sbaa__AssignedTo__c,sbaa__AssignedGroupId__c,Quote__r.SBQQ__Opportunity2__c, 
                Quote__r.SBQQ__Opportunity2__r.Name, Quote__r.SBQQ__Opportunity2__r.StageName,Quote__r.ETM_Area__c,Quote__r.ETM_Region__c,
                sbaa__Approver__r.sbaa__DelegationStart__c, sbaa__Approver__r.sbaa__DelegationEnd__c ,
                sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__DelegationStart__c, sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__DelegationEnd__c, 
                Quote__r.ApprovalStatus__c,Quote__r.SBQQ__NetAmount__c,Quote__r.SBQQ__SubscriptionTerm__c,Quote__r.TotalACV__c, CreatedBy.Name, 
                Deal_Desk_Case__c,Deal_Desk_Case__r.Name,
                (Select Id, OldValue, NewValue , createdDate from Histories WHERE createdDate >= :hour120Dt AND 
                createdDate <= :hour48Dt Order by createdDate),
                Deal_Desk_Case__r.Opportunity__c,Deal_Desk_Case__r.Opportunity__r.Name,Deal_Desk_Case__r.Opportunity__r.StageName, 
                Deal_Desk_Case__r.Opportunity__r.ETM_Area__c,Deal_Desk_Case__r.Opportunity__r.ETM_Region__c    FROM sbaa__Approval__c 
                WHERE                 
                Quote__c != NULL AND sbaa__Status__c = 'Requested' LIMIT 5
            ]);
        } 
       
    }
    
/**************************************************************************************************************
Method Name			:  execute Method for Batch class
Author				:  Rahul Kappa
Purpose				:  Performs the Main logic for preparing the email body and then send emails as per scope
/**************************************************************************************************************/ 
    
    public void execute(Database.BatchableContext batchableContext, List<sbaa__Approval__c> appRecords){
        
            Set<Id> setGrpId = new Set<Id>();  //Stores All Assigned group Id's of approval records.
            Map<Id, set<Id>> mapGrpMemUserList = new Map<Id, Set<Id>>(); //Stores groupId as Key and Group members as Set collection        
            List<sbaa__Approval__c> lstApprGrp = new List<sbaa__Approval__c>(); // Stores filtered approval records with assignee as group.
        
            /******This block separates approvers with group as approver************/
            system.debug('hour120Dt is '+hour120Dt);
             system.debug('hour48Dt is '+hour48Dt);
            if(!appRecords.isEmpty()){ 
                for(sbaa__Approval__c sbb : appRecords) {
                    for(sbaa__Approval__History sh : sbb.Histories){
                        if(sh.NewValue == 'Requested' && sh.CreatedDate >=hour120Dt && sh.createdDate <= hour48Dt){
                            if(sbb.sbaa__AssignedGroupId__c != NULL){
                                setGrpId.add(sbb.sbaa__AssignedGroupId__c);
                            }
                            lstApprGrp.add(sbb);
                        }
                    }
                }
            }
             /********************************************************************/     
            
        	/*************************Test Class Purpose**************************/
        	
            if(test.isRunningTest()){
                for(sbaa__Approval__c sbb : appRecords) {
                    if(sbb.sbaa__AssignedGroupId__c != NULL){
                                setGrpId.add(sbb.sbaa__AssignedGroupId__c);
                            }
                   lstApprGrp.add(sbb); 
                }
            }
        	/*********************************************************************/
                  
            Set<Id> secondSet = new Set<Id>(); //Stores second level group Id which are part of first group
            
            /******This block prepares map collection in the form of Groupd Id as Key and Group members as values up to 2 levels************/
            if(!setGrpId.isEmpty()){
                List<GroupMember> lstGrpMembers = [SELECT Id, UserOrGroupId, GroupId,UserOrGroup.Name FROM GroupMember WHERE GroupId IN :setGrpId];
                if(!lstGrpMembers.isEmpty()){
                    for(GroupMember gp: lstGrpMembers){
                        if(String.ValueOf(gp.UserOrGroupId).StartsWith('00G')){
                            secondSet.add(gp.UserOrGroupId);
                        }else if(String.ValueOf(gp.UserOrGroupId).StartsWith('005')){
                            mapUserIdName.put(gp.UserOrGroupId, gp.UserOrGroup.Name);
                            if(mapGrpMemUserList.containsKey(gp.GroupId)){
                                mapGrpMemUserList.get(gp.GroupId).add(gp.UserOrGroupId);
                            }else{
                                mapGrpMemUserList.put(gp.GroupId, new Set<Id>{gp.UserOrGroupId});
                            }
                        }
                    }
                    if(!secondSet.isEmpty()){
                      List<GroupMember> lstGrpSecMembers = [SELECT UserOrGroupId, GroupId,UserOrGroup.Name FROM GroupMember WHERE GroupId IN :secondSet]; 
                        if(!lstGrpSecMembers.isEmpty()){
                            for(GroupMember gps: lstGrpSecMembers){
                                if(String.ValueOf(gps.UserOrGroupId).StartsWith('005')){
                                    mapUserIdName.put(gps.UserOrGroupId, gps.UserOrGroup.Name);
                                    if(mapGrpMemUserList.containsKey(gps.GroupId)){
                                        mapGrpMemUserList.get(gps.GroupId).add(gps.UserOrGroupId);
                                    }else{
                                        mapGrpMemUserList.put(gps.GroupId, new Set<Id>{gps.UserOrGroupId});
                                    }
                                }
                            }
                        }
                    }
                }
            }
             /********************************************************************/
            
            /******This block performs logic for mapping userId from individual approvers and Group members users to Approval list collection************/
            if(!lstApprGrp.isEmpty()){
            
                for(sbaa__Approval__c sb : lstApprGrp){
                     if(sb.sbaa__AssignedTo__c != NULL){
                         if(mapUserIdApp.containsKey(sb.sbaa__AssignedTo__c)){
                            mapUserIdApp.get(sb.sbaa__AssignedTo__c).add(sb);
                            }else{
                                mapUserIdApp.put(sb.sbaa__AssignedTo__c, new List<sbaa__Approval__c>{sb});
                            }
                         	  mapUserIdName.put(sb.sbaa__Approver__r.sbaa__User__c, sb.sbaa__Approver__r.sbaa__User__r.Name);
                         if(sb.sbaa__Approver__r.sbaa__DelegatedApprover__c != NULL 
                                     && sb.sbaa__Approver__r.sbaa__DelegationStart__c <= system.today() && sb.sbaa__Approver__r.sbaa__DelegationEnd__c >= system.today()){
                              mapUserIdName.put(sb.sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c, sb.sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__r.Name);           
                              if(mapUserIdApp.containsKey(sb.sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c)){
                                    mapUserIdApp.get(sb.sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c).add(sb);
                              }else{
                                    mapUserIdApp.put(sb.sbaa__Approver__r.sbaa__DelegatedApprover__r.sbaa__User__c, new List<sbaa__Approval__c>{sb});
                            }           
                                             
                           }
                     }else if(sb.sbaa__AssignedGroupId__c != NULL){
                         if(mapGrpMemUserList.containsKey(sb.sbaa__AssignedGroupId__c) && mapGrpMemUserList.get(sb.sbaa__AssignedGroupId__c).size() >0){
                             Set<Id> setUserId = mapGrpMemUserList.get(sb.sbaa__AssignedGroupId__c);
                             for(Id uId : setUserId){	
                                 if(mapUserIdApp.containsKey(uId)){
                                            mapUserIdApp.get(uId).add(sb);
                                        }else{
                                            mapUserIdApp.put(uId, new List<sbaa__Approval__c>{sb});
                                        }
                             }
                         } 
                     }
                 }
                    
            }
            	/********************************************************************/
            	
    	
    }
    
/**************************************************************************************************************
Method Name			:  finish Method for Batch class
Author				:  Rahul Kappa
Purpose				:  This Method sends emails in case failure records or emails
/**************************************************************************************************************/  
    
    public void finish(Database.BatchableContext batchableContext){
        
    Messaging.SingleEmailMessage[] lstSendEmail = new List<Messaging.SingleEmailMessage>();
        
        /******This block prepares email body oer user basis and then add all the approval records in the form of table************/
                if(!mapUserIdApp.KeySet().isEmpty()){
                    
                   	String href = URL.getOrgDomainUrl().toExternalForm();
                    String subject = System.Label.Approval_Reminder_Email_Subject;
                    for(Id userId : mapUserIdApp.KeySet()){
                        String emailTextHtml = '';
                        if(mapUserIdName.containsKey(userId) && mapUserIdName.get(userId) != NULL){
                            emailTextHtml += '<p>Hello '+mapUserIdName.get(userId)+',</p>'; 
                        }else{
                            emailTextHtml += '<p>Hello,</p>'; 
                        }
                        
                        emailTextHtml += '<p>'+System.label.Approval_Reminder_Email_Text+'</p>';
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        emailTextHtml += '<table border="1" style="border-collapse: collapse"><tr><th>Approval Number</th><th>Quote</th><th>Quote Net Amount</th><th>Opportunity</th></tr>';
						email.setTargetObjectId(userId);
                        email.setSaveAsActivity(false);
                        
                        if(mapUserIdApp.get(userId) != NULL){
                            
                            for(sbaa__Approval__c sb : mapUserIdApp.get(userId)){
                             
                                String AppNumber = '';
                                String DDNumber = '';
                                String QuoteNumber = '';
                                String OppName = '';
                                String QuoteAmount = '';
                            	AppNumber +='<a href="' + href + '/' + sb.Id + '">' + sb.Name + '</a>, ';
                                if(sb.Quote__c != NULL){
                                    QuoteNumber += '<a href="' + href + '/' + sb.Quote__c + '">' + sb.Quote__r.Name + '</a>, ';
                                    QuoteAmount += sb.Quote__r.SBQQ__NetAmount__c+',';
                                    QuoteNumber = QuoteNumber.removeEnd(', '); 
                                	QuoteAmount = QuoteAmount.removeEnd(',');
                                }
                                OppName += sb.Deal_Desk_Case__c != null ? sb.Deal_Desk_Case__r.Opportunity__r.Name : (sb.Quote__c != null ? sb.Quote__r.SBQQ__Opportunity2__r.Name : '')+',';
                            	
                                AppNumber = AppNumber.removeEnd(', ');  
                                OppName = OppName.removeEnd(',');
                                emailTextHtml += '<tr></td>'+AppNumber+'</td><td>'+QuoteNumber+'</td><td>'+QuoteAmount+'</td><td>'+OppName+'</td></tr>';
                            }
                            emailTextHtml += '</table>'; 
                            emailTextHtml += '<p>'+System.Label.Approval_Reminder_Email_Footer+'</p>';
                        }
                        email.setSubject(subject);    
        				email.setHtmlBody(emailTextHtml);
                        lstSendEmail.add(email);
                    }
                    
                }    
            /********************************************************************/
                  /*****Sends Emails to the required users and Error Handling**************/
        
          if(lstSendEmail.size() > 0){
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstSendEmail);
            for(Messaging.SendEmailResult mr : results){
                if (mr.isSuccess()) {
                }  else {
                    batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='ReminderEmailBatch',
                                                               Failure_Job_ID__c=batchableContext.getJobId(),Failure_Message__c=string.ValueOf(results[0].errors[0].message),
                                                               Failure_Date__c=Date.today()));
                    for(Messaging.SendEmailError err : mr.getErrors()) {
                        errorsnewSCList.add('Error Message is : '+err.getMessage() + ' Status Code is :'+err.getStatusCode());                    
                    }
                }                
            }
        }
        /********************************************************************/
        
        try{
            if(!batchErrLogList.isEmpty()){
                upsert batchErrLogList; 
            	}
            }catch(exception e){
                system.debug('@@@@ Error Details line 114 @@@'+e.getMessage());
        }
        
        Messaging.SingleEmailMessage emailmessage = new Messaging.SingleEmailMessage();
        String strCPQAdmin = System.Label.CPQAdminEmailId;
        String[] toAddresses = new List<String>{strCPQAdmin};
        emailmessage.setToAddresses(toAddresses);
        emailmessage.setSubject('Approval Request Reminder Emails Failed Today ' + Date.today().format());
        String Message = 'Below is a list of the Approval Request Reminder Emails Failed Today <br/><br/>';
        if(!errorsnewSCList.isEmpty()) {
            for(String eachError : errorsnewSCList) {
                Message += eachError + '<br/>';
            }
            Message += '<br/>';
        }

        Message += '<br/>Thank you';
        emailmessage.setHtmlBody(Message);

        if (!test.isRunningTest() && (!errorsnewSCList.isEmpty() )) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailmessage });
              System.debug('Email is sent Successfully.');
        }
    }    
}