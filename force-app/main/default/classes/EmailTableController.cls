/*
 * Class Name :- EmailTableController
 * Visualforce Component :- EmailTableComponent
 * Author :- Shiva Sharma
 * Created Date :- 22-08-2018
 * Description : This Controller is being used in EmailTableComponent to get data of User which is updated from Admin Panel.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
public class EmailTableController {
    public String tableType{get;set;}   
    public List<AdminPanelApexController.UserLogin> userlist{get;set;}
    public List<AdminPanelApexController.UserLogin> getTableList(){
        userlist = new List<AdminPanelApexController.UserLogin>();
        if(AdminPanelApexController.changedUserMap.containsKey(tableType))
        userlist = AdminPanelApexController.changedUserMap.get(tableType);
        return userlist;
    }
}