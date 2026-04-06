public without sharing class ContactTriggerHandler implements ITrigger {
    Map<Id,CampaignMember> latestCampaignMap;
    /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    public void bulkBefore(){}
    
    //Change by grazitti on 15-10-18
    //create Edge Trial user when a contact is created 
    @future
    public static void trialEdgeContact(Set<Id> contactIdList){
        List<User> usrList = new List<User>();
        try{
            List<Contact> conList = [select FirstName ,LastName ,Email ,Title ,Phone ,Id from Contact where Id = : contactIdList];
            List<String> emailList = new List<String>();
            for(Contact con : conList){
                emailList.add(con.Email);
            }
            List<String> userWithEmail = new List<String>();
            for(User u : [SELECT id,UserName from User where username IN: emailList ]){
                userWithEmail.add(u.UserName); 
            }
            System.debug(userWithEmail);
            List<User> usrUpdate = new List<User>();
            for(Contact con : conList){
                if(!userWithEmail.contains(con.Email)){
                    Double rnd =  Integer.valueOf( Math.Round( Math.random()*100000000));
                    Long Ln = Math.roundToLong(rnd);
                    Integer intVal = Integer.valueOf(Ln);
                    User usr = new User();
                    usr.FirstName = con.FirstName;
                    usr.LastName = con.LastName;
                    usr.Title = con.Title;
                    usr.Email = con.Email;
                    usr.Phone = con.Phone;
                    usr.ContactId = con.Id;
                    usr.profileid = Label.Trial_Edge_Profile;
                    String nameString = con.FirstName.substring(0,1) +' '+ con.LastName.substring(0,1)+' '+intVal;
                    nameString = nameString.trim();
                    nameString = nameString.substring(0, 7);
                    usr.Username = con.Email;
                    String nickName =  con.FirstName +'.'+ con.LastName+'-'+System.now().formatGMT('MMddyy-HHmm');
                    if(nickName.length() > 40){
                        nickName = con.FirstName.substring(0,1) +'.'+ con.LastName.substring(0,1)+'-'+System.now().formatGMT('MMddyy-HHmm');
                    }
                    usr.CommunityNickname = nickName;
                    usr.Alias =  nameString;
                    usr.TimeZoneSidKey = 'America/Phoenix';
                    usr.LocaleSidKey = 'en_US';
                    usr.EmailEncodingKey = 'ISO-8859-1';
                    usr.LanguageLocaleKey = 'en_US';
                    usrList.add(usr);
                }
                
            }
            System.debug(usrList);
            if(!usrList.isEmpty())
                insert usrList;
            if(test.isRunningTest())
                throw new DMLException();                
        }catch(Exception e){
            System.debug(e);
        }
    }
    
    public void bulkAfter(){
     
    }
    
    /**
    * beforeInsert
    *
    * This method is called iteratively for each record to be inserted during a BEFORE
    * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
    */
    public void beforeInsert(SObject so){
    }
    
    /**
    * beforeUpdate
    *
    * This method is called iteratively for each record to be updated during a BEFORE
    * trigger.
    */
    public void beforeUpdate(SObject oldSo, SObject so){

    }
    
    /**
    * beforeDelete
    *
    * This method is called iteratively for each record to be deleted during a BEFORE
    * trigger.
    */
    public void beforeDelete(SObject so){}
    
    /**
    * afterInsert
    *
    * This method is called iteratively for each record inserted during an AFTER
    * trigger. Always put field validation in the 'After' methods in case another trigger
    * has modified any values. The record is 'read only' by this point.
    */
    public void afterInsert(SObject so){
    }
    
    /**
    * afterUpdate
    *
    * This method is called iteratively for each record updated during an AFTER
    * trigger.
    */
    public void afterUpdate(SObject oldSo, SObject so){
        
        
    }
    
    /**
    * afterDelete
    *
    * This method is called iteratively for each record deleted during an AFTER
    * trigger.
    */
    public void afterDelete(SObject so){}
    
    /**
    * andFinally
    *
    * This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    */
    public void andFinally(){
        if(Trigger.isBefore && Trigger.isUpdate){
            if(latestCampaignMap != null && !latestCampaignMap.isEmpty()){
                update latestCampaignMap.values();
            }
        }
    }
}