@isTest public class Test_LGT_Migration_Utils {
    public static testMethod void migrationUtil(){
        //Create Account
        Account acc = new Account(Name = 'Test Account',Type = 'Prospect');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        insert cont;
        Case cs = TestDataFactory.getCase(acc, cont);       
        INSERT cs;
        LGT_Migration_Utils.getCaseRecForAllComponents(cs.Id);
        
    }
}