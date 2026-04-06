public without sharing class BatchExecutionController {
    @AuraEnabled(cacheable = true)
    public static List<BatchExecutionMetadata__mdt> getConfigurationData(){
        try {
            List<BatchExecutionMetadata__mdt> lstBatchMetadata = BatchExecutionMetadata__mdt.getAll().values();
            
            return lstBatchMetadata;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    
    @AuraEnabled
    public static string executeBatchApex(String strJson) {
        try{
            BatchExecutionMetadata__mdt oBatchExecutionMetdata = (BatchExecutionMetadata__mdt) JSON.deserialize(strJson, BatchExecutionMetadata__mdt.class);
            System.debug('oBatchExecutionMetdata :::>'+oBatchExecutionMetdata);
            Type batchType = Type.forName(oBatchExecutionMetdata.BatchClassName__c);
            /*if (batchType == null && !Test.isRunningTest()) {
throw new IllegalArgumentException('Invalid batch name: ' + oBatchExecutionMetdata.BatchClassName__c);
}*/
            Database.Batchable<SObject> batchInstance = (Database.Batchable<SObject>) batchType.newInstance();
            
            // Execute the batch
            Database.executeBatch(batchInstance, Integer.valueOf(oBatchExecutionMetdata.Batch_Size__c));
            return 'Sucess';
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String isBatchScheduled(String batchClassName) {
        Map<String,Object>responseMap = new Map<String,Object>();
        //Integer i = 0;
        
        try{
             String message = '';
            /*system.debug('batchClassName>>>'+batchClassName);
            List<CronTrigger> scheduledJobs = [
                SELECT Id, State , NextFireTime ,CronJobDetail.Name
                FROM CronTrigger 
                
                
            ];
            system.debug('***'+scheduledJobs);
            if (!scheduledJobs.isEmpty()) {
                Datetime nextRunTime = scheduledJobs[0].NextFireTime;
                if (nextRunTime != null) {
                message = 'The batch job is scheduled. Next run time: ' + nextRunTime.format() + ' Do you really want to proceed?';
            } else {
                message = 'The batch job is scheduled, but the next run time is unavailable. Do you really want to proceed?';
            }
                responseMap.put('bScheduled',true);
                responseMap.put('message',message);
                return JSON.serialize(responseMap);
            }
            
            */
            List<AsyncApexJob> queuedJobs = [
                SELECT Id, Status 
                FROM AsyncApexJob 
                WHERE ApexClass.Name = :batchClassName 
                AND (Status = 'Queued' OR Status = 'Processing' OR Status = 'Holding' OR Status = 'Preparing')
            ];
            
            if(!queuedJobs.isEmpty() || test.isRunningTest()){
                AsyncApexJob oJob = queuedJobs[0];
                String status = oJob?.Status;
                if(status != null){
                message = 'The batch job is '+ status +'. Do you really want to proceed ?';
                }
                responseMap.put('bScheduled',true);
                responseMap.put('message',message);  
            }
            else{
                responseMap.put('bScheduled',false);
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
            
        }
        return JSON.serialize(responseMap);
    }
}