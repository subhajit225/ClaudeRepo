/**
* @description : Generic class to send notifcation for CPQ track ARY-92              
* @CreatedDate : 19th Oct 2022
* @Created By : Sameer Kulakarni
* @Test Class : 
* Changes:
  Version Ticket       Owner                   Changes
* 
*/
    
public class SendChatterNotification{
    /**sendNotification */
    public static void sendNotification(Set<Id> userIdSet, Map<Id,SBQQ__Quote__c> opptyOwnerQuoteIdMap,String Source){
        String Recordlink = URL.getSalesforceBaseUrl().toExternalForm()+'/';
        String FinalString ='Quote : ';
        String createdMessage;
        String approvedMessage;
        List<FeedItem> feedItemList = new List<FeedItem>();
        List<CPQ_Custom_Metadata__mdt> CPQMetaDataList = [SELECT Id,DeveloperName,Type__c,Active__c,Value__c FROM CPQ_Custom_Metadata__mdt WHERE Active__c= true and Type__c='ChatterNotification'];
        
        for(CPQ_Custom_Metadata__mdt customMetatdaRec : CPQMetaDataList){
            if(customMetatdaRec.DeveloperName =='Quote_Created_Message'){
                createdMessage = customMetatdaRec.value__c;
            }
            else if (customMetatdaRec.DeveloperName =='Quote_Approved_Message'){
                approvedMessage = customMetatdaRec.value__c;
            }
        }

        for(Id userId :userIdSet){
            FeedItem post = new FeedItem();
            post.ParentId = userId;
            
            if(opptyOwnerQuoteIdMap.containsKey(userId)){
                if(Source == 'Approved'){
                     FinalString = FinalString + opptyOwnerQuoteIdMap.get(userId).Name + ' '+approvedMessage+' ';
                }
                else if(Source == 'Created'){
                    FinalString = FinalString + opptyOwnerQuoteIdMap.get(userId).Name +' '+createdMessage+' ';
                }
                Recordlink = Recordlink + opptyOwnerQuoteIdMap.get(userId).Id ;
                FinalString = FinalString + Recordlink;
                post.Body = FinalString;
            }
            
            feedItemList.add(post) ;
            FinalString = null;
        }

        if(!feedItemList.isEmpty()){
            if(CPQ_Constants.chatterNotification == false){
                Database.insert(feedItemList,false);
                CPQ_Constants.chatterNotification = true;
            }
        }
        
    }

    /** sendEmailNotification*/
        public static void sendEmailNotification(Map<Id,Set<String>>QuoteIdEmailSet,String Source,Map<Id,SBQQ__Quote__c> quoteNewMap){
            
            system.debug('Source>>'+Source);
            String myDomain = String.valueOf(System.Url.getOrgDomainUrl());
            List<String> domainList = myDomain.split('=');
            String htmlBody = 'Hi Team,'+ '<br/>'+'<br/>';
            boolean sendEmail = false;
            //ARY-1075
            List<User> groupUsers = [SELECT Id, Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Renewal_Sales_Team')];

            List<String> ccRenewalTeam = new List<String>();
            for(User user : groupUsers) {
                ccRenewalTeam.add(user.Email);
            }
            //ARY-1075

         List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
         Messaging.reserveSingleEmailCapacity(QuoteIdEmailSet.size());  
         for(Id quoteId : QuoteIdEmailSet.keySet()){
              Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
              List<String> sendTo = new List<String>();
              String sub = '';

               System.debug('QuoteIdEmailSet->'+QuoteIdEmailSet);
              for(String emailAdress : QuoteIdEmailSet.get(quoteId)){
                    if(!emailAdress.contains('invalid')){
                        sendTo.add(emailAdress);
                        sendEmail = true;
                        System.debug('emailAdress-->'+emailAdress);
                    }
                   
              }

              mail.setToAddresses(sendTo);
              if(!ccRenewalTeam.isEmpty()) mail.setCcAddresses(ccRenewalTeam); //ARY-1075
              //mail.setReplyTo('support@acme.com');
              mail.setSenderDisplayName('SFDC CPQ Admin');
              if(Source == 'Approved'){
                    sub = 'The Renewal+Expansion quote is approved';
                   //mail.setSubject(sub);
                   htmlBody = htmlBody + 'The quote is approved ';
              }
              else {
                    sub = 'New Renewal+Expansion Quote Created';
                   //mail.setSubject(sub);
                   htmlBody = htmlBody + 'New Renewal+Expansion quote is created ';
              }
              
              sub = sub +' On Account ' + quoteNewMap.get(quoteId).SBQQ__Account__r.Name;
              mail.setSubject(sub);
              
              htmlBody = htmlBody + ',to View this quote , please click on this link ';
              domainList[1] = domainList[1].removeEnd(']');
              htmlBody = htmlBody + domainList[1]+'/'+quoteId;
              mail.setBccSender(false);
              mail.setUseSignature(false);
              system.debug('htmlBody>>'+htmlBody);
              //mail.setPlainTextBody('Your Case: ' + case.Id +' has been created.');
              mail.setHtmlBody(htmlBody);

              mail.setBccSender(false);
              mail.setUseSignature(false);
              if(quoteNewMap.containsKey(quoteId) && quoteNewMap.get(quoteId).Email_Sent__c == false){
                mails.add(mail);
              }
              
         }

         system.debug('mails>>'+mails);

         try{
         if(!mails.isEmpty() && sendEmail == true){
         
            Messaging.sendEmail(mails);
            
            for(Id qId : QuoteIdEmailSet.keySet()){
                if(quoteNewMap.containsKey(qId)){
                    quoteNewMap.get(qId).Email_Sent__c = true;
                }
            }
         }
         } catch (Exception ex) {
         System.debug('Exception caught-->'+ex.getMessage());}

         CPQ_Constants.recusriveSendNotification = true;
        
    }

}