@IsTest
private class AccountRiskTriggerHelperTest {
    
    @TestSetup
    static void setup() { 
        Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();

        insert new Custom_Configuration_Change__c(
            Config_For__c = 'CX & ML Both',
            Config_Type__c = 'Daily',
            Next_Run__c = Date.today().addDays(-1),
            RecordTypeId = recordTypeId
        );
        
        
        
        List<Account> accts = new List<Account>();
        for(Integer i=0;i<4;i++) accts.add(new Account(Name='Acct'+i));
        insert accts;
        
        Account_Risk__c rML = new Account_Risk__c(Account__c=accts[0].Id, Risk_Type__c='ML', ML_Risk__c = true, Account_External_Id__c =accts[0].Id);
        insert rML;
        
        List<Custom_Configuration_Change__c> configList = [
            SELECT Config_For__c, Config_Type__c, Next_Run__c
            FROM Custom_Configuration_Change__c WHERE RecordTypeId =: recordTypeId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!configList.isEmpty()) {
            Custom_Configuration_Change__c freqConfig = configList[0];
            freqConfig.Next_Run__c = Date.today().addDays(-1);
            update freqConfig;
        }
    }
    
    @IsTest static void testBatchInsertMixed() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<Account> accts = [SELECT Id FROM Account LIMIT 3];
            List<Account_Risk__c> risks = new List<Account_Risk__c>{
                new Account_Risk__c(Account__c=accts[2].Id, Risk_Type__c='ML', Opportunities__c='006', Account_External_Id__c = accts[2].Id),
                    new Account_Risk__c(Account__c=accts[1].Id, Risk_Type__c='CX', CX_Score_Status__c='Fragile', Account_External_Id__c = accts[1].Id )
                    };
                        
                        Test.startTest();
            insert risks;
            Test.stopTest();
            
            Integer countML = [SELECT count() FROM Risk_Profile__c WHERE Account__c = :accts[2].Id];
            Integer countCX = [SELECT count() FROM Risk_Profile__c WHERE Account__c = :accts[1].Id];
            System.assertEquals(1, countML);
            System.assertEquals(1, countCX);
        }
    }
    
    @IsTest static void testNoCreateWhenNoChange() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account a = [SELECT Id FROM Account LIMIT 1];
            Test.startTest();
            Account_Risk__c rML = [SELECT Id, Opportunities__c, Account__c FROM Account_Risk__c WHERE Risk_Type__c='ML' AND ML_Risk__c = true LIMIT 1];
            Risk_Profile__c rp = [SELECT Id, Risk_Reason_Additional_Comments__c FROM Risk_Profile__c WHERE Account__c = :rML.Account__c];
            rp.Risk_Reason_Additional_Comments__c = '';
            update rp;
            // update but don't change anything
            rML.get('Opportunities__c') ; 
            
            update rML;
            Test.stopTest();
            
            Integer cnt = [SELECT count() FROM Risk_Profile__c WHERE Account__c = :rML.Account__c];
            System.assertEquals(1, cnt, 'No new creation when no changes');
        }
    }
    
    @IsTest
    static void testContainsCommentHelper() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            String quarterString = AccountRiskTriggerHelper.CURRENT_QUARTER;      
            System.assertEquals(false, AccountRiskTriggerHelper.containsComment(null));
            System.assertEquals(true, AccountRiskTriggerHelper.containsComment('Some note with ' + quarterString));
            System.assertEquals(false, AccountRiskTriggerHelper.containsComment('Plain comment'));
        }
    }
    
    @IsTest
    static void testHasChangedHelper() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account_Risk__c oldRec = new Account_Risk__c(CX_Score_Status__c = 'Good');
            Account_Risk__c newRec = new Account_Risk__c(CX_Score_Status__c = 'Poor');
            System.assertEquals(true, AccountRiskTriggerHelper.hasChanged(oldRec, newRec, 'CX_Score_Status__c'));        
            newRec.CX_Score_Status__c = 'Good';
            System.assertEquals(false, AccountRiskTriggerHelper.hasChanged(oldRec, newRec, 'CX_Score_Status__c'));      
        }
    }
    
    @IsTest static void testInvalidateDefaultFrequencyType() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Custom_Configuration_Change__c cfg = new Custom_Configuration_Change__c(
                Config_For__c='ML Sync',
                Config_Type__c='Daily',
                Next_Run__c=Date.today().addDays(-1)
            );
            insert cfg;
            
            List<Account> a = [SELECT Id FROM Account LIMIT 4];
            Test.startTest();
            insert new Account_Risk__c(Account__c=a[3].Id, Risk_Type__c='ML', Account_External_Id__c = a[3].Id);
            Test.stopTest();
            
            // Should not update Next_Run__c; frequency record remains same date
            cfg = [SELECT Next_Run__c FROM Custom_Configuration_Change__c WHERE Id = :cfg.Id];
            System.assertEquals(Date.today().addDays(-1), cfg.Next_Run__c);
        }
    }
    @isTest
    static void testLogErrorMethod() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Exception simulatedException;
            try {
                Integer result = 1 / 0;
            } catch (Exception e) {
                simulatedException = e;
            }
            
            System.assertNotEquals(null, simulatedException, 'Expected an exception to be thrown.');
            
            Test.startTest();
            AccountRiskTriggerHelper.logError(simulatedException, 'Account', 'testLogErrorMethod');
            Test.stopTest();
            
            List<Error_Logs__c> logs = [SELECT Id, Object__c, Method__c, Class__c, Success__c FROM Error_Logs__c WHERE Method__c = 'testLogErrorMethod'];
            System.assertEquals(1, logs.size(), 'Expected one error log to be inserted.');
            System.assertEquals('Account', logs[0].Object__c);
        }
    }
}