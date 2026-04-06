@isTest
public class LtngAnnouncementListController_Test {
    static testmethod void getPortalNews(){
        LtngAnnouncementListController.getPortalNews('1', '2', 'Product life cycle', false);  
    }
    
    static testmethod void getPortalNews1(){
        LtngAnnouncementListController.getPortalNews('1', '2', 'Product life cycle', true);  
    }
}