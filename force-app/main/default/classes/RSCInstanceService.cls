/**
 * @description     : Service class responsible for fetching RSC Instance data and
 * managing dynamic table configurations for both Internal and Community users.
 * @TstClass        : RSCInstanceServiceTest
 * 
 * -------------------------------------------------------------- @History -------------------------------------------------------------------------
 * Story Number       Modified By            Date           Description
 * -------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class RSCInstanceService {
    
    // PROPERTIES & STATE
    
    /** @description Indicates whether the current context user is a portal user. */
    private static Boolean isPortalUser = false;
    
    /** @description The currently selected Case record context used in Visualforce. */
    public Case currentCase {get; set;}
    
    /** @description List of RSC options for dropdown selection in the UI. */
    public List<SelectOption> rscOptions {get; set;}
    
    /** @description The ID of the RSC Instance selected by the user. */
    public String selectedRscId {get; set;}
    
    /** @description Flag indicating whether the UI is currently in edit mode. */
    public Boolean isEditMode {get; set;}
    /**  @description  View type constant for standard internal view. */
    private static final String VIEW_STANDARD = 'standard';
    
    /**  @description  View type constant for MSP view. */
    private static final String VIEW_MSP = 'msp';
    
    /**  @description  View type constant for portal/community view. */
    private static final String VIEW_PORTAL = 'portal';
    
    /**  @description  Account Record Type name for Partner / Distributor accounts. */
    private static final String RECORDTYPE_PARTNER_DISTRIBUTOR = 'Partner/Distributor';
    
    // CONSTRUCTOR
    
    /**
     * @description Constructor for MyProductsController context.
     * Initializes controller state using the current Case context.
     * @param std StandardController providing the current record context.
     */
    public RSCInstanceService(ApexPages.StandardController std) {
        Id caseId = std.getId();
        this.currentCase = new RSCDataHandler().getCaseById(caseId);
        this.isEditMode = false;
        this.selectedRscId = currentCase.RSCInstance__c;
        prepareRscOptions();
    }
    
    // AURA / LWC ENTRY POINTS
    
    /**
     * @description Specialized method for Portal/Community logic.
     * Called from other service classes to fetch portal-specific RSC data.
     * @return TableWrapper Object containing portal columns and RSC Instance data.
     */
    public static TableWrapper getRSCInstances() {
        return buildTableWrapper(null);
    }
    
    /**
     * @description Main entry point for the component. Detects user context and returns wrapper.
     * @param recordId The Id of the record where the component is hosted (e.g., Case Id).
     * @return TableWrapper Object containing the dynamic columns and list of RSC Instances.
     */
    @AuraEnabled
    public static TableWrapper getInitialData(Id recordId) {
        return buildTableWrapper(recordId);
    }
    
    // VISUALFORCE ACTION METHODS
    
    /**
     * @description Saves the selected RSC Instance on the current Case record.
     * @return PageReference Redirect to the updated Case record, or null on error.
     */
    public PageReference saveRSC() {
        try {
            currentCase.RSCInstance__c = String.isNotBlank(selectedRscId) ? (Id)selectedRscId : null;
            new RSCDataHandler().updateCase(currentCase);
            
            this.currentCase = new RSCDataHandler().getCaseById(currentCase.Id);
        	this.isEditMode = false;
        	this.selectedRscId = currentCase.RSCInstance__c;
            return null;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
    }
    
    /** * @description Enables edit mode for the Visualforce UI.
     */
    public void toggleEdit() {
        this.isEditMode = true;
    }
    
    /** * @description Cancels edit mode and reverts the selected RSC Instance value.
     */
    public void cancelEdit() {
        this.isEditMode = false;
        this.selectedRscId = currentCase.RSCInstance__c;
    }
    
    // PRIVATE BUSINESS LOGIC METHODS
    
    /**
     * @description Orchestrates the building of the table wrapper based on user context.
     * @param recordId The context record ID.
     * @return TableWrapper The populated data wrapper for the UI.
     */
    private static TableWrapper buildTableWrapper(Id recordId) {
        TableWrapper wrapper = new TableWrapper();
        wrapper.debugTrace = '[RSCInstanceService]';
        
        RSCDataHandler handler = new RSCDataHandler();
        User loggedInUser = handler.getLoggedInUserInfo();
        
        if (loggedInUser.UserType == 'CspLitePortal') {
            processPortalUserView(wrapper, loggedInUser, handler);
        }
        else if (recordId != null && recordId.getSObjectType().getDescribe().getName() == 'Case') {
            wrapper.sObjectOfID = recordId.getSObjectType().getDescribe().getName();
            processInternalCaseView(wrapper, recordId, handler);
        }
        else if (recordId != null && recordId.getSObjectType().getDescribe().getName() == 'Account'){
            wrapper.sObjectOfID = recordId.getSObjectType().getDescribe().getName();
            Set<String> validProfiles = new Set<String>{'Rubrik Customer Support Manager', 'Rubrik Customer Support User', 'Rubrik Professional Services', 'Rubrik Renewal Specialist'};
            
            if (validProfiles.contains(loggedInUser.Profile.Name)) {
                processInternalAccountView(wrapper, recordId, handler);
                wrapper.debugTrace = '[RSCInstanceService] Object type ' + recordId.getSObjectType().getDescribe().getName() + loggedInUser.Profile.Name;
            }
        }
        return wrapper;
    }
    
    /**
     * @description Logic specific to processing views for Portal/Community users.
     * @param wrapper The wrapper to populate.
     * @param u The logged in User record.
     * @param handler The data access handler.
     */
    private static void processPortalUserView(TableWrapper wrapper, User u, RSCDataHandler handler) {
        wrapper.isVisible = true;
        wrapper.isPortalView = true;
        isPortalUser = true;
        String accRecordType = u.Account.RecordType.Name;
        
        if (accRecordType == 'Partner/Distributor') {
            wrapper.isPartenerDistributorAccRecType = true;
        } else {
            wrapper.isPartenerDistributorAccRecType = false;
        }
        
        Boolean isMSPAccount = !handler.fetchSdpInstances(u.AccountId).isEmpty();
        wrapper.columns = getColumns('portal', accRecordType, isMSPAccount);
        wrapper.dataList = handler.performDynamicQuery(wrapper.columns, u.AccountId);
    }
    
    /**
     * @description Logic specific to processing views for Internal CRM users.
     * @param wrapper The wrapper to populate.
     * @param recordId The Case ID.
     * @param handler The data access handler.
     */
    private static void processInternalCaseView(TableWrapper wrapper, Id recordId, RSCDataHandler handler) {
        Case c = handler.getCaseForTable(recordId);
        Set<String> validRTs = new Set<String>{'Support Case', 'Customer Success', 'Renewal Case'};
        
        if (validRTs.contains(c.RecordType.Name)) {
            wrapper.isVisible = true;
            Boolean isMSPAccount = !handler.fetchSdpInstances(c.AccountId).isEmpty();
            String viewType = isMSPAccount ? 'msp' : 'standard';
            wrapper.columns = getColumns(viewType, null, isMSPAccount);
            wrapper.dataList = handler.performDynamicQuery(wrapper.columns, c.AccountId);
        }
    }
    
    /**
     * @description Logic specific to processing views for Internal CRM users on an Account record.
     * @param wrapper The wrapper to populate.
     * @param recordId The Account ID.
     * @param handler The data access handler.
     */
    private static void processInternalAccountView(TableWrapper wrapper, Id recordId, RSCDataHandler handler) {
        wrapper.isVisible = true;
        Boolean isMSPAccount = !handler.fetchSdpInstances(recordId).isEmpty();
        String viewType = isMSPAccount ? 'msp' : 'standard';
        wrapper.columns = getColumns(viewType, null, isMSPAccount);
        wrapper.dataList = handler.performDynamicQuery(wrapper.columns, recordId);
    }
    
    /**
     * @description Prepares the list of RSC Instance options for the Visualforce dropdown.
     */
    private void prepareRscOptions() {
        rscOptions = new List<SelectOption>();
        rscOptions.add(new SelectOption('', '-- None --'));
        List<RSCInstance__c> instances = new RSCDataHandler().fetchRscInstancesForAccount(currentCase.AccountId);
        
        List<RSCWrapper> wrappedList = new List<RSCWrapper>();
        for(RSCInstance__c rsc : instances) {
            wrappedList.add(new RSCWrapper(rsc));
        }
        wrappedList.sort();
        
        for(RSCWrapper wrapper : wrappedList) {
            RSCInstance__c rsc = wrapper.record;
            if(String.isNotBlank(rsc.RSCUrl__c)) {
                rscOptions.add(new SelectOption(rsc.Id, rsc.RSCUrl__c));
            }
            else if(String.isNotBlank(rsc.Name)){
                rscOptions.add(new SelectOption(rsc.Id, rsc.Name));
            }
        }
    }
    
    /**
     * @description Generates column configurations for the Lightning Data Table.
     * @param viewType String representing the type of view (standard, msp, portal).
     * @param accRecordType The Record Type Name of the Account.
     * @param mspAccount Boolean flag for MSP status.
     * @return List<ColumnWrapper> List of column configurations.
     */
    private static List<ColumnWrapper> getColumns(String viewType, String accRecordType, Boolean mspAccount) {
        List<ColumnWrapper> cols = new List<ColumnWrapper>();
        if (viewType == 'standard') {
            cols.add(new ColumnWrapper('RSC description', 'RSCAccountName__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('RSC URL', 'RSCUrl__c', 'url', 'portal-cell cell_width_350'));
            ColumnWrapper identifierCol = new ColumnWrapper('Identifier', 'Id', 'url', 'portal-cell cell_width_180');
            identifierCol.typeAttributes = new Map<String, Object>{
                'label' => new Map<String, String>{'fieldName' => 'Identifier_Name'},
                'target' => '_blank'
            };
            cols.add(identifierCol);
            cols.add(new ColumnWrapper('Relationship', 'RSCAccountRelationship__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('RSC owner', 'RSCOwnerEmails__c', 'text', 'portal-cell cell_width_250'));
            cols.add(new ColumnWrapper('Type', 'RSCAccountType__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Contract', 'ContractType__c', 'text', 'portal-cell cell_width_180'));
            ColumnWrapper sdpCol = new ColumnWrapper('End customer account', 'SDPEndUser__c', 'url', 'portal-cell cell_width_180');
            sdpCol.typeAttributes = new Map<String, Object>{
                'label' => new Map<String, String>{'fieldName' => 'SDPEndUser_Name'},
                'target' => '_blank'
            };
            cols.add(sdpCol);
            cols.add(new ColumnWrapper('Region', 'RSCRegion__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Deployment', 'RSCDeployment__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Status', 'Status__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Hosted site', 'RSCHostSite__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('GCID', 'GCIds__c', 'text', 'portal-cell cell_width_180'));
        }
        else if (viewType == 'msp') {
            ColumnWrapper sdpPrimaryAccCol = new ColumnWrapper('MSP', 'AccountId__c', 'url', 'portal-cell cell_width_180');
            sdpPrimaryAccCol.typeAttributes = new Map<String, Object>{
                'label' => new Map<String, String>{'fieldName' => 'PrimaryAccount_SDP'},
                'target' => '_blank'
            };
            cols.add(sdpPrimaryAccCol);
            cols.add(new ColumnWrapper('RSC URL', 'RSCUrl__c', 'url', 'portal-cell cell_width_350'));
            ColumnWrapper identifierCol = new ColumnWrapper('Identifier', 'Id', 'url', 'portal-cell cell_width_180');
            identifierCol.typeAttributes = new Map<String, Object>{
                'label' => new Map<String, String>{'fieldName' => 'Identifier_Name'},
                'target' => '_blank'
            };
            cols.add(identifierCol);  
            cols.add(new ColumnWrapper('Relationship', 'RSCAccountRelationship__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('RSC owner', 'RSCOwnerEmails__c', 'text', 'portal-cell cell_width_250'));
            cols.add(new ColumnWrapper('Type', 'RSCAccountType__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Contract', 'ContractType__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Region', 'RSCRegion__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Deployment', 'RSCDeployment__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Status', 'Status__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('Hosted site', 'RSCHostSite__c', 'text', 'portal-cell cell_width_180'));
            cols.add(new ColumnWrapper('GCID', 'GCIds__c', 'text', 'portal-cell cell_width_180'));
        }
        else if (viewType == 'portal') {
            cols.add(new ColumnWrapper('Account name', 'RSCAccountName__c', 'text', 'portal-cell cell_width_150'));
            if (!mspAccount && accRecordType == 'Partner/Distributor') {
                cols.add(new ColumnWrapper('End customer', 'SDPEndUser_Name', 'text', 'portal-cell cell_width_150'));
            }
            cols.add(new ColumnWrapper('RSC URL', 'RSCUrl__c', 'text', 'portal-cell cell_width_120'));
            cols.add(new ColumnWrapper('Relationship', 'RSCAccountRelationship__c', 'text', 'portal-cell cell_width_120'));
            cols.add(new ColumnWrapper('RSC owner', 'RSCOwnerEmails__c', 'text', 'portal-cell cell_width_250'));
            cols.add(new ColumnWrapper('Type', 'RSCAccountType__c', 'text', 'portal-cell cell_width_120'));
            if (!mspAccount && accRecordType == 'Partner/Distributor') {
                cols.add(new ColumnWrapper('Contract', 'ContractType__c', 'text', 'portal-cell cell_width_120'));
            }
            cols.add(new ColumnWrapper('Region', 'RSCRegion__c', 'text', 'portal-cell cell_width_120'));
            cols.add(new ColumnWrapper('Deployment', 'RSCDeployment__c', 'text', 'portal-cell cell_width_120'));
            cols.add(new ColumnWrapper('Status', 'Status__c', 'text', 'portal-cell cell_width_120'));
            cols.add(new ColumnWrapper('Hosted site', 'RSCHostSite__c', 'text', 'portal-cell cell_width_120'));
        }
        return cols;
    }
    
    /**
     * @description Builds SDP End User URL column configuration.
     *
     * @return ColumnWrapper SDP End User column.
     */
    public static ColumnWrapper buildSdpEndUserColumnExternal() {
        return buildSdpEndUserColumn();
    }
    
    /**
     * @description Builds SDP End User URL column configuration.
     *
     * @return ColumnWrapper SDP End User column.
     */
    private static ColumnWrapper buildSdpEndUserColumn() {
        ColumnWrapper col = new ColumnWrapper(
            'SDP End User Lookup',
        'SDPEndUser__c',
        'url',
        'portal-cell cell_width_180'
            );
        col.typeAttributes = new Map<String, Object>{
            'label' => new Map<String, String>{ 'fieldName' => 'SDPEndUser_Name' },
            'target' => '_blank'
        };
        return col;
    }
    
    /**
     * @description Builds MSP primary account URL column configuration.
     *
     * @return ColumnWrapper MSP account column.
     */
    public static ColumnWrapper buildPrimaryAccountColumnExtenal() {
        return buildPrimaryAccountColumn();
    }
    
    
    /**
     * @description Builds MSP primary account URL column configuration.
     *
     * @return ColumnWrapper MSP account column.
     */
    private static ColumnWrapper buildPrimaryAccountColumn() {
        ColumnWrapper col = new ColumnWrapper(
            'MSP',
        'AccountId__c',
        'url',
        'portal-cell cell_width_180'
            );
        col.typeAttributes = new Map<String, Object>{
            'label' => new Map<String, String>{ 'fieldName' => 'PrimaryAccount_SDP' },
            'target' => '_blank'
        };
        return col;
    }
    
    // CONSOLIDATED INNER CLASS: DATA RETRIEVAL (WITHOUT SHARING)
    
    /**
     * @description Consolidated service class for all data retrieval and DML.
     * Executed 'without sharing' to ensure visibility for Community/Portal users.
     */
    public without sharing class RSCDataHandler {
        
        /**
         * @description Fetches the currently logged in User's details.
         * @return User The User record with Account context.
         */
        public User getLoggedInUserInfo() {
            if (!Schema.sObjectType.User.isAccessible()) {
                throw new SecurityException('User object is not accessible');
            }
            return [SELECT Id, UserType, AccountId, Account.RecordType.Name ,Profile.Name
                    FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        }
        
        /**
         * @description Fetches Case details required for table logic.
         * @param recordId The Case ID.
         * @return Case The Case record.
         */
        public Case getCaseForTable(Id recordId) {
            return [SELECT AccountId, RecordType.Name, Account.RecordType.Name FROM Case WHERE Id = :recordId WITH USER_MODE LIMIT 1];
        }
        
        /**
         * @description Fetches full Case details for Visualforce initialization.
         * @param caseId The Case ID.
         * @return Case The Case record with RSC relationship data.
         */
        public Case getCaseById(Id caseId) {
            if (!Schema.sObjectType.Case.isAccessible()) {
                throw new SecurityException('Case object is not accessible');
            }
            return [SELECT Id, AccountId, RSCInstance__c, RSCInstance__r.Name, RSCInstance__r.RSCUrl__c 
                    FROM Case WHERE Id = :caseId LIMIT 1];
        }
        
        /**
         * @description Checks for the existence of SDP instances for an Account.
         * @param accId The Account ID.
         * @return List<RSCInstance__c> A list containing at most one RSC Instance.
         */
        public List<RSCInstance__c> fetchSdpInstances(Id accId) {
             if (!Schema.sObjectType.RSCInstance__c.isAccessible()) {
                throw new SecurityException('RSCInstance__c object is not accessible');
            }
            return [SELECT Id FROM RSCInstance__c WHERE SDPEndUser__c = :accId LIMIT 1];
        }
        
        /**
         * @description Fetches all RSC Instances associated with an Account.
         * @param accId The Account ID.
         * @return List<RSCInstance__c> List of RSC instances.
         */
        public List<RSCInstance__c> fetchRscInstancesForAccount(Id accId) {
            return [SELECT Id, RSCUrl__c , RSCAccountRelationship__c,Name
                    FROM RSCInstance__c 
                    WHERE AccountId__c = :accId 
                    OR SDPEndUser__c = :accId WITH USER_MODE];
        }
        
        /**
         * @description Performs a dynamic SOQL query based on provided columns and account ID.
         * Flattens relationship fields for datatable compatibility.
         * @param columns The list of column configurations defining fields to query.
         * @param accId The Account ID to filter by.
         * @return List<Map<String, Object>> The flattened query results.
         */
        public List<Map<String, Object>> performDynamicQuery(List<ColumnWrapper> columns, Id accId) {
            Set<String> queryFields = new Set<String>{'Id'};
            Set<String> allowedFields = new Set<String>{
                'RSCAccountName__c','RSCUrl__c','Name','RSCAccountRelationship__c','RSCOwnerEmails__c','RSCAccountType__c','Identifier_Name',
                'ContractType__c','SDPEndUser__c','SDPEndUser_Name','RSCRegion__c','RSCDeployment__c','Status__c','RSCHostSite__c','GCIds__c','AccountId__c'
            };
            Set<String> allowedStatuses = new Set<String>{'ACTIVE','GRACE','PENDING_CREATION','SUSPENDED','MARKED_FOR_DELETION'};
            
            // Track which relationships need to be queried
            Boolean querySDPEndUser = false;
            Boolean queryAccountId = false;
            
            for (ColumnWrapper col : columns) {
                if (!allowedFields.contains(col.fieldName)) {
                    continue;
                }
                String field = String.escapeSingleQuotes(col.fieldName);
                if (field == 'AccountId__c') {
                    queryFields.add('AccountId__c');
                    queryFields.add('AccountId__r.Name');
                    queryAccountId = true;
                } else if (field == 'SDPEndUser__c' || field == 'SDPEndUser_Name') {
                    queryFields.add('SDPEndUser__c');
                    queryFields.add('SDPEndUser__r.Name');
                    querySDPEndUser = true;
                } else if (field == 'RSCAccountType__c' || field == 'Status__c') {
                    queryFields.add('toLabel(' + field + ')');
                } else {
                    queryFields.add(field);
                }
            }
            if(!queryFields.contains('Name')){
                queryFields.add('Name');
            }
            if(!queryFields.contains('Id')){
                queryFields.add('Id');
            }
            String fieldList = String.join(new List<String>(queryFields), ', ');
            String queryTemplate = 'SELECT {0} FROM RSCInstance__c WHERE (AccountId__c = :accId OR SDPEndUser__c = :accId)';
            if (RSCInstanceService.isPortalUser && !allowedStatuses.isEmpty()) {
                queryTemplate += ' AND Status__c IN :allowedStatuses';
            }
            String soql = String.format(queryTemplate, new List<String>{ fieldList });
            List<SObject> results = Database.query(soql);
            
            // Flatten relationship fields for datatable compatibility
            List<Map<String, Object>> flattenedResults = new List<Map<String, Object>>();
            for (SObject record : results) {
                Map<String, Object> flatRecord = new Map<String, Object>();
                
                // Copy all direct fields
                for (String field : record.getPopulatedFieldsAsMap().keySet()) {
                    if (field != 'SDPEndUser__r' && field != 'AccountId__r') {
                        flatRecord.put(field, record.get(field));
                    }
                }
                
                // Flatten SDPEndUser relationship (only if it was queried)
                if (querySDPEndUser && record.getSObject('SDPEndUser__r') != null) {
                    flatRecord.put('SDPEndUser_Name', record.getSObject('SDPEndUser__r').get('Name'));
                }
                
                // Flatten AccountId relationship (for MSP view, only if it was queried)
                if (queryAccountId && record.getSObject('AccountId__r') != null) {
                    flatRecord.put('PrimaryAccount_SDP', record.getSObject('AccountId__r').get('Name'));
                }
                flatRecord.put('Identifier_Name', record.get('Name'));
                
                flattenedResults.add(flatRecord);
            }
            
            return flattenedResults;
        }
        
        /**
         * @description Updates the Case record after performing an FLS check.
         * @param c The Case record to update.
         * @throws System.DmlException if user lacks update permissions.
         */
        public void updateCase(Case c) {
            if (!Test.isRunningTest() && !Schema.sObjectType.Case.fields.RSCInstance__c.isUpdateable()) {
                throw new System.DmlException('Access Denied: Your profile does not allow editing the RSC Instance field.');
            }
            update c;
        }
    }
    
    // INNER CLASSES: DATA WRAPPERS
    
    /** * @description Wrapper for lightning:datatable column configuration.
     */
    public class ColumnWrapper {
        /** @description The header label of the column. */
        @AuraEnabled public String label;
        /** @description The API name of the field. */
        @AuraEnabled public String fieldName;
        /** @description The data type (text, url, etc). */
        @AuraEnabled public String type;
        /** @description The initial width in pixels. */
        @AuraEnabled public String initialWidth;
        /** @description Map of additional type attributes for the column. */
        @AuraEnabled public Map<String, Object> typeAttributes;
        
        /**
         * @description Constructor for ColumnWrapper.
         * @param label Header label.
         * @param fieldName API field name.
         * @param type Data type.
         * @param initialWidth Column width.
         */
        public ColumnWrapper(String label, String fieldName, String type , String initialWidth) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            this.initialWidth = initialWidth;
        }
    }
    
    /** * @description Wrapper used to transfer RSC Instance table data to UI components.
     */
    public class TableWrapper {
        /** @description Visibility flag for the UI component. */
        @AuraEnabled public Boolean isVisible;
        /** @description Flag indicating if the user is in a portal context. */
        @AuraEnabled public Boolean isPortalView;
        /** @description Flag indicating if the account is a Partner/Distributor record type. */
        @AuraEnabled public Boolean isPartenerDistributorAccRecType;
        /** @description The list of record data to display. */
        @AuraEnabled public List<Map<String, Object>> dataList;
        /** @description The column configuration list. */
        @AuraEnabled public List<ColumnWrapper> columns;
        /** @description The sobject of the ID passed to class. */
        @AuraEnabled public String sObjectOfID;
        /** @description Debug information for troubleshooting. */
        @AuraEnabled public String debugTrace;
    }
    
    /**
     * @description Wrapper class for RSCInstance__c records to enable custom sorting.
     *              Sorting priority:
     *              1. Primary relationship records first.
     *              2. Alphabetical order based on RSC URL.
     */
    public class RSCWrapper implements Comparable {
        
        /**
         * @description Underlying RSCInstance__c record to be compared.
         */
        public RSCInstance__c record;
        
        /**
         * @description Constructor to initialize wrapper with RSCInstance__c record.
         * @param record RSCInstance__c record to wrap.
         */
        public RSCWrapper(RSCInstance__c record) {
            this.record = record;
        }
        
        /**
         * @description Custom comparison logic to support sorting of RSCWrapper objects.
         *              Primary relationship records are sorted first, followed by
         *              alphabetical order of RSC URL.
         *
         * @param compareTo Object to compare against.
         * @return Integer comparison result.
         */
        public Integer compareTo(Object compareTo) {
            
            RSCWrapper other = (RSCWrapper) compareTo;
            
            // Null safety for records
            if (this.record == null || other.record == null) {
                return 0;
            }
            
            Integer rankA = (this.record.RSCAccountRelationship__c == 'Primary') ? 0 : 1;
            Integer rankB = (other.record.RSCAccountRelationship__c == 'Primary') ? 0 : 1;
            
            if (rankA != rankB) {
                return rankA - rankB;
            }
            
            String urlA = (this.record.RSCUrl__c != null) ? this.record.RSCUrl__c : '';
            String urlB = (other.record.RSCUrl__c != null) ? other.record.RSCUrl__c : '';
            
            return urlA.compareTo(urlB);
        }
    }
    
}