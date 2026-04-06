/**
* Date :04-January-2024
* Author : Rajat Jain
* JIRA : SAL24-641 - Trade-Up
* TestClass : Asset_TradeUp_Email_Bounce_Test
**/

public class Asset_TradeUp_Email_Bounce_Notification {
    
    @InvocableMethod(label='Asset TradeUp' description='Send Email bounce notification to Opp Owner if PDF Addendum email is bounced')
    public static void assetTradeUpPDFAddendumEmailBounce(List<EmailMessage> eMsgs){
        Set<Id> accIdSetBounced = new Set<Id>();
        List<Account> accLiUpdate = new List<Account>();
        Map<Id,String> accidToOwnerEmailMap = new Map<Id,String>();
        Map<Id,String> accIdMapBounced = new Map<Id,String>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate et=[Select id,Name, Subject, Body, HtmlValue, Markup from EmailTemplate where DeveloperName  ='Asset_TradeUp_Email_Bounce_Notification' limit 1];
        List<OrgWideEmailAddress> owEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
        try{
            
            for (EmailMessage msg : eMsgs) {
                if(msg.IsBounced && msg.RelatedToId != null){
                    accIdSetBounced.add(msg.RelatedToId);
                    accIdMapBounced.put(msg.RelatedToId, msg.ToAddress);
                }
            }
            
            if(accIdSetBounced.size()>0 && !accIdSetBounced.isEmpty()){
                List<Account> liAcc = [Select Id, Owner.Email from Account where Id in: accIdSetBounced];
                for(Account acc: liAcc){
                    accidToOwnerEmailMap.put(acc.Id,acc.Owner.Email);
                }
            }
            
            if(accidToOwnerEmailMap!=null){
                
                for(Id accId : accidToOwnerEmailMap.keyset()){
                    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, null, accId);
                    List<String> toAddress = new List<String>();
                    List<String> ccAddress = new List<String>();
                    toAddress.add(accidToOwnerEmailMap.get(accId));
                    mail.setToAddresses(toAddress); 
                    mail.setccAddresses(ccAddress);
                    mail.setOrgWideEmailAddressId(owEmail[0].Id);
                    mail.setSaveAsActivity(true);
                    mail.setWhatId(accId);
                    mails.add(mail);
                    Account accObj = new Account();
                    accObj.Id = accId;
                    accObj.Tradeup_Email_Bounced_Temp__c = true;
                    accLiUpdate.add(accObj);
                 }
            }
            if(!mails.isEmpty() && !test.isRunningTest()){
                Messaging.sendEmail(mails);
            }
            if(accLiUpdate.size()>0 && !accLiUpdate.isEmpty()){
                boolean tempFlag = flowControll.accountTrigger;
                flowControll.accountTrigger = false;
                update accLiUpdate;
                flowControll.accountTrigger = tempFlag;
            }
            
        }
        catch(exception ex){
            system.debug('Asset error occured ==> '+ex.getMessage() +' '+ex.getLineNumber());
        }
    }
    
}