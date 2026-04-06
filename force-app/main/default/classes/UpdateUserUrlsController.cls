/**
* @Class Name : UpdateUserUrlsController.cls
* @description : Used to Save/Update user id and urls to User_Info__c custom object
* @Modification Log :
********************Change Logs ********************************************
* User Story             Modified By          Date                     Description
* CS21-3349              Shailesh Kumar	      April 28, 2025		   Created this class
* CS21-3349              Shailesh Kumar	      May 13, 2025		       Made a few changes after testing batch job from here.
* CS21-3349				 Shailesh Kumar		  5 Sep, 2025			   Added get ExistingUrl method
********************Change Logs Ends****************************************
**/

public with sharing class UpdateUserUrlsController {
    /**
     * @description - to check the user is a Manager or not
     * @return if manager then true else it will be false
    */
    @AuraEnabled(cacheable = true)
    public static Boolean isUserManager(){
        Boolean isManager = false;
        User usr = [SELECT Id , Profile_Name__c FROM User WHERE Id =: UserInfo.getUserId() WITH USER_MODE];
        if(usr.Profile_Name__c == 'Rubrik Customer Support Manager'){
            isManager = true;
        }
        return isManager;
    }
    
	/**
     * @description - to save the records in User Info object
     * @param userInfoList JSON String list of UserId and Url
    */
	@AuraEnabled
    public static void saveUserInfoRecords(String userInfoList) {
        List<User_Info__c> recordsToInsert = new List<User_Info__c>();
        List<UserInfoWrapper> parsedList = (List<UserInfoWrapper>)JSON.deserialize(userInfoList, List<UserInfoWrapper>.class);

        for (UserInfoWrapper obj : parsedList) {
            User_Info__c usrInfObj = new User_Info__c();
            usrInfObj.Url__c = obj.url;
            usrInfObj.User__c = obj.userId;
            // usrInfObj.Is_Updated__c = false;
            recordsToInsert.add(usrInfObj);
        }
        if(!recordsToInsert.isEmpty()){
            if(Schema.sObjectType.User_Info__c.isCreateable())
				insert recordsToInsert;
			else
                throw new AuraHandledException('No permission to insert User_Info__c records.');
        }
    }

    /**
     * @description - to save the Queue related info in User Info object
     * @param fieldMap JSON String Key value pair of fieldApiName and its value
    */
    @AuraEnabled
    public static void saveUserFieldData(Map<String, Object> fieldMap) {
        String objectApiName = 'User_Info__c';
        // Dynamically create the sObject (e.g., Account)
        SObject record = (SObject) Type.forName('Schema.' + objectApiName).newInstance();
        if(!fieldMap.isEmpty()){
            for (String fieldName : fieldMap.keySet()) {
                record.put(fieldName, String.valueOf(fieldMap.get(fieldName)));
            }
        } 
        if(record!=NULL){
            // record.put('Is_Updated__c', false);
            record.put('User__c',UserInfo.getUserId());
            if(Schema.sObjectType.User_Info__c.isCreateable())
				insert record;
			else
                throw new AuraHandledException('No permission to insert User_Info__c records.');
        }
    }

    /**
     * @description - to get the existing Calendar Booking URL value of User record
     * @param userId - User Id to get the Calendar Booking URL
     * @return calendarBookingUrl
    */
    @AuraEnabled(cacheable=false)
    public static String getExistingUrl(String userId) {
        if (String.isBlank(userId)) {
            return 'No User Id provided';
        }
        User u = [SELECT Id,Calendar_booking_URL__c  FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
        return u.Calendar_booking_URL__c;
    }

	/**
     * @description - Wrapper class
    */
    public class UserInfoWrapper {
		/**
        * @description stores userId
        */
        @AuraEnabled public String userId;
		/**
        * @description stores url
        */
        @AuraEnabled public String url;
    }
}