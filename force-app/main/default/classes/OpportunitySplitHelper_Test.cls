/******************************************************************************
@description    : test class for OpportunitySplitHelper
*******************************************************************************/
@isTest
public class OpportunitySplitHelper_Test {
    private static final String USER_EMAIL = 'testUser@rubrik.com';
    private static final Boolean DOINSERT_TRUE = true;
    private static final Boolean DOINSERT_FALSE = false;

    /******************************************************************************
    @description    : prepare test data
    *******************************************************************************/
    @testSetup
    static void dataSetup() {
        //create test user
        User testUser = TestDataFactory.getUser();
        testUser.Email = USER_EMAIL;
        insert testUser;

        System.runAs(testUser) {
            // Create custom settings
            List<OpportunitySplitMapping__c> opportunitySplitMappings = createOpportunitySplitMappings(DOINSERT_TRUE);

            //disable Opportunity trigger
            TriggerControl__c triggerControl = new TriggerControl__c();
            triggerControl.Name = 'Opportunity';
            triggerControl.DisableTrigger__c = true;
            insert triggerControl;

            //create account
            Account accountObj = TestDataFactory.getAccount();
            insert accountObj;

            //create opportunity
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity opportunityObj = TestDataFactory.getOpportunity(accountObj);
            opportunities.add(opportunityObj);

            //opportunity without line items
            Opportunity opportunityObj2 = TestDataFactory.getOpportunity(accountObj);
            opportunities.add(opportunityObj2);
            insert opportunities;

            Product2 productObj = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT');
            insert productObj;

            Pricebook2 pricebook = new Pricebook2(name = 'Test Price Book', isActive = true);
            insert pricebook;

            //update opportunity for pricebook
            Id standardPBId = Test.getStandardPricebookId();
            opportunityObj.Pricebook2Id = standardPBId;
            update opportunityObj;

            PriceBookEntry pbEntry = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = standardPBId, Product2Id = productObj.Id, IsActive = true, UseStandardPrice = false);
            insert pbEntry;

            OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid = pbEntry.Id, TotalPrice = 2000, Quantity = 2, OpportunityID = opportunityObj.Id);
            insert oppLine;
        }
    }

    /******************************************************************************
    @description    : test createOptySplitLineItem method for opportunities with and without line items
    *******************************************************************************/
    @IsTest
    static void createOptySplitLineItemTest() {
        User testUser = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
        Opportunity opportunityObj = [SELECT Id, Amount, Pricebook2Id, (SELECT Id, ProductCode, TotalPrice FROM OpportunityLineItems) FROM Opportunity LIMIT 1];
        //opportunity without line items
        Opportunity opportunityObj2 = [SELECT Id, Amount, Pricebook2Id FROM Opportunity WHERE Id NOT IN (SELECT OpportunityId FROM OpportunityLineItem) LIMIT 1];
        OpportunityLineItem opportunityLineItem;
        OpportunityLineItem opportunityLineItem2;

        System.runAs(testUser) {
            test.startTest();
            opportunityLineItem = OpportunitySplitHelper.createOptySplitLineItem(opportunityObj, 2);
            opportunityLineItem2 = OpportunitySplitHelper.createOptySplitLineItem(opportunityObj2, 0);
            OpportunitySplitHelper.createAmountProduct(opportunityObj, 2000);
            test.stopTest();
        }
        Assert.isNotNull(opportunityLineItem, 'opportunityLineItem should not be null');
        Assert.isNotNull(opportunityLineItem2, 'opportunityLineItem should not be null');
    }

    /******************************************************************************
    @description    : test createOptySplitLineItem method for negative scenario where standard pricebook is not defined
    *******************************************************************************/
    @IsTest
    static void createOptySplitLineItemTest2() {
        User testUser = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
        //opportunity without line items
        Opportunity opportunityObj = [SELECT Id, Amount, Pricebook2Id FROM Opportunity WHERE Id NOT IN (SELECT OpportunityId FROM OpportunityLineItem) LIMIT 1];
        OpportunityLineItem opportunityLineItem;

        Boolean isException = false;
        System.runAs(testUser) {
            test.startTest();
            try {
                opportunityLineItem = OpportunitySplitHelper.createOptySplitLineItem(opportunityObj, 0);
            } catch (Exception ex) {
                isException = true;
            }
            test.stopTest();
        }
        Assert.isTrue(isException, 'Expected an exception to be thrown');
    }

    /******************************************************************************
    @description    : test copyOpportunity method
    *******************************************************************************/
    @IsTest
    static void copyOpportunityTest() {
        User testUser = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
        //create opportunity to copy
        Account accountObj = [SELECT Id FROM Account LIMIT 1];
        Opportunity opportunityToCopy = TestDataFactory.getOpportunity(accountObj);
        insert opportunityToCopy;

        Opportunity copiedOpportunity = new Opportunity();

        System.runAs(testUser) {
            test.startTest();
            OpportunitySplitHelper.copyOpportunity(copiedOpportunity, opportunityToCopy);
            test.stopTest();
        }
        Assert.areEqual(opportunityToCopy.StageName, copiedOpportunity.StageName, 'copiedOpportunity StageName should match original opportunity StageName');
    }

    /******************************************************************************
    @description    : test copyOpportunityFieldToSplit method
    *******************************************************************************/
    @IsTest
    static void copyOpportunityFieldToSplitTest() {
        User testUser = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
        List<OpportunitySplitMapping__c> opportunitySplitMappings = [SELECT Id, Field__c, Default_Value__c, Suffix__c, From_Field__c, Skip_Update_if_child_has_value__c FROM OpportunitySplitMapping__c];
        //create opportunity to copy
        Account accountObj = [SELECT Id FROM Account LIMIT 1];
        Opportunity opportunityToCopy = TestDataFactory.getOpportunity(accountObj);
        insert opportunityToCopy;
        Opportunity copiedOpportunity = new Opportunity();
        System.runAs(testUser) {
            test.startTest();
            OpportunitySplitHelper.copyOpportunityFieldToSplit(copiedOpportunity, opportunityToCopy, opportunitySplitMappings);
            test.stopTest();
        }
        Assert.areEqual(opportunityToCopy.StageName, copiedOpportunity.StageName, 'copiedOpportunity StageName should match original opportunity StageName');
    }

    /******************************************************************************
    @description     prepare OpportunitySplitMapping__c custom setting records
    @param           doInsert - boolean to determine if the records should be inserted in the database
    @return          List<OpportunitySplitMapping__c> list of OpportunitySplitMapping__c records
    *******************************************************************************/
    private static List<OpportunitySplitMapping__c> createOpportunitySplitMappings(Boolean doInsert) {
        List<OpportunitySplitMapping__c> opportunitySplitMappings = new List<OpportunitySplitMapping__c>();
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'Name', Skip_Update_if_child_has_value__c = false));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'StageName', Skip_Update_if_child_has_value__c = false));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'CloseDate', Skip_Update_if_child_has_value__c = false));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'Risk_Identified__c', Default_Value__c = 'false'));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'Meeting_evidence_link__c', Default_Value__c = 'false'));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'Push_Counter__c', Default_Value__c = '1'));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'NextStep', From_Field__c = 'Order_Sub_Type__c'));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'NextStep', Suffix__c = 'Split_percentage__c'));
        opportunitySplitMappings.add(new OpportunitySplitMapping__c(Field__c = 'ETM_Theatre__c', Skip_Update_if_child_has_value__c = true));
        if (doInsert) {
            insert opportunitySplitMappings;
        }
        return opportunitySplitMappings;
    }
}