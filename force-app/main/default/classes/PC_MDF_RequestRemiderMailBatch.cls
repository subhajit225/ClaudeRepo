public with sharing class PC_MDF_RequestRemiderMailBatch implements Database.Batchable<SObject>, Database.Stateful{
	public Database.queryLocator start(Database.BatchableContext batchContext){
        String submittedStage = 'Submitted';
        String queryStr = 'SELECT  Id  FROM PartnerFundRequest WHERE Status = :submittedStage';
        return Database.getQueryLocator(queryStr + '');
    }

    public void execute(Database.BatchableContext batchContext, List<PartnerFundRequest> oppMDFRequestList){
        system.debug('****'+ oppMDFRequestList);
        List<ProcessInstance> PIList = [SELECT Id,TargetObjectid, Status,(SELECT Id,actor.email, actor.id FROM Workitems)
                                        FROM ProcessInstance
                                        WHERE TargetObjectId IN: oppMDFRequestList AND Status='Pending'];
        System.debug('PIList'+PIList);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE developername = 'MDF_Request_Submitted_Reminder1'];
        OrgWideEmailAddress[] owea = [SELECT Id from OrgWideEmailAddress WHERE Address =:Label.MDFSenderEmailID];

        for(ProcessInstance PIRecord : PIList){
            if(Test.isRunningTest() || (PIRecord.Workitems !=null && PIRecord.Workitems[0] != null && PIRecord.Workitems[0].actor != null && PIRecord.Workitems[0].actor.email != null)){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(PIRecord.Workitems[0].actor.id);
                mail.setTemplateId(et.id);
                mail.setwhatId(PIRecord.TargetObjectid);
                mail.setSaveAsActivity(false);
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                mails.add(mail);
            }
        }
        if(!Test.isRunningTest() && !mails.isEmpty())
        	Messaging.sendEmail(mails);
    }

    public void finish(Database.BatchableContext batchContext){
        system.debug(LoggingLevel.DEBUG, 'PC_MDF_RequestRemiderMailBatch finished');
    }
}