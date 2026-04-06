/**
 * @author Abhishek Mahajan
 * @date 25th October 2023
 * @description Controller to CeOperationsDashboard/CeGenericReport, This Apex class is responsible for providing data and methods
 * for the CE Operations Dashboard in Customer Experience
 */
public class CeOperationsDashboardController {
    /*
    * @description Flag to show debug logs
    */
    private static boolean SHOW_DEBUG = false;
    /*
    * @description Define a list of fields related to Request for Enhancements (RFEs)
    */
    static List < String > RFEs = new List < String > {
        'Name',
        'Status__c',
        'Product_Component__c',
        'Product_Area__c',
        'Aha_Idea_Number__c',
        'Aha_Unique_ID__c',
        'External_Unique_Id__c',
        'Idea_Category__c',
        'Idea_Description__c',
        'Impacted_Customers__c',
        'Problem_Statement__c'
    };
    /*
    * @description Define a list of fields related to JIRA issues
    */    
    static String[] JIRAs = new List < String > {
        'Name',
        'zsfjira__Summary__c',
        'zsfjira__Prioriy__c',
        'Fixed_in_Version__c',
        'zsfjira__Resolution__c',
        'zsfjira__Status__c',
        'Release_Notes_Candidate__c',
        'Resolution_Details__c'
    };
    /*
    * @description Define a list of fields related to Salesforce cases
    */
    static String[] CASES = new List < String > {
        'Account.Name',
        'CaseNumber',
        'Contact.Name',
        'Priority',
        'Cluster_Tag__c',
        'Subject',
        'Current_Status__c',
        'Next_Step__c',
        'Owner.Name',
        'Jira_Reference_urls__c',
        'Status'
    };
    /**
     * @description Checks if a given string array is empty or null.
     *
     * @param arr The string array to check.
     * @return True if the array is empty or null, otherwise false.
     */
    private static Boolean isArrayEmptyOrNull(String[] arr) {
        return arr == null || arr.isEmpty();
    }
    /*
    * @description values considered under None grouping
    */
    private static final string[] PRIORITY_NONE_VALUES = new List<String>{NULL,'--- None ---','None'};
     /**
     * @description Similiar priorities are grouped together, example P3 & P3 - Medium, grouped priorites
     *              are expanded
     * @param groupByValue Priority Value
     * @return String representing priority clause
     */
    private static String getReversePriorityGrouping(String groupByValue){
        String priorityClause;
        if(groupByValue.equalsIgnoreCase('None')){
            priorityClause = 'Priority IN :PRIORITY_NONE_VALUES';
        } else if(groupByValue.equalsIgnoreCase('P1')){
            priorityClause = 'Priority Like \'P1%\'';
        } else if(groupByValue.equalsIgnoreCase('P2')){
            priorityClause = 'Priority Like \'P2%\'';
        } else if(groupByValue.equalsIgnoreCase('P3')){
            priorityClause = 'Priority Like \'P3%\'';
        } else if(groupByValue.equalsIgnoreCase('P4')){
            priorityClause = 'Priority Like \'P4%\'';
        } else {
            priorityClause = '';            
        }
        return priorityClause;
    }
    /**
     * @description Retrieves picklist values for a specified object and field.
     *
     * @param objectName The name of the object.
     * @param fieldName  The name of the field.
     * @return List of picklist values.
     */
    @AuraEnabled(cacheable = true)
    public static List < Map < String, String >> getPicklistValues(String objectName, String fieldName) {
        List < Map < String, String >> picklistValues = new List < Map < String, String >> ();
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType != null) {
                Schema.DescribeFieldResult fieldResult = objectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                if (fieldResult.getType() == Schema.DisplayType.Picklist || fieldResult.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    List < Schema.PicklistEntry > picklistEntries = fieldResult.getPicklistValues();
                    for (Schema.PicklistEntry entry: picklistEntries) {
                        picklistValues.add(new Map < String, String > {
                            'label' => entry.getLabel(),
                            'value' => entry.getValue()
                        });
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return picklistValues;
    }
    /**
     * @description Generates a WHERE clause for filtering records,filters, metrics based on various criteria.
     *
     * @param preference   Array of Account preferences.
     * @param name         Array of Account Ids.
     * @param cem          Array of CEM values.
     * @param search       Search keyword.
     * @param baseRelationship Base relationship for the object.
     * @return WHERE clause as a string.
     */
    private static String getWhereClause(String[] preference, String[] name, String[] cem, String search, String baseRelationship) {
        List < String > whereFilters = new List < String > ();
        baseRelationship = String.isBlank(baseRelationship) ? '' : baseRelationship;
        if (!isArrayEmptyOrNull(preference)) {

            String[] preferences = new List < String > ();
            for (String p: preference) {
                preferences.add('\'' + String.escapeSingleQuotes(p) + '\'');
            }
            whereFilters.add(baseRelationship + 'Account_Preference__c INCLUDES (' + String.join(preferences, ',') + ') ');
        }

        if (!isArrayEmptyOrNull(name)) {
            whereFilters.add(baseRelationship + 'Id IN :name ');
        }

        if (!isArrayEmptyOrNull(cem)) {
            whereFilters.add(baseRelationship + 'Account_SAM__c IN :cem ');
        }
        if (!String.isBlank(search)) {
            whereFilters.add(baseRelationship + 'Name Like \'%' + String.escapeSingleQuotes(search) + '%\'');
        }
        whereFilters.add(baseRelationship +'Account_SAM__r.UserType = \'Standard\'');
        String whereClause = '';
        if (!whereFilters.isEmpty()) {
            whereClause = String.join(whereFilters, ' AND ');
        }
        return whereClause;
    }
    /**
     * @description Constructs a relationship query for different metrics.
     *
     * @param preference Array of Account preferences.
     * @param name       Array of Account names.
     * @param cem        Array of CEM values.
     * @param metric     The selected metric (Opportunity, Case, Jira, TTR).
     * @return A relationship query.
     */
    public static string getRelationshipQuery(String[] preference, String[] name, String[] cem, String metric) {

        String baseRelationship;
        if (metric == 'Opportunity') {
            baseRelationship = 'Opportunity_Name__r.Account.';
        }
        else if (metric == 'Case') {
            baseRelationship = 'Case_Number__r.Account.';
        }
        else if (metric == 'Jira') {
            baseRelationship = 'zsfjira__CaseId__r.Account.';
        }
        else if (metric == 'TTR') {
            baseRelationship = 'Case.Account.';
        }
        return getWhereClause(preference, name, cem, null, baseRelationship);
    }
    /**
     * @description Retrieves a list of Account records based on filter criteria.
     *
     * @param fields     List of fields to select.
     * @param preference Array of Account preferences.
     * @param name       Array of Account names.
     * @param cem        Array of CEM values.
     * @return List of Account records.
     */
    @AuraEnabled(cacheable = true)
    public static List < Account > getAccounts(List < String > fields, String[] preference, String[] name, String[] cem) {
        List<sObject> sObjects = new List<SObject>();
        String queryFormat = 'SELECT Id, {0} FROM Account {1} Order By Name LIMIT 1500';
        String whereClause = getWhereClause(preference, name, cem, null, null);
        if (!String.isBlank(whereClause)) {
            whereClause = ' WHERE ' + whereClause;
        }
        String query = String.format(queryFormat, new List < String > {
            String.join(fields, ','),
            whereClause
        });
        log(fields, preference, name, cem, null, query);
        try {
            sObjects = Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }        
        return sObjects;
    }
    /**
     * @description Retrieves a list of Account options based on filter criteria.
     *
     * @param context    The context for the query.
     * @param defaults   Array of default values.
     * @param preference Array of Account preferences.
     * @param cem        Array of CEM values.
     * @param search     Search keyword.
     * @param wiredSwitch Integer indicating a switch value.
     * @return List of Account options.
     */
    @AuraEnabled(cacheable = true)
    public static List < Account > getAccountOptions(String context, String[] defaults, String[] preference, String[] cem, String search, Integer wiredSwitch) {
        List<sObject> sObjects = new List<SObject>();
        String ACCOUNT_OPTIONS_QUERY_FORMAT = 'SELECT Id, Name FROM Account {0} Order By Name LIMIT 500';
        String whereClause = getWhereClause(preference, null, cem, search, null);

        if (!String.isBlank(whereClause)) {
            if (!isArrayEmptyOrNull(defaults)) {
                String andOrOR = context == 'name-change' ? ' OR ' : ' AND ';
                whereClause = ' WHERE (' + whereClause + ') ' + andOrOR + '  Id in :defaults';
            }
            else {
                whereClause = ' WHERE ' + whereClause;
            }
        }
        else {
            if (!isArrayEmptyOrNull(defaults)) {
                whereClause = ' WHERE Id in :defaults';
            }
        }
        String query = String.format(ACCOUNT_OPTIONS_QUERY_FORMAT, new List < String > {
            whereClause
        });
        log(defaults, preference, null, cem, search, query);

        try {
            sObjects = Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }        
        return sObjects;
    }
    /**
     * @description Retrieves a list of CEM (Customer Engagement Manager) options.
     *
     * @param context    The context for the query.
     * @param defaults   Array of default values.
     * @param preference Array of Account preferences.
     * @param name       Array of Account names.
     * @param search     Search keyword.
     * @param wiredSwitch Integer indicating a switch value.
     * @return List of CEM options.
     */
    @AuraEnabled(cacheable = true)
    public static List < User > getCEMOptions(String context, String[] defaults, String[] preference, String[] name, String search, Integer wiredSwitch) {
        String CEM_OPTIONS_QUERY_FORMAT = 'SELECT Id, Name FROM User WHERE Id IN ({0}) {1} Order By Name LIMIT 500';
        String CEM_QUERY_FORMAT = 'SELECT Account_SAM__c FROM Account {0}';

        String whereClause = getWhereClause(preference, name, null, null, null);
        String[] whereClauses = new List < String > ();
        if (!String.isBlank(whereClause)) {
            whereClauses.add(whereClause);
        }
        if (!String.isBlank(search)) {
            whereClauses.add('Account_SAM__r.Name Like \'' + String.escapeSingleQuotes(search) + '%\'');
        }
        String combinedWhereClause = String.join(whereClauses, ' AND ');
        String cemQuery = '';

        if (String.isBlank(combinedWhereClause)) {
            cemQuery = String.format(CEM_QUERY_FORMAT, new List < String > {
                ''
            });
        }
        else {
            cemQuery = String.format(CEM_QUERY_FORMAT, new List < String > {
                'WHERE ' + combinedWhereClause
            });
        }

        List < sObject > cems = new List < User > ();
        String query = String.format(CEM_OPTIONS_QUERY_FORMAT, new List < String > {
            cemQuery,
            ''
        });
        cems = Database.query(query);
        try {
            if (!isArrayEmptyOrNull(defaults)) {
                cems.addAll(Database.query('SELECT Id, Name FROM User WHERE Id IN :defaults'));
            }
            log(defaults, preference, name, null, search, query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return cems;
    }
    private static void log(String[] defaults, String[] preference, String[] name, String[] cem, String search, String query) {
        if(SHOW_DEBUG){
            System.debug(JSON.serializePretty(
                new Map < String, Object > {
                    'defaults' => defaults,
                    'preference' => preference,
                    'name' => name,
                    'search' => search,
                    'query' => query,
                    'cem' => cem
                }
            ));
        }
    }
    /**
     * @description Retrieves metrics data based on selected metric and filter criteria.
     *
     * @param preference Array of Account preferences.
     * @param name       Array of Account names.
     * @param cem        Array of CEM values.
     * @param metric     The selected metric.
     * @param fullData   Indicates whether to retrieve full data or summary data.
     * @return Map of metric data.
     */
    @AuraEnabled(cacheable = true)
    public static Map < String, Object > getMetrics(String[] preference, String[] name, String[] cem, String metric, Boolean fullData) {
		List<String> closedAhaStatuses = System.Label.Closed_AHA_Status.split(',');
        List<String> closedJiraStatuses = System.Label.Closed_Jira_Status.Split(',');
        List<String> issueKeys = System.Label.JIRA_Issue_Key.split(',');
        Date n_monthsFromToday12 = System.today().addMonths(-12);
        
        String whereClause = getWhereClause(preference, name, cem, null, null);		
        List < String > whereClauses = new List < String > ();
        String selectClause = '';
        String fromObject = '';
        String groupByClause = '';
        String limitClause = '';

        switch on metric {
            when 'open_p1', 'open_cases', 'closed_cases' {
                selectClause = fullData ? String.join(CASES, ',') : 'COUNT(Id)';
                fromObject = 'Case';
                if (!String.isBlank(whereClause)) {
                    whereClauses.add('AccountId IN (SELECT Id FROM Account WHERE ' + whereClause + ')');
                }
                if (metric == 'closed_cases') {
                    whereClauses.add('Status  = \'Closed\'');
                }
                else {
                    whereClauses.add('Status  <> \'Closed\'');
                }

                if (metric == 'open_p1') {
                    whereClauses.add('Priority = \'P1\'');
                }
            }
            when 'tcv_12_priority', 'tcv_12' {
                selectClause = metric == 'tcv_12_priority' ? 'COUNT(Id), Priority' : fullData ? String.join(CASES, ',') : 'COUNT(Id)';
                fromObject = 'Case';
                groupByClause = metric == 'tcv_12_priority' ? 'Priority' : '';
                if (!String.isBlank(whereClause)) {
                    whereClauses.add('AccountId IN (SELECT Id FROM Account WHERE ' + whereClause + ')');
                }
                whereClauses.add('CreatedDate >= :n_monthsFromToday12');
            }
            when 'jiras' {
                selectClause = fullData ? String.join(JIRAs, ',') : 'COUNT(Id)';
                fromObject = 'zsfjira__ZIssue__c';
                String relationshipClause = getRelationshipQuery(preference, name, cem, 'Jira');
                String issueQuery = 'SELECT zsfjira__ZIssueId__c FROM zsfjira__ZIssue_Case__c';
                if(!String.isBlank(relationshipClause)){
                    issueQuery+=' WHERE '+relationshipClause;
                }
                whereClauses.add('Id IN ('+issueQuery+')');
                whereClauses.add('zsfjira__IssueKey__c like :issueKeys');
                whereClauses.add('(NOT zsfjira__Status__c IN :closedJiraStatuses)');
            }
            when 'rfes' {
                selectClause = fullData ? String.join(RFEs, ',') : 'COUNT(Id)';
                fromObject = 'Aha_Ideas__c';
                String opportunityRelationshipClause = getRelationshipQuery(preference, name, cem, 'Opportunity');
                String caseRelationshipClause = getRelationshipQuery(preference, name, cem, 'Case');
                if (!String.isBlank(caseRelationshipClause)) {
                    whereClauses.add('Id IN (SELECT Aha_Ideas__c FROM Aha_Idea_Link__c WHERE (' + opportunityRelationshipClause + ') OR (' + caseRelationshipClause + '))');
                }
                whereClauses.add('(NOT status__c IN :closedAhaStatuses)');
            }
            when 'avg_ttr_12', 'avg_ttr_12_priority' {
                selectClause = metric == 'avg_ttr_12_priority' ? 'AVG(TTR__c), Priority' : fullData ? 'Id, CaseNumber' : 'AVG(TTR__c)';
                fromObject = 'Case';
                groupByClause = metric == 'avg_ttr_12_priority' ? 'Priority' : '';
                String relationShipQuery = getRelationshipQuery(preference, name, cem, 'TTR');
                if (!String.isBlank(relationShipQuery)) {
                    whereClauses.add(relationShipQuery);
                }
                whereClauses.add('CreatedDate = LAST_N_YEARS:1');

            }
            when
            else {

            }
        }

        String wc = String.join(whereClauses, ' AND ');
        String query = String.format('SELECT {0} FROM {1} {2} {3} {4}', new List < Object > {
            selectClause,
            fromObject,
            !String.isBlank(wc) ? 'WHERE ' + wc : '',
            !String.isBlank(groupByClause) ? 'GROUP BY ' + groupByClause : '',
            fullData ? 'LIMIT 2000' : limitClause
        });
        Map < String, Object > response = new Map < String, Object > ();
        try {
            response = new Map < String, Object > {
                'data' => Database.query(query)
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }
    /**
     * @description Retrieves group-based metrics data.
     *
     * @param preference   Array of Account preferences.
     * @param name         Array of Account names.
     * @param cem          Array of CEM values.
     * @param metric       The selected metric.
     * @param groupBy      The field to group by.
     * @param groupByValue The value to group by.
     * @return Map of group-based metric data.
     */
    @AuraEnabled(cacheable = true)
    public static Map < String, Object > getGroupMetrics(String[] preference, String[] name, String[] cem, String metric, String groupBy, String groupByValue) {
        String whereClause = getWhereClause(preference, name, cem, null, null);
		Date n_monthsFromToday12 = System.today().addMonths(-12);
        List < String > whereClauses = new List < String > ();
        String selectClause = '';
        String fromObject = '';
        
        switch on metric {
            when 'tcv_12_priority' {
                selectClause = String.join(CASES, ',');
                fromObject = 'Case';
                if (!String.isBlank(whereClause)) {
                    whereClauses.add('AccountId IN (SELECT Id FROM Account WHERE ' + whereClause + ')');
                }
                whereClauses.add('CreatedDate >= :n_monthsFromToday12');
                if (!(String.isBlank(groupBy) /*|| String.isBlank(groupByValue)*/)) {
                    String priorityClause;
                    if(groupBy=='Priority'){
                        priorityClause = getReversePriorityGrouping(groupByValue);
                    } else {
                        priorityClause = groupBy + ' =:groupByValue';
                    }
                    whereClauses.add(priorityClause);
                }
            }

            when
            else {

            }
        }

        String wc = String.join(whereClauses, ' AND ');
        String query = String.format('SELECT {0} FROM {1} {2} LIMIT 2000', new List < Object > {
            selectClause,
            fromObject,
            !String.isBlank(wc) ? 'WHERE ' + wc : ''
        });
        Map < String, Object > response = new Map < String, Object > ();
        try {
            response = new Map < String, Object > {
                'data' => Database.query(query)
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;

    }
}