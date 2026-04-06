public with sharing class ContactBatchSetMarketingNurture  implements Database.Batchable<SObject>, Schedulable  {
    public static string NQ ='Non-Qualified';
    public static string MEETING_SET = 'Meeting Set';
    //public static string NURTURE = 'Nurture';

    public static Set<String> groupNameSet = new Set<String>{'Marketing_Routing_Queue', 'Partner_Routing_Queue', 'Routing_Queue'};
    public static Set<String> profileNameSet = new Set<String>{'Rubrik Inside Sales', 'Rubrik Field Sales User'};
    public static Map<Id, Group> gpMap = new Map<Id, Group>([select Id,DeveloperName from Group where DeveloperName IN:groupNameSet]);
  
     public void execute(SchedulableContext sc) { 
        Database.executeBatch(this);
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {      
        Set<Id> setGroupId = gpMap.keySet();
        Set<String> setProfileName = profileNameSet;
        string query = 'select Id,Contact_Status__c,MQL__c,Last_MQL_Date__c,SAL__c,Meeting_Id__c,MeetingDate__c,Last_SAL_Date__c,Partner_MQL__c,owner.Profile.Name,Account.Account_Status__c,Account.ownerId,LastActivityDate,ContactRejectReason__c,Post_Meeting_Status__c from Contact where Contact_Status__c =:MEETING_SET';

                           // + ' '; //AND ( OwnerId In :setGroupId OR Owner.Profile.Name IN :setProfileName )
      system.debug('query>>'+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<Contact> conList = new List<Contact>();
        system.debug('scopescopescope+'+scope);
         system.debug('scopescopescope+'+scope.size());
        for(Contact con : scope){
            
            if(con.Meeting_Id__c ==null) {
                            con.Contact_Status__c = 'Nurture';
                            con.ContactRejectReason__c='Automated unMQL (Admin Only)';
                            con.MQL__c = false;
                            con.SAL__c = false;
                            con.Partner_MQL__c = false;
                            conList.add(con);
                } 
            
            else if(con.MeetingDate__c !=null && con.LastActivityDate !=null) {
                if((con.MeetingDate__c.date()+60<Date.today() && con.LastActivityDate.addDays(10) <=system.today())) {
			     con.Contact_Status__c = 'Nurture';
                 con.ContactRejectReason__c='Automated unMQL (Admin Only)';
				 con.MQL__c = false;
                con.SAL__c = false;
                con.Partner_MQL__c = false;
                conList.add(con);
                }          
            }
            
			/*
            if(isMQLorActivity(ld)) {
                if(ld.status != NQ  && ld.status != 'Nurture){
                    // Chnages added for MKT22-53 JIRA // Changes as per MKT22-296 - JIRA
				    if(ld.status != 'Nurture' || (ld.status == 'Nurture' && ld.Lead_Rejection_Reason__c == null))
                        ld.Lead_Rejection_Reason__c=Label.AutouMQLReason;
                	
                    ld.status = 'Nurture';
                }
                ld.MQL__c = false;
                ld.SAL__c = false;
                ld.Partner_MQL__c = false;
                leadList.add(ld);
            }*/
			
        }
        system.debug('leadListleadListleadList'+conList);
        if(!conList.isEmpty()){
            List<Contact> lstTempList = new List<Contact>{conList[0]};
                system.debug('-==-=-====lstTempList=' + lstTempList);
            Database.SaveResult[] srList = new List<Database.SaveResult>();
            srList= Database.update(conList,false);
            system.debug('srList'+conList);
        }
    }

    public void finish(Database.BatchableContext BC) {
         
    }

    /*private Boolean isUserOrQueue(Lead ld) {
        return ( ld.owner.Profile != null && profileNameSet.contains(ld.owner.Profile.Name) ) || gpMap.containsKey( ld.ownerId ); 
    }*/
/*
    private Boolean isMQLorActivity(Lead ld) {
        return ld.Last_MQL_Date__c != null && ld.Last_MQL_Date__c.addDays(30) <= system.today() && 
                ( ld.LastActivityDate == null || ( (ld.LastActivityDate !=null && ld.LastActivityDate.addDays(10) <=system.today()) )) && 
                ( ld.MQL__c || ld.Partner_MQL__c );
    }
    */
}