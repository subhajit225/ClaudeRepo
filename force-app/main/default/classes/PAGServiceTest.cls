/*
@ Class Name :-
@ Author :- Rubrik Dev
@ Created Date :- July 5th , 2023
@ Description : CPQ22-3109 :- Test Class for CPQ_CSATUtility
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
* Rubrik Dev           01/10/2025       added methods for PQL service
* 
// ********************Modification Log *****************************************************************************
*/
@isTest
public class PAGServiceTest {
    /** 
     * @description method to create test data
     */
    @testSetup
    public static void setupData(){
        //Disable trigger
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                            Disable_Campaign_Trigger__c = true,
                                                                            Disable_Campaign_Validation_Rules__c = true,
                                                                            Disable_Order_Validation_Rules__c=true, 
                                                                            Disable_ServiceContract_Trigger__c=true,
                                                                            Disable_Entitlement_Usage_Trigger__c=true,
                                                                            Disable_Entitlement_Trigger__c=true,
                                                                            Disable_Asset_Triggers__c=true);    
        insert cdf;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser1 = new User(
            FirstName = 'Test', LastName = 'User', Email = 'testuserPQL@example.com',
            Username = 'testuserPQL@example.com', Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id);
        insert testUser1;
        User testUser2 = new User(
            FirstName = 'Test', LastName = 'User2', Email = 'testuserPQL2@example.com',
            Username = 'testuserPQL2@example.com', Alias = 'tuser2', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id);
        insert testUser2;
        List<Territory2> terr_List = [Select id, Territory2Type.DeveloperName, Adaptive_Territory_Id__c,(Select id,RoleInTerritory2 from UserTerritory2Associations where RoleInTerritory2 IN ('SABU AE','SaaS AE','NAS AE')) from Territory2 where Territory2.Territory2Model.State = 'Active' and Territory2.Territory2Type.DeveloperName = 'Territory' and Adaptive_Territory_Id__c!='' limit 2];
        System.runAs(new User(Id=UserInfo.getUserId())) {   
            UserTerritory2Association UTA2 = new UserTerritory2Association();
            UTA2.UserId = testUser2.Id; 
            UTA2.Territory2Id = terr_List[0].Id; // Use the first Territory2 record's ID
            UTA2.RoleInTerritory2 = 'Rubrik X';
            insert UTA2;
            UserTerritory2Association UTA3 = new UserTerritory2Association();
            UTA3.UserId = UserInfo.getUserId(); 
            UTA3.Territory2Id = terr_List[0].Id; // Use the first Territory2 record's ID
            UTA3.RoleInTerritory2 = 'SaaS AE';
            insert UTA3;
            UserTerritory2Association UTA4 = new UserTerritory2Association();
            UTA4.UserId = testUser1.Id; 
            UTA4.Territory2Id = terr_List[1].Id; // Use the first Territory2 record's ID
            UTA4.RoleInTerritory2 = 'NAS AE';
            insert UTA4;
        }
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.Adaptive_Territory_Id__c = terr_List[0].Adaptive_Territory_Id__c;
        act.Non_Core_Type_and_Adaptive_Id__c = 'PLS NAS:123;PLS SaaS:'+terr_List[0].Adaptive_Territory_Id__c;
        act.Non_Core_Adaptive_Territory_Ids__c = '123,'+terr_List[0].Adaptive_Territory_Id__c;
        insert act;
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act1.Adaptive_Territory_Id__c = terr_List[1].Adaptive_Territory_Id__c;
        act1.Non_Core_Type_and_Adaptive_Id__c = 'PLS NAS:'+terr_List[1].Adaptive_Territory_Id__c;
        act1.Non_Core_Adaptive_Territory_Ids__c = terr_List[1].Adaptive_Territory_Id__c;
        act1.Name = 'Test Account';
        insert act1;
        List<Account> accList = new List<Account>();
        accList.add(act);
        Assert.areEqual(1, accList.size());
    }

    static testMethod void  testPAGCreation() {
        User u = [Select id from user where Email ='testuserPQL@example.com' limit 1];
		System.runAs(u) {
            Account act = [Select id from Account Limit 1];
            String requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 1.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Trial_ID__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Status__c": "ACTIVE","Account__c": "'+act.ID+'","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request = new RestRequest();
            RestContext.response = new RestResponse();
            RestContext.request.requestURI = '/services/apexrest/CreateAndExtendPAGTrials';
            RestContext.request.httpMethod = 'POST';
    
            RestContext.request.requestBody = Blob.valueof(requestBody);
    
    
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
    
            Test.startTest(); 
            PAGService2.createTrials();
            
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 1.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Trial_ID__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Status__c": "ACTIVE","Account__c": "'+act.ID+'","Start_Date__c":"2035-12-22","End_Date__c":"2036-12-12","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.createTrials();           
            
            ID pagID = [Select ID from Product_Assisted_Growth__c where Trial_ID__c = 'Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1'].ID;
            RestContext.request.httpMethod = 'PATCH';
            //Create Entitlements
            requestBody = '{"entitlements":[{"entWrapper":{"entitlementRecord":{"RSC_Entitlement_Id__c":"TestClass-pag-1-2","AccountId":"' + act.Id + '","StartDate":"2035-12-22","EndDate":"2036-12-12","PAG__c":"'+pagID+'","PAG_Features__c":"M365, Sonar, Sonar for M365","Name":"RS-UR-EE-MD-PE-PP"},"SKU":"RS-UR-EE-MD-PE-PP"}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.ExtendTrials();              
            
            requestBody = '{"entitlements":[{"entWrapper":{"entitlementRecord":{"RSC_Entitlement_Id__c":"TestClass-pag-1-2","AccountId":"' + act.Id + '","StartDate":"2036-12-22","EndDate":"2037-12-12","PAG__c":"'+pagID+'","Name":"RS-UR-EE-MD-PE-PP"},"SKU":"RS-UR-EE-MD-PE-PP"}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.ExtendTrials();
            
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 0.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Trial_ID__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Status__c": "ACTIVE","Account__c": "'+act.ID+'","ID":"'+pagID+'","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.ExtendTrials();
            
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 0.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Trial_ID__c" : "Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1Trial_1Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Status__c": "ACTIVE","Account__c": "'+act.ID+'","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.ExtendTrials();           
            
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 1.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Status__c": "ACTIVE","Account__c": "'+act.ID+'","ID":"'+pagID+'","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.ExtendTrials();    
            
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 1.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Trial_ID__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Status__c": "ACTIVE","Account__c: "'+act.ID+'","ID":"'+pagID+'","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.ExtendTrials();    
            
            RestContext.request.httpMethod = 'POST';
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Score__c": 1.0,"Usage_Dashboard__c" : "https://rubrik.com","Trial_Ignored__c": true,"Trial_ID__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Status__c": "ACTIVE","Account__c: "'+act.ID+'","ID":"'+pagID+'","Trial_type__c": "M365","Trial_Duration__c": 10}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PAGService2.createTrials();    
            
            Test.stopTest(); 
            System.assertEquals([Select ID from Product_Assisted_Growth__c where Trial_ID__c = 'Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1'].ID, pagID, 'PAG is created.');
        }                     
    }
    static testMethod void  testPQLCreation() {
        User u = [Select id from user where Email ='testuserPQL@example.com' limit 1];
		System.runAs(u) {
            Account act = [Select id from Account Limit 1];
            Account act2 = [Select id from Account where name = 'Test Account' limit 1];
            String requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "SaaS","Request_Type__c": "PQL","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PLS_AE_ETM_Role_Name__c":"SaaS AE","PQL_External_Id__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request = new RestRequest();
            RestContext.response = new RestResponse();
            RestContext.request.requestURI = '/services/apexrest/CreateOrUpdatePQL';
            RestContext.request.httpMethod = 'POST';        
            RestContext.request.requestBody = Blob.valueof(requestBody);
            Test.startTest(); 
            PQLService.CreatePQL(); 
            String pagID = [Select PQL_External_Id__c from Product_Assisted_Growth__c limit 1].PQL_External_Id__c;
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "SaaS","Request_Type__c": "PQL","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PLS_AE_ETM_Role_Name__c":"SaaS AE","PQL_External_Id__c" : "'+pagID+'","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            RestContext.request.httpMethod = 'PATCH';
            PQLService.UpdatePQL(); 
            RestContext.request.httpMethod = 'PATCH';
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "SaaS","Request_Type__c": "","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PLS_AE_ETM_Role_Name__c":"SaaS AE","PQL_External_Id__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PQLService.UpdatePQL();         
            RestContext.request.httpMethod = 'PATCH';
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "Unstructured","Request_Type__c": "","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PLS_AE_ETM_Role_Name__c":"SaaS AE","PQL_External_Id__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Account__c": "'+act2.ID+'"}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PQLService.UpdatePQL();
            Test.stopTest(); 
            System.assertEquals('Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1',pagID, 'PQL is created.');
        }
    }
    
    static testMethod void  testPQLCreationWithExternalAndPQLId() {
        User u = [Select id from user where Email ='testuserPQL@example.com' limit 1];
		System.runAs(u) {
            Account act = [Select id from Account Limit 1];
            String requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "Unstructuredd","Request_Type__c": "PQL","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PQL_External_Id__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request = new RestRequest();
            RestContext.response = new RestResponse();
            RestContext.request.requestURI = '/services/apexrest/CreateOrUpdatePQL';
            RestContext.request.httpMethod = 'POST';        
            RestContext.request.requestBody = Blob.valueof(requestBody);
            Test.startTest(); 
            PQLService.CreatePQL();
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "Unstructuredd","Request_Type__c": "","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PQL_External_Id__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PQLService.CreatePQL();
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "Unstructured","Request_Type__c": "PQL","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","PQL_External_Id__c" : "Trial_Id_Trial_Id_Trial_Id_Trial_Id_Trial_Id_1","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PQLService.CreatePQL();
            ID pagID = [Select ID from Product_Assisted_Growth__c Limit 1].ID;
            requestBody = '{"pags": [{"pagWrapper": {"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "Unstructuredd","Request_Type__c": "PQL","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","Id" : "'+pagID+'","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request.httpMethod = 'PATCH'; 
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PQLService.UpdatePQL();
            requestBody = '{"pags": [{"pagWrapper": ""{"pagRecord": {"Usage_Dashboard__c" : "https://rubrik.com","Overage_Product_Type__c": "Unstructuredd","Request_Type__c": "PQL","Total_Used_Capacity__c": "20","Total_Licensed_Capacity__c": "80","Id" : "'+pagID+'","Account__c": "'+act.ID+'"}}}]}';
            RestContext.request.httpMethod = 'PATCH'; 
            RestContext.request.requestBody = Blob.valueof(requestBody);
            PQLService.UpdatePQL();  
            Test.stopTest();
            System.assertEquals(act.Id,[Select id from Account Limit 1].Id, 'Acc is created.');
        }
    }
    
}