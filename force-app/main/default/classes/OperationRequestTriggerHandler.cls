/**
 * @description
 * Added as part of SAL26-323.
 * This Apex class is the handler class of Operations_Request__c object..
 */ 
public without sharing class OperationRequestTriggerHandler extends TriggerManager.GenericTriggerHandler{
    
    /*=============================================================================================================================================*/
    /** 
     * @description
     * @param newRecords
     * This method is to write the logic on before insert 
     */
    public override void onBeforeInsert(List<sObject> newRecords) {
        //System.debug('newRecords'+newRecords);
        try{
            List<Operations_Request__c> newOperations =(List<Operations_Request__c>)newRecords;
            Set<Id> managerId=new Set<Id>();
            For(Operations_Request__c op:newOperations){
                if(op.Current_account_owner__c!=null)
                    managerId.add(op.Current_account_owner__c);
                if(op.Future_account_owner__c!=null)
                    managerId.add(op.Future_account_owner__c);
            }
            if(!managerId.IsEmpty()){
                Map<Id,User> userMap =new Map<Id,User>([Select Id,ManagerId from User where Id IN :managerId]);
                if(userMap!=null){
                    For(Operations_Request__c op:newOperations){
                        if(op.Current_account_owner__c!=null)
                            op.Current_Owner_Manager__c=userMap.get(op.Current_account_owner__c).ManagerId;
                        if(op.Future_account_owner__c!=null)
                            op.Future_owner_manager__c=userMap.get(op.Future_account_owner__c).ManagerId;
                    }
                }
            }
            Set<Id> futAccId = new Set<Id>();
            for(Operations_Request__c op:newOperations){
                if(op.Issue__c == 'Entitlement/Asset Transfer' && op.Future_Account__c!=null){
                    futAccId.add(op.Future_Account__c);
                }
            }
            if(!futAccId.isEmpty() && futAccId!=null){
                Map<Id,Account> accMap =new Map<Id,Account>([Select Id,OwnerId, Owner.ManagerId from Account where Id IN :futAccId]);
                if(accMap!=null){
                    for(Operations_Request__c op:newOperations){
                        op.Future_account_owner__c = accMap.get(op.Future_Account__c).OwnerId;
                        op.Future_owner_manager__c = accMap.get(op.Future_Account__c).Owner.ManagerId;
                    }
                }
            }
        }
        catch(exception ex){
            insert LogError.CreateGenericErrorLog('OperationRequestTriggerHandler',ex,'Before Insert Operations Request');
        }
        
    }
    /*=============================================================================================================================================*/ 
    /** 
     * @description
     * @param oldRecordsMap
     * @param newRecordsMap
     * This method is to write the logic on before update 
     */
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        
        try{
            List<Operations_Request__c> newOperations =(List<Operations_Request__c>)newRecordsMap.values();
            Map<Id,Operations_Request__c> oldOperationMap =(Map<Id,Operations_Request__c>)oldRecordsMap;
            Set<Id> managerId=new Set<Id>();
            For(Operations_Request__c op:newOperations){
                Operations_Request__c oldOper = oldOperationMap.get(op.Id);
                if(op.Current_account_owner__c!=null && op.Current_account_owner__c!=oldOper.Current_account_owner__c)
                    managerId.add(op.Current_account_owner__c);
                if(op.Future_account_owner__c!=null && op.Future_account_owner__c!=oldOper.Future_account_owner__c)
                    managerId.add(op.Future_account_owner__c);
            }
            if(!managerId.IsEmpty()){
                Map<Id,User> userMap =new Map<Id,User>([Select Id,ManagerId from User where Id IN :managerId]);
                if(userMap!=null){
                    For(Operations_Request__c op:newOperations){
                        Operations_Request__c oldOper = oldOperationMap.get(op.Id);
                        if(op.Current_account_owner__c!=null && op.Current_account_owner__c!=oldOper.Current_account_owner__c)
                            op.Current_Owner_Manager__c=userMap.get(op.Current_account_owner__c).ManagerId;
                        if(op.Future_account_owner__c!=null && op.Future_account_owner__c!=oldOper.Future_account_owner__c)
                            op.Future_owner_manager__c=userMap.get(op.Future_account_owner__c).ManagerId;
                    }
                }
            }
            Set<Id> futAccId = new Set<Id>();
            for(Operations_Request__c op:newOperations){
                Operations_Request__c oldOper = oldOperationMap.get(op.Id);
                if(op.Issue__c == 'Entitlement/Asset Transfer' && op.Future_Account__c!=null && op.Future_Account__c!=oldOper.Future_Account__c){
                    futAccId.add(op.Future_Account__c);
                }
            }
            if(!futAccId.isEmpty() && futAccId!=null){
                Map<Id,Account> accMap =new Map<Id,Account>([Select Id,OwnerId,Owner.ManagerId from Account where Id IN :futAccId]);
                if(accMap!=null){
                    for(Operations_Request__c op:newOperations){
                        op.Future_account_owner__c = accMap.get(op.Future_Account__c).OwnerId;
                        op.Future_owner_manager__c = accMap.get(op.Future_Account__c).Owner.ManagerId;
                    }
                }
            }
            /*** Start SLA25-646 */
            Boolean isEnabled = FeatureManagement.checkPermission('Allow_to_Edit_OR_Issue');
            for (Operations_Request__c op : newOperations) {
                if(!isEnabled && op.Issue__c != oldOperationMap.get(op.Id).Issue__c){
                    op.addError('You do not have the required permission to edit the Issue field.');
                }
            }
            /*** End SLA25-646 */
        }
        catch(exception ex){
            insert LogError.CreateGenericErrorLog('OperationRequestTriggerHandler',ex,'Before Update Operations Request');
        }
        
    }
    /*=============================================================================================================================================*/
    /** 
     * @description
     * @param oldRecordsMap
     * This method is to write the logic on before deletion
     */
    public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap) {
        system.debug(System.LoggingLevel.DEBUG,'this method id for before deletion operation.');
    }
    /*=============================================================================================================================================*/
    /** 
     * @description
     * @param newRecordsMap
     * This method is to write the logic once the record is insrted
     */
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        try{
            OperationRequestTriggerHelper.shareRecords((List<Operations_Request__c>)newRecordsMap.values(), null);
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            List<OrgWideEmailAddress> owEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
            List<EmailTemplate> emTemp = [SELECT Id, DeveloperName, Subject, HtmlValue FROM EmailTemplate where DeveloperName in ('Admin_Queue_Req_Submission_Notification','Admin_Queue_Acc_Transfer_Req_Submitted'
                                                                                                                                  ,'Admin_Queue_Req_Other_than_Acc_and_Ent','Admin_Queue_Request_has_been_completed','Admin_Queue_Request_has_been_rejected')];
            Map<String,Id> emTempMap = new Map<String,Id>();
            for(EmailTemplate et : emTemp){
                if(!emTempMap.containsKey(et.DeveloperName))
                emTempMap.put(et.DeveloperName,et.Id);
            }
            Email_Preferences__mdt mdt = [Select Id,Receipient__c,cc__c from Email_Preferences__mdt where MasterLabel = 'Admin_Queue_Req_Submission_Notification' LIMIT 1];
            
            List<Operations_Request__c> newOperations =(List<Operations_Request__c>)newRecordsMap.values();
            set<String> toUserIds = new set<String>();
            set<string> ccuserid = new set<string>();
            
            For(Operations_Request__c op1 :newOperations){
                if(op1.Issue__c=='Entitlement/Asset Transfer' && op1.Current_account_owner__c!=null){
                    toUserIds.add(op1.Current_account_owner__c);
                    if(op1.Future_account_owner__c!=null){
                        ccuserid.add(op1.Future_account_owner__c);
                    }
                    if(mdt != null){
                       ccuserid.add(mdt.Receipient__c); 
                    }
                    Messaging.SingleEmailMessage mail = EmailHelper.getSingleEmailMessageObj(toUserIds, ccuserid, null, op1.Current_account_owner__c, op1.Id, emTempMap.get('Admin_Queue_Req_Submission_Notification'));
                    if(!owEmail.isEmpty()){
                        mail.setOrgWideEmailAddressId(owEmail[0].Id); 
                    }
                    mails.add(mail);
                    toUserIds.clear();
                    ccuserid.clear();
                }
                if(op1.Issue__c=='Account Transfer'){
                    toUserIds.add(op1.OwnerId);
                    if(mdt != null){
                        system.debug(System.LoggingLevel.DEBUG,'mdt is not null');
                      // ccuserid.add(mdt.Receipient__c); //commented as per SAL25-369
                    }
                    Messaging.SingleEmailMessage mail = EmailHelper.getSingleEmailMessageObj(toUserIds, ccuserid, null, op1.OwnerId, op1.Id, emTempMap.get('Admin_Queue_Acc_Transfer_Req_Submitted'));
                    if(!owEmail.isEmpty()){
                        mail.setOrgWideEmailAddressId(owEmail[0].Id); 
                    }
                    mails.add(mail);
                    toUserIds.clear();
                    ccuserid.clear();
                }
                if(op1.Issue__c!='Account Transfer' && op1.Issue__c!='Entitlement/Asset Transfer' ){
                    toUserIds.add(op1.OwnerId);
                    if(mdt != null){
                       ccuserid.add(mdt.cc__c); 
                    }
                    Messaging.SingleEmailMessage mail = EmailHelper.getSingleEmailMessageObj(toUserIds, ccuserid, null, op1.OwnerId, op1.Id, emTempMap.get('Admin_Queue_Req_Other_than_Acc_and_Ent'));
                    mail.setSubject('Your '+op1.Issue__c+' Request has been Submitted');
                    if(!owEmail.isEmpty()){
                        mail.setOrgWideEmailAddressId(owEmail[0].Id); 
                    }
                    mails.add(mail);
                    toUserIds.clear();
                    ccuserid.clear();
                }
            }
            if(!mails.isEmpty() && !test.isRunningTest()){
                flowControll.taskTrigger = false;
                Messaging.sendEmail(mails,false);
                flowControll.taskTrigger = true;
            }
        }
        catch(exception ex){
            insert LogError.CreateGenericErrorLog('OperationRequestTriggerHandler',ex,'After Insert Operations Request');
        }
        
    }
    
    /*=============================================================================================================================================*/
    /** 
     * @description
     * @param oldRecordsMap
     * @param newRecordsMap
     * This method is to write the logic once the record is updated
     */
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        try{
            OperationRequestTriggerHelper.shareRecords((List<Operations_Request__c>)newRecordsMap.values(), (Map<Id,Operations_Request__c>)oldRecordsMap);
            List<Messaging.SingleEmailMessage> mails1 = new List<Messaging.SingleEmailMessage>();
            List<OrgWideEmailAddress> owEmail1 = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
            List<EmailTemplate> emTemp = [SELECT Id, DeveloperName, Subject, HtmlValue FROM EmailTemplate where DeveloperName in ('Admin_Queue_Req_Submission_Notification','Admin_Queue_Acc_Transfer_Req_Submitted'
                                                                                                                                  ,'Admin_Queue_Req_Other_than_Acc_and_Ent','Admin_Queue_Request_has_been_completed','Admin_Queue_Request_has_been_rejected')];
            Map<String,Id> emTempMap = new Map<String,Id>();
            for(EmailTemplate et : emTemp){
                if(!emTempMap.containsKey(et.DeveloperName))
                emTempMap.put(et.DeveloperName,et.Id);
            }
            Email_Preferences__mdt mdt1 = [Select Id,Receipient__c from Email_Preferences__mdt where MasterLabel = 'Admin_Queue_Req_Submission_Notification' LIMIT 1];
            
            List<Operations_Request__c> newOperations1 =(List<Operations_Request__c>)newRecordsMap.values();
            Map<Id,Operations_Request__c> oldOperationMap =(Map<Id,Operations_Request__c>)oldRecordsMap;
            set<String> toUserIds1 = new set<String>();
            set<string> ccuserid1 = new set<string>();
            List<Account_Stage__c> accountStageList = new List<Account_Stage__c>();// SAL26-323
            List<Id> futureAccountOwnerList = new List<Id>();//SAL26-323
            List<String> territoryStructureTypes = new List<String>();//SAL26-323
            map<Id,string> UTAMap = new map<Id,string>();//SAL26-323
            List<Operations_Request__c> opListToUpdate = new List<Operations_Request__c>();//SAL26-323
            //SAL26-323
            List<ETMStage_Monitoring__c> etmStageMonitoringList = new List<ETMStage_Monitoring__c>();
            etmStageMonitoringList = [select id from ETMStage_Monitoring__c where Status__c = 'New' and Initiated_By__c = 'Admin Queue'];

            For(Operations_Request__c op2 :newOperations1){
                if(op2.Issue__c=='Entitlement/Asset Transfer' && op2.Current_account_owner__c!=null && op2.Current_account_owner__c!=oldOperationMap.get(op2.Id).Current_account_owner__c){
                    toUserIds1.add(op2.Current_account_owner__c);
                    if(op2.Future_account_owner__c!=null){
                        ccuserid1.add(op2.Future_account_owner__c);  
                    }
                    if(mdt1 != null){
                       ccuserid1.add(mdt1.Receipient__c); 
                    }
                    Messaging.SingleEmailMessage mail2 = EmailHelper.getSingleEmailMessageObj(toUserIds1, ccuserid1, null, op2.Current_account_owner__c, op2.Id, emTempMap.get('Admin_Queue_Req_Submission_Notification'));
                    if(!owEmail1.isEmpty()){
                        mail2.setOrgWideEmailAddressId(owEmail1[0].Id);
                    }
                    mails1.add(mail2);
                    toUserIds1.clear();
                    ccuserid1.clear();
                }
                if(op2.Status__c=='Complete'  && op2.Status__c!=oldOperationMap.get(op2.Id).Status__c){
                   toUserIds1.add(op2.OwnerId);
                    Messaging.SingleEmailMessage mail2 = EmailHelper.getSingleEmailMessageObj(toUserIds1, ccuserid1, null, op2.OwnerId, op2.Id, emTempMap.get('Admin_Queue_Request_has_been_completed'));
                    mail2.setSubject('Your '+op2.Issue__c+' Request has been Completed');
                    if(!owEmail1.isEmpty()){
                        mail2.setOrgWideEmailAddressId(owEmail1[0].Id);
                    }
                    mails1.add(mail2);
                    toUserIds1.clear();
                    ccuserid1.clear();
                   }
                if(op2.Status__c=='Rejected'  && op2.Status__c!=oldOperationMap.get(op2.Id).Status__c){
                   toUserIds1.add(op2.OwnerId);
                    Messaging.SingleEmailMessage mail2 = EmailHelper.getSingleEmailMessageObj(toUserIds1, ccuserid1, null, op2.OwnerId, op2.Id, emTempMap.get('Admin_Queue_Request_has_been_rejected'));
                    mail2.setSubject('Your '+op2.Issue__c+' Request has been Rejected');
                    if(!owEmail1.isEmpty()){
                        mail2.setOrgWideEmailAddressId(owEmail1[0].Id);
                    }
                    mails1.add(mail2);
                    toUserIds1.clear();
                    ccuserid1.clear();
                   }
                //SAL26-323
                if(op2.Account_Transfer_Approval_Status__c == 'Approved' && op2.Account_Transfer_Approval_Status__c!=oldOperationMap.get(op2.Id).Account_Transfer_Approval_Status__c && op2.Territory_Structure_Type__c != null && op2.Future_account_owner__c != null && op2.Account_Move_Reason__c != null){
                    futureAccountOwnerList.add(op2.Future_account_owner__c);
                    territoryStructureTypes.add(op2.Territory_Structure_Type__c);
                }
            }
            //SAL26-323
            if(!futureAccountOwnerList.IsEmpty()){
                List<UserTerritory2Association> UTAList = [Select id,UserId,Territory2.Adaptive_Territory_Id__c, User.Name from UserTerritory2Association where UserId IN : futureAccountOwnerList and User.IsActive = true and Territory2.Territory2Model.State = 'Active' and RoleInTerritory2 IN ('Account Executive') and Territory2.Territory_Structure_Type__c IN : territoryStructureTypes];
                if(!UTAList.IsEmpty()){
                    for(UserTerritory2Association uta : UTAList){
                        UTAMap.put(uta.UserId,uta.Territory2.Adaptive_Territory_Id__c);
                    }
                }
                for(Operations_Request__c op2 :newOperations1){
                    if(op2.Account_Transfer_Approval_Status__c == 'Approved' && op2.Account_Transfer_Approval_Status__c!=oldOperationMap.get(op2.Id).Account_Transfer_Approval_Status__c && op2.Territory_Structure_Type__c != null && op2.Future_account_owner__c != null && op2.Account_Move_Reason__c != null){
                        Operations_Request__c opRequest = new Operations_Request__c();
                        opRequest.Id = op2.Id;
                        If(UTAMap.containsKey(op2.Future_account_owner__c)){
                            if(etmStageMonitoringList.IsEmpty()){                            
                                etmStageMonitoringList.add(createETMStageMonitoringRecord());
                                accountStageList.add(createAccountStage(etmStageMonitoringList,op2,UTAMap.get(op2.Future_account_owner__c)));
                            }else{                   
                                accountStageList.add(createAccountStage(etmStageMonitoringList,op2,UTAMap.get(op2.Future_account_owner__c)));
                            }
                            opRequest.Is_ETM_Stage_Job_Created__c = 'ETM stage Job record is created';
                        }else{
                            opRequest.Is_ETM_Stage_Job_Created__c = 'Future Account Owner doesn\'t have active territory assigned.';
                        }
                        opListToUpdate.add(opRequest);
                    }
                }
            }
            if(!opListToUpdate.isEmpty()){
                update opListToUpdate;
            }
            if(!mails1.isEmpty() && !test.isRunningTest()){
                flowControll.taskTrigger = false;
                Messaging.sendEmail(mails1,false);
                flowControll.taskTrigger = true;
            } 
            //SAL26-323 Create account stage record if operation request is approved
            if(!accountStageList.IsEmpty()){
                insert accountStageList;
            }         

        }
        catch(exception ex){
            insert LogError.CreateGenericErrorLog('OperationRequestTriggerHandler',ex,'After Update Operations Request');
        }
        
    }
    /*=============================================================================================================================================*/
    /** 
     * @description
     * @param oldRecordsMap
     * This method is to write the logic in case of after deletion of the record
     */
    public override void onAfterDelete(Map<ID, sObject> oldRecordsMap) {
        system.debug(System.LoggingLevel.DEBUG,'this method id for after deletion operation.');
    }
    /*=============================================================================================================================================*/
    /** 
     * @description
     * @param newRecords
     * This method is to write the logic in case of undelete
     */
    public override void onAfterUnDelete(List<sObject> newRecords) {
        system.debug(System.LoggingLevel.DEBUG,'this method id for after undeletion operation.');
    }
    /*=============================================================================================================================================*/
    
    /** 
     * @description
     * @param etmStageMonitoringList
     * @param op2
     * @param adaptiveId
     * SAL26-323 Method to prepare Account_Sage__c object
     * @return asObject
     */
    public static Account_Stage__c createAccountStage(List<ETMStage_Monitoring__c> etmStageMonitoringList , Operations_Request__c op2, String adaptiveId){
        Account_Stage__c asObject = new Account_Stage__c();
        asObject.JobId__c = etmStageMonitoringList[0].Id;
        asObject.Account__c = op2.Account_Name__c != null ? Id.valueOf(op2.Account_Name__c) : null;
        asObject.TerritoryAdaptive_Id__c = adaptiveId;
        asObject.Account_Move_Reason__c = op2.Account_Move_Reason__c;
        asObject.Territory_Structure_Type__c = op2.Territory_Structure_Type__c;
        asObject.Operations_Request__c = op2.Id;
        return asObject;
    }

    /** 
     * @description
     * SAL26-323 Method to create ETMStage_Monitoring__c record
     * @return ETMStgObj
     */
    public static ETMStage_Monitoring__c createETMStageMonitoringRecord(){
        ETMStage_Monitoring__c ETMStgObj = new ETMStage_Monitoring__c(); 
        ETMStgObj.Initiated_By__c = 'Admin Queue';
        ETMStgObj.Status__c = 'New';
        insert ETMStgObj;
        return ETMStgObj;
    }
}