/**
 * Class: RBRK_SubscriptionSummaryVariableCalc
 * @description Calculates and updates Account-level summary variables based on Contract Line Items.
 *   Driven by configurable metadata from RBRK_SubscriptionSummaryVariable__c custom metadata records.
 */
public class RBRK_SubscriptionSummaryVariableCalc {

    // Constants for reference field API names and operator values
    static final String subscriptionAccountAPIName = 'SBQQSC__Account__c';
    static final String SUBSCRIPTION = 'Subscription';
    static final String ASSET = 'Asset';
    static final String NOTEQUALS = 'not equals';

    // @description Mapping of logical operators to their equivalent SOQL syntax
    private static final Map<String, String> operatorMap = new Map<String, String>{
        'Equals' => 'IN',
        'contains' => 'LIKE',
        'not equals' => 'NOT IN'
    };

    // @description Cached list of metadata configuration records
    private static List<RBRK_SubscriptionSummaryVariable__c> configRecords;

    // Set to hold all rule IDs used during the run for tracking not applicable rules
    public static Set<String> ruleIdSet = new Set<String>();

    /**
     * Constructor
     * @description Triggers summary variable processing on instantiation
     * 
     * @param scopeList List of Accounts to evaluate for summary variable update
     */
    public RBRK_SubscriptionSummaryVariableCalc(List<Account> scopeList) {
        processAllSubscription(SUBSCRIPTION, scopeList);
    }
    /**
     * Constructor
     * @description Triggers summary variable processing on instantiation
     * 
     * @param CliList List of ContractLineItem to evaluate for summary variable update
     */
     @InvocableMethod(label='Pass ContractLineItems to Calculator Class')
    public static void processContractLineItems(List<ContractLineItem> CliList) {
        List<Account> accounts = new List<Account>();
        Set<id> parentAccounts = new Set<id>();
        for (ContractLineItem cli : cliList) {
            if (cli.SBQQSC__Account__c != null) {
                parentAccounts.add(cli.SBQQSC__Account__c);
            }
        }
        
        for (Id accid : parentAccounts) {
            Account acc = new Account(
                ID = accid
            );
            accounts.add(acc);
        }
    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(!disableBusinessLogicCS.Disable_Contract_Line_Item_Triggers__c){
        
        processAllSubscription(SUBSCRIPTION, accounts);
    }
    }

    /**
     * @description Orchestrates the full workflow:
     *  - Load config
     *  - Build dynamic SOQL
     *  - Execute query
     *  - Process results
     *  - Update Accounts
     * 
     * @param targetObject Target object type (Subscription/Asset)
     * @param accounts     List of Accounts to process
     */
    public static void processAllSubscription(String targetObject, List<Account> accounts) {
        configRecords = getConfigRecords(targetObject);
        Map<String, Map<String, List<String>>> operatorFilterMap = buildOperatorFilterMap(targetObject);
        Set<String> selectedFields = collectSelectedFields(operatorFilterMap, targetObject);

        String query = buildQuery(operatorFilterMap, selectedFields, accounts);
        List<ContractLineItem> results  = new List<ContractLineItem>();
        if(query != null){
        results = Database.query(query);
        Map<Id, Map<String, Integer>> accountToFilterCountMap = processRecords(results);
        Set<Id> acntId=extractnonCLIAccounts(accounts,accountToFilterCountMap.keySet());
        updateAccountWithRuleId(accountToFilterCountMap,acntId);
        }
    }

