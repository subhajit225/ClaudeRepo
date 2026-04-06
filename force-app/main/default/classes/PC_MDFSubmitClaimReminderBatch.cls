public class PC_MDFSubmitClaimReminderBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Database.queryLocator start(Database.BatchableContext batchContext){
        String submittedStage = 'Approved';
        String queryStr = 'SELECT Id, Activity_End_Date__c FROM PartnerFundRequest WHERE Activity_End_Date__c = YESTERDAY AND Status = :submittedStage AND Disable_MDF_Claim_Notifications__c = FALSE' ;
        return Database.getQueryLocator(queryStr + '');
    }

    public void execute(Database.BatchableContext batchContext, List<PartnerFundRequest> mdfRequestList){
        List<PartnerFundRequest> pFRListToSendMail = new List<PartnerFundRequest>();

        for(PartnerFundRequest pfr : [SELECT Id, CreatedById, Partner_Contact__c, (SELECT Id from PartnerFundClaims)
                                        FROM PartnerFundRequest
                                        WHERE Id IN: mdfRequestList]){
            if(pfr.PartnerFundClaims.isEmpty()){
                pFRListToSendMail.add(pfr);
            }
        }
        system.debug('pFRListToSendMail '+ pFRListToSendMail);
        if(pFRListToSendMail.isEmpty())
            return; // MDF Claim Due
        EmailTemplate et = [SELECT ID FROM EmailTemplate WHERE developername =:'MDF_Claim_Due1'];
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address =:Label.MDFSenderEmailID];

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(PartnerFundRequest pfrRec: pFRListToSendMail){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(pfrRec.CreatedById);
            mail.setTemplateId(et.id);
            mail.setwhatId(pfrRec.Id);
            mail.setSaveAsActivity(false);
            //mail.setSenderDisplayName('Rubrik Support');
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mails.add(mail);
        }
        Messaging.sendEmail(mails);
    }

    public void finish(Database.BatchableContext batchContext){
    }
}