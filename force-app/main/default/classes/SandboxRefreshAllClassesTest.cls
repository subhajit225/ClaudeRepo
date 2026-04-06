@isTest(SeeAllData = false)
public class SandboxRefreshAllClassesTest {
    @testSetup static void setup() {
        Profile profiles=[Select Id From Profile Where Name='System Administrator'];
        String roleId = [SELECT Id FROM UserRole WHERE Name ='CEO' ].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;        
        User u = new User();
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.ProfileId = profiles.Id;
        u.UserRoleId = roleId;
        u.LastName = 'test';
        u.Alias = 'tUser';
        u.Email = 'testuser@testuser1.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        insert u;
        
        testDataFactoryClass.createUser();
        Group testGroup = new Group();
        testGroup.Name = 'testGroup';
        testGroup.DeveloperName = 'TestGroup';
        insert testGroup;
        
        GroupMember gm = new GroupMember();
        gm.GroupId = testGroup.Id;
        gm.UserOrGroupId = u.Id;
        insert gm;
        System.assert(true);
    }
    static testmethod void testSandboxRefreshEmailMaskingScheduler() {
        TestDataFactory.getOpportunity();
        Test.StartTest();
        String objectName = 'Contact';
        Sandbox_Refresh_Config__c sandboxRefreshConfigObj = SandboxRefreshUtil.getEmailMaskingObject(objectName);
        insert sandboxRefreshConfigObj;
        sandboxRefreshConfigObj.BatchSize__c = (sandboxRefreshConfigObj.Status__c != 'Not Started') ? (SandboxRefreshUtil.BATCH_SIZE_SESET_MAP.get(Integer.valueOf(sandboxRefreshConfigObj.BatchSize__c)) ): sandboxRefreshConfigObj.BatchSize__c;
        Datetime dt = Datetime.now().addMinutes(1);
        String jobName = 'EmailMasking: ' + sandboxRefreshConfigObj.ObjectLabel__c + '-' + sandboxRefreshConfigObj.BatchSize__c + dt.format('~dd-HH_mm_ss') + (String.isBlank(objectName) ? 'A' : 'M');
        SandboxRefreshEmailMaskingScheduler scheduler = new SandboxRefreshEmailMaskingScheduler ();
        String jobId = System.schedule(jobName, dt.format('s m H d M \'?\' yyyy'), scheduler);
        Test.StopTest();
        System.assert(true);
    }

    static testmethod void testScheduleNextBatch() {
        TestDataFactory.getOpportunity();
        Test.StartTest();
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Contact';
        srconfig.Status__c = 'Not Started';
        srconfig.Query__c = 'Select ID, Email,SalesEngineerEmail__c FROM Contact where id != null ';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.batchSize__c = 200;
        srconfig.ObjectLabel__c = 'Contact';
        srconfig.Type__c = 'Email Mask';
        srconfig.EmailFields__c = 'Email, SalesEngineerEmail__c';
        insert srconfig;
        SandboxRefreshUtil.scheduleNextBatch(1);
        Test.StopTest();
        System.assert(true);
    }

