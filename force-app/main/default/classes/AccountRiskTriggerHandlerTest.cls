@isTest
private class AccountRiskTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'Test Account');
        accList.add(acc);
        insert accList;

        Risk_Profile__c rp = new Risk_Profile__c(
            Account__c = accList[0].Id,
            Risk_Origin__c = 'Account',
            Risk_Type__c = 'Entitlement Risk',
            Risk_Category__c = 'CX Score Risk',
            Risk_Reason_Additional_Comments__c = ''
        );
        insert rp;
        
        Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();

        insert new Custom_Configuration_Change__c(
            Config_For__c = 'CX & ML Both',
            Config_Type__c = 'Daily',
            Next_Run__c = Date.today().addDays(-1),
            RecordTypeId = recordTypeId
        );  
        
        List<Account> accts = new List<Account>();
        for(Integer i=0;i<5;i++) accts.add(new Account(Name='Acct'+i));
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
            freqConfig.Config_Type__c ='Biweekly';
            freqConfig.Config_For__c ='CX Sync';
            update freqConfig;
        }
        
        if (!configList.isEmpty()) {
            Custom_Configuration_Change__c freqConfig = configList[0];
            freqConfig.Config_Type__c ='Monthly';
            update freqConfig;
        }
        
        if (!configList.isEmpty()) {
            Custom_Configuration_Change__c freqConfig = configList[0];
            freqConfig.Config_Type__c ='Snooze';
            update freqConfig;
        }
    }

    @isTest
    static void testProcessAfterInsertAndUpdate() {
     System.runAs(new User(Id = UserInfo.getUserId())) {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Account_Risk__c ar = new Account_Risk__c(
            Account__c = acc.Id,
            Account_External_Id__c = acc.Id,
            Risk_Type__c = 'ML',
            Opportunities__c = 'http://opp,001',
            Entitlements__c = 'http://ent,002',
            Product_Pillar_1__c = 'P1',
            Product_Pillar_2__c = 'P2',
            ML_Risk__c = true
        );
        insert ar;
        
        System.assertNotEquals(null, ar.Id, 'Account_Risk__c should be inserted');
        Map<Id, Account_Risk__c> newMap = new Map<Id, Account_Risk__c>{ ar.Id => ar };
            
        ar.CX_Score_Status__c = 'Poor';
        update ar;
         
        Account_Risk__c updatedAR = [SELECT CX_Score_Status__c FROM Account_Risk__c WHERE Id = :ar.Id];
        System.assertEquals('Poor', updatedAR.CX_Score_Status__c, 'CX_Score_Status__c should be updated to Poor');

        Account_Risk__c oldAR = ar.clone(false, true, false, false);
        oldAR.CX_Score_Status__c = 'Fragile';

        Map<Id, Account_Risk__c> oldMap = new Map<Id, Account_Risk__c>{ ar.Id => oldAR };
        List<Account_Risk__c> newList = new List<Account_Risk__c>{ ar };

        Test.startTest();
        AccountRiskTriggerHelper.processAfterUpdate(newList, oldMap);
        Test.stopTest();
     }
    }

    @isTest
    static void testUtilityMethods() {
      System.runAs(new User(Id = UserInfo.getUserId())) {
        Account_Risk__c oldRec = new Account_Risk__c(CX_Score_Status__c = 'Good');
        Account_Risk__c newRec = new Account_Risk__c(CX_Score_Status__c = 'Poor');
        System.assert(AccountRiskTriggerHelper.hasChanged(oldRec, newRec, 'CX_Score_Status__c'));

        String comment = 'Risk Analyzed in Q'+(((Math.mod(System.today().month() +10, 12))/3) +1)+' Quarter';
        System.assert(AccountRiskTriggerHelper.containsComment(comment));
      }
    }
    
    @isTest
    static void testExpirePreviousMLRiskProfiles() {
      System.runAs(new User(Id = UserInfo.getUserId())) {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Risk_Profile__c rp = new Risk_Profile__c(
            Account__c = acc.Id,
            ML_Risk__c = true,
            Risk_Origin__c = 'Account',
            Risk_Reason_Additional_Comments__c = '',
            Risk_Type__c = 'Entitlement Risk',
            Risk_Category__c = 'Prediction Model'
        );
        insert rp;

        Test.startTest();
        AccountRiskTriggerHelper.expirePreviousMLRiskProfiles();
        Test.stopTest();

        Risk_Profile__c notExpired = [SELECT ML_Risk__c FROM Risk_Profile__c WHERE Id = :rp.Id];
        System.assertEquals(true , notExpired.ML_Risk__c);
        }
    }
    
    @IsTest
    static void testUpdateNextRunForWeekly() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        // Create record type for Custom_Configuration_Change__c (if needed)
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Custom_Configuration_Change__c' LIMIT 1];
        
        Custom_Configuration_Change__c config = new Custom_Configuration_Change__c(
            RecordTypeId = rt.Id,
            Config_For__c = 'ML Sync',
            Config_Type__c = 'Snooze with a Date picker',

            Config_Disabled__c = false
        );
        insert config;
    
        Test.startTest();
        AccountRiskTriggerHelper.updateNextRun();
        Test.stopTest();
    
        Custom_Configuration_Change__c updatedConfig = [
            SELECT Next_Run__c, Last_Run__c
            FROM Custom_Configuration_Change__c
            WHERE Id = :config.Id
        ];
        System.assertEquals(Date.today(), updatedConfig.Last_Run__c, 'Last_Run__c should be today');
        }
    }



    @isTest
    static void testLogErrorCoverage() {
      System.runAs(new User(Id = UserInfo.getUserId())) {
        String freqName = 'Test';
        for(integer i=1; i<200; i++){
            freqName += 'Test';
        }
        Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();
        Custom_Configuration_Change__c badFreq = new Custom_Configuration_Change__c(
            Config_For__c = 'CX Sync',
            Config_Type__c = 'INVALID_TYPE', // invalid type to trigger exception
            Next_Run__c = Date.today(),
            RecordTypeId = recordTypeId
        );
        Test.startTest();
        try {
            insert badFreq;
        } catch (Exception e) {
            AccountRiskTriggerHelper.logError( e, 'Risk_Profile__c', 'handleBatch - update Risk_Profile__c');
        }
        Test.stopTest();
        List<Error_Logs__c> logs = [SELECT Id, Method__c FROM Error_Logs__c WHERE Method__c = 'handleBatch - update Risk_Profile__c' LIMIT 1];
        System.assert(!logs.isEmpty());
      }
    }
    
    @isTest
    static void testCXFrequency() {
      User u = [SELECT Id FROM User WHERE UserName LIKE '%apiautomation@rubrik.com%' LIMIT 1];
      System.runAs(u) {
        Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();
        Custom_Configuration_Change__c freq = new Custom_Configuration_Change__c(
            Config_For__c = 'CX Sync',
            Config_Type__c = 'Daily',
            Next_Run__c = Date.today().addDays(-1),
            RecordTypeId = recordTypeId
        );
        insert freq; 

        Account acc = [SELECT Id FROM Account LIMIT 1];
                   
        Account_Risk__c ar = new Account_Risk__c(
            Account__c = acc.Id,
            Risk_Type__c = 'CX',
            Opportunities__c = 'http://opp',
            Entitlements__c = 'http://ent',
            Product_Pillar_1__c = 'P1',
            Product_Pillar_2__c = 'P2',
            Account_External_Id__c = acc.Id
        );
        insert ar;
          
        System.assertNotEquals(null, ar.Id, 'Account_Risk__c should be inserted');  

        Map<Id, Account_Risk__c> newMap = new Map<Id, Account_Risk__c>{ ar.Id => ar };

        // Simulate update and check hasChanged logic
        ar.CX_Score_Status__c = 'Poor';
        update ar;
        
        Account_Risk__c updatedAR = [SELECT CX_Score_Status__c FROM Account_Risk__c WHERE Id = :ar.Id];
    	System.assertEquals('Poor', updatedAR.CX_Score_Status__c, 'CX Score Status should be updated to Poor');

        Account_Risk__c oldAR = ar.clone(false, true, false, false);
        oldAR.CX_Score_Status__c = 'Fragile';

        Map<Id, Account_Risk__c> oldMap = new Map<Id, Account_Risk__c>{ ar.Id => oldAR };
        List<Account_Risk__c> newList = new List<Account_Risk__c>{ ar };

        Test.startTest();
        AccountRiskTriggerHelper.processAfterInsert(newMap);
        AccountRiskTriggerHelper.processAfterUpdate(newList, oldMap);
        Test.stopTest();
    }
    }
    
    @isTest
    static void testProcessAfterInsertMLBlocked() {
        User u = [SELECT Id FROM User WHERE UserName LIKE '%apiautomation@rubrik.com%' LIMIT 1];
        System.runAs(u) {
        Account acc = new Account(Name = 'Direct Method Call Account');
        insert acc;
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Custom_Configuration_Change__c' 
            AND DeveloperName = 'RP_Frequency_Config' 
            LIMIT 1
        ];
    
        Custom_Configuration_Change__c config = new Custom_Configuration_Change__c(
            RecordTypeId = rt.Id,
            Config_For__c = 'ML Sync',
            Config_Type__c = 'Weekly',
            Next_Run__c = Date.today().addDays(5), // Future date, should block ML
            Config_Disabled__c = false
        );
      //  insert config;
        Account_Risk__c risk = new Account_Risk__c(
            Account__c = acc.Id,
            Risk_Type__c = 'ML',
            CX_Score_Status__c = 'Poor',
            Account_External_Id__c = acc.Id
        );
        insert risk;   
       
            Integer countMLAR = [SELECT count() FROM Account_Risk__c WHERE Account__c = : risk.Account__c];
            Integer countMLRP = [SELECT count() FROM Risk_Profile__c WHERE Account__c = : risk.Account__c];
            System.assertEquals(1, countMLAR);
            System.assertEquals(0, countMLRP); 
            
      }
    }
    
     @IsTest static void testBatchInsertMixed() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();
            Custom_Configuration_Change__c freq = new Custom_Configuration_Change__c(
                Config_Disabled__c = true
            );
            insert freq; 
		    List<Account> accList = new List<Account>();
            Account acc = new Account(Name = 'Direct Account 1', close_won_date__c = System.today().addDays(-100));
            Account acc2 = new Account(Name = 'Direct Account 2', close_won_date__c = System.today().addDays(-100));
            accList.add(acc); 
            accList.add(acc2);
            insert accList;
            List<Account_Risk__c> risks = new List<Account_Risk__c>{
                new Account_Risk__c(Account__c=accList[0].Id, Risk_Type__c='ML', Opportunities__c='006', Account_External_Id__c = accList[0].Id),
                    new Account_Risk__c(Account__c=accList[1].Id, Risk_Type__c='CX', CX_Score_Status__c='Fragile', Account_External_Id__c = accList[1].Id )
                    };
                        
            Test.startTest();
            insert risks;
            Test.stopTest();
            
            Integer countML = [SELECT count() FROM Risk_Profile__c WHERE Account__c = :accList[0].Id];
            Integer countCX = [SELECT count() FROM Risk_Profile__c WHERE Account__c = :accList[1].Id];
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
            Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();
            Custom_Configuration_Change__c cfg = new Custom_Configuration_Change__c(
                Config_For__c='ML Sync',
                Config_Type__c='Daily',
                Next_Run__c=Date.today().addDays(-1),
                RecordTypeId = recordTypeId
            );
            insert cfg;
            
            List<Account> a = [SELECT Id FROM Account LIMIT 4];
            Test.startTest();
            insert new Account_Risk__c(Account__c=a[3].Id, Risk_Type__c='ML', Account_External_Id__c = a[3].Id);
            Test.stopTest();
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
    
        @isTest
        static void testExpirePreviousMLRiskProfiles2() {
          System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            Risk_Profile__c rp = new Risk_Profile__c(
                Account__c = acc.Id,
                ML_Risk__c = true,
                Risk_Category__c = 'Prediction Model',
                Risk_Type__c = 'Entitlement Risk'
            );
            insert rp;
            Test.setCreatedDate(rp.Id, System.today().addDays(-10));
            rp.Risk_Type__c = 'Account Risk';
            update rp;
            Test.setCreatedDate(rp.Id, System.today().addDays(-5));
            Risk_Profile__c beforeUpdate = [
                SELECT Id, IsClosed__c, ML_Risk__c, Risk_Category__c, 
                       LastModifiedDate, CreatedDate, 
                       Risk_Reason_Additional_Comments__c 
                FROM Risk_Profile__c 
                WHERE Id = :rp.Id
            ];
            Account accNew = new Account(Name = 'New Account');
            insert accNew;
        
            Test.startTest();
            AccountRiskTriggerHelper.expirePreviousMLRiskProfiles();
            Test.stopTest();
            
            Risk_Profile__c afterUpdate = [
                SELECT Id, IsClosed__c, ML_Risk__c, Risk_Category__c, 
                       LastModifiedDate, CreatedDate, 
                       Risk_Reason_Additional_Comments__c 
                FROM Risk_Profile__c 
                WHERE Id = :rp.Id
            ];
              
            System.assertEquals(true, afterUpdate.ML_Risk__c);

          }
        }
    
}