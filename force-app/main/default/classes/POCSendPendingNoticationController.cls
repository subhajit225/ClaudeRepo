public with sharing class POCSendPendingNoticationController {
    
    //MKT23-661 JIRA Deployment POCSendPendingNoticationController.cls deployment V9
    @InvocableMethod 
    public static void sendEmailNotification (List<Id> PocIds) {
        system.debug('PocIds----->'+PocIds);
        LIST<id> userId = new LIST<id>();
        Map<String,String> ActorMap = new Map<String,String>();
        LIST<id> pocObjId = new LIST<id>();
        Map<id , id> mapOfPocIdToUsrId = new MAP<id , id>();
        Map<id , id> mapOfUserIdToPiwId = new MAP<id , id>();
        Map<id , POC__c> mapOfUserIdToPoc = new MAP<id , POC__c>();
        Map<id , POC__c> pojObjmap = new MAP<id , POC__c>();
        
        LIST<ProcessInstanceWorkitem> piw = [SELECT ActorId,Actor.Name, ProcessInstance.TargetObjectId 
                                             FROM ProcessInstanceWorkitem 
                                             WHERE ProcessInstance.targetObjectId IN: PocIds and ProcessInstance.Status='Pending' ];
        system.debug('piw----->'+piw);
        if(piw.size()>0) {
            for(ProcessInstanceWorkitem p :piw )
            {      
                mapOfUserIdToPiwId.put(p.ActorId ,p.Id );
                userId.add(p.ActorId);
                ActorMap.put(p.ActorId,p.Actor.Name);
                mapOfPocIdToUsrId.put(p.ProcessInstance.TargetObjectId,p.ActorId );
            } 
        }
        
        system.debug('mapOfUserIdToPiwId--->'+mapOfUserIdToPiwId);
        system.debug('userId--->'+userId);
        system.debug('mapOfPocIdToUsrId--->'+mapOfPocIdToUsrId);
        
        if(mapOfPocIdToUsrId.size()>0) {
            List<POC__C> pocObjDetails = [SELECT id,Name , POC_Submitter__c,Approval_Status__c, POC_Submitter__r.Name
                                          FROM POC__c WHERE id IN:PocIds ];
            system.debug('pocObjDetails--->'+pocObjDetails);
            for(POC__C pocObj : pocObjDetails ) {  
                if(mapOfPocIdToUsrId.containsKey(pocObj.Id)){
                    mapOfUserIdToPoc.put(mapOfPocIdToUsrId.get(pocObj.Id),pocObj );
                }
            }
            
            List<POC__c> updatePOCRecord = new List<POC__c>();
            for(POC__C pocObj : pocObjDetails ) {  
                if(pocObj.Approval_Status__c =='Pending' || pocObj.Approval_Status__c =='Extension Requested' ) {
                   updatePOCRecord.add(new POC__C (id=pocObj.id,Current_POC_Submission_Date__c=system.now(),Send_Pending_Notification__c=true)); 
                }
            }
            
            if(updatePOCRecord.size()>0) {
                update updatePOCRecord;
            }
            
        }
        LIST<Messaging.SingleEmailMessage> allMsg = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate where DeveloperName='Reminder_Pending_Approval_Request'];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'donotreply@rubrik.com'];
        
        if(!userId.isEmpty() && mapOfUserIdToPoc.size() >0){
            for(Id indUser : userId){
                if(mapOfUserIdToPoc.containsKey(indUser))  {
                    if(mapOfUserIdToPoc.get(indUser) != null){  
                        String htmlBody = emailTemplate.HtmlValue;
                        if(mapOfUserIdToPoc.get(indUser).POC_Submitter__c !=null)
                          htmlBody = htmlBody.replace('{!POC__c.POC_Submitter__c}',mapOfUserIdToPoc.get(indUser).POC_Submitter__r.Name);
                        
                        //htmlBody = htmlBody.replace('{!Workitem.ID}', mapOfUserIdToPiwId.get(indUser));
                         String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
                        String StringURL = baseUrl+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+mapOfUserIdToPiwId.get(indUser);
                        String linkgenerate = '<a href ='+StringURL+' > link </a>'; 
                         htmlBody = htmlBody.replace('{!LINK}', linkgenerate);
                        htmlBody = htmlBody.replace(']]>', '');
                        List<string> toAddress = new List<string>();
                        toAddress.add(Label.POCHelpEmial);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateID(emailTemplate.id);
                        mail.setSubject(emailTemplate.Subject+'-'+mapOfUserIdToPoc.get(indUser).Name);
                       // mail.setCCAddresses( new String[]{'ankush.dubey@rubrik.com'});
                        
                        String s1 =String.valueof(indUser);
                        if(s1.startsWith('00G'))
                        {  system.debug('inside if---->');
                         mail.setToAddresses(toAddress);
                        }
                        else
                        {    system.debug('inside else---->');
                         mail.setTargetObjectId(indUser);
                         //  mail.setTargetObjectId(indUser); 
                        }
                        mail.setSaveAsActivity(false);
                        mail.setHtmlBody(htmlBody);
                        if ( owea.size() > 0 ) {
                            mail.setOrgWideEmailAddressId(owea.get(0).Id);
                        }
                        
                        allMsg.add(mail);
                    }
                }
            }  
            if(allMsg.size()>0) {
                Messaging.SendEmailResult [] results = Messaging.sendEmail(allMsg);
                if (results[0].success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' + results[0].errors[0].message);
                } 
            }
            
        }
        
    }        
}