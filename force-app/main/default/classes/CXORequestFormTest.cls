/**
 * @description Apex test class for CXORequestForm apex controller
 * @createdDate July 20025
 */ 
@istest
public class CXORequestFormTest {

    /**
     * @description create test data
     */ 
    @testsetup static void createTestData(){
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        insert settingDisable;
        
        List<Opportunity> oppLst = new List<Opportunity>();
        Opportunity sOpp1 = TestDataFactory.getOpportunity();
        sOpp1.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        sOpp1.Name = 'Test Opp1';
        sOpp1.Opportunity_Split_Parent__c = null;
        sOpp1.Opportunity_Type__c = 'New Customer';
        oppLst.add(sOpp1);
        
        Opportunity sOpp2 = TestDataFactory.getOpportunity();
        sOpp2.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        sOpp2.Name = 'Test Opp2';
        sOpp2.Opportunity_Split_Parent__c = null;
        sOpp2.Opportunity_Type__c = 'New Customer';
        oppLst.add(sOpp2);
        INSERT oppLst;
    }
    
    /**
     * @description test createCveEngagementRecord method
     */ 
    @istest static void createCveEngagementRecordTest(){
        Id profileId = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<User> users = TestDataFactory.getUsers('testClassUser1', new Set<Id>{profileId}, 1);
        INSERT users;
        List<Opportunity> oppLst = [SELECT Id, Name, AccountId FROM Opportunity];
        
        Test.startTest();
        CXORequestForm.Response res;
        String cveEngagementJsonStr = '{"X3_Why_s_Presented__c":"Yes", "Account__c":"'+oppLst[0].AccountId+'"}';
        System.runAs(users[0]){
            res = CXORequestForm.getFormData();
            System.assert(res.Success);
            
            res = CXORequestForm.createCveEngagementRecord(null, null, null);
            System.assert(!res.Success);
            
            res = CXORequestForm.createCveEngagementRecord(cveEngagementJsonStr, null, null);  
            //System.assert(res.Success);
            
            res = CXORequestForm.createCveEngagementRecord(cveEngagementJsonStr, 'abc', null);
        	//System.assert(!res.Success);
        }
        
        String selectedOppStr = '[{"Id":"'+oppLst[0].Id+'", "Name":"'+oppLst[0].Name+'"}]';
        res = CXORequestForm.createCveEngagementRecord(cveEngagementJsonStr, selectedOppStr, null);
        //System.assert(res.Success);
        Test.stopTest();
    }
    
    /**
     * @description Test retriveSearchData method
     */ 
    @isTest static void retriveSearchDataTest(){        
        
        Id profileId = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<User> users = TestDataFactory.getUsers('testClassUser1', new Set<Id>{profileId}, 1);
        INSERT users;        
        
        Test.startTest();
        CXORequestForm.Response res;
        System.runAs(users[0]){
            //Negative test
            res = CXORequestForm.retriveSearchData(null, null, null, null, null);
            System.assert(!res.Success);
                        
            //Negative test
            res = CXORequestForm.retriveSearchData('Opportunity', 'Id, IncorrectField', 'Test', null, null);
            System.assert(!res.Success);
            
            //Positive test
            res = CXORequestForm.retriveSearchData('Opportunity', 'Id, Name', 'Test', null, null);
            System.assert(res.Success);
        }
        //Positive test
        List<Opportunity> oppLst = [SELECT Id, Name, AccountId FROM Opportunity];
        res = CXORequestForm.retriveSearchData('Opportunity', 'Id, Name', 'Test', new List<String>(), oppLst[0].AccountId);
        System.assert(res.Success);
        Test.stopTest();
    }
}