    /**
     * @description Builds a dynamic SOQL query string based on metadata filters.
     * 
     * @param filterMap Operator-to-field-to-values mapping
     * @param fields    Fields to include in SELECT clause
     * @param accounts  List of Accounts for WHERE clause
     * @return          Complete SOQL string
     */
    public static String buildQuery(Map<String, Map<String, List<String>>> filterMap, Set<String> fields, List<Account> accounts) {
        String baseQuery = 'SELECT ' + String.join(fields, ',') + ' FROM ContractLineItem WHERE Status=\'Active\'';
        baseQuery += ' AND ' + subscriptionAccountAPIName + ' IN :accounts AND (';

        List<String> conditions = new List<String>();

        for (String op : filterMap.keySet()) {
            String soqlOp = operatorMap.get(op);
            for (String field : filterMap.get(op).keySet()) {
                List<String> vals = filterMap.get(op).get(field);
                if (soqlOp == 'LIKE') {
                    for (String val : vals) {
                        if (field != null) {
                            conditions.add(field + ' LIKE \'' + val + '\'');
                        }
                    }
                } else if (field != null) {
                    conditions.add(field + ' ' + soqlOp + ' (\'' + String.join(vals, '\',\'') + '\')');
                }
            }
        }
       if (conditions == null || conditions.isEmpty()) {
      return null;
      }
        baseQuery += String.join(conditions, ' OR ') + ')';
        return baseQuery;
    }
	/**
     * @description Identifies Account that did not had any CLI
     * 
     * @param account List of Account records from SOQL
     * @param AccountIdFromMap Set of Account records from SOQL
     * @return      Set of account that did not had CLIs
     */
    public static Set<Id> extractnonCLIAccounts(List<Account> account,Set<Id> AccountIdFromMap) {
        Set<Id> acntId = new Set<Id>();
        for(Account acnt:account){
            acntId.add(acnt.Id);
        }
        if(AccountIdFromMap != null){
            acntId.removeAll(AccountIdFromMap);
        }
        return acntId;
    }
    
    
    /**
     * @description Identifies rule IDs that matched any Contract Line Item
     * 
     * @param items List of ContractLineItem records from SOQL
     * @return      Set of matching rule IDs
     */
    public static Set<String> extractMatchingRuleIds(List<ContractLineItem> items) {
        Set<String> matchedIds = new Set<String>();
        for (ContractLineItem item : items) {
            for (RBRK_SubscriptionSummaryVariable__c config : configRecords) {
                if (config.RBRK_FilterField__c != null) {
                    String field = config.RBRK_FilterField__c;
                    String val = (String) item.get(field);
                    if (val != null && config.RBRK_FilterValue__c != null &&
                        config.RBRK_FilterValue__c.split(',').contains(val)) {
                        matchedIds.add(config.RBRK_SVUniqueId__c);
                    }
                }
            }
        }
        return matchedIds;
    }

    /**
     * @description Retrieves active configuration rules for a target object.
     * Also populates ruleIdSet with all active rule IDs.
     * 
     * @param targetObject Object type to filter config records
     * @return             List of config records
     */
    public static List<RBRK_SubscriptionSummaryVariable__c> getConfigRecords(String targetObject) {
        List<RBRK_SubscriptionSummaryVariable__c> summaryVarList = [
            SELECT RBRK_FilterField__c, RBRK_AggregateFunction__c, RBRK_AggregateField__c,
                   RBRK_FilterValue__c, RBRK_Operator__c, RBRK_SVUniqueId__c
            FROM RBRK_SubscriptionSummaryVariable__c 
            WHERE RBRK_TargetObject__c = :targetObject AND RBRK_IsActive__c = TRUE
        ];
        for (RBRK_SubscriptionSummaryVariable__c rssv : summaryVarList) {
            ruleIdSet.add(rssv.RBRK_SVUniqueId__c);
        }
        return summaryVarList;
    }

    /**
     * @description Prepares formatted filter values for LIKE-based operators.
     * 
     * @param operator  Configured operator
     * @param rawValue  Comma-separated raw value
     * @return          Formatted list of values for SOQL
     */
    public static List<String> getFormattedValues(String operator, String rawValue) {
        if (String.isBlank(rawValue)) return new List<String>();
        List<String> values = rawValue.split(',');
        if (operator == 'contains') {
            for (Integer i = 0; i < values.size(); i++) {
                values[i] = '%' + values[i] + '%';
            }
        }
        return values;
    }

    /**
     * @description Builds a map of operator → field → list of filter values
     * 
     * @param targetObject Subscription or Asset
     * @return             Structured filter map
     */
    private static Map<String, Map<String, List<String>>> buildOperatorFilterMap(String targetObject) {
        Map<String, Map<String, List<String>>> operatorMap = new Map<String, Map<String, List<String>>>();
        for (RBRK_SubscriptionSummaryVariable__c config : configRecords) {
            String op = config.RBRK_Operator__c;
            String field = config.RBRK_FilterField__c;
            List<String> values = getFormattedValues(op, config.RBRK_FilterValue__c);

            if (!operatorMap.containsKey(op)) {
                operatorMap.put(op, new Map<String, List<String>>());
            }
            if (!operatorMap.get(op).containsKey(field)) {
                operatorMap.get(op).put(field, new List<String>());
            }
            operatorMap.get(op).get(field).addAll(values);
        }
        return operatorMap;
    }

    /**
     * @description Collects all field names required in the SOQL SELECT clause
     * 
     * @param operatorFilterMap Map of filter logic
     * @param targetObject      Object type
     * @return                  Set of field names
     */
    private static Set<String> collectSelectedFields(Map<String, Map<String, List<String>>> operatorFilterMap, String targetObject) {
        Set<String> fields = new Set<String>();
        for (RBRK_SubscriptionSummaryVariable__c config : configRecords) {
            if (config.RBRK_FilterField__c != null) {
                fields.add(config.RBRK_FilterField__c);
            }
            if (config.RBRK_AggregateField__c != null) {
                fields.add(config.RBRK_AggregateField__c);
            }
        }
        fields.add(subscriptionAccountAPIName);
        return fields;
    }

