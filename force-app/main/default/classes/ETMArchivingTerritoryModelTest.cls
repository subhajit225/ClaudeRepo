/**
 * @File Name          : ETM_ArchivingTerritoryModelTest.cls
 * @Description        : 
 * @Author             : Bhushan Patil
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 6/3/2020, 12:03:23 pm
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    5/3/2020          Bhushan Patil         Initial Version
**/
@isTest
Private class ETMArchivingTerritoryModelTest {
    
    @isTest static void testArchiveTerritory() {
        User user1 = createUserAdmin('tUser1');
        User user2 = createUserAdmin('tUser2');
        set<id> monitorid = new set<Id>(); 
        List<Territory2Model> lstModels = [select id,Name from Territory2Model where state = 'Active'];
        List<Territory2Model> archlstModel = [select id,Name from Territory2Model where state = 'Archived' order by LastModifiedDate limit 1];
        system.runas(user1){  
          if(lstModels.isEmpty()){
            lstModels = ETM_TestDataFactory.createTerritoryModel('Test FY',1);
            Insert lstModels;
          }
          //lstModels = ETM_TestDataFactory.createTerritoryModel('Test_FY_New',1);
          //Insert lstModels;
        }
        
        system.runas(user2){ 
          List<ETMStage_Monitoring__c> lstMonitor = ETM_TestDataFactory.createMoniter('Test_FY_New',1);
          Insert lstMonitor;
          
          monitorid.add(lstMonitor[0].id);
          
          ETMArchieveTerritoryModel obj = new ETMArchieveTerritoryModel(new set<id>(),archlstModel[0]?.Name);
          String hour = String.valueOf(Datetime.now().hour()); 
          String minute = String.valueOf(Datetime.now().minute() + 2);
          String second = String.valueOf(Datetime.now().second());  
          String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
          Test.startTest();
          System.enqueueJob(obj);
          ETMArchieveTerritoryModel.CreateErrUpdateTerrLog('Exception','Exception',monitorid,'Complete',lstModels[0].Name);
          Test.stopTest();
        }

    }
    static User createUserAdmin(string alias) {
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
}