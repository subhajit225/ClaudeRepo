@isTest(SeeAllData=true)
public with sharing class UserLoginHistory_Test {
    public static @IsTest void methodName(){
        
        Test.startTest();
        UserLoginHistory sch1 = new UserLoginHistory();
        String sch = '0  00 3 4 * ?';
        system.schedule('Test', sch, sch1);
        Test.stopTest();
        
    }
}