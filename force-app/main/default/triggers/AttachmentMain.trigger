/**
* @Last modified by : Akashdeep Singh
* @Description : Send an email notification to case owner when a new attachment gets added to the Case or CCR  object by someone other than case owner.
* @Tickect no. : CS-397
**/
trigger AttachmentMain on Attachment (after insert, after Delete) {
    map<Id,CCR__c> mapIdToCCR = new map<Id,CCR__c>();
    set<Id> CCRIds = new set<Id>();
    List<CCR__c> updateList = new List<CCR__c>();
    set<Id> caseIds = new set<Id>();
    set<Id> attachIds = new set<Id>();
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    
    if(Trigger.isInsert){
        for(Attachment attch : Trigger.New){
            if(attch.parentId.getSObjectType().getDescribe().getName() == 'CCR__c'){   
                //CCRIds.add(attch.ParentId);    
            }
            if(attch.parentId.getSObjectType().getDescribe().getName() == 'Case'){
                caseIds.add(attch.ParentId);
            }
            attachIds.add(attch.Id);
        }
        /*try{
            EmailTemplate et=[Select id from EmailTemplate where name =:'Email to case owner when a new attachment gets added to the case by someone else'];
            map<Id,Attachment > mapofAttachment  = new map<Id,Attachment>([Select Id,ownerId from Attachment where ID IN : attachIds]);    
            map<Id,case> mapofCase = new map<Id,case>([Select Id,ownerId,owner.Email,ContactId from Case where ID IN : caseIds]);
            
            for(Attachment attch : Trigger.New){
                String parentID = (String)attch.parentId;
                if(parentID.startsWith('500') && mapofCase!=null && !mapofCase.isEmpty() && mapofCase.containsKey(parentID )){
                    Id attachmentOwnerId = null;
                    if(mapofAttachment!=null && !mapofAttachment.isEmpty() && mapofAttachment.containsKey(attch.id)){
                        attachmentOwnerId = mapofAttachment.get(attch.id).ownerId;
                    }
                    if(mapofCase.get(parentID).OwnerId != null && attachmentOwnerId != mapofCase.get(parentID).OwnerId && String.valueof(mapofCase.get(parentID).OwnerId).startsWith('005')){
                        List<String> sendTo = new List<String>();
                        Messaging.SingleEmailMessage singleMail = Messaging.renderStoredEmailTemplate(et.Id, UserInfo.getUserId(), parentID);
                        //Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
                        singleMail.setTemplateId(et.Id);
                        singleMail.setTargetObjectId(userInfo.getUserId());
                        if(mapofCase.get(parentID).Owner.Email != null)
                            sendTo.add(mapofCase.get(parentID).Owner.Email);
                        if(Test.isRunningTest() && sendTo.isEmpty())
                            sendTo.add('test@test.com');
                        singleMail.setToAddresses(sendTo);
                        //singleMail.setWhatId(parentId);
                        singleMail.setSaveAsActivity(false);
                        singleMail.setTreatTargetObjectAsRecipient(false);
                        if(mapofCase.get(parentID).Owner.Email != null)
                            emails.add(singleMail);
                    }
                }
            }
            Messaging.sendEmail(emails,false);
        }catch(Exception e){
            System.debug('error'+e);
        }*/
        
        
       /* if(CCRIds!=null && !CCRIds.isEmpty()){
            mapIdToCCR = new map<Id,CCR__c>([Select Id,Number_of_Attchments__c from CCR__c where ID IN : CCRIds ]);
            System.debug('.............'+mapIdToCCR);
        }
        for(Attachment attch : Trigger.New){
            if(mapIdToCCR.containsKey(attch.ParentId)){
                System.debug('.............'+mapIdToCCR.get(attch.ParentId));
                CCR__c UpdateParent = mapIdToCCR.get(attch.ParentId);
                /*Ticket SF-8627 changes made by Akashdeep Singh*/
               /* if( NULL ==  UpdateParent.Number_of_Attchments__c){
                    UpdateParent.Number_of_Attchments__c=0;
                }
                UpdateParent.Number_of_Attchments__c +=1;
                updateList.add(UpdateParent);
            }
        }*/
    }
   /* if(Trigger.isDelete){
        for(Attachment attch : Trigger.Old){
            system.debug('@@######'+attch.parentId.getSObjectType().getDescribe().getName());
            if(attch.parentId.getSObjectType().getDescribe().getName() == 'CCR__c'){
                CCRIds.add(attch.ParentId);    
            }
        }
        if(CCRIds!=null && !CCRIds.isEmpty()){
            mapIdToCCR = new map<Id,CCR__c>([Select Id,Number_of_Attchments__c from CCR__c where ID IN : CCRIds ]);
        }
        for(Attachment attch : Trigger.Old){
            if(mapIdToCCR.containsKey(attch.ParentId)){
                CCR__c UpdateParent = mapIdToCCR.get(attch.ParentId);
                UpdateParent.Number_of_Attchments__c -=1;
                updateList.add(UpdateParent);
            }
        }
    }
    if(updateList !=null && !updateList .isEmpty())
        update updateList;*/
    
}