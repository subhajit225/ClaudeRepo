global class LeadUnMQLBatchController  implements Database.Batchable<SObject>  {
    public static string NQ ='Non-Qualified';
    public static string MEETING_SET = 'Meeting Set';
    public static string NURTURE = 'Nurture';

    public static Set<String> groupNameSet = new Set<String>{'Marketing_Routing_Queue', 'Partner_Routing_Queue', 'Routing_Queue'};
    public static Set<String> profileNameSet = new Set<String>{'Rubrik Inside Sales', 'Rubrik Field Sales User'};
    public static Map<Id, Group> gpMap = new Map<Id, Group>([select Id,DeveloperName from Group where DeveloperName IN:groupNameSet]);

    global Database.QueryLocator start(Database.BatchableContext BC) {      
        Set<Id> setGroupId = gpMap.keySet();
        Set<String> setProfileName = profileNameSet;
        string query = 'SELECT Id,status,MQL__c,Last_MQL_Date__c,SAL__c,Lead_Rejection_Reason__c,Last_SAL_Date__c,Partner_MQL__c,owner.Profile.Name,OwnerId,LastActivityDate,MeetingDate__c from Lead '
                            +'WHERE status !=:MEETING_SET AND Deal_registration__c = false AND (MQL__c = true OR Partner_MQL__c = true)' 
                            + ' AND ( OwnerId In :setGroupId OR Owner.Profile.Name IN :setProfileName )';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Lead> leadList = new List<Lead>();
        map<Id,Lead> leadListMap = new map<id,Lead>();
        system.debug('scope>>>>'+scope);
        for(Lead ld : scope){
            if(ld.MeetingDate__c!=null) {
             if(ld.MeetingDate__c.date()+60<Date.today()) {
                 system.debug('Meeting Set ld>>>'+ld);
                ld.SDR_Led__c = FALSE;
                //leadList.add(ld);
                leadListMap.put(ld.Id,ld);
              }
                
            }
           
            if(isMQLorActivity(ld)) {
                if(ld.status != NQ  && ld.status != NURTURE){
                    // Chnages added for MKT22-53 JIRA // Changes as per MKT22-296 - JIRA
				    if(ld.status != NURTURE || (ld.status == NURTURE && ld.Lead_Rejection_Reason__c == null))
                        ld.Lead_Rejection_Reason__c=Label.AutouMQLReason;
                	
                    ld.status = NURTURE;
                }
                ld.MQL__c = false;
                ld.SAL__c = false;
                ld.Partner_MQL__c = false;
                leadListMap.put(ld.Id,ld);
                //leadList.add(ld);
            }
        }
        system.debug('leadListMap>>>'+leadListMap);
        if(leadListMap.size()>0){
            Database.update(leadListMap.Values(),false);
        }
    }

    global void finish(Database.BatchableContext BC) {
       ContactUnMQLBatchController b = new ContactUnMQLBatchController();
       Database.executeBatch(b,100);    
    }

    /*private Boolean isUserOrQueue(Lead ld) {
        return ( ld.owner.Profile != null && profileNameSet.contains(ld.owner.Profile.Name) ) || gpMap.containsKey( ld.ownerId ); 
    }*/

    private Boolean isMQLorActivity(Lead ld) {
        return ld.Last_MQL_Date__c != null && ld.Last_MQL_Date__c.addDays(30) <= system.today() && 
                ( ld.LastActivityDate == null || ( (ld.LastActivityDate !=null && ld.LastActivityDate.addDays(10) <=system.today()) )) && 
                ( ld.MQL__c || ld.Partner_MQL__c );
    }
    
}