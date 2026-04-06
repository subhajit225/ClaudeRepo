/*******************************************************************************************************
Description : Test Class for UserTerritoryAssociationHistoryHelper
Developer : Natesh
Date : 06/15/2020
**********************************************************************************************************/
@isTest
private class UserTerritoryAssociationHistoryTest {
    
    @testSetup 
    static void setup() {
        User adminUser1 = createUserAdmin('tAdmin1');
        User adminUser2 = createUserAdmin('tAdmin2');
        User adminUser3 = createUserAdmin('tAdmin3');
        User tUser1 = createUser('tUser1');
        User tUser2 = createUser('tUser2');
        User tUser3 = createUser('tUser3');
        List<Territory2> territories = new List<Territory2>();

        system.runas(adminUser1){
            List<Territory2Model> TModel = [select id,Name from territory2model where State ='Active'];
            List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DEveloperNAme = 'Territory'];
            
            for(Integer i=0;i<3;i++){
                Territory2 terr = new Territory2();
                terr.Name = 'TEST-TERR-' + i;
                terr.DeveloperName = 'TEST_TERR_' + i;
                terr.Adaptive_Territory_Id__c = '999999'+i;
                terr.Territory2ModelId = TModel[0].Id;
                terr.Territory2TypeId = terrType[0].Id;
                territories.add(terr);
            }
            insert territories;
        }

        List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = tUser1.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[1].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = tUser2.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[2].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = tUser3.Id;
        utaRecords.add(uta);
        system.runas(adminUser2){
            insert utaRecords;
        }
    }

    static User createUser(String alias) {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Rubrik Field Sales User']; //Rubrik Field Sales User
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin@randomtestdomain.com',
            Alias = alias,
            Email = System.now().millisecond() + 'random1.email@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(sysAdmin);
        return sysAdmin;
    }   
    static User createUserAdmin(String alias) {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin123@randomtestdomain.com',
            Alias = alias,
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(sysAdmin);
        return sysAdmin;
    }

    @IsTest
    static void testCreateAndUpdateUTAHistory(){
        List<User> tUsers = [select Id from User where alias = 'tUser3'];
        List<User> tadminUsers = [select Id from User where alias = 'tAdmin3'];
        Test.startTest();
        system.assertEquals(3, [select count() from UserTerritoryAssociation_History__c]);
        UserTerritory2Association utaToDelete = [select Id from UserTerritory2Association where UserId=:tUsers[0].Id];
        System.runAs(tadminUsers[0]){
            delete utaToDelete;
        }
        //test createErrLogs method
        UserTerritoryAssociationHistoryHelper.CreateErrLogs('Test Error Message','Test Stack Tracing', 'ETM-UTA-History-Update-Test', 'UserTerritoryAssociationHistoryTest');
        
        //test BATCH call
        //System.enqueueJob(new UserTerritoryAssociationHistoryHelper(new Set<Id>(), new Set<Id>(), 'BATCH'));
        System.enqueueJob(new UserTerritoryAssociationHistoryHelper(new Map<Id, Date>(), new Map<Id, Date>(), new Set<Id>(), 'BATCH'));

        Test.stopTest();
        system.assertEquals(1, [select count() from UserTerritoryAssociation_History__c where End_date__c != null]);
    }
}