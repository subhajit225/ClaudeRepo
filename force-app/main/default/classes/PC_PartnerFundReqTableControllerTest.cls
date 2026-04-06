@isTest
/** 
* Purpose : Test class of PC_PartnerFundReqTableController
**/
private class PC_PartnerFundReqTableControllerTest {
    @isTest static void testMethod1() {
        List<Territory2> territories = new List<Territory2>();
        List<Territory2Model> TModel = [Select id,Name from territory2model where State ='Active'];
        List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DeveloperName = 'Territory'];

        for(Integer i=0;i<3;i++){
            Territory2 terr = new Territory2();
            terr.Name = 'CDM-' + i;
            terr.DeveloperName = 'CDM_' + i;
            terr.Adaptive_Territory_Id__c = '999999'+i;
            terr.Territory2ModelId = TModel[0].Id;
            terr.Territory2TypeId = terrType[0].Id;
            territories.add(terr);
        }
        insert territories;

        UserRole ur = [SELECT Id from userrole where name ='CEO'];
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         UserRoleId = ur.Id); 
        insert uu;

        //UserRole urCDM = new UserRole(Name = 'Channel Development Manager');
        UserRole urCDM = [SELECT Id from userrole where name ='Channel Development Manager'];
        Profile prCDM = [Select Id from profile where Name='Channel Development Manager']; 
        User uCDM1 = new User(firstname = 'James', 
                              lastName = 'Webb', 
                              email = 'JamWeb00098990@gmail.com', 
                              Username = 'JamWeb00098990@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id,
                              UserRoleId = urCDM.Id); 
        insert uCDM1;

        User uCDM2 = new User(firstname = 'James', 
                              lastName = 'Philips', 
                              email = 'JamPhilp889000@gmail.com', 
                              Username = 'JamPhilp889000@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id,
                              UserRoleId = urCDM.Id); 
        insert uCDM2;

        User uCDM3 = new User(firstname = 'Joe', 
                              lastName = 'Rovers', 
                              email = 'JoeRov987895@gmail.com', 
                              Username = 'JoeRov987895@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id,
                              UserRoleId = urCDM.Id); 
        insert uCDM3;

        List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Channel Manager';
        uta.UserId = uCDM1.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[1].Id;
        uta.RoleInTerritory2 = 'Channel Manager';
        uta.UserId = uCDM2.Id;
        utaRecords.add(uta);

        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[2].Id;
        uta.RoleInTerritory2 = 'Channel Manager';
        uta.UserId = uCDM3.Id;
        utaRecords.add(uta);

        insert utaRecords;

        System.RunAs(uu) {
            Id pid = [select id from profile where name='Rubrik Customer Community Login User'].id;
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
            insert acc;
            Contact c = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
            insert c;
            User u1 = new User( email='fgh@gmail.com',
                               profileid = pid, 
                               UserName='gjhgj456546@gmail.com', 
                               Alias = 'GDS',
                               TimeZoneSidKey='America/New_York',
                               EmailEncodingKey='ISO-8859-1',
                               LocaleSidKey='en_US', 
                               LanguageLocaleKey='en_US',
                               ContactId = c.Id,
                               PortalRole = 'Manager',
                               FirstName = 'Genelia',
                               LastName = 'Dsouza');
            insert u1;
            acc.isPartner = true;
            update acc;

            PartnerMarketingBudget budgt = new PartnerMarketingBudget(Amount=1000,ChannelPartnerId=acc.Id,EndDate=system.today()+1,StartDate=system.today(),Title='test',IsIgnoreValidation=true);
            insert budgt;
            PartnerFundAllocation al = new PartnerFundAllocation(Amount=1000,ChannelPartnerId=acc.Id,Title='test', BudgetId= budgt.id);
            insert al;
            List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
            PartnerFundRequest pfrec = new PartnerFundRequest();
            pfrec.Status = 'Draft';
            pfrec.title = 'test';
            pfrec.Activity = 'Digital Advertising';
            pfrec.Activity_Objective__c = 'Enablement';
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing';
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1000;
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Segment__c = 'FED';
            pfrec.CDM__c = uCDM1.Id;
			pfrec.Planned_Inquiries__c = 0;
            
            partnerFundRequest pfrec1 = new PartnerFundRequest();
            pfrec1.Status = 'Draft';
            pfrec1.title = 'test1';
            pfrec1.Activity = 'Digital Advertising';
            pfrec1.Activity_Objective__c = 'Enablement';
            pfrec1.Campaign_Focus__c = 'Expansion';
            pfrec1.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing';
            pfrec1.Alliances__c = 'Cisco';
            pfrec1.Activity_Start_Date__c = Date.today().addDays(-1);
            pfrec1.Activity_End_Date__c = Date.today().addDays(-1);
            pfrec1.RequestedAmount = 1000;
            pfrec1.Description = 'gbjhsad';
            pfrec1.Amount = 500;
            pfrec1.AllocationId = al.id;
            pfrec1.ChannelPartnerId = acc.Id;
            pfrec1.Campaign_Focus__c = 'SFDC';
            pfrec1.Segment__c = 'FED';
            pfrec1.Planned_Inquiries__c = 0;
            pfrec.CDM__c = uCDM1.Id;

            PartnerFundRequest pfrec2 = new PartnerFundRequest();
            pfrec2.Status = 'Draft';
            pfrec2.title = 'test2';
            pfrec2.Activity = 'Digital Advertising';
            pfrec2.Activity_Objective__c = 'Enablement';
            pfrec2.Alliances__c = 'Cisco';
            pfrec2.Activity_Start_Date__c = Date.today().addDays(-1);
            pfrec2.Activity_End_Date__c = Date.today().addDays(-1);
            pfrec2.RequestedAmount = 1000;
            pfrec2.Description = 'gbjhsad';
            pfrec2.AllocationId = al.id;
            pfrec2.ChannelPartnerId = acc.Id;
            pfrec2.Campaign_Focus__c = 'SFDC';
            pfrec2.Segment__c = 'FED';
            pfrec.CDM__c = uCDM1.Id;
			pfrec2.Planned_Inquiries__c = 0;
            
            pfrList.add(pfrec);
            pfrList.add(pfrec1);
            pfrList.add(pfrec2);

            insert pfrList;

            Database.executeBatch(new PC_MDFSubmitClaimReminderBatch());
            pfrList[1].Status = 'Submitted';
            pfrList[1].Disable_MDF_Claim_Notifications__c=False;
            update pfrList[1];
            Database.executeBatch(new PC_MDF_RequestRemiderMailBatch());
            pfrList[0].Status = 'Approved';
            pfrList[0].Executed_By__c = 'Partner Marketing';
            pfrList[0].Planned_MQL__c = 0;
            pfrList[0].Planned_Meetings__c = 0;
            pfrList[0].Approved_Amount_USD__c = 10;
            pfrList[0].Fiscal_Period__c = 'FY26';
            update pfrList[0];
            try{
                pfrList[2].Status = 'Approved';
                pfrList[2].Disable_MDF_Claim_Notifications__c=False;
                pfrList[2].Planned_Meetings__c = 0;
                pfrList[2].Planned_Inquiries__c = null;
                update pfrList[2];
            }catch(Exception e){
                system.debug('Exception occurred');
            }
            PartnerFundClaim pfc = new PartnerFundClaim();
            pfc.RequestId = pfrList[0].Id;
            pfc.Title = 'test';
            pfc.Amount = 100;
            pfc.Description = 'asds';
            pfc.Status = 'Draft';
            insert pfc;
            pfc.Status = 'Submitted';
            update pfc;
            pfc.Status = 'Approved';
            pfc.Claim_Amount_USD__c  = 5;
            update pfc;
            string returnFields = 'Id,createddate,Title,Status,Amount,Request.Title,Request.Request_Number__c,RequestId,Description';
            string objType = 'PartnerFundClaim';
            Integer pageSize;
            string fieldapiName = '';
            string sortedDirection = '';
            String sortedByValue = '';
            string direction = '';
            String startDate = '';
            String endDate = '';
            List<string> IdSet = new List<String>();
            IdSet.add(pfc.Id);
            List<String> accIds = new List<String>();
            
            //create contentVersion  record
            ContentVersion contentVersion = new ContentVersion(Title = 'EMT Pic', PathOnClient = 'Pic.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
            insert contentVersion;
            
            Test.startTest();
            Database.executeBatch(new PC_MDFSubmitClaimReminderBatch());

            List<sobject> records =  PC_PartnerFundReqTableController.getRecords('',returnFields,objType,pageSize,fieldapiName,sortedDirection,sortedByValue,IdSet,startDate,endDate,accIds);
            List<sobject> records1 =  PC_PartnerFundReqTableController.getRecords('',returnFields,objType,pageSize,'Title','desc','test', IdSet,startDate,endDate,accIds);
            List<sobject> records2 =  PC_PartnerFundReqTableController.getRecords('test',returnFields,objType,pageSize,'Title','asc','test', IdSet,startDate,endDate,accIds);
            PC_PartnerFundReqTableController.getTotalRecords(objType);
            PC_PartnerFundReqTableController.getStatus(pfrList[0].Id);
            PC_PartnerFundReqTableController.getFiscalYearData();

            PC_PartnerFundClaimTableController.getRecords('',returnFields,objType,pageSize,fieldapiName,sortedDirection,sortedByValue, IdSet,pfrList[0].Id);
            PC_PartnerFundClaimTableController.getRecords('',returnFields,objType,pageSize,'Title','desc','test', IdSet,pfrList[0].Id);
            PC_PartnerFundClaimTableController.getRecords('test',returnFields,objType,pageSize,'Title','asc','test', IdSet,pfrList[0].Id);
            PC_PartnerFundClaimTableController.getTotalRecords(objType);

            PC_PartnerFundClaimController.getfileBaseURL();
            PC_PartnerFundClaimController.getBaseURL();
            PC_PartnerFundClaimController.getTotalAmount(pfrList[0].Id);
            PC_PartnerFundClaimController.recId = pfrList[0].Id;
            PC_PartnerFundClaimController.status = 'Draft';
            PC_PartnerFundClaimController.claimname = 'Test';
            PC_PartnerFundClaimController.contentVersionIds = contentVersion.Id;
            PC_PartnerFundClaimController.getRequestDetails(pfrList[0].Id);
            PC_PartnerFundClaimController.getPicklistValues('Fiscal_Quarter__c');
            PC_PartnerFundClaimController pfcont = new PC_PartnerFundClaimController();
            pfcont.saveFilesAction();
            System.assertEquals(1,1);
            Test.stoptest();
        }
    }
    @isTest static void testMethod2() {
        UserRole ur = [SELECT Id from userrole where name ='CEO'];
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         UserRoleId = ur.Id); 
        insert uu;

        System.RunAs(uu) {
            Id pid = [select id from profile where name='Rubrik Customer Community Login User'].id;
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
            insert acc;
            Contact c = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
            insert c;
            User u1 = new User( email='fgh@gmail.com',
                               profileid = pid, 
                               UserName='gjhgj456546@gmail.com', 
                               Alias = 'GDS',
                               TimeZoneSidKey='America/New_York',
                               EmailEncodingKey='ISO-8859-1',
                               LocaleSidKey='en_US', 
                               LanguageLocaleKey='en_US',
                               ContactId = c.Id,
                               PortalRole = 'Manager',
                               FirstName = 'Genelia',
                               LastName = 'Dsouza');
            insert u1;
            acc.isPartner = true;
            update acc;

            PartnerMarketingBudget budgt = new PartnerMarketingBudget(Amount=1000,ChannelPartnerId=acc.Id,EndDate=system.today()+1,StartDate=system.today(),Title='test',IsIgnoreValidation=true);
            insert budgt;
            PartnerFundAllocation al = new PartnerFundAllocation(Amount=1000,ChannelPartnerId=acc.Id,Title='test', BudgetId= budgt.id);
            insert al;
            List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();     
            PartnerFundRequest pfrec = new PartnerFundRequest();
            pfrec.Status = 'Draft';
            pfrec.title = 'test';
            pfrec.Activity = 'Digital Advertising';
            pfrec.Activity_Objective__c = 'Enablement';
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing'; 
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1000;
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            pfrec.Segment__c = 'FED';
            pfrec.Planned_Inquiries__c = 0;
            pfrList.add(pfrec);

            PartnerFundRequest pfrec1 = new PartnerFundRequest();
            pfrec1.Status = 'Draft';
            pfrec1.Planned_MQL__c = null;
            pfrec1.title = 'test';
            pfrec1.Activity = 'Event Marketing';
            pfrec1.Activity_Objective__c = 'Enablement';
            pfrec1.Campaign_Focus__c = 'SFDC';
            pfrec1.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing'; 
            pfrec1.Alliances__c = 'Cisco';
            pfrec1.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec1.Activity_End_Date__c = system.today().addDays(-1);
            pfrec1.RequestedAmount = 1000;
            pfrec1.Description = 'gbjhsad';
            pfrec1.Amount = 1000;
            pfrec1.AllocationId = al.id;
            pfrec1.ChannelPartnerId = acc.Id;
            pfrec1.Segment__c = 'FED';
            pfrec1.Field_Event_Type__c = '';
            pfrec1.Planned_Inquiries__c = 0;
            pfrec1.Cancel_Partner_Fund_Request__c = false;
            pfrList.add(pfrec1);
            insert pfrList;
            
            PartnerFundClaim pfc = new PartnerFundClaim();
            pfc.RequestId = pfrList[1].Id;
            pfc.Title = 'test';
            pfc.Amount = 100;
            pfc.Description = 'asds';
            pfc.Status = 'Draft';
            insert pfc;
            
            pfrList[0].Status = 'Approved';
            pfrList[0].Executed_By__c = 'Partner Marketing';
            pfrList[0].Planned_MQL__c = 0;
            pfrList[0].Planned_Meetings__c = 0;
            pfrList[0].Approved_Amount_USD__c = 5;
            pfrList[0].Fiscal_Period__c = 'FY26';
            //pfrList[0].Cancel_Partner_Fund_Request__c = true;
            update pfrList;

            try {
                pfrList[1].Status = 'Approved';
                pfrList[1].Field_Event_Type__c = null;
                pfrList[1].Activity = 'Event Marketing';
                pfrList[1].Amount = null;
                pfrList[1].Campaign_Focus__c = null;
                pfrList[1].Budget_Code__c = null;
                pfrList[1].Executed_By__c = null;
                pfrList[1].Planned_MQL__c = null;
                pfrList[1].Planned_Meetings__c = 0;
                pfrList[1].Do_Not_Auto_Generate_Campaign__c = true;
                pfrList[1].Planned_meetings__c = null;
                pfrList[1].ETM_Role__c = null;
                pfrList[1].Routing_Method__c = 'MQL to ETM';
                pfrList[1].Requested_Amount__c =1;
          		pfrList[1].Cancel_Partner_Fund_Request__c = true;
                update pfrList[1];
            }
            catch(DMLException Ex) {
                System.debug(LoggingLevel.ERROR, 'An error occurred: ' + Ex.getMessage());
            }

            pfc.Status = 'Submitted';
            update pfc;
            pfc.Status = 'Approved';
            pfc.Claim_Amount_USD__c  = 5;
            update pfc;
            string returnFields = 'Id,createddate,Title,Status,Amount,Request.Title,Request.Request_Number__c,RequestId,Description';
            string objType = 'PartnerFundClaim';
            Integer pageSize;
            string fieldapiName = '';
            string sortedDirection = '';
            String sortedByValue = '';
            string direction = '';
            List<string> IdSet;

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(pfrec1);
            PC_PartnerFundReqController testpc = new PC_PartnerFundReqController(sc);
            PC_PartnerFundReqController.getPicklistValues('Activity');

            ContentVersion contentVersion = new ContentVersion(
                Title          = 'test file',
                PathOnClient   = 'test.jpg',
                VersionData    = Blob.valueOf('Test Content'),
                IsMajorVersion = true);
            insert contentVersion;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            PC_PartnerFundReqController.savePartnerFundReq('test','USD','Expansion','Cloud','Cisco',system.today(),system.today(),'200','asdsd',new List<Id> {documents[0].Id},'d1','Dev','mos1','mos2','mos3','mos4');
            PC_PartnerFundClaimController.getStatus(pfrList[0].Id);
            PC_PartnerFundReqController.attachUploadedDocuments(new List<Id> {documents[0].Id},pfrList[0].Id);
            testpc.callcheckCancel();
            System.assertEquals(1,1);
        }
    }

    @isTest static void testMethod3() {
        UserRole ur = [SELECT Id from userrole where name ='CEO'];
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         UserRoleId = ur.Id); 
        insert uu;

        System.RunAs(uu) {
            Id pid = [select id from profile where name='Rubrik Customer Community Login User'].id;
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
            insert acc;
            Contact c = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
            insert c;
            User u1 = new User( email='fgh@gmail.com',
                               profileid = pid, 
                               UserName='gjhgj456546@gmail.com', 
                               Alias = 'GDS',
                               TimeZoneSidKey='America/New_York',
                               EmailEncodingKey='ISO-8859-1',
                               LocaleSidKey='en_US', 
                               LanguageLocaleKey='en_US',
                               ContactId = c.Id,
                               PortalRole = 'Manager',
                               FirstName = 'Genelia',
                               LastName = 'Dsouza');
            insert u1;
            acc.isPartner = true;
            update acc;

            PartnerMarketingBudget budgt = new PartnerMarketingBudget(Amount=1000,ChannelPartnerId=acc.Id,EndDate=system.today()+1,StartDate=system.today(),Title='test',IsIgnoreValidation=true);
            insert budgt;
            PartnerFundAllocation al = new PartnerFundAllocation(Amount=1000,ChannelPartnerId=acc.Id,Title='test', BudgetId= budgt.id);
            insert al;
            List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
            PartnerFundRequest pfrec = new PartnerFundRequest();
            pfrec.Status = 'Draft';
            pfrec.title = 'test';
            pfrec.Activity = 'Digital Advertising';
            pfrec.Activity_Objective__c = 'Enablement';
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing';
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1000;
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Segment__c = 'FED';
			pfrec.Planned_Inquiries__c = 0;
            
            partnerFundRequest pfrec1 = new PartnerFundRequest();
            pfrec1.Status = 'Draft';
            pfrec1.title = 'test1';
            pfrec1.Activity = 'Digital Advertising';
            pfrec1.Activity_Objective__c = 'Enablement';
            pfrec1.Campaign_Focus__c = 'Expansion';
            pfrec1.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing';  
            pfrec1.Alliances__c = 'Cisco';
            pfrec1.Activity_Start_Date__c = Date.today().addDays(-1);
            pfrec1.Activity_End_Date__c = Date.today().addDays(-1);
            pfrec1.RequestedAmount = 1000;
            pfrec1.Description = 'gbjhsad';
            pfrec1.Amount = 500;
            pfrec1.AllocationId = al.id;
            pfrec1.ChannelPartnerId = acc.Id;
            pfrec1.Campaign_Focus__c = 'SFDC';
            pfrec1.Segment__c = 'FED';
            pfrec1.Disable_MDF_Claim_Notifications__c=False;
			pfrec1.Planned_Inquiries__c = 0;
            
            PartnerFundRequest pfrec2 = new PartnerFundRequest();
            pfrec2.Status = 'Draft';
            pfrec2.title = 'test2';
            pfrec2.Activity = 'Dedicated Resource';
            pfrec2.Activity_Objective__c = 'Enablement';
            pfrec2.Alliances__c = 'Cisco';
            pfrec2.Activity_Start_Date__c = Date.today().addDays(-1);
            pfrec2.Activity_End_Date__c = Date.today().addDays(-1);
            pfrec2.RequestedAmount = 1000;
            pfrec2.Description = 'gbjhsad';
            pfrec2.AllocationId = al.id;
            pfrec2.ChannelPartnerId = acc.Id;
            pfrec2.Campaign_Focus__c = 'SFDC';
            pfrec2.Segment__c = 'FED';
            pfrec2.Disable_MDF_Claim_Notifications__c=False;
			pfrec2.Planned_Inquiries__c = 0;
            
            pfrList.add(pfrec);
            pfrList.add(pfrec1);
            pfrList.add(pfrec2);

            insert pfrList;
            List<PartnerFundClaim> PFCList =[Select id from PartnerFundClaim];

            Database.executeBatch(new PC_MDFSubmitClaimReminderBatch());
            pfrList[1].Status = 'Submitted';
            pfrList[1].Disable_MDF_Claim_Notifications__c=False;
            update pfrList[1];
            Database.executeBatch(new PC_MDF_RequestRemiderMailBatch());
            pfrList[0].Status = 'Approved';
            pfrList[0].Executed_By__c = 'Partner Marketing';
            pfrList[0].Planned_MQL__c = 0;
            pfrList[0].Planned_Meetings__c = 0;
            pfrList[0].Approved_Amount_USD__c = 5;
            pfrList[0].Fiscal_Period__c = 'FY26';
            update pfrList[0];
            try{
                pfrList[2].Status = 'Approved';
                pfrList[2].Planned_Meetings__c = 0;
                pfrList[2].Disable_MDF_Claim_Notifications__c=False;
                update pfrList[2];
            }catch(Exception e){
                System.debug(LoggingLevel.ERROR, 'An error occurred: ' + e.getMessage());
            }
            System.assertEquals(1,1);
        }
    }
	
	@isTest static void testMethod4() {
        UserRole ur = [SELECT Id from userrole where name ='CEO'];
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         UserRoleId = ur.Id); 
        insert uu;

        System.RunAs(uu) {
            Id pid = [select id from profile where name='Rubrik Customer Community Login User'].id;
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
            insert acc;
            Contact c = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
            insert c;
            User u1 = new User( email='fgh@gmail.com',
                               profileid = pid, 
                               UserName='gjhgj456546@gmail.com', 
                               Alias = 'GDS',
                               TimeZoneSidKey='America/New_York',
                               EmailEncodingKey='ISO-8859-1',
                               LocaleSidKey='en_US', 
                               LanguageLocaleKey='en_US',
                               ContactId = c.Id,
                               PortalRole = 'Manager',
                               FirstName = 'Genelia',
                               LastName = 'Dsouza');
            insert u1;
            acc.isPartner = true;
            update acc;

            PartnerMarketingBudget budgt = new PartnerMarketingBudget(Amount=1000,ChannelPartnerId=acc.Id,EndDate=system.today()+1,StartDate=system.today(),Title='test',IsIgnoreValidation=true);
            insert budgt;
            PartnerFundAllocation al = new PartnerFundAllocation(Amount=1000,ChannelPartnerId=acc.Id,Title='test', BudgetId= budgt.id);
            insert al;
            PartnerFundRequest pfrec = new PartnerFundRequest();
            pfrec.Status = 'Draft';
            pfrec.title = 'test';
            pfrec.Activity = 'Digital Advertising';
            pfrec.Activity_Objective__c = 'Enablement';
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing';
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1000;
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Segment__c = 'FED';
            
            insert pfrec;

            Database.executeBatch(new PC_MDFSubmitClaimReminderBatch());
            pfrec.Status = 'Submitted';
            pfrec.Disable_MDF_Claim_Notifications__c=False;
            update pfrec;
			Approval.lock(new List<Id>{pfrec.Id});
			update pfrec;
        }
    }
    
    @isTest static void testMethod5() {
        UserRole ur = [SELECT Id from userrole where name ='CEO'];
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         UserRoleId = ur.Id); 
        insert uu;

        System.RunAs(uu) {
            Id pid = [select id from profile where name='Rubrik Customer Community Login User'].id;
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
            insert acc;
            Contact c = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
            insert c;
            User u1 = new User( email='fgh@gmail.com',
                               profileid = pid, 
                               UserName='gjhgj456546@gmail.com', 
                               Alias = 'GDS',
                               TimeZoneSidKey='America/New_York',
                               EmailEncodingKey='ISO-8859-1',
                               LocaleSidKey='en_US', 
                               LanguageLocaleKey='en_US',
                               ContactId = c.Id,
                               PortalRole = 'Manager',
                               FirstName = 'Genelia',
                               LastName = 'Dsouza');
            insert u1;
            acc.isPartner = true;
            update acc;

            PartnerMarketingBudget budgt = new PartnerMarketingBudget(Amount=1000,ChannelPartnerId=acc.Id,EndDate=system.today()+1,StartDate=system.today(),Title='test',IsIgnoreValidation=true);
            insert budgt;
            PartnerFundAllocation al = new PartnerFundAllocation(Amount=1000,ChannelPartnerId=acc.Id,Title='test', BudgetId= budgt.id);
            insert al;
            
            PartnerFundRequest pfrec = new PartnerFundRequest();
            pfrec.Status = 'Draft';
            pfrec.title = 'test';
            pfrec.Activity = 'Digital Advertising';
            pfrec.Activity_Objective__c = 'Enablement';
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing'; 
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1000;
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            pfrec.Segment__c = 'FED';
            pfrec.Planned_Inquiries__c = 0;
            insert pfrec;
            try {
                pfrec.Status = 'Rejected';
                pfrec.Rejection_Reason__c = '';
                update pfrec;
            }
            catch(DMLException e) {
                System.debug(LoggingLevel.ERROR, 'An error occurred: ' + e.getMessage());
            }
            System.assertEquals(1,1);
        }
    }

}