public without sharing class PC_PartnerOnboardingRequestContoller {
    private static List<string> pickListValues;
    private static boolean accountAlreadyExists;

    @AuraEnabled
    public static Map<String,List<String>> getPicklistValues(List<String> fieldAPINamesList)
    {
        system.debug('fieldAPINamesList-->'+fieldAPINamesList);
        Map<String, List<String>> fieldWithPicklistValues = new Map<String, List<String>>();
        
        try{
            Schema.sObjectType objType = Partner_Onboarding_Request__c.getSObjectType();
            Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
            for(String fieldName : fieldAPINamesList){
                String picklistFieldAPI = fieldName.toLowerCase();
                Schema.SObjectField picklistField = objFieldMap.get(picklistFieldAPI);
                List<Schema.PicklistEntry> fieldValues = picklistField.getDescribe().getPicklistValues();
                List<String> picklistValues = new List<String>();
                
                for (Schema.PicklistEntry pEntry : fieldValues) 
                {                  
                    picklistValues.add(pEntry.getLabel()+';'+pEntry.getValue());
                }
                fieldWithPicklistValues.put(fieldName, picklistValues);
            }
        }
        catch(Exception e){
            system.debug('Exception occured-->'+e.getMessage()); 
        }
        return fieldWithPicklistValues;
    }
    
    //Pass dependent field parameter e.g.: Account.YourDependentField__c
    @AuraEnabled
    public static Map<String, Map<String,String>> getDependentPicklistValues() {
        Schema.sObjectField dependToken = Partner_Onboarding_Request__c.StateProvince__c;
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, Map<String,String>>();
        }
        
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,Map<String,String>> dependentPicklistValues = new Map<String,Map<String,String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                    String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null
                         ?   (Object) (index == 1)
                         :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new Map<String,String>());
                    }
                    dependentPicklistValues.get((String) controlValue).put(entry.getLabel(),entry.getValue());
                }
            }
        }
        system.debug('-->'+dependentPicklistValues);
        return dependentPicklistValues;
    }
    @AuraEnabled
    public static List<string> getPicklistValues(string fieldName){
        try{
            system.debug(fieldName);
            Schema.sObjectType objType = Partner_Onboarding_Request__c.getSObjectType();
            String pickFieldAPI = fieldName.toLowerCase();
            Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
            Schema.SObjectField pickField = objFieldMap.get(pickFieldAPI);
            List<Schema.PicklistEntry> fieldValues = pickField.getDescribe().getPicklistValues();
            pickListValues = new List<string>();
            for (Schema.PicklistEntry a : fieldValues) {
                pickListValues.add(a.getLabel()+';'+a.getValue());
            }
        }catch (Exception e){
            system.debug('Exception occured '+e.getMessage()+ ' at line number '+e.getLineNumber());
        }
        system.debug('## Options'+ pickListValues);
        return pickListValues;
    }

    @AuraEnabled
    public static List<String> getDistributorValues(List<string> territorySelectedValue){
        List<Account> accList = new List<Account>();
        List<String> selValues = new List<String>();
        system.debug('@@ territorySelectedValue'+ territorySelectedValue);
        for(String str : territorySelectedValue){
            String temp ='\''+Str+'\'';
            system.debug(temp);
            selValues.add(temp);
        }
        String values = String.join(selValues,',');
        system.debug(values);
        String query = 'Select Id,Name from Account where Territory__c INCLUDES ('+ String.escapeSingleQuotes(values) +') AND  type = \'Distributor\' AND Partner_Agreement_Status__c = \'Signed - Active\' ';
        system.debug('@@ '+query);
        if(!String.isBlank(values)){
            accList = Database.query(query);
            //accList = [select Id,Name from Account where Territory__c INCLUDES () AND  type = 'Distributor' AND Partner_Agreement_Status__c = 'Signed - Active'];
        }
        pickListValues = new List<String>();
        for(Account a : accList){
            pickListValues.add(a.Name+';'+a.Id);
        }
        system.debug('@@ Options'+ pickListValues);
        return pickListValues;
    }

    @AuraEnabled
    public static String savePartnerOnboard(Partner_Onboarding_Request__c PO_Request){
        String flag = 'success';
        system.debug('in');
        Map<String,String> ownersMaps = new Map<String,String>();
        Map<String, List<PatchManager__c>> patchMap = new Map<String, List<PatchManager__c>>();
        List<Partner_Onboarding_Request__c> lstPOR = new List<Partner_Onboarding_Request__c>();

        Id resellerRecTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
        Id serviceDeliveryRecTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();

        try {
            if(PO_Request.PartnerType__c != 'Alliance Partner'){
                PO_Request.Agreed_Term_Conditions__c = true;
            }
            //Distributor Assignment
            if(PO_Request.Distributor__c == '' || PO_Request.Distributor__c == '--None--'){
                PO_Request.Distributor_Account__c = null;
            }else{
                PO_Request.Distributor_Account__c = PO_Request.Distributor__c;
            }
            //Record Type Assignment
            if(PO_Request.PartnerType__c == 'MSP'){
                PO_Request.RecordTypeId = serviceDeliveryRecTypeId;
            }else if(PO_Request.PartnerType__c == 'Reseller' || PO_Request.PartnerType__c == 'MSP-Reseller'){
                PO_Request.RecordTypeId = resellerRecTypeId;
            }

            PO_Request.Partner_Onboarding_Status__c ='Unassigned';
            PO_Request.Distributor__c = '';
            System.debug('Segment'+PO_Request.Segment__c);
            //PO_Request.Segment__c = segment;

            lstPOR.add(PO_Request);

            if(!duplicateContactCheck(PO_Request)){
                if(!String.isBlank(PO_Request.Company_Name__c)){
                    system.debug('@@ PatchManager.ROUTE_ON_INSERT_PARTNER '+PatchManager.ROUTE_ON_INSERT_PARTNER);
                   /* if(PatchManager.ROUTE_ON_INSERT_PARTNER){                        
                        patchMap = PatchManager.getPatchMap(lstPOR, PatchManager.PARTNER_ONBOARDING);
                        PatchManager.assignPartner(patchMap, PO_Request);
                    }else{
                        PO_Request.OwnerId = label.Unassigned_Partner_Request_Queue_Id;
                    }                   
                    system.debug('@@ PO_Request.OwnerId '+PO_Request.OwnerId);*/
                    Database.SaveResult sr = Database.insert(PO_request,false);

                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted PO_Request. PO_Request ID: ' + sr.getId());
                        pc_pactsafecalloutcontroller.callpactsafe(sr.getId(),PO_Request.PartnerType__c,PO_Request.email__c);

                        flag = 'success';
                    }else {
                        // Operation failed, so get all errors
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('PO_Request fields that affected this error: ' + err.getFields());
                            flag = 'Error while saving onboarding';
                        }
                    }
                }
            } else{
                flag = 'Account record already Exists';
            }
            return flag;
        }catch(Exception e) {
            flag = 'Error while saving';
            system.debug('Exception occured '+e.getMessage()+ ' at line number '+e.getLineNumber()+' ' +e.getCause());
            return flag;
        }
    }

    public static boolean duplicateContactCheck(Partner_Onboarding_Request__c PO_Request){
        accountAlreadyExists = false;
        String email = PO_Request.email__c;
        String companyDomain = '';
        List<String> domain = new List<string>();
        if(!String.isBlank(email) && email.contains('@')){
            domain = email.split('@');
            companyDomain = '%'+domain[1]+'%';
        }
        system.debug('@@ companyDomain '+companyDomain);
            if(!string.isBlank(PO_Request.Website__c)){
                List<Partner_Onboarding_Request__c> PORecord = new List<Partner_Onboarding_Request__c>();
                PORecord =  [SELECT Id,name,Email__c,Partner_Onboarding_Status__c
                            FROM Partner_Onboarding_Request__c
                            WHERE Website__c =: PO_Request.Website__c AND partnertype__c =: PO_Request.partnertype__c AND  Partner_Onboarding_Status__c != 'Rejected' and country__c =:PO_Request.country__c];
                if(PORecord != null && PORecord.size() > 0){
                    accountAlreadyExists = true;
                }else if(!accountAlreadyExists){
                    //List<User> userRecord = new List<User>();
                    List<Account> accRecord =  new List<Account>();

                    if(!String.isBlank(companyDomain)){
                        accRecord = [SELECT ID,Name
                                    FROM Account
                                    WHERE Type =: PO_Request.partnertype__c AND billingcountry =: PO_Request.country__c AND RecordType.Name = 'Partner/Distributor' AND (CM_Parent_Domain_Name__c LIKE: companyDomain OR Website LIKE: companyDomain)];
                        if(accRecord != null && !accRecord.isEmpty()){
                            accountAlreadyExists = true;
                        }
                        /*userRecord = [SELECT id,name,Profile.Name,contact.Email,account.type
                                        FROM user
                                        WHERE (Profile.Name = :label.Rubrik_Partner_Community_User OR Profile.Name = :label.Rubrik_Partner_Community_Manager) AND account.type = :PO_Request.partnertype__c AND contact.Email LIKE: companyDomain  AND isActive=true AND account.billingcountry =:PO_Request.country__c];
                        system.debug('@@ userRecord '+userRecord);
                        if(userRecord != null && !userRecord.isEmpty()){
                            accountAlreadyExists = true;
                        }*/
                    }
                }
                else{
                    accountAlreadyExists= false;
                }
            }
        return accountAlreadyExists;
    }

    @AuraEnabled
    public static Map<String,List<String>> getDependentMap(string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        List<String> finalvalues = new List<string>();

        Schema.sObjectType objType = Partner_Onboarding_Request__c.getSObjectType();
        if (objType==null){
            return objResults;
        }

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;
        }

        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);

        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry ple : contrEntries) {
            String value = ple.getValue();
            objResults.put(value, new List<String>());
            controllingValues.add(value);
        }

        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    string str = plew.value+';'+label;
                    objResults.get(controllingValues.get(i)).add(str);
                }
            }
        }
        //finalvalues = objResults.get(controllinglabel);
        return objResults;
    }

    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';

    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){
        }
    }
    @AuraEnabled
    public static List<string> getDistributorNames(string sellingCountry){
        Set<string> disNames = new Set<string>();
        List<string> distNames = new List<string>();
        Set<string> acctIds = new Set<string>();
        List<Account> accList = new List<Account>();
        List<Contract> contList = new List<Contract>();
        Date d = system.today();
        string accIdName;
        system.debug('@@ sellingCountry '+sellingCountry);
        contList = [select Id,Territory_Country__c,EndDate,AccountId,Account.Name from Contract where Territory_Country__c INCLUDES(:sellingCountry) AND /*(Agreement_Type__c='Addendum' OR Agreement_Type__c ='Distributor')*/ Agreement_Type__c ='Distributor' AND Contract_Status__c='Active' order by EndDate DESC];
        system.debug('@@ contList '+contList);
        for(Contract con : contList){
            if((acctIds.isEmpty() || (!acctIds.isEmpty() && !acctIds.contains(con.AccountId)))){
                accIdName = con.Account.Name+';'+con.AccountId;
                disNames.add(accIdName);
            }
        }
        system.debug('@@ disNames '+disNames);
        distNames.addAll(disNames);
        return distNames;
    }
    @AuraEnabled
    public static List<string> getUSDistributorNames(string segment){
        Set<string> disNames = new Set<string>();
        List<string> distNames = new List<string>();
        List<Account> accList = new List<Account>();
        set<String> accNames = new set<String>();

        system.debug('@@ segment '+segment);
        if(!string.isBlank(segment) && segment.contains('Commercial/Enterprise')){
            accNames.add('Arrow ECS North America (Disti)');
            accNames.add('Ingram Micro US');//PRIT24-229
        }
        else if(!string.isBlank(segment) && segment.contains('Federal')){
            accNames.add('Carahsoft Technology Corp.');
            accNames.add('Ingram Micro US');//PRIT24-229
        }
        else if(!string.isBlank(segment) && segment.contains('SLED')){
            accNames.add('Arrow ECS North America (Disti)');
            accNames.add('Carahsoft Technology Corp.');
            accNames.add('Ingram Micro US');//PRIT24-229
        }
        accList = [select Id,Name from Account where Name IN:accNames];
        system.debug('@@ accList '+accList);
        string accIdName;
        for(Account acc : accList){
            accIdName = acc.Name+';'+acc.Id;
            disNames.add(accIdName);
        }
        system.debug('@@ disNames '+disNames);
        distNames.addAll(disNames);
        return distNames;
    }
}