    /**
     * @description Processes the list of ContractLineItems and aggregates count/value per rule ID per Account.
     * 
     * @param contractList List of queried ContractLineItems
     * @return             Map of Account Id → ruleId → aggregate value
     */
    public static Map<Id, Map<String, Integer>> processRecords(List<ContractLineItem> contractList) {
        Map<Id, Map<String, Integer>> accountToFilterCountMap = new Map<Id, Map<String, Integer>>();
        Map<String, String> functionToCounterMap = new Map<String, String>{
        'Count' => 'Countvalue',
        'Max' => 'Maxvalue',
        'Min' => 'Minvalue',
        'Sum' => 'Sumvalue'
    };
    Map<String, Integer> counterToValueMap = new Map<String, Integer>();
        for (ContractLineItem cli : contractList) {
            for (RBRK_SubscriptionSummaryVariable__c config : configRecords) {
                String fieldApi = config.RBRK_FilterField__c;
                String aggField = config.RBRK_AggregateField__c;
                String filterValue = config.RBRK_FilterValue__c;
                String aggFunction = config.RBRK_AggregateFunction__c;
                String cliFieldValue = fieldApi != null
                ? ((String)cli.get(fieldApi) != null ? (String)cli.get(fieldApi) : '')
                : '';
                Integer fieldVal = Integer.valueOf(cli.get(aggField));

                if (cliFieldValue != null && filterValue != null && fieldVal != null) {
                    for (String filter : filterValue.split(',')) {
                        Boolean eval = cliFieldValue.equals(filter);
                        if(config.RBRK_Operator__c == 'contains'){
                        eval = cliFieldValue.contains(filter);
                        }
                        if (config.RBRK_Operator__c == NOTEQUALS) {
                            eval = !cliFieldValue.equals(filter);
                        }
                        if (eval) {
                            Map<String, Integer> filterCountMap = accountToFilterCountMap.get(cli.SBQQSC__Account__c);
                            if (filterCountMap == null) filterCountMap = new Map<String, Integer>();

                           counterToValueMap.put(functionToCounterMap.get(aggFunction),filterCountMap.containsKey(config.RBRK_SVUniqueId__c) && filterCountMap.get(config.RBRK_SVUniqueId__c) != null ? 
                                                    filterCountMap.get(config.RBRK_SVUniqueId__c) : 0) ;
                            if(aggFunction.equalsIgnoreCase('Count')) {
                                counterToValueMap.put(functionToCounterMap.get(aggFunction),(counterToValueMap.containsKey(functionToCounterMap.get(aggFunction)) ? 
                                counterToValueMap.get(functionToCounterMap.get(aggFunction)) : 0) + 1);
                            } if(aggFunction.equalsIgnoreCase('Max')) {
                                if(fieldVal > counterToValueMap.get(aggFunction)) {
                                    counterToValueMap.put(functionToCounterMap.get(aggFunction), fieldVal);
                                }
                            }  
                              if(aggFunction.equalsIgnoreCase('Min')){
                                if(counterToValueMap.get(aggFunction) > fieldVal) {
                                    counterToValueMap.put(functionToCounterMap.get(aggFunction), fieldVal);

                                }
                            } if(aggFunction.equalsIgnoreCase('Sum')) {
                                   counterToValueMap.put(functionToCounterMap.get(aggFunction),(counterToValueMap.containsKey(functionToCounterMap.get(aggFunction)) ? 
                                   counterToValueMap.get(functionToCounterMap.get(aggFunction)) : 0) + fieldVal);

                            }
                            

                            filterCountMap.put(config.RBRK_SVUniqueId__c, counterToValueMap.get(functionToCounterMap.get(aggFunction)));
                            accountToFilterCountMap.put(cli.SBQQSC__Account__c, filterCountMap);
                            break;
                        }
                    }
                }
            }
        }

        // Apply composite calculations
        Map<String, RBRK_SubscriptionSummaryVariable__c> compositeRules = processCompositeVariable();
        Map<String, Integer> alreadyCalculated = new Map<String, Integer>();

        for (String acct : accountToFilterCountMap.keySet()) {
            Map<String, Integer> ruleMap = accountToFilterCountMap.get(acct);
            
            for (String ruleId : ruleMap.keySet()) {
                
                if (compositeRules.containsKey(ruleId)) {
                    calculateComposite(ruleId, ruleMap, compositeRules, alreadyCalculated);
                }
            }
        }

        return accountToFilterCountMap;
    }

