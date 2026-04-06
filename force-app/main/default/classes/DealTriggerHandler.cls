public class DealTriggerHandler{
    
    public static void dealUpdatesonParent(List<Deal_Update__c> duList,map<id,Deal_Update__c> triggerRecords){
        List<Deal_update__c> dulistQueried =[select Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Account__c, Opportunity__c, Body__c, Type__c, Object_Type__c,createdby.firstname,createdby.lastname from Deal_Update__c where id in: duList];
        DealUpdateHelper.updateParent(dulistQueried,triggerRecords);
    }
    
}