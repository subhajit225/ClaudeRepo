public with sharing class PatchManager1 {
    public static Map<String, List<PatchManager__c>> getPatchMap(List<Lead> vList){
        Map<String, List<PatchManager__c>> patchMap = new  Map<String, List<PatchManager__c>>();
        Map<String, String> queryMap = new Map<String, String>();
        for(Lead vLead : vList){
            addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vLead.PostalCode)); 
            addQuery(queryMap, 'City__c', escapeString(vLead.City));  
            addQuery(queryMap, 'Domain__c', escapeString(vLead.Domain__c));    
            addQuery(queryMap, 'StateGlobal__c', escapeString(vLead.StateCode));
            addQuery(queryMap, 'CountryGlobal__c', escapeString(vLead.Country));                
            addQuery(queryMap, 'Industry_Category__c', escapeString(vLead.Industry_Category__c));           
            addQuery(queryMap, 'Tier__c', escapeString(vLead.L2AAccountTier__c)); 
            addQuery(queryMap, 'Metro_Area__c', escapeString(vLead.Metro_Area__c));      
        }
        patchMap =  queryPatchManger(queryMap); //contains non-null values only
        return patchMap;
    }
    public static  Map<String, List<PatchManager__c>> queryPatchManger(Map<String, String> query){
        String soqlStatment = 'Select Id, Account__c, SearchCity__c, SearchState__c, SearchCountry__c, City__c, County__c, Domain__c,TLevel1__c,MatchedAccountOwner__r.Name,Region__c, Industry_Category__c, Lead_Source_Detail__c, LeadSource__c, Object_Type__c, OwnerId, SDR__c, SIC__c, Zip_code__c, CountryGlobal__c, StateGlobal__c, SMB_Owner__c, CDM__c, InsideAccountExecutive__c, Distributor_Rep__c, MSP_Rep__c,recordtypeId, RecordType.Name, Alliance_BDM__c, Alliance_BDM__r.IsActive, Country__c,AccountExecutive__c,InsideAccountExecutive__r.IsActive,AccountExecutive__r.IsActive,CDM__r.IsActive,Tier__c, Metro_Area__c  from PatchManager__c';
        //Version 2.0
        String objectTypeCondition = 'Object_Type__c= \'All\'';
        String zipSearch = null;
        if(query.containsKey('Zip_code__c')){
            zipSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (Zip_code__c IN ('+query.get('Zip_code__c')+'))';
        }
        String citySearch=null;
        if(query.containsKey('City__c')){
                citySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchCity__c IN ('+query.get('City__c')+'))';
        }
        String stateSearch=null;
        if(query.containsKey('StateGlobal__c')){
                stateSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (StateGlobal__c IN ('+query.get('StateGlobal__c')+'))';
        }
        String countrySearch=null;
        if(query.containsKey('CountryGlobal__c')){
                countrySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchCountry__c IN ('+query.get('CountryGlobal__c')+'))';
        } else if(query.containsKey('Country__c')){
                countrySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchCountryCode__c IN ('+query.get('Country__c')+'))';
        }           
        String DomainSearch=null;
        if(query.containsKey('Domain__c')){
                DomainSearch= soqlStatment+' WHERE ('+objectTypeCondition+') AND ( Domain__c IN ('+query.get('Domain__c')+'))';
        }
        String industryCategorySearch=null;
        if(query.containsKey('Industry_Category__c')){
            industryCategorySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (Industry_Category__c IN ('+query.get('Industry_Category__c')+'))';
        }
        String metroAreaSearch=null;
        if(query.containsKey('Metro_Area__c')){
            metroAreaSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (Metro_Area__c IN ('+query.get('Metro_Area__c')+'))';
        }
        String TierSearch=null;
        if(query.containsKey('Tier__c')){
            tierSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (Tier__c INCLUDES ('+query.get('Tier__c')+'))';
        }
        
        List<PatchManager__c> listPManager = new List<PatchManager__c>();
        if(DomainSearch != null){
            system.debug('DOMAIN DATA '+DomainSearch);
            listPManager.addAll((List<PatchManager__c>)Database.query(DomainSearch));
        }
        if(industryCategorySearch != null){
            listPManager.addAll((List<PatchManager__c>)Database.query(industryCategorySearch));
        }
        if(zipSearch != null){
            listPManager.addAll((List<PatchManager__c>)Database.query(zipSearch));
        }
        if(metroAreaSearch != null){
            listPManager.addAll((List<PatchManager__c>)Database.query(metroAreaSearch));
        }
        if(citySearch != null){
            listPManager.addAll((List<PatchManager__c>)Database.query(citySearch));
        }
        if(stateSearch != null){
            listPManager.addAll((List<PatchManager__c>)Database.query(stateSearch));
        }
        if(countrySearch != null){
            listPManager.addAll((List<PatchManager__c>)Database.query(countrySearch));
        }
        system.debug('listPManager>>'+listPManager);
        Map<String, List<PatchManager__c>> patchMap = new  Map<String, List<PatchManager__c>>();
        if(listPManager!=null){
            for(PatchManager__c vManager:listPManager){
                //domain
                if(vManager.Domain__c != null) {
                    addPatchMap(patchMap,vManager.Domain__c, vManager);
                }
                else {
                    String key = vManager.CountryGlobal__c;
                    if(vManager.StateGlobal__c != null)
                        key = key + '/' + vManager.StateGlobal__c;
                    if(vManager.Metro_Area__c != null)
                        key = key+'/'+vManager.Metro_Area__c.toLowercase();
                    if(vManager.Zip_code__c != null) 
                        key = key + '/'+vManager.Zip_code__c;
                    if(vManager.Industry_Category__c != null)
                        key = key+'/'+vManager.Industry_Category__c;
                    
                    if(vManager.Tier__c == null) {
                        addPatchMap(patchMap, key, vManager);
                    }
                    else {
                        for(String tier : vManager.Tier__c.split(';')){
                            //key = key+'/'+tier;
                            addPatchMap(patchMap, key+'/'+tier, vManager);
                        }
                    }   
                }
            }
        }
        return patchMap;
    }

    public static String cleanPostalCode(String postalCode){
        String vString;
            if(postalCode!=null){               
                vString = postalCode.trim();
                if(vString.contains('-')){
                    String[] zipSplit = vString.split('-');
                    if(zipSplit.size()==2 && zipSplit[0].isNumeric() && zipSplit[1].isNumeric()){
                        return zipSplit[0];
                    }
                }
            }
            
        return escapeString(postalCode);
    }
    public static String escapeString(String vString){
        if(vString!=null){
            vString=vString.escapeJava();
            vString=String.escapeSingleQuotes(vString);
            vString=vString.replace('\\"', '\"');
        }           
        return vString;     
    }
    public static void addQuery(Map<String, String> queryMap, String key, String value1){
        if(value1!= Null && !value1.contains('null')){
            String value = String.escapeSingleQuotes(value1);
            if(!queryMap.containsKey(key)){
                queryMap.put(key, '\''+value+'\'');
            } else {
                if(!queryMap.values().contains('\''+value+'\'')){
                    queryMap.put(key, queryMap.get(key)+','+'\''+value+'\'');
                }
                
            }
        }
    }
    /**********************************************************************
     Utility Method for building the PatchMap
    ***********************************************************************/
    public static void addPatchMap(Map<String, List<PatchManager__c>> patchMap,String key, PatchManager__c vManager){
        if(key!=null && !key.contains('null')){
            if(patchMap.containsKey(key)){
                patchMap.get(key).add(vManager);
            }
            else 
                patchMap.put(key, new List<PatchManager__c>{vManager});
        }
    }

  public static Map<Id, PatchManager__c> assignLead(Map<String, List<PatchManager__c>> patchMap, List<Lead> vLeads){
        Map<Id, PatchManager__c> leadIdToPatchManager = new Map<Id, PatchManager__c>();
        
      system.debug('patchMap>>'+patchMap);
        //if(patchMap.size()>0){
        for(Lead vLead : vLeads){
            PatchManager__c vManager=null;
            String metroArea = vLead.Metro_Area__c != null ? vLead.Metro_Area__c.toLowercase() : '';
            String strL2AAccountTier = vLead.L2A_Parent_Account_Tier__c != null ? vLead.L2A_Parent_Account_Tier__c : vLead.L2AAccountTier__c;
            //country+statecode+zipcode+industrycategory+tier
            //country+statecode+zipcode+industrycategory
            //country+zipcode+industrycategory+tier
            //country+zipcode+industrycategory
            //
            //country+statecode+metro area+industrycategory+tier
            //country+statecode+metro area+industrycategory
            //
            //country+statecode+industrycategory+tier
            //country+statecode+industrycategory    
            //country+industrycategory+tier
            //country+industrycategory
            //
            //country+statecode+zipcode+tier
            ////country+zipcode+tier
            //country+statecode+metro area+tier
            //country+statecode+tier
            //country+tier
            //country+statecode+metro area
            //country+statecode
            //country
            if(patchMap.containsKey(vLead.Domain__c)) {
                vManager = patchMap.get(vLead.Domain__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c)) { //country+statecode+zipcode+industrycategory+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c)) { //country+statecode+zipcode+industrycategory
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c)) { 
                vManager = patchMap.get(vLead.Country+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c).get(0); //country+zipcode+industrycategory+tier
            } else if(patchMap.containsKey(vLead.Country +'/'+vLead.postalCode+'/'+vLead.Industry_Category__c)) { //country+zipcode+industrycategory
                vManager = patchMap.get(vLead.Country +'/'+vLead.postalCode+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+metroArea+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c)) { //country+statecode+metro area+industrycategory+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+metroArea+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+metroArea+'/'+vLead.Industry_Category__c)) { //country+statecode+metro area+industrycategory
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+metroArea+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c)) { //country+statecode+industrycategory+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c)) { //country+statecode+industrycategory
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c)) { //country+industrycategory+tier
                vManager = patchMap.get(vLead.Country +'/'+vLead.Industry_Category__c+'/'+vLead.L2AAccountTier__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.Industry_Category__c)) { //country+industrycategory
                vManager = patchMap.get(vLead.Country +'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+strL2AAccountTier)) { //country+statecode+zipcode+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+strL2AAccountTier).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.postalCode+'/'+strL2AAccountTier)) { //country+statecode+zipcode+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.postalCode+'/'+strL2AAccountTier).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+metroArea+'/'+strL2AAccountTier)) { //country+statecode+metro area+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+metroArea+'/'+strL2AAccountTier).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+strL2AAccountTier)) { //country+statecode+tier
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+strL2AAccountTier).get(0);
            }else if(patchMap.containsKey(vLead.Country+'/'+strL2AAccountTier)) { //country+tier
                vManager = patchMap.get(vLead.Country+'/'+strL2AAccountTier).get(0);
            }else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+metroArea)) { //country+statecode+metro area
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+metroArea).get(0);
            }else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode)) { 
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode).get(0);
            }else if(patchMap.containsKey(vLead.Country)) { //country
                vManager = patchMap.get(vLead.Country).get(0);
            }
            system.debug('vManager'+vManager);
            leadIdToPatchManager.put(vLead.Id, vManager); 
        }
        return leadIdToPatchManager;
    }
}