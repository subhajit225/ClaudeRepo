/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description 
 * This class is responsible for sending email notifications for Risk Profile-related events.
 * It handles different event types such as creation, validation, status changes, and closures
 * to ensure appropriate stakeholders are notified.
 *
 * @TestClass - CS_RiskMitigationNotificationService_Test
 */
public class CS_RiskMitigationNotificationService {

    /**
     * Enum representing the types of events for Risk Profile notifications.
     */
    public enum EventType {
            Created,
            Validated,
            Invalidated,
            StatusChange,
            ActionOwnerChange,
            Closure
        }
    private List<Risk_Profile__c> riskProfiles;
    private String emailTemplateName;
    private List<Id> recepientIds = new List<Id>();
    private EventType eventType;
    Map<Id,Set<Id>> riskProfileToWatchers;
    List<Id> governanceOwners = new List<Id>();
    
    /**
     * Constructor to initialize the service with the provided Risk Profiles.
     * @param riskProfiles Set of Risk Profile IDs to process.
     */
    public CS_RiskMitigationNotificationService(Set<Id> riskProfiles){
        this.riskProfiles = [SELECT Id,CreatedById,OwnerId,Action_Owner__c,Risk_Origin__c,Opportunity__r.OwnerId,Governance_Owner__c FROM Risk_Profile__c WHERE Id IN :riskProfiles];
        this.loadParticipants();
    }

    /**
     * Loads governance owners and watchers for the Risk Profiles.
     */
    private void loadParticipants(){
        riskProfileToWatchers = CS_RiskMitigationUtility.getWatchers(riskProfiles);
        governanceOwners = CS_RiskMitigationUtility.getGovernanceOwners();
    }
    
    /**
     * Sets the event type and determines the email template to use based on the event.
     * @param eventType The event type triggering the notification.
     * @return CS_RiskMitigationNotificationService The current instance for chaining.
     */
    public CS_RiskMitigationNotificationService onEvent(EventType eventType){
        this.eventType = eventType;
        switch on this.eventType {
            when Created {
                this.emailTemplateName = 'Risk_Profile_Creation_Notification_RRM';
            }
            when StatusChange {
                this.emailTemplateName = 'Risk_Profile_Status_Updates_RRM';
            }
            when Closure {
                this.emailTemplateName = 'Risk_Profile_Status_Closure_RRM';
            }
            when Validated {
                this.emailTemplateName = 'Risk_Profile_Validation_Notification_RRM';
            }
            when Invalidated {
                this.emailTemplateName = 'Risk_Profile_Invalid_Notification_RRM';
            }
            when ActionOwnerChange {
                this.emailTemplateName = 'Risk_Profile_Action_Owner_Change_RRM';
            }
        }
        return this;
    }

    /**
     * Sends email notifications based on the Risk Profiles and event type.
     */
    public void notifyByEmail() {
        sendEmailToUsersAndQueue(this.emailTemplateName, this.riskProfiles);
    }
    
    /**
     * Retrieves the creators of the given Risk Profiles.
     * @param riskProfiles List of Risk Profiles.
     * @return List<Id> List of creator user IDs.
     */
   /* private List<Id> getCreator(Risk_Profile__c[] riskProfiles) {
        Set<Id> creatorIds = new Set<Id>();
        for (Risk_Profile__c profile : riskProfiles) {
            creatorIds.add(profile.CreatedById);
        }
        return new List<Id>(creatorIds);
    }
    */
    /**
     * Retrieves the list of email addresses to be included as recipients.
     * @param riskProfile The Risk Profile to process.
     * @return List<String> List of email addresses.
     */
    private List<String> getToAddresses(Risk_Profile__c riskProfile){
        Set<String> toAddress = new Set<String>();
        switch on this.eventType {
            when Created, ActionOwnerChange {
                if(String.isNotBlank(System.Label.Retention_Team_Email)){
                    toAddress.add(System.Label.Retention_Team_Email);
                }
                if(String.isNotBlank(System.Label.Retention_Team_Slack_Email)){
                    toAddress.add(System.Label.Retention_Team_Slack_Email);
                }                
            }
            when StatusChange {
                if(String.isNotBlank(System.Label.Retention_Team_Slack_Email)){
                    toAddress.add(System.Label.Retention_Team_Slack_Email);
                } 
            }
        }        
        return new List<String>(toAddress);        
    }

