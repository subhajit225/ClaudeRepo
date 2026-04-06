@isTest

public class CaseS3FileUploadtest{

     static testMethod void testFile(){
        insert new TriggerControl__c(Name='Case'); 
        Account acc = new Account(name='testAcc');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        insert cont;
        Case ca = TestDataFactory.getCase(acc, cont);
        CaseApexController.saveCase( ca);
        CaseS3FileUpload.Customer_Case_Attach2(ca.id,'test','test','test','test');
     }

}