@isTest
public class PatchManagerAssignment_Test {
    public static User getuser(){
        User u=TestDataFactory.getUser();
        return u;
    }
    static testMethod void LeadTest(){
        User ur=getUser();
        insert ur;
        System.runas(ur){
            ShGl_TestFactoryHelper.WorkflowTriggerBypass();
            PatchManagerSettings__c setting=new PatchManagerSettings__c();
            setting.Segment_Revenue__c=10000;
            setting.Default_Account_User__c=ur.id;
            setting.Default_SDR_ID__c=ur.id;
            insert setting;
            PatchManagerSettings__c s=[Select Segment_Revenue__c from PatchManagerSettings__c];  
            System.assertEquals(10000, s.Segment_Revenue__c,'NO');
            
            List<PatchManager__c> lstPatch = new List<PatchManager__c>();
            for(integer i = 0; i<5; i++){
                PatchManager__c patch=new PatchManager__c();
                patch.City__c='California';
                if(i==1){
                    patch.Zip_code__c='302022';
                    patch.State__c='CA';                    
                }
                lstPatch.add(patch);
            }
            insert lstPatch;
            /*PatchManager__c patch=new PatchManager__c();
            //patch.Zip_code__c='302022';
            patch.City__c='California';
            //insert Patch;*/
            
            Lead lead=new Lead(Company='Test',LeadSource='Email',Lastname='Test',
                               Lead_Source_Details__c='Test',Country='United States',City='California');
            insert lead;
            Lead a=[Select id,LeadSource, Industry_Category__c from Lead where id=:lead.id];
            System.assertEquals(a.LeadSource,'Email');
            PageReference ObjDealReg = Page.PatchMangerReAssignLead;
            Test.setCurrentPage(ObjDealReg);
            ObjDealReg.getParameters().put('id',lead.id);
            ApexPages.StandardController sc = new ApexPages.standardController(lead);
            PatchManagerAssignment objHandler = new PatchManagerAssignment(sc);
            objHandler.reAssignment();
            PatchManagerAssignment.reAssignment(new list<Id>{lead.Id});
        }
    }
    static testMethod void ContactTest(){
        Contact con=new Contact(LastName='Test',Ownerid=UserInfo.getUserId(),MailingCountry='United States',
                                MailingCity='California',MailingPostalCode='111111');
        insert con;
        Contact c=[Select id,Lastname from Contact where id=:con.id];
        System.assertEquals(c.Lastname,'Test');
        PageReference ObjDealReg = Page.PatchMangerReAssignContact;
        Test.setCurrentPage(ObjDealReg);
        ObjDealReg.getParameters().put('id',con.id);
        ApexPages.StandardController sc = new ApexPages.standardController(con);
        PatchManagerAssignment objHandler = new PatchManagerAssignment(sc);
        objHandler.reAssignment();
        PatchManagerAssignment.reAssignment(new list<Id>{c.Id});
    }
    static testMethod void DealRegistrationTest(){
        
        User ur=getUser();
        insert ur;
        System.runas(ur){
            PatchManagerSettings__c setting=new PatchManagerSettings__c();
            setting.Segment_Revenue__c=10000;
            setting.Default_Account_User__c=ur.id;
            insert setting;
            PatchManagerSettings__c s=[Select Segment_Revenue__c from PatchManagerSettings__c];  
            System.assertEquals(10000, s.Segment_Revenue__c,'NO');
            Deal_Registration__c deal=new Deal_Registration__c(Title__c='Test',Segment_Revenue__c=decimal.valueof('1000'),Deal_Reg_Exp_Date__c = system.today(),
                                                               Lead_Source_Details__c='Test',Country__c='United States',City__c='California',Lead_Source__c='Test',
                                                               Deal_Registration_Status__c='Pending Conversion');
            insert deal;
            Deal_Registration__c newDeal=[Select id,Title__c from Deal_Registration__c where id=:deal.id];
            System.assertEquals(newDeal.Title__c,'Test');
            PageReference ObjDealReg = Page.PatchMangerReAssignDealReg;
            Test.setCurrentPage(ObjDealReg);
            ObjDealReg.getParameters().put('id',deal.id);
            ApexPages.StandardController sc = new ApexPages.standardController(deal);
            PatchManagerAssignment objHandler = new PatchManagerAssignment(sc);
            objHandler.reAssignment();
            PatchManagerAssignment.reAssignment(new list<Id>{deal.Id});
        }
    }
    static testMethod void AccountTest(){
        User ur=getUser();
        insert ur;
        System.runas(ur){
            ShGl_DisableFunctionalityLogic__c cs = ShGl_DisableFunctionalityLogic__c.getInstance(ur.Id); 
            cs.Allow_account_Transfer__c = true;
            upsert cs;
            ShGl_TestFactoryHelper.WorkflowTriggerBypass();
            PatchManagerSettings__c setting=new PatchManagerSettings__c();
            setting.Segment_Revenue__c=10000;
            setting.Default_Account_User__c=ur.id;
            insert setting;
            Account acc=new Account(Name='Test',ownerid='00540000003nuO9',
                                    BillingCountry='United States',BillingCity='California',BillingPostalCode='111111');
            insert acc;
            Account a=[Select id,Name from Account where id=:acc.id];
            System.assertEquals(a.Name,'Test');
            PageReference ObjDealReg = Page.PatchMangerReAssignAccount;
            Test.setCurrentPage(ObjDealReg);
            ObjDealReg.getParameters().put('id',acc.id);
            ApexPages.StandardController sc = new ApexPages.standardController(acc);
            PatchManagerAssignment objHandler = new PatchManagerAssignment(sc);
            objHandler.reAssignment();
            PatchManagerAssignment.reAssignment(new list<Id>{acc.Id});
        }
    }
}