    /**
     * Retrieves the recipients for the given Risk Profile based on the event type.
     * @param riskProfile The Risk Profile to process.
     * @return List<Id> List of recipient user IDs.
     */
    private List<Id> getRecepeints(Risk_Profile__c riskProfile){
        Set<Id> recepientIds = new Set<Id>();
        switch on this.eventType {
            when Created {
                recepientIds.add(riskProfile.createdById);
                recepientIds.add(riskProfile.OwnerId);
                //recepientIds.add(riskProfile.Governance_Owner__c);
                //recepientIds.addAll(this.governanceOwners);
                if(riskProfile.Risk_Origin__c == 'Opportunity'){
                    recepientIds.add(riskProfile.Opportunity__r.OwnerId);
                }
                //recepientIds.addAll(this.governanceOwners);
            }
            when StatusChange, Closure, Validated {
                recepientIds.add(riskProfile.createdById);
                recepientIds.add(riskProfile.OwnerId);
                recepientIds.add(riskProfile.Action_Owner__c);
                if(this.riskProfileToWatchers.containsKey(riskProfile.Id)){
                    recepientIds.addAll(this.riskProfileToWatchers.get(riskProfile.Id));
                }                
            }
            when Invalidated {
                recepientIds.add(riskProfile.createdById);
                recepientIds.add(riskProfile.OwnerId);
            }
            when ActionOwnerChange {
                recepientIds.add(riskProfile.Action_Owner__c);
            }
        }
        recepientIds.remove(null);

        List<Id> filteredRecipientIds = new List<Id>();
        for(Id recipientId : recepientIds){
            if(Risk_Profile_Assignment__c.getInstance(recipientId)?.Send_Notifications__c != false){
                filteredRecipientIds.add(recipientId);
            }
        }
        return filteredRecipientIds;        
    }

    /**
     * @description Sends email notifications using the provided template and Risk Profiles.
     * @param templateName The developer name of the email template.
     * @param riskProfiles List of Risk Profiles to notify about.
     */
    private void sendEmailToUsersAndQueue(String templateName, List<Risk_Profile__c> riskProfiles) {
        EmailTemplate[] emailTemplates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
        if(emailTemplates.isEmpty()) {
            return;
        }
        EmailTemplate emailTemplate = emailTemplates[0];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();        
        
        for (Risk_Profile__c riskProfile : riskProfiles) {
            List<Id> recepientIds = getRecepeints(riskProfile);            
            List<String> toAddresses = getToAddresses(riskProfile);

            for(String recipentId: recepientIds){
                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                 mail.setTargetObjectId(recipentId);
                 mail.setTemplateId(emailTemplate.Id);
                 mail.setSaveAsActivity(false);
                 mail.setWhatId(riskProfile.Id);
                 if(String.isNotBlank(System.Label.NoReplyAddressID)){
                    mail.setOrgWideEmailAddressId(System.Label.NoReplyAddressID);
                 }
                 mail.setUseSignature(false);
                 emails.add(mail);
            }
            if(!(recepientIds.isEmpty() || toAddresses.isEmpty())){
                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                 mail.setTargetObjectId(recepientIds[0]);
                 mail.setTreatTargetObjectAsRecipient(false);
                 mail.setToAddresses(toAddresses);                 
                 mail.setTemplateId(emailTemplate.Id);
                 mail.setSaveAsActivity(false);
                 mail.setWhatId(riskProfile.Id);
                 if(String.isNotBlank(System.Label.NoReplyAddressID)){
                    mail.setOrgWideEmailAddressId(System.Label.NoReplyAddressID);
                 }
                 emails.add(mail);
                 mail.setUseSignature(false);
            }
        }
        try{
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);             
            }
        } catch(Exception e){
            insert as system new Error_Logs__c(Object__c = 'Risk_Profile__c',
                Error_Message__c = e.getMessage() + e.getStackTraceString(),
                Class__c = 'CS_RiskMitigationNotificationService',
                Method__c = 'sendEmailToUsersAndQueue',
                Type__c = 'SFDC',
                Success__c = false);
        }
       
    }
}