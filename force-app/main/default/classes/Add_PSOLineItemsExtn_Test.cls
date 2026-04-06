/*Test Class added By Shadab
Related Class: Add_PSOLineItemsExtn
*/
@isTest
public class Add_PSOLineItemsExtn_Test{
    static testmethod void TestMethod1(){
        Account acc= new Account(Name='Test');
        insert acc;
        
        PSO__c pso =new PSO__c(Completion_date__c =System.today());
        insert pso;
        
        PageReference pageRef = Page.Add_PSOTimeEntries; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', pso.Id);//for page reference
        ApexPages.StandardController sc = new ApexPages.standardController(pso);
        Add_PSOLineItemsExtn  controller = new Add_PSOLineItemsExtn(sc);
        controller.lineItems.get(0).Start_date__c=System.Today();
        controller.lineItems.get(0).End_Date__c =System.Today().addDays(5);
        controller.calculateNumber();
        controller.save();
        controller.addrow();
        controller.removerow();
        
     }

}