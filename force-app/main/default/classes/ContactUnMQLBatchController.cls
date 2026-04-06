global class ContactUnMQLBatchController  implements Database.Batchable<SObject>  {
    public string NQ ='Non-Qualified';
    public string MEETING_SET = 'Meeting Set';
    public string NURTURE = 'Nurture';
    public string RUBRIK_INSIDE_SALES = 'Rubrik Inside Sales';
    public string RUBRIK_FIELD_SALES_USER = 'Rubrik Field Sales User';
    public string LOST_OPPORTUNITY ='Lost Opportunity';
    public string PROSPECT ='Prospect';
    public string ACTIVE_OPPORTUNITY ='Active Opportunity';
    public string EXISTING_CUSTOMER ='Existing Customer';
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
               
   string query = 'select Id,Contact_Status__c,MQL__c,Last_MQL_Date__c,SAL__c,Last_SAL_Date__c,Partner_MQL__c,owner.Profile.Name,Account.Account_Status__c,Account.ownerId,LastActivityDate from Contact where Contact_Status__c !=:MEETING_SET AND (MQL__c = true OR SAL__c = true OR Partner_MQL__c = true)';

        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<Contact> conList = new List<Contact>();
        for(Contact con : scope){
          
 // Chnages added for MKT22-42 JIRA for Lastactivity condition// 
    if((con.owner.Profile != null && (con.owner.Profile.Name.containsIgnoreCase(RUBRIK_INSIDE_SALES) || con.owner.Profile.Name.containsIgnoreCase(RUBRIK_FIELD_SALES_USER))) && (((con.MQL__c || con.Partner_MQL__c) && con.Last_MQL_Date__c!= null && con.Last_MQL_Date__c.addDays(30) <= system.today()&& ( con.LastActivityDate == null || (con.LastActivityDate !=null && con.LastActivityDate.addDays(10) <=system.today() ))) || (con.SAL__c && con.Last_SAL_Date__c != null && con.Last_SAL_Date__c.addDays(30) <= system.today())))
    {
       
                if(con.Account.Account_Status__c == LOST_OPPORTUNITY || con.Account.Account_Status__c == PROSPECT || con.Account.Account_Status__c == EXISTING_CUSTOMER ){
                    if(con.Contact_Status__c != NQ  && con.Contact_Status__c != NURTURE){
                    	con.Contact_Status__c = NURTURE;
                          // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74.... //

                          con.ContactRejectReason__c=Label.AutouMQLReason;
                    }
                    con.MQL__c = false;
                    con.SAL__c = false;
                    con.Partner_MQL__c = false;
                }else if(con.Account.Account_Status__c == ACTIVE_OPPORTUNITY  && con.Contact_Status__c != NURTURE){
                    con.ownerId = con.Account.ownerId;
                }
                conList.add(con);
            }
        }
        if(!conList.isEmpty()){
            Database.update(conList,false);
        }
    }
    global void finish(Database.BatchableContext BC) {
		
    }
    
}