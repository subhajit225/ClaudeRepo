public with sharing class AccountScreeningTriggerHelper {
    
    public static final String DENIED_PARTY_LIST ='Denied Party List';
    public static final String ORDER_STATUS_PENDING ='Pending';
    public static final String ORDER_STATUS_ORDER_ACCEPTED ='Order Accepted';
    public static final String ORDER_STATUS_ON_HOLD ='On Hold';
    
    public static void updateRelatedOpportunities(List<Account_Screening__c> newList, Map<id,Account_Screening__c>oldMap ){
        if (newList == Null) {
            return;
        }
        Set<Id> accountsWithOrdersToBeUpdated = new Set<Id>();
        for(Account_Screening__c ascr : newList){
            if(ascr.GTC_Screen_Status__c == DENIED_PARTY_LIST && ascr.GTC_Screen_Status__c != oldMap.get(ascr.Id).GTC_Screen_Status__c ){
               accountsWithOrdersToBeUpdated.add(ascr.Account__c); 
            }
        }
        List<string> orderStatusesForUpdate = new List<string>{ORDER_STATUS_PENDING,ORDER_STATUS_ORDER_ACCEPTED,ORDER_STATUS_ON_HOLD};
        List<Order> ordersForUpdate = new List<Order>();
            for(order order : [select id,Hold_Code__c from Order where  AccountId In :accountsWithOrdersToBeUpdated and Order_Status__c IN :orderStatusesForUpdate  ]){
               if(order.Hold_Code__c == null || !order.Hold_Code__c.contains(DENIED_PARTY_LIST))
                    order.Hold_Code__c= (order.Hold_Code__c != Null && order.Hold_Code__c != '')?order.Hold_Code__c+';'+ DENIED_PARTY_LIST:DENIED_PARTY_LIST;
               order.Order_Status__c ='On Hold';
               ordersForUpdate.add(order); 
            }
        if(ordersForUpdate.size()>0 ){
            Database.Update(ordersForUpdate,False);
        }
    }

    public static void doCalloutIfGTCPassedForFreeTrial(List<Account_Screening__c> newList, Map<id,Account_Screening__c>oldMap){
        set<Id> accountEligibleForGTCPass = new Set<Id>();
        for(Account_Screening__c ascr : newList){
        if((ascr.Screening_Action__c == 'Start' || ascr.Screening_Action__c == 'Resend')  && 
        ascr.Screening_Action_Status__c == 'Sent' && 
        ascr.GTC_Screen_Status_Message__c == 'Screening Complete' && ascr.GTC_Screen_Status_Message__c != oldMap.get(ascr.Id).GTC_Screen_Status_Message__c){
        accountEligibleForGTCPass.add(ascr.Account__c); 
        }
        }
        
        if(!accountEligibleForGTCPass.isEmpty()){
        Map<Id, RSC_Process__c> RSCProcessRecordMap = new Map<Id, RSC_Process__c>([Select id,AccountID__c from RSC_Process__c where AccountID__c IN : accountEligibleForGTCPass AND Free_trail__c = 'Free Trial' AND RSC_Status__c = 'Initiated']);
        if(!RSCProcessRecordMap.keyset().isEmpty())
        callProvisioningAPI(RSCProcessRecordMap.keyset());
        }
        }
        
        @future(callout=true)
        public static void callProvisioningAPI(Set<Id>  rscProcessIds)
        {   
            for(Id rscProcessId : rscProcessIds)
            LCC_ButtonsController.response_Wrapper response = LCC_ButtonsController.doCallout(rscProcessId);
        }

}