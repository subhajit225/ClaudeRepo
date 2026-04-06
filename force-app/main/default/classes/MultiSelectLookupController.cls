public class MultiSelectLookupController {

    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, List<sObject> ExcludeitemsList,String whereclauseFilter,String allowedRecordType) {
        String searchKey =  searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
        Set<Id> profileIdSet = new Set<Id>();
        List<string> lstExcludeitems = new List<string>();
        if(ExcludeitemsList != null) {
            for(sObject item : ExcludeitemsList ){
                lstExcludeitems.add(item.id);
            }
        }
        
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 and exclude already selected records  
        String sQuery ='';
        if(ObjectName.toLowerCase() == 'order') {
            sQuery =  'select id, OrderNumber from ' + String.escapeSingleQuotes(ObjectName) + ' where OrderNumber LIKE: searchKey AND Id NOT IN : lstExcludeitems AND Have_PS_Products__c =true order by createdDate DESC limit 5';
        }
        else if(ObjectName.toLowerCase() == 'case') {
            sQuery =  'SELECT Id, CaseNumber, Account.Name FROM ' + String.escapeSingleQuotes(ObjectName) + ' WHERE ';
            if(!String.isBlank(searchKeyWord)) {
                sQuery =  sQuery + 'CaseNumber LIKE: searchKey ORDER BY CreatedDate DESC LIMIT 5';
            }
            else {
                sQuery =  sQuery + 'LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT 5';
            }
        }
        else if(ObjectName.toLowerCase() == 'survey') {
            sQuery =  'SELECT Id, Name, DeveloperName FROM ' + String.escapeSingleQuotes(ObjectName) + ' WHERE ActiveVersion.Name != null ';
            if(!String.isBlank(searchKeyWord)) {
                sQuery =  sQuery + 'AND Name LIKE: searchKey ORDER BY CreatedDate DESC LIMIT 5';
            }
            else {
                sQuery =  sQuery + 'ORDER BY Name LIMIT 5';
            }
        }
        else if(ObjectName.toLowerCase() == 'group') {
             List<QueueSobject> queueSupportedList = [Select Id,QueueId  from QueueSobject q where q.SobjectType='Lead'];
            set<String> queuesetIds = new set<String>();
            if(queueSupportedList.size()>0){
                
                for(QueueSobject rsQueue:queueSupportedList) {
                    queuesetIds.add(rsQueue.QueueId);
                    
                }
            }
              system.debug('sQuery>>'+queuesetIds);
            if(queuesetIds.size()>0) {
            String typeVal ='Queue';
            sQuery =  'SELECT Id, Name  FROM ' + String.escapeSingleQuotes(ObjectName) + ' WHERE type =:typeVal AND Id IN :queuesetIds ';
            if(!String.isBlank(searchKeyWord)) {
                sQuery =  sQuery + 'AND Name LIKE: searchKey ORDER BY CreatedDate DESC LIMIT 5';
            }
            else {
                sQuery =  sQuery + 'ORDER BY Name LIMIT 5';
            }
            
        	}
        }
        else if(ObjectName.toLowerCase() == 'user') {
            boolean activeVal =true;
             sQuery =  'SELECT Id, Name  FROM ' + String.escapeSingleQuotes(ObjectName) + ' WHERE isActive =true AND Profile.UserLicense.Name=\'Salesforce\' ';
            if(!String.isBlank(searchKeyWord)) {
                sQuery =  sQuery + 'AND Name LIKE: searchKey ORDER BY CreatedDate DESC LIMIT 5';
            }
            else {
                sQuery =  sQuery + 'ORDER BY Name LIMIT 5';
            }
        }else if(ObjectName.toLowerCase() == 'channelprogramlevel' && !string.isBlank(whereclauseFilter)) {
            List<string> progNameArr = new List<string>();
            whereclauseFilter = whereclauseFilter.removeEnd(';');
            progNameArr = whereclauseFilter.split(';');
            sQuery =  'SELECT Id, Name,ProgramId,Program.Name  FROM ' + String.escapeSingleQuotes(ObjectName);
            sQuery =  sQuery + ' Where	Program.Name IN: progNameArr AND Id NOT IN : lstExcludeitems';
            if(!String.isBlank(searchKeyWord)) {
                sQuery =  sQuery + ' AND Name LIKE: searchKey ORDER BY CreatedDate DESC LIMIT 5';
            }
            else {
                sQuery =  sQuery + ' ORDER BY Name LIMIT 5';
            }
        }
        else {
            sQuery =  'select id, Name,Owner.Name from ' + String.escapeSingleQuotes(ObjectName) + ' where Name LIKE: searchKey AND Id NOT IN : lstExcludeitems';
            if(!string.isBlank(whereclauseFilter) && whereclauseFilter == 'isContactId=null'){
                Map<Id,Profile> profileIds = new Map<id,profile>([SELECT Id,UserLicenseId FROM Profile where UserLicenseId  in (SELECT Id FROM UserLicense where name ='Salesforce' OR name ='Salesforce Platform')]);
                profileIdSet.addAll(profileIds.Keyset());
                sQuery = sQuery+' AND profileId in:profileIdSet AND isActive=true';
            }
            if(!string.isBlank(allowedRecordType)) {
                List<String> recordTypes = new List<String>();
                if(allowedRecordType.contains(',')){
                	recordTypes = allowedRecordType.split(',');
                }else{
                    recordTypes.add(allowedRecordType);
                }
                system.debug('recordTypes-->'+recordTypes);
              sQuery = sQuery+' AND RecordType.Name in:recordTypes';  
                
            }
            
            sQuery = sQuery+' order by name, createdDate DESC limit 5';
        }
        
        system.debug('sQuery>>'+sQuery);
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            if(Schema.Order.getSObjectType() == obj.getSObjectType()){
                Order myorder = (Order)obj; //Here you will have to make sure your sObject is of type Account
                myorder.Name = myorder.OrderNumber ;
                returnList.add(myorder);
            }else if(ObjectName.toLowerCase() == 'channelprogramlevel'){
                ChannelProgramLevel mycpl = (ChannelProgramLevel)obj;
                mycpl.Name = mycpl.Program.Name+'-'+mycpl.Name;
                returnList.add(mycpl);
            }
            else {
                returnList.add(obj);
            }
            
        }
        
        return returnList;
    }
    
    @AuraEnabled
    public static List < String > getselectOptions(sObject currentObject, string field) {
        List < String > allOpts = new list < String > ();
        // Get the object type of the SObject.
        Schema.sObjectType objType = currentObject.getSObjectType();
        
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
        map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values =
            fieldMap.get(field).getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a: values) {
            allOpts.add(a.getValue());
        }
        return allOpts;
    }
}