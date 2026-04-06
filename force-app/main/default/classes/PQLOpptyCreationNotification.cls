/**
 * @description This class will send an email to oppty owner and other users once the PQL oppty is created
 * Created Date   20/01/2025
 * TestClass    PAGServiceTest
 */ 
public without sharing class PQLOpptyCreationNotification {
    /** 
     * @description this method is to send email when the new PQL is created
     * @param OpptyMap
     */
    public static void sendPQLCreationEmail(Map<Id,Opportunity> OpptyMap){
        try{        
            Map<string,Product_Assisted_Growth__c> PQLMap = new Map<string,Product_Assisted_Growth__c>();
            List<string> adaptiveIds = new List<string>();
            Map<string,List<UserTerritory2Association>> userTerritoryMap = new Map<string,List<UserTerritory2Association>>();
            List<string> requestTypeList = new List<String>{'Cloud','RCV','OnPrem','Unstructured'};
            List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
            Email_Preferences__mdt EmailPreference = Email_Preferences__mdt.getInstance('PQL_Sender_Email');
            if(EmailPreference.From__c!=null){
                owea  = [select Id from OrgWideEmailAddress where Address =: EmailPreference.From__c];
            }
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();   
            for(opportunity opp : OpptyMap.Values()){
                if(String.IsNotBlank(opp.Account.Adaptive_Territory_Id__c))
                    adaptiveIds.add(opp.Account.Adaptive_Territory_Id__c);
            }
            List<Territory2> territoryList = [Select id, Territory2Type.DeveloperName, Adaptive_Territory_Id__c,(Select id,RoleInTerritory2,UserId,User.Email from UserTerritory2Associations where RoleInTerritory2 = 'Rubrik X') from Territory2  where Adaptive_Territory_Id__c IN : adaptiveIds and Territory2.Territory2Model.State = 'Active'];
            for(Territory2 tr : territoryList){
                if(tr.UserTerritory2Associations.Size()>0){
                    List<UserTerritory2Association> uTAs = new List<UserTerritory2Association>();
                    uTAs.addAll(tr.UserTerritory2Associations);
                    userTerritoryMap.put(tr.Adaptive_Territory_Id__c, uTAs);                
                }
            }
            List<Product_Assisted_Growth__c> PQLList = [Select id,Overage_Product_Type__c,Opportunity__c from Product_Assisted_Growth__c where Opportunity__c IN : OpptyMap.KeySet()];
            for(Product_Assisted_Growth__c pql : PQLList){
                PQLMap.put(pql.Opportunity__c,pql);
            }
            EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Markup  from EmailTemplate where DeveloperName ='Notification_PQL_Created'];
            for(Opportunity oppty : OpptyMap.Values()){
                List<string> ccAddresses = new List<string>{oppty.Account.Owner.Email};
                List<string> toAddresses = new List<string>{oppty.Owner.Email};
                if(PQLMap.ContainsKey(oppty.Id) && (PQLMap.get(oppty.Id).Overage_Product_Type__c == 'SaaS' || PQLMap.get(oppty.Id).Overage_Product_Type__c == 'Unstructured') && oppty.Co_Owner__c !=null){
                    ccAddresses.add(oppty.Co_Owner__r.Email);
                }
                if(PQLMap.ContainsKey(oppty.Id) && requestTypeList.contains(PQLMap.get(oppty.Id).Overage_Product_Type__c) && userTerritoryMap.containsKey(oppty.Account.Adaptive_Territory_Id__c)){
                    for(UserTerritory2Association territoryUser : userTerritoryMap.get((oppty.Account.Adaptive_Territory_Id__c))){
                        ccAddresses.add(territoryUser.User.Email);
                    }
                }
                
                if(oppty.Owner.ManagerId != null && String.IsNotEmpty(oppty.Owner.Manager.Email)){
                    ccAddresses.add(oppty.Owner.Manager.Email);
                }
                if(oppty.Rubrik_Sales_Engineer__c != null && String.IsNotEmpty(oppty.Rubrik_Sales_Engineer__r.Email)){
                    ccAddresses.add(oppty.Rubrik_Sales_Engineer__r.Email);
                }
                messaging.singleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setCcAddresses(ccAddresses);
                if (!owea.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owea[0].Id);
                }
                mail.setTemplateID(emailTemplate.Id);
                mail.setSaveAsActivity(false);
                mail.setHtmlBody(mail.getHTMLBody());
                mail.setTargetObjectId(oppty.OwnerId);
                mail.setWhatId(oppty.Id);
                mail.setSubject(mail.getSubject());    
                mails.add(mail);
            }        
            Messaging.sendEmail(mails);
        }catch(exception e){
            insert LogError.CreateGenericErrorLog('PQLOpptyCreationNotification',e,'PQL');
        }
    }
    
}