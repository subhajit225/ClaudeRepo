public class reqMoreInfoTriggerHandler {
    
    public static void onBeforeInsert(List<Request_More_Information_Notes__c> newList){
    }
    public static void onAfterInsert(List<Request_More_Information_Notes__c> newList, Map<Id,Request_More_Information_Notes__c> newMap){
        //postChatterToDDCase(newList, null);
        updateApprovalStatus(newList,null);
        sendEmailNotification(newList);
    }
    public static void onBeforeUpdate(List<Request_More_Information_Notes__c> newList, Map<Id,Request_More_Information_Notes__c> oldMap){
        
    }
    public static void onAfterUpdate(List<Request_More_Information_Notes__c> newList, Map<Id,Request_More_Information_Notes__c> oldMap){
        //postChatterToDDCase(newList,oldMap);
        updateApprovalStatus(newList,oldMap);
    }
    
  
    public static void updateApprovalStatus(List<Request_More_Information_Notes__c> newList, Map<Id,Request_More_Information_Notes__c> oldMap){
        List<sbaa__approval__c> approvalsToBeUpdated= new List<sbaa__approval__c> ();
        set<Id> approvalId= new Set<Id>();
        list<FeedItem> listFI = new list<FeedItem>();
        list<FeedComment> listFC = new list<FeedComment>();
        for(Request_More_Information_Notes__c eachReqNote:newList){
            approvalId.add(eachReqNote.Approval__c);
        }
        Map<Id, sbaa__Approval__c> approvalMap=new Map<Id, sbaa__Approval__c>([Select Id,Name,sbaa__Status__c from Sbaa__approval__c where Id in: approvalId]);
        
        for(Request_More_Information_Notes__c eachReqNote:newList){
            if(oldMap!=null){
                //moving the status back to requested as soon as the more info question is answered
                if(eachReqNote.Feedback_Group_Comments__c  !=null && oldMap.get(eachReqNote.Id).Feedback_Group_Comments__c  == null){
                    if(approvalMap.get(eachReqNote.Approval__c).sbaa__Status__c=='Waiting On Others'){
                        approvalsToBeUpdated.add(new sbaa__approval__c(Id=eachReqNote.Approval__c ,sbaa__Status__c='Requested'));
                    }
                }
                if(eachReqNote.Requestor_Comments__c != null && eachReqNote.Requestor_Comments__c != oldMap.get(eachReqNote.Id).Requestor_Comments__c){
                    listFC.add(ChatterUtil.commentOnFeedPost(eachReqNote.Feed_Id__c,'Requested information question has been updated for approval => '+approvalMap.get(eachReqNote.Approval__c).Name+'\n'+ eachReqNote.Requestor_Comments__c));
                }//JIRA : DD-10-A
                if(eachReqNote.Feedback_Group_Comments__c  != null && eachReqNote.Feedback_Group_Comments__c  != oldMap.get(eachReqNote.Id).Feedback_Group_Comments__c ){
                    if(!String.IsBlank(oldMap.get(eachReqNote.Id).Feedback_Group_Comments__c )){
                        listFC.add(ChatterUtil.commentOnFeedPost(eachReqNote.Feed_Id__c,eachReqNote.Feedback_Groups__c +' has updated the information on => '+approvalMap.get(eachReqNote.Approval__c).Name+'\n'+ eachReqNote.Feedback_Group_Comments__c ));
                    }else{
                        listFC.add(ChatterUtil.commentOnFeedPost(eachReqNote.Feed_Id__c, eachReqNote.Feedback_Groups__c +' has provided the information on => '+approvalMap.get(eachReqNote.Approval__c).Name+'\n'+ eachReqNote.Feedback_Group_Comments__c ));
                    }
                }
            }else{
                if(eachReqNote.Requestor_Comments__c !=null){
                    approvalsToBeUpdated.add(new sbaa__approval__c(Id=eachReqNote.Approval__c ,sbaa__Status__c='Waiting On Others'));
                    listFI.add(ChatterUtil.postOnFeed(eachReqNote.Deal_Desk_Case__c,'Requested for more information on approval => '+approvalMap.get(eachReqNote.Approval__c).Name+'\n'+ eachReqNote.Requestor_Comments__c));
                }
            }
        }
        
        if(!approvalsToBeUpdated.isEmpty()){
            update approvalsToBeUpdated;
        }
        if(!listFI.isEmpty()){
            insert listFI;
        }
        if(!listFC.isEmpty()){
            insert listFC;
        }
        List<Request_More_Information_Notes__c> reqsToBeUpdated= new List<Request_More_Information_Notes__c>();
        for(integer i=0;i<listFI.size();i++){
            reqsToBeUpdated.add(new Request_More_Information_Notes__c(Id=newList[i].Id, Feed_Id__c=listFi[i].Id));
        }
        if(!reqsToBeUpdated.isEmpty()){
            update reqsToBeUpdated;
        }
    }
    
    public static void sendEmailNotification(list<Request_More_Information_Notes__c> newList){
        try{
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emTemp = [SELECT Id, DeveloperName,Body FROM EmailTemplate where DeveloperName='Request_More_Info_Notification' limit 1];
            List<OrgWideEmailAddress> owEmail = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
            List<String> mailToAddresses = new List<String>();
            List<String> idList = new List<String>();
            Set<Id> ddcIds= new Set<Id>();
            String[] toaddresses = new String[] {};
                
                for(Request_More_Information_Notes__c rmi : newList){
                    ddcIds.add(rmi.Deal_Desk_Case__c);
                }
            Map<Id,Deal_Desk_Case__c> ddcMap=new Map<Id,Deal_Desk_Case__c>([Select Id, Opportunity__c , Opportunity__r.Owner.Email, Opportunity__r.Owner.Manager.Email from Deal_Desk_Case__c where id in :ddcIds]);
            for(Request_More_Information_Notes__c rmi : newList){
                
                if(rmi != null && rmi.Feedback_Groups__c != null) {
                    if(rmi.Feedback_Groups__c == 'Deal Operations') {
                        toaddresses.add(System.Label.DealDeskEmail); 
                    } else if(rmi.Feedback_Groups__c == 'Deal Structuring' || rmi.Feedback_Groups__c == 'Revenue' || rmi.Feedback_Groups__c == 'Legal') {
                        toaddresses.add(System.Label.DealStructuringEmail);
                    } else if(rmi.Feedback_Groups__c == 'Deal Desk Leadership') {
                        toaddresses.add(System.Label.DealDeskLeadershipEmail);
                    } else if(rmi.Feedback_Groups__c == 'Sales (to opportunity owner)' && ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__c != null && ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__r.Owner.Email != null) {
                        toaddresses.add(ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__r.Owner.Email);
                    } else if(rmi.Feedback_Groups__c == 'Sales Manager (to opportunity owner’s manager)' && ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__c  != null && ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__r.Owner.Manager != null && ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__r.Owner.Manager.Email != null) {
                        toaddresses.add(ddcMap.get(rmi.Deal_Desk_Case__c).Opportunity__r.Owner.Manager.Email);
                    } else if(rmi.Feedback_Groups__c == 'Orders') {
                        toaddresses.add(System.Label.OrdersEmail);
                    }
                }
                if(rmi != null && rmi.Feedback_Groups__c != null) {    
                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emTemp.Id, rmi.OwnerId, rmi.Id);
                    String emailSubject = email.getSubject();
                    String emailTextBody = email.getPlainTextBody();
                    email.setToAddresses(toaddresses);
                    email.setTargetObjectId(rmi.OwnerId);
                    email.setSubject(emailSubject);
                    email.setPlainTextBody(emailTextBody);
                    email.saveAsActivity = false;
                    email.setOrgWideEmailAddressId(owEmail[0].Id);
                    mails.add(email); 
                }
            }
            if(!mails.isEmpty()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
                if (results[0].isSuccess()) {
                    System.debug('Email sent successfully.');
                } else {
                    System.debug('Email failed to send. Error: ' + results[0].getErrors()[0].getMessage());
                }
            }
        }
        catch(Exception ex){
            system.debug('exception occured: '+ex.getMessage());
        }
    }
}