/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   05-06-2020
* @Jira Ticket  :   CS21-183 - Configure and Implement Salesforce Surveys with PS Project
* @Description  :   Controller for PSProjectsSurveyComponent. The class is responsible for creating
                    Survey Invitation records for customers
* @TestClass    :   PSProjectsSurveyControllerTest.cls
*/
public class PSProjectsSurveyController {

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   05-06-2020
    * @Description  :   Validates if the current user has Create permission on Survey Invitation object or not.
                        If not, it throws error to the user else loads the page
    */
    @AuraEnabled
    public static Boolean isInvitationCreationAllowed() {
        return Schema.sObjectType.SurveyInvitation.isCreateable();
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   05-06-2020
    * @Description  :   Fetches data for the current PS Project record
    */
    @AuraEnabled
    public static PS_Project__c getPSProjectRecord(String psProjectId) {
        return [SELECT Id, Name, Account__c, Account__r.Name FROM PS_Project__c WHERE Id =: psProjectId];
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   05-06-2020
    * @Description  :   Fetches list fo contacts associated to the Account related to the PS Project
    */
    @AuraEnabled
    public static List<Contact> getContacts(String accountId) {
		return [SELECT Id, Name, Email, Last_Survey_Sent_Date_Time__c, AccountId
                FROM Contact
                WHERE AccountId =: accountId
                ORDER BY Name];
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   05-06-2020
    * @Description  :   Creates Survey Invitation records for the selected Contacts and Survey record
    */
    @AuraEnabled
    public static String sendSurveyInvitations(List<Contact> contactList, Survey selectedSurvey, String psProjectId) {
        Integer contactListSize = contactList.size();
        SurveyInvitation invitationObject;
        List<SurveyInvitation> invitationList = new List<SurveyInvitation>();
        String message = '';

        Domain surveyDomain = [SELECT Id, Domain FROM Domain WHERE HttpsOption = 'CommunityAlt'];

        for(Integer i = 0; i < contactListSize; i++) {
            invitationObject = new SurveyInvitation();
            invitationObject.SurveyId = selectedSurvey.Id;
            invitationObject.ParticipantId = contactList[i].Id;
            invitationObject.Contact__c = contactList[i].Id;
            invitationObject.CommunityId = '0DB6f000000XZQe';
            invitationObject.Account__c = contactList[i].AccountId;
            invitationObject.Name = contactList[i].Name + ' ' + System.now();
            invitationObject.OptionsAllowGuestUserResponse = true;
            invitationObject.OptionsAllowParticipantAccessTheirResponse = false;
            invitationObject.OptionsCollectAnonymousResponse = false;
            invitationObject.Participant_Email__c = contactList[i].Email;
            invitationObject.Domain__c = surveyDomain.Domain + '/';
            invitationObject.PS_Project__c = psProjectId;
            invitationObject.Survey_DeveloperName__c = selectedSurvey.DeveloperName;
            invitationList.add(invitationObject);
        }
        Database.SaveResult[] invitationsResults = Database.insert(invitationList, false);

        Set<Id> insertedInvitations = new Set<Id>();
        for(SurveyInvitation eachInvitation : invitationList) {
            if(eachInvitation.Id != null) {
                insertedInvitations.add(eachInvitation.Id);
            }
        }

        List<SurveyInvitation> invites = [SELECT Id, Contact__c, Contact__r.Name, Contact__r.Email
                                         FROM SurveyInvitation
                                         WHERE Id =: insertedInvitations];

        updateLastSurveySentDateOnContacts(invites);

        return getSaveResultsMessage(invitationsResults, invites);
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   05-06-2020
    * @Description  :   Generate success or error message
    */
    private static String getSaveResultsMessage(Database.SaveResult[] saveResults, List<SurveyInvitation> invites) {
        String message = '';

        for(SurveyInvitation eachInvitation : invites) {
            message = message + eachInvitation.Contact__r.Name + ' (' + eachInvitation.Contact__r.Email + ')\n';
        }

        message = !String.isBlank(message) ? 'Survey invitations sent successfully for :\n' + message + '\n' : message;

        for(Database.SaveResult eachResult : saveResults){
            if (!eachResult.isSuccess()) {
                for(Database.Error eachError : eachResult.getErrors()) {
                    message = message + 'The following error has occurred :\n';
                    message = message + eachError.getMessage();
                }
            }
        }

        return message;
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   05-06-2020
    * @Description  :   Update Last Survey Sent Date field on Contact after successful creation of Survey Invitation records
    */
    public static void updateLastSurveySentDateOnContacts(List<SurveyInvitation> invites) {
        List<Contact> contactListToBeUpdated = new List<Contact>();

        for(SurveyInvitation eachSurveyInvitation : invites) {
            contactListToBeUpdated.add(new Contact(Id = eachSurveyInvitation.Contact__c, Last_Survey_Sent_Date_Time__c = System.now()));
        }

        Database.update(contactListToBeUpdated, false);
    }
    
    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiThemeDisplayed();
        return theme;
    }
}