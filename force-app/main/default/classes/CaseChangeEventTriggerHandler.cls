/**
 * @description Used to handle the Platform Event's Trigger
 * @TestClass   CaseTriggerHandlerTest
 **/
public class CaseChangeEventTriggerHandler {
    /**
     * @description insert case comments
     * @param caseChangeRecords
     */
    public static void afterInsert(List<Case_Change_Event__e> caseChangeRecords){
        List<CaseComment> comments = new List<CaseComment>();
        Set<Id> usrIds = new Set<Id>();
        for (Case_Change_Event__e evt : caseChangeRecords) {
            if(evt.User_Id__c!=null){
                usrIds.add(evt.User_Id__c);
            }
        }
        Map<Id,User> userMap = new Map<ID,User>([SELECT Id, Name FROM User WHERE ID IN: usrIds]);
        for (Case_Change_Event__e evt : caseChangeRecords) {
            String userUrl = System.URL.getOrgDomainUrl().toExternalForm() + '/' + evt.User_Id__c;
            CaseComment cmt = new CaseComment();
            cmt.ParentId = evt.Case_Id__c;
            String msg = 'Case ' + evt.Case_Number__c + ' has been closed for over 7 days. Please create a new case in Salesforce. ';
            if(evt.Changed_Field_Name__c == 'Owner'){
                msg += '<br/><br/><ul> <li> Case Owner change requested by <a href="'+userUrl+'">'+ userMap.get(evt.User_Id__c)?.Name +'</a></li></ul>';
            }
            if(evt.Changed_Field_Name__c == 'Status'){
                msg += '<br/><br/><ul> <li> Status change requested by <a href="'+userUrl+'">'+ userMap.get(evt.User_Id__c)?.Name +'</a></li></ul>';
            }
            if(evt.Changed_Field_Name__c == 'Case Transfer'){
                msg += '<br/><br/><ul> <li> Case transfer requested by <a href="'+userUrl+'">'+ userMap.get(evt.User_Id__c)?.Name +'</a></li></ul>';
            }
            cmt.CommentBody = msg;
            comments.add(cmt);
        }
        if (!comments.isEmpty()) {
            insert comments;
        }
    }
}