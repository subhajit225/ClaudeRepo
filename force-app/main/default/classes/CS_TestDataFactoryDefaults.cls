/******************************************************************************
 * @description       : This Class has all the default values for CS (Customer Support) related test data creation sObject records
 * @author            : 
 * @last modified on  : 11-13-2025
 * @last modified by  : 
 * Modifications Log
 * Ver   Date          Author        Modification
 *  
 ******************************************************************************/
public with sharing class CS_TestDataFactoryDefaults {

    // Account_Historical_View__b - Big Object (required: Account__c)
    public static final Map<String, Object> mapAccountHistoricalViewCommonFields = new Map<String, Object>{
        'Account__c' => null, // Will be set dynamically
        'FISCAL_YEAR__c' => '2025',
        'START_DATE__c' => System.now(),
        'END_DATE__c' => System.now().addDays(365)
    };

    // Account_Score__b - Big Object (required: Account__c)
    public static final Map<String, Object> mapAccountScoreCommonFields = new Map<String, Object>{
        'Account__c' => null, // Will be set dynamically
        'CX_Score__c' => 85.5,
        'Product_Score__c' => 90.0,
        'OnBoarding_Score__c' => 88.0,
        'FIS_QTR_ID__c' => 'Q1-2025'
    };

    // AccountAuditLog__c (no required fields - auto-number name)
    public static final Map<String, Object> mapAccountAuditLogCommonFields = new Map<String, Object>{
        'EditedField__c' => 'Enforce Admin Panel',
        'NewValue__c' => true,
        'User__c' => null // Will be set dynamically
    };

    // Aha_Idea_Link__c (required: Aha_Ideas__c - Master-Detail)
    public static final Map<String, Object> mapAhaIdeaLinkCommonFields = new Map<String, Object>{
        'Aha_Ideas__c' => null, // Will be set dynamically
        'Case_Number__c' => null,
        'Opportunity_Name__c' => null
    };
    
    // Aha_Ideas__c (required: Name)
    public static final Map<String, Object> mapAhaIdeasCommonFields = new Map<String, Object>{
        'Name' => 'Test Aha Idea',
        'Aha_Unique_ID__c' => 'AHA-TEST-001',
        'Aha_Idea_Number__c' => 'IDEA-001',
        'Idea_Description__c' => 'Test idea description for automated testing'
    };

    // Assigned_Support_Engineer__c (no required fields - auto-number name)
    public static final Map<String, Object> mapAssignedSupportEngineerCommonFields = new Map<String, Object>{
        'User__c' => null, // Will be set dynamically
        'Case__c' => null,
        'Assignment_Date__c' => System.today()
    };

    // Assist_Request__c (no required fields - auto-number name)
    public static final Map<String, Object> mapAssistRequestCommonFields = new Map<String, Object>{
        'Status__c' => 'Open',
        'Priority__c' => 'Medium',
        'Request_Type__c' => 'Technical Assistance'
    };

    // Case (required: none for standard Case, but common fields needed)
    public static final Map<String, Object> mapCaseCommonFields = new Map<String, Object>{
        'Subject' => 'Test Case Subject',
        'Status' => 'New',
        'Priority' => 'Medium',
        'Origin' => 'Internal',
        'Type' => 'Software',
        'AccountId' => null, // Will be set dynamically
        'ContactId' => null
    };

    // Case_Audit__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCaseAuditCommonFields = new Map<String, Object>{
        'Case__c' => null, // Will be set dynamically
        'Action_Taken__c' => 'Case Created',
        'Audit_Date__c' => System.now()
    };

    // Case_History_Tracking__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCaseHistoryTrackingCommonFields = new Map<String, Object>{
        'Case__c' => null, // Will be set dynamically
        'Field_Changed__c' => 'Status',
        'Old_Value__c' => 'New',
        'New_Value__c' => 'In Progress'
    };

    // Case_Notification_Preference__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCaseNotificationPreferenceCommonFields = new Map<String, Object>{
        'User__c' => null, // Will be set dynamically
        'Email_Notifications__c' => true,
        'SMS_Notifications__c' => false
    };

    // Case_Special_Handling__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCaseSpecialHandlingCommonFields = new Map<String, Object>{
        'Case__c' => null, // Will be set dynamically
        'Special_Instructions__c' => 'Handle with priority',
        'Handling_Type__c' => 'Escalated'
    };

    // Case_Summary_by_Project_Genius_Feedback__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCaseSummaryByProjectGeniusFeedbackCommonFields = new Map<String, Object>{
        'Case__c' => null, // Will be set dynamically
        'Summary__c' => 'AI-generated case summary',
        'Confidence_Score__c' => 95.5
    };

    // Catalog__c (auto-number name)
    public static final Map<String, Object> mapCatalogCommonFields = new Map<String, Object>{
        'Description__c' => 'Test catalog for automated testing',
        'Status__c' => 'Active'
    };

    // Checklist__c (required: Name)
    public static final Map<String, Object> mapChecklistCommonFields = new Map<String, Object>{
        'Name' => 'Test Checklist',
        'Description__c' => 'Test checklist for automated testing',
        'Status__c' => 'Active'
    };

    // Cluster__c (required: Name)
    public static final Map<String, Object> mapClusterCommonFields = new Map<String, Object>{
        'Name' => 'Test Cluster',
        'Cluster_ID__c' => 'CLUSTER-001',
        'Status__c' => 'Active',
        'Version__c' => '1.0.0'
    };

    // Cluster_Issue__c (no required fields - auto-number name)
    public static final Map<String, Object> mapClusterIssueCommonFields = new Map<String, Object>{
        'Cluster__c' => null, // Will be set dynamically
        'Issue_Type__c' => 'Performance',
        'Severity__c' => 'Medium',
        'Status__c' => 'Open'
    };

    // Cluster_registration__c (no required fields - auto-number name)
    public static final Map<String, Object> mapClusterRegistrationCommonFields = new Map<String, Object>{
        'Cluster__c' => null, // Will be set dynamically
        'Registration_Date__c' => System.today(),
        'Status__c' => 'Registered'
    };

    // ClusterAttribute__b - Big Object (no required fields)
    public static final Map<String, Object> mapClusterAttributeCommonFields = new Map<String, Object>{
        'Cluster_ID__c' => 'CLUSTER-001',
        'Attribute_Name__c' => 'CPU_Usage',
        'Attribute_Value__c' => '75.5'
    };

    // Community_Feed__c (auto-number name)
    public static final Map<String, Object> mapCommunityFeedCommonFields = new Map<String, Object>{
        'Content__c' => 'Test community feed content',
        'Status__c' => 'Published',
        'Author__c' => null // Will be set dynamically
    };

    // CS_Order__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCSOrderCommonFields = new Map<String, Object>{
        'Account__c' => null, // Will be set dynamically
        'Status__c' => 'Draft',
        'Order_Date__c' => System.today()
    };

    // Customer_Registration_Request__c (no required fields - auto-number name)
    public static final Map<String, Object> mapCustomerRegistrationRequestCommonFields = new Map<String, Object>{
        'Account__c' => null, // Will be set dynamically
        'Status__c' => 'Pending',
        'Request_Date__c' => System.today()
    };

    // Customer_Subscription__c (auto-number name)
    public static final Map<String, Object> mapCustomerSubscriptionCommonFields = new Map<String, Object>{
        'Account__c' => null, // Will be set dynamically
        'Status__c' => 'Active',
        'Start_Date__c' => System.today(),
        'End_Date__c' => System.today().addDays(365)
    };

    // DomainsUpdate__c (no required fields - auto-number name)
    public static final Map<String, Object> mapDomainsUpdateCommonFields = new Map<String, Object>{
        'Domain_Name__c' => 'test.example.com',
        'Update_Type__c' => 'Configuration',
        'Status__c' => 'Completed'
    };

    // Download_History__c (no required fields - auto-number name)
    public static final Map<String, Object> mapDownloadHistoryCommonFields = new Map<String, Object>{
        'User__c' => null, // Will be set dynamically
        'File_Name__c' => 'test-file.zip',
        'Download_Date__c' => System.now()
    };

    // Escalation__c (auto-number name)
    public static final Map<String, Object> mapEscalationCommonFields = new Map<String, Object>{
        'Case__c' => null, // Will be set dynamically
        'Escalation_Reason__c' => 'Customer Request',
        'Status__c' => 'Open',
        'Priority__c' => 'High'
    };

    // Escalation_Communication__c (no required fields - auto-number name)
    public static final Map<String, Object> mapEscalationCommunicationCommonFields = new Map<String, Object>{
        'Escalation__c' => null, // Will be set dynamically
        'Communication_Type__c' => 'Email',
        'Subject__c' => 'Escalation Update',
        'Body__c' => 'Test escalation communication'
    };

    // Escalation_Contact__c (no required fields - auto-number name)
    public static final Map<String, Object> mapEscalationContactCommonFields = new Map<String, Object>{
        'Escalation__c' => null, // Will be set dynamically
        'Contact__c' => null, // Will be set dynamically
        'Role__c' => 'Primary Contact'
    };

    // Escalation_Management__c (no required fields - auto-number name)
    public static final Map<String, Object> mapEscalationManagementCommonFields = new Map<String, Object>{
        'Escalation__c' => null, // Will be set dynamically
        'Manager__c' => null, // Will be set dynamically
        'Assignment_Date__c' => System.today()
    };

    // Escalation_Request__c (no required fields - auto-number name)
    public static final Map<String, Object> mapEscalationRequestCommonFields = new Map<String, Object>{
        'Case__c' => null, // Will be set dynamically
        'Requested_By__c' => null, // Will be set dynamically
        'Request_Reason__c' => 'Customer Dissatisfaction',
        'Status__c' => 'Pending'
    };

    // Forum_Info__c (required: Name)
    public static final Map<String, Object> mapForumInfoCommonFields = new Map<String, Object>{
        'Name' => 'Test Forum',
        'Description__c' => 'Test forum for automated testing',
        'Status__c' => 'Active'
    };

    // GetFeedback_Survey_Response__c (no required fields - auto-number name)
    public static final Map<String, Object> mapGetFeedbackSurveyResponseCommonFields = new Map<String, Object>{
        'Survey_Name__c' => 'Customer Satisfaction Survey',
        'Response_Date__c' => System.today(),
        'Score__c' => 4.5
    };

    // Heartbeat_Server_Log__c (no required fields - auto-number name)
    public static final Map<String, Object> mapHeartbeatServerLogCommonFields = new Map<String, Object>{
        'Server_Name__c' => 'TEST-SERVER-01',
        'Status__c' => 'Online',
        'Last_Heartbeat__c' => System.now()
    };

    // How_To__kav (Knowledge Article - required: Title, UrlName)
    public static final Map<String, Object> mapHowToCommonFields = new Map<String, Object>{
        'Title' => 'Test How-To Article',
        'UrlName' => 'Test-How-To-Article-' + String.valueOf(Math.random()).substring(2, 8),
        'Summary' => 'Test how-to article summary',
        'Language' => 'en_US'
    };

    // Idea (Standard Salesforce object - required: Title)
    public static final Map<String, Object> mapIdeaCommonFields = new Map<String, Object>{
        'Title' => 'Test Idea',
        'Body' => 'Test idea description for automated testing',
        'Status' => 'New'
    };

    // Idea_Exception__c (no required fields - auto-number name)
    public static final Map<String, Object> mapIdeaExceptionCommonFields = new Map<String, Object>{
        'Idea__c' => null, // Will be set dynamically
        'Exception_Type__c' => 'Validation Error',
        'Exception_Message__c' => 'Test exception message'
    };

    // JIRA_Issue__c (no required fields - auto-number name)
    public static final Map<String, Object> mapJIRAIssueCommonFields = new Map<String, Object>{
        'JIRA_Key__c' => 'TEST-001',
        'Issue_Type__c' => 'Bug',
        'Status__c' => 'Open',
        'Priority__c' => 'Medium'
    };

    // Lessons_Learned__c (required: Name)
    public static final Map<String, Object> mapLessonsLearnedCommonFields = new Map<String, Object>{
        'Name' => 'Test Lesson Learned',
        'Description__c' => 'Test lesson learned for automated testing',
        'Category__c' => 'Technical'
    };

    // LinkedArticle (Standard Salesforce object - no required fields)
    public static final Map<String, Object> mapLinkedArticleCommonFields = new Map<String, Object>{
        'KnowledgeArticleId' => null, // Will be set dynamically
        'LinkedEntityId' => null // Will be set dynamically
    };

    // Metadata_Request__c (no required fields - auto-number name)
    public static final Map<String, Object> mapMetadataRequestCommonFields = new Map<String, Object>{
        'Request_Type__c' => 'Field Update',
        'Status__c' => 'Pending',
        'Requested_Date__c' => System.today()
    };

    // Note__c (required: Name)
    public static final Map<String, Object> mapNoteCommonFields = new Map<String, Object>{
        'Name' => 'Test Note',
        'Content__c' => 'Test note content for automated testing',
        'Type__c' => 'General'
    };

    // Playbook__c (required: Name)
    public static final Map<String, Object> mapPlaybookCommonFields = new Map<String, Object>{
        'Name' => 'Test Playbook',
        'Description__c' => 'Test playbook for automated testing',
        'Status__c' => 'Active'
    };

    // Playbook_Checklist__c (no required fields - auto-number name)
    public static final Map<String, Object> mapPlaybookChecklistCommonFields = new Map<String, Object>{
        'Playbook__c' => null, // Will be set dynamically
        'Task_Name__c' => 'Test Checklist Item',
        'Status__c' => 'Pending'
    };

    // Playbook_Sub_Task__c (no required fields - auto-number name)
    public static final Map<String, Object> mapPlaybookSubTaskCommonFields = new Map<String, Object>{
        'Playbook__c' => null, // Will be set dynamically
        'Task_Name__c' => 'Test Sub Task',
        'Status__c' => 'Not Started'
    };

    // Playbook_Template__c (required: Name)
    public static final Map<String, Object> mapPlaybookTemplateCommonFields = new Map<String, Object>{
        'Name' => 'Test Playbook Template',
        'Description__c' => 'Test playbook template for automated testing',
        'Category__c' => 'Support'
    };

    // Portal_News__c (required: Name)
    public static final Map<String, Object> mapPortalNewsCommonFields = new Map<String, Object>{
        'Name' => 'Test Portal News',
        'Content__c' => 'Test portal news content',
        'Status__c' => 'Published',
        'Publish_Date__c' => System.today()
    };

    // PushTopic (Standard Salesforce object - required: Name, Query, ApiVersion)
    public static final Map<String, Object> mapPushTopicCommonFields = new Map<String, Object>{
        'Name' => 'TestPushTopic',
        'Query' => 'SELECT Id, Name FROM Account',
        'ApiVersion' => 64.0,
        'IsActive' => true
    };

    // Release_Software__c (required: Name)
    public static final Map<String, Object> mapReleaseSoftwareCommonFields = new Map<String, Object>{
        'Name' => 'Test Release Software',
        'Version__c' => '1.0.0',
        'Release_Date__c' => System.today(),
        'Status__c' => 'Released'
    };

    // Release_Version__c (required: Name)
    public static final Map<String, Object> mapReleaseVersionCommonFields = new Map<String, Object>{
        'Name' => 'Test Release Version',
        'Version_Number__c' => '1.0.0',
        'Release_Date__c' => System.today(),
        'Status__c' => 'Active'
    };

    // Releases__c (required: Name)
    public static final Map<String, Object> mapReleasesCommonFields = new Map<String, Object>{
        'Name' => 'Test Release',
        'Release_Date__c' => System.today(),
        'Version__c' => '1.0.0',
        'Status__c' => 'Released'
    };

    // Risk_Profile__c (required: Name)
    public static final Map<String, Object> mapRiskProfileCommonFields = new Map<String, Object>{
        'Name' => 'Test Risk Profile',
        'Account__c' => null, // Will be set dynamically
        'Risk_Level__c' => 'Medium',
        'Assessment_Date__c' => System.today()
    };

    // Risk_Profile_PDM_Feature__c (no required fields - auto-number name)
    public static final Map<String, Object> mapRiskProfilePDMFeatureCommonFields = new Map<String, Object>{
        'Risk_Profile__c' => null, // Will be set dynamically
        'Feature_Name__c' => 'Test PDM Feature',
        'Status__c' => 'Active'
    };

    // Risk_Profile_Watcher__c (no required fields - auto-number name)
    public static final Map<String, Object> mapRiskProfileWatcherCommonFields = new Map<String, Object>{
        'Risk_Profile__c' => null, // Will be set dynamically
        'User__c' => null, // Will be set dynamically
        'Watch_Date__c' => System.today()
    };

    // Rkcli_User_Log__c (no required fields - auto-number name)
    public static final Map<String, Object> mapRkcliUserLogCommonFields = new Map<String, Object>{
        'User__c' => null, // Will be set dynamically
        'Command__c' => 'test-command',
        'Execution_Date__c' => System.now(),
        'Status__c' => 'Success'
    };

    // RSC_Migration_Tasks__c (no required fields - auto-number name)
    public static final Map<String, Object> mapRSCMigrationTasksCommonFields = new Map<String, Object>{
        'Task_Name__c' => 'Test Migration Task',
        'Status__c' => 'Pending',
        'Priority__c' => 'Medium',
        'Due_Date__c' => System.today().addDays(7)
    };

    // Solution (Standard Salesforce object - required: SolutionName)
    public static final Map<String, Object> mapSolutionCommonFields = new Map<String, Object>{
        'SolutionName' => 'Test Solution',
        'SolutionNote' => 'Test solution description for automated testing',
        'Status' => 'Draft'
    };

    // Status_Tracking__c (no required fields - auto-number name)
    public static final Map<String, Object> mapStatusTrackingCommonFields = new Map<String, Object>{
        'Record_Id__c' => null, // Will be set dynamically
        'Status__c' => 'In Progress',
        'Last_Updated__c' => System.now()
    };

    // Sub_Task__c (no required fields - auto-number name)
    public static final Map<String, Object> mapSubTaskCommonFields = new Map<String, Object>{
        'Parent_Task__c' => null, // Will be set dynamically
        'Task_Name__c' => 'Test Sub Task',
        'Status__c' => 'Not Started',
        'Due_Date__c' => System.today().addDays(7)
    };

    // Success_Plan__c (required: Name)
    public static final Map<String, Object> mapSuccessPlanCommonFields = new Map<String, Object>{
        'Name' => 'Test Success Plan',
        'Account__c' => null, // Will be set dynamically
        'Status__c' => 'Active',
        'Start_Date__c' => System.today(),
        'End_Date__c' => System.today().addDays(365)
    };

    // Tasks__c (auto-number name)
    public static final Map<String, Object> mapTasksCommonFields = new Map<String, Object>{
        'Description__c' => 'Test task description',
        'Status__c' => 'Not Started',
        'Priority__c' => 'Medium',
        'Due_Date__c' => System.today().addDays(7)
    };

    // User_History__c (no required fields - auto-number name)
    public static final Map<String, Object> mapUserHistoryCommonFields = new Map<String, Object>{
        'User__c' => null, // Will be set dynamically
        'Action__c' => 'Login',
        'Action_Date__c' => System.now()
    };

    // WL_Domain__c (required: Name)
    public static final Map<String, Object> mapWLDomainCommonFields = new Map<String, Object>{
        'Name' => 'test.example.com',
        'Domain_Type__c' => 'Whitelist',
        'Status__c' => 'Active'
    };

    /**
     * @description Get default fields for a specific sObject type
     * @param sObjectType The API name of the sObject
     * @return Map<String, Object> Default field values for the sObject
     */
    public static Map<String, Object> getDefaultFields(String sObjectType) {

        if (String.isBlank(sObjectType)) {
            return new Map<String, Object>();
        }

        switch on sObjectType.toLowerCase() {
            when 'account_historical_view__b' { return mapAccountHistoricalViewCommonFields; }
            when 'account_score__b' { return mapAccountScoreCommonFields; }
            when 'accountauditlog__c' { return mapAccountAuditLogCommonFields; }
            when 'aha_idea_link__c' { return mapAhaIdeaLinkCommonFields; }
            when 'aha_ideas__c' { return mapAhaIdeasCommonFields; }
            when 'assigned_support_engineer__c' { return mapAssignedSupportEngineerCommonFields; }
            when 'assist_request__c' { return mapAssistRequestCommonFields; }
            when 'case' { return mapCaseCommonFields; }
            when 'case_audit__c' { return mapCaseAuditCommonFields; }
            when 'case_history_tracking__c' { return mapCaseHistoryTrackingCommonFields; }
            when 'case_notification_preference__c' { return mapCaseNotificationPreferenceCommonFields; }
            when 'case_special_handling__c' { return mapCaseSpecialHandlingCommonFields; }
            when 'case_summary_by_project_genius_feedback__c' { return mapCaseSummaryByProjectGeniusFeedbackCommonFields; }
            when 'catalog__c' { return mapCatalogCommonFields; }
            when 'checklist__c' { return mapChecklistCommonFields; }
            when 'cluster__c' { return mapClusterCommonFields; }
            when 'cluster_issue__c' { return mapClusterIssueCommonFields; }
            when 'cluster_registration__c' { return mapClusterRegistrationCommonFields; }
            when 'clusterattribute__b' { return mapClusterAttributeCommonFields; }
            when 'community_feed__c' { return mapCommunityFeedCommonFields; }
            when 'cs_order__c' { return mapCSOrderCommonFields; }
            when 'customer_registration_request__c' { return mapCustomerRegistrationRequestCommonFields; }
            when 'customer_subscription__c' { return mapCustomerSubscriptionCommonFields; }
            when 'domainsupdate__c' { return mapDomainsUpdateCommonFields; }
            when 'download_history__c' { return mapDownloadHistoryCommonFields; }
            when 'escalation__c' { return mapEscalationCommonFields; }
            when 'escalation_communication__c' { return mapEscalationCommunicationCommonFields; }
            when 'escalation_contact__c' { return mapEscalationContactCommonFields; }
            when 'escalation_management__c' { return mapEscalationManagementCommonFields; }
            when 'escalation_request__c' { return mapEscalationRequestCommonFields; }
            when 'forum_info__c' { return mapForumInfoCommonFields; }
            when 'getfeedback_survey_response__c' { return mapGetFeedbackSurveyResponseCommonFields; }
            when 'heartbeat_server_log__c' { return mapHeartbeatServerLogCommonFields; }
            when 'how_to__kav' { return mapHowToCommonFields; }
            when 'idea' { return mapIdeaCommonFields; }
            when 'idea_exception__c' { return mapIdeaExceptionCommonFields; }
            when 'jira_issue__c' { return mapJIRAIssueCommonFields; }
            when 'lessons_learned__c' { return mapLessonsLearnedCommonFields; }
            when 'linkedarticle' { return mapLinkedArticleCommonFields; }
            when 'metadata_request__c' { return mapMetadataRequestCommonFields; }
            when 'note__c' { return mapNoteCommonFields; }
            when 'playbook__c' { return mapPlaybookCommonFields; }
            when 'playbook_checklist__c' { return mapPlaybookChecklistCommonFields; }
            when 'playbook_sub_task__c' { return mapPlaybookSubTaskCommonFields; }
            when 'playbook_template__c' { return mapPlaybookTemplateCommonFields; }
            when 'portal_news__c' { return mapPortalNewsCommonFields; }
            when 'pushtopic' { return mapPushTopicCommonFields; }
            when 'release_software__c' { return mapReleaseSoftwareCommonFields; }
            when 'release_version__c' { return mapReleaseVersionCommonFields; }
            when 'releases__c' { return mapReleasesCommonFields; }
            when 'risk_profile__c' { return mapRiskProfileCommonFields; }
            when 'risk_profile_pdm_feature__c' { return mapRiskProfilePDMFeatureCommonFields; }
            when 'risk_profile_watcher__c' { return mapRiskProfileWatcherCommonFields; }
            when 'rkcli_user_log__c' { return mapRkcliUserLogCommonFields; }
            when 'rsc_migration_tasks__c' { return mapRSCMigrationTasksCommonFields; }
            when 'solution' { return mapSolutionCommonFields; }
            when 'status_tracking__c' { return mapStatusTrackingCommonFields; }
            when 'sub_task__c' { return mapSubTaskCommonFields; }
            when 'success_plan__c' { return mapSuccessPlanCommonFields; }
            when 'tasks__c' { return mapTasksCommonFields; }
            when 'user_history__c' { return mapUserHistoryCommonFields; }
            when 'wl_domain__c' { return mapWLDomainCommonFields; }
            when else { return new Map<String, Object>(); }
        }
    }
}