/**
* @author Sushant Arora
* @date 2024-01-31
* @description review accounts and send email alerts
* @TestClass - CS_CaseSpecialHandlingReviewBatchTest
*/
@SuppressWarnings('PMD.StdCyclomaticComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock')
public class CS_CaseSpecialHandlingReviewBatch implements Database.Batchable <SObject> , Schedulable {
    static EmailTemplate emailTemplate;
    /*Fetch Data from Custom Label name CSH_CCO_CS_ID */
    static final String CHIEF_CUSTOMER_OFFICER_ID = System.Label.CSH_CCO_CS_ID;
    /*Fetch Data from Custom Label name CS_MGMT_EMAIL_ADDRESSD */
    static final String CS_MGMT_EMAIL_ADDRESS = System.Label.CS_MGMT_EMAIL_ADDRESS;
    /*List to store Unique vp roles */
    static Set<String> vpRolesList = new Set <String>();
    /*Fetching templates data from EmailTemplate  */
    CS_CaseSpecialHandlingReviewBatchService service = new CS_CaseSpecialHandlingReviewBatchService();
    
    static {
        EmailTemplate[] templates = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Case_Special_Handling_Object_Review_Alert'
                                     LIMIT 1
                                    ];
        if (!templates.isEmpty()) {
            emailTemplate = templates[0];
        }
    }
    /*Fetching org-wide address*/
    static OrgWideEmailAddress[] orgWideAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress Where Address = 'donotreply@rubrik.com' LIMIT 1];
    
    
    private static final Integer MAX_SIZE_MESSAGE = 200;
    
    /**
    * @description execute CS_CaseSpecialHandlingReviewBatch
    * @param sc inserted by sytstem
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CS_CaseSpecialHandlingReviewBatch());
    }
    
    /**
    * @description Returns a query locator to retrieve Case_Special_Handling__c records that meet specific criteria.
    * @param bc The batch context.
    * @return Database.QueryLocator A query locator to retrieve records.
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, LastModifiedById, Valid_Until__c,Auto_Archive__c,Message__c,Account_Id__r.Name, Manual_Review_Requested_On__c, expirationDays__c, ' +
            'Account_Id__r.Account_SAM__c, Account_Id__r.Account_SAM__r.ManagerId, Account_Id__r.Account_SAM__r.Manager.ManagerId, ' +
            'LastModifiedBy.ManagerId, LastModifiedBy.Manager.ManagerId, ' +
            'CreatedById, CreatedBy.ManagerId, CreatedBy.Manager.ManagerId ' +
            'FROM Case_Special_Handling__c ' +
            'WHERE (Valid_Until__c != null OR Manual_Review_Requested_On__c != null) AND expirationDays__c > 0 AND Is_Archived__c = false'
        );
    }
    
    /**
    * @description Executes the batch process on the provided list of Case_Special_Handling__c records.
    * @param bc The batch context.
    * @param scope The list of Case_Special_Handling__c records to process.
    */ 
    public void execute(Database.BatchableContext bc, List <Case_Special_Handling__c> scope) {
        
        List <Messaging.SingleEmailMessage> emailsToSend = new List <Messaging.SingleEmailMessage> ();
        List <Case_Special_Handling__c> objectsToUpdate = new List <Case_Special_Handling__c> ();
        
        Map<Id, Id> caseToRecipientMap = service.getCaseToRecipientMap(scope);
       
        Map<Id, User> idToUser = new Map<Id, User>([SELECT Id, isActive, Name, UserRole.Name, Manager.Id, Manager.Name, Manager.isActive FROM User WHERE id IN: caseToRecipientMap.values()]);
        
        for (Case_Special_Handling__c caseObj: scope) {
            if (caseObj.Auto_Archive__c) {
                caseObj.Is_Archived__c = true;
                objectsToUpdate.add(caseObj);
            } else {
                User u= idToUser.get(caseToRecipientMap.get(caseObj.Id));
                Messaging.SingleEmailMessage email = service.createAlertEmail(caseObj, u);
                if (email != null) {
                    emailsToSend.add(email);
                }
            }
        }
        if (!objectsToUpdate.isEmpty()) {
            update objectsToUpdate;
        }
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    /**
    * @description Completes the batch process.
    * @param bc The batch context.
    */
    
    public void finish(Database.BatchableContext bc) {
        //Mandatory Implementation for Batchable Interface.
    }
 
 
    public class CS_CaseSpecialHandlingReviewBatchService {
        
        private Map<Id, Id> getCaseToRecipientMap(List <Case_Special_Handling__c> scope){
            Map<Id, Id> caseToRecipientMap = new Map<Id, Id>();

            Set<Id> usersWithCustomPermission = getUsersWithCustomPermission(scope);

            for (Case_Special_Handling__c caseObj: scope) {
                Id reviewAlertRecipient = getAccountManager(caseObj, usersWithCustomPermission.contains(caseObj.LastModifiedById));
                caseToRecipientMap.put(caseObj.Id, reviewAlertRecipient);
            }
            
            return caseToRecipientMap;
        }
        
    /**
     * @description Retrieves the appropriate Account Manager or related user based on the special handling conditions of a `Case_Special_Handling__c` record.
     * 
     * @param caseRecord The `Case_Special_Handling__c` record containing information about the case, such as the expiration days and associated account manager.
     * @param specialHandlingPermission A boolean flag indicating whether the user has special handling permissions.
     * 
     * @return Id The `Id` of the Account Manager or a related user based on the special handling logic, or null if no conditions are met.
     */
    private Id getAccountManager(Case_Special_Handling__c caseRecord, Boolean specialHandlingPermission) {
        if ((caseRecord.Valid_Until__c != null || caseRecord.Manual_Review_Requested_On__c != null) && caseRecord.expirationDays__c > 0) {
            if (caseRecord.Account_Id__r.Account_SAM__c != null) {
                if (caseRecord.expirationDays__c < 30) {
                    return caseRecord.Account_Id__r.Account_SAM__c;
                } else if (caseRecord.expirationDays__c < 90) {
                    return caseRecord.Account_Id__r.Account_SAM__r.ManagerId;
                } else {
                    return caseRecord.Account_Id__r.Account_SAM__r.Manager.ManagerId;
                }
            } else {
                if (specialHandlingPermission) {
                    if (caseRecord.expirationDays__c < 30) {
                        return caseRecord.LastModifiedById;
                    } else if (caseRecord.expirationDays__c < 90) {
                        return caseRecord.LastModifiedBy.ManagerId;
                    } else {
                        return caseRecord.LastModifiedBy.Manager.ManagerId;
                    }
                } else {
                    if (caseRecord.expirationDays__c < 30) {
                        return caseRecord.CreatedById;
                    } else if (caseRecord.expirationDays__c < 90) {
                        return caseRecord.CreatedBy.ManagerId;
                    } else {
                        return caseRecord.CreatedBy.Manager.ManagerId;
                    }
                }
            }
        }
        return null;
    }
        
        /**
         * @description Retrieves a set of user IDs that have been assigned a specific custom permission.
         *
         * @param userIds A set of user IDs to check for the custom permission.
         * @param customPermissionName The developer name of the custom permission to check for.
         * 
         * @return Set<Id> A set of user IDs that have the specified custom permission, or an empty set if no users have the permission.
         */
        public Set<Id> getUsersWithCustomPermission(List <Case_Special_Handling__c> scope) {
            Set<Id> lastModifierIds = new Set<Id>();
            for (Case_Special_Handling__c caseObj: scope) {
                lastModifierIds.add(caseObj.LastModifiedById);
            }
            Set<Id> permissionSetIds = new Set<Id>();
            for (SetupEntityAccess access : [
                SELECT ParentId 
                FROM SetupEntityAccess 
                WHERE SetupEntityId IN (
                    SELECT Id 
                    FROM CustomPermission 
                    WHERE DeveloperName = 'Case_Special_Handling_Object_Edit_Permission'
                )
            ]) {
                permissionSetIds.add(access.ParentId);
            }
            
            if (!permissionSetIds.isEmpty()) {
                Set<Id> userIdsWithPermission = new Set<Id>();
                for (PermissionSetAssignment psa : [
                    SELECT AssigneeId 
                    FROM PermissionSetAssignment 
                    WHERE PermissionSetId IN :permissionSetIds
                    AND AssigneeId IN :lastModifierIds
                ]) {
                    userIdsWithPermission.add(psa.AssigneeId);
                }
                return userIdsWithPermission;
            }
            return new Set<Id>();
        }
        /**
    * @description Creates an alert email for a Case_Special_Handling__c record and returns it.
    * @param caseObj The Case_Special_Handling__c record for which the alert email is created.
    * @param idToUser A map of user IDs to corresponding User objects.
    * @return Messaging.SingleEmailMessage The alert email message, or null if conditions are not met.
    */
    @TestVisible
        public Messaging.SingleEmailMessage createAlertEmail(Case_Special_Handling__c caseObj, User u) {
            if (emailTemplate == null || u == null || orgWideAddress.IsEmpty()) {
                return null;
            }
            Boolean sendToCSMgmt = false;
            User recipeint;
            if (u.isActive) {
                if (u.Id == CHIEF_CUSTOMER_OFFICER_ID) {
                    sendToCSMgmt = true;
                }
                recipeint = new User(Id = u.Id, FirstName = u.Name);
            } else if (u.Manager <> null && u.Manager.IsActive) {
                if (u.ManagerId == CHIEF_CUSTOMER_OFFICER_ID) {
                    sendToCSMgmt = true;
                }
                recipeint = new User(Id = u.ManagerId, FirstName = u.Manager.Name);
            } else {
                return null;
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            if (sendToCSMgmt) {
                email.setToAddresses(new List <String> {
                    CS_MGMT_EMAIL_ADDRESS
                        });
            } else {
                email.setTargetObjectId(recipeint.Id);
            }
            email.setSaveAsActivity(false);
            email.setSubject(emailTemplate.Subject);
            email.setOrgWideEmailAddressId(orgWideAddress[0].Id);
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String message = String.isBlank(caseObj.Message__c) ? '' : caseObj.Message__c;
            message = message.length() > MAX_SIZE_MESSAGE ? message.substring(0, MAX_SIZE_MESSAGE) + '...' : message;
            Map <String, String> templateMergeFields = new Map <String, String> {
                'AccountName' => caseObj.Account_Id__r.Name,
                    'RecipientName' => sendToCSMgmt ? 'Members' : recipeint.FirstName,
                        'AccountId' => caseObj.Account_Id__c,
                        'AccountLink' => baseUrl + '/' + caseObj.Account_Id__c,
                        'Link' => baseUrl + '/' + caseObj.Id,
                        'Id' => caseObj.Id,
                        'Message' => message
                        };
                            String mergedBody = emailTemplate.HtmlValue;
            for (String field: templateMergeFields.keyset()) {
                mergedBody = mergedBody.replace('{!' + field + '}', templateMergeFields.get(field));
            }
            email.setHtmlBody(mergedBody);
            return email;
        }
    }
    
}