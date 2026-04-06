public with sharing class TriggerManager {

	public static ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());

	private static Map<String, LoopCount> loopCountMap = new Map<String, LoopCount>();
	public static Integer triggerDepthCount = 0;
	public static void resetTriggerCounter(String triggerObjectName) {
		if(loopCountMap.containsKey(triggerObjectName)){
			loopCountMap.get(triggerObjectName).reset();
		}
	}
	public static boolean isTriggerExecutionAllowed(String objectApiName) {
		boolean isAllowed =  (Trigger.isUpdate && loopCountMap.containsKey(objectApiName)) ? !loopCountMap.get(objectApiName).exceeded() : true;
		if(!isAllowed){
			System.debug(isAllowed + '\n\n' + objectApiName + ' Trigger is blocked. \n\n');
		}
		return isAllowed;
	}

	/**
	 * @description  Invoke trigger handler by existing instance. Usage: in trigger make call like  TriggerManager.invokeHandler(new ContactTriggerhandler());
	 */
	public static void invokeHandler(GenericTriggerHandler handler) {
		DateTime startTime = System.now();
		Long cpuLimitstart = Limits.getCpuTime();
		Long soqlLimitstart = Limits.getQueries();
		Long dmlLimitstart = Limits.getDMLStatements();
		String triggerObjectName = Trigger.isDelete ? Trigger.old[0].getSObjectType().getDescribe().getName() : Trigger.new[0].getSObjectType().getDescribe().getName();
		
		String triggerDetails = triggerObjectName + (Trigger.isBefore ? ' Before' : (Trigger.isAfter ? ' After' : '')) + (Trigger.isInsert ? ' Insert' : (Trigger.isUpdate ? ' Update' : (Trigger.isDelete? ' Delete' : ' SomethingElse')));
		
		Boolean isAfterInsertTrigger = Trigger.isAfter && Trigger.isInsert ; 
		Boolean isBeforeInsertEvent = Trigger.isBefore && Trigger.isInsert ;
		if(!loopCountMap.containsKey(triggerObjectName)){
			Integer mxloopCount = Integer.valueOf(disableBusinessLogicCS.Trigger_Max_Loop_Count__c);
			mxloopCount = (mxloopCount == null) ? 3 : mxloopCount;	
			loopCountMap.put(triggerObjectName, new TriggerManager.LoopCount(mxloopCount));
		}
		
		if (Trigger.isUpdate){
			if(Trigger.isBefore){
				loopCountMap.get(triggerObjectName).increment();
			}
		}

		Boolean isTriggerExecutionAllowed = isTriggerExecutionAllowed(triggerObjectName);
		   System.debug('\n\t\t' + triggerObjectName +'\tRUBRIK TRIGGER Initiated \t' + triggerDetails + ', isTriggerExecutionAllowed: ' + isTriggerExecutionAllowed + ', ' + loopCountMap.get(triggerObjectName) +  '\nTrigger~~~~: oldRecord: ' + Trigger.old + '\nTrigger~~~~: newRecord: ' + Trigger.new);

		if (isTriggerExecutionAllowed) {
            System.debug('\n\t\t' + triggerObjectName + '\tRUBRIK TRIGGER-EXECUTION STARTED:\t' + ++triggerDepthCount + ': ' +  triggerDetails +  ' at: ' + startTime);
			try {
				handler.invoke( Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUnDelete, Trigger.old, Trigger.new, Trigger.oldMap,Trigger.newMap);
				System.debug('\n~~~~ At the end of trigger \n~~~~: newRecord: ' + Trigger.new);
			} catch(Exception ex){
				List<sObject> objList = Trigger.isDelete ? Trigger.old : Trigger.new;
                String errorMsg = getGenericErrorMessage(ex, null);
                for (Integer i = 0; i < objList.size(); i++){
                    objList[i].addError(errorMsg);
                }
				System.debug('\n\t\t' + triggerObjectName + '\tRUBRIK TRIGGER-EXECUTION ERROR:\t' + errorMsg);
			}
            System.debug('\n\t\t' + triggerObjectName + '\tRUBRIK TRIGGER-EXECUTION FINISHED:\t' +  triggerDepthCount-- + ': ' + triggerDetails + ' at: '  + System.now()
			+ '\t Total time taken: ' + (System.now().getTime() - startTime.getTime()) + 'ms, \tCPU_TIME_TAKEN: ' + (Limits.getCpuTime() - cpuLimitstart) + ' ms.\tSOQL # ' + (Limits.getQueries() - soqlLimitstart) + ', DMLs #' + (Limits.getDMLStatements() - dmlLimitstart));
		}else{
			System.debug( '\n\t\t' + triggerObjectName + '\tRUBRIK Trigger Blocked:\t' + triggerDetails +  ' at: '  + System.now()
			+ '\t Total time taken: ' + (System.now().getTime() - startTime.getTime()) + 'ms, \tCPU_TIME_TAKEN: ' + (Limits.getCpuTime() - cpuLimitstart) + ' ms.\tSOQL # ' + (Limits.getQueries() - soqlLimitstart) + ', DMLs #' + (Limits.getDMLStatements() - dmlLimitstart));
		}
	}
		/**
	 * @description  Invoke trigger handler by existing instance. Usage: in trigger make call like  TriggerManager.invokeHandler(new ContactTriggerhandler());
	 */
	
	public static void invokeHandlerWithoutException(GenericTriggerHandler handler) {
		Long cpuLimitstart = Limits.getCpuTime();
		Long soqlLimitstart = Limits.getQueries();
		Long dmlLimitstart = Limits.getDMLStatements();
		String triggerObjectName = Trigger.isDelete ? Trigger.old[0].getSObjectType().getDescribe().getName() : Trigger.new[0].getSObjectType().getDescribe().getName();
		String triggerDetails = triggerObjectName + (Trigger.isBefore ? ' Before' : (Trigger.isAfter ? ' After' : '')) + (Trigger.isInsert ? ' Insert' : (Trigger.isUpdate ? ' Update' : (Trigger.isDelete? ' Delete' : ' SomethingElse')));
		DateTime startTime = System.now();
		System.debug('\n\t\t' + triggerObjectName + '\tRUBRIK TRIGGER Initiated \t' + triggerDetails + '\nTrigger~~~~: oldRecord: ' + Trigger.old + '\nTrigger~~~~: newRecord: ' + Trigger.new);
		System.debug('\n\t\t' + triggerObjectName + '\tRUBRIK TRIGGER-EXECUTION STARTED:\t' + ++triggerDepthCount + ': ' + triggerDetails +  ' at: ' + startTime);
		handler.invoke( Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUnDelete, Trigger.old, Trigger.new, Trigger.oldMap,Trigger.newMap);
		System.debug('\n\t\t' + triggerObjectName + '\tRUBRIK TRIGGER-EXECUTION FINISHED:\t' +  triggerDepthCount-- + ': ' + triggerDetails + ' at: '  + System.now()
		+ '\t Total time taken: ' + (System.now().getTime() - startTime.getTime()) + 'ms, \tCPU_TIME_TAKEN: ' + (Limits.getCpuTime() - cpuLimitstart) + ' ms.\tSOQL # ' + (Limits.getQueries() - soqlLimitstart) + ', DMLs #' + (Limits.getDMLStatements() - dmlLimitstart));
}
	

	public static String getGenericErrorMessage(Exception exp, String additionalMessage){
		String errDetails = '';
        String errMessage = '';
		if(exp != null && !String.isBlank(exp.getMessage())){
			errMessage = exp.getMessage();
			if(errMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION,')){
				errMessage = errMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1];
			}
			errDetails = exp.getStackTraceString();
		}
		errMessage = String.isBlank(additionalMessage) ? errMessage : additionalMessage + ' ' + errMessage;
		System.debug(LoggingLevel.DEBUG, '\n~~~~Error: ' + errMessage + ' \n' + errDetails);
		return errMessage;
	}

	public abstract class GenericTriggerHandler{

		public virtual void onAfterInsert(Map<ID, sObject> newRecordsMap) {}
		public virtual void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {}
		public virtual void onAfterDelete(Map<ID, sObject> oldRecordsMap) {}
		public virtual void onAfterUnDelete(List<sObject> newRecords) {}

		public virtual void onBeforeInsert(List<sObject> newRecords) {}
		public virtual void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {}
		public virtual void onBeforeDelete(Map<ID, sObject> oldRecordsMap) {}

		private void invoke(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete,
				List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordsMap, Map<ID, SObject> newRecordsMap){
			if(isBefore) {
				if (isInsert) {
					onBeforeInsert(newRecords);
				}else if (isUpdate) {
					onBeforeUpdate(oldRecordsMap, newRecordsMap);
				}else if (isDelete) {
					onBeforeDelete(oldRecordsMap);
				}
			}else if(isAfter) {
				if (isInsert){
					onAfterInsert(newRecordsMap);
				}else if (isUpdate){
					onAfterUpdate(oldRecordsMap, newRecordsMap);
				}else if (isDelete){
					onAfterDelete(oldRecordsMap);
				}else if (isUnDelete){
					onAfterUnDelete(newRecords);
				}
			}
		}
	}

	private class LoopCount {
        private Integer max;
		private Integer count;
		
        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }
        
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }
        
        public Boolean exceeded() {
            return this.max > 0 && this.count > this.max;
        }
        public void reset() {
            this.count = 0;
        }
    }
	public static String getFillerText(Integer iCount, String fillerText){
		String filler = '';
		for(Integer i = 1; i <= iCount; i++){
			filler += fillerText;
		}
		return filler;

	}
}