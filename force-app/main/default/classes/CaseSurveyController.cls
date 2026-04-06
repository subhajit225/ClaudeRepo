public class CaseSurveyController {

    /* this drives the Survey in Public Case Close Email templates for the cases */
    public String cseID {get;set;}

 /*   public String getSurveyLink() {
        String Slink;
        if (cseID != null) {
            Case lcase = [Select Id,ContactId FROM Case where Id = :cseID limit 1];
            Contact dd = [Select Id,FirstName, Last_GetFeedback_Date__c FROM Contact where Id = :lcase.ContactId limit 1];
            Slink = '<a href="https://www.getfeedback.com/r/lOUXxVj0?CaseID='+cseID+'&ContactID='+dd.Id+'&ContactName='+dd.FirstName+'">Please click Here to submit Survey</a>';
        }
        return Slink;
    }
*/
    public String getContactName() {
        String Slink;
        if (cseID != null) {
            Case lcase = [Select Id,ContactId FROM Case where Id = :cseID limit 1];
            Contact dd = [Select Id,FirstName, Last_GetFeedback_Date__c FROM Contact where Id = :lcase.ContactId limit 1];
            Slink = dd.FirstName;
        }
        return Slink;
    }
    public String getContactId() {
        String Slink;
        if (cseID != null) {
            Case lcase = [Select Id,ContactId FROM Case where Id = :cseID limit 1];
            Contact dd = [Select Id,FirstName, Last_GetFeedback_Date__c FROM Contact where Id = :lcase.ContactId limit 1];
            Slink = dd.Id;
        }
        return Slink;
    }

}