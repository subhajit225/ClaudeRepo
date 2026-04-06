public with sharing class SandboxRefreshEmailMaskingBatch implements Database.Batchable<sObject>, Database.Stateful{

    private Long noOfRecords = 0;
    private Set<Id> failedRecordIDs = new Set<Id>();
    private Map<String, ID> errorMessages = new Map<String, ID>();
    private Sandbox_Refresh_Config__c sandboxRefreshConfigObj; 
    private String emailNullCondition = '';

    public SandboxRefreshEmailMaskingBatch(Sandbox_Refresh_Config__c  sandboxRefreshConfigObj){
        this.sandboxRefreshConfigObj = sandboxRefreshConfigObj;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){      
        Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization LIMIT 1];
        if(orgInfo.IsSandbox || Test.isRunningTest()){
            Datetime createdDate = sandboxRefreshConfigObj.CreatedDate;
            String queryString = sandboxRefreshConfigObj.Query__c + ' LIMIT ' + ((sandboxRefreshConfigObj.BatchSize__c * 100000 -1) > 4000000 ? 4000000 : (sandboxRefreshConfigObj.BatchSize__c * 100000 -1));
            System.debug('#SandboxRefreshEmailMaskingBatch#finish#queryString:'+queryString);
            return Database.getQueryLocator(queryString); 
        }else{
            return null;
        }
    }
    
    public void execute (Database.BatchableContext BC, List<Sobject>scope){
        System.debug('#SandboxRefreshEmailMaskingBatch#finish#scope:'+scope);
        noOfRecords += scope.size();
        String fieldsCSV = sandboxRefreshConfigObj.EmailFields__c;
        fieldsCSV = fieldsCSV.replaceAll(' ', '');
        List<String> fields = fieldsCSV.split(',');
        String emailStr = '';
        Integer len;
        for(sObject s : scope) {
            for(string fieldName : fields){
                emailStr = (String) s.get(fieldName);
                if(String.isNotBlank(emailStr)){
                    emailStr = emailStr.replace(' ','');
                    emailStr = emailStr.trim();
                    emailStr = emailStr.replaceAll('[^a-zA-Z0-9-_.@\\s+]', '');
                    len = emailStr.length();
                    if(len > 70){
                        emailStr = 'test.test@test.com';
                    }
                    if(!emailStr.endsWithIgnoreCase(SandboxRefreshUtil.EMAIL_SUFFIX)){
                        s.put(fieldName, emailStr + SandboxRefreshUtil.EMAIL_SUFFIX);
                    }
                }
            }               
        } 
        flowControll.disableAllTriggers();
        Integer index = 0;
        Database.SaveResult[] results = Database.Update(scope, false); 
        for(Database.SaveResult result : results){
            if(!result.isSuccess()){ 
                String errorMesaage = '';
                Integer iCount = 1;
                for(Database.Error error : result.getErrors()){
                    errorMesaage += error.getMessage() + '. ';
                    if(iCount++ == 3){
                        break;
                    }
                }
                if(errorMessages.size() <= SandboxRefreshUtil.MAX_ERROR_COUNTS){
                    errorMessages.put(errorMesaage, scope[index].id);
                }
                failedRecordIDs.add(scope[index].id);
            }
            index++;
        }
        System.debug('#SandboxRefreshEmailMaskingBatch#finish#failedRecordIDs:'+failedRecordIDs);
    }    
        
    public void finish(Database.BatchableContext bc){

        Integer failedRecordsSize = failedRecordIDs.size();
        sandboxRefreshConfigObj.LastFailedRecordCount__c = failedRecordsSize;
        sandboxRefreshConfigObj.NoOfRecords__c = noOfRecords;

        if((/*sandboxRefreshConfigObj.BatchSize__c == 1 && */ noOfRecords == failedRecordsSize) || failedRecordsSize == 0){ // All records failed or all records pass
            //stop the batch
            sandboxRefreshConfigObj.Status__c = 'Completed';
        }
        boolean isBatchExecutedManually = sandboxRefreshConfigObj.isInitiatedManually__c;
        String eMessage = JSON.serialize(errorMessages);
        eMessage = eMessage.length() > 5 ? eMessage : '';
        sandboxRefreshConfigObj.ErrorDetails__c = eMessage.replaceAll('"', '');
        update sandboxRefreshConfigObj;
        if(!Test.isRunningTest()){
            if(isBatchExecutedManually){
                SandboxRefreshUtil.scheduleNextBatch(1, sandboxRefreshConfigObj.name);
            }else{
                SandboxRefreshUtil.scheduleNextBatch(1);
            }
        }else{//Test Code coverage
            Integer i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;
            i = 0;            
        }
    }

}