global class PC_MassConverLeadBatch  implements Database.Batchable<SObject>  {
    public Integer val = 5;
    public string NQ ='Non-Qualified';
    public string DISCOVERY = '1 Discovery';
    public string CLOSEDLOST = '7 Closed Lost';
    public string NURTURE = '0 Nurture';
    public string ACTIVE_OPPORTUNITY = 'Active Opportunity';
    public string CUSTOMER = 'Customer';
    public string PROSPECT = 'Prospect';
    public string DISTRIBUTOR = 'Distributor';
    public string RESELLER = 'Reseller';
    public string MSP_RESELLER = 'MSP-Reseller';
    public string MSP = 'MSP';
    public string EXISTING_CUSTOMER = 'Existing Customer';
    public string AMER_PS = 'AMER-PS';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
               
        string query = 'select Id,status,L2A_Confidence_Code__c,L2A_Account__c,L2A_Account__r.type,L2A_Account__r.Account_Status__c,L2A_Account__r.Id,L2A_Account__r.ETM_Territory__c,Agreed_to_Edge_Trail_Agreement__c from Lead where status !=:NQ AND L2A_Confidence_Code__c >=:val AND Agreed_to_Edge_Trail_Agreement__c = false AND L2A_Account__r.ETM_Territory__c !=:AMER_PS';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        list<Database.LeadConvert> leadConverts = new list<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        Set<string> accIdSet = new Set<string>();
        Set<string> oppAccSet = new Set<string>();
        List<opportunity> oppList = new List<opportunity>();
        system.debug('@@ scope '+scope);
        for(Lead ld : scope){
            if(!string.isBlank(ld.L2A_Account__c) && ld.L2A_Account__r.Account_Status__c == ACTIVE_OPPORTUNITY ){
                accIdSet.add(ld.L2A_Account__c);
            }
        }
        if(!accIdSet.isEmpty()){
            oppList = [select Id,StageName,AccountId from Opportunity where AccountId IN: accIdSet AND StageName !=:NURTURE AND StageName !=:DISCOVERY AND StageName !=:CLOSEDLOST];
        }    
        system.debug('@@ oppList '+oppList);
        for(Opportunity opp: oppList){
            oppAccSet.add(opp.AccountId);
        }
        system.debug('@@ oppAccSet '+oppAccSet);
        for(Lead ld : scope){
            if(!string.isBlank(ld.L2A_Account__c)){
            string accId = Id.valueOf(ld.L2A_Account__r.Id);
            if((ld.L2A_Account__r.Account_Status__c == ACTIVE_OPPORTUNITY && !oppAccSet.isEmpty() && oppAccSet.contains(accId) && (ld.L2A_Account__r.type == CUSTOMER || ld.L2A_Account__r.type == PROSPECT )) 
               ||(ld.L2A_Account__r.Account_Status__c == EXISTING_CUSTOMER && ld.L2A_Account__r.type != DISTRIBUTOR && ld.L2A_Account__r.type != RESELLER  && ld.L2A_Account__r.type != MSP_RESELLER && ld.L2A_Account__r.type != MSP) 
               || (ld.L2A_Account__r.type == DISTRIBUTOR || ld.L2A_Account__r.type == RESELLER  || ld.L2A_Account__r.type == MSP_RESELLER || ld.L2A_Account__r.type == MSP)){
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(ld.Id);
                    lc.setAccountId(ld.L2A_Account__r.Id);
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    system.debug('@@ Ld '+ld.Id);
                    leadConverts.add(lc);
               }
               }
        }
        if(!leadConverts.isEmpty()){
            Database.LeadConvertResult[] lcrList = Database.convertLead(leadConverts, false);
        }
    }
    global void finish(Database.BatchableContext BC) {

    }
}