public class RelatedListStatusTrackerController {
    public Id caseId;
    public List<Status_Tracking__c> caseTrackerList{get;set;}
    public RelatedListStatusTrackerController(ApexPages.StandardController controller){
        caseId = (id) controller.getId();
        caseTrackerList = new List<Status_Tracking__c>();
        caseTrackerListAction();
    }
    
    public void caseTrackerListAction(){
        caseTrackerList = [SELECT id,Tracking__c, Miliseconds__c, Days__c, Hours__c, Minutes__c, Total_Time__c, Number_of_times_in_status__c FROM Status_Tracking__c where Case__c =: caseId];
    }    
}