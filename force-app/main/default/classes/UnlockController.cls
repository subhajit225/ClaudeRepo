public with sharing class UnlockController { 
	@AuraEnabled
    public static InitWrapper unlockCCR(Id recordId){
        InitWrapper ir = new InitWrapper();
        Boolean isLocked = Approval.isLocked(recordId);
        if(!isLocked){
            ir.isError = true;
            ir.errMsg = 'Record is already unlocked.';
            return ir;
        }
        String sObjectName = recordId.getSObjectType().getDescribe().getName();

        String baseQuery = 'SELECT Id FROM '+sObjectName+' WHERE Id = \''+recordId+'\'';
        system.debug('baseQuery..!'+baseQuery);
        
        List<SObject> records = Database.query(baseQuery);
                
        Approval.UnLockResult[] lrList = Approval.Unlock(records, false);
        for(Approval.UnlockResult lr : lrList) 
        {
            if (lr.isSuccess()) {
                ir.isError = false;
                ir.errMsg = 'Record unlocked successfully.';
            }
            else 
            {
                list<String> errors = new list<String>();
                for(Database.Error err : lr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Quote fields that affected this error: ' + err.getFields());
                    errors.add(err.getMessage());
                }
                ir.isError = true;
                ir.errMsg = 'Error: '+String.join(errors, '. ');
            }
        }
        return ir;
    }
    public class InitWrapper
    {
        @AuraEnabled public Boolean isError;
        @AuraEnabled public String errMsg;
    }
}