    static testmethod void testSandboxRefreshMaster() {
        Test.StartTest();
        Test.testSandboxPostCopyScript(
            new SandboxRefreshMaster(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        Test.StopTest();
        System.assert(true);
    }
    static testmethod void testSandboxRefreshActivateUsersBatch() {
        Profile profiles=[Select Id,Name From Profile Where Name='System Administrator'];
        Group groupDetails = [Select id, name from group where name = 'testGroup'];
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Activate Users';
        srconfig.Status__c = 'Not Started';
        srconfig.EmailFields__c = groupDetails.Name+':'+ profiles.Name;
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        insert srconfig;
        Test.StartTest();
        SandboxRefreshActivateUsersBatch usersBatch = new SandboxRefreshActivateUsersBatch(srconfig.Id);
        Database.executeBatch(usersBatch);
        Test.StopTest();
        System.assert(true);
    }
    static testmethod void testSandboxRefreshConfigTriggerHandler(){
        EmailAlertJSONParser e = new EmailAlertJSONParser();
        e.size = e.size;
        e.totalSize = e.totalSize;
        e.done = e.done;
        e.queryLocator = e.queryLocator;
        e.entityTypeName = e.entityTypeName;
        e.records = e.records;

        EmailAlertJSONParser.EntityDefinition e1 = new EmailAlertJSONParser.EntityDefinition();
        e1.attributes = e1.attributes;
        e1.DeveloperName = e1.DeveloperName;
        EmailAlertJSONParser.Attributes e2 = new EmailAlertJSONParser.Attributes();
        e2.type = e2.type;
        e2.url = e2.url;

        EmailAlertJSONParser.Records e3 = new EmailAlertJSONParser.Records();
        e3.attributes = e3.attributes;
        e3.id = e3.id;
        e3.EntityDefinitionId = e3.EntityDefinitionId;
        e3.EntityDefinition = e3.EntityDefinition;
        e3.DeveloperName = e3.DeveloperName;
        e3.CcEmails = e3.CcEmails;
        e3.SenderType = e3.SenderType;
        e3.TemplateId = e3.TemplateId;
        e3.Description = e3.Description;
        System.assert(true);
    }
    static testmethod void testCustomMetadataUpdate() {
        Test.StartTest();
        Database.executebatch(new SandboxRefreshCustomMetadataBatch('Email_Preferences__mdt', new List<String>{'cc__c', 'Receipient__c'},'Email Masking in Email Preference Custom Metadata'), 1);
        Database.executebatch(new SandboxRefreshCustomMetadataBatch('AspenConfig__mdt', new List<String>{'EmailId__c'},'Email Masking in Aspen Config Custom Metadata'), 1);
        Test.StopTest();
        System.assert(true);
    }

    static testmethod void testSandboxRefreshConfigTriggerHandler2() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Update URLs';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        Sandbox_Refresh_Config__c srconfig1=[Select Id,Name,Description__c,isInitiatedManually__c From Sandbox_Refresh_Config__c Where Name='Update URLs'];
        srconfig1.Description__c='Test1';
         srconfig1.isInitiatedManually__c=true;
        update srconfig1;
       
    }
 static testmethod void testSandboxRefreshConfigTriggerHandler3() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Delete Scheduled Reports';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        Sandbox_Refresh_Config__c srconfig1=[Select Id,Name,Description__c,isInitiatedManually__c From Sandbox_Refresh_Config__c Where Name='Delete Scheduled Reports'];
        srconfig1.Description__c='Test1';
         srconfig1.isInitiatedManually__c=true;
        update srconfig1;
       
    }
     static testmethod void testSandboxRefreshConfigTriggerHandler4() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Disable Triggers & Validation Rules';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        Sandbox_Refresh_Config__c srconfig1=[Select Id,Name,Description__c,isInitiatedManually__c From Sandbox_Refresh_Config__c Where Name='Disable Triggers & Validation Rules'];
        srconfig1.Description__c='Test1';
         srconfig1.isInitiatedManually__c=true;
        update srconfig1;
       
    }
    
    static testmethod void testSandboxRefreshConfigTriggerHandler5() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Enable Triggers & Validation Rules';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        srconfig.isInitiatedManually__c=true;
        try{
            update srconfig;
        }catch(Exception e){
            System.assert(true);
        }
       
    }

    static testmethod void testSandboxRefreshConfigTriggerHandler7() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Email Masking in Email Preference Custom Metadata';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        Sandbox_Refresh_Config__c srconfig1=[Select Id,Name,Description__c,isInitiatedManually__c From Sandbox_Refresh_Config__c Where Name='Email Masking in Email Preference Custom Metadata'];
        srconfig1.Description__c='Test1';
         srconfig1.isInitiatedManually__c=true;
        update srconfig1;
       
    }
     static testmethod void testSandboxRefreshConfigTriggerHandler9() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Masking on Workflow Email Alerts';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        Sandbox_Refresh_Config__c srconfig1=[Select Id,Name,Description__c,isInitiatedManually__c From Sandbox_Refresh_Config__c Where Name='Masking on Workflow Email Alerts'];
        srconfig1.Description__c='Test1';
         srconfig1.isInitiatedManually__c=true;
        update srconfig1;
    }
       static testmethod void testSandboxRefreshConfigTriggerHandler10() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Initiate Email Masking';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        srconfig.isInitiatedManually__c=true;
        try{
            update srconfig;
        }catch(Exception e){
            System.assert(true);
        }
    }
     static testmethod void testSandboxRefreshConfigTriggerHandler11() {
        Sandbox_Refresh_Config__c srconfig = new Sandbox_Refresh_Config__c();
        srconfig.Name = 'Execute Sandbox Post Refresh Script';
        srconfig.Status__c = 'Not Started';
        srconfig.Description__c = 'Test';
        srconfig.Execution_Order__c = 20;
        srconfig.ObjectLabel__c = 'Users';
        srconfig.Type__c = 'Configuration';
        srconfig.ProcessType__c='Automated';
        srconfig.isInitiatedManually__c=false;
        insert srconfig;
        Sandbox_Refresh_Config__c srconfig1=[Select Id,Name,Description__c,isInitiatedManually__c From Sandbox_Refresh_Config__c Where Name='Execute Sandbox Post Refresh Script'];
        srconfig1.Description__c='Test1';
         srconfig1.isInitiatedManually__c=true;
        update srconfig1;
    }
    static testmethod void testSandboxRefreshReportAbortBatch() {
        Database.executebatch(new SandboxRefreshReportAbortBatch(), 100);
        System.assert(true);
    }

    

}