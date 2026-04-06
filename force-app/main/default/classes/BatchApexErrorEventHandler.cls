public with sharing class BatchApexErrorEventHandler {
    public BatchFailureEmailService batchFailureInstance = new BatchFailureEmailService();
    public void onAfterInsert(List<BatchApexErrorEvent> newList){
        // Get Apex class name
        batchFailureInstance.getClassInfo(newList);
    }


}