/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
* Test Class : dealDeskComments_Test
**/
public class dDCaseCommentsTriggerHandler {
    
    public static void onAfterInsert(List<Deal_Desk_Comments__c> newList, Map<Id,Deal_Desk_Comments__c> newMap){
        shareRecords(newList);
    }
    //Deal_Desk_Comments__Share
    public static void shareRecords(List<Deal_Desk_Comments__c> newList){
        try{
            List<FeedItem> FeedItemList = New List<FeedItem>();//DD25-12
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            map<string,id> emailTemptoIdMap = new map<string,id>();
            List<EmailTemplate> emTemp = [SELECT Id, DeveloperName FROM EmailTemplate where DeveloperName in ('DDC_Private_Comment_Tag_Notification')];
            for(EmailTemplate et : emTemp){
                emailTemptoIdMap.put(et.DeveloperName,et.Id);
            }
            List<OrgWideEmailAddress> owEmail = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
            List<Deal_Desk_Comments__Share> shareList = new List<Deal_Desk_Comments__Share>();
            List<Id> recipientIds = new List<Id>();
            Id ddCommentId;
            Id ddCaseId; //DD25-12
            String ddCaseName; //DD25-12
            for(Deal_Desk_Comments__c ddc : newList){
                ddCommentId = ddc.Id;
                ddCaseId = ddc.ParentId__c; //DD25-12
                if(ddc.Recipient_Ids__c!=null && ddc.Recipient_Ids__c!=''){
                    recipientIds=ddc.Recipient_Ids__c.split(',');
                }
            }
            //DD25-12
            if(ddCaseId!=null){
                Deal_Desk_Case__c ddcase= [Select Id, Name from Deal_Desk_Case__c where ID=:ddCaseId LIMIT 1];
                ddCaseName = ddcase.Name;
            }
            if(recipientIds.size()>0 && recipientIds!=null){
                for(Id rId : recipientIds){
                    Deal_Desk_Comments__Share ddShare = new Deal_Desk_Comments__Share();
                    ddShare.parentId = ddCommentId;
                    ddShare.UserOrGroupId = rId;
                    ddShare.AccessLevel = 'Read';
                    ddShare.RowCause = Schema.Deal_Desk_Comments__Share.RowCause.Manual;
                    shareList.add(ddShare);
                    // To send email notifications to the tagged user
                    Messaging.SingleEmailMessage email = EmailHelper.sendEmail(emailTemptoIdMap.get('DDC_Private_Comment_Tag_Notification'), rId, ddCommentId);
                    email.setOrgWideEmailAddressId(owEmail[0].Id);
                    mails.add(email);
                    
                    //To send notification bell //DD25-12
                    FeedItem post = new FeedItem();
                    post.ParentId = rId;
                    post.Body = 'You are tagged in a Private Comment on Deal Desk Case, please click on this notification to review';
                    post.Title = ddCaseName;
                    post.LinkUrl = '/lightning/r/Deal_Desk_Case__c/' + ddCaseId + '/view';
                    FeedItemList.add(post);
                }
            }
            if(shareList.size()>0 && shareList!=null){
                Database.SaveResult[] sr = Database.insert(shareList,false);
            }
            if(!mails.isEmpty() && !test.isRunningTest()){
                Messaging.sendEmail(mails);
            }
            //DD25-12
            if (FeedItemList.size()>0) {         
                insert FeedItemList;                
            }
        }
        catch(Exception ex){
            system.debug('exception occured: '+ex.getMessage());
        }
    }
}