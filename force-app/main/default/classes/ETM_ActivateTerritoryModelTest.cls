/**
 * @File Name          : ETM_ActivateTerritoryModelTest.cls
 * @Description        : 
 * @Author             : Bhushan Patil
 * @Group              : 
 * @Last Modified By   : Bhushan Patil
 * @Last Modified On   : 6/3/2020, 12:07:44 pm
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    6/3/2020        Bhushan Patil            Initial Version
**/
@isTest
Private class ETM_ActivateTerritoryModelTest {
    
    @isTest static void testActivateTerritory() {
        List<Territory2Model> lstModels = [select id,Name,state from Territory2Model];
        List<Territory2Model> lstModel = new List<Territory2Model>();
        //List<Territory2Model> lstModeltoDelete = new List<Territory2Model>();
        for(Territory2Model objModel : lstModels){
            if(objModel.state == 'Planning' 
            || objModel.state == 'Active' ){
              lstModel.add(objModel);
                break;
            }
        }
        if(lstModel.isEmpty()){
            //delete lstModeltoDelete;
            lstModel = ETM_TestDataFactory.createTerritoryModel('Test FY',1);
          Insert lstModel;
        }
        ETM_ActivateTerritoryModel obj = new ETM_ActivateTerritoryModel(new set<id>(),lstModel[0].Name,'test');
        obj.activatingTerritory = true; 
        String hour = String.valueOf(Datetime.now().hour()); 
        String minute = String.valueOf(Datetime.now().minute() + 2);
        String second = String.valueOf(Datetime.now().second());  
        String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
        System.schedule('ETM_ActivateTerritoryModel_' + String.valueOf(Datetime.now()), nextFireTime, obj);
        ETMStage_Monitoring__c etmStg =new ETMStage_Monitoring__c(Status__c='New',name='newETMModel_test');
        insert etmStg;
        ETM_ActivateTerritoryModel.UpdateTerritoryLogs(new set<id>{etmStg.id},'territory Activated','Test model');
        ETM_ActivateTerritoryModel.CreateErrUpdateTerrLog('Exception','Exception',new set<id>{etmStg.id},'territory Activated','Test model');
    }
}