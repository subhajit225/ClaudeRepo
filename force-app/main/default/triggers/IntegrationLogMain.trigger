trigger IntegrationLogMain on Error_Logs__c (before insert, after insert, before update, after update) {
    new IntegrationLogMainTriggerHandler().run();
	
    /*
     * //OLD CODE - commented as part of 
    if(trigger.isAfter ){
        Set<Error_Logs__c> errorLogIds = new Set<Error_Logs__c>();
        //Set<Account> errorLogIds = new Set<Account>();
        Set<Id> onSuccessupdateOrderList = new Set<Id>();
        Set<Id> onErrorupdateOrderList = new Set<Id>();
        Set<Id> onSuccessUpdateAccountList = new Set<Id>();
        Set<Id> onErrorupdateAccountList = new Set<Id>();
        Set<Account> updateAccountSet = new Set<Account>();
        Set<Order> updateOrderSet = new Set<Order>();
        List<Account> updateAccountList = new List<Account>();
        List<Order> updateOrderList = new List<Order>();
        if(trigger.isinsert){
            for(Error_Logs__c error : trigger.new){

                // skip sfdc error logs
                if(error.Type__c == 'SFDC') continue;

                if(error.Related_Order__c != null && error.Success__c ==true){
                    onSuccessUpdateOrderList.add(error.Related_Order__c);
                }
                else if(error.Related_Order__c != null && error.Success__c ==false){
                    onErrorupdateOrderList.add(error.Related_Order__c);
                }
                else if(error.Account__c !=null && error.Related_Order__c == null && error.Success__c ==true){
                    onSuccessUpdateAccountList.add(error.Account__c);
                }
                else if(error.Account__c !=null && error.Related_Order__c == null && error.Success__c ==false){
                    onErrorupdateAccountList.add(error.Account__c);
                }
            }
            for(Account acc : [select id,name , Update_Netsuite__c, Sync_To_NetSuite__c, Integration_failure__c from Account where Id In: onSuccessUpdateAccountList]){
                acc.Update_Netsuite__c = false;
                acc.Sync_To_NetSuite__c = false;
                acc.Integration_failure__c = false;
                updateAccountSet.add(acc);

            }
            for(Account acc : [select id,name , Update_Netsuite__c, Sync_To_NetSuite__c, Integration_failure__c from Account where Id In: onErrorupdateAccountList]){
                acc.Update_Netsuite__c = true;
                acc.Sync_To_NetSuite__c = true;
                acc.Integration_failure__c = true;
                updateAccountSet.add(acc);

            }
            for(Order ordr : [select id,name , Update_Netsuite__c, Sync_To_NetSuite__c, Integration_failure__c from Order where Id In: onSuccessUpdateOrderList]){
                ordr.Update_Netsuite__c = false;
                ordr.Sync_To_NetSuite__c = false;
                ordr.Integration_failure__c = false;
                updateOrderSet.add(ordr);

            }
            for(Order ordr : [select id,name , Update_Netsuite__c, Sync_To_NetSuite__c, Integration_failure__c from Order where Id In: onErrorUpdateOrderList]){
                ordr.Update_Netsuite__c = true;
                ordr.Sync_To_NetSuite__c = true;
                ordr.Integration_failure__c = true;
                updateOrderSet.add(ordr);

            }
        }
        system.debug('Value updateOrderList--'+updateOrderSet);
        system.debug('Value updateAccountList--'+updateAccountList);
        updateOrderList.addAll(updateOrderSet);
        updateAccountList.addAll(updateAccountSet);
        if(updateOrderList.size()>0)
            update updateOrderList;
        if(updateAccountList.size()>0)
            update updateAccountList;
    }
    */
}