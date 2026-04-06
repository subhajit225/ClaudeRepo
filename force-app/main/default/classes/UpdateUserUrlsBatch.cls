/**
* @File Name : UpdateUserUrlsBatch.cls
* @Test Class : UpdateUserUrlsControllerTest
* @description : To update the user urls
* @Modification Log :
************************************Change Logs ***********************************************
* User Story 			Modified By          	Date                     Description
* CS21-3349				Shailesh Kumar	 	    April 28, 2025			 Created this class
* CS21-3349				Shailesh Kumar	 	    May 14, 2025			 ApexPMD issues resolved
********************Change Logs Ends***********************************************************
**/

public with sharing class UpdateUserUrlsBatch implements Database.Batchable<sObject>,Schedulable {
	public String query;
	/**
	* @description constructor
	* @param customQuery The query to fetch the records to process
	*/
	public UpdateUserUrlsBatch(String customQuery){
		this.query = customQuery;
	}
	/**
	* @description 
	* The start method of the batch class that defines the scope of records to be processed.
	* It generates a query locator based on the provided `query` string, or defaults to a 
	* predefined query if no custom query is provided. This method is called by the 
	* Apex batch framework to fetch records for processing.
	*
	* @param BC The batchable context for the batch execution.
	* @return Database.QueryLocator A query locator that determines the scope of records to process.
	*/
	public Database.QueryLocator start(Database.BatchableContext BC){
		if(String.isBlank(query))
			query='SELECT Id, User__c,Url__c,Is_Updated__c,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM User_Info__c WHERE Is_Updated__c = false ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(query);
    }

    /**
	* @description 
	* The execute method of the batch class that processes a list of records in batches.
	* It updates the corresponding User records with calendar URLs from User_Info__c and 
	* marks the records as updated. This method is called by the Apex batch framework for each 
	* batch of records.
	*
	* @param BC The batchable context for the batch execution.
	* @param scope The list of User_Info__c records to process in the current batch.
	*/
    public void execute(Database.BatchableContext BC, List<sObject> scope){
		Map<Id,User_Info__c> userIdToUserInfoMap = new Map<Id,User_Info__c>();
		List<User_Info__c> updateUserInfoRecords = new List<User_Info__c>();
		List<User> userList = new List<User>();
		List<User> userListToUpdate = new List<User>();
		if(scope!=null && !scope.isEmpty()){
			for(User_Info__c obj : (List<User_Info__c>)scope){
                obj.Is_Updated__c = true;
                updateUserInfoRecords.add(obj);
				userIdToUserInfoMap.put(obj.User__c, obj);
			}
			userList = [SELECT Id,Calendar_booking_URL__c,Automated_time_off_case_routing__c,Destination_queue_for_automated_time_off__c FROM User WHERE isActive =true AND ID IN: userIdToUserInfoMap.keySet()];//add new field for url on User Object
		}
		
		if(!userList.isEmpty()){
			for(User userObj : userList){
				if(userIdToUserInfoMap.containsKey(userObj.Id)){
					if(String.isNotBlank(userIdToUserInfoMap.get(userObj.Id).Url__c))
						userObj.Calendar_booking_URL__c = userIdToUserInfoMap.get(userObj.Id).Url__c;
					if(String.isNotBlank(userIdToUserInfoMap.get(userObj.Id).Automated_time_off_case_routing__c ))
						userObj.Automated_time_off_case_routing__c = userIdToUserInfoMap.get(userObj.Id).Automated_time_off_case_routing__c;
					if(String.isNotBlank(userIdToUserInfoMap.get(userObj.Id).Destination_queue_for_automated_time_off__c ))
						userObj.Destination_queue_for_automated_time_off__c = userIdToUserInfoMap.get(userObj.Id).Destination_queue_for_automated_time_off__c;
					userListToUpdate.add(userObj);
					/*User_Info__c uInfo = userIdToUserInfoMap.get(userObj.Id);
					uInfo.Is_Updated__c = true;
					updateUserInfoRecords.add(uInfo);*/
				}
			}
		}
		if(!userListToUpdate.isEmpty()){
            if(Schema.sObjectType.User.isUpdateable())
                update userListToUpdate;
            else
                System.debug(LoggingLevel.DEBUG,'No permission to update User records.');
			
		}
		
		if(!updateUserInfoRecords.isEmpty()){
			if(Schema.sObjectType.User_Info__c.isUpdateable())
				update updateUserInfoRecords;
			else
				System.debug(LoggingLevel.DEBUG,'No permission to update User_Info__c records.');
		}
    }
    
	/**
	* @description 
	* The finish method of the batch class, called after all records have been processed. 
	* This method can be used to perform post-processing tasks such as sending notifications, 
	* logging results, or invoking other processes. It is currently not used in this implementation.
	*
	* @param BC The batchable context for the batch execution.
	*/
    public void finish(Database.BatchableContext BC){
        System.debug(LoggingLevel.DEBUG,'Batch finish executed - no logic required.');
    }

	/**
	* @description 
	* This method schedules the batch job to be executed. It is called when the job is scheduled 
	* through Apex Scheduler. The job is created with the provided query and executed as a batch job.
	* 
	* @param sc The schedulable context for the scheduled job.
	*/
	public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateUserUrlsBatch(this.query));
    }
}