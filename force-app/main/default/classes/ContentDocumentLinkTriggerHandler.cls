/**
** @Last modified by : Akashdeep Singh
* @Description : Notify case owner when new attachment added to case on the Support Portal
* @Tickect no. : CS-452
**/
public class ContentDocumentLinkTriggerHandler {
    public static Boolean CDLTriggerRecurssion = false;
    public void beforeInsert(List<ContentDocumentLink> cdl){

        for(ContentDocumentLink cvt : cdl){

            String entityId = String.valueof(cvt.linkedEntityId);
            if(entityId.startsWithIgnoreCase('500') || entityId.startsWithIgnoreCase('ka0')){
                cvt.Visibility  = 'AllUsers';
            }
        }
    }

    public void afterInsert (List<ContentDocumentLink> cdl){
        set<Id> caseIds = new set<Id>();
        set<Id> CCRIds = new set<Id>();
        set<Id> FSIds = new set<Id>();
        set<Id> cDIds = new set<Id>();
        List<ContentDocumentLink> updatedcdlList = new List<ContentDocumentLink>();
        map<Id,CCR__c> mapIdToCCR = new map<Id,CCR__c>();
        List<CCR__c> updateList = new List<CCR__c>();
        List<ContentVersion> cvlist = new List<ContentVersion>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<ContentDocumentLink> shareWithCollaborators = new List<ContentDocumentLink>();
        //Set<String> excludeUserIdsFromCollab = new Set<String>();
        Set<Id> contentDocIds = new Set<Id>();
        Set<Id> permAssignedUserIds = new Set<Id>();
        Set<Id> existingCollabsUserIds = new Set<Id>();
        //excludeUserIdsFromCollab.add(UserInfo.getUserId());
        List<PermissionSetAssignment> permSetAssignees = [SELECT Id, AssigneeId FROM PermissionSetAssignment 
                                       WHERE PermissionSet.Name = 'PSG_CS_User_Knowledge_Publishers' 
                                       AND Assignee.isActive =True];
        if(!permSetAssignees.isEmpty() && permSetAssignees!=null){
            for(PermissionSetAssignment assignee : permSetAssignees){
                permAssignedUserIds.add(assignee.AssigneeId);
            }
        }
        
        for(ContentDocumentLink cvt : cdl){
            contentDocIds.add(cvt.contentDocumentId);
        }
        
        Map<Id,ContentDocumentLink> existingCollabsWithContentDocument = new Map<Id,ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocumentId,LinkedEntity.Type  
                                                                        FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocIds AND LinkedEntityId IN :permAssignedUserIds]);
        if(existingCollabsWithContentDocument!=null){
            for(ContentDocumentLink cdlobject : existingCollabsWithContentDocument.values()){
                if(cdlobject.LinkedEntity.Type == 'User')
                	existingCollabsUserIds.add(cdlobject.LinkedEntityId);
            }
        }
		        
        for(ContentDocumentLink cvt : cdl){
            String entityId = String.valueof(cvt.linkedEntityId);
            if(entityId.startsWithIgnoreCase('500')){
                caseIds.add(cvt.linkedEntityId);
                cDIds.add(cvt.contentDocumentId);
            }
            if(cvt.linkedEntityId.getSObjectType().getDescribe().getName() == 'CCR__c'){
                CCRIds.add(cvt.linkedEntityId);
            }
            if(cvt.linkedEntityId.getSObjectType().getDescribe().getName() == 'File_Sharing__c'){
                FSIds.add(cvt.linkedEntityId);
            }

            if(cvt.linkedEntityId.getSObjectType().getDescribe().getName() == 'How_To__kav' && !permSetAssignees.isEmpty()){
                for(PermissionSetAssignment perSetAssignee : permSetAssignees){
                    if(existingCollabsUserIds.isEmpty() || !existingCollabsUserIds.contains(perSetAssignee.AssigneeId)){
                        ContentDocumentLink newCdl = new ContentDocumentLink();
                        newCdl.ContentDocumentId = cvt.ContentDocumentId;
                        newCdl.LinkedEntityId = perSetAssignee.AssigneeId;
                        newCdl.ShareType = 'C';
                        shareWithCollaborators.add(newCdl);
                    }
                }
            }
        }
        
        if(!FSIds.isEmpty()){
            for(ContentDocumentLink ucdl : [Select Id,ContentDocumentId,LinkedEntityId,Visibility,ShareType from ContentDocumentLink where LinkedEntityId IN : FSIds ]){
                ucdl.Visibility = 'AllUsers';
                ucdl.ShareType = 'I';
                updatedcdlList.add(ucdl);
            }
            CDLTriggerRecurssion = true;
            update updatedcdlList;
        }
        if(CCRIds!=null && !CCRIds.isEmpty()){
            mapIdToCCR = new map<Id,CCR__c>([Select Id,Number_of_Attchments__c from CCR__c where ID IN : CCRIds ]);
            System.debug('.............'+mapIdToCCR);
        }
        for(ContentDocumentLink cvt : cdl){
            if(mapIdToCCR.containsKey(cvt.linkedEntityId)){
                System.debug('.............'+mapIdToCCR.get(cvt.linkedEntityId));
                CCR__c UpdateParent = mapIdToCCR.get(cvt.linkedEntityId);
                /*Ticket SF-8627 changes made by Akashdeep Singh*/
                if( NULL ==  UpdateParent.Number_of_Attchments__c){
                    UpdateParent.Number_of_Attchments__c=0;
                }
                UpdateParent.Number_of_Attchments__c +=1;
                updateList.add(UpdateParent);
            }
        }
        if(updateList !=null && !updateList .isEmpty()){
            update updateList;
        }
        if(Userinfo.getName() != 'Support bot'){
            Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>([SELECT Id,Title,FileExtension FROM ContentVersion WHERE ContentDocumentId IN : cDIds]);
            for(Id cvID : cvMap.keySet()){
                ContentVersion cv = cvMap.get(cvID);
                system.debug('cv..........'+cv);
                cv.Title = cv.Title+'.'+cv.FileExtension;
                cvlist.add(cv);
            }
            System.debug('cvlist----'+cvlist);
            update cvlist;

            List<CaseComment> newCaseCommentList=new List<CaseComment>();
            EmailTemplate et=[Select id from EmailTemplate where name ='Email file added on case from community'];
            map<Id,ContentDocument > mapofContentDocument  = new map<Id,ContentDocument>([Select Id,ownerId,title,ContentSize from ContentDocument where ID IN : cDIds]);
            map<Id,case> mapofCase = new map<Id,case>([Select Id,ownerId,owner.Email,ContactId from Case where ID IN : caseIds]);
            Id userId=UserInfo.getUserId();
            User usr = new User();
            if(test.isRunningTest()){
                usr=[select id,FirstName,LastName from user where Id=:userId limit 1];
            }
            else{
                usr=[select id,FirstName,LastName,Contact.Account.Name from user where Id=:userId limit 1];
            }
            Id FromEmailID = [select id from OrgWideEmailAddress WHERE DisplayName = 'No Reply'].id;

            for(ContentDocumentLink cvt : cdl){


                String parentID = (String)cvt.LinkedEntityId;
                if(parentID.startsWith('500') && mapofCase!=null && !mapofCase.isEmpty() && mapofCase.containsKey(parentID )){
                    String title = '';
                    Long fileSize;
                    String fileSizeString = '';
                    CaseComment newCaseComment = new CaseComment();
                    if(mapofContentDocument!=null && !mapofContentDocument.isEmpty() && mapofContentDocument.containskey(cvt.contentDocumentId))
                        title = mapofContentDocument.get(cvt.contentDocumentId).title;
                    fileSize = mapofContentDocument.get(cvt.contentDocumentId).ContentSize;
                    if(fileSize > 0 && fileSize <= 1023){
                        fileSizeString = ''+fileSize.format()+'Byte';
                    }
                    if(fileSize >= 1024 && fileSize <= 1047552){
                        fileSizeString = ''+(fileSize/1024).format()+'KB';
                    }
                    if(fileSize >= 1048576 && fileSize <= 1072693248){
                        fileSizeString = ''+(fileSize/1048576).format()+'MB';
                    }
                    if(fileSize >= 1073741824L && fileSize <= 2147483648L){
                        fileSizeString = ''+(fileSize/1073741824).format()+'GB';
                    }

                    if(test.isRunningTest()){
                        newCaseComment.CommentBody = usr.FirstName+' '+usr.LastName+' from attached '+title;
                    }
                    else{
                        //newCaseComment.CommentBody = usr.FirstName+' '+usr.LastName+' from '+usr.Account.Name+' attached '+title;
                        newCaseComment.CommentBody = usr.FirstName+' '+usr.LastName+' from '+usr.Contact.Account.Name+' attached '+title+ ' ('+fileSizeString+')';

                    }
                    newCaseComment.parentid = (Id)parentID;
                    newCaseCommentList.add(newCaseComment);
                    Id contentDocumentOwnerId = null;
                    if(mapofContentDocument!=null && !mapofContentDocument.isEmpty() && mapofContentDocument.containsKey(cvt.contentDocumentId)){
                        contentDocumentOwnerId = mapofContentDocument.get(cvt.contentDocumentId).ownerId;
                    }
                    if(contentDocumentOwnerId != mapofCase.get(cvt.LinkedEntityId).OwnerId){
                        List<String> sendTo = new List<String>();
                        Messaging.SingleEmailMessage singleMail = Messaging.renderStoredEmailTemplate(et.Id, UserInfo.getUserId(), cvt.LinkedEntityId);
                        singleMail.setTemplateId(et.Id);
                        singleMail.setTargetObjectId(userInfo.getUserId());
                        singleMail.setOrgWideEmailAddressId(FromEmailID);
                        if(mapofCase.get(cvt.LinkedEntityId).Owner.Email != null)
                            sendTo.add(mapofCase.get(cvt.LinkedEntityId).Owner.Email);
                        singleMail.setToAddresses(sendTo);
                        singleMail.setSaveAsActivity(false);
                        singleMail.setTreatTargetObjectAsRecipient(false);
                        if(!sendTo.isEmpty())
                            emails.add(singleMail);
                    }
                }
            }
            if(newCaseCommentList!=null && !newCaseCommentList.isEmpty()){
                insert newCaseCommentList;
            }
            if(emails.size()>0){
                Messaging.sendEmail(emails);
            }
        }
		
        if(shareWithCollaborators!=null && !shareWithCollaborators.isEmpty()){
            try{
                CDLTriggerRecurssion = true;
                List <Database.SaveResult> results = Database.insert(shareWithCollaborators,false);
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error: ' + error.getMessage());
                            System.debug('Field causing error: ' + error.getFields());
                        }
                    }
                }
            }
            catch(Exception ex){
                System.debug('Error Found while sharing with collabs='+ ex.getMessage());
            }
        }
    }

     public void beforeDelete(List<ContentDocumentLink> cdl){
        for(ContentDocumentLink cvt : cdl){
            if(cvt.linkedEntityId.getSObjectType().getDescribe().getName() == 'Entitlement_Warranty_Details__c'){
                cvt.addError('can not delete this attachment as it is linked with Entitlement Warranty Record');
            }
        }
    }


    public void afterDelete(List<ContentDocumentLink> cdl){
        List<Id> CCRIds = new List<Id>();
        List<CCR__c> updateList = new List<CCR__c>();
        List<ContentDocumentLink> conDocLinkList = new List<ContentDocumentLink>();
        Map<Id,Integer> cdlMap = new Map<Id,Integer>();
        Integer count = 0;
         for(ContentDocumentLink cvt : cdl){
            system.debug('@@######'+cvt.linkedEntityId.getSObjectType().getDescribe().getName());
            if(cvt.linkedEntityId.getSObjectType().getDescribe().getName() == 'CCR__c'){
                CCRIds.add(cvt.linkedEntityId);
            }
        }
        if(!CCRIds.isEmpty()){
            conDocLinkList = [select Id, ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId IN: CCRIds];
            for(ContentDocumentLink cdkl : conDocLinkList){
                count = 0;
                if(!cdlMap.isEmpty() && cdlMap.containskey(cdkl.LinkedEntityId)){
                    count = cdlMap.get(cdkl.LinkedEntityId)+1;
                }else if(cdlMap.isEmpty() || !cdlMap.containskey(cdkl.LinkedEntityId)){
                   count = 1;
                }
                cdlMap.put(cdkl.LinkedEntityId,count);
            }
            for(Id ccrId: cdlMap.keySet()){
                CCR__c ccrrec = new CCR__c(Id=ccrId,Number_of_Attchments__c=cdlMap.get(ccrId));
                updateList.add(ccrrec);
            }
        if(updateList !=null && !updateList.isEmpty())
            update updateList;
        }
    }
}