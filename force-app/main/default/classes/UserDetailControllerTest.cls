@isTest
public class UserDetailControllerTest {
    static testmethod void test1(){
        UserDetailController uc = new UserDetailController();
        uc.userRecordId = UserInfo.getUserId();
        uc.getUserRecords();
    }
}