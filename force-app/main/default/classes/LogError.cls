/********************************************************************
  Developer : Rubrik
  Date : 14/06/2019
  Description : Class to cature error logs in a transaction
****************************************************************************/
Public class LogError {

    // To capture generic exceptions
     public static Custom_Error_Log__c CreateGenericErrorLog(String ClassName,Exception excep ,string Functionality){
          return logEtmErrorids( ClassName, excep, '' , Functionality);
     }

     public static Custom_Error_Log__c logEtmErrorids(String ClassName,Exception excep,String strIds ,string Functionality){
          Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
          CaptureError.Class__c = ClassName;
          CaptureError.Functionality__c = Functionality;
          if(excep != NULL){
          CaptureError.Exception_Message__c= excep.getMessage() + strIds;
          CaptureError.ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+excep.getTypeName(),'Trace : '+excep.getStackTraceString()});
          }
          return CaptureError;
     }
    
     
     // To capture the records failed during DML operation
     public static Custom_Error_Log__c CreateDMLErrorLog(String ClassName,String RecIds,String message,string Functionality){
          Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
          CaptureError.Class__c = ClassName ;
          CaptureError.Functionality__c = Functionality;
          CaptureError.Exception_Message__c= message;
          CaptureError.FailedRecords__c = RecIds ;
          return CaptureError;
     }
	@future
    public static void logCustomError(String className, String errorMsg, String errorDetail, String functionality){
          Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
          CaptureError.Class__c = className;
          CaptureError.Functionality__c = functionality;
          CaptureError.Exception_Message__c= errorMsg;
          CaptureError.ErrorTrace__c= errorDetail;
          insert CaptureError;
     }
  /**
* @description  constructor
*/    
     public void LogError(){}
 /**
* @description  To capture the records failed during insert/update DML operation
* @param sobjectRecords
* @param srList
* @param className
* @param functionality
*/
     public static void createDMLErrorLog(List<SObject> sobjectRecords, List<Database.SaveResult> srList, String className,String functionality){
          map<string,Custom_Error_Log__c> errorLogs = new map<string,Custom_Error_Log__c>();
          Integer i = 0;
          for (Database.SaveResult sr : srList) {
               if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                         if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage()) && errorLogs.get(err.getMessage()).FailedRecords__c != null){ 
                              if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                              errorLogs.get(err.getMessage()).FailedRecords__c += ','+sobjectRecords[i].Id;              
                         }
                         else{
                              errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = functionality, Exception_Message__c =  (err.getMessage()+':'+err.getFields()),Class__c = className,FailedRecords__c=sobjectRecords[i].Id));
                         }
                         
                    }
               }
               i++;
          }
          if(!errorLogs.isEmpty()) insert errorLogs.values();
     }
/**
* @description  To capture the records failed during delete DML operation
* @param sobjectRecords 
* @param drList
* @param className
* @param functionality
*/
     public static void deleteDMLErrorLog(List<SObject> sobjectRecords, List<Database.DeleteResult> drList, String className,String functionality){
          map<string,Custom_Error_Log__c> errorLogs = new map<string,Custom_Error_Log__c>();
          Integer i = 0;
          for (Database.DeleteResult dr : drList) {
               if (!dr.isSuccess()) {
                    for(Database.Error err : dr.getErrors()) {
                         if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                              if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                              errorLogs.get(err.getMessage()).FailedRecords__c += ','+sobjectRecords[i].Id;              
                         }
                         else{
                              errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = functionality, Exception_Message__c =  (err.getMessage()+':'+err.getFields()),Class__c = className,FailedRecords__c=sobjectRecords[i].Id));
                         }
                         
                    }
               }
               i++;
          }
          if(!errorLogs.isEmpty()) insert errorLogs.values();
     }
/**
* @description  To capture the records failed during insert/update DML operation //SAL25-717
* @param sobjectRecords 
* @param srList
* @param className
* @param functionality
* @return errorLogs records
*/
     public static List<Custom_Error_Log__c> createDMLErrorLogWithRetrunType(List<SObject> sobjectRecords, List<Database.SaveResult> srList, String className,String functionality){
          map<string,Custom_Error_Log__c> errorLogs = new map<string,Custom_Error_Log__c>();
          Integer i = 0;
          for (Database.SaveResult sr : srList) {
               if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                         if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage()) && errorLogs.get(err.getMessage()).FailedRecords__c != null){ 
                              if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                              errorLogs.get(err.getMessage()).FailedRecords__c += ','+sobjectRecords[i].Id;              
                         }
                         else{
                              errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = functionality, Exception_Message__c =  (err.getMessage()+':'+err.getFields()),Class__c = className,FailedRecords__c=sobjectRecords[i].Id));
                         }
                         
                    }
               }
               i++;
          }
          if(!errorLogs.isEmpty()) insert errorLogs.values();
          return errorLogs.values();
     }
/**
* @description To capture the records failed during insert/update DML operation - SAL26-73
* @param sobjectRecords 
* @param srList
* @param className
* @param functionality
* @return errorLogs records
*/
     public static List<Custom_Error_Log__c> createUpsertDMLErrorLogWithRetrunType(List<SObject> sobjectRecords, List<Database.UpsertResult> srList, String className,String functionality){
          map<string,Custom_Error_Log__c> errorLogs = new map<string,Custom_Error_Log__c>();
          Integer i = 0;
          for (Database.UpsertResult sr : srList) {
               if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                         if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage()) && errorLogs.get(err.getMessage()).FailedRecords__c != null){ 
                              if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                              errorLogs.get(err.getMessage()).FailedRecords__c += ','+sobjectRecords[i].Id;              
                         }
                         else{
                              errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = functionality, Exception_Message__c =  (err.getMessage()+':'+err.getFields()),Class__c = className,FailedRecords__c=sobjectRecords[i].Id));
                         }
                         
                    }
               }
               i++;
          }
          if(!errorLogs.isEmpty()) insert errorLogs.values();
          return errorLogs.values();
     }
}