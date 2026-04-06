/**
* @description Email Messages service class for business functionality
*
* @CreatedDate 15th July 2021
* @Created By Veera Gandi
*
* @Test Class EmailMessageServiceTest
*/
public class EmailMessageService {

    /**
    * @description Capture ADP Reference Number from ADP's Ticketing System support email
    *              and update it on the case. CS21-616
    * @param  newList - trigger context variable
    * @return void
    */

    public static void captureADPReferenceIdFromSupportEmail(List<EmailMessage> newMessages) {
        Map<Id, String> caseIdAndADPReferenceNumbers = new Map<Id, String>();
        Map<Id,Case> caseMap = new Map<Id,Case>();
        for (EmailMessage eachMessage : newMessages) {
            if(eachMessage.Incoming && eachMessage.ParentId != null){
                caseMap.put(eachMessage.ParentId, new Case());
            }
        }
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
        caseMap = new Map<Id,Case>([SELECT id, RecordTypeId, Origin, OwnerId, Last_Email_Sent_Date__c, Owner.Email, ContactId, AccountId, RecordType.Name, Status, Type__c, SubType__c, Date_Time_Closed__c,Duplicate_Case_Id__c, SuppliedEmail, Subject, Description, Recipient_Email__c FROM Case WHERE id IN: caseMap.keySet() AND (RecordTypeId =: successCaseId OR RecordTypeId =: partnerCaseId )]);
        List<Case> caseToUpdate = new List<Case>();
        List<Case> caseToInsert = new List<Case>();
        List<String> closedStatusCases = Label.TAPPartnerClosedStatus.split(';');
        
        for (EmailMessage eachMessage : newMessages) {

            if(eachMessage.Incoming && !eachMessage.FromAddress.contains('@rubrik.com') && caseMap.containsKey(eachMessage.ParentId) &&
               caseMap.get(eachMessage.ParentId).RecordType.Name == 'Customer Success'
               && caseMap.get(eachMessage.ParentId).Status != 'Reopen' && caseMap.get(eachMessage.ParentId).Status != 'Waiting for Rubrik Support'
              ){
                    caseMap.get(eachMessage.ParentId).Sub_Phase__c = 'CSM Action Pending';
                    caseMap.get(eachMessage.ParentId).Status = 'Waiting for Rubrik Support';
                    caseToUpdate.add(caseMap.get(eachMessage.ParentId));
                }

            
            if(caseMap.containsKey(eachMessage.ParentId) && 
               caseMap.get(eachMessage.ParentId).RecordType.Name == 'Partner Case')
            {
                //CS21-2826
                if(eachMessage.ToAddress == Label.TAPPartnerEmail && caseMap.get(eachMessage.ParentId).Status == 'New' &&
                   caseMap.get(eachMessage.ParentId).Type__c != 'Third-Party Hardware'){
                       caseMap.get(eachMessage.ParentId).Type__c = 'Third-Party Hardware';
                   }
                
                if(caseMap.get(eachMessage.ParentId).Recipient_Email__c == null) {
                    caseMap.get(eachMessage.ParentId).Recipient_Email__c = eachMessage.ToAddress == Label.TAPPartnerEmail ? 
                                                                           Label.TAPPartnerEmail : 
                                                                           eachMessage.ToAddress == Label.GoForwardEmail ? 
                                                                           Label.GoForwardEmail : 
                                                                           null;
                }
                
                //CS21-2120
                if(caseMap.get(eachMessage.ParentId).Date_Time_Closed__c != null && 
                   closedStatusCases.contains(caseMap.get(eachMessage.ParentId).Status)){
                       if(DateTime.now() <= caseMap.get(eachMessage.ParentId).Date_Time_Closed__c.addDays(7)){
                           caseMap.get(eachMessage.ParentId).Status = 'Reopen';
                       }
                       if(DateTime.now() >= caseMap.get(eachMessage.ParentId).Date_Time_Closed__c.addDays(7)){
                           Case cs = new Case();
                           cs.Duplicate_Case_Id__c = caseMap.get(eachMessage.ParentId).Id;
                           cs.Status = 'New';
                           cs.Origin = caseMap.get(eachMessage.ParentId).Origin;
                           cs.OwnerId = caseMap.get(eachMessage.ParentId)?.OwnerId;
                           cs.ContactId = caseMap.get(eachMessage.ParentId)?.ContactId;
                           cs.AccountId = caseMap.get(eachMessage.ParentId)?.AccountId;
                           cs.RecordTypeId = caseMap.get(eachMessage.ParentId)?.RecordTypeId;
                           cs.Type__c = caseMap.get(eachMessage.ParentId)?.Type__c;
                           cs.SubType__c = caseMap.get(eachMessage.ParentId)?.SubType__c;
                           cs.SuppliedEmail = caseMap.get(eachMessage.ParentId)?.SuppliedEmail;
                           cs.Subject = caseMap.get(eachMessage.ParentId)?.Subject;
                           cs.Description = caseMap.get(eachMessage.ParentId)?.Description;
                           cs.Last_Email_Sent_Date__c = DateTime.now();
                           caseToInsert.add(cs);
                       }
                }
                
                //CS21-2117
                if(caseMap.get(eachMessage.ParentId).Status == 'Waiting on Requester' && 
                   eachMessage.FromAddress != caseMap.get(eachMessage.ParentId).Owner.Email)
                {
                    caseMap.get(eachMessage.ParentId).Status = 'Requester Responded';
                }  
                //CS21-2113
                caseMap.get(eachMessage.ParentId).Last_Email_Sent_Date__c = DateTime.now();
                caseToUpdate.add(caseMap.get(eachMessage.ParentId));
            }
            

            //If the email is send from ADP support email ['support@assured-dp.com']
            //and Case Account is Assured Data Protection (EMEA)
            //EmailBody is not empty
            if (eachMessage.FromAddress == Label.ADPSupportEmail
                && eachMessage.IsADPMessage__c
                && string.isNotBlank(eachMessage.TextBody))
            {
                //ADP Reference Number is appended at the end of the email body
                //when support email is sent from ADP Ticketing System.
                //e.g., {CMI: MCID031752}
                String adpReferenceNumber = eachMessage.TextBody.substringAfterLast('{CMI:');
                adpReferenceNumber = adpReferenceNumber.substringBefore('}');

                //If ADP Reference# is found
                if (string.isNotBlank(adpReferenceNumber)) {
                    caseIdAndADPReferenceNumbers.put(eachMessage.ParentId, '{CMI:' + adpReferenceNumber + '}');
                }
            }
        }
        
        if(!caseToInsert.isEmpty()){
            insert caseToInsert;
        }

        if(!caseToUpdate.isEmpty()){
            update caseToUpdate;
        }

        if (!caseIdAndADPReferenceNumbers.isEmpty()) {
            //future method to update ADP reference# on the case
            updateADPReferenceNumber(caseIdAndADPReferenceNumbers);
        }
    }

