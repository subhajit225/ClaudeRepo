@isTest
public class MIPAccContriTriggerHelper_Test {

    @testSetup 
    static void testDataSetup(){
        List<MIP_Contract__c> mipContractList = new List<MIP_Contract__c>();
        Account aObj = new Account(Name='Test CDW', 
                                   RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId(),
                                   Type='Prospect',
                                   Primary_Contact_Email__c ='abc.xyz@rubrik.com');
        insert aObj;
        
        
        Contact cObj = new Contact(FirstName='Test MIP Contact', 
                                   LastName='Ending Name',
                                   AccountId=aObj.Id);
        
        MIP_Contract__c mipConObj = new MIP_Contract__c(Status__c ='Approved',
                                                        Start_Date__c = System.today().addDays(-180), 
                                                        End_Date__c = System.today(),
                                                        Partner_Account__c = aObj.Id);
        mipContractList.add(mipConObj);
        
        MIP_Contract__c mipConObj2 = new MIP_Contract__c(Status__c ='Approved',
                                                        Start_Date__c = System.today().addDays(-180), 
                                                        End_Date__c = System.today(),
                                                        Partner_Account__c = aObj.Id);
        mipContractList.add(mipConObj2);
        insert mipContractList;
    }
    
    @isTest
    static void addAndRemoveMIPAccContri(){
        Id accId = [SELECT Id FROM Account].Id;
        List<MIP_Contract__c> mipContracts = [SELECT Id FROM MIP_Contract__c];
        Id mipContract1Id = mipContracts[0].Id;
        Id mipContract2Id = mipContracts[1].Id;
        List<MIP_Account_Contribution__c> mipContriList = new List<MIP_Account_Contribution__c>();
        
        MIP_Account_Contribution__c mipContri = new MIP_Account_Contribution__c();
        mipContri.MIP_Contract__c = mipContract1Id;
        mipContri.Partner_Account__c = accId;
        mipContriList.add(mipContri);
        
        MIP_Account_Contribution__c mipContri2 = new MIP_Account_Contribution__c();
        mipContri2.MIP_Contract__c = mipContract2Id;
        mipContri2.Partner_Account__c = accId;
        mipContriList.add(mipContri2);
        
        insert mipContriList;
        
        delete mipContri2;
    }
    
    static testMethod void testMethod2() {  
        Test.startTest();
        flowControll.disableAllTriggers();
        Test.stopTest();
    }
}