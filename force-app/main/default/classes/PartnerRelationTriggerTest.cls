@isTest
public class PartnerRelationTriggerTest {
	/*
    // Test for Before Insert trigger
    @isTest
    public static void testBeforeInsert() {
        User userRecord = TestDataFactory.getUser();
        Id userId = UserInfo.getUserId();
        
        system.runAs(userRecord) {
        // Create test Account record
        Account testAccount = new Account(
            Name = 'Test Account',
            National_Partner__c = true,
            Focused_Partner__c = false,
            MSP_Sub_Type__c = 'MSP'
        );
        insert testAccount;

        Opportunity oppObject = TestDataFactory.getOpportunity();
        insert oppObject;

        // Create test Partner_Relation__c record
        Partner_Relation__c partnerRelation = new Partner_Relation__c(
            Partner_Account__c = testAccount.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Transacting Partner'
        );

        // Perform the insert
        Test.startTest();
        insert partnerRelation;
        Test.stopTest();
            Partner_Relation__c insertedPartnerRelation = [SELECT National_Flag__c, Focus_Flag__c, SDP_Sub_Type__c FROM Partner_Relation__c WHERE Id = :partnerRelation.Id];
        System.assertEquals(testAccount.National_Partner__c, insertedPartnerRelation.National_Flag__c);
        System.assertEquals(testAccount.Focused_Partner__c, insertedPartnerRelation.Focus_Flag__c);
        System.assertEquals(testAccount.MSP_Sub_Type__c, insertedPartnerRelation.SDP_Sub_Type__c);
    }
    }

    // Test for Before Update trigger
    @isTest
    public static void testBeforeUpdate() {
        User userRecord = TestDataFactory.getUser();
        Id userId = UserInfo.getUserId();
        String exceptionMessage1;
        String exceptionMessage2;
        
        system.runAs(userRecord) {
        // Create test Account record
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            National_Partner__c = true,
            Focused_Partner__c = false,
            MSP_Sub_Type__c = 'GSI'
        );
        insert testAccount1;
        Opportunity oppObject = TestDataFactory.getOpportunity();
        insert oppObject;
        
        // Create and insert Partner_Relation__c record
        Partner_Relation__c pr = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Transacting Partner'
        );
        insert pr;
        Partner_Relation__c pr1 = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Transacting Partner'
        );
        
        // Create test Account record
        Account testAccount2 = new Account(
            Name = 'Test Account2',
            National_Partner__c = false,
            Focused_Partner__c = true,
            MSP_Sub_Type__c = 'MSP'
        );
        insert testAccount2;

        // Update the Partner_Relation__c record
        

        Test.startTest();
        //insert exception
        try{
            insert pr1;
        }catch(exception e){
            exceptionMessage1 = e.getMessage();
        }
        pr1.Partner_Account__c = testAccount2.Id;
        pr1.Involvement_Type__c = 'Sourcing Partner';
        insert pr1;
        //update exception
        try{
            pr1.Involvement_Type__c = 'Transacting Partner';
            update pr1;
        }catch(exception e){
            exceptionMessage2 = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, exceptionMessage1.contains('Duplicate Involvement Type : Transacting Partner for Opportunity - Please check existing records'));
        Partner_Relation__c updatedPartnerRelation = [SELECT National_Flag__c, Focus_Flag__c, SDP_Sub_Type__c FROM Partner_Relation__c WHERE Id = :pr1.Id]; // Assert that the fields were updated correctly
        System.assertEquals(testAccount2.National_Partner__c, updatedPartnerRelation.National_Flag__c);
        System.assertEquals(testAccount2.Focused_Partner__c, updatedPartnerRelation.Focus_Flag__c);
        System.assertEquals(testAccount2.MSP_Sub_Type__c, updatedPartnerRelation.SDP_Sub_Type__c);
    }
    }
	*/
    // Test with no related Account
    @isTest
    public static void testBeforeInsertNoAccount() {
        User userRecord = TestDataFactory.getUser();
        Id userId = UserInfo.getUserId();
        Partner_Relation__c partnerRelation = new Partner_Relation__c();
        
        Test.startTest();
        system.runAs(userRecord) {
            insert partnerRelation;
        }
        Test.stopTest();

        Partner_Relation__c insertedPartnerRelation = [SELECT National_Flag__c, Focus_Flag__c, SDP_Sub_Type__c FROM Partner_Relation__c WHERE Id = :partnerRelation.Id];
        System.assertEquals(false, insertedPartnerRelation.National_Flag__c);
        System.assertEquals(false, insertedPartnerRelation.Focus_Flag__c);
        System.assertEquals(null, insertedPartnerRelation.SDP_Sub_Type__c);
    }
    