    /**
     * @description Recursively calculates composite summary variable values.
     * 
     * @param ruleId             Composite rule ID
     * @param filterCountMap     Rule values per account
     * @param rss                All composite rules
     * @param alreadyCalculated  Prevent recalculation
     */
    private static void calculateComposite(
        String ruleId,
        Map<String, Integer> filterCountMap,
        Map<String, RBRK_SubscriptionSummaryVariable__c> rss,
        Map<String, Integer> alreadyCalculated
    ) {
        if (!rss.containsKey(ruleId)) return;

        RBRK_SubscriptionSummaryVariable__c current = rss.get(ruleId);
        if (current.RBRK_CombineWith__r == null || current.RBRK_CombineWith__r.RBRK_SVUniqueId__c == null) return;

        String depId = current.RBRK_CombineWith__r.RBRK_SVUniqueId__c;
        calculateComposite(depId, filterCountMap, rss, alreadyCalculated);

        Integer a = filterCountMap.get(ruleId) != null ? filterCountMap.get(ruleId) : 0;
        Integer b = filterCountMap.get(depId) != null ? filterCountMap.get(depId) : 0;

        Integer result = mathCalc(a, b, current.RBRK_CompositeOperator__c);
        filterCountMap.put(ruleId, result);
        alreadyCalculated.put(ruleId, result);
    }

    /**
     * @description Performs mathematical operations for composite calculation.
     * 
     * @param A        First value
     * @param B        Second value
     * @param Operator Operation type ('Add', 'Subtract', 'Divide')
     * @return         Result of operation
     */
    public static Integer mathCalc(Integer A, Integer B, String Operator) {
        if (Operator == 'Add') return A + B;
        if (Operator == 'Subtract') return A - B;
        if (Operator == 'Divide') return B != 0 ? A / B : 0;
        return 0;
    }

    /**
     * @description Retrieves all active composite summary rules with dependencies.
     * 
     * @return Map of ruleId → rule definition
     */
    public static Map<String, RBRK_SubscriptionSummaryVariable__c> processCompositeVariable() {
        Map<String, RBRK_SubscriptionSummaryVariable__c> result = new Map<String, RBRK_SubscriptionSummaryVariable__c>();
        List<RBRK_SubscriptionSummaryVariable__c> subSummaryVarforComposite = [
            SELECT RBRK_CombineWith__c, RBRK_SVUniqueId__c, RBRK_CompositeOperator__c,
                   RBRK_CombineWith__r.RBRK_SVUniqueId__c
            FROM RBRK_SubscriptionSummaryVariable__c
            WHERE RBRK_CompositeOperator__c != null AND RBRK_CombineWith__c != null AND RBRK_IsActive__c = TRUE
        ];
        for (RBRK_SubscriptionSummaryVariable__c rec : subSummaryVarforComposite) {
            result.put(rec.RBRK_SVUniqueId__c, rec);
        }
        return result;
    }

    /**
     * @description Updates Account records with the summary rule values (applied and not applied).
     * 
     * @param accountToFilterCountMap Account-level rule values
     * @param accountIdfrmMap Accounts 
     */
    private static void updateAccountWithRuleId(Map<Id, Map<String, Integer>> accountToFilterCountMap,Set<Id> accountIdfrmMap) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Id accountId : accountToFilterCountMap.keySet()) {
            Account acc = new Account(Id = accountId);
            Map<String, Integer> filterCountMap = accountToFilterCountMap.get(accountId);

            Set<String> ruleIdNotApplicable = new Set<String>(ruleIdSet);
            ruleIdNotApplicable.removeAll(filterCountMap.keySet());

            Set<String> idValueSet = new Set<String>();
            for (String key : filterCountMap.keySet()) {
                idValueSet.add(key + ':' + filterCountMap.get(key));
            }

            acc.RBRK_SummaryVarCustomRuleId__c = String.join(idValueSet, ';');
            acc.RBRK_NotSummaryVarCustomRuleId__c = String.join(ruleIdNotApplicable, ';');
            accountsToUpdate.add(acc);
            
        }
            for(Id accntId:accountIdfrmMap){
               Account accont = new Account(Id = accntId); 
               accont.RBRK_NotSummaryVarCustomRuleId__c= String.join(ruleIdSet, ';');
               accountsToUpdate.add(accont); 
            }
            
        if (!accountsToUpdate.isEmpty()) {
            try {
                List<sObject> sObjectsFailed = new List<sObject>();
                List<Database.SaveResult> srList = new List<Database.SaveResult>();
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                for(Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()) {
                sObjectsFailed.add(accountsToUpdate[i]);
                srList.add(results[i]);
                    }
                } 
                LogError.createDMLErrorLog(sObjectsFailed,srList,'RBRK_SubscriptionSummaryVariableCalc','Update Account with custom Summary variable count on CLI(CPQ-5370)');
                }catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Failed to update Accounts: ' + e.getMessage());
            }
        }
    }
}