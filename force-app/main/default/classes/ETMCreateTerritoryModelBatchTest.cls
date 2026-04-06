/***************************************************************************************************************
Description : Test class for ETMCreateTerritoryModelBatch and folllowing chained ETM staging table processing
Developer : Chaitra
Date : 10/2019
*****************************************************************************************************************/

@isTest
public class ETMCreateTerritoryModelBatchTest {
    @testSetup 
    static void setup() {
      // createTerritory.createTerritory('TestTerr',) 
       // public static List<Territory2> createTerritory( String strTerritoryName, String adaptiveId, Id ModelId, Integer intCount )
        User user1 = createUserAdmin('tUser');
         user User2 = createUserAdmin('tUser1');
         user User3 = createUserAdmin('tUser3');
         User2.isActive = false ;
         update user2;
         List<Territory2> ExistingTerritory = new List<Territory2>();
         List<Territory2Model> TModel = new List<Territory2Model>();
         system.runas(user3){
               TModel = [select id,Name from territory2model where State ='Active'];
               ExistingTerritory = [select id, Adaptive_Territory_Id__c,ParentTerritory2.Adaptive_Territory_Id__c from territory2 where Territory2Model.Name= :TModel[0].Name and Territory2Model.State ='Active' and Territory2Type.DeveloperName ='Territory'  limit 4];

               //Create UTA for SalesEngineer
               List<UserTerritory2Association> salesEngineerUTA = new List<UserTerritory2Association>();
               salesEngineerUTA.add(new UserTerritory2Association(UserId = user1.Id, Territory2Id = ExistingTerritory[0].Id, RoleInTerritory2 = 'Sales Engineer'));
               salesEngineerUTA.add(new UserTerritory2Association(UserId = user3.Id, Territory2Id = ExistingTerritory[1].Id, RoleInTerritory2 = 'Sales Engineer'));
               insert salesEngineerUTA;
         }
         system.runas(user1){
          ETM_Territory_Controller__c etmCS = new ETM_Territory_Controller__c(Name = 'Con_OTA_LMDT',
                                                                            Field_API_Name__c='LastModifiedDate',
                                                                            Field_Value__c='2023-07-12T15:13:53Z',
                                                                            Operator__c='>',
                                                                            Field_Type__c='DateTime');
          insert etmCS;
          ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
          disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
          upsert disableFuncCS;
          ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance();
          disableBusinessLogicCS.Disable_ETMStageMonitoring_Triggers__c = true;
          upsert disableBusinessLogicCS;

          SOX_Objects_Delete_Access__c soxDel = SOX_Objects_Delete_Access__c.getInstance();
          soxDel.Allow_Account_Delete__c = true;
          upsert soxDel;
          
       List<ETMStage_Monitoring__c> MonitoringLog = new list<ETMStage_Monitoring__c>();
       List<UserTerritory2Association> ExistingUTA = new List<UserTerritory2Association>();
        /*List<ShGl_DisableFunctionalityLogic__c> funLogic = new List<ShGl_DisableFunctionalityLogic__c>();
        funLogic.add(new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Allow_account_Transfer__c = TRUE));
       funLogic.add(new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = user1.id, Allow_account_Transfer__c = TRUE));
       funLogic.add(new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = User3.id, Allow_account_Transfer__c = TRUE));
       insert funLogic; */
       if(!TModel.isEmpty()){
        ExistingUTA = [select UserId,Territory2Id,territory2.Adaptive_Territory_Id__c, RoleInTerritory2 from UserTerritory2Association where Territory2.Territory2Model.Name=:TModel[0].Name  and Territory2.Territory2Model.State ='Active' limit 4];
        ExistingUTA.addall([select UserId,Territory2Id,territory2.Adaptive_Territory_Id__c, RoleInTerritory2 from UserTerritory2Association where Territory2.Territory2Model.State ='Active' and RoleInTerritory2='Sales Engineer' limit 2]);
        }
       
       MonitoringLog.add(new ETMStage_Monitoring__c(Status__c='Init',name=TModel[0].Name)); //new
       MonitoringLog.add(new ETMStage_Monitoring__c(Status__c='Init',name=TModel[0].Name)); //new
       if(TModel.size()<4){ 
       MonitoringLog.add(new ETMStage_Monitoring__c(Status__c='Init',name='newETMModel_test')); //new
       MonitoringLog.add(new ETMStage_Monitoring__c(Status__c='Init',name='newETMModel_test')); //new
       }   
           
       
       insert MonitoringLog;
       system.debug('MonitoringLog'+MonitoringLog);
       
       
       List<Territory_Stage__c> stageList = new List<Territory_Stage__c>();
        for(integer i=0;i<30;i++){
        if(math.mod(i,2)==0){
        stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[0].id,SQL_Operation__c='add',Type__c='Territory'));
        stageList.add(new Territory_Stage__c(AdaptiveId__c= ExistingTerritory[0].Adaptive_Territory_Id__c, JobId__c=MonitoringLog[0].id,SQL_Operation__c='add',Type__c='Territory'));
        stageList.add(new Territory_Stage__c(AdaptiveId__c= ExistingTerritory[1].Adaptive_Territory_Id__c,Parent_Adaptive_Id__c=ExistingTerritory[0].ParentTerritory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[0].id,SQL_Operation__c='update',Type__c='Territory'));
        if(TModel.size()<4){ 
        stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add',Type__c='Territory'));
        stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[3].id,SQL_Operation__c='update',Type__c='Territory'));
        }
        }
        else if(math.mod(i,3)==0){
        stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add',Type__c='Theatre'));
        if(TModel.size()<4){ 
         stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[3].id,SQL_Operation__c='add',Type__c='Theatre'));
        }
        }
        else if(math.mod(i,5)==0){
        stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[0].id,SQL_Operation__c='add',Type__c='Area'));
         if(TModel.size()<4){ 
         stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add',Type__c='Area'));
        }
        }
        else if(math.mod(i,11)==0){
        stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[0].id,SQL_Operation__c='add',Type__c='Region')) ;
        if(TModel.size()<4){ 
         stageList.add(new Territory_Stage__c(AdaptiveId__c=String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add',Type__c='Theatre'));
        }
        }
        else{
             stageList.add(new Territory_Stage__c(AdaptiveId__c=ExistingTerritory[2].Adaptive_Territory_Id__c, JobId__c=MonitoringLog[1].id,SQL_Operation__c='delete',Type__c='Territory')); 
            if(TModel.size()<4){ 
         stageList.add(new Territory_Stage__c(AdaptiveId__c='11', JobId__c=MonitoringLog[3].id,SQL_Operation__c='delete',Type__c='Territory'));
        }
        }
       }
         stageList.add(new Territory_Stage__c(AdaptiveId__c='0909', JobId__c=MonitoringLog[1].id,SQL_Operation__c='add',Type__c='dummyType'));   
       insert stageList;
       for(ETMStage_Monitoring__c ETM_montr : MonitoringLog){
         ETM_montr.Status__c='New';
       }
       update MonitoringLog;
       
       List<UserTerritoryAssociation_Stage__c> UTAStageList = new List<UserTerritoryAssociation_Stage__c>();
       for(integer i=0;i<20;i++){
        if(math.mod(i,2)==0){
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add', RoleInTerritory2__c ='AccountExecutive', User__c=user1.id, Start_Date__c=system.today()));
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id,SQL_Operation__c='add', RoleInTerritory2__c ='AccountExecutive', User__c=user1.id, Start_Date__c=system.today()));
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id,SQL_Operation__c='add', RoleInTerritory2__c ='Sales Engineer', User__c=user3.id, Start_Date__c=system.today()));
        }
        else if(math.mod(i,3)==0){
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id,SQL_Operation__c='add', RoleInTerritory2__c ='AccountExecutive', User__c=user1.id, Start_Date__c=system.today()));
        if(TModel.size()<4){ 
                UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =ExistingUTA[0].territory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[0].id,SQL_Operation__c='update', RoleInTerritory2__c =ExistingUTA[0].RoleInTerritory2, User__c=ExistingUTA[2].UserId));
                UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =ExistingUTA[1].territory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[0].id,SQL_Operation__c='update', RoleInTerritory2__c =ExistingUTA[1].RoleInTerritory2, User__c=ExistingUTA[1].UserId));
                UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =ExistingUTA[0].territory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[1].id,SQL_Operation__c='add', RoleInTerritory2__c =ExistingUTA[0].RoleInTerritory2, User__c=ExistingUTA[2].UserId, Start_Date__c=system.today()));
                UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =ExistingUTA[3].territory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[0].id,SQL_Operation__c='delete', RoleInTerritory2__c =ExistingUTA[3].RoleInTerritory2, User__c=ExistingUTA[3].UserId, End_Date__c=system.today()));
                UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =ExistingUTA[2].territory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[0].id,SQL_Operation__c='delete', RoleInTerritory2__c ='test', User__c=user2.id, End_Date__c=system.today()));
                UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =ExistingUTA[4].territory2.Adaptive_Territory_Id__c, JobId__c=MonitoringLog[1].id,SQL_Operation__c='delete', RoleInTerritory2__c =ExistingUTA[4].RoleInTerritory2, User__c=ExistingUTA[4].UserId, End_Date__c=system.today()));

        }
        }
        else if(math.mod(i,5)==0){
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add', RoleInTerritory2__c ='AccountExecutive', Start_Date__c=system.today()));
        }
        else if(math.mod(i,11)==0){
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[2].id,SQL_Operation__c='add', RoleInTerritory2__c ='AccountExecutive', User__c=user2.id, Start_Date__c=system.today()));
        }
        else{
        UTAStageList.add(new UserTerritoryAssociation_Stage__c(Adaptive_Id__c ='11', JobId__c=MonitoringLog[3].id,SQL_Operation__c='add', RoleInTerritory2__c ='AccountExecutive', User__c=user1.id, Start_Date__c=system.today()));
        }
       }
       //UTAStageList.add(new UserTerritoryAssociation_Stage__c(name='testUnassignd', JobId__c=MonitoringLog[0].id,SQL_Operation__c='add', RoleInTerritory2__c ='SalesOps', User__c=user1.id));
       insert UTAStageList;
       List<Account> accList = testDataFactoryClass.createAccount(6,0);
       
       //List<opportunity> oppList = testDataFactoryClass.createOpporunity(accList);
        List<Opportunity> oppList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(),4,null);
        
        integer j=0;
        for(Opportunity opp: oppList){        
         opp.AccountId = accList[j].id;
         if(j==0)
         opp.Opportunity_Split_Parent__c = oppList[j+1].id;   
            j++;
        }       
        
        insert oppList;
        delete accList[5];
        accList[2].Adaptive_Territory_Id__c = String.valueOf(2);
        update accList[2];

       List<Account_Stage__c> AccStageList = new List<Account_Stage__c>();
       for(integer i=0;i<5;i++){
        if(math.mod(i,2)==0){
        AccStageList.add(new Account_Stage__c(TerritoryAdaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id, Account__c =accList[i].id,Account_Move_Reason__c='DNA (Do Not Assign)'));
        AccStageList.add(new Account_Stage__c(TerritoryAdaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id, Account__c =accList[i].id,Account_Move_Reason__c='DNA (Do Not Assign)'));
        AccStageList.add(new Account_Stage__c(TerritoryAdaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id, Account__c ='0211W00001qsqdU',Account_Move_Reason__c='DNA (Do Not Assign)'));
        }
        else{
        AccStageList.add(new Account_Stage__c(TerritoryAdaptive_Id__c =String.valueOf(i), JobId__c=MonitoringLog[0].id, Account__c ='0211W00001qsqdU',Account_Move_Reason__c='DNA (Do Not Assign)'));  // Invalid accountId
        }
       } 
             
       AccStageList.add(new Account_Stage__c(TerritoryAdaptive_Id__c = '123123', JobId__c = MonitoringLog[0].id, 
                                                              Account__c = accList[0].id, Account_Move_Reason__c='DNA (Do Not Assign)',
                                                              Territory_Structure_Type__c = 'PLS Cloud')); //SAL26-138:NAS to Cloud
       insert AccStageList;   
             
       accList[0].Non_Core_Adaptive_Territory_Ids__c  = '123,345';
       accList[0].Non_Core_Type_and_Adaptive_Id__c = 'PLS Cloud:123;PLS SaaS:345'; //SAL26-138:NAS to Cloud
       UPDATE accList[0];      
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
    
     static testmethod void createGlobalTerritoryTest() {
     ShGl_DisableFunctionalityLogic__c funcLogicCS = ShGl_DisableFunctionalityLogic__c.getInstance();
     funcLogicCS.ETM_Allow_Archiving_Territory_Model__c = true;
     upsert funcLogicCS;
     Test.startTest();
          delete [select id from ETMStage_Monitoring__c where name!='newETMModel_test'];
          Database.executeBatch(new ETMCreateTerritoryModelBatch(),10);          
     Test.stopTest();
     }       
      static testmethod void createTheatreTerritoryTest() {
     Test.startTest();
          ETMCreateTerritoryModelBatch TerrModel = new ETMCreateTerritoryModelBatch();
          TerrModel.setpriority_Test = 4; // territory type = Theatre
          Database.executeBatch(TerrModel,10);
          
     Test.stopTest();
     }  
     static testmethod void createTerritoryTest1() {
     Test.startTest();
          ETMCreateTerritoryModelBatch TerrModel = new ETMCreateTerritoryModelBatch();
          TerrModel.setpriority_Test = 1; // // territory type = Territory
          Database.executeBatch(TerrModel,10);
          
     Test.stopTest();
     }  
     static testmethod void ExistingModelTest() {
     Test.startTest();
          delete [select id from ETMStage_Monitoring__c where name='newETMModel_test'];
          ETMCreateTerritoryModelBatch TerrModel = new ETMCreateTerritoryModelBatch();
          TerrModel.setpriority_Test = 1; // // territory type = Territory
          Database.executeBatch(TerrModel,10);
     Test.stopTest();
     }
     static testmethod void scheduleJobTest() {
     Test.startTest();
          ETMCreateTerritoryModelBatch TerrModel = new ETMCreateTerritoryModelBatch();
          TerrModel.setpriority_Test = 1; // // territory type = Territory
          DateTime testDate = Datetime.now().addminutes(1);
         String hour = String.valueOf(testDate.hour()); 
        String minute = String.valueOf(testDate.minute());
        String second = String.valueOf(testDate.second());  
        String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
        System.schedule('ETMCreateTerritoryModelBatchTest_' + String.valueOf(Datetime.now()), nextFireTime, TerrModel);
          
     Test.stopTest();
     }    
     static testmethod void ETMClearMonitoringLogsTest() {
     Test.startTest();
         DateTime testDate = Datetime.now().addminutes(1);
         String hour = String.valueOf(testDate.hour()); 
        String minute = String.valueOf(testDate.minute());
        String second = String.valueOf(testDate.second());  
        String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
        System.schedule('ETMClearMonitoringLogsTest_' + String.valueOf(Datetime.now()), nextFireTime, new ETMClearMonitoringLogs(' order by createddate'));
          
     Test.stopTest();
     }  
    
    @istest static void testETMAdaptiveUpdateOnAccount() {
        Test.startTest();
        
        territory2model tModel = [SELECT id,Name FROM territory2model WHERE State ='Active' LIMIT 1];
        territory2 existingTerritory = [SELECT id, Adaptive_Territory_Id__c,ParentTerritory2.Adaptive_Territory_Id__c 
                             FROM territory2 WHERE Territory2Model.Name= :tModel.Name 
                             AND Territory2Model.State ='Active' AND Territory2Type.DeveloperName ='Territory' Limit 1];
		existingTerritory.Territory_Structure_Type__c = 'PLS Cloud';//SAL26-138:NAS to Cloud
        existingTerritory.Adaptive_Territory_Id__c = '123123';
        UPDATE existingTerritory;
        
        Set<Id> monitoringLogIds = new Set<Id>();
        for(ETMStage_Monitoring__c monitor : [SELECT Id FROM ETMStage_Monitoring__c]) {
            monitoringLogIds.add(monitor.Id);
        }

        Database.executeBatch(new ETMAdaptiveUpdateOnAccountBatch(monitoringLogIds, tModel.Name));
     Test.stopTest();
     }       
}