/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   29th May 2020
 * Description  :   Batch class to update Employee Time-Off flag on User based on Time-Off Dates field updated by Workday as per CS21-22
 * TestClass    :   Workday_UserOnTimeOffTest
 */
global class Workday_UserOnTimeOff implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> userProfilesEligibleForWDIntegration = System.Label.Profiles_for_Workday_Employee_Time_Off_Integration.split(';');
        String query = 'SELECT Id, Employee_Time_Off__c, Time_Off_Dates__c, TimeZoneSidKey FROM User WHERE (Profile.Name =: userProfilesEligibleForWDIntegration) AND isActive = true';
        query = query + ' AND ((Time_Off_Dates__c = null AND Employee_Time_Off__c = true) OR (Time_Off_Dates__c != null))';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<User> usersList){
        List<User> userListToBeUpdated = new List<User>();

        for(User eachUser : usersList) {
            if(String.isBlank(eachUser.Time_Off_Dates__c)) {
                eachUser.Employee_Time_Off__c = false;
                userListToBeUpdated.add(eachUser);
            }
            else {
                //Get current date time in GMT format
                Datetime currentDateTime = System.now();

                //Convert it into Pacific Standard Time(PST).
                String dateTimeInUserTimeZone = currentDateTime.format('yyyy-MM-dd HH:mm:ss', eachUser.TimeZoneSidKey);
                dateTimeInUserTimeZone = dateTimeInUserTimeZone.substringBefore(' ');

                if(eachUser.Time_Off_Dates__c.contains(dateTimeInUserTimeZone) && !eachUser.Employee_Time_Off__c) {
                    eachUser.Employee_Time_Off__c = true;
                    userListToBeUpdated.add(eachUser);
                }
                else if(!eachUser.Time_Off_Dates__c.contains(dateTimeInUserTimeZone) && eachUser.Employee_Time_Off__c) {
                    eachUser.Employee_Time_Off__c = false;
                    userListToBeUpdated.add(eachUser);
                }
            }
        }

        Database.update(userListToBeUpdated, false);
    }

    global void finish(Database.BatchableContext bc){
        if(!Test.isRunningTest()) {
            System.scheduleBatch(new Workday_UserOnTimeOff(), 'Workday Integration For Employee Time-Off - Class : Workday_UserOnTimeOff', 15, 200);
        }
    }
}