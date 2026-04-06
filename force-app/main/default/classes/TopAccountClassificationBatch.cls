/**
* @description CS21-3667 Top Accounts (Part 1): Customer identification and classification
* @author Raveesh Layal
* @date 2025-10-02
*/
public class TopAccountClassificationBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    /**
	@description All the criteria based processedIds
	*/
    Set<Id> processedByCriteria = new Set<Id>();
    
	/**
	@description Test Schedulable interface execution method
	@param sc
	*/
    public void execute(SchedulableContext sc) {
        if (!Test.isRunningTest()) {
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
        	Database.executeBatch(batch, 500); 
        }
        //String cronExp = '0 0 0 ? * 7';
		//System.schedule('TopAccountBatchSaturday', cronExp, new TopAccountClassificationBatch());
	}
    
    /**
	@description Start method Query all Accounts
	@param bc
    @return Database.QueryLocator
	*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, ParentId,Account_Preference__c,r6000_Series_Products_Tagged__c,parent.Account_Preference__c,Customer_URL__c,Top_Accounts_Criteria__c FROM Account where (Customer_URL__c != null or Account_Preference__c INCLUDES (\'Top Accounts\'))  order by ParentId asc'
        );
    }
    
    /**
	@description Execute method - Process each chunk of Accounts
	@param bc
	@param scope
	*/
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Map<Id, Set<Id>> rootToChildrenMap = new Map<Id, Set<Id>>(); 
        Map<Id, Set<Id>> toBeTopAccountsMap = new Map<Id, Set<Id>>(); 
        Map<Id,Account> allAccounts = new Map<Id, Account>(scope);
        Set<Id> toBeTopAccountsList = new Set<Id>();
        
        
        // Store Root Accounts
        for (Account acc : scope) {
        	rootToChildrenMap.put(acc.Id, new Set<Id>());
            if(acc.Customer_URL__c != null){
                toBeTopAccountsList.add(acc.Id);
                toBeTopAccountsMap.put(acc.Id, new Set<Id>());
            }
        }
        // Fetch children up to 2 levels for these root accounts
        for (Account child : [SELECT Id, ParentId,Account_Preference__c,r6000_Series_Products_Tagged__c,parent.Account_Preference__c,Customer_URL__c,parent.Customer_URL__c,Top_Accounts_Criteria__c FROM Account WHERE ParentId IN :rootToChildrenMap.keyset() or id in :rootToChildrenMap.keyset() order by parentid asc]) {
            allAccounts.put(child.Id,child);
            if(toBeTopAccountsMap.containsKey(child.ParentId) && (child.Customer_URL__c != null)){
                toBeTopAccountsList.add(child.Id);
                toBeTopAccountsMap.get(child.ParentId).add(child.Id);
            }
        }
        
        Set<Id> accountsToUpdate = new Set<Id>();
        Set<Id> entitlementAccounts = new Set<Id>();
		List<String> cemDescValues = System.Label.CEM_Product_Description.split(',');

        // Build the base query
		String baseQuery = 'SELECT Id, AccountId, Status, Product__r.Family, Product__r.Description FROM Entitlement WHERE Status = \'Active\' AND AccountId IN :toBeTopAccountsList AND (Product__r.Family LIKE \'%CEM%\' ';

		// Add dynamic OR conditions for each description
		if (!cemDescValues.isEmpty()) {
    		List<String> likeConditions = new List<String>();
    		for (String val : cemDescValues) {
        		val = val.trim();
        		if (String.isNotBlank(val)) {
            		baseQuery += ' OR Product__r.Description LIKE \'%' + String.escapeSingleQuotes(val) + '%\'';
        		}
    		}
		}

		baseQuery += ')';
        
		//Add these Accounts related to Entitlements to Update List
		for (Entitlement ent : Database.query(baseQuery)) {
            accountsToUpdate.add(ent.Accountid);
            entitlementAccounts.add(ent.Accountid);
             if(toBeTopAccountsMap.containskey(ent.Accountid) && toBeTopAccountsMap.get(ent.Accountid) != null){
                accountsToUpdate.addAll(toBeTopAccountsMap.get(ent.Accountid));
           }

        }
        
        // Calculate ARR per Account
        Map<Id, Decimal> accountToARR = new Map<Id, Decimal>();
        for (ServiceContract sc : [SELECT Id, GrandTotal, Term, AccountId FROM ServiceContract WHERE Status = 'Active' AND AccountId IN :toBeTopAccountsList]) {                                        
            if (sc.GrandTotal != null && sc.GrandTotal > 0 && sc.Term != null && sc.Term > 0) {
                Decimal acv = (sc.GrandTotal / sc.Term) * 12;
                if (!accountToARR.containsKey(sc.AccountId)) {
                    accountToARR.put(sc.AccountId, acv);
                }
                else{
                    accountToARR.put(sc.AccountId, accountToARR.get(sc.AccountId) + acv);
                }
            }
        }
        
        Set<Id> serviceContracts = new Set<Id>();
        for (Id rootId : accountToARR.keySet()) {
            if (accountToARR.get(rootId) > 500000) {
                accountsToUpdate.add(rootId);
                serviceContracts.add(rootId);
                 if(toBeTopAccountsMap.containskey(rootId) && toBeTopAccountsMap.get(rootId) != null){
                accountsToUpdate.addAll(toBeTopAccountsMap.get(rootId));
           		}
            }
        }
        
        // Update Account_Preference__c and r6000_Series_Products_Tagged__c
        Map<Id,String> processedAccounts = new Map<Id,String>();
        Map<Id,Account> accUpdateMap = new Map<Id,Account>();
        for (Account acc : allAccounts.values()) {
            Set<String> newCriteria = new Set<String>();
            if(!processedByCriteria.contains(acc.id)){
                if(String.isNotBlank(acc.Account_Preference__c) && acc.Account_Preference__c.contains('Top Accounts (Manual exception)')){
                    acc.Top_Accounts_Criteria__c = 'Manual exception';
                }
                else{
                    acc.Top_Accounts_Criteria__c = '';
                }
                if(!entitlementAccounts.contains(acc.id) && !String.isBlank(acc.r6000_Series_Products_Tagged__c) && acc.r6000_Series_Products_Tagged__c.contains('CEM')){
                	List<String> ProductsTagged = acc.r6000_Series_Products_Tagged__c.split(',');
                    List<String> filtered = new List<String>();
                    for (String s : ProductsTagged) {
    					String trimmedValue = s.trim();
                        if (trimmedValue != 'CEM') {
                         	filtered.add(s);
    					}
					}
                    String updatedValue = String.join(filtered, ',');
					acc.r6000_Series_Products_Tagged__c = updatedValue;
                    accUpdateMap.put(acc.Id,acc);
            	} 
            if(accountsToUpdate.contains(acc.id)){
            	Boolean exactMatchTopAccount = false;
                if(String.isBlank(acc.Account_Preference__c)){
                	acc.Account_Preference__c = 'Top Accounts'; 
                    accUpdateMap.put(acc.Id,acc);
                }
                else if(!acc.Account_Preference__c.contains('Top Accounts') ){
                	acc.Account_Preference__c += ';Top Accounts';
                    accUpdateMap.put(acc.Id,acc);
                }
                else if(acc.Account_Preference__c.contains('Top Accounts') ){
                	for (String s : acc.Account_Preference__c.split(';')) {
    					String trimmedPrefValue = s.trim();
                        if (trimmedPrefValue == 'Top Accounts') {
                        	exactMatchTopAccount = true;
                            break;
    					}
					}
                    if(exactMatchTopAccount == false){
                        acc.Account_Preference__c += ';Top Accounts';
                    	accUpdateMap.put(acc.Id,acc);
                    }
                }
                if(entitlementAccounts.contains(acc.Id)){
                	if (String.isBlank(acc.r6000_Series_Products_Tagged__c)) {
    					acc.r6000_Series_Products_Tagged__c = 'CEM';
                        accUpdateMap.put(acc.Id,acc);
					} 
                	else if (!acc.r6000_Series_Products_Tagged__c.contains('CEM')) {
    					acc.r6000_Series_Products_Tagged__c += ', CEM';
                        accUpdateMap.put(acc.Id,acc);
					}
                    newCriteria.add('CEM');
                } 
                if(serviceContracts.contains(acc.Id)){
                    newCriteria.add('ARR');
                }
                if(entitlementAccounts.contains(acc.ParentId)){
                    newCriteria.add('Account inheritance (CEM)'); 
                 }
                 if(serviceContracts.contains(acc.ParentId)){
                    newCriteria.add('Account inheritance (ARR)');
                 }
                addTopAccountCriteria(accUpdateMap, acc, newCriteria);
            }
            else if(!accountsToUpdate.contains(acc.id) && !String.isBlank(acc.Account_Preference__c) && acc.Account_Preference__c.contains('Top Accounts')){
                if (String.isBlank(acc.ParentId) ||
					(processedAccounts.containsKey(acc.ParentId) && 
                		(processedAccounts.get(acc.ParentId) == null ||
            				(!processedAccounts.get(acc.ParentId).contains('Top Accounts') ||
                				(processedAccounts.get(acc.ParentId).contains('Top Accounts') &&
                    				(accountsToUpdate == null || !accountsToUpdate.contains(acc.ParentId) || (accountsToUpdate.contains(acc.ParentId) && acc.Customer_URL__c==null)) 
                				)
            				)
        				)
    				) ||
    				((String.isNotBlank(acc.ParentId) && acc.Parent != null &&
        				(String.isBlank(acc.Parent.Account_Preference__c) ||
            				(!String.isBlank(acc.Parent.Account_Preference__c) && 
             					!acc.Parent.Account_Preference__c.contains('Top Accounts')
                            )
        				)) || acc.Customer_URL__c==null
    				)
				){
                    List<String> RemovedTopAccountList = new List<String>();
                    for (String s : acc.Account_Preference__c.split(';')) {
    					String trimmedPrefValue = s.trim();
                        if (trimmedPrefValue != 'Top Accounts') {
                        	RemovedTopAccountList.add(s);
    					}
					} 
                    String finalTopAccountPrefernces = String.join(RemovedTopAccountList, ';');
					acc.Account_Preference__c = finalTopAccountPrefernces;
                                            
                    //List<String> TopAcnCrt = acc.Top_Accounts_Criteria__c.split(';');
                    if (String.isNotBlank(acc.Top_Accounts_Criteria__c)) {
                    	List<String> filteredCrt = new List<String>();
                    	for (String crt :  acc.Top_Accounts_Criteria__c.split(';')) {
    						String trimValue = crt.trim();
                        	if (trimValue == 'Manual exception') {
                         		filteredCrt.add(trimValue);
    						}
						}
                    	String updatedValueCrt = String.join(filteredCrt, ',');
                        acc.Top_Accounts_Criteria__c = updatedValueCrt;
                    }
                    accUpdateMap.put(acc.Id,acc);
                }
            }
                if(entitlementAccounts.contains(acc.id) || serviceContracts.contains(acc.id)){
                    processedByCriteria.add(acc.id);
                }
                processedAccounts.put(acc.id,acc.Account_Preference__c);
            }
        }
        if (!accUpdateMap.isEmpty()) {
            Database.update(accUpdateMap.values(),false);
        }
    }
    /**
	@description Batch finish method 
	@param bc
	*/
    public void finish(Database.BatchableContext bc) {
        System.debug(logginglevel.INFO, 'Finish Processing');
    }
    
    /**
 	* @description Helper method to add criteria to an Account field only if not already present.
    * @param accUpdateMap
    * @param acc
    * @param newCriteria
 	*/
	private static void addTopAccountCriteria(Map<Id, Account> accUpdateMap, Account acc, Set<String> newCriteria) {
        if (newCriteria.isEmpty()) {
            return;
    	}
		
    	String existingCriteria = acc.Top_Accounts_Criteria__c;
    	Set<String> allCriteria = new Set<String>();

    	// Add existing criteria if any
    	if (!String.isBlank(existingCriteria)) {
        	for (String s : existingCriteria.split(';')) {
            	if (!String.isBlank(s)) {
                	allCriteria.add(s.trim());
            	}
        	}
    	}
        
    	// Add the new one
    	allCriteria.addall(newCriteria);
        
    	// Join and update if there's a change
    	String updatedValue = String.join(new List<String>(allCriteria), '; ');
    	if (existingCriteria != updatedValue) {
        	acc.Top_Accounts_Criteria__c = updatedValue;
        	accUpdateMap.put(acc.Id, acc);
    	}
	}
}