    /**
    * @description Future method to update ADP Reference Number on case - CS21-616
    * @param  Map<Id, String>  caseId and ADP Reference Number
    * @return void
    */
    @future
    public static void updateADPReferenceNumber(Map<Id, String> caseIdAndADPReferenceNumbers) {
        List<Case> cases = new List<Case>();

        //loop through the map and update ADP Reference # on case
        for (Id eachCaseId : caseIdAndADPReferenceNumbers.keySet()) {
            case newCase = new Case();
            newCase.Id = eachCaseId;
            newCase.ADPReferenceId__c = caseIdAndADPReferenceNumbers.get(eachCaseId);
            cases.add(newCase);
        }

        if (!cases.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(cases, false);

            //log errors
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    System.debug('Error Occured ::' + JSON.serialize(result.getErrors()));
                }
            }
        }
    }

    /** //SAL24-443
    * @description Invocable method to update related Opportunity record PDF Addendum Email Delivered flag when email is bounced or not bounced
    * @param  List<EmailMessage>  EmailMessage
    * @return void
    */
    @InvocableMethod(label='Email Message' description='Update related Opportunity record PDF Addendum Email flag when email is bounced or not bounced')
    public static void updateOpportunityPDFAddendumFlag(List<EmailMessage> eMsgs){
        Set<Id> oppIdSetBounced = new Set<Id>();
        Set<Id> oppIdSetNotBounced = new Set<Id>();
        Map<Id,String> oppIdMapBounced = new Map<Id,String>();
        Map<Id,String> oppIdMapNotBounced = new Map<Id,String>();
        List<Opportunity> oppToUpdateList = new List<Opportunity>();
        for (EmailMessage msg : eMsgs) {
            if(msg.IsBounced && msg.RelatedToId != null){
                oppIdSetBounced.add(msg.RelatedToId);
                oppIdMapBounced.put(msg.RelatedToId, msg.ToAddress);
            }
            else if(!msg.IsBounced && msg.RelatedToId != null){
                oppIdSetNotBounced.add(msg.RelatedToId);
                oppIdMapNotBounced.put(msg.RelatedToId, msg.ToAddress);
            }
        }
        if(!oppIdMapBounced.isEmpty() || !oppIdMapNotBounced.isEmpty()){
            for(Opportunity opp :[SELECT Id,PDF_Addendum_Email_Delivered__c,Click_Thru_Contact_Email__c from Opportunity where (Id in:oppIdMapBounced.keySet() or Id in :oppIdMapNotBounced.keySet()) and PDF_Addendum_Email_Sent__c = TRUE and PDF_Addendum_Email_Delivered__c = FALSE]){
                Boolean isUpdate = false;
                if(oppIdMapBounced.containsKey(opp.Id) && opp.Click_Thru_Contact_Email__c == oppIdMapBounced.get(opp.Id)) { opp.PDF_Addendum_Email_Sent__c = FALSE; isUpdate = true;}
                else if(oppIdMapNotBounced.containsKey(opp.Id) && opp.Click_Thru_Contact_Email__c == oppIdMapNotBounced.get(opp.Id)) { opp.PDF_Addendum_Email_Delivered__c = TRUE; isUpdate = true;}
                if(isUpdate) { oppToUpdateList.add(opp); }
            }
        }
        if(!oppToUpdateList.isEmpty()){
            FlowControll.opportunityTriggerHandler = false;
            Database.SaveResult[] srList = Database.update(oppToUpdateList, false);
            FlowControll.opportunityTriggerHandler = true;
            LogError.createDMLErrorLog((List<SObject>)oppToUpdateList, srList, 'EmailMessageService','Update Opportunity PDF Addendum Email Flag');
        }
    } //SAL24-443 - End
}