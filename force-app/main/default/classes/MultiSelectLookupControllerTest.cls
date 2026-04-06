@isTest
public class MultiSelectLookupControllerTest {
    @isTest
    public static  void testFetchLookUpValues() {
        MultiSelectLookupController.fetchLookUpValues('', 'Order', null, null,null);
         MultiSelectLookupController.fetchLookUpValues('', 'Account', null, null,'Customer/Prospect');
        MultiSelectLookupController.fetchLookUpValues('', 'channelprogramlevel', null,'Authorized',null);
        MultiSelectLookupController.fetchLookUpValues('', 'Case', null, null,null);
        MultiSelectLookupController.fetchLookUpValues('00', 'Case', null, null,null);
        MultiSelectLookupController.fetchLookUpValues('', 'User', null, 'isContactId=null',null);
        MultiSelectLookupController.fetchLookUpValues('', 'Survey', null, null,null);
        MultiSelectLookupController.fetchLookUpValues('Test', 'Survey', null, null,null);
         MultiSelectLookupController.fetchLookUpValues('', 'user', null, null,null);
        MultiSelectLookupController.fetchLookUpValues('', 'group', null, null,null);
        
    }
    @isTest
    public static  void testGetselectOptions() {
        MultiSelectLookupController.getselectOptions(new Case(), 'Status');
    }
}