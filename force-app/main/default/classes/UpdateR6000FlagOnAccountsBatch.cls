/**
* @description CS21-161 : Set the flag for r6000 series on Account to identify if an Account has at least one r6000 series product based on the Assets tagged
* @author Ashwini G
* @date 9th April 2020
*/

public class UpdateR6000FlagOnAccountsBatch implements Database.Batchable<sObject>, System.Schedulable{
   	/**
   	* @description List of product names considered as CEM Entitlement products, derived from custom label 'CEM_Entitlement_Product_Names'.
   	*/ 
	public list<String> cemEntitlementProducts=system.label.CEM_Entitlement_Product_Names.split(',');
    
    /**
    * @description Start method of the Batch class. Queries all Account records to process.
    * @param BC
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC){

        String query = 'Select Id,name from account';
        return Database.getQueryLocator(query);
    }

    /**
    * @description Execute method for Schedulable interface. Schedules batch execution for UpdateR6000FlagOnAccountsBatch.
    * @param SC
    */
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new UpdateR6000FlagOnAccountsBatch(),100);
    }
	
    /**
    * @description If condition udpated for CS21-3553
    * @param BC
    * @param scope
    */
    public void execute(Database.BatchableContext BC, List<Account> scope){
        List<Account> accountsToUpdate = new List<Account>();
        Boolean hasPurchasedCompleteEdition = false;
        Boolean hasPurchasedASE = false;
        Boolean hasPurchasedIgneous = false;
        Boolean hasPurchasedRRW = false;
        Boolean hasPurchasedLaminar = false;
        Boolean hasPurchasedCodebaseRecovery = false;
        Boolean hasPurchasedPredibase = false;
        Set<String> productsAlreadyTaggedSet = new Set<String>();
        Set<String> newProductsToBeTaggedSet = new Set<String>();
        Boolean containsR6Asset = false;
        Boolean isProductsTaggedDifferent = false;
        Boolean updateAccount = false;
        
        map<Id,Date> accountToLatestEntEndDate=new map<id,Date>();
        boolean updateLatestEndInAccount=false;
        Map<Id, Account> scopeMap = new Map<Id, Account>(scope); //SPH-2713
        
        Map<Id, Decimal> accountToARR = new Map<Id, Decimal>();
        for (ServiceContract sc : [SELECT Id, GrandTotal, Term, AccountId FROM ServiceContract WHERE Status = 'Active' AND AccountId IN :scopeMap.keyset()]) {                                        
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
        //CS21-3741 Changes, Aggregate query throwing error
        Map<Id,List<Asset>> accToAssetListMap = new Map<Id,List<Asset>>();
        for(Asset ass: [SELECT Id, AccountId, Product2.Family, Product2.Description, Product2.Name FROM Asset where AccountId IN: scopeMap.keySet() LIMIT 5000]){
            if(!accToAssetListMap.containskey(ass.AccountId)){
                accToAssetListMap.put(ass.AccountId, new List<Asset>());
            }
            accToAssetListMap.get(ass.AccountId).add(ass);   
        }
        
        Map<Id,List<Entitlement>> accToEntitlementListMap = new Map<Id,List<Entitlement>>();
        for(Entitlement ent: [SELECT Id, AccountId, Status,Product__r.Product_Type__c,Product__r.Description ,Product__r.Family, Product__r.Support_Type__c, StartDate, Name, Product__r.Name,Product__c,enddate FROM Entitlement where AccountId IN: scopeMap.keySet() LIMIT 5000]){
            if(!accToEntitlementListMap.containskey(ent.AccountId)){
                accToEntitlementListMap.put(ent.AccountId, new List<Entitlement>());
            }
            accToEntitlementListMap.get(ent.AccountId).add(ent);
        }
        //CS21-3741 Ended
        
        for(Account eachAccount : [SELECT Id,ARR_Band__c,r6000_Series_Products_Tagged__c,
                                        Contains_r6000_Product_s__c,Latest_CEM_Entitlement_End_Date__c
                                        FROM Account
                                        WHERE ID IN: scopeMap.keySet()]){ 
            hasPurchasedCompleteEdition = false;
            hasPurchasedASE = false;
            hasPurchasedIgneous = false;
            hasPurchasedRRW = false;
            hasPurchasedLaminar = false;
            hasPurchasedCodebaseRecovery = false;
			hasPurchasedPredibase = false;
            productsAlreadyTaggedSet = new Set<String>();
            newProductsToBeTaggedSet = new Set<String>();
            containsR6Asset = false;
            isProductsTaggedDifferent = false;
            updateAccount = false;
            updateLatestEndInAccount=false;
			String oldARRTier = eachAccount.ARR_Band__c;
            
            Decimal arrValue = accountToARR.containsKey(eachAccount.Id)? accountToARR.get(eachAccount.Id): null;
            eachAccount.ARR_Band__c = getArrTierLabel(arrValue);
            if(oldARRTier != eachAccount.ARR_Band__c){
            	updateAccount = true;
            }
                                            
            if(accToAssetListMap.containsKey(eachAccount.Id)){
                for(Asset ast : accToAssetListMap.get(eachAccount.Id)){
                    String tempDescription = '';
                    if(ast.Product2.Family != null){
                        if(ast.Product2.Family.contains('R6000')){
                            containsR6Asset = true;
                        }
                    }
                    if(ast.Product2.Description != null ){
                        tempDescription = ast.Product2.Description;

                        if(tempDescription.contains('r6')){
                            containsR6Asset = true;

                            Integer indexOfSeriesStart = tempDescription.indexOf('r6');
                            tempDescription = tempDescription.substring(indexOfSeriesStart,indexOfSeriesStart+6);
                            tempDescription = tempDescription.removeEnd('/');
                            tempDescription = tempDescription.trim();

                            newProductsToBeTaggedSet.add(tempDescription);
                        }
                    }
                    if(ast.Product2.Name != null){
                        if(ast.Product2.Name.contains('R6')){
                            String tempName = ast.Product2.Name;
                            containsR6Asset = true;

                            Integer indexOfSeriesStartInName = tempName.indexOf('R6');

                            if(indexOfSeriesStartInName+6 > tempName.length()){
                                tempName = tempName.substring(indexOfSeriesStartInName,indexOfSeriesStartInName+5);
                            } else{
                                tempName = tempName.substring(indexOfSeriesStartInName,indexOfSeriesStartInName+6);
                            }
                            tempName = tempName.removeEnd('-');
                            tempName = tempName.toLowerCase();
                            tempName = tempName.trim();

                            newProductsToBeTaggedSet.add(tempName);
                        }
                    }
                }
            }

            if(accToEntitlementListMap.containskey(eachAccount.Id)){
                for(Entitlement eachEnt : accToEntitlementListMap.get(eachAccount.Id)) {
                     if(eachEnt.EndDate!=null && cemEntitlementProducts!=null  && eachEnt.Product__c!=null){
                           for(String productName:cemEntitlementProducts){
                                if(eachEnt.product__r.Name.contains(productName)){
                                    if(accountToLatestEntEndDate.containskey(eachAccount.Id)){
                                         Date entEndDate=accountToLatestEntEndDate.get(eachAccount.Id);
                                         if(entEndDate < eachEnt.EndDate){
                                             accountToLatestEntEndDate.put(eachAccount.Id,eachEnt.EndDate);
                                            }
                                         }else{
                                              accountToLatestEntEndDate.put(eachAccount.Id,eachEnt.EndDate);
                                         }
                                      }
                                  }
                    }
                    
                    if(!hasPurchasedCompleteEdition && !String.isBlank(eachEnt.Product__r.Product_Type__c) && System.Label.Complete_Edition.equalsIgnoreCase(eachEnt.Product__r.Product_Type__c)) {
                        newProductsToBeTaggedSet.add(System.Label.Complete_Edition);
                        hasPurchasedCompleteEdition = true;
                    }

                    if(!hasPurchasedASE && ((!String.isBlank(eachEnt.Product__r.Family) && eachEnt.Product__r.Family.equalsIgnoreCase(System.Label.ASE)) || 
                                            (!String.isBlank(eachEnt.Product__r.Support_Type__c) && eachEnt.Product__r.Support_Type__c == 'Proactive') ||
        									(!String.isBlank(eachEnt.Product__r.Description) && eachEnt.Product__r.Description.toLowerCase().contains('assigned support engineer'))
                                           )) {
                        newProductsToBeTaggedSet.add(System.Label.ASE);
                        hasPurchasedASE = true;
                    }

                    if(!hasPurchasedIgneous && System.Label.Igneous_Entitlements.containsIgnoreCase(eachEnt.Name) && eachEnt.StartDate <= System.today()) {
                        newProductsToBeTaggedSet.add(System.Label.Igneous);
                        hasPurchasedIgneous = true;
                    }

                    if(!hasPurchasedRRW && eachEnt.Product__r.Name != null && System.Label.RansomwareProduct.toUpperCase().containsIgnoreCase(eachEnt.Product__r.Name)) {
                        newProductsToBeTaggedSet.add(System.Label.Ransomware_Recovery_Warranty);
                        hasPurchasedRRW = true;
                    }

                    if(!hasPurchasedLaminar && !String.isBlank(eachEnt.Product__r.Product_Type__c) && System.Label.DSPM_Product_Types.containsIgnoreCase(eachEnt.Product__r.Product_Type__c)) {
                        newProductsToBeTaggedSet.add(System.Label.DSPM);
                        hasPurchasedLaminar = true;
                    }
                    
                    //------ CS21-3024: Append Codebase Recovery to Products Tagged field -------
                    if(!hasPurchasedCodebaseRecovery && !String.isBlank(eachEnt.Product__r.Product_Type__c) && System.Label.Codebase_Recovery.equalsIgnoreCase(eachEnt.Product__r.Product_Type__c)){
                        newProductsToBeTaggedSet.add(System.Label.Codebase_Recovery);
                        hasPurchasedCodebaseRecovery = true;
                    }
                    //------ CS21-3024: Append Codebase Recovery to Products Tagged field -------
                    
                    //------ CS21-3667: Add CEM tagging logic -------
                    if(eachEnt.Status == 'Active' && 
						(
							(eachEnt.Product__r.Family != null && eachEnt.Product__r.Family.containsIgnoreCase('CEM')) ||
        					(eachEnt.Product__r.Description != null && (eachEnt.Product__r.Description.toLowerCase().contains('customer experience manager') || eachEnt.Product__r.Description.toLowerCase().contains('customer experience specialist')))
           
						)) {
                            // Add CEM to r6000_Series_Products_Tagged__c if not already there
            				newProductsToBeTaggedSet.add('CEM');
                        }
                    //------ CS21-3667: Add CEM tagging logic -------
  					//------ CS21-3477: Append Predibase to Products Tagged field -------
                      if(!hasPurchasedPredibase && !String.isBlank(eachEnt.Product__r.Product_Type__c) && System.Label.PredibaseProduct.equalsIgnoreCase(eachEnt.Product__r.Product_Type__c)){
                          newProductsToBeTaggedSet.add(System.Label.PredibaseProduct);
                          hasPurchasedPredibase = true;
                      }
                      //------ CS21-3477: Append Predibase to Products Tagged field -------
                }
            }

            if(!String.isBlank(eachAccount.r6000_Series_Products_Tagged__c)){
                productsAlreadyTaggedSet = new Set<String>(eachAccount.r6000_Series_Products_Tagged__c.split(', '));
            }
                                            
            if(productsAlreadyTaggedSet.isEmpty() && newProductsToBeTaggedSet.isEmpty()){
                if(eachAccount.Contains_r6000_Product_s__c != containsR6Asset){
                    updateAccount = true;
                }
            }
            else if(productsAlreadyTaggedSet.size() != newProductsToBeTaggedSet.size()){
                updateAccount = true;
            }
            else{
                for(String eachNewProduct : newProductsToBeTaggedSet){
                    if(!productsAlreadyTaggedSet.contains(eachNewProduct)){
                        isProductsTaggedDifferent = true;
                        break;
                    }
                }
                if(isProductsTaggedDifferent){
                    updateAccount = true;
                }
            }

           
                if(updateAccount){
                    eachAccount.Contains_r6000_Product_s__c = containsR6Asset;
                    eachAccount.r6000_Series_Products_Tagged__c = String.join(newProductsToBeTaggedSet, ', '); 
                    if(newProductsToBeTaggedSet.size() == 1 && newProductsToBeTaggedSet.contains('Predibase')){
                        eachAccount.Enforce_Admin_User__c = true;
                    }
                }
               
                if(accountToLatestEntEndDate!=null && accountToLatestEntEndDate.size()>0 && accountToLatestEntEndDate.containskey(eachAccount.Id)){                   
                    if (eachAccount.Latest_CEM_Entitlement_End_Date__c==null || (eachAccount.Latest_CEM_Entitlement_End_Date__c!=null && accountToLatestEntEndDate.get(eachAccount.Id)!=eachAccount.Latest_CEM_Entitlement_End_Date__c)){ 
                         eachAccount.Latest_CEM_Entitlement_End_Date__c=accountToLatestEntEndDate.get(eachAccount.Id) ;
                         updateLatestEndInAccount=true;
                     } 
                      
                }else if(eachAccount.Latest_CEM_Entitlement_End_Date__c!=null){
                    updateLatestEndInAccount=true;
                    eachAccount.Latest_CEM_Entitlement_End_Date__c=null;
                }
                                            
                if(updateLatestEndInAccount || updateAccount){
                      accountsToUpdate.add(eachAccount);                          
                 } 
            }

        List<Database.SaveResult> saveAccounts = Database.update(accountsToUpdate, false);
    }

    /**
    * @description Finish method of the Batchable interface.
    * @param BC
    */
    public void finish(Database.BatchableContext BC){
    	System.debug(logginglevel.INFO, 'Finish Processing');    
    }
    
    /**
 	* @description Determines the ARR tier label based on the provided ARR value.
 	* @param arrValue
    * @return String
 	*/
    
    private static String getArrTierLabel(Decimal arrValue) {
    	if (arrValue == null || arrValue == 0) return 'No revenue information';
    	if (arrValue < 250000) return 'X-Small - XS';
    	if (arrValue < 500000) return 'Small - S';
    	if (arrValue < 1000000) return 'Medium - M';
    	if (arrValue < 2000000) return 'Large - L';
    	if (arrValue < 5000000) return 'X-Large - XL';
    	return 'XX-Large - XXL';
	}
}