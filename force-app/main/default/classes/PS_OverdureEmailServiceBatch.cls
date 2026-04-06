global class PS_OverdureEmailServiceBatch  implements Database.Batchable<SObject> {
    public string NOT_STARTED = 'Not Started';
    public string Day90 = '90';
	global Database.QueryLocator start(Database.BatchableContext BC) {
        string query = 'select Id,Order_Accepted_Timestamp__c,Notification_Sent_Date__c,Day_at_Email_Sent__c from Order where Order_Accepted_Timestamp__c != null AND Order_Accepted_Timestamp__c = LAST_N_DAYS:93';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<order> scope) {
		system.debug('@@ scope '+scope);
        List<Order> orderList = new List<order>();
        Set<Id> updatedorderIds = new Set<Id>();
        for(PS_Task__c ptask :[select Id,Task_Status__c,Order_Item__r.OrderId from PS_Task__c where Task_Status__c=: NOT_STARTED AND Order_Item__r.OrderId IN: scope]){
            updatedorderIds.add(ptask.Order_Item__r.OrderId);
        }
        system.debug('@@ updatedorderIds '+updatedorderIds);
        for(Order ord1 : scope){
            system.debug('@@ ord1.Order_Accepted_Timestamp__c '+ord1.Id+' ## '+Date.valueOf(ord1.Order_Accepted_Timestamp__c));
        system.debug('@@ date.today() '+date.today());
            system.debug('@@ Date.valueOf(ord1.Order_Accepted_Timestamp__c).daysBetween(Date.today()) '+Date.valueOf(ord1.Order_Accepted_Timestamp__c).daysBetween(Date.today()));
            if(!updatedorderIds.isEmpty() && updatedorderIds.contains(ord1.Id) && Date.valueOf(ord1.Order_Accepted_Timestamp__c).daysBetween(Date.today()) == 30 ){
            	Order ord = new Order(Id=ord1.Id,Notification_Sent_Date__c=system.today());
                orderList.add(ord);
            }else if(!updatedorderIds.isEmpty() && updatedorderIds.contains(ord1.Id) && Date.valueOf(ord1.Order_Accepted_Timestamp__c).daysBetween(Date.today()) == 60 ){
            	Order ord = new Order(Id=ord1.Id,Notification_Sent_Date__c=system.today());
                orderList.add(ord);
            }else if(!updatedorderIds.isEmpty() && updatedorderIds.contains(ord1.Id) && Date.valueOf(ord1.Order_Accepted_Timestamp__c).daysBetween(Date.today()) == 90 ){
            	Order ord = new Order(Id=ord1.Id,Notification_Sent_Date__c=system.today());
                orderList.add(ord);
            }
        }
        if(!orderList.isEmpty()){
            TriggerControl.stopOrderTrigger = true;
            update orderList;
        }
    }
    global void finish(Database.BatchableContext BC) {
        /*try{
            PC_DealRegExpiryUpdateBatch bt = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(bt,1);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_DealRegExpiryUpdateBatch '+e.getMessage());
        }
        try{
            PC_MDFSubmitClaimRemainderBatch claimReminder = new PC_MDFSubmitClaimRemainderBatch();
            Database.executeBatch(claimReminder);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_MDFSubmitClaimRemainderBatch '+e.getMessage());
        }
        try{
            PC_ContractExpiryBatch contractexpbatch = new PC_ContractExpiryBatch();
            Database.executeBatch(contractexpbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_ContractExpiryBatch '+e.getMessage());
        }*/
        try{
            LeadUnMQLBatchController unMQLbatch = new LeadUnMQLBatchController();
            Database.executeBatch(unMQLbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured LeadUnMQLBatchController '+e.getMessage());
        }
        /* MKT26-1249: Deactivate lead conversion */
        /* try{
            PC_MassConverLeadBatch massleadconvbatch = new PC_MassConverLeadBatch();
            Database.executeBatch(massleadconvbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_MassConverLeadBatch '+e.getMessage());
        } */
        /*try{
            PC_ReCalculate_FileSharingBatch filesharebatch = new PC_ReCalculate_FileSharingBatch();
            Database.executeBatch(filesharebatch,200);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_ReCalculate_FileSharingBatch '+e.getMessage());
        }*/
        /* commented for SFDCSOX-215 start
        try{
            updateProductTypeOLIBatch ptypebatch = new updateProductTypeOLIBatch();
            Database.executeBatch(ptypebatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured updateProductTypeOLIBatch '+e.getMessage());
        } 
        try{
            RenewalOppClosedAdminBatch roppclosedAdmin = new RenewalOppClosedAdminBatch();
            Database.executeBatch(roppclosedAdmin,50);
        }catch(Exception e){
            system.debug('@@ Exception occured RenewalOppClosedAdminBatch '+e.getMessage());
        } 
		commented for SFDCSOX-215 end */
        /*try{
            Database.executeBatch(new MIPSyncBatch(null), 1);
        }catch(Exception e){
            system.debug('@@ Exception occured MIPSyncBatch'+ e.getMessage());
        } */
        /* commented for SFDCSOX-215 start
        try{
            SDRLedBatchController sdrbatch = new SDRLedBatchController();
            Database.executeBatch(sdrbatch,50);
        }catch(Exception e){
            system.debug('@@ Exception occured SDRLedBatchController '+e.getMessage());
        }
		commented for SFDCSOX-215 end */
    }
}