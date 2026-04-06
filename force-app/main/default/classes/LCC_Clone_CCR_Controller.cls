public class LCC_Clone_CCR_Controller {
    public static List<msgWrapper> msgWrapperList;
@AuraEnabled
    public static CCR__c getRecord(string recId){
        Schema.DescribeSObjectResult objDescribe = CCR__c.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        String commaSepratedFields = String.join(new List<String>(fieldMap.keySet()), ',');
        String query = 'SELECT ' + String.escapeSingleQuotes(commaSepratedFields) + ',RecordType.Name FROM CCR__c WHERE Id = \''+ String.escapeSingleQuotes('' + recId) +'\'';
        CCR__c ccrRec =  Database.query(query); 
        ccrRec.OwnerId = userInfo.getUserId();
        return ccrRec;
    }
@AuraEnabled
    public static boolean getsectionVisibility(){
       Boolean show = Schema.sObjectType.CCR__c.fields.Internal_Notes__c.isAccessible();
        return show;
    }    
  @AuraEnabled
    public static List<msgWrapper> saveRecord(CCR__c ccrRecord){  
        string message = '';
        msgWrapperList = new List<msgWrapper>();
        ccrRecord.Id = null;
        try{
            system.debug('@@ in...');
        	insert ccrRecord;
        	msgWrapperList.add(new msgWrapper('success',ccrRecord.Id,ccrRecord.Name));
        }catch(Exception e){
          if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Error : '+e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : '+e.getMessage();
            }
            msgWrapperList.add(new msgWrapper(message,'',''));
            system.debug('@@ Exception occurred '+e.getMessage());
        }
        return msgWrapperList;
    }
    public class msgWrapper{
        @AuraEnabled public string message;
        @AuraEnabled public string recId;
        @AuraEnabled public string recName;
        msgWrapper(string message1,string recId1,string recName1){
            message = message1;
            recId = recId1;
            recName = recName1;
        }
    }
}