@isTest public with sharing class MarketingFeedbackTriggerHandlerTest {
    @isTest static void setMarketingFeedbackSurveyLastReceivedDate(){
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 3, null);
        conList[0].AccountId = act.Id;
        conList[0].Primary_Customer_Mailing_Contact__c = TRUE;
        conList[1].AccountId = act.Id;
        conList[1].Primary_Customer_Mailing_Contact__c = TRUE;
        conList[2].AccountId = act.Id;
        insert conList;
        
        test.starttest();
        try{
            Marketing_GetFeedback_Survey__c objSurvey = new Marketing_GetFeedback_Survey__c();
            objSurvey.Account__c = act.Id;
            objSurvey.Contact__c = conList[0].Id;
            objSurvey.Name = 'Test Survey - 001';
            objSurvey.Area_of_interest_next__c = 'Security';
            insert objSurvey;
        }catch(Exception e){
            
        }

        test.stoptest();
        system.assert( [Select Last_Marketing_GetFeedBack_Date__c From Contact Where Id=:conList[0].Id LIMIT 1].Last_Marketing_GetFeedBack_Date__c == Date.today() );
    }
}