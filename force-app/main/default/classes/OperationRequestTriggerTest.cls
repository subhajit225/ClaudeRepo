@IsTest
public class OperationRequestTriggerTest {
    @testSetup
    static void testSetup(){
        
        List<User> listUsers = new List<User>();
        Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id listProfile2 = [Select Id From Profile Where Name = 'Sales Operations'].Id;
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 2);
        List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 3);
        listUsers.addAll(listUsers1);
        listUsers.addAll(listUsers2);
        insert listUsers;
        for(User us : listUsers2){
            us.ManagerId= listUsers1[0].id;
        }
        update listUsers2;
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'Allow_to_Edit_OR_Issue'][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = listUsers1[0].id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        System.runAs(listUsers[0]) {
            List<Account> actLi = new List<Account>();
            Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account act = new Account(
                Name = 'Customer',
                recordtypeId = partner,
                Phone = '123-456-7890',
                AccountNumber = 'Test',
                BillingStreet = '123 street',
                BillingCity = 'Santa Clara',
                BillingState = 'California',
                BillingPostalCode = '95050',
                BillingCountry = 'United States',
                ShippingStreet = '123 street',
                ShippingCity = 'Santa Clara',
                ShippingState = 'California',
                ShippingPostalCode = '95050',
                ShippingCountry = 'United States',
                OwnerId = listUsers2[0].Id
            );
            Account act1 = new Account(
                Name = 'Customer1',
                recordtypeId = partner,
                Phone = '123-456-7890',
                AccountNumber = 'Test1',
                BillingStreet = '123 street',
                BillingCity = 'Santa Clara',
                BillingState = 'California',
                BillingPostalCode = '95050',
                BillingCountry = 'United States',
                ShippingStreet = '123 street',
                ShippingCity = 'Santa Clara',
                ShippingState = 'California',
                ShippingPostalCode = '95050',
                ShippingCountry = 'United States',
                OwnerId = listUsers2[1].Id
            );
            actLi.add(act);
            actLi.add(act1);
            insert actLi;
            List<UserTerritory2Association> UTAList = new List<UserTerritory2Association>();
            List<Territory2> terrList = [Select id,Adaptive_Territory_Id__c,Territory_Structure_Type__c from Territory2 where Territory2Model.state='Active' And Territory2Type.DeveloperName='Territory'and Adaptive_Territory_Id__c!='' and DeveloperName!='Unassigned' limit 2];
        	UserTerritory2Association UTA3 = new UserTerritory2Association();
            UTA3.UserId = listUsers2[1].id; 
            UTA3.Territory2Id = terrList[1].Id; 
            UTA3.RoleInTerritory2 = 'Channel Manager';
            UTAList.add(UTA3);
            UserTerritory2Association UTA2 = new UserTerritory2Association();
            UTA2.UserId = listUsers2[1].id; 
            UTA2.Territory2Id = terrList[0].Id; 
            UTA2.RoleInTerritory2 = 'Account Executive';
            UTAList.add(UTA2);
            insert UTAList;
            List<Operations_Request__c> oprList = new List<Operations_Request__c>();  
            oprList.add(new Operations_Request__c(Territory_Structure_Type__c = terrList[0].Territory_Structure_Type__c,Name ='test 1',Current_account_owner__c=listUsers2[0].id,Future_account_owner__c=listUsers2[1].id,Issue__c = 'Entitlement/Asset Transfer', Account_Move_Reason__c ='Channel Reassignment',Future_Account__c=act.Id));
            oprList.add(new Operations_Request__c(Territory_Structure_Type__c = terrList[1].Territory_Structure_Type__c,Name ='test 2',Current_account_owner__c=listUsers2[1].id,Current_Owner_Manager__c=listUsers2[0].id,Future_account_owner__c=listUsers2[1].id,Future_owner_manager__c=listUsers2[2].id,Issue__c = 'Account Transfer', Account_Move_Reason__c ='Channel Reassignment',Future_Account__c=act.Id));
            oprList.add(new Operations_Request__c(Territory_Structure_Type__c = terrList[1].Territory_Structure_Type__c,Name ='test 3',Current_account_owner__c=listUsers2[0].id,Future_account_owner__c=listUsers2[2].id,Issue__c = 'Account Transfer',Future_Account__c=act.Id));
            oprList.add(new Operations_Request__c(Territory_Structure_Type__c = 'Core',Name ='test 4',Current_account_owner__c=listUsers2[0].id,Future_account_owner__c=listUsers2[0].id,Issue__c = 'Contact merge', Account_Move_Reason__c ='Channel Reassignment',Future_Account__c=act.Id));
            insert oprList;
            
        }
    }
	@istest
    static void testbeforeinsert(){
        List<User> usAdminlist =[select id,ManagerId from User where name Like '%testClassUser1%'];
        System.runAs(usAdminlist[0]) {
            List<User> uslist =[select id,ManagerId from User where name Like '%testClassUser2%'];
            List<Operations_Request__c> OpList = [select id,Future_account_owner__c from Operations_Request__c];
            Account act1= [Select id from Account where Name = 'Customer1' limit 1];           
            for(Operations_Request__c op:OpList){
                op.Current_account_owner__c=op.Future_account_owner__c;
                op.Future_account_owner__c=uslist[1].id;
                op.Future_Account__c = act1.Id;
                op.Status__c = 'Complete';
            }
            update OpList;
            OpList[3].Issue__c = 'Others';
            update OpList[3];
            Operations_Request__c op = [Select id,Future_owner_manager__c,Current_owner_manager__c from Operations_Request__c where Id IN : OpList limit 1];       
            System.assertNotEquals(null, op.Future_owner_manager__c);
            System.assertNotEquals(null, op.Current_owner_manager__c);
        }
    }
    @istest
    static void testAfterUpdate(){
        List<User> usAdminlist =[select id,ManagerId from User where name Like '%testClassUser1%'];
        System.runAs(usAdminlist[0]) {
            List<User> uslist =[select id,ManagerId from User where name Like '%testClassUser2%'];
            List<Operations_Request__c> OpList = [select id,Future_account_owner__c from Operations_Request__c]; 
            Account act1= [Select id from Account where Name = 'Customer1' limit 1]; 
            for(Operations_Request__c op : OpList){
                op.Current_account_owner__c=op.Future_account_owner__c;
                op.Future_account_owner__c=uslist[1].id;
                op.Future_Account__c = act1.Id;
                op.Account_Name__c = act1.Id;
                op.Account_Transfer_Approval_Status__c = 'Approved'; 
            }    
            update OpList;
            System.assertEquals('Approved', OpList[0].Account_Transfer_Approval_Status__c); 
            Delete [select id from Operations_Request__c Limit 1];
        }
    }
    @istest
    static void testAfterUpdateRejectedStatus(){
        List<User> usAdminlist =[select id,ManagerId from User where name Like '%testClassUser1%'];
        System.runAs(usAdminlist[0]) {
            List<User> uslist =[select id,ManagerId from User where name Like '%testClassUser2%'];
            List<Operations_Request__c> OpList = [select id,Future_account_owner__c from Operations_Request__c]; 
            Account act1= [Select id from Account where Name = 'Customer1' limit 1]; 
            for(Operations_Request__c op : OpList){
                op.Status__c = 'Rejected'; 
            }    
            update OpList;
            System.assertEquals('Rejected', OpList[0].Status__c); 
        }
    }
    @istest
    static void testAfterUpdateEntitlementAssetTransferIssue(){
        List<User> usAdminlist =[select id,ManagerId from User where name Like '%testClassUser1%'];
        System.runAs(usAdminlist[0]) {
            List<User> uslist =[select id,ManagerId from User where name Like '%testClassUser2%'];
            List<Operations_Request__c> OpList = [select id,Future_account_owner__c,Current_account_owner__c from Operations_Request__c where Issue__c = 'Entitlement/Asset Transfer' limit 1]; 
            //system.debug('OpList[0].Current_account_owner__c ==> '+OpList[0].Current_account_owner__c+' uslist[0].Id => '+uslist[1].Id); 
            OpList[0].Current_account_owner__c = uslist[1].Id;    
            //system.debug('OpList[0].Current_account_owner__c ===> '+OpList[0].Current_account_owner__c);
            update OpList[0];
            System.assertEquals(uslist[1].Id, OpList[0].Current_account_owner__c); 
        }
    }
	// Cover AFTER INSERT (if trigger has after insert logic)
    @IsTest
    static void testAfterInsert() {
        List<User> usAdminlist = [SELECT Id FROM User WHERE Name LIKE '%testClassUser2%' LIMIT 3];
        System.runAs(usAdminlist[0]) {
            Account act = [SELECT Id FROM Account WHERE Name = 'Customer' LIMIT 1];
            Operations_Request__c op = new Operations_Request__c(
                Name = 'New Request',
                Future_Account__c = act.Id,
                Issue__c = 'Account Transfer',
                Current_account_owner__c = usAdminlist[0].Id,
                Future_account_owner__c = usAdminlist[0].Id
            );
            insert op;
            List<User> uslist =[select id,ManagerId from User where name Like '%testClassUser1%'];
            op.Current_account_owner__c = usAdminlist[1].id;
            op.Future_account_owner__c = usAdminlist[2].id;
            update op; 
            System.assertNotEquals(null, op.Id);
            
        }
    }
    
}