    @isTest
    public static void testDuplicatePartnerRelations(){
        User userRecord = TestDataFactory.getUser();
        Id userId = UserInfo.getUserId();
        String exceptionMessage1;
        String exceptionMessage2;
        String exceptionMessage3;
        String exceptionMessage4;
        system.runAs(userRecord) {
        // Create test Account record
        Account testAccount = new Account(
            Name = 'Test Account1',
            National_Partner__c = true,
            Focused_Partner__c = false,
            MSP_Sub_Type__c = 'GSI'
        );
        insert testAccount;    
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            parentId = testAccount.Id,
            National_Partner__c = true,
            Focused_Partner__c = false,
            MSP_Sub_Type__c = 'GSI'
        );
        insert testAccount1;
             Account testAccount2 = new Account(
                Name = 'Test Account2',
                National_Partner__c = true,
                Focused_Partner__c = false,
                 parentId = testAccount.Id,
                MSP_Sub_Type__c = 'GSI'
            );
            insert testAccount2;
        
        Opportunity oppObject = TestDataFactory.getOpportunity();
        insert oppObject;
        
        List<Partner_Relation__c> prList = new List<Partner_Relation__c>();
        // Create and insert Partner_Relation__c record
        Partner_Relation__c pr = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'TAP Alliance'
        );
        prList.add(pr);
        Partner_Relation__c pr1 = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'TAP Alliance'
        );
        Partner_Relation__c pr2 = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Teaming Partner'
        );
        prList.add(pr2);
        
        
        Partner_Relation__c pr3 = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Distributor'
        );
        prList.add(pr3);
        
        Partner_Relation__c pr4 = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Incumbent Partner'
        );
        prList.add(pr4);
            
        insert prList;
        
        Partner_Relation__c pr5 = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'Distributor'
        );
        
        Test.startTest();
        //insert duplicate 752
        try{
            insert pr1;
        }catch(exception e){
            exceptionMessage1 = e.getMessage();
        }
		//update duplicate 752
        try{
            pr2.Involvement_Type__c = 'TAP Alliance';
            update pr2;
        }catch(exception e){
            exceptionMessage2 = e.getMessage();
        }
        pr2.Involvement_Type__c = 'Influence Partner';
            pr2.Partner_Account__c = testAccount2.Id;
        update pr2;
        
        //insert duplicate 751
        try{
            insert pr5;
        }catch(exception e){
            exceptionMessage3 = e.getMessage();
        }
        //update duplicate 751
        try{
            pr4.Involvement_Type__c = 'Distributor';
            update pr4;
        }catch(exception e){
            exceptionMessage4 = e.getMessage();
        }
        pr4.Involvement_Type__c = 'Transacting Partner';
        update pr4;
        
        Test.stopTest();
        System.assertEquals(true, exceptionMessage1.contains('Duplicate Involvement Type : TAP Alliance for Partner Account on this Opportunity - Please check existing records'));
        System.assertEquals(true, exceptionMessage2.contains('Duplicate Involvement Type : TAP Alliance for Partner Account on this Opportunity - Please check existing records'));
        System.assertEquals(true, exceptionMessage3.contains('Duplicate Involvement Type : Distributor for Opportunity - Please check existing records.'));
        System.assertEquals(true, exceptionMessage4.contains('Duplicate Involvement Type : Distributor for Opportunity - Please check existing records.'));
    }
    }
    
    @isTest
    public static void testBeforeDelete() {
        User userRecord = TestDataFactory.getUser();
        Id userId = UserInfo.getUserId();
        system.runAs(userRecord) {            
         Account testAccount1 = new Account(
            Name = 'Test Account224',
            National_Partner__c = true,
            Focused_Partner__c = false,
                MSP_Sub_Type__c = 'GSI',
                ownerId=userId
            );
            insert testAccount1;
        Opportunity oppObject = TestDataFactory.getOpportunity();
        insert oppObject;
         
        // Create and insert Partner_Relation__c record
        Partner_Relation__c pr = new Partner_Relation__c(
            Partner_Account__c = testAccount1.Id,
            Opportunity__c = oppObject.Id,
            Involvement_Type__c = 'TAP Alliance'
        );
        insert pr;
            List<Partner_Relation__c> partnerRelation = [SELECT Id, Partner_Account__c, Involvement_Type__c FROM Partner_Relation__c WHERE Id=:pr.Id LIMIT 1];
            System.assertEquals(1, partnerRelation.size());            
            try{
                Test.startTest();
                PartnerRelationTriggerHelper.updatePRFieldsOnClosedStage(new Set<Id>{oppObject.Id});
                delete partnerRelation;
                Test.stopTest();
            } catch (Exception ex) {
                system.debug(LoggingLevel.DEBUG, 'ex'+ex.getMessage());
            }
        }
    }
}