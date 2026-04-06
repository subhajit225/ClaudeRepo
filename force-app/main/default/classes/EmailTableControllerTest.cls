@isTest
public class EmailTableControllerTest {
    @isTest static void EmailTableControllerTest(){
        EmailTableController etc = new EmailTableController();
        AdminPanelApexController.changedUserMap.put('Update',new List<AdminPanelApexController.UserLogin>());
        etc.tableType = 'Update';
        etc.getTableList();
    }
}