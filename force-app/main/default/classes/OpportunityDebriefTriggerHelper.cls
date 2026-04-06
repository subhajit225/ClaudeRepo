public class OpportunityDebriefTriggerHelper {
    public static Map<string,opportunity> opptrackerMap;
    
    public static void updateOwner (List<Opportunity_Debrief__c> oppdefList) {
        List<Opportunity> oppList = new List<Opportunity>();
        List<Specialist_Request_Approval_Mapping__mdt> sraMDList = new List<Specialist_Request_Approval_Mapping__mdt>();
        opptrackerMap = new Map<string,opportunity>();
        Set<Id> oppIdSet = new Set<Id>();
        set<string> userIds = new set<string>();
        set<string> emailaddresses = new set<string>();
        List<string> tempList = new List<string>();
        for(Opportunity_Debrief__c od : oppdefList){
            oppIdSet.add(od.Opportunity__c);
        }
        if(!oppIdSet.isEmpty()){
            oppList = [select Id, Name, StageName,Escalation_Stage__c from Opportunity where Id IN: oppIdSet];
        }
        /*
        for(Opportunity_Debrief__c od : oppdefList){
            for(opportunity opp : oppList){
                opptrackerMap.put(opp.Id,opp);
            }
        }
        */
        opptrackerMap = new Map<string,opportunity>(oppList);
        sraMDList = [Select Id,Approvers__c,Primary_Focus_Area__c,Secondary_Focus_Area__c,Specialist_Record_Type_Name__c from Specialist_Request_Approval_Mapping__mdt];

        for(Opportunity_Debrief__c od : oppdefList){
            for(Specialist_Request_Approval_Mapping__mdt sraMD : sraMDList){
                /*SF-3900
                if(od.PM_Notified__c == null && od.Area__c =='Product Issue' && (od.Severity__c == 'Blocker' || od.Severity__c == 'Major') && !opptrackerMap.isEmpty() && opptrackerMap.containsKey(od.Opportunity__c) && opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Lost' && opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Won'){
                    if(od.Area_Detail__c == sraMD.Primary_Focus_Area__c && od.Area_Sub_Detail__c == sraMD.Secondary_Focus_Area__c && sraMD.Specialist_Record_Type_Name__c == 'PM'){
                        od.ownerId = sraMD.Approvers__c;
                        
                    } 
                }else */ if(od.PM_Notified__c == null && od.Area__c =='Missing Feature'){
                    if(od.Area_Detail__c == sraMD.Primary_Focus_Area__c && od.Area_Sub_Detail__c == sraMD.Secondary_Focus_Area__c && sraMD.Specialist_Record_Type_Name__c == 'FCTO'){
                        od.ownerId = sraMD.Approvers__c;
                    }
                }
            }
            od.PM_Notified__c = system.today();
            od.PM_Review_Status__c = 'Submitted';
            od.Opportunity_Escalation_Stage__c = opptrackerMap.get(od.Opportunity__c).Escalation_Stage__c;
        }
    }
    public static void sendEmail(List<Opportunity_Debrief__c> oppdefList){
     Map<string,string> oppDefEmail = new Map<string,string>();   
     List<Specialist_Request_Approval_Mapping__mdt> sraMDList = new List<Specialist_Request_Approval_Mapping__mdt>(); 
     sraMDList = [Select Id,Approvers__c,Primary_Focus_Area__c,Secondary_Focus_Area__c,Specialist_Record_Type_Name__c from Specialist_Request_Approval_Mapping__mdt];   
     EmailTemplate et = [Select id from EmailTemplate where developername  = 'Issue_Tracker_Notification' limit 1];
     List<contact> contactRec = [select id from contact limit 1];
     List<string> emailaddresses = new List<string>();   
     string userId;
     string userEmail;
     List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
     string emailstr;   
     set<string> userIdSet = new set<string>();   
     List<User> userList = new List<User>();   
     List<string> tempList = new List<string>(); 
     Map<string,string> oppDefUserId = new Map<string,string>();   
         for(Opportunity_Debrief__c od : oppdefList){
                for(Specialist_Request_Approval_Mapping__mdt sraMD : sraMDList){
                    if(od.Area__c =='Missing Feature' /*|| (od.Area__c =='Product Issue' && (od.Severity__c == 'Blocker' || od.Severity__c == 'Major') && opptrackerMap.containsKey(od.Opportunity__c) && opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Lost' && opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Won')*/){
                        if(od.Area_Detail__c == sraMD.Primary_Focus_Area__c && od.Area_Sub_Detail__c == sraMD.Secondary_Focus_Area__c){
                            if(!oppDefUserId.isEmpty() && oppDefUserId.containsKey(od.Id)){
                                userId = oppDefUserId.get(od.Id);
                                userId = userId+';'+Id.valueOf(sraMD.Approvers__c);
                                oppDefUserId.put(od.Id,userId);
                            }else{
                                oppDefUserId.put(od.Id,Id.valueOf(sraMD.Approvers__c));
                            }
                        }
                    }
                }
             userId = '';
         }
        for(string str : oppDefUserId.keyset()){
            if(oppDefUserId.get(str).contains(';')){
                tempList = oppDefUserId.get(str).split(';');
                for(string val : tempList){
                    userIdSet.add(val);
                }
            }else{
                userIdSet.add(oppDefUserId.get(str));
            } 
        }
        if(!userIdSet.isEmpty()){
            userList = [select Id,Name,email from User where Id IN: userIdSet];
            for(Opportunity_Debrief__c od : oppdefList){
                for(User u: userList){
                    if(oppDefUserId.containskey(od.Id) && oppDefUserId.get(od.Id).contains(u.Id)){
                        if(!oppDefEmail.isEmpty() && oppDefEmail.containsKey(od.Id)){
                            userEmail = oppDefEmail.get(od.Id);
                            userEmail = userEmail+';'+u.Email;
                            oppDefEmail.put(od.Id,userEmail);
                        }else{
                            oppDefEmail.put(od.Id,u.Email);
                        }
                    }     
                }
                if(!opptrackerMap.isEmpty() && opptrackerMap.containsKey(od.Opportunity__c)  && od.Area__c =='Product Issue' && (od.Severity__c == 'Blocker' || od.Severity__c == 'Major')  &&  opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Lost' && opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Won' && opptrackerMap.get(od.Opportunity__c).stageName != '7 Closed Admin'){
                    userEmail = userEmail+';'+label.Opportunity_Debrief_PM_email;
                    oppDefEmail.put(od.Id,userEmail);
                }
                userEmail = '';
            }
        }
        system.debug('@@ oppDefEmail '+oppDefEmail);

        for(Opportunity_Debrief__c od : oppdefList){
            emailaddresses.clear();
            emailstr = oppDefEmail.get(od.Id);
            if(!string.isBlank(emailstr) && emailstr.contains(';')){
                emailaddresses = emailstr.split(';');
            }
            if(emailaddresses != null && !emailaddresses.isEmpty()){
                 Messaging.SingleEmailMessage  mail = new Messaging.SingleEmailMessage();
                 mail.settargetObjectId(contactRec[0].Id);
                 mail.setTreatTargetObjectAsRecipient(false);
                 mail.setWhatId(od.Id);
                 mail.setToAddresses(emailaddresses);   
                 mail.setTemplateId(et.id);
                 emailList.add(mail);
            }
        }
        if(!emailList.isEmpty()){
            try {
                messaging.sendEmail(emailList);
            }catch(Exception ex){
                System.debug(System.LoggingLevel.DEBUG, 'email sending failed!, OpportunityDebriefTriggerHelper.');
            }
        }
    }
}