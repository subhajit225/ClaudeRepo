/**
    $ClassName$   : TerritoryTriggerTest
    $Description$ : Test Class for TerritoryTrigger
*/

@isTest
private class Territory2TriggerTest {

    @testSetup static void setupTestData() {
        
        //1. Get Territory Type
        Set<String> trtType = new Set<String> {'Territory', 'Region', 'Area', 'Theatre', 'WW'};
        List<Territory2Type> terTypeList = [SELECT Id FROM Territory2Type WHERE DeveloperName IN :trtType ORDER BY Priority];
        
        //2. create Territory2Model records
        //Territory2Model terModel = new Territory2Model(DeveloperName = 'FY21_Model_Test', Name='FY21_Model_Test');
        //insert terModel;
        Territory2Model terModel = [SELECT Id FROM Territory2Model where State = 'Active']; 
        
        //3.Create territories
        
        Territory2 terGlobal = new Territory2(DeveloperName ='Global_Test', Name='Global_Test', ParentTerritory2Id=null, Territory2ModelId=terModel.Id, Territory2TypeId=terTypeList[4].Id);
        insert terGlobal;
        
        Territory2 terTheatre = new Territory2(DeveloperName ='AMER_COM_Test', Name = 'AMER_COM_Test', ParentTerritory2Id=terGlobal.Id, Territory2ModelId = terModel.Id, Territory2TypeId = terTypeList[3].Id);
        insert terTheatre;
        
        Territory2 terArea = new Territory2(DeveloperName ='COM_CANADA_Test', Name = 'COM_CANADA_Test', ParentTerritory2Id = terTheatre.Id, Territory2ModelId = terModel.Id, Territory2TypeId = terTypeList[2].Id);
        insert terArea;
        
        Territory2 terRegion = new Territory2(DeveloperName = 'CANADA_COM_CENTRAL_CANADA_Test', Name = 'CANADA_COM_CENTRAL_CANADA_Test', ParentTerritory2Id=terArea.Id, Territory2ModelId = terModel.Id, Territory2TypeId = terTypeList[1].Id,SE_Pooling__c = true);
        insert terRegion;
    }
    //test Assignment rule creation 
    @isTest static void teritoryAssignmentCreate_TM1() {
       
        List<Territory2> trtList = [SELECT Id,ParentTerritory2Id,Territory2ModelId FROM Territory2 
                                        WHERE Territory2Type.DeveloperName = 'Region' AND DeveloperName = 'CANADA_COM_CENTRAL_CANADA_Test'];
        List<Territory2Type> trtType = [SELECT Id FROM Territory2Type WHERE DeveloperName = 'Territory'];
        trtList[0].SE_Pooling__c = false;
        Test.startTest();
            update trtList;
            Territory2 terTerritory = new Territory2(DeveloperName = 'COM_CENTRAL_CANADA_COM_CAN_CEN_Test', 
            Name = 'COM_CENTRAL_CANADA_COM_CAN_CEN_Test', ParentTerritory2Id = trtList[0].Id, Territory2ModelId = trtList[0].Territory2ModelId, Territory2TypeId = trtType[0].Id, Adaptive_Territory_Id__c = '557734896');
            insert terTerritory;
        Test.stopTest();
        
        List<RuleTerritory2Association> trtRuleAssList = [SELECT Id from RuleTerritory2Association WHERE Territory2Id = :terTerritory.Id];
        System.debug('@@'+trtRuleAssList);
        System.assert(trtRuleAssList.size() > 0);
    }
    //test update of Adaptive Territory Id
    @isTest static void teritoryAssignmentUpdate_TM2() {
       
        List<Territory2> trtList = [SELECT Id,ParentTerritory2Id,Territory2ModelId FROM Territory2 
                                        WHERE Territory2Type.DeveloperName = 'Region' 
                                        AND DeveloperName = 'CANADA_COM_CENTRAL_CANADA_Test'];
        List<Territory2Type> trtType = [SELECT Id FROM Territory2Type WHERE DeveloperName = 'Territory'];
        
        
        Territory2 terTerritory = new Territory2(
            DeveloperName = 'COM_CENTRAL_CANADA_COM_CAN_CEN_Test', 
            Name = 'COM_CENTRAL_CANADA_COM_CAN_CEN_Test', 
            ParentTerritory2Id = trtList[0].Id, 
            Territory2ModelId = trtList[0].Territory2ModelId, 
            Territory2TypeId = trtType[0].Id, 
            Adaptive_Territory_Id__c = '111222333444'
        );
        
        Territory2 Unassigned = new Territory2(
            DeveloperName = 'Unassigned', 
            Name = 'Unassigned', 
            ParentTerritory2Id = trtList[0].Id, 
            Territory2ModelId = trtList[0].Territory2ModelId, 
            Territory2TypeId = trtType[0].Id, 
            Adaptive_Territory_Id__c = ''
        );
        insert new List<Territory2> {terTerritory, Unassigned};
        List<RuleTerritory2Association> trtRuleAssList = [SELECT Id,RuleId from RuleTerritory2Association WHERE Territory2Id = :terTerritory.Id];
        System.assert(trtRuleAssList.size() > 0);
        Test.startTest();
            terTerritory.Adaptive_Territory_Id__c = '1234512345';
        terTerritory.Territory_Structure_Type__c = 'Core';
            update terTerritory;
        Test.stopTest();
        trtRuleAssList = [SELECT Id,RuleId from RuleTerritory2Association WHERE Territory2Id = :terTerritory.Id];
        List<ObjectTerritory2AssignmentRuleItem> trtRuleAssItemList = [SELECT Id, RuleId, Value FROM ObjectTerritory2AssignmentRuleItem
                    WHERE RuleId = :trtRuleAssList[0].RuleId];
        System.assertEquals('1234512345', trtRuleAssItemList[0].Value);
    }
}