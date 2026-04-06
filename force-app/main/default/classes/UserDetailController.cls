/*
 * Class Name :- UserDetailController
 * Visualforce Component :- UserDetailComponent
 * Author :- Shiva Sharma
 * Created Date :- 14-06-2019
 * Description : This Controller is being used in UserDetailComponent for displaying user info.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
global without sharing class UserDetailController {
    global String userRecordId{get;set;}
    global List<User> userRecord{get;set;}
    
    public List<User> getUserRecords(){
        userRecord = new List<User>();
        userRecord = [select id,Contact.Account.Name,Email,ContactId from User where id =:userRecordId ];
        return userRecord;
    }
}