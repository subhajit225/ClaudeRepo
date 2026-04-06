public class IdeaComUtils {

    @future
    public static void sendIdeaCommentEmail(Id ideaId, Id createdById) {
      
        String templateId= [select Id from EmailTemplate where DeveloperName = 'Idea_Comment' and TemplateType='visualforce'].Id;
        system.debug('### comment template ' + templateId);
        
        OrgWideEmailAddress[] owea = [select Id, Address from OrgWideEmailAddress where Address = 'donotreply@rubrik.com'];

        Id lastCommentById;
        try {
            lastCommentById = [select CreatedById from IdeaComment where IdeaId = :ideaId order by CreatedDate desc Limit 1].CreatedById;
        } catch (exception ex) {}
        system.debug('\n ### lastCommentById ' + lastCommentById);        
        
        Map<Id, String> userMap = new Map<Id, String>();
        Set<Id> userDownVoter = new Set<Id>();
        
        //Fetch all Repliers
        User[] commenters = [SELECT Id,Email from User where Community_Notifications__c=true AND IsActive = true and Id IN 
                            (SELECT CreatedById FROM IdeaComment Where IdeaID = :ideaId and IsDeleted=false 
                                //and CreatedById!=:createdById
                               // and CreatedById!=:lastCommentById
                                ) 
                                Limit 50000];
                                
       system.debug('\n ### commenters.size ' + commenters.size() + ' => ' + commenters);                                
                                                                
       User[] promoters = [SELECT Id, Email from User where Community_Notifications__c=true AND IsActive = true and Id IN 
       (select CreatedbyId from Vote where ParentId =:ideaId and isdeleted=false and Type='Up')
       limit 50000];   
       
       Vote[] downvotes = [select CreatedbyId, Id, ParentID, Type from Vote where ParentId=:ideaId and Type='Down'];
       
       if(downvotes.size()>0){
       for(Vote v : downvotes){
       userDownVoter.add(v.CreatedbyId);
       }
       }
                                                             
       system.debug('\n ### promoters.size ' + promoters.size() + ' => ' + promoters);                                
                       
       for (User c : commenters) {
       if(!userDownVoter.contains(c.Id)) userMap.put(c.Id, c.Email);
       }                                                         

       for (User p : promoters) {
       if(!userDownVoter.contains(p.Id)) userMap.put(p.Id, p.Email);
       } 
       
       system.debug('### usermap ' + userMap);            
                                                                
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        //Iterate over the filtered commenters                        
       // for (User c : commenters) {
           for (Id u : userMap.keySet() ){
            //Construct email object with all fields set
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {userMap.get(u)};
            mail.setToAddresses(toAddresses);
            if(owea.size()==0) mail.setSenderDisplayName('Rubrik Ideas');
            if(owea.size()>0) mail.setReplyTo(owea.get(0).Address);
            if(owea.size()==0) mail.setReplyTo('donotreply@rubrik.com');

            mail.setSaveAsActivity(false);
            mail.setTargetObjectId(u);
            mail.setWhatId(ideaId);
            mail.setTemplateId(templateId);
            if(owea.size()>0) mail.setOrgWideEmailAddressId(owea.get(0).Id);
            mailList.add(mail); 
       }    
                  
       Messaging.sendEmail(mailList);
    }

}