@IsTest
private class SupportOperationsUtility_Test {
    
    // Utility: query an existing System Administrator user
    private static User getAdminUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
    }
    
    // Utility: create custom setting record
    private static E2CAdv__EnhanceBlackListExcludeList__c createSetting(String typeValue, String emailValues) {
        E2CAdv__EnhanceBlackListExcludeList__c cs = new E2CAdv__EnhanceBlackListExcludeList__c(
            Name = typeValue + '-1',
            E2CAdv__Type__c = typeValue,
            E2CAdv__values__c = emailValues
        );
        insert cs;
        return cs;
    }
    
    @IsTest
    static void testGetEmailListDataAsAdmin() {
        User adminUser = getAdminUser();
        
        System.runAs(adminUser) {
            // Arrange
            String typeName = 'Exclude Email';
            String values = 'test@example.com;abc@example.com';
            E2CAdv__EnhanceBlackListExcludeList__c cs = createSetting(typeName, values);
            
            // Act
            Test.startTest();
            SupportOperationsUtility.CustomSettingWrapper result = SupportOperationsUtility.getEmailListData(typeName);
            Test.stopTest();
            
            // Assert
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(typeName, result.emailListType, 'Email list type should match');
            System.assertEquals(values, result.emailListValues, 'Email list values should match');
        }
    }
    
    @IsTest
    static void testSaveEmailListAsAdmin() {
        
        User adminUser = getAdminUser();
        
        System.runAs(adminUser) {
            
            // Arrange
            String typeName = 'Blacklist Email';
            String initialValues = 'init@example.com';
            createSetting(typeName, initialValues);
            
            String updatedValues = 'updated@example.com;new@example.com';
            
            // Act
            Test.startTest();
            SupportOperationsUtility.saveEmailList(typeName, updatedValues);
            Test.stopTest();
            
            // Assert
            List<E2CAdv__EnhanceBlackListExcludeList__c> records = [
                SELECT E2CAdv__values__c
                FROM E2CAdv__EnhanceBlackListExcludeList__c
                WHERE E2CAdv__Type__c = :typeName
            ];
            
            System.assertEquals(1, records.size(),
                                'Only one chunk should be created');
            
            System.assertEquals(
                'updated@example.com;new@example.com',
                records[0].E2CAdv__values__c,
                'Email list should exactly match updated values'
            );
        }
    }
    
    
    @IsTest
    static void testExceedingCharLimit() {
        User adminUser = getAdminUser();
        System.runAs(adminUser) { 
            String typeName = 'Blacklist Email';
            String longEmailList =
                'theta.user08@testdomain.fake;' +
                'iota.user09@testdomain.fake;' +
                'kappa.user10@testdomain.fake;' +
                'lambda.user11@testdomain.fake;' +
                'mu.user12@testdomain.fake;' +
                'test321@gcc.com;' +
                'alpha.user01@testdomain.fake;' +
                'beta.user02@testdomain.fake;' +
                'gamma.user03@testdomain.fake';
            
            createSetting(typeName, longEmailList);
            
            // Act
            Test.startTest();
            SupportOperationsUtility.saveEmailList(
                typeName,
                longEmailList + ';delta.user04@testdomain.fake'
            );
            Test.stopTest();
            
            // Assert
            List<E2CAdv__EnhanceBlackListExcludeList__c> records = [
                SELECT E2CAdv__values__c
                FROM E2CAdv__EnhanceBlackListExcludeList__c
                WHERE E2CAdv__Type__c = :typeName
            ];
            
            System.assert(
                records.size() > 1,
                'Multiple records should be created due to 255 char limit'
            );
            
            // Verify no data loss
            String combined = '';
            for (E2CAdv__EnhanceBlackListExcludeList__c rec : records) {
                combined += rec.E2CAdv__values__c + ';';
            }
            
            Set<String> emails = new Set<String>();
            
            for (String email : combined.split(';')) {
                if (String.isNotBlank(email)) {
                    emails.add(email.trim());
                }
            }
            System.assertEquals(
                10,
                emails.size(),
                'All emails should be preserved across chunks'
            );
        }
    }
    
    @IsTest
    static void testBlankEmailListDeletesAllRecords() {
        User adminUser = getAdminUser();
        System.runAs(adminUser) { 
            String typeName = 'Blacklist Email';
            createSetting(typeName, 'one@test.com;two@test.com');
            System.assertEquals(
                1,
                [SELECT COUNT() FROM E2CAdv__EnhanceBlackListExcludeList__c
                 WHERE E2CAdv__Type__c = :typeName]
            );
            Test.startTest();
            SupportOperationsUtility.saveEmailList(typeName, '   ');
            Test.stopTest();
            
            Integer remaining =
                [SELECT COUNT()
                 FROM E2CAdv__EnhanceBlackListExcludeList__c
                 WHERE E2CAdv__Type__c = :typeName];
            
            System.assertEquals(
                0,
                remaining,
                'All custom setting records should be deleted when input is blank'
            );
        }
    }
}