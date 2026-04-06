public inherited sharing class MarketingFeedbackSurveyTriggerHelper {
    
    public void updateContactLastFeedbackDate( List<Marketing_GetFeedback_Survey__c> lstFeedback ) {
        List<Contact> lstContactToUpdate = new List<Contact>();

        for( Marketing_GetFeedback_Survey__c objMGFS : lstFeedback ) {
            if( objMGFS.Contact__c != null ) {
                lstContactToUpdate.add(
                    new Contact(Id=objMGFS.Contact__c, Last_Marketing_GetFeedBack_Date__c = System.Today()) 
                );
            }
        }

        if( !lstContactToUpdate.isEmpty() ) {
            update lstContactToUpdate;
        }
    }

}