public with sharing class LeadBatchSetMarketingNurture  implements Database.Batchable<sObject>, Schedulable  {
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
        string query = 'SELECT Id,status,MQL__c,Last_MQL_Date__c,SAL__c,Lead_Rejection_Reason__c,Last_SAL_Date__c,Partner_MQL__c,owner.Profile.Name,OwnerId,LastActivityDate,MeetingDate__c,Post_Meeting_Status__c,Meeting_Id__c from Lead '
                            +'WHERE status =:MEETING_SET AND IsConverted =false'; 
                           // + ' '; //AND ( OwnerId In :setGroupId OR Owner.Profile.Name IN :setProfileName )
      system.debug('query>>'+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Lead> leadList = new List<Lead>();
        system.debug('scopescopescope+'+scope);
         system.debug('scopescopescope+'+scope.size());
        for(Lead ld : scope){
            
            if(ld.Meeting_Id__c ==null) {
                            ld.status = 'Nurture';
                            ld.Lead_Rejection_Reason__c='Automated unMQL (Admin Only)';
                            ld.MQL__c = false;
                            ld.SAL__c = false;
                            ld.Partner_MQL__c = false;
                            leadList.add(ld);
                } 
            
            else if(ld.MeetingDate__c !=null && ld.LastActivityDate!=null) {
                if((ld.LastActivityDate.addDays(10) <system.today() && ld.MeetingDate__c.date()+60<Date.today()) ) {
			     ld.status = 'Nurture';
                 ld.Lead_Rejection_Reason__c='Automated unMQL (Admin Only)';
				 ld.MQL__c = false;
                ld.SAL__c = false;
                ld.Partner_MQL__c = false;
                leadList.add(ld);
                }          
            }
            
			/*
            if(isMQLorActivity(ld)) {
                if(ld.status != NQ  && ld.status != 'Nurture'){
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
        system.debug('leadListleadListleadList'+leadList);
        if(!leadList.isEmpty()){
             Database.SaveResult[] srList = new List<Database.SaveResult>();
           srList= Database.update(leadList,false);
            
            system.debug('srList'+srList);
        }
    }

    //MKT23-32432
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