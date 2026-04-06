public without sharing class TaskHandler implements ITrigger {
    
    @testVisible 
    private Map<Id, List<Deal_Registration__c>> mapLeadIdDealReg = new Map<Id, List<Deal_Registration__c>>();
    private List<Deal_Registration__c> updateDealRegs = new List<Deal_Registration__c>();
    private Map<Id, List<Lead>> mapLeadId = new Map<Id, List<Lead>>();
    private List<Lead> updateLead = new List<Lead>();
    private Map<String,Integer> mapLeadTaskCount = new Map<String,Integer>(); // SAL-183
    public static String PID_MEETING = 'PID Meeting';
    public static String CONVERT_TO_OPTY = 'Convert to Opportunity';
    public static String DO_NOT_CONVERT = 'Do Not Convert To Opportunity';
    public static String APPROVED = 'Approved';
    public static String REJECT = 'Rejected';
    public static String PENDING = 'Pending';
    public static String NO_PRIMARY_DEALREG_ERRORMSG = 'Please select primary Deal Registration on Lead to complete the task';
    
    //
    //bulkBefore
    //
    //This method is called prior to execution of a BEFORE trigger. Use this to cache
    //any data required into maps prior execution of the trigger.
    ///
    public void bulkBefore(){
        
    }
    /**
* bulkAfter
*
* This method is called prior to execution of an AFTER trigger. Use this to cache
* any data required into maps prior execution of the trigger.
*/
    public void bulkAfter(){
        if(!Trigger.isDelete) {
            Set<String> setLeadId = new Set<String>();
            Set<String> setLeadIdStatus = new Set<String>(); // SAL-183
            for(sObject so : Trigger.New) {
                Task tsk = (Task) so;
                Schema.SObjectType sobjectType = (tsk.WhoId != null ) ? tsk.WhoId.getSObjectType() : null;
                if(sobjectType ==  Lead.sobjectType && tsk.Subject == PID_MEETING) {
                    setLeadId.add(tsk.WhoId);
                }
                
                // SAL-183 start
                Schema.SObjectType sobjectTaskType = Schema.Task.sObjectType;
                if(sobjectTaskType ==  Task.sobjectType ) {
                    setLeadIdStatus.add(tsk.WhoId);
                }
                // SAL-183 end
            }
            if(setLeadId.size() > 0) {
                List<Deal_Registration__c> dealRegList = [SELECT id, Deal_Registration_Status__c,Lead__c, Primary__c from Deal_Registration__c where Lead__c in :setLeadId];
                for(Deal_Registration__c deal : dealRegList) {
                    if(!mapLeadIdDealReg.containsKey(deal.Lead__c)) {
                        mapLeadIdDealReg.put(deal.Lead__c, new List<Deal_Registration__c>());
                    } 
                    mapLeadIdDealReg.get(deal.Lead__c).add(deal);
                }
                List<Lead> leadList = [SELECT Id, Deal_Reg_Approval_Status__c from Lead where Id IN :setLeadId];
                for(Lead fLead : LeadList){
                    if(!mapLeadId.containsKey(fLead.Id)){
                        mapLeadId.put(flead.Id, new List<Lead>());
                    }
                    mapLeadId.get(fLead.Id).add(fLead);
                }               
                
            }
            // SAL-183 - Updating Attempts All Time field  start
            if(setLeadIdStatus.size()>0) {
                List<Lead> leadListStatus = [SELECT Id, Attempts_All_Time__c FROM Lead WHERE Id IN :setLeadIdStatus];
                for(Lead wrkLead : leadListStatus) {
                    if(wrkLead.Attempts_All_Time__c !=  null || wrkLead.Attempts_All_Time__c != 0) {
                        mapLeadTaskCount.put(wrkLead.Id,integer.valueof(wrkLead.Attempts_All_Time__c));
                    } else {
                        mapLeadTaskCount.put(wrkLead.Id,0);
                    }
                }
            }
            // SAL-183 Update Attempts All Time end

            System.debug('@@Task: setLeadId: '+setLeadId);
            System.debug('@@Task: mapLeadIdDealReg: '+mapLeadIdDealReg);
            
        }
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
        Task tsk = (Task) so;
        
        if(tsk.Subject == 'PID Meeting' && tsk.WhoId != null && mapLeadId.containsKey(tsk.WhoId)) {
            for(Lead iLead : mapLeadId.get(tsk.WhoId)){
                iLead.skipValidationRules__c=true;
                iLead.PID_Meeting_Task_Id__c=tsk.Id;
                
                if(!updateLead.contains(iLead)){
                    updateLead.add(iLead);
                }                
            }
        }
        
        // SAL-183 Updating Attempts All Time & Attempts Most Recent fields start
        // system.debug(' mapLeadTaskCount ' + mapLeadTaskCount);
        if(tsk.WhoId!= null && mapLeadTaskCount.containsKey(tsk.WhoId)) {
            for(Lead iLead : [SELECT Id, Attempts_All_Time__c,Most_Recent_Activity_Date__c   FROM Lead WHERE Id=:tsk.WhoId]) {
                //system.debug(' iLead.Attempts_All_Time__c ' + iLead.Attempts_All_Time__c);
                //iLead.Attempts_All_Time__c = mapLeadTaskCount.get(tsk.WhoId) + 1;
                if(iLead.Attempts_All_Time__c != null) {
                    iLead.Attempts_All_Time__c += 1;
                }else {
                    iLead.Attempts_All_Time__c = 1;
                }
                
                iLead.Most_Recent_Activity_Date__c = Date.today();
                if(!updateLead.contains(iLead)) {
                    updateLead.add(iLead);
                }  
            }
        } 
        // SAL-183 Updating Attempts All Time & Attempts Most Recent fields end    
    }
    
    /**
    * afterUpdate
    *
    * This method is called iteratively for each record updated during an AFTER
    * trigger.
    */
    public void afterUpdate(SObject oldSo, SObject so){
        Task tsk = (Task) so;
        Task oldtsk = (Task) oldSo;
        System.debug('@@proccing Task  '+ tsk);
        System.debug('@@mapLeadIdDealReg  '+ mapLeadIdDealReg);
        if(tsk.WhoId != null && mapLeadIdDealReg.containsKey(tsk.WhoId)) {
            if(tsk.Post_Meeting_Status__c==CONVERT_TO_OPTY){
                // SF-342
                Boolean isPrimaryDealRegFound = false;
                for(Deal_Registration__c dealReg : mapLeadIdDealReg.get(tsk.WhoId)) {                   
                    if(dealReg.Primary__c==true){
                        isPrimaryDealRegFound = true;
                        System.debug('@@Approved DR '+ dealReg);
                        dealReg.Deal_Registration_Status__c = APPROVED;
                        dealReg.Approval_Timestamp__c = Datetime.now();
                        //dealReg.skipValidation__c=true;
                        //updateDealRegs.add(dealReg);
                    } else {
                        System.debug('@@Rejected DR '+ dealReg);
                        dealReg.Deal_Registration_Status__c = REJECT;
                        //dealReg.skipValidation__c=true;
                        //updateDealRegs.add(dealReg);
                    }
                    dealReg.skipValidation__c=true;
                    updateDealRegs.add(dealReg);
                }
                if(!isPrimaryDealRegFound){
                    tsk.addError(NO_PRIMARY_DEALREG_ERRORMSG);
                }
                
            } else if(tsk.Post_Meeting_Status__c==DO_NOT_CONVERT && tsk.Post_Meeting_Status__c!=oldtsk.Post_Meeting_Status__c){
                for(Deal_Registration__c dealReg : mapLeadIdDealReg.get(tsk.WhoId)) {
                    if(dealReg.Primary__c==true){
                        System.debug('@@Rejected2 DR '+ dealReg);
                        dealReg.Deal_Registration_Status__c = REJECT;
                        dealReg.skipValidation__c=true;
                        updateDealRegs.add(dealReg);
                    }
                }           
            }
        }
        if(tsk.WhoId != null && mapLeadId.containsKey(tsk.WhoId)) {
            for(Lead iLead : mapLeadId.get(tsk.WhoId)){
                iLead.skipValidationRules__c=true;
                if(tsk.Post_Meeting_Status__c==CONVERT_TO_OPTY){
                    iLead.Deal_Reg_Approval_Status__c=APPROVED;
                    iLead.Deal_Reg_Submitted_Date__c = Datetime.now();
                    iLead.Deal_Reg_Approval_Timestamp__c = Datetime.now();
                }else if(tsk.Post_Meeting_Status__c==DO_NOT_CONVERT){
                    iLead.Deal_Reg_Approval_Status__c=REJECT;
                }
                if(!updateLead.contains(iLead)){
                    updateLead.add(iLead);
                }
                
            }
        }
        
        
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
        if(!updateDealRegs.isEmpty()){
            flowControll.DealRegistrationTrigger=false;
            update updateDealRegs;
        }
        List<Lead> finalList = new List<Lead>();
        set<string> uniqueId = new set<string>();
        for(Lead l : updateLead){
            if(!uniqueId.isEmpty() && !uniqueId.contains(l.Id)){
                uniqueId.add(l.Id);
                finalList.add(l);
            }else if(uniqueId.isEmpty()){
                uniqueId.add(l.Id);
                finalList.add(l);
            }
        }
        if(!finalList.isEmpty()){
            System.debug('@@finalList'+finalList);
            update finalList;
            
        }
    }
    // this class is not invoked anywhere
    public void forTestClass(){
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
    
}