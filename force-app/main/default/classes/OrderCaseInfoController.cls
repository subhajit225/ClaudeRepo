public class OrderCaseInfoController {
    public String orderId {get;set;}
    public Id caseID;
    public Case cs;
   
    public Case getCaseInfo(){
        if(orderId!=null){
            caseID = [SELECT Case_Id__c FROM Order WHERE Id =: orderId].Case_Id__c;
            cs = [SELECT Contact.Name,ContactPhone,Contact.Email,Cluster_Tag__c,Priority,Software_Version__c,Origin,Contact_method__c,Problem_Type__c,Owner.Name,Current_Status__c,Subject,Description,Cluster__r.Name FROM Case WHERE Id =: caseID];
        }
        return cs;
    }
}