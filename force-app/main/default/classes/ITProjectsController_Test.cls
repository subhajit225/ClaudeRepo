@isTest(SeeAllData = true)
public with sharing class ITProjectsController_Test {
    @isTest
    public static void testController(){
        ITProjectsController cont = new ITProjectsController();
        cont.login();
        cont.applyFilter();
        cont.getSelectedOrganizations();
        cont.getSelectedEnterpriseFunctions();
        cont.getOrganizationsFilter();
        cont.getEnterpriseFuntionsFilter();
        cont.showFilterDialog();
        cont.dismissFilter();
        cont.saveDecision();
        cont.logout();
    }
}