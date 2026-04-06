global class PC_DealRegExpiryUpdateBatch  implements Database.Batchable<SObject>,Database.RaisesPlatformEvents {
    public static string EXPIRED = 'Expired';
    public static string APPROVED = 'Approved';
    public static string REJECTED = 'Rejected';
    public static string PENDING_CONVERSION = 'Pending Conversion';
    public static string PENDING_MEETING = 'Pending Meeting';
    public static string SUBMITTED = 'Submitted';
    public static string CLOSED_WON = '7 Closed Won';
    public static string CLOSED_LOST = '7 Closed Lost';
    public static string CLOSED_ADMIN =  '7 Closed Admin';
    public static string ESCALATED =  'Escalated';
    public static String GSI_NDA = 'GSI-NDA Pending Approval';
    /**
     * @description - start method for batch class to query all Deal Registrations
     * @return Database.QueryLocator
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        string query = 'Select Id,Name,Deal_Registration_Status__c,Deal_Reg_Exp_Date__c,Deal_Registration_Expiration__c,Lead__c,Lead__r.Deal_Reg_Approval_Status__c,Lead__r.isconverted,Deal_Registration_Sub_Status__c,Opportunity__c,Opportunity__r.Deal_Reg_Approval_Status__c,Opportunity__r.Deal_Reg_Expiration_Date__c,Opportunity__r.Deal_Registration_Number__c,Opportunity__r.stageName,Opportunity__r.IsClosed,PS_Escalated__c, RecordType.Name from Deal_Registration__c where Deal_Registration_Expiration__c !=null AND Deal_Registration_Expiration__c = LAST_N_DAYS:30 AND Deal_Registration_Status__c NOT IN (:EXPIRED,:REJECTED)';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Deal_Registration__c> scope) {
        List<Opportunity> oppToUpdateList = new List<Opportunity>();
        List<Lead> leadToUpdateList = new List<Lead>();
        Map<String,Deal_Registration__c> dealRegToUpdate = new Map<String,Deal_Registration__c>();
        
        for(Deal_Registration__c dealreg : scope){
            if (dealreg.Deal_Registration_Expiration__c.addDays(1) != System.today()) continue;
            Boolean isApprovedOrPending = dealreg.Deal_Registration_Status__c == APPROVED || dealreg.Deal_Registration_Status__c == PENDING_CONVERSION;
            Boolean isEscalatedGSI = dealreg.Deal_Registration_Status__c == ESCALATED && dealreg.Deal_Registration_Sub_Status__c == GSI_NDA;
            Boolean isSubmittedOrMeeting = dealreg.Lead__c == null && (dealreg.Deal_Registration_Status__c == SUBMITTED || dealreg.Deal_Registration_Status__c == PENDING_MEETING);
            Boolean isEscalatedOpportunity = dealreg.Deal_Registration_Status__c == ESCALATED && dealreg.Opportunity__c != null && dealreg.PS_Escalated__c;
            Boolean hasUnconvertedLead = dealreg.Lead__c != null && !dealreg.Lead__r.isconverted && isApprovedOrPending;
            Boolean hasTaggedOpportunity = dealreg.Deal_Registration_Status__c == APPROVED && dealreg.Opportunity__c != null;
            Boolean shouldUpdateDR = false;
            
            Deal_Registration__c updateDR = new Deal_Registration__c(Id=dealreg.Id);
            
            if (isApprovedOrPending || isEscalatedGSI || isSubmittedOrMeeting || isEscalatedOpportunity) {
                updateDR.Deal_Registration_Status__c = EXPIRED;
                updateDR.Remainder_Expiry_Notification_Sent_Date__c = System.today();
                updateDR.Send_Expiry_Notification__c = true;
                updateDR.Deal_Registration_Sub_Status__c = '';
                shouldUpdateDR = true;
                if (isEscalatedOpportunity) {
                    updateDR.Opportunity__c = null;
                    updateDR.PS_Escalated__c = false;
                    updateDR.Primary_Deal_Registration__c = false;
                }
            }
            
            if (hasUnconvertedLead) {
                leadToUpdateList.add(new Lead(Id = dealreg.Lead__c, Deal_Reg_Approval_Status__c = EXPIRED, copy_of_Deal_Reg_Expiry_Date__c = dealreg.Deal_Registration_Expiration__c));
            }
            
            if (hasTaggedOpportunity) {
                if (dealreg.Opportunity__r.IsClosed != null && dealreg.Opportunity__r.IsClosed == true) {
                    updateDR.Send_Expiry_Notification__c = false;
                    updateDR.Deal_Registration_Sub_Status__c = dealreg.Deal_Registration_Sub_Status__c;
                    shouldUpdateDR = true;
                }
                if (dealreg.Opportunity__r.Deal_Registration_Number__c != null && dealreg.Opportunity__r.Deal_Reg_Approval_Status__c == APPROVED) {
                    oppToUpdateList.add(new Opportunity(Id = dealreg.Opportunity__c, Deal_Reg_Approval_Status__c = EXPIRED, Deal_Reg_Expiration_Date__c = dealreg.Deal_Registration_Expiration__c));
                }
            }
            if (shouldUpdateDR) {
                dealRegToUpdate.put(updateDR.Id, updateDR);
            }
        }
        
        if(!dealRegToUpdate.isEmpty()){
            flowControll.DealRegistrationTrigger = false;
            update dealRegToUpdate.values();
        }
        if(!oppToUpdateList.isEmpty()){
            flowControll.opportunityTriggerHandler = false;
            update oppToUpdateList;
        }
        if(!leadToUpdateList.isEmpty()){
            flowControll.LeadTriggerHandler = false;
            update leadToUpdateList;
        }
    }
    /**
     * @description - finish method for batch class
     * @return void
     */
    global void finish(Database.BatchableContext BC) {
        //no code needed
    }
}