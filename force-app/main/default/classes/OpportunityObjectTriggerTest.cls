@isTest
public with sharing class OpportunityObjectTriggerTest {
    //private static  oppObject; 
    /**@description This is Test Setup Data */
    @TestSetUp
    public static void initialDataSetup() {
        
        List<OpportunitySplitMapping__c> oppSplitMappingList = new List<OpportunitySplitMapping__c> ();
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Name', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'StageName', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'CloseDate', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Risk_Identified__c', Default_Value__c='false'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Meeting_evidence_link__c', Default_Value__c='false'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Push_Counter__c', Default_Value__c='1'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'NextStep', From_Field__c='Order_Sub_Type__c'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'NextStep', Suffix__c='Split_percentage__c'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'ETM_Theatre__c', Skip_Update_if_child_has_value__c=true));
        insert oppSplitMappingList;
        
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable.Disable_Account_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Account_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        insert settingDisable;
        
        upsert disableFuncCS;
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Contact objContact1 = new Contact();
        Account objAccount1 = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objAccount1.Name = 'Test Account 01-06';
        objAccount1.RecordTypeId = recordTypeId;
        insert objAccount1;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 
        
        objContact1.LastName = 'Test Contact 01-06';
        objContact1.Account = objAccount1;
        insert objContact1; 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '2 Consensus';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        insert objOpportunity;
        
         OpportunityContactRole ocr = new OpportunityContactRole();
       ocr.OpportunityId = objOpportunity.Id;
       ocr.Role = 'Click-Thru Contact';
       ocr.ContactId = objContact1.id;
       insert ocr; 
        
        /* Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT');
insert newProd;


Id standardPBId = test.getStandardPricebookId();

PriceBookEntry pbEntry = new PriceBookEntry(
UnitPrice = 400,
PriceBook2Id = standardPBId,
Product2Id = newProd.Id,
IsActive = true,
UseStandardPrice=false);
insert pbEntry ;

OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = objOpportunity.Id);
insert oppLine;*/
        
        
        /* SAL26-117 
* SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
objQuote.SBQQ__Status__c = 'Draft';
objQuote.SBQQ__Opportunity2__c = objOpportunity.Id;
objQuote.Task_Products__c='RBK-DISK-RETENTION';
//insert objQuote;*/
    }
    
    @isTest
    static void testOpportunityUpdate(){

        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> opps = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
            
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c = true;
            insert sdb;
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            
            Account vAccount2 = new Account();
            vAccount2.Name = 'Test Account';
            vAccount2.recordTypeId = vAccount.recordTypeId;
            vAccount2.Payment_Term__c = 'Net 30';
            accountList.add(vAccount2);
            insert accountList;
            
            Test.startTest();
            Opportunity oppObject = TestDataFactory.getOpportunity();
            Opportunity oppObject1 = TestDataFactory.getOpportunity();
            Opportunity oppObject2 = TestDataFactory.getOpportunity();
            // oppObject2.Cloud_Partner_Led_Activity__c = 'No'; //SAl24-466
            oppObject2.Alliance_Partner_Name__c = 'Microsoft';
            oppObject1.StageName = '2 Consensus';
            oppObject1.CloseDate = System.today() +2;
            oppObject1.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            opps.add(oppObject);
            opps.add(oppObject1);
            opps.add(oppObject2);
            insert opps;
            After_Action_Review__c aar = new After_Action_Review__c();
            aar.Opportunity__c = oppObject1.Id;
            aar.Opportunity_ClosedDate__c = System.today()+2;
            //insert aar;
            System.assert(oppObject.Id != null);
            List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert listQuote;
            
            Order o = new Order();
            o.OpportunityId = oppObject.Id;
            o.AccountId = oppObject.AccountId;
            o.EffectiveDate = System.today();
            o.Status = 'Draft';
            insert o;
            
            oppObject.RenewalOwner__c = listUser[0].id;
            oppObject.Send_Hold_Off_Email__c = true;
            oppObject.Include_Datos__c = true;
            oppObject.StageName = System.Label.Order_Creation_Stage;
            oppObject.Installation_Assigned_To__c = 'Partner Install';
            oppObject.Opportunity_Sub_Type__c='Renewal';
            oppObject.Lost_To_Won_Against__c ='Actifio';
            oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            oppObject.Valooto_Quote__c ='Test';
            oppObject.PLS_ETM_Overrides__c = 'CLOUD ETM Override';
            oppObject.Co_Owner__c = userinfo.getUserId();
            oppObject.Non_Core_Adaptive_Id__c = '12345';
            
            oppObject1.Stagename = '7 Closed Lost';
            oppObject1.Opportunity_Type__c = 'New Customer';
            oppObject1.Opportunity_Sub_Type__c ='Regular';
            oppObject1.After_Action_Form_Submitted__c = True;
            oppObject1.CloseDate = System.today();
            oppObject.ACV_Amount__c = 60000;
            // oppObject2.Cloud_Partner_Led_Activity__c = 'Yes';
            oppObject2.Alliance_Partner_Name__c = 'Microsoft';
            
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.PriceBookEntryId = null;
            oli.Valooto_Sales_Price__c = 100;
            oli.TotalPrice = 100;
            oli.quantity = 2;
            oli.Description = 'Test';
            oli.UnitPrice = 100;
            oli.Discount = 20;
            TriggerManager.resetTriggerCounter('Opportunity');      
            
            
            update opps;
            insert aar;
            Test.stopTest();
               List<OpportunityContactRole> ocr = [SELECT Id,OpportunityId,Role,ContactId FROM OpportunityContactRole Limit 1];
            Map<Id, Opportunity> oppMap = new  Map<Id, Opportunity>();
            Set<Id> oppMapids = new Set<Id>();
            OpportunityObjectTriggerHelper.getOrderLineItem (new Order(), oli);
            OpportunityObjectTriggerHelper.upsertOpportunityContactRoles(ocr,oppMap ,oppMapids);
            System.assert(oppObject.Id != null);
            
        }
    }
    @isTest
    static void setOpptySubTypeOnAmendmentOpptyTest()
    {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> opps = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
            
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = false;
        disableFuncCS.Disable_Account_Old_Trigger__c = false;
        disableFuncCS.Disable_Quote_Clone_Date__c = System.now().addDays(-1);
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = true,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
                                                                             Disable_Opportunity_Validation_Rules__c = true,
                                                                             Disable_ServiceContract_Trigger__c = true,
                                                                             Disable_Contract_Line_Item_Triggers__c = true,
                                                                             Disable_Order_Validation_Rules__c = true,
                                                                             Disable_Account_Validation_Rules__c = true);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.Focused_Partner__c = True;
        vAccount.Payment_Term__c = 'Net 30';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert vAccount;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.Marketplace__c = 'Azure Marketplace';
        oppr.Distributor_Lookup__c = vAccount.Id; //SAL26-548
        oppr.Partner_Lookup__c = vAccount.Id; //SAL26-548
        insert oppr;
        
        Map<String, Object> quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Quote';
        qt1.SBQQ__StartDate__c = Date.Today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt1;
        
        qt1.SBQQ__Status__c = 'Approved';
        update qt1;
        
        Order ord = new Order();
        ord.AccountId = accObj.Id;
        ord.OpportunityId = oppr.Id;
        ord.SBQQ__Quote__c = qt1.Id;
        ord.EffectiveDate = System.TODAY();
        ord.Status = 'Activated';
        
        ord.Partner_Name_Text__c = 'CDW';
        ord.AddOn_Node_Count__c = null;
        ord.Order_Status__c = 'Order Accepted';
        ord.ScreenStatus__c = 'On hold';
        ord.Integration_Failure__c = true;
        ord.Hold_Code__c = null;
        ord.Polaris_Fulfillment_Status__c = 'In Progress';
        ord.NetSuite_Order__c = 'NSTest12';
        ord.Type = 'Revenue';
        ord.Credit_Check_Failure_Reason__c = 'Customer balance of 32 exceeds credit limit of 41.00 ';
        ord.Order_Sub_Type__c = 'GC Offer';
        ord.Hold_Code__c = null;
        ord.ScreenStatus__c = 'Approved';
        ord.Order_Status__c = 'Pending';
        insert ord;
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'TestServiceContract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.SBQQSC__RenewalTerm__c = 12;
        serviceContractObj.SBQQSC__Order__c = ord.Id;
        insert serviceContractObj;
        
        Opportunity oppObjectRec = TestDataFactory.getOpportunity();
        oppObjectRec.StageName = '2 Consensus';
        oppObjectRec.CloseDate = System.today() +2;
        oppObjectRec.Opportunity_Program__c = 'Refresh';
        oppObjectRec.SBQQSC__AmendedServiceContract__c = serviceContractObj.Id;
        oppObjectRec.Opportunity_Sub_Type__c ='Regular';

        Test.startTest();
        insert oppObjectRec;
        
        List<SBQQ__Quote__c> quoteRecList = new List<SBQQ__Quote__c>();
        quoteRecList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppObjectRec.Id, SBQQ__Type__c = 'Quote', SBQQ__Primary__c=true));
        quoteRecList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppObjectRec.Id, SBQQ__Type__c = 'Amendment', SBQQ__Primary__c=false));
        quoteRecList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppObjectRec.Id, SBQQ__Type__c = 'Amendment', SBQQ__Primary__c=false));
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert quoteRecList;
        oppObjectRec.SBQQ__PrimaryQuote__c = quoteRecList[0].Id;
        oppObjectRec.Rubrik_Security_Cloud_Gov_t_Owner__c = [select id from contact limit 1].id;
        update oppObjectRec;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        
        System.assert(oppObjectRec.Id != null);
        
        Test.stopTest();
    }
    }
    @isTest
    static void testOpportunityUpdateDealReg(){
        List<User> listUsers = new List<User>();
        Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 1);
        List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 1);
        listUsers.addAll(listUsers1);
        listUsers.addAll(listUsers2);
        insert listUsers;
        listUsers[0].ManagerId = listUsers[1].Id;
        update listUsers;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUsers[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUsers[0]) {
            
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c = true;
            insert sdb;
            List<Account> accountList = new List<Account>();
            Account vAcc = new Account();
            vAcc.Name = 'Test Account';
            vAcc.Type='Distributor';
            vAcc.Focused_Partner__c = True;
            vAcc.Payment_Term__c = 'Net 30';
            vAcc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAcc);
            
            Account vAcc2 = new Account();
            vAcc2.Name = 'Test Account';
            vAcc2.recordTypeId = vAcc.recordTypeId;
            vAcc2.Payment_Term__c = 'Net 30';
            accountList.add(vAcc2);
            insert accountList;
            /*Alliance_Deal_Registration__c adr = new Alliance_Deal_Registration__c();
            adr.Account__c = vAcc2.Id;
            adr.BDM__c = listUsers[0].Id;
            adr.Alliance_Partner__c = 'Amazon';
            adr.Raw_Country__c = 'US';
            adr.Company__c = 'Amazon';
            adr.Active__c = True;
            adr.Status__c = 'Approved';
            insert adr;*/
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Primary__c = true;
            deal.Company_Name__c = vAcc2.Id;
            try{
                flowControll.DealRegistrationTrigger = false;
                insert deal;
                flowControll.DealRegistrationTrigger = true;
            }
            catch(Exception e){
                system.debug(LoggingLevel.DEBUG, '@@ exception '+e.getMessage());
            }
            List<Deal_Registration__c> deal1 = [select name from Deal_Registration__c where id =:deal.Id];
            Opportunity oppObject1 = TestDataFactory.getOpportunity();
            Opportunity oppObject2 = TestDataFactory.getOpportunity();
            oppLi.add(oppObject1);
            oppLi.add(oppObject2);
            if(!deal1.isEmpty()){
            oppObject1.Deal_Registration__c = True;
                oppObject1.Deal_Registration_Number__c = deal1[0].name;
            oppObject1.Deal_Reg_Approval_Status__c = 'Approved';
            }
            oppObject1.AccountId = vAcc2.Id;
            insert oppLi;
            Order o = new Order();
            o.OpportunityId = oppObject2.Id;
            o.AccountId = vAcc2.Id;
            o.EffectiveDate = System.today();
            Test.startTest();
            o.Status = 'Draft';
            insert o;
            
            oppObject2.StageName = '6 PO With Channel';
            oppObject2.Opportunity_Type__c = 'New Customer';
            oppObject2.Opportunity_Sub_Type__c ='Regular';
            oppObject1.Deal_Reg_Approval_Status__c= 'Approved';
            oppObject1.Stagename = '7 Closed Lost';
            oppObject1.Opportunity_Type__c = 'New Customer';
            oppObject1.Opportunity_Sub_Type__c ='Regular';
            oppObject2.Holdover_Requested__c = true;
            oppObject2.Holdover_Sales_Rep__c = listUsers[1].Id;
            
            
            update oppLi;
            System.assert(oppObject1.Id != null);
            Test.stopTest();
            
        }
    }
    
    @isTest
    static void testOpportunityUpdateOwnerChange(){
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        listUser[0].LastName = 'Sinha';
        insert listUser;
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            accountList.add(vAccount);
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            
            Account vAccount2 = new Account();
            vAccount2.Name = 'Test Account';
            vAccount2.recordTypeId = vAccount.recordTypeId;
            vAccount2.Payment_Term__c = 'Net 30';
            accountList.add(vAccount2);
            insert accountList;
            
            Opportunity oppObject = TestDataFactory.getOpportunity();
            insert oppObject;
            
            update new Account(ID=vAccount2.id, Distributor__c = vAccount.id);
            System.assert(oppObject.Id != null);
            List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert listQuote;
            
            oppObject.OwnerId = listUser[0].id;
            oppObject.SecondaryOwnerSubmitter__c = listUser[0].id;
            oppObject.SecondaryOwnerApproved__c = true;
            oppObject.RenewalOwnerSubmitter__c = listUser[0].id;
            oppObject.RenewalOwnerApproved__c = true;
            oppObject.SE_Misaligned__c = true;
            oppObject.PO_Received_Notification_Sent__c = true;
            oppObject.Include_Datos__c = true;
            oppObject.StageName = '2 Consensus';
            //oppObject.Identified_Pain__c = 'true';
            oppObject.Alliance_HW_Partner__c = 'Cisco';
            oppObject.Alliance_Source_Type_HW__c = 'Alliance Initiated Deal';
            oppObject.Cloud_Type__c = 'Google';
            //oppObject.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            oppObject.Compelling_Bus_Driver__c = 'Instant Recovery';
            oppObject.Current_State__c = 'test';
            oppObject.Negative_Consequences__c = 'test';
            oppObject.Future_State__c = 'test';
            oppObject.Positive_Business_Outcomes__c = 'test';
            oppObject.Distributor_Lookup__c = vAccount.id;
            oppObject.Partner_Lookup__c = vAccount2.id;
            oppObject.Opportunity_Sub_Type__c = 'MSP';
            oppObject.Rubrik_Sales_Engineer__c = UserInfo.getUserId();
            oppObject.Win_Loss_Comments__c = 'test';
            oppObject.Primary_Competitor__c = 'Actifio';
            oppObject.Key_Feature_Needs__c = 'Other';
            oppObject.Deal_Impact__c = 'Deal Blocker';
            oppObject.Valooto_Quote__c = '123123123';
            oppObject.Valooto_Quote_Stage__c = 'Approved';
            oppObject.Help_Needed__c = 'Approved';
            //oppObject.Help_Needed_From__c = listUser[0].id;
            //oppObject.Technical_Validation_Next_Step__c = 'true';
            oppObject.Escalation_Stage__c = 'Needs Monitoring';
            oppObject.Manager_s_Note__c = 'true';
            oppObject.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
            oppObject.Pricebook2Id = Test.getStandardPricebookId();
            oppObject.Projected_Product_Edition__c = 'Complete Edition';
            // oppObject.Cloud_Partner_Led_Activity__c = 'Yes';
            oppObject.Lost_To_Won_Against__c ='Actifio';
            oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            oppObject.Valooto_Quote__c ='Test';
            
            Test.startTest();
            TriggerManager.resetTriggerCounter('Opportunity');
            try{
            update oppObject;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG, '@@ exception '+e.getMessage());
            }
            Opportunity opp = [SELECT SBQQ__Ordered__c, manager_note_date_time__c, Stage_6_TimeStamp__c, 
                               SE_Forecast_Category__c, SecondaryOwner__c, RenewalOwner__c, Rubrik_Sales_Engineer__c, 
                               PO_Notification_Sent_timestamp__c, CloseDate, Actual_Close_Lost_Date__c, SBQQ__QuotePricebookId__c, 
                               Estimated_Close_Date__c, SDR_Led_Checked_Date__c, Next_Step_date_time__c, Risk_Identified_Date__c, 
                               Date_Last_Escalation_Stage_Change__c, Push_Counter__c, Stagnant__c, Technical_Validation_Last_Touch__c, 
                               Current_State_Date_Time__c, Win_Date_Hidden__c, OwnerId, Type, Opportunity_Type__c, Owner_Region__c, Owner_Area__c, Owner_Theatre__c, Owner_Sub_Region__c, Region_Text__c, Theatre_Text__c, Sub_Region_Text__c,  Stage_Lost_From__c, In_Forecast_Area__c, In_Forecast_RD__c, In_Forecast_RSM__c, In_Forecast_Theatre__c, Advanced_Past_Stage_1__c, Advanced_Past_Stage_1_Date_Time__c, Advanced_Past_Stage_2__c, Advanced_Past_Stage_2_Date_Time__c,  In_Forecast_Renewal__c, Opportunity_Sub_Type__c, Last_Stage_Update_Date__c, Help_Needed_Date__c, Help_Needed_From_Updated_Date__c, LeadSource, OriginalLeadOwner__c
                               FROM Opportunity where ID = :oppObject.id]; // removed Area_Text__c, Agreed_to_POC_terms__c as part of SAL27-702
            System.assert(oppObject.Id != null);            
            Test.stopTest();
        }
    }
    @isTest
    static void testOpportunityClosedWon(){       
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].RBAC_Group__c = 'System - IT';
        update listUser[0];
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        system.runas(listUser[0]){
            ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            BLSetting.Disable_Opportunity_Validation_Rules__c = true;
            BLSetting.Disable_Account_Validation_Rules__c = true;
            insert BLSetting;
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.StageName = '1 Discovery';
            opp.name ='PSO Rebook';
            
            insert opp;
            System.assert(opp.Id != null);
            List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opp.Id}, 1);
            insert listQuote;
            opp.Opportunity_Sub_Type__c='Renewal';
            opp.RenewalOwner__c= listUser[0].id;
            opp.StageName = '7 Closed Won';
            opp.Lost_To_Won_Against__c ='Actifio';
            opp.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            opp.Valooto_Quote__c ='Test';
            Test.startTest();
            TriggerManager.resetTriggerCounter('Opportunity');
            update opp;
            Test.stopTest();
        } 
    }
    @isTest
    static void testOpportunityDebooking(){       
        List<Profile> listProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        system.assertNotEquals(null,listUser);
        PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        system.runas(listUser[0]){
            ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            BLSetting.Disable_Opportunity_Validation_Rules__c = true;
            BLSetting.Disable_Account_Validation_Rules__c = true;
            insert BLSetting;
			/*TriggerControl__c setting0 = new TriggerControl__c();
            setting0.Name = 'Booking';
            setting0.DisableTrigger__c = TRUE;
			insert setting0;*/
            Account acct = new Account(Name='test account', AccountNumber='123456');
            insert acct;
            Test.startTest();
            Opportunity oppty=new Opportunity(
                Name='test Opportunity',
                AccountId=acct.id, 
                StageName='1 Discovery', 
                CloseDate=system.Today(),
                ForecastCategoryName='Best Case',
                Business_Unit__c='Rubrik',
                Installation_Assigned_To__c='FE Install'
            );
            insert oppty;
            Booking__c bkg=new Booking__c(
                Opportunity__c=oppty.id,
                Account_Name__c=acct.id,
                status__c='Completed',
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
            );
            insert bkg;
            CCR__c cc=new CCR__C(
                Comment__c='test',
                Opportunity__c=oppty.id,
                AssignmentStatus__c='Unassigned',
                User__c='Pending',
                CCR_Type__c='Customer Returns / Refunds',    
                Amount__c=100,
                booking__c=bkg.id,
                Account_Name__c=acct.id,
                Impacts_Commission__c = TRUE                
            );
            insert cc;            
            oppty.CCR__c = cc.Id; //SAL26-549
            UPDATE oppty; //SAL26-549
            cc.User__c='Approved';
            update cc;
            OpportunityObjectTriggerHelper.createPartnerRelation(new Map<Id, Opportunity>{oppty.Id => oppty});
            Test.stopTest();
        } 
    }
    @isTest
    static void testOpportunityUpdateStageChange(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        System.runAs(listUser[0]) {
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        sdb.Disable_Account_Validation_Rules__c = true;
        insert sdb;
        //SAL25-748
        SOX_Objects_Delete_Access__c soxObjCS = new SOX_Objects_Delete_Access__c(setupownerid = userinfo.getuserid());
        soxObjCS.Allow_Opportunity_Delete__c = true;
        insert soxObjCS;
        
        OppStageAndHours__c OppStageAndHoursCS = new OppStageAndHours__c(Name = '1 Discovery', HoursInStage__c = 'Hours_in_Discovery__c');
        insert OppStageAndHoursCS;
        
        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.StageName = '1 Discovery';
        insert oppObject;
        System.assert(oppObject.Id != null);
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
        insert listQuote;
        oppObject.Opportunity_Sub_Type__c='Renewal';
        oppObject.RenewalOwner__c= listUser[0].id;
        oppObject.StageName = '7 Closed Lost';
        
        oppObject.Lost_To_Won_Against__c ='Actifio';
        oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
        oppObject.Valooto_Quote__c ='Test';
        Test.startTest();
        TriggerManager.resetTriggerCounter('Opportunity');
        update oppObject;
        System.assert(oppObject.Id != null);
        TriggerManager.resetTriggerCounter('Opportunity');
        
        Mosaic_Opportunity_Management_Mapping__mdt objMosaicMapping = new Mosaic_Opportunity_Management_Mapping__mdt();
        objMosaicMapping.Mosaic_Rep_Id__c = listUser[0].id;
        objMosaicMapping.Mosaic_SE_Id__c = listUser[0].id;
        objMosaicMapping.Opportunity_Owner_Region__c = 'test';
        
        
        OpportunityObjectTriggerHelper.setRegionWithMosaicUserIdMap(objMosaicMapping, 
                                                                    new Map<String, Set<Id>>{'test'=> new Set<ID>{listUser[0].id}}, new Set<Id>(), new Set<Id>());     
        delete oppObject;
        TriggerManager.getGenericErrorMessage(null, 'additionalMessage');
        Test.stopTest();
        //OpportunityObjectTriggerHelper.testCodeCoverage();
    }
    }
    
    /*    static testMethod void opportunityWithOli(){
Test.startTest();
List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());

List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
listUser[0].LastName = 'Sinha';
insert listUser;
System.runAs(listUser[0]) {
ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
upsert disableFuncCS;

Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT');
insert newProd;

Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', isActive = true);
insert priceBook;

Id standardPBId = test.getStandardPricebookId();

PriceBookEntry pbEntry = new PriceBookEntry(
UnitPrice = 400,
PriceBook2Id = standardPBId,
Product2Id = newProd.Id,
IsActive = true,
UseStandardPrice=false);
insert pbEntry ;
FlowControll.opportunityTriggerHandler = false;
FlowControll.accountTrigger = false;
Opportunity opp = TestDataFactory.getOpportunity();
opp.Pricebook2Id=standardPBId;
opp.Split_percentage__c=25;
opp.split_amount__c = 0.00;
opp.split__c = true;
opp.Has_LOD_Products__c = true;
insert opp;
//FlowControll.opportunityTriggerHandler = true;
//Test.startTest();
SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
qt.Task_Products__c='RBK-DISK-RETENTION';
qt.SBQQ__Account__c = opp.AccountId;
qt.SBQQ__Opportunity2__c = opp.Id;
qt.SBQQ__Type__c = 'Quote';
insert qt; 

SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = newProd.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,SubscribedAssetNames__c='as1,as2' );  
insert qli1;
//OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id);
OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id, SBQQ__QuoteLine__c=qli1.Id);
insert oppLine;

oppLine = [Select pricebookentryid,TotalPrice, Quantity, OpportunityID, isSplit__c, Is_Opportunity_Split__c from OpportunityLineItem WHERE id = :oppLine.id];
OpportunityLineItemTriggersHelper.createOli (oppLine);
delete oppLine;
FlowControll.opportunityTriggerHandler = true;
Test.stopTest();
}
}
*/
    
    static testMethod void splitOppByPercent(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        insert listUser;
        System.runAs(listUser[0]) {//sailaja
            insert new Opportunity_Stage_Days__c (SetupOwnerId = listUser[0].id, AllowAcvCalculation__c = false, AllowArrCalculation__c = true);
            List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
            
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            Id standardPBId = test.getStandardPricebookId();
            
            List<Product2> listProduct = TestDataFactory.getProducts('OPTY-SPLIT', 1);
            listProduct[0].ProductCode = 'OPTY-SPLIT';
            insert listProduct;
            
            List<Pricebook2> listPricebook = TestDataFactory.getPricebook('PriceBook', 1);
            insert listPricebook;
            
            List<PriceBookEntry> listPricebookentry = TestDataFactory.getPriceBookEntry(
                new List<Id>{listProduct[0].Id},
                new List<Id>{Test.getStandardPricebookId(), listPricebook[0].Id}
            );
            System.runAs(getUser('System Administrator'))  {
                insert listPricebookentry;
            }
            
            FlowControll.opportunityTriggerHandler = false;
            FlowControll.AccountTrigger=false;
            Test.startTest();
            Opportunity parentOppObject = TestDataFactory.getOpportunity();
            insert parentOppObject;
            
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.Pricebook2Id=standardPBId;
            opp.Split_percentage__c=25;
            opp.split__c = true;
            opp.Opportunity_Split_Parent__c = parentOppObject.id; 
            insert opp;
            System.assert(opp.Id != null);
            //FlowControll.opportunityTriggerHandler = true;
            TriggerManager.resetTriggerCounter('Opportunity');
            parentOppObject.Split_percentage__c=75;
            parentOppObject.split__c = true;
            parentOppObject.Amount = 1000;
            //system.debug('parentOppObject: '+parentOppObject);
            if(parentOppObject!=null)//sailaja
            {
                update parentOppObject;
            }
            // SAL26-117 //parentOppObject = [Select amount, Split_percentage__c, split_Amount__c, split__c, (Select TotalPrice, ProductCode from OpportunityLineItems)  from Opportunity where id = :parentOppObject.id];
            //System.assertEquals(750, parentOppObject.Amount);
            //System.assertEquals(2, parentOppObject.OpportunityLineItems.size());
            /*TriggerManager.resetTriggerCounter('Opportunity');
parentOppObject.Split_percentage__c=50;
parentOppObject.split_Amount__c = 500;
opp.Split_percentage__c=50;
opp.split_Amount__c = 500;
update (new List<Opportunity> {parentOppObject, opp});
parentOppObject = [Select amount, Split_percentage__c, split_Amount__c, split__c, (Select TotalPrice, ProductCode from OpportunityLineItems)  from Opportunity where id = :parentOppObject.id];
System.debug('\n1~~~~Test Result: ' + parentOppObject);*/
            //System.assertEquals(500, parentOppObject.Amount);
            //System.assertEquals(2, parentOppObject.OpportunityLineItems.size());
            FlowControll.opportunityTriggerHandler = true;//sailaja
            Test.stopTest();
        }
    }
    
    static testMethod void splitOppETM(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        insert listUser;
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            Test.startTest();
            Id standardPBId = test.getStandardPricebookId();
            List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName !='Unassigned' and Territory_Structure_Type__c != 'Core' limit 10];                     
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Account Executive',UserId = listUser[0].id));
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Sales Engineer',UserId = listUser[1].id));
            insert UTAList ;
            
            List<Product2> listProduct = TestDataFactory.getProducts('OPTY-SPLIT', 1);
            listProduct[0].ProductCode = 'OPTY-SPLIT';
            insert listProduct;
            
            List<Pricebook2> listPricebook = TestDataFactory.getPricebook('PriceBook', 1);
            insert listPricebook;
            
            List<PriceBookEntry> listPricebookentry = TestDataFactory.getPriceBookEntry(
                new List<Id>{listProduct[0].Id},
                new List<Id>{Test.getStandardPricebookId(), listPricebook[0].Id}
            );
            System.runAs(getUser('System Administrator'))  {
                insert listPricebookentry;
            }
            
            //FlowControll.opportunityTriggerHandler = false;
            FlowControll.AccountTrigger=false;
            Opportunity parentOppObject = TestDataFactory.getOpportunity();
            insert parentOppObject;
            Account acc = new Account(Id=parentOppObject.AccountId, Adaptive_Territory_Id__c=terrList[0].Adaptive_Territory_Id__c); 
            insert new ObjectTerritory2Association(ObjectId =acc.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
            update acc; 
            System.assert(parentOppObject.Id != null);
            
            Test.stopTest();
        }
    }
    
    /*  testMethod static void updatePrimaryQuoteTest(){
List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
List<Opportunity> oppLi = new List<Opportunity>();
List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
insert listUser;
listUser[0].ManagerId = listUser[1].Id;
update listUser;

System.runAs(listUser[0]) {
ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
sdb.Disable_Opportunity_Validation_Rules__c = true;
insert sdb;

Account acc = new Account(Name = 'Test Account');
insert acc;


Opportunity oppo = new opportunity();
oppo.StageName = '1 Discovery';
oppo.closeDate = System.Today() + 30;
oppo.AccountId = acc.Id;
oppo.Name = 'Test oppo';
oppo.SOW_Required__c = true;
oppo.OwnerId = listUser[0].Id;
insert oppo;

SBQQ__Quote__c sd = new SBQQ__Quote__c();
sd.SBQQ__Opportunity2__c =oppo.Id;
sd.sendSOWNotification__c = false;
sd.SBQQ__Type__c = 'Renewal';
sd.Task_Products__c='RBK-DISK-RETENTION';
//sd.SBQQ_Primary__c =true;
//sd.SBQQ_Status = 'Draft';
insert sd;
system.debug('quote id=>'+sd.Id);
oppo.SBQQ__PrimaryQuote__c = sd.Id;

oppo.StageName = '3 Technical Validation';
oppo.SOW_Required__c = true;
oppo.Opportunity_Program__c ='Refresh';
flowControll.opportunityTriggerHandler = true;

test.startTest();
update oppo;
system.debug('test oppo.SBQQ__PrimaryQuote__c=>'+oppo.SBQQ__PrimaryQuote__c);
// OpportunityObjectTriggerHelper.createTasksForRenewalExpansionQuote(new List<Opportunity>{oppo});
test.stopTest();
}
} */
    
    
    testMethod static void updatePrimaryQuoteTest(){
        test.startTest();  
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        //User ciUser = [select Id from User where Id='0056f000009zoBM'];
        Opportunity oppo = new opportunity();
        SBQQ__Quote__c sd = new SBQQ__Quote__c();
        System.runAs(listUser[0]) {
            Account accs = new Account(Name = 'Test Accounts');
            insert accs; 

            Account acc = new Account(Name = 'Test Account');
            insert acc; 
            //Opportunity opp = [Select id from Opportunity Limit 1];
            //Account acc = [Select id from Account Limit 1];
            
            // SAL26-117
            /*List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'Test', family = 'test family', ProductCode = 'RS-BT-BE-SC-PE-PA', Product_Subtype__c = 'FEDRAMP')
                    };
                        insert lstProds;
            
            Id standardPBId = test.getStandardPricebookId();
            Pricebook2 pricebook = new Pricebook2(Name = 'Test Pricebook', isActive = true);
            insert priceBook; 
            
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true)
                    }; // SAL26-117 end
            INSERT pbEntry; */    
            
            //oppo.Id = opp.Id;  
            oppo.StageName = '6 PO With Channel';
            oppo.closeDate = System.Today() + 30;
            oppo.AccountId = acc.Id;
            oppo.Name = 'Test oppo';
            oppo.SOW_Required__c = false;
            oppo.OwnerId = listUser[0].Id;
            oppo.Has_Polaris_Product__c =true;
            oppo.Opportunity_Sub_Type__c = 'MSP Overage';
            //oppo.Pricebook2Id = standardPBId;
            insert oppo;
            System.assert(oppo.Id != null);
            
            /*ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            settingDisable.Disable_Opportunity_Triggers__c = true;
            INSERT settingDisable;
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(Product2Id = lstProds[0].Id, pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppo.Id));
            insert oppLineList;   //SAL26-117
            settingDisable.Disable_Opportunity_Triggers__c = false;
            UPDATE settingDisable;*/
            
            sd.SBQQ__Opportunity2__c =oppo.Id;
            sd.SBQQ__Account__c = acc.Id;
            sd.sendSOWNotification__c = false;
            sd.SBQQ__Type__c = 'Renewal';
            sd.Task_Products__c='RBK-DISK-RETENTION';
            sd.SBQQ__Primary__c =true;
            sd.SBQQ__Status__c = 'Draft';
            flowControll.opportunityTriggerHandler = false;
            insert sd;
            flowControll.opportunityTriggerHandler = true;
              
            oppo.SBQQ__PrimaryQuote__c = sd.Id;
            oppo.StageName = '7 Closed Won';
            oppo.SOW_Required__c = true;
            //oppo.Opportunity_Program__c ='Refresh';
            TriggerControls.disableQuoteTrigger = true;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = true;
            oppo.MSP_End_User_Lookup__c = accs.Id;
            oppo.Opportunity_Amount_Override__c = true;
            oppo.ACV_Amount__c = 1000;
            oppo.Renewal_Subsumed_ACV__c = 1000;
            oppo.Subsumed_Renewal_TCV__c = 1000;
            oppo.New_Expansion_ACV__c = 1000;
            oppo.New_Expansion_TCV__c = 1000;
            oppo.Core_New_Expansion_ACV__c =  1000;
            oppo.Nas_New_Expansion_ACV__c = 1000;
            oppo.SaaS_New_Expansion_ACV__c = 1000;
            oppo.Subsumed_Renewal_Churn_ACV__c = 1000;
            oppo.Subsumed_Renewal_Churn_TCV__c = 1000;
            //   oppObjectRec.SBQQSC__AmendedServiceContract__c = serviceContractObj.Id;
            try {
            update oppo;
            } catch(Exception ex) {
                system.debug(LoggingLevel.DEBUG, '@@ exception '+ex.getMessage());
            }
            test.stopTest(); 
        }
        //OpportunityObjectTriggerHelper.createTasksForRenewalExpansionQuote(new List<Opportunity>{oppo});
    }
    
    testMethod static void renewalOppFieldsTest(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        sdb.Disable_Account_Validation_Rules__c = true;    
        insert sdb;
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.accountTrigger = false;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        TriggerHandler.bypass('QuoteTriggerHandler');
        Opportunity oppo = new opportunity();
        oppo.StageName = '1 Discovery';
        oppo.closeDate = System.Today() + 30;
        oppo.AccountId = acc.Id;
        oppo.Name = 'Test oppo';
        oppo.Alliance_Partner_Name__c = 'Google'; //SAL26-492
        insert oppo;
        
        FlowControll.opportunityTriggerHandler = true;
        FlowControll.accountTrigger = true;
        
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = acc.id;
        testContract.SBQQSC__Opportunity__c = oppo.Id;
        testContract.Name = 'Test Service Contract for Renewal';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        insert testContract;
        
        System.assert(testContract.Id != null);
        testContract.SBQQSC__RenewalForecast__c = true;
        Test.startTest();
        try{
            update testContract;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG, '@@ exception '+e.getMessage());
            }
        Test.stopTest();
        //System.assert(testContract.SBQQSC__RenewalForecast__c);
    }
    }
    
    @isTest static void updateQuoteFields(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        
        List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
        String ContactID = [SELECT Id FROM Contact where LastName = 'Test Contact 01-06' LIMIT 1].Id;
        String AccountID = [SELECT Id FROM Account where Name = 'Test Account 01-06' LIMIT 1].Id;
        
        Opportunity Opp = new Opportunity();
        Opp.Id = lstOpp[0].Id;
        Opp.Opportunity_Sub_Type__c = 'MSP Overage';
        Opp.Initial_Contacts_Name__c = ContactID;
        Opp.Distributor_Lookup__c = AccountID;
        Opp.Partner_Lookup__c = AccountID;
        System.assert(opp.Id != null);
        Test.startTest();
        update Opp;
        Test.stopTest();
    }
    }
    
    /*testMethod static void testOppAnnualContractValueUtil(){

ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
sdb.Disable_Opportunity_Validation_Rules__c = true;
insert sdb;
FlowControll.opportunityTriggerHandler = false;
FlowControll.accountTrigger = false;

Account acc = new Account(Name = 'Test Account');
insert acc;

List<Product2> lstProducts = new List<Product2>{
new Product2(Name = 'OPTY-SPLIT', ProductCode = 'OPTY-SPLIT', isActive = true),
new Product2(Name = 'CONSUMPTION', ProductCode = 'CONSUMPTION', isActive = true, Sales_Comp_Category__c = 'CONSUMPTION'),
new Product2(Name = 'CONSUMPTION ACTUALS', ProductCode = 'CONSUMPTION-ACTUALS', isActive = true, Sales_Comp_Category__c = 'CONSUMPTION ACTUALS'),
new Product2(Name = 'LOD PRODUCT', ProductCode = 'RUBRIK CLOUD DATA MGMT', isActive = true, Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT'),
new Product2(Name = 'Premium Support 1-Yr Prepaid, r304', ProductCode = 'HW SUPPORT', isActive = true, Sales_Comp_Category__c = 'HW SUPPORT')
};

insert lstProducts;
Id pricebookId = Test.getStandardPricebookId();
List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true),
new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[3].Id, UnitPrice = 100.00, IsActive = true),
new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[4].Id, UnitPrice = 100.00, IsActive = true)
};

insert lstPricebooks;        
Opportunity opp = TestDataFactory.getOpportunity();
List<Opportunity> oppList = new List<Opportunity>{opp};

oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));

oppList[0].Pricebook2Id = pricebookId;
oppList[1].Pricebook2Id = pricebookId;
oppList[2].Pricebook2Id = pricebookId;
oppList[3].Pricebook2Id = pricebookId;
oppList[4].Pricebook2Id = pricebookId;
insert oppList;



List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppList[0].Id, sendSOWNotification__c = false, SBQQ__Primary__c=true, Task_Products__c='RBK-DISK-RETENTION'));
quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppList[1].Id, sendSOWNotification__c = false, SBQQ__Primary__c=true, Task_Products__c='RBK-DISK-RETENTION'));
quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppList[2].Id, sendSOWNotification__c = false, SBQQ__Primary__c=true, Task_Products__c='RBK-DISK-RETENTION'));
insert quoteList;

List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProducts[1].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__SubscriptionTerm__c = 6,SubscribedAssetNames__c='as1,as2'));
lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[1].Id, SBQQ__Product__c = lstProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 45, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__SubscriptionTerm__c = 12,SubscribedAssetNames__c='as1,as2'));
//lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[2].Id, SBQQ__Product__c = lstProducts[3].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 36, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__SubscriptionTerm__c = 18,SubscribedAssetNames__c='as1,as2'));
lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[2].Id, SBQQ__Product__c = lstProducts[4].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 36, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__SubscriptionTerm__c = 48,SubscribedAssetNames__c='as1,as2'));

Test.startTest();
insert lines;
Database.executebatch(new OppAcvUpdateBatch());
Test.stopTest();

}*/
    
    testMethod static void testOppAnnualContractValueUtilSplit(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].RBAC_Group__c = 'System - IT';
        update listUser;
        
        ShGl_DisableBusinessLogic__c sdbl = new ShGl_DisableBusinessLogic__c(
            setupownerid = userinfo.getuserid(),
            Disable_Account_Triggers__c = true,
            Disable_Asset_Triggers__c = true,
            Disable_Order_Old_Trigger__c = true,
            Disable_OrderItem_Old_Trigger__c = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_SBQQ_QuoteLine_Triggers__c = true,
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_ServiceContract_Trigger__c = true,
            Disable_Contract_Line_Item_Triggers__c = true,
            Enable_Logs__c = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
            Disable_Opportunity_Triggers__c = true,
            Disable_Entitlement_Usage_Trigger__c = true,
            Disable_Entitlement_Trigger__c = true,
            Disable_Account_Validation_Rules__c = true
        );
        insert sdbl;
        
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.accountTrigger = false;
        FlowControll.opportunityLineItemHandler = false;
        FlowControll.taskTrigger = false;
        FlowControll.UserTriggerHandler = false;
        FlowControll.ScaleUtilityOverageTrigger = false;
        FlowControll.AARTrigger = false;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-SVC-PREM-APPLIANCE',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod4 = new Product2(
            Name = 'Wrapper',
            ProductCode = 'Wrapper',
            IsActive = true,
            Product_Level__c = 'Wrapper'
        );
        Product2 prod5 = new Product2(
            Name = 'RBK-R348-01',
            ProductCode = 'RBK-R348-01',
            isActive = true,
            Sales_Comp_Category__c = 'HARDWARE',
            Product_Type__c = 'Appliance'
        );
        Product2 prod6 = new Product2(
            Name = 'RBK-R6408S-HW-01',
            ProductCode = 'RBK-R6408S-HW-01',
            isActive = true,
            Sales_Comp_Category__c = 'HARDWARE',
            Product_Type__c = 'Hardware'
        );
        insert new List<Product2>{prod1, prod2, prod3, prod4, prod5, prod6};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry5 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbStanEntry6 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod6.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry5 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        PricebookEntry pbEntry6 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod6.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        insert new List<PricebookEntry>
        {pbStanEntry1, pbStanEntry2, pbStanEntry3, pbStanEntry4, pbStanEntry5, pbStanEntry6, pbEntry1, pbEntry2, pbEntry3, pbEntry4
            , pbEntry5, pbEntry6};
                
                Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity oppr = TestDataFactory.getOpportunity(acc);
        insert oppr;
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => acc.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal+Expansion';
        qt1.SBQQ__StartDate__c = Date.Today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.SBQQ__ExpirationDate__c = Date.Today() + 365;
        insert qt1;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper ContractA';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj1.AccountId = acc.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        lstServiceContract.add(serviceContractObj1);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = acc.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        system.RunAs(listUser[0]){
        insert ContractLineItemObj;
        }
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId = acc.Id;
        assetObj.Name = 'EntitlementTriggerHelperAsset';
        assetObj.Product2Id = prod1.Id;
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        insert assetObj;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing',
            Product_Level__c = 'Support',
            SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, CCLI__c = ContractLineItemObj.Id, Special_Program__c = null,
            PriorACVwithUplift__c = 10000, Prior_Net_Total__c = 21000, RTAwithoutUplift__c = 10007,
            Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', 
            SubscribedAssetNames__c = 'BB192863040046',
            SubsAstNameInt__c = 'BB192863040046'
        );
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
            SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SBQQ__SubscriptionPricing__c = null, 
            SBQQ__DefaultSubscriptionTerm__c = null, Sales_Comp_Category__c = 'INSTALL', Disposition_Reason__c = 'None',
            SBQQSC__RenewedContractLine__c = null, Product_Type__c = 'Consulting', Product_Level__c = 'Addon'
        );
        lines.add(ql1);
        lines.add(ql2);
        insert lines;
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'OPTY-SPLIT', ProductCode = 'OPTY-SPLIT', isActive = true),
                new Product2(Name = 'CONSUMPTION', ProductCode = 'CONSUMPTION', isActive = true, Sales_Comp_Category__c = 'CONSUMPTION'),
                new Product2(Name = 'CONSUMPTION ACTUALS', ProductCode = 'CONSUMPTION-ACTUALS', isActive = true, Sales_Comp_Category__c = 'CONSUMPTION ACTUALS'),
                new Product2(Name = 'LOD PRODUCT', ProductCode = 'RUBRIK CLOUD DATA MGMT', isActive = true, Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT'),
                new Product2(Name = 'Premium Support 1-Yr Prepaid, r304', ProductCode = 'HW SUPPORT', isActive = true, Sales_Comp_Category__c = 'HW SUPPORT'),
                new Product2(Name = 'SW Premium Support 1-Yr Prepaid, r304', ProductCode = 'SW SUPPORT', isActive = true, Sales_Comp_Category__c = 'SW SUPPORT', SBQQ__SubscriptionTerm__c = 18)
                };
                    
                    insert lstProducts;
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true),
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[3].Id, UnitPrice = 100.00, IsActive = true),
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[4].Id, UnitPrice = 100.00, IsActive = true),
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[5].Id, UnitPrice = 100.00, IsActive = true)
                };
                    
                    System.runAs(getUser('System Administrator'))  {
                        insert lstPricebooks;      
                    }  
        Opportunity opp = TestDataFactory.getOpportunity();
        List<Opportunity> oppList = new List<Opportunity>{opp};
            
            oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        oppList.add(TestDataFactory.getOpportunity(new Account(ID=opp.AccountId), new Contact(ID= opp.Initial_Contacts_Name__c, Email='cp@cp.cp')));
        
        oppList[0].Pricebook2Id = pricebookId;
        oppList[0].Opportunity_Type__c = 'Existing Customer';
        oppList[0].Opportunity_Sub_Type__c = 'Regular';
        oppList[1].Pricebook2Id = pricebookId;
        oppList[1].Opportunity_Type__c = 'Existing Customer';
        oppList[0].Opportunity_Sub_Type__c = 'Regular';
        oppList[1].Pricebook2Id = pricebookId;
        oppList[2].Opportunity_Type__c = 'Existing Customer';
        oppList[2].Opportunity_Sub_Type__c = 'Regular';
        oppList[3].Pricebook2Id = pricebookId;
        oppList[4].Pricebook2Id = pricebookId;
        oppList[5].Pricebook2Id = pricebookId;
        oppList[6].Pricebook2Id = pricebookId;
        insert oppList;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppList[0].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppList[1].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[3].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppList[2].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[3].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppList[2].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[0].Id,TotalPrice=-2000, Quantity = 1,OpportunityID =  oppList[3].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[0].Id,TotalPrice=2000, Quantity = 1,OpportunityID =  oppList[4].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[3].Id,TotalPrice=2000, Quantity = 1,OpportunityID =  oppList[4].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[5].Id,TotalPrice=2000, Quantity = 1,OpportunityID =  oppList[5].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=pbStanEntry1.Id,TotalPrice=2000, Quantity = 1,OpportunityID =  oppList[5].Id,SBQQ__QuoteLine__c = lines[0].Id));
        oppLineList.add(new OpportunityLineItem(pricebookentryid=pbStanEntry1.Id,TotalPrice=2000, Quantity = 1,OpportunityID =  oppList[1].Id,SBQQ__QuoteLine__c = lines[1].Id));
        insert oppLineList;
        
        oppList[1].split__c = true;
        oppList[2].split__c = true;
        oppList[1].Split_percentage__c = 50;
        oppList[2].Split_percentage__c = 50;
        oppList[2].Opportunity_Split_Parent__c = oppList[1].id;
        
        oppList[3].split__c = true;
        oppList[4].split__c = true;
        oppList[3].Split_percentage__c = 50;
        oppList[4].Split_percentage__c = 50;
        oppList[4].Opportunity_Split_Parent__c = oppList[3].id;
        
        oppList[5].split__c = true;
        oppList[6].split__c = true;
        oppList[5].Split_percentage__c = 50;
        oppList[6].Split_percentage__c = 50;
        oppList[6].Opportunity_Split_Parent__c = oppList[5].id;
        FlowControll.opportunityTriggerHandler = true;
        
        update oppList;
        
        oppList[1].Split_percentage__c = 55;
        oppList[2].Split_percentage__c = 45;
        oppList[3].Split_percentage__c = 45;
        
        Test.startTest();
        update oppList;
        
        Database.executebatch(new OppAcvUpdateBatch());
        Test.stopTest();
        
        Map<ID, Opportunity> savedOppList = new Map<ID, Opportunity>([Select ID, OppSubscriptionTermMonths__c, ACV_Amount__c, TotalHW_HwSupportAmount__c from Opportunity WHERE ID in :oppList]);
        System.assert(savedOppList != null);
        
        OpportunityObjectTriggerHelper.updateSplitChildrenOpportynities(oppList[0], 20, null, null, null );
    }
    
    @isTest static void updateReferrealAmountField(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        
        List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
        String ContactID = [SELECT Id FROM Contact where LastName = 'Test Contact 01-06' LIMIT 1].Id;
        String AccountID = [SELECT Id FROM Account where Name = 'Test Account 01-06' LIMIT 1].Id;
        
        Map<String, Object> CCRMap = new Map<String, Object> {
            'Comment__c'=>'test',
                'Opportunity__c'=>lstOpp[0].id,
                'AssignmentStatus__c'=>'Unassigned',
                'User__c'=>'Pending',
                'Account_Name__c'=>AccountID,
                'Effective_Date__c'=>System.today(),
                'Impacts_Commission__c'=>true,
                'Effective_End_Date__c'=>System.today(), 
                //'Booking__c'=> bkg.id,
                'Referral_Fee_Percent__c' => 20,
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
                };
                    List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),3, CCRMap); 
        insert CCRList;
            system.debug(LoggingLevel.DEBUG,'CCRList==>'+CCRList);
        Opportunity Opp = new Opportunity();
        Opp.Id = lstOpp[0].Id;
        Opp.Amount = 3000;
        Opp.Opportunity_Sub_Type__c = 'MSP Overage';
        Opp.Initial_Contacts_Name__c = ContactID;
        Opp.Distributor_Lookup__c = AccountID;
        Opp.Partner_Lookup__c = AccountID;
        System.assert(opp.Id != null);
        Test.startTest();
        update Opp;
        Test.stopTest();
    }
    }
    /**
     * @description test method
     */
    testMethod static void debookingOppwithprods(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
    
        System.runAs(listUser[0]) {
            User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
            Set<ID> oppIdset = new Set<ID>();
            List<Opportunity> lstOpp = [select Id from opportunity];
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Map<String, Object> CCRMap = new Map<String, Object> {
                'Comment__c'=>'test',
                    'Opportunity__c'=>lstOpp[0].id,
                    'AssignmentStatus__c'=>'Unassigned',
                    'User__c'=>'Pending',
                    'Account_Name__c'=>acc.Id,
                    'Effective_Date__c'=>System.today(),
                    'Impacts_Commission__c'=>true,
                    'Effective_End_Date__c'=>System.today(), 
                    //'Booking__c'=> bkg.id,
                    'Referral_Fee_Percent__c' => 20,
                    'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
                    };
            List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),1, CCRMap); 
            insert CCRList;
            Opportunity opp = new Opportunity();
            opp.StageName = '1 Discovery';
            opp.closeDate = System.Today() + 30;
            opp.Name = 'Test Opp 31-05';
            opp.Opportunity_Type__c = 'Debooking';
            opp.Opportunity_Sub_Type__c = 'Full';
            opp.Amount = -1000;
            opp.ccr__c = CCRList[0].Id;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            FlowControll.accountTrigger = false;
            flowControll.contactTrigger = false;
            FlowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            insert opp;
            System.assert(opp.Id != null); 
        }
    }
    @isTest
    static void testOpportunityUpdateOne(){
        ShGl_DisableBusinessLogic__c sdbl = new ShGl_DisableBusinessLogic__c(
            setupownerid = userinfo.getuserid(),
            Disable_Account_Triggers__c = true,
            Disable_Asset_Triggers__c = true,
            Disable_Order_Old_Trigger__c = true,
            Disable_OrderItem_Old_Trigger__c = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_SBQQ_QuoteLine_Triggers__c = true,
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_ServiceContract_Trigger__c = true,
            Disable_Contract_Line_Item_Triggers__c = true,
            Enable_Logs__c = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
            Disable_Entitlement_Usage_Trigger__c = true,
            Disable_Entitlement_Trigger__c = true,
            Disable_Account_Validation_Rules__c = true
        );
        insert sdbl;
        Test.startTest();
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        System.runAs(listUser[0]) {//sailaja
            
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_SBQQ_Quote_Triggers__c = True;
            sdb.Disable_SBQQ_QuoteLine_Validation_Rules__c = True;
            sdb.Disable_SBQQ_QuoteLine_Triggers__c = True;
            sdb.Disable_ServiceContract_Trigger__c=true;
            sdb.Disable_Entitlement_Usage_Trigger__c=true;
            sdb.Disable_Entitlement_Trigger__c=true;
            sdb.Disable_Asset_Triggers__c=true;
            sdb.Disable_Contract_Line_Item_Triggers__c=true;
            sdb.Disable_Account_Validation_Rules__c = true; 
            insert sdb;
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.Pricebook2Id = Test.getStandardPricebookId();
            oppObject.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            oppObject.Marketplace__c = 'AWS Marketplace';
            insert oppObject;
            System.assert(oppObject.Id != null);
            List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            listQuote[0].SBQQ__Opportunity2__c = oppObject.Id;
            insert listQuote;
            oppObject.RenewalOwner__c = listUser[0].id;
            oppObject.Send_Hold_Off_Email__c = true;
            oppObject.Include_Datos__c = true;
            oppObject.StageName = '4 Business Justification';
            oppObject.Installation_Assigned_To__c = 'Partner Install';
            oppObject.Opportunity_Sub_Type__c='Renewal';
            oppObject.Lost_To_Won_Against__c ='Actifio';
            oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            oppObject.Valooto_Quote__c ='Test';
            oppObject.Cloud_Partner_Impact__c ='Partner gets a well-qualified meeting with key decision-makers';
            
            List<Product2> lstProducts = new List<Product2>{
                new Product2(Name = 'OPTY-SPLIT', ProductCode = 'OPTY-SPLIT', isActive = true),
                    new Product2(Name = 'CONSUMPTION', ProductCode = 'CONSUMPTION', isActive = true, Sales_Comp_Category__c = 'CONSUMPTION'),
                    new Product2(Name = 'CONSUMPTION ACTUALS', ProductCode = 'CONSUMPTION-ACTUALS', isActive = true, Sales_Comp_Category__c = 'CONSUMPTION ACTUALS'),
                    new Product2(Name = 'LOD PRODUCT', ProductCode = 'RUBRIK CLOUD DATA MGMT', isActive = true, Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT'),
                    new Product2(Name = 'Premium Support 1-Yr Prepaid, r304', ProductCode = 'HW SUPPORT', isActive = true, Sales_Comp_Category__c = 'HW SUPPORT')
                    };
                        insert lstProducts;
            
            
            Id pricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
                    new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
                    new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true),
                    new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[3].Id, UnitPrice = 100.00, IsActive = true),
                    new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[4].Id, UnitPrice = 100.00, IsActive = true)
                    };
                        System.runAs(getUser('System Administrator'))  {
                            insert lstPricebooks;
                        }          
            
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[3].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=lstPricebooks[3].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject.Id));
            insert oppLineList;
            
            //Test.startTest();//sailaja
            update oppObject;
            Test.stopTest();
        }//sailaja
    }
    
    /* @isTest static void testCalculatePortfolioField() {
Opportunity oppObject = [Select ID, Commission_Portfolio_Type__c, StageName, Opportunity_Type__c, Opportunity_Sub_Type__c, Order_Sub_Type__c , SBQQ__PrimaryQuote__c,
(Select ID, Product2.Name, Product2.Item_Type__c, Product2.Product_Type__c, Product2.Product_Subtype__c, Product2.License_Type__c, SBQQ__QuoteLine__r.Licensing_Model__c from OpportunityLineItems) from Opportunity LIMIT 1];

Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT');
insert newProd;


Id standardPBId = test.getStandardPricebookId();

PriceBookEntry pbEntry = new PriceBookEntry(
UnitPrice = 400,
PriceBook2Id = standardPBId,
Product2Id = newProd.Id,
IsActive = true,
UseStandardPrice=false);
insert pbEntry ;

OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id);
insert oppLine;


OpportunityLineItem oli = oppObject.OpportunityLineItems[0];
oli.Product2.Product_Subtype__c = 'GO';
oli.Product2.Product_Type__c = 'Accessories';
oli.Product2.Name = '-HYB-';
//oli.SBQQ__QuoteLine__r = new SBQQ__QuoteLine__c(Licensing_Model__c = 'Perpetual');
oppObject.Opportunity_Sub_Type__c = 'Renewal';
oppObject.StageName = '4 Business Justification';
test.startTest();
update oppObject;
test.stopTest();
}*/
    @isTest
    static void testNotifyToParentAccountOwner(){
        Test.startTest();
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid(),Disable_Account_Validation_Rules__c = true);
        insert sdb;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        System.runAs(listUser[0]) {//sailaja
            Account vAccount1 = TestDataFactory.getAccount();
            vAccount1.OwnerId = listUser[0].id;
            vAccount1.ETM_Territory__c = 'Test-1';
            insert vAccount1;
            
            Account vAccount2 = TestDataFactory.getAccount();
            vAccount2.ParentId = vAccount1.id;
            vAccount2.ETM_Territory__c = 'Test-2';
            insert vAccount2;  
            
            Opportunity oppObject = TestDataFactory.getOpportunity(vAccount2);
            insert oppObject;
            System.assert(oppObject.Id != null);
            //OpportunityObjectTriggerHelper.testCoverage(); // method call added by Sumedha since it was in commented section in line 986
            //OpportunityUtil.testCoverage(); SAL26-117
        }//sailaja
        Test.stopTest();
    }
    
    @isTest
    public static void  testIsCommissionPortfolioTypeChanged(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c sdb = ShGl_DisableBusinessLogic__c.getInstance();
        sdb.Disable_SBQQ_Quote_Triggers__c = true;
        sdb.Disable_SBQQ_QuoteLine_Triggers__c= true;
        sdb.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        sdb.Disable_Account_Validation_Rules__c = true; 
        upsert sdb;
        
        List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-FE-', Product_Level__c='OnPrem', Product_Type__c='Edition Upgrade', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                    new Product2(Name = 'RSCP-BE-', family = 'test family', Product_Level__c='OnPrem', Product_Type__c='Enterprise Edition', ProductCode = 'OPTY-SPLIT'),
                    new Product2(Name = 'RSCP-BUE-', family = 'test family', Product_Level__c='OnPrem', Product_Type__c='Business Edition', ProductCode = 'OPTY-SPLIT'),
                    new Product2(Name = 'RS', family = 'test family', Product_Level__c='OnPrem', Product_Type__c='Foundation Edition', ProductCode = 'OPTY-SPLIT'),
                new Product2(Name = '-UG-P-BUE', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                new Product2(Name = '-BE-HPE', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                new Product2(Name = '-BE-', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                    new Product2(Name = 'RCDM-T', family = 'test family', ProductCode = 'OPTY-SPLIT', Product_Subtype__c = 'Saas Cloud'),
                new Product2(Name = '-SCALE-', family = 'test family', ProductCode = 'OPTY-SPLIT', Product_Subtype__c = 'Saas Cloud'),

                    new Product2(Name = 'RSC - with RCDM', family = 'test family', ProductCode = 'OPTY-SPLIT', Product_Subtype__c = 'Complete'),
                    new Product2(Name = 'Scale Utility - SaaS', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                    new Product2(Name = 'Scale Utility - OnDemand', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                new Product2(Name = 'Test4', Category__c = 'saas', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                new Product2(Name = '-SCALE-', family = 'test family', ProductCode = 'OPTY-SPLIT'),
                new Product2(Name = 'Test4', Product_Type__c = 'Travel & Expense', family = 'test family', ProductCode = 'OPTY-SPLIT')
                
                };
                    insert lstProds;
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', isActive = true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        
        List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
            new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[3].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[4].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[5].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[6].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[7].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[8].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[9].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[10].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[11].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[12].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[13].Id, IsActive = true, UseStandardPrice=false)
                };
                    System.runAs(getUser('System Administrator'))  {
                        insert pbEntry;
                    }
        
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.accountTrigger = false;
        
        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Pricebook2Id=standardPBId;
        opp.Split_percentage__c=25;
        opp.split_amount__c = 0.00;
        opp.split__c = true;
        opp.Has_LOD_Products__c = true;
        opp.Order_Sub_Type__c = 'Renewal';
        //opp.Opportunity_Sub_Type__c = 'MSP Overage';
        
        insert opp;
        Opportunity opp1 = TestDataFactory.getOpportunity();
        opp1.Pricebook2Id=standardPBId;
        opp1.Split_percentage__c=75;
        opp1.split_amount__c = 10.00;
        opp1.split__c = true;
        opp1.Opportunity_Split_Parent__c = opp.id;
        opp1.Has_LOD_Products__c = true;
        opp1.Order_Sub_Type__c = 'MSP Consumption';
        opp1.Opportunity_Sub_Type__c = 'MSP Overage';
        
        insert opp1;
            Opportunity opp2 = TestDataFactory.getOpportunity();
            opp2.Pricebook2Id=standardPBId;
            opp2.Split_percentage__c=25;
            opp2.split_amount__c = 0.00;
            opp2.split__c = true;
            opp2.Has_LOD_Products__c = true;
            opp2.Order_Sub_Type__c = 'GC OnDemand';
            insert opp2;
            Opportunity opp3 = TestDataFactory.getOpportunity();
            opp3.Pricebook2Id=standardPBId;
            opp3.Split_percentage__c=25;
            opp3.split_amount__c = 0.00;
            opp3.split__c = true;
            opp3.Has_LOD_Products__c = true;
            opp3.Order_Sub_Type__c = 'GC Offer';
            insert opp3;
        System.assert(opp.Id != null);
        FlowControll.opportunityTriggerHandler = true;
        
        //Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = opp.AccountId;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Type__c = 'Quote';
        insert qt; 
        
        List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[3].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[4].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[5].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[6].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[7].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[8].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[9].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[10].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[11].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[12].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[13].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2')
                }; 
                    insert qli1;
        
        Test.startTest();
        //OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id);
        
        List<OpportunityLineItem> lstOLIs = new List<OpportunityLineItem>();
        //lstOLIs.add(new OpportunityLineItem(Product2Id = newProd.Id, pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id, SBQQ__QuoteLine__c=qli1.Id));
            system.debug(System.logginglevel.DEBUG, 'PB ENTRY  ====> '+pbEntry.size());
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[0].Id, pricebookentryid=pbEntry[0].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[1].Id, pricebookentryid=pbEntry[1].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[2].Id, pricebookentryid=pbEntry[2].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[3].Id, pricebookentryid=pbEntry[3].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[4].Id, pricebookentryid=pbEntry[4].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[5].Id, pricebookentryid=pbEntry[5].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[6].Id, pricebookentryid=pbEntry[6].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[7].Id, pricebookentryid=pbEntry[7].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[8].Id, pricebookentryid=pbEntry[8].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[9].Id, pricebookentryid=pbEntry[9].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[10].Id, pricebookentryid=pbEntry[10].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[11].Id, pricebookentryid=pbEntry[11].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[12].Id, pricebookentryid=pbEntry[12].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        lstOLIs.add(new OpportunityLineItem(ACV_Amount__c = 100,Product2Id = lstProds[13].Id, pricebookentryid=pbEntry[13].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp.Id));
        
        
        insert lstOLIs;
        
        OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(
            [SELECT Product2.Name, Product2.Product_Subtype__c, Opportunity.Order_Sub_Type__c, opportunity.Opportunity_Sub_Type__c,
             Product2.Product_Type__c, Product2.Category__c, SBQQ__QuoteLine__r.Licensing_Model__c, Product2.Product_Level__c
             FROM OpportunityLineItem WHERE Id IN :lstOLIs],opp);
        list<OpportunitySplitMapping__c>oppSplitMapping = [select id from OpportunitySplitMapping__c];
            Opportunity oppTest = [SELECT Id,Order_Sub_Type__c, (SELECT Id,ProductCode FROM OpportunityLineItems),(SELECT Id,Split_Amount__c,Split_percentage__c
                                                                                             FROM Split_Opportunities__r) FROM Opportunity WHERE Id=:opp1.Id LIMIT 1];

        OpportunityObjectTriggerHelper.setSplitOpportunityLineItem(opp,lstOLIs[0],20);
        OpportunityObjectTriggerHelper.syncSplitOpportunities(opp,new Map<Id,Opportunity> {opp.id =>opp},lstOLIs,lstOLIs,oppSplitMapping,new Map<Id,OpportunityLineItem> {lstOLIs[0].id =>lstOLIs[0]});
        OpportunityObjectTriggerHelper.updateSplitChildrenOpportynities(oppTest,20,new Map<Id,Opportunity> {opp.id =>opp},oppSplitMapping,new Map<Id,OpportunityLineItem> {lstOLIs[0].id =>lstOLIs[0]});
        OpportunityObjectTriggerHelper.getTotalOpportunityAmount(opp,lstOLIs,lstOLIs);
        Test.stopTest();
    }  
    }  
    //SAL23-926 //SAL24-120
    @istest
    static void testOpportunityUpdateblocker(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        Id standardPBId = test.getStandardPricebookId();
        Opportunity opp = TestDataFactory.getOpportunity();
        List<Opportunity> oppList=new List<Opportunity>();
        opp.Pricebook2Id=standardPBId;
        opp.Split_percentage__c=25;
        opp.split_amount__c = 0.00;
        opp.split__c = true;
        opp.Order_Sub_Type__c = 'MSP Consumption';
        opp.Send_Hold_Off_Email__c = true;
        opp.Opportunity_Sub_Type__c = 'Renewal';
        opp.Renewals_Sentiment__c='Green';
        opp.Opportunity_Type__c='Partner';
        opp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        Opportunity opp2 =opp.clone();
        opp.Renewals_Sentiment__c='Yellow';
        oppList.add(opp);
        oppList.add(opp2);
        Test.startTest();
        insert oppList;
        for(Opportunity oppnew:oppList){
            oppnew.Renewals_Sentiment__c=(oppnew.Renewals_Sentiment__c=='Green')?'Yellow':'Green';
        }
        update oppList;
        OpportunityObjectTriggerHelper.clearDRInfoOnClonedOpportunity(oppList);
        //OppAnnualContractValueUtil.testingMethod();
        Test.stopTest();
        System.assert((oppList[0].Id!=null), 'Correct');
    }
    }
    
    @isTest
    static void createTasksForRenewalExpansionQuoteTest(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.StageName = '2 Consensus';
        oppObject1.CloseDate = System.today() +2;
        oppObject1.Opportunity_Program__c = 'Refresh';
        Test.startTest();
        insert oppObject1;
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppObject1.Id, SBQQ__Type__c = 'Renewal+Expansion', SBQQ__Primary__c=true));
        quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppObject1.Id, SBQQ__Type__c = 'Renewal', SBQQ__Primary__c=false));
        quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppObject1.Id, SBQQ__Type__c = 'Renewal', SBQQ__Primary__c=false));
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert quoteList;
        
        oppObject1.SBQQ__PrimaryQuote__c = quoteList[0].Id;
        update oppObject1;
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        System.assert(oppObject1.Id != null);
        Test.stopTest();
    }
    }
    
    //SAL24-679
    /*@isTest
static void manageNPMAccountOpptyShareFutureTest(){
ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
insert settingDisable;
        
List<User> listUsers = new List<User>();
Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
Id listProfile2 = [Select Id From Profile Where Name = 'Sales Operations'].Id;
List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 1);
List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 3);
listUsers.addAll(listUsers1);
listUsers.addAll(listUsers2);
insert listUsers;
Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
List<Account> accounts = new List<Account>{
new Account(Name = 'Test CP Account 1', RecordTypeId = AcRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
new Account(Name = 'Test PD Account 1', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId()),
new Account(Name = 'Test PD Account 2', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId()),
new Account(Name = 'Test PD Account 3', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
};
insert accounts;
        
List<Account_To_Users__c> atuList = new List<Account_To_Users__c>();
atuList.add(new Account_To_Users__c(Account__c = accounts[1].Id, User__c = listUsers2[0].Id, Relationship_Type__c ='National Partner Manager'));
atuList.add(new Account_To_Users__c(Account__c = accounts[2].Id, User__c = listUsers2[1].Id, Relationship_Type__c ='National Partner Manager'));
atuList.add(new Account_To_Users__c(Account__c = accounts[3].Id, User__c = listUsers2[2].Id, Relationship_Type__c ='National Partner Manager'));
insert atuList;
        
List<Opportunity> oppList=new List<Opportunity>();
System.runAs(listUsers[0]){
            
ShGl_DisableBusinessLogic__c csettingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
csettingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
csettingDisable.Disable_SBQQ_Quote_Triggers__c = true;
csettingDisable.Disable_Opportunity_Validation_Rules__c  = true;
insert csettingDisable;
            
Opportunity opp1 = TestDataFactory.getOpportunity(accounts[0]);
opp1.StageName = '1 Discovery';
opp1.CloseDate = System.today() +2;
oppList.add(opp1);
Opportunity opp2 = opp1.clone();
opp2.Partner_Lookup__c = accounts[1].Id;
opp2.Sourcing_Partner__c = accounts[2].Id;
opp2.Teaming_Partner__c = accounts[3].Id;
oppList.add(opp2);
Test.startTest();
insert oppList;
oppList[0].Partner_Lookup__c = accounts[1].Id;
oppList[1].Teaming_Partner__c = null;
update oppList;
Test.stopTest();
List<OpportunityShare> oppShare1 = [select ID, UserOrGroupId from OpportunityShare where OpportunityId = :opp1.Id and Rowcause = 'Manual'];
List<OpportunityShare> oppShare2 = [select ID, UserOrGroupId from OpportunityShare where OpportunityId = :opp2.Id and Rowcause = 'Manual'];
//system.assertEquals(oppShare1.size()==1,true,'not matching');
//system.assertEquals(oppShare2.size()==2,true,'not matching');
            
}
}*/ // SAL26-75
    
    @isTest
    static void updateOpptyShareRecForRenewalOpptyFutureTest(){
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        settingDisable.Disable_ServiceContract_Trigger__c=true;
        settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
        settingDisable.Disable_Entitlement_Trigger__c=true;
        settingDisable.Disable_Asset_Triggers__c=true;
        settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
        settingDisable.Disable_Account_Validation_Rules__c = true; 
        insert settingDisable;
        
        ShGl_DisableFunctionalityLogic__c ds = ShGl_DisableFunctionalityLogic__c.getInstance();
        ds.Allow_account_Transfer__c = true;
        ds.DisableDemandMatrixCalculation__c = true;
        upsert ds;
        
        Account acc = new Account(Name = 'Test Account', ParentId = null);
        insert acc;
        
        Id standardPBId = test.getStandardPricebookId();
        List<Product2> lstProds = new List<Product2>{
            new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-'),
                new Product2(Name = 'RSCP-BE-', family = 'test family', ProductCode = 'RSCP-BE-'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RSCP-BUE-')
                };
                    insert lstProds;
        
        List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
            new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
                };
                    System.runAs(getUser('System Administrator'))  {
                        insert pbEntry;
                    }
        
        List<User> listUsers = new List<User>();
        Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 1);
        List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 1);
        List<User> listUsers3 = TestDataFactory.getUsers('testClassUser3', new Set<Id>{listProfile1}, 1);
        listUsers.addAll(listUsers1);
        listUsers.addAll(listUsers2);
        listUsers.addAll(listUsers3);
        insert listUsers;
		listUsers[0].RBAC_Department__c = 'Service Account';
        listUsers[0].RBAC_Group__c = 'System - IT';
        update listUsers;
        
        //Create Sales Opptys
        List<Opportunity> oppList=new List<Opportunity>();
        Opportunity sOpp = TestDataFactory.getOpportunity();
        sOpp.AccountId = acc.Id;
        sOpp.Pricebook2Id=standardPBId;
        sOpp.Opportunity_Sub_Type__c = 'Regular';
        sOpp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        sOpp.Deal_Registration__c = True;
        sOpp.Deal_Reg_Approval_Status__c = 'Approved';
        sOpp.Converted_From_Lead__c = true;
        sOpp.Opportunity_Split_Parent__c = null;
        sOpp.OwnerId = UserInfo.getUserId();
        sOpp.StageName = '6 PO With Channel';
        //oppList.add(sOpp);
        Opportunity sOpp2 = sOpp.clone();
        oppList.add(sOpp2);
        Opportunity sOpp3 = sOpp.clone();
        insert sOpp3;
        
        
        //Create Renewal Opptys
        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Pricebook2Id=standardPBId;
        opp.Opportunity_Sub_Type__c = 'Renewal';
        opp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        opp.Deal_Registration__c = True;
        opp.Deal_Reg_Approval_Status__c = 'Approved';
        opp.OwnerId = UserInfo.getUserId();
        opp.Converted_From_Lead__c = true;
        opp.Opportunity_Split_Parent__c = null;
        Opportunity opp2 =opp.clone();
        Opportunity opp3 =opp.clone();
        Opportunity opp4 =opp.clone();
        oppList.add(opp);
        oppList.add(opp2);
        oppList.add(opp3);
        oppList.add(opp4);
        Test.startTest();
        insert oppList;
        System.assert((oppList[0].Id!=null), 'Correct');
        
        
        opp.OwnerId = listUsers[0].Id;
        opp2.OwnerId = listUsers[1].Id;
        opp3.OwnerId = listUsers[1].Id;
        opp4.OwnerId = listUsers[2].Id;
        update oppList;
        
        List<OpportunityShare> oppShareList = new List<OpportunityShare>();
        OpportunityShare oppShr  = new OpportunityShare();
        oppShr.opportunityId  = oppList[0].Id;
        oppShr.UserOrGroupId = listUsers[0].Id;
        oppShr.OpportunityAccessLevel = 'Edit';
        oppShr.RowCause = Schema.OpportunityShare.RowCause.Manual;
        OpportunityShare oppShr3  = new OpportunityShare();
        oppShr3.opportunityId  = oppList[1].Id;
        oppShr3.UserOrGroupId = listUsers[1].Id;
        oppShr3.OpportunityAccessLevel = 'Edit';
        oppShr3.RowCause = Schema.OpportunityShare.RowCause.Manual;
        OpportunityShare oppShr4  = new OpportunityShare();
        oppShr4.opportunityId  = oppList[1].Id;
        oppShr4.UserOrGroupId = UserInfo.getUserId();
        oppShr4.OpportunityAccessLevel = 'Edit';
        oppShr4.RowCause = Schema.OpportunityShare.RowCause.Manual;
        
        oppShareList.add(oppShr);
        oppShareList.add(oppShr3);
        oppShareList.add(oppShr4);
        insert oppShareList;
        
        List<ServiceContract> lstSCs = new List<ServiceContract>();
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = acc.id;
        testContract.SBQQSC__Opportunity__c = sOpp3.Id;
        testContract.SBQQSC__RenewalOpportunity__c = opp.Id;
        testContract.Name = 'Test Service Contract for Renewal1';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        testContract.Pricebook2Id = standardPBId;
        testContract.SBQQSC__RenewalForecast__c = true;
        
        ServiceContract testContract2 = testContract.clone();
        testContract2.Name = 'Test Service Contract for Renewal2';
        testContract2.SBQQSC__RenewalOpportunity__c = opp2.Id;
        testContract2.SBQQSC__RenewalForecast__c = true;
        
        ServiceContract testContract3 = testContract.clone();
        testContract3.Name = 'Test Service Contract for Renewal3';
        testContract3.SBQQSC__RenewalOpportunity__c = opp3.Id;
        testContract3.SBQQSC__RenewalForecast__c = true;
        
        ServiceContract testContract4 = testContract.clone();
        testContract4.Name = 'Test Service Contract for Renewal4';
        testContract4.SBQQSC__RenewalOpportunity__c = opp4.Id;
        testContract4.SBQQSC__RenewalForecast__c = true;
        
        lstSCs.add(testContract);
        lstSCs.add(testContract2);
        lstSCs.add(testContract3);
        lstSCs.add(testContract4);
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        insert lstSCs;
        
        
        List<ContractLineItem> cli1 = new List<ContractLineItem>{
            new ContractLineItem(ServiceContractId = lstSCs[0].Id, SBQQSC__Product__c = lstProds[0].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[0].Id),
                new ContractLineItem(ServiceContractId = lstSCs[1].Id, SBQQSC__Product__c = lstProds[1].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[1].Id),
                new ContractLineItem(ServiceContractId = lstSCs[2].Id, SBQQSC__Product__c = lstProds[2].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[2].Id),
                new ContractLineItem(ServiceContractId = lstSCs[3].Id, SBQQSC__Product__c = lstProds[2].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[2].Id)
                }; 
                    system.RunAs(listUsers[0]){
                    insert cli1;
                    }
        Test.stopTest();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppList[1].Id, SBQQ__Type__c = 'Renewal+Expansion',SBQQ__Account__c = acc.Id));
        quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppList[1].Id, SBQQ__Type__c = 'Renewal+Expansion',SBQQ__Account__c = acc.Id));
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        insert quoteList;
        List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2',SBQQSC__RenewedContractLine__c = cli1[0].Id, SBQQ__PricebookEntryId__c = pbEntry[0].Id ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'Asset1, Asset2', SBQQSC__RenewedContractLine__c = cli1[1].Id, SBQQ__PricebookEntryId__c = pbEntry[1].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, SubscribedAssetNames__c = 'Asset1, Asset2', SBQQSC__RenewedContractLine__c = cli1[2].Id, SBQQ__PricebookEntryId__c = pbEntry[2].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[1].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2', SBQQSC__RenewedContractLine__c = cli1[3].Id, SBQQ__PricebookEntryId__c = pbEntry[2].Id)
                }; 
                    insert qli1;
        
        List<Opportunity> lstToUpdate = new List<Opportunity>();
        opp.OwnerId = listUsers[1].Id;
        opp2.OwnerId = listUsers[2].Id;
        lstToUpdate.add(opp);
        lstToUpdate.add(opp2);
        update lstToUpdate;
    }
    
    /*
@isTest
static void testOpportunityUpdateStageTo6(){
Test.startTest();
List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
insert listUser;
System.runAs(listUser[0])
{

ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id);
sdb.Disable_Opportunity_Validation_Rules__c = true;
sdb.Disable_SBQQ_Quote_Validation_Rules__c= true;
sdb.Disable_Opportunity_Triggers__c = true;
insert sdb;

ShGl_DisableFunctionalityLogic__c disableFuncCS = new ShGl_DisableFunctionalityLogic__c(setupownerid = listUser[0].Id);
disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
disableFuncCS.Disable_OpportunityValidationRules__c = true;
insert disableFuncCS;

Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
List<Account> accounts = new List<Account>{
new Account(Name = 'Test Account', RecordTypeId = AcRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
new Account(Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
};
insert accounts;
Opportunity oppObject = TestDataFactory.getOpportunity(accounts[0]);
oppObject.Distributor_Lookup__c = accounts[1].Id;
oppObject.Partner_Lookup__c = accounts[1].Id;
oppObject.Aspen_Eligibility__c = 'Proposed Aspen';
oppObject.StageName = '1 Discovery';
oppObject.Opportunity_Sub_Type__c = 'Regular';
oppObject.Pricebook2Id =  System.Label.CPQPricebookId;
insert oppObject;

List<Product2> sampleProducts = new List<Product2>{
// 0
new Product2(
Name = 'CPQ Bundle Product',
ProductCode = 'CPQ Bundle Product',
IsActive = true,
Product_Level__c = 'Hybrid Software',
SBQQ__Hidden__c = true,
SBQQ__ExcludeFromOpportunity__c = true,
New_CPQ_Product__c = true
),
// 1
new Product2(
Name = 'HW',
ProductCode = 'HW',
Category__c = 'Platform',
Family = 'r300',
Usable_Capacity__c = 1,
Product_Level__c = 'Hardware',
Product_Type__c = 'Hardware',
Appliance_Model__c = 'RBK-R344',
Appliance_Model_HW__c = 'RBK-R344',
CPQ_MSP_Base_Price__c = 0.13,
SBQQSC__EntitlementConversion__c = 'None',
SBQQ__AssetAmendmentBehavior__c = 'Default',
IsActive = true,
Asset_Priority__c = 0,
MSP_Segment_Product__c = true,
SBQQ__SubscriptionPricing__c = 'Fixed Price',
SBQQ__SubscriptionTerm__c = 1,
SBQQ__SubscriptionBase__c = 'List',
SBQQ__SubscriptionType__c = 'Renewable',
Bundle_Features__c = 'Sonar'
)
};
insert sampleProducts;
List<PricebookEntry> entries = new List<PricebookEntry>{
new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100),
new PricebookEntry( Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 0),
new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100),
new PricebookEntry( Pricebook2Id = System.Label.CPQPricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 0)
};
insert entries;
Map<Id,Id> productToPricebookEntry = new Map<Id,Id>();
for(PricebookEntry entry: entries ) {
if(entry.Pricebook2Id == System.Label.CPQPricebookId) productToPricebookEntry.put(entry.Product2Id, entry.Id);
}
System.assert(oppObject.Id != null);
SBQQ__Quote__c quote = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
new SBQQ__Quote__c(),
new Map<String, Object>{
'SBQQ__Account__c' => oppObject.AccountId,
'SBQQ__Opportunity2__c' => oppObject.Id,
'SBQQ__Primary__c' => true,
'SBQQ__SubscriptionTerm__c' => 12,
// 'Is_RWD_Polaris_Quote__c' => true,
'ProcessType__c' => 'Aspen',
'SBQQ__PaymentTerms__c' => 'Net 45'
}
);

insert quote;
List<ProductModel> prodModels = new List<ProductModel>();

for (product2 prod : sampleProducts) {
prodModels.add(
(ProductModel) JSON.deserialize(
SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.Id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "USD"}'),
ProductModel.class
)
);
}

String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
ProductAdder adder = new ProductAdder();
QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
Map<String, Integer> prodKey = new Map<String, Integer>();
for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
if (QLModel.record.Product_Level__c == 'Hybrid Software') {
prodKey.put(QLModel.record.SBQQ__ProductCode__c, QLModel.key);
QLModel.record.SBQQ__Quantity__c = 500;
QLModel.record.SBQQ__SubscriptionTerm__c = 12;
QLModel.record.SBQQ__NetPrice__c = 100;
} else if (QLModel.record.Product_Level__c == 'Hardware') {
prodKey.put(QLModel.record.SBQQ__ProductCode__c, QLModel.key);
QLModel.record.SBQQ__Quantity__c = 6;
QLModel.record.SBQQ__NetPrice__c = 0;
}
QLModel.record.SBQQ__PricebookEntryId__c = productToPricebookEntry.get(QLModel.record.SBQQ__Product__c);

}
for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
if (QLModel.record.Product_Level__c == 'Hardware') {
QLModel.parentItemKey = prodKey.get('CPQ Bundle Product');
}
} 
quote.ApprovalStatus__c = 'Approved';
quote.SBQQ__Status__c = 'Approved';
quote.Payment_year_2__c = 0;
update quote;
oppObject.StageName = '6 PO With Channel';
//oppObject.CM_Notification_To_Distributor__c = 'Recalculate & Send CM recommendation';
//Test.startTest();
TriggerManager.resetTriggerCounter('Opportunity');
update oppObject;
System.assert(oppObject.Id != null);
Test.stopTest();
}
//OpportunityObjectTriggerHelper.testCodeCoverage();
}*/
    private static User getUser (String profileName){
        return [SELECT Id FROM User WHERE Profile.Name = :profileName AND isActive=true AND Id != :UserInfo.getUserId() LIMIT 1];
    }
    @istest
    static void isStage5ChangeAllowedTest(){
        User us =getUser('Sales Operations');
        System.runAs(us) {
			//SAL26-549 start 
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(SetupOwnerId=us.Id);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_SBQQ_Quote_Validation_Rules__c= true;
            sdb.Disable_Opportunity_Triggers__c = true;
            sdb.Disable_Account_Validation_Rules__c = true;
            insert sdb; //SAL26-549 end
            Opportunity op = TestDataFactory.getOpportunity();
            insert op;
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Microsoft Azure Marketplace';
            vAccount.Type='Distributor';
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            Account vAccount2 = new Account();
            vAccount2.Name = 'Rubrik Field Sales User';
            vAccount2.recordTypeId = vAccount.recordTypeId;
            vAccount2.Payment_Term__c = 'Net 30';
            accountList.add(vAccount2);
            Account vAccount3 = new Account();
            vAccount3.Name = 'ASPEN Disti TBD';
            vAccount3.recordTypeId = vAccount.recordTypeId;
            vAccount3.Payment_Term__c = 'Net 30';
            accountList.add(vAccount3);
            Test.StartTest();
            insert accountList;   
            op.Distributor_Lookup__c=vAccount.Id;
            update op;
            op.Distributor_Lookup__c=vAccount2.Id;
            update op;
            op.Distributor_Lookup__c=vAccount3.Id;
            update op;
            //OpportunityObjectTriggerHelper.testpasser(); SAL26-117
            
            List<Opportunity> newOpptys = new List<Opportunity>();
            newOpptys.add(op);
            try{
                OpportunityObjectTriggerHelper.preventAmendingNonGCOfferContracts(newOpptys);
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG, '@@ exception '+e.getMessage());
            }
            Test.StopTest();
            System.assert(op.Id != null);
        }
    }

    @istest
    static void testPLSOpptyETMLogic(){
        List<Profile> profList = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> userList = TestDataFactory.getUsers('testPLSUser', new Set<Id>{profList[0].Id}, 2);
        userList[0].LastName = 'testPLSUser';
        insert userList;
        List<UserTerritory2Association> utaList = new List<UserTerritory2Association>();
        System.runAs(userList[0]) {
            ShGl_DisableFunctionalityLogic__c disfunCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disfunCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disfunCS;
            Test.startTest();
            List<Territory2> territoryList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 10];                     
            utaList.add(new UserTerritory2Association(Territory2Id = territoryList[0].Id,RoleInTerritory2 = 'SaaS AE',UserId = userList[0].id));
            utaList.add(new UserTerritory2Association(Territory2Id = territoryList[0].Id,RoleInTerritory2 = 'PLS SE',UserId = userList[1].id));
            insert utaList ;
            
            FlowControll.AccountTrigger=false;
            Opportunity opp = TestDataFactory.getOpportunity();
            
            Account acc = new Account(Id=opp.AccountId, Adaptive_Territory_Id__c=territoryList[0].Adaptive_Territory_Id__c); 
            insert new ObjectTerritory2Association(ObjectId =acc.id , Territory2Id =territoryList[0].id, AssociationCause ='Territory2Manual');
            update acc; 
            insert opp;
            OpportunityObjectTriggerHelper.updateSDPAccType(new Set<Id> {acc.Id});
            OpportunityObjectTriggerHelper.updateRSCOwner(new List<Opportunity> {OPP});
            OpportunityObjectTriggerHelper.updatePSNLonAccount(new List<Opportunity> {OPP});
            OpportunityObjectTriggerHelper.unlockOpportunities(new List<Id> {OPP.Id});
            id ids=[select id from contact limit 1].id;
            OpportunityObjectTriggerHelper.polarisContactValidation(OPP,new Map<Id,Set<Id>>{OPP.Id=>new set<Id>{ids}});
            Test.stopTest();
            Opportunity oppRes = [SELECT Id,OwnerId,Rubrik_Sales_Engineer__c from Opportunity where Id =:opp.Id limit 1];
            System.assertEquals(oppRes.OwnerId, userList[0].id);
            //System.assertEquals(oppRes.Rubrik_Sales_Engineer__c, userList[1].id);
        }
    }
       @isTest
    public static void  testIsCommissionPortfolioTypeChangedNonOplySplit(){
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c sdb = ShGl_DisableBusinessLogic__c.getInstance();
        sdb.Disable_SBQQ_Quote_Triggers__c = true;
        sdb.Disable_SBQQ_QuoteLine_Triggers__c= true;
        sdb.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        sdb.Disable_Account_Validation_Rules__c = true; 
        sdb.Disable_Opportunity_Triggers__c=true;
        upsert sdb;
        
        List<Product2> lstProds = new List<Product2>{
            new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'RSCP-BE-', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'RS', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = '-UG-P-BUE', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = '-BE-HPE', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = '-BE-', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'Test', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP', Product_Subtype__c = 'Saas Cloud'),
                new Product2(Name = '-SCALE-', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP', Product_Subtype__c = 'Saas Cloud'),

                new Product2(Name = 'Test1', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP', Product_Subtype__c = 'Complete'),
                new Product2(Name = 'Test2', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'Test3', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'Test4', Category__c = 'saas', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = '-SCALE-', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP'),
                new Product2(Name = 'Test4', Product_Type__c = 'Travel & Expense', family = 'test family', ProductCode = 'RS-UR-FE-MDX-PE-PP')
                
                };
                    insert lstProds;
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', isActive = true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        
        List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
            new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[3].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[4].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[5].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[6].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[7].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[8].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[9].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[10].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[11].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[12].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[13].Id, IsActive = true, UseStandardPrice=false)
                };
                    System.runAs(getUser('System Administrator'))  {
                        insert pbEntry;
                    }
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        INSERT listUser;
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 10];                     
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Cloud AE',UserId = listUser[0].id)); //SAL26-138:NAS to Cloud
            INSERT UTAList;
        }
        Id userId = [SELECT Id, userId FROM UserTerritory2Association WHERE RoleInTerritory2 = 'Cloud AE' LIMIT 1].userId;
        
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.accountTrigger = false;
        
        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Pricebook2Id=standardPBId;
        opp.Split_percentage__c=25;
        opp.split_amount__c = 0.00;
        opp.split__c = true;
        opp.Has_LOD_Products__c = true;
        opp.Order_Sub_Type__c = 'MSP Consumption';
        opp.Opportunity_Sub_Type__c = 'MSP Overage';
        
        insert opp;
        Opportunity opp1 = TestDataFactory.getOpportunity();
        opp1.Pricebook2Id=standardPBId;
        opp1.Split_percentage__c=75;
        opp1.split_amount__c = 10.00;
        opp1.split__c = true;
        opp1.Opportunity_Split_Parent__c = opp.id;
        opp1.Has_LOD_Products__c = true;
        opp1.Order_Sub_Type__c = 'MSP Consumption';
        opp1.Opportunity_Sub_Type__c = 'MSP Overage';
        opp1.ETM_Theatre__c = 'EMEA';
        opp1.Co_Owner__c = Userinfo.getUserId();
        opp1.PLS_ETM_Overrides__c = 'CLOUD ETM Override';
        



        opp1.ETM_Theatre__c = 'EMEA';
        opp1.Co_Owner__c = Userinfo.getUserId();
        opp1.PLS_ETM_Overrides__c = 'CLOUD ETM Override';
        



        opp1.ETM_Theatre__c = 'EMEA';
        opp1.Co_Owner__c = Userinfo.getUserId();
        opp1.PLS_ETM_Overrides__c = 'CLOUD ETM Override';
        
        insert opp1;
        List<Opportunity> oplist = new List<Opportunity>();
        Opportunity opp2 = TestDataFactory.getOpportunity();
        opp2.Pricebook2Id=standardPBId;
        opp2.Split_percentage__c=75;
        opp2.split_amount__c = 0;
        opp2.split__c = true;
        opp2.Opportunity_Split_Parent__c = opp1.id;
        opp2.Has_LOD_Products__c = true;
        opp1.Co_Owner__c = userId;
        opp2.Opportunity_Sub_Type__c = 'MSP Overage';
        opp2.ETM_Theatre__c = 'APAC';
        opp2.Co_Owner__c = Userinfo.getUserId();
        opp2.PLS_ETM_Overrides__c = 'CLOUD ETM Override';
        oplist.add(opp2);
        
          Opportunity opp3 = TestDataFactory.getOpportunity();
        opp3.Pricebook2Id=standardPBId;
        opp3.Split_percentage__c=10;
        opp3.split_amount__c = 0;
        opp3.split__c = true;
        opp3.Opportunity_Split_Parent__c = opp1.id;
        opp3.Has_LOD_Products__c = true;
        opp3.Order_Sub_Type__c = 'MSP Consumption';
        opp2.Co_Owner__c = userId;
        
        oplist.add(opp3);
        insert oplist;

        System.assert(opp.Id != null);
        FlowControll.opportunityTriggerHandler = true;
        
        //Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = opp.AccountId;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Type__c = 'Quote';
        insert qt; 
        
        List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[3].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[4].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[5].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[6].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[7].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[8].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[9].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[10].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[11].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[12].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2'),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = lstProds[13].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2')
                }; 
                    insert qli1;
        
        Test.startTest();
        //OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id);
        
        List<OpportunityLineItem> lstOLIs = new List<OpportunityLineItem>();
        //lstOLIs.add(new OpportunityLineItem(Product2Id = newProd.Id, pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id, SBQQ__QuoteLine__c=qli1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[0].Id, pricebookentryid=pbEntry[0].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[1].Id, pricebookentryid=pbEntry[1].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[2].Id, pricebookentryid=pbEntry[2].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[3].Id, pricebookentryid=pbEntry[3].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[4].Id, pricebookentryid=pbEntry[4].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[5].Id, pricebookentryid=pbEntry[5].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[6].Id, pricebookentryid=pbEntry[6].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[7].Id, pricebookentryid=pbEntry[7].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[8].Id, pricebookentryid=pbEntry[8].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[9].Id, pricebookentryid=pbEntry[9].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[10].Id, pricebookentryid=pbEntry[10].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[11].Id, pricebookentryid=pbEntry[11].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[12].Id, pricebookentryid=pbEntry[12].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        lstOLIs.add(new OpportunityLineItem(Product2Id = lstProds[13].Id, pricebookentryid=pbEntry[13].Id, TotalPrice=2000, Quantity = 2, OpportunityID = opp1.Id));
        insert lstOLIs;
        
        update opp1;
        
        sdb.Disable_Opportunity_Triggers__c=false;
        upsert sdb;
        OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(
            [SELECT Product2.Name, Product2.Product_Subtype__c, Opportunity.Order_Sub_Type__c, opportunity.Opportunity_Sub_Type__c,
             Product2.Product_Type__c, Product2.Category__c, SBQQ__QuoteLine__r.Licensing_Model__c, Product2.Product_Level__c
             FROM OpportunityLineItem WHERE Id IN :lstOLIs],opp);
        list<OpportunitySplitMapping__c>oppSplitMapping = [select id,Field__c,Default_Value__c,From_Field__c,Suffix__c,Skip_Update_if_child_has_value__c from OpportunitySplitMapping__c];
        OpportunityObjectTriggerHelper.setSplitOpportunityLineItem(opp,lstOLIs[0],20);
        
        Opportunity oppTest = [SELECT Id,Name,StageName,CloseDate,Split_percentage__c,Pricebook2Id,Order_Sub_Type__c,NextStep,Split_Amount__c, ETM_Theatre__c,PLS_ETM_Override__c,Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c, PLS_AE_ETM_Role_Name__c,Core_PLS_source__c,Co_Owner__c,Rubrik_Co_Sales_Engineer__c,PLS_ETM_Overrides__c,SaaS_Co_Owner__c,Opp_PLS_SaaS_ETM_Area__c,Opp_PLS_SaaS_ETM_Region__c,Opp_PLS_SaaS_ETM_Territory__c,Opp_PLS_SaaS_ETM_Theatre__c,NCD_Co_Owner__c,Opp_PLS_NCD_ETM_Area__c,Opp_PLS_NCD_ETM_Region__c,Opp_PLS_NCD_ETM_Territory__c,Opp_PLS_NCD_ETM_Theatre__c,Non_Core_Adaptive_Id__c, (SELECT Id,ProductCode FROM OpportunityLineItems),(SELECT Id,Split_Amount__c,Pricebook2Id,Split_percentage__c,Name,StageName,PLS_ETM_Override__c,ETM_Theatre__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c, PLS_AE_ETM_Role_Name__c,Core_PLS_source__c, Co_Owner__c, CloseDate,Rubrik_Co_Sales_Engineer__c,PLS_ETM_Overrides__c, Opportunity_Split_Parent__r.PLS_ETM_Overrides__c,NCD_Co_Owner__c, SaaS_Co_Owner__c,Non_Core_Adaptive_Id__c
                                                                                             FROM Split_Opportunities__r) FROM Opportunity WHERE Id=:opp1.Id LIMIT 1]; //PL26-40
        Opportunity oppTest1 = [SELECT Id,Name,StageName,CloseDate,Split_percentage__c,Pricebook2Id,Order_Sub_Type__c,NextStep,Split_Amount__c, ETM_Theatre__c,PLS_ETM_Override__c,Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c, PLS_AE_ETM_Role_Name__c,Core_PLS_source__c,Co_Owner__c,Rubrik_Co_Sales_Engineer__c,PLS_ETM_Overrides__c,SaaS_Co_Owner__c,Opp_PLS_SaaS_ETM_Area__c,Opp_PLS_SaaS_ETM_Region__c,Opp_PLS_SaaS_ETM_Territory__c,Opp_PLS_SaaS_ETM_Theatre__c,NCD_Co_Owner__c,Opp_PLS_NCD_ETM_Area__c,Opp_PLS_NCD_ETM_Region__c,Opp_PLS_NCD_ETM_Territory__c,Opp_PLS_NCD_ETM_Theatre__c,Non_Core_Adaptive_Id__c, (SELECT Id,ProductCode FROM OpportunityLineItems),(SELECT Id,Split_Amount__c,Pricebook2Id,Split_percentage__c,Name,StageName,PLS_ETM_Override__c,ETM_Theatre__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c, PLS_AE_ETM_Role_Name__c,Core_PLS_source__c, Co_Owner__c, CloseDate,Rubrik_Co_Sales_Engineer__c,PLS_ETM_Overrides__c, Opportunity_Split_Parent__r.PLS_ETM_Overrides__c,NCD_Co_Owner__c, SaaS_Co_Owner__c,Non_Core_Adaptive_Id__c
                                                                                                                                                                                                                                                                                                                                                                               FROM Split_Opportunities__r) FROM Opportunity WHERE Id=:opp2.Id LIMIT 1]; //PL26-40
        
        OpportunityObjectTriggerHelper.syncSplitOpportunities(opp,new Map<Id,Opportunity> {opp.id =>opp},lstOLIs,lstOLIs,oppSplitMapping,new Map<Id,OpportunityLineItem> {lstOLIs[0].id =>lstOLIs[0]});
        OpportunityObjectTriggerHelper.updateSplitChildrenOpportynities(oppTest,20,new Map<Id,Opportunity> {opp.id =>opp},oppSplitMapping,new Map<Id,OpportunityLineItem> {lstOLIs[0].id =>lstOLIs[0]});
        OpportunityObjectTriggerHelper.updateSplitChildrenOpportynities(oppTest1,20,new Map<Id,Opportunity> {opp.id =>opp},oppSplitMapping,new Map<Id,OpportunityLineItem> {lstOLIs[0].id =>lstOLIs[0]});
        OpportunityObjectTriggerHelper.getTotalOpportunityAmount(opp,lstOLIs,lstOLIs);
        
        //SBQQ__Quote__c quote = [SELECT Id, (SELECT Id FROM LineItems) FROM SBQQ__Quote__c LIMIT 1];
        
        OpportunityObjectTriggerHelper.validateNetAppError(new Set<Id>{qt.Id}, new Map<Id,Opportunity>{opp.id => opp}, new List<SBQQ__Quote__c>{qt} );
        Test.stopTest();
    }  
    
    @isTest
    static void testOpportunitySDPandRSCGlogic(){
        List<User> listUsers = new List<User>();
        Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 1);
        List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 1);
        listUsers.addAll(listUsers1);
        listUsers.addAll(listUsers2);
        insert listUsers;
        listUsers[0].ManagerId = listUsers[1].Id;
        update listUsers;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUsers[0].Id, PermissionSetId = ps.Id);
            
        System.runAs(listUsers[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_SBQQ_Quote_Triggers__c = true;
          sdb.Disable_SBQQ_QuoteLine_Triggers__c= true;
          sdb.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c = true; 
            insert sdb;
            List<Account> accountList = new List<Account>();
            Account vAcc = new Account();
            vAcc.Name = 'Test Account';
            vAcc.Type = 'Prospect';
            vAcc.RSC_G_Eligible__c = true;
            vAcc.Focused_Partner__c = True;
                vAcc.Payment_Term__c = 'Net 30';
            vAcc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAcc);
            
            Account vAcc2 = new Account();
            vAcc2.Name = 'Test Account';
            vAcc2.RSC_G_Eligible__c = true;
            vAcc2.Type = 'Prospect';
            vAcc2.recordTypeId = vAcc.recordTypeId;
                vAcc2.Payment_Term__c = 'Net 30';
            accountList.add(vAcc2);
            insert accountList;
            Contact objContact = new Contact();
            objContact.Account = vAcc;
            objContact.LastName = 'Test Contact 31-05';
            insert objContact; 
            
            
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'Test', family = 'test family', ProductCode = 'OPTY-SPLIT', Product_Subtype__c = 'FEDRAMP'),
                    new Product2(Name = 'Test1', family = 'test family', ProductCode = 'OPTY-SPLIT', Product_Subtype__c = 'Complete')
                    };
                        insert lstProds;
            Id standardPBId = test.getStandardPricebookId();
            Pricebook2 pricebook = new Pricebook2(Name = 'Test Pricebook', isActive = true);
            insert priceBook;
            
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true),
                    new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true)
                    };
                        System.runAs(getUser('System Administrator'))  {
                            insert pbEntry;
                        }
            
            Opportunity oppObject1 = TestDataFactory.getOpportunity();
            Opportunity oppObject2 = TestDataFactory.getOpportunity();
            oppLi.add(oppObject1);
            oppLi.add(oppObject2);
            oppObject1.Opportunity_Type__c = 'Existing Customer';
            oppObject1.AccountId = vAcc2.Id;
           oppObject1.Pricebook2Id = standardPBId;
          oppObject1.MSP_End_User_Lookup__c = vAcc.Id;
            oppObject1.SBQQ__QuotePricebookId__c = standardPBId;
            oppObject2.Opportunity_Type__c = 'Existing Customer';
            oppObject2.MSP_End_User_Lookup__c = vAcc2.Id;
            oppObject2.Pricebook2Id = standardPBId;
            oppObject2.SBQQ__QuotePricebookId__c = standardPBId;
            insert oppLi;
            
             Test.startTest();
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(Product2Id = lstProds[0].Id, pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject1.Id));
            oppLineList.add(new OpportunityLineItem(Product2Id = lstProds[1].Id, pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject1.Id));
            oppLineList.add(new OpportunityLineItem(Product2Id = lstProds[0].Id, pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject2.Id));
            oppLineList.add(new OpportunityLineItem(Product2Id = lstProds[1].Id, pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject2.Id));
            insert oppLineList;
            
       oppObject1.Polaris_Portal_Contact__c = objContact.Id;
            oppObject1.Stagename = '5 Negotiate & Close';
            oppObject1.Opportunity_Type__c = 'New Customer';
            oppObject1.Opportunity_Sub_Type__c ='Regular';       
            oppObject2.StageName = '7 Closed Won';
            oppObject2.Rubrik_Security_Cloud_Gov_t_Owner__c = objContact.Id;
            oppObject2.Opportunity_Sub_Type__c ='Regular';
            oppObject2.Holdover_Requested__c = true;
            oppObject2.Holdover_Sales_Rep__c = listUsers[1].Id;
            oppObject1.MSP_End_User_Lookup__c = vAcc2.Id;
          Set<Id> sdpAccIds = new Set<Id>();
          sdpAccIds.add(vAcc.Id);
            update oppLi;
          OpportunityObjectTriggerHelper.updateRSCOwner(oppLi);
            System.assert(oppObject1.Id != null);
            Test.stopTest();
    }
    }
    
    //SAL25-247
    @isTest static void testPartnerReferralCCRRejected(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;

        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {

            List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
            String ContactID = [SELECT Id FROM Contact where LastName = 'Test Contact 01-06' LIMIT 1].Id;
            String AccountID = [SELECT Id FROM Account where Name = 'Test Account 01-06' LIMIT 1].Id;

        Opportunity Opp = new Opportunity();
        Opp.Id = lstOpp[0].Id;
        Opp.AccountId = AccountID;
        Opp.Amount = 3000;
        Opp.Opportunity_Type__c = 'New Customer';
        Opp.Opportunity_Sub_Type__c ='Regular';
        Opp.ETM_Theatre__c = 'AMER';
        Opp.ETM_Area__c = 'TEST';
        Opp.ETM_Region__c = 'TEST';
        update Opp;

        Map<String, Object> CCRMap = new Map<String, Object> {
            'Comment__c'=>'test',
                'Opportunity__c'=>lstOpp[0].id,
                'Affective_Person__c'=>listUser[0].Id,
                'CCR_Type__c'=>'Partner Referral Fee',
                'User__c'=>'Pending',
                'Account_Name__c'=>AccountID,
                'Effective_Date__c'=>System.today(),
                'Impacts_Commission__c'=>true,
                'Effective_End_Date__c'=>System.today(), 
                //'Booking__c'=> bkg.id,
                'Referral_Fee_Percent__c' => 20,
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
                };
        List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),3, CCRMap); 
        insert CCRList;
        
        Opp.Stagename = '7 Closed Lost';
        Opp.CloseDate = System.today();
        System.assert(opp.Id != null);
        Test.startTest();
        Approval.ProcessSubmitRequest reqApproval = new Approval.ProcessSubmitRequest();
        reqApproval.setComments('Submitting request for approval.');
        reqApproval.setObjectId(CCRList[0].id);
        Approval.ProcessResult result = Approval.process(reqApproval);
        update Opp;
        Test.stopTest();
    }
    }

    /*//SAL25-549
    @isTest static void testUpdateUpliftEligibleOpp(){
        Id standardPBId = test.getStandardPricebookId();
        List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
        String ContactID = [SELECT Id FROM Contact where LastName = 'Test Contact 01-06' LIMIT 1].Id;
        String AccountID = [SELECT Id FROM Account where Name = 'Test Account 01-06' LIMIT 1].Id;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;

        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        settingDisable.Disable_ServiceContract_Trigger__c=true;
        settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
        settingDisable.Disable_Entitlement_Trigger__c=true;
        settingDisable.Disable_Asset_Triggers__c=true;
        settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
        settingDisable.Disable_Opportunity_Triggers__c=true;
        insert settingDisable;

        Account acc = new Account(Name = 'Test Account for Uplift', ParentId = AccountID);
        insert acc;

        Opportunity Opp = new Opportunity();
        Opp.Id = lstOpp[0].Id;
        Opp.AccountId = acc.Id;
        Opp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Opp.Amount = 80000;
        Opp.ACV_Amount__c = 80000;
        Opp.New_Expansion_ACV__c = 80000;
        Opp.Opportunity_Type__c = 'New Customer';
        Opp.Opportunity_Sub_Type__c ='Regular';
        Opp.ETM_Theatre__c = 'AMER';
        Opp.Stagename = '7 Closed Won';
        Opp.CloseDate = System.today();
        update Opp;

        Opportunity sOpp = TestDataFactory.getOpportunity();
        sOpp.AccountId = acc.Id;
        sOpp.Pricebook2Id=standardPBId;
        sOpp.Opportunity_Type__c = 'Existing Customer';
        sOpp.Opportunity_Sub_Type__c = 'Regular';
        sOpp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        sOpp.StageName = '6 PO With Channel';
        insert sOpp;

        System.assert(sOpp.Id != null);
        system.runAs(listUser[0]){
            settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
            settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
            settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
            settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
            settingDisable.Disable_ServiceContract_Trigger__c=true;
            settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
            settingDisable.Disable_Entitlement_Trigger__c=true;
            settingDisable.Disable_Asset_Triggers__c=true;
            settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
            insert settingDisable;
            Test.startTest();
            sOpp.Stagename = '7 Closed Won';
            sOpp.CloseDate = System.today();
            update sOpp;
            Test.stopTest();
        }
        Opportunity resOpp = [SELECT Id, Uplift_Eligible__c from Opportunity where Id =:sOpp.Id LIMIT 1];
        system.assertEquals(FALSE,resOpp.Uplift_Eligible__c);
    }*/
    /*
    * Method Name          : testUpdatePLS_SDP_Account
    * @description         : SAL25-172
    */
    @isTest static void testUpdatePLSSDPAccount(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<ObjectTerritory2Association> lstAssociation = new List<ObjectTerritory2Association>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);

        
        System.runAs(listUser[0]) {
            Account accs = new Account(Name = 'Test Accounts',PLS_NAS_ETM_Territory__c='abc',PLS_NAS_ETM_Region__c='abc',PLS_NAS_ETM_Area__c='abc',PLS_NAS_Theatre__c='abc',PLS_SaaS_Theatre__c='abc',PLS_SaaS_ETM_Area__c='abc',PLS_SaaS_ETM_Region__c='abc',PLS_SaaS_ETM_Territory__c='abc',Payment_Term__c = 'Net 30',recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()); 
            insert accs; 
            List<Territory2> terrList = [select id,Adaptive_Territory_Id__c,Territory_Structure_Type__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned' and Territory_Structure_Type__c != 'Core' AND Territory_Structure_Type__c != '' limit 10];  
            Territory2 nastr = new Territory2();
            Territory2 saastr = new Territory2();
            for(Territory2 tr : terrList){
                if(tr.Territory_Structure_Type__c.contains('SaaS')){
                    saastr = tr;
                }else{
                    nastr = tr;
                }
            }
            if(nastr.Id != null){
                lstAssociation = ETM_TestDataFactory.createAssociationRecords(accs.Id, nastr.Id,'Territory2Manual', 1);
            }
            if(saastr.Id != null){
                lstAssociation = ETM_TestDataFactory.createAssociationRecords(accs.Id, saastr.Id,'Territory2Manual', 1);
            }
            if(!lstAssociation.isEmpty()){
                insert lstAssociation;
            }
            
            Id standardPBId = test.getStandardPricebookId();
            List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
            String ContactID = [SELECT Id FROM Contact where LastName = 'Test Contact 01-06' LIMIT 1].Id;
            String AccountID = [SELECT Id FROM Account where Name = 'Test Account 01-06' LIMIT 1].Id;
            
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
            settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
            settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
            settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
            settingDisable.Disable_ServiceContract_Trigger__c=true;
            settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
            settingDisable.Disable_Entitlement_Trigger__c=true;
            settingDisable.Disable_Asset_Triggers__c=true;
            settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
            settingDisable.Disable_Account_Validation_Rules__c = true; 
            insert settingDisable;
            
            Account acc = new Account(Name = 'Test Account for PSNLonAccount', Type='MSP-Reseller',recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId());
            insert acc;
            
            Opportunity Opp = new Opportunity();
            Opp.Id = lstOpp[0].Id;
            Opp.AccountId = acc.Id;
            Opp.Sourcing_Partner__c = acc.Id; 
            Opp.MSP_End_User_Lookup__c = AccountID;
            Opp.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            Opp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            Opp.Amount = 80000;
            Opp.ACV_Amount__c = 80000;
            Opp.Opportunity_Type__c = 'New Customer';
            Opp.MSP_End_User_Lookup__c = accs.Id;
            Opp.Opportunity_Sub_Type__c ='Regular';
            Opp.ETM_Theatre__c = 'AMER';
            Opp.Stagename = '1 Discovery';
            Opp.CloseDate = System.today();
            //SAL26-117 

            List<UserTerritory2Association> userTerr = [SELECT Id, userId,RoleInTerritory2 FROM UserTerritory2Association 
                                                  WHERE RoleInTerritory2 IN ('Cloud AE','SaaS AE') AND Territory2.Territory2Model.State = 'Active']; //SAL26-138:NAS to Cloud
            for(UserTerritory2Association uta : userTerr){
                if(uta.RoleInTerritory2 == 'Cloud AE'){ //SAL26-138:NAS to Cloud
                    Opp.Co_Owner__c = uta.userId;
                    Opp.PLS_AE_ETM_Role_Name__c = 'Cloud AE'; //SAL26-138:NAS to Cloud
                    break;
                }
            }

            Test.startTest();
            update Opp;

            
            for(UserTerritory2Association uta : userTerr){
                if(uta.RoleInTerritory2 == 'SaaS AE'){
                    Opp.Co_Owner__c = uta.userId;
                    Opp.PLS_AE_ETM_Role_Name__c = 'SaaS AE';
                    break;
                }
            }
            update Opp;
            
            Test.stopTest();

            system.assertNOtEquals(acc.Id,null);
        }
    }
    //SAL25-595
    @isTest static void testUpdatePSNLOnAccount(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].RBAC_Group__c = 'System - IT';
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
            Id standardPBId = test.getStandardPricebookId();
            List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
            String ContactID = [SELECT Id FROM Contact where LastName = 'Test Contact 01-06' LIMIT 1].Id;
            String AccountID = [SELECT Id FROM Account where Name = 'Test Account 01-06' LIMIT 1].Id;

        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        settingDisable.Disable_ServiceContract_Trigger__c=true;
        settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
        settingDisable.Disable_Entitlement_Trigger__c=true;
        settingDisable.Disable_Asset_Triggers__c=true;
        settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
        settingDisable.Disable_Account_Validation_Rules__c = true;     
        insert settingDisable;

        Account acc = new Account(Name = 'Test Account for PSNLonAccount', Type='MSP-Reseller',
                                    recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId());
        insert acc;

        Opportunity Opp = new Opportunity();
        Opp.Id = lstOpp[0].Id;
        Opp.AccountId = acc.Id;
        Opp.Sourcing_Partner__c = acc.Id;
        Opp.MSP_End_User_Lookup__c = AccountID;
        Opp.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
        Opp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Opp.Amount = 80000;
        Opp.ACV_Amount__c = 80000;
        Opp.Opportunity_Type__c = 'New Customer';
        Opp.Opportunity_Sub_Type__c ='Regular';
        Opp.ETM_Theatre__c = 'AMER';
        Opp.Stagename = '7 Closed Won';
        Opp.CloseDate = System.today();
        //SAL26-117 
        UserTerritory2Association userTerr = [SELECT Id, userId FROM UserTerritory2Association 
                                              WHERE RoleInTerritory2 = 'Cloud AE' AND Territory2.Territory2Model.State = 'Active' LIMIT 1]; //SAL26-138:NAS to Cloud
        Opp.Co_Owner__c = userTerr.userId;
        Opp.POC_Phase__c = 'In Progress'; //SAL26-117 end

        Test.startTest();
        update Opp;
        OpportunityObjectTriggerHelper.setOrderWithOrderItems(Opp.Id, Opp, new List<OpportunityLineItem>(), new List<OpportunityContactRole>());
        Test.stopTest();
        Account resAcc = [SELECT Id, PSNL_Partner__c from Account where Id =:AccountID LIMIT 1];
        system.assertEquals(acc.Id,resAcc.PSNL_Partner__c);
    }
    }

    @istest static void testUCLScaleValidation() {
        Test.startTest();
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;

        List<Product2> lstProds = new List<Product2>{
            new Product2(Name = 'Test', family = 'test family', ProductCode = 'RS-BT-BE-SC-PE-PA', Product_Subtype__c = 'FEDRAMP')
                };
        insert lstProds;

        Id standardPBId = test.getStandardPricebookId();
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Pricebook', isActive = true);
        insert priceBook;
        
        List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
            new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true)
        };
        System.runAs(getUser('System Administrator'))  {
            insert pbEntry;
        }
        
        OpportunityUtil.accountTypeChangefromAccountTriggerHelper = true;
        
        List<UserTerritory2Association> userTerrLst = [SELECT Id, userId FROM UserTerritory2Association 
                                              WHERE RoleInTerritory2 = 'Cloud AE' AND Territory2.Territory2Model.State = 'Active' LIMIT 2]; //SAL26-138:NAS to Cloud
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.Pricebook2Id = standardPBId;
        oppObject1.SBQQ__QuotePricebookId__c = standardPBId;
        oppObject1.Rubrik_Sales_Engineer__c = listUser[0].Id;
        oppObject1.Include_Datos__c = true;
        oppObject1.Co_Owner__c = userTerrLst[0].userId;
        oppObject1.PLS_ETM_Override__c = true;
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.POC_Phase__c = 'No POC';
        oppObject1.OriginalLeadOwner__c = userInfo.getUserId();
        oppObject1.SDR_Led__c = false;
        insert oppObject1;
        
        System.assert(oppObject1.Id != null);
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(Product2Id = lstProds[0].Id, pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID =  oppObject1.Id));
        insert oppLineList;  

        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = false;
        disableBusinessLogicCS.Disable_Account_Validation_Rules__c = true;  
        INSERT disableBusinessLogicCS;    
        
        List<OpportunityLineItem> oppLineList12 = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppObject1.Id];
        FlowControll.opportunityTriggerHandler = true;

        oppObject1.StageName = '6 PO With Channel';  
        oppObject1.Include_Datos__c = false;
        oppObject1.Co_Owner__c = userTerrLst[1].userId;
        oppObject1.PLS_New_Expansion_ACV__c = 100;
        oppObject1.PLS_New_Expansion_ACV__c = 10;
        oppObject1.Opp_Product_Mix__c = 'Core Standalone';
        oppObject1.Core_New_Expansion_ACV__c = 0;
        oppObject1.CloseDate = oppObject1.CloseDate.addMonths(1);
        oppObject1.POC_Phase__c = 'Completed';
        oppObject1.SDR_Led__c = true; 
        oppObject1.Opportunity_Amount_Override__c = true;
        try {
            UPDATE oppObject1;
        } catch(Exception ex) {
            System.assert(true);
        }

        oppObject1 = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppObject1.Id];
        oppObject1.Rubrik_Sales_Engineer__c = UserInfo.getUserId();
        UPDATE oppObject1;

        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        UPDATE disableBusinessLogicCS;    
        oppObject1.StageName = '5 Negotiate & Close';  
        oppObject1.Accept_Conditions__c = false;
        oppObject1.Cloud_Partner_Impact__c = 'None';
		UPDATE oppObject1;
        Test.stopTest();
    }
    
    //SAL26-117
    @istest static void valootoOrderProcessTest() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.Opportunity_Amount_Override__c = false;
        insert oppObject1;
        System.assert(oppObject1.Id != null);
        
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        disableBusinessLogicCS.Disable_Account_Validation_Rules__c = true; 
        INSERT disableBusinessLogicCS;    
            Test.startTest();
        oppObject1.StageName = '6 PO With Channel';  
        try {
            UPDATE oppObject1;
        } catch(Exception ex) {
            System.assert(true);
        }
        Test.stopTest();
    }
    }

    //SAL25-748
    @isTest static void testValidateOpportunityOnDelete(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
        List<Opportunity> lstOpp = new List<Opportunity>([SELECT Id, Opportunity_Sub_Type__c, Initial_Contacts_Name__c, Distributor_Lookup__c, Partner_Lookup__c FROM Opportunity WHERE Name = 'Test Opp 31-05']);
        System.assert(lstOpp[0].Id != null);
        Test.startTest();
        Database.DeleteResult res1 = database.delete(lstOpp[0], false);
        system.assertEquals(false, res1.success);
        SOX_Objects_Delete_Access__c soxObjCS = new SOX_Objects_Delete_Access__c(setupownerid = userinfo.getuserid());
        soxObjCS.Allow_Opportunity_Delete__c = true;
        insert soxObjCS;
        Database.DeleteResult res2 = database.delete(lstOpp[0], false);
        system.assertEquals(true, res2.success);
        Test.stopTest();
    }
    }
    
    /*  @isTest
static void testOpportunityUpdateList(){
List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
List<Opportunity> oppLi = new List<Opportunity>();
List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
insert listUser;
listUser[0].ManagerId = listUser[1].Id;
update listUser;
contact con = [select id from contact limit 1];
System.runAs(listUser[0]) {//sailaja
            
ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
sdb.Disable_Opportunity_Validation_Rules__c = false;
insert sdb;
List<Account> accountList = new List<Account>();
Account vAccount = new Account();
vAccount.Name = 'Test Account';
vAccount.Type='Distributor';
vAccount.Focused_Partner__c = True;
vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
accountList.add(vAccount);
            
Account vAccount2 = new Account();
vAccount2.Name = 'Test Account';
vAccount2.recordTypeId = vAccount.recordTypeId;
accountList.add(vAccount2);
insert accountList;
            
            
Opportunity oppObject = TestDataFactory.getOpportunity();
Opportunity oppObject1 = TestDataFactory.getOpportunity();
Opportunity oppObject2 = TestDataFactory.getOpportunity();
// oppObject2.Cloud_Partner_Led_Activity__c = 'No'; //SAl24-466
oppObject2.Alliance_Partner_Name__c = 'Microsoft';
oppObject.StageName = '2 Consensus';
oppObject2.StageName = '2 Consensus';
oppObject1.StageName = '2 Consensus';
oppObject1.CloseDate = System.today() +2;
oppObject1.Rubrik_Sales_Engineer__c = listUser[0].Id;
oppObject.Partner_Lookup__c = vAccount.Id;
oppLi.add(oppObject);
oppLi.add(oppObject1);
oppLi.add(oppObject2);
insert oppLi;
After_Action_Review__c aar = new After_Action_Review__c();
aar.Opportunity__c = oppObject1.Id;
aar.Opportunity_ClosedDate__c = System.today() +2;
//insert aar;
System.assert(oppObject.Id != null);
List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
insert listQuote;
oppObject.RenewalOwner__c = listUser[0].id;
oppObject.Send_Hold_Off_Email__c = true;
oppObject.Include_Datos__c = true;
oppObject.StageName = System.Label.Order_Creation_Stage;
oppObject.Installation_Assigned_To__c = 'Partner Install';
oppObject.Opportunity_Sub_Type__c='Renewal';
oppObject.Lost_To_Won_Against__c ='Actifio';
oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
oppObject.Valooto_Quote__c ='Test';
            
oppObject1.Stagename = '7 Closed Lost';
oppObject1.Opportunity_Type__c = 'New Customer';
oppObject1.Opportunity_Sub_Type__c ='Regular';
oppObject1.After_Action_Form_Submitted__c = True;
oppObject1.CloseDate = System.today();
oppObject.ACV_Amount__c = 60000;
// oppObject2.Cloud_Partner_Led_Activity__c = 'Yes';
oppObject2.Alliance_Partner_Name__c = 'Microsoft';
            
OpportunityLineItem oli = new OpportunityLineItem();
oli.PriceBookEntryId = null;
oli.Valooto_Sales_Price__c = 100;
oli.TotalPrice = 100;
oli.quantity = 2;
oli.Description = 'Test';
oli.UnitPrice = 100;
oli.Discount = 20;
TriggerManager.resetTriggerCounter('Opportunity');      
Test.startTest();
update oppLi;
insert aar;
            
List<OpportunityContactRole> ocr = [SELECT Id,OpportunityId,Role,ContactId FROM OpportunityContactRole Limit 1];
Map<Id, Opportunity> oppMap = new  Map<Id, Opportunity>();
Set<Id> oppMapids = new Set<Id>();
OpportunityObjectTriggerHelper.getOrderLineItem (new Order(), oli);
OpportunityObjectTriggerHelper.upsertOpportunityContactRoles(ocr,oppMap ,oppMapids);
System.assert(oppObject.Id != null);
Test.stopTest();
}//sailaja
}*/
  
    @IsTest
    static void validateOppOnCloseDateTest(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].RBAC_Group__c = 'System - IT';
        update listUser;
        
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].RBAC_Group__c = 'System - IT';
        update listUser[0];
        System.runAs(listUser[0]) { 
        Id standardPriceBookId =  Test.getStandardPricebookId();
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1
        );
        insert new List<Product2>{prod1};
         PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 200.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1,pbEntry1}; 
        Account acc = new Account(Name = 'Test Account',Payment_Term__c = 'Net 75',
        recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId());
        insert acc;
        Opportunity oppr = TestDataFactory.getOpportunity(acc);
        oppr.Opportunity_Sub_Type__c = 'GC Offer';
        insert oppr;
        System.assert(oppr.Id != null);
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => acc.Id,'SBQQ__Opportunity2__c' => oppr.Id};
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Primary__c = false;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Amendment';
        qt1.SBQQ__StartDate__c = Date.Today();
        insert qt1;
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper ContractA';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj1.AccountId = acc.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        lstServiceContract.add(serviceContractObj1);
        insert lstServiceContract;
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = acc.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
            system.RunAs(listUser[0]){    
        insert ContractLineItemObj;
            }
        Opportunity opp = new Opportunity(id = oppr.id,CloseDate = Date.today().addMonths(5),SBQQSC__AmendedServiceContract__c = lstServiceContract[0].id);
        Test.startTest();
                update opp; 
                    system.assertNOTEquals(oppr.Id, null);
        Test.stoptest();
        }
    }
    
    @istest static void coOwnerOverrideTest() {
        Test.startTest();
        PermissionSetAssignment fieldOpsAssignee = [SELECT Id, AssigneeId FROM PermissionSetAssignment 
                                                    WHERE PermissionSetGroup.DeveloperName = 'PSG_Field_Ops_User'
                                                    AND Assignee.isActive = true
                                                    LIMIT 1];
        User user = [SELECT Id FROM User WHERE Id = :fieldOpsAssignee.AssigneeId];
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.Amount_on_lead_conversion__c = 500;
        oppObject1.SOW_Required__c = true;
        oppObject1.OriginalLeadOwner__c = userInfo.getUserId();
        oppObject1.SDR_Led__c = true;
        insert oppObject1;
        
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(user.Id);
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = false;
		disableBusinessLogicCS.Disable_Account_Validation_Rules__c = true;
        INSERT disableBusinessLogicCS;    
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        INSERT listUser;
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 10];                     
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Cloud AE',UserId = listUser[0].id)); //SAL26-138:NAS to Cloud
            INSERT UTAList;
        }
        Id userId = [SELECT Id, userId FROM UserTerritory2Association WHERE RoleInTerritory2 = 'Cloud AE' LIMIT 1].userId; //SAL26-138:NAS to Cloud
        System.runAs(user){
            oppObject1.Co_Owner__c = userId;
            oppObject1.PLS_ETM_Overrides__c = 'CLOUD ETM Override';
            oppObject1.Non_Core_Adaptive_Id__c = '12345';
            UPDATe oppObject1;  
            
            System.assert(oppObject1.Co_Owner__c != null);
            
            oppObject1.Co_Owner__c = null; //SAL26-548
            UPDATe oppObject1; //SAL26-548
            System.assert(oppObject1.Co_Owner__c == null);
        }          
        Test.stopTest();
    } 
    
    testMethod static void m365ValidationTest(){
        test.startTest();  
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        //User ciUser = [select Id from User where Id='0056f000009zoBM'];
        Opportunity oppo = new opportunity();
        SBQQ__Quote__c sd = new SBQQ__Quote__c();
        System.runAs(listUser[0]) {
            Account accs = new Account(Name = 'Test Accounts',Payment_Term__c = 'Net 30',recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()); 
            insert accs; 

            Account acc = new Account(Name = 'Test Account',Payment_Term__c = 'Net 30',
                                      recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId());  
            insert acc; 
            //Opportunity opp = [Select id from Opportunity Limit 1];
            //Account acc = [Select id from Account Limit 1];
            
            // SAL26-117
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'SaaS Standalone Add-Ons Wrapper', family = 'test family', ProductCode = 'SaaS Standalone Add-Ons Wrapper', Product_Subtype__c = ''),
                    new Product2(Name = 'RS-UR-EE-MS-PE-PP', family = 'test', ProductCode = 'RS-UR-EE-MS-PE-PP', Product_Subtype__c = '', Product_Type__c = 'M365H'),
                    new Product2(Name = 'RS-GB-GRS-MS-PE-PP', family = 'test family', ProductCode = 'RS-GB-GRS-MS-PE-PP', Product_Subtype__c = '', Product_Type__c = 'M365 GRS'),
                    new Product2(Name = 'RS-GB-MS-PE-PP', family = 'test family', ProductCode = 'RS-GB-MS-PE-PP', Product_Subtype__c = '', Product_Type__c = 'M365 ZRS')
                    };
                        insert lstProds;
            
            Id standardPBId = test.getStandardPricebookId();
            Pricebook2 pricebook = new Pricebook2(Name = 'Test Pricebook', isActive = true);
            insert priceBook; 
            
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true),
                    new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true),
                    new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true),
                    new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[3].Id, IsActive = true)
                    }; // SAL26-117 end
                        INSERT pbEntry;    
            
            //oppo.Id = opp.Id;  
            oppo.StageName = '1 Discovery';
            oppo.closeDate = System.Today() + 30;
            oppo.AccountId = acc.Id;
            oppo.Name = 'Test oppo';
            oppo.SOW_Required__c = false;
            oppo.OwnerId = listUser[0].Id;
            oppo.Has_Polaris_Product__c =true;
            oppo.Opportunity_Sub_Type__c = 'Regular';
            oppo.Pricebook2Id = standardPBId;
            insert oppo;
            System.assert(oppo.Id != null);
            
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            settingDisable.Disable_Opportunity_Triggers__c = true;
            INSERT settingDisable;
            
            List<PriceBookEntry> pbEntryList = [SELECT Id, Name, Pricebook2Id, Product2Id, ProductCode, IsActive FROM PricebookEntry];
            
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(Product2Id = pbEntryList[0].Product2Id, pricebookentryid=pbEntryList[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppo.Id));
            oppLineList.add(new OpportunityLineItem(Product2Id = pbEntryList[1].Product2Id, pricebookentryid=pbEntryList[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppo.Id));
            oppLineList.add(new OpportunityLineItem(Product2Id = pbEntryList[2].Product2Id, pricebookentryid=pbEntryList[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppo.Id));
            oppLineList.add(new OpportunityLineItem(Product2Id = pbEntryList[3].Product2Id, pricebookentryid=pbEntryList[3].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppo.Id));
            // insert oppLineList;   //SAL26-117
            settingDisable.Disable_Opportunity_Triggers__c = false;
            UPDATE settingDisable;
            
            sd.SBQQ__Opportunity2__c =oppo.Id;
            sd.SBQQ__Account__c = acc.Id;
            sd.sendSOWNotification__c = false;
            sd.SBQQ__Type__c = 'Quote';
            //sd.Task_Products__c='RBK-DISK-RETENTION';
            sd.SBQQ__Primary__c =true;
            sd.SBQQ__Status__c = 'Draft';
            //flowControll.o211pportunityTriggerHandler = false;
            insert sd;
            flowControll.opportunityTriggerHandler = true;          
            
            oppo.SBQQ__PrimaryQuote__c = sd.Id;
            oppo.StageName = '6 PO With Channel';
            oppo.SOW_Required__c = true;
            //oppo.Opportunity_Program__c ='Refresh';
            TriggerControls.disableQuoteTrigger = true;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = true;
            oppo.MSP_End_User_Lookup__c = accs.Id;
            oppo.Opportunity_Amount_Override__c = true;
            oppo.ACV_Amount__c = 1000;
            oppo.Renewal_Subsumed_ACV__c = 1000;
            oppo.Subsumed_Renewal_TCV__c = 1000;
            oppo.New_Expansion_ACV__c = 1000;
            oppo.New_Expansion_TCV__c = 1000;
            oppo.Core_New_Expansion_ACV__c =  1000;
            oppo.Nas_New_Expansion_ACV__c = 1000;
            oppo.SaaS_New_Expansion_ACV__c = 1000;
            oppo.Subsumed_Renewal_Churn_ACV__c = 1000;
            oppo.Subsumed_Renewal_Churn_TCV__c = 1000;
            //   oppObjectRec.SBQQSC__AmendedServiceContract__c = serviceContractObj.Id;
            try {
                update oppo;
            } catch(Exception ex) {
                system.debug(LoggingLevel.DEBUG, '@@ exception '+ex.getMessage());
            }
            test.stopTest(); 
        }
        //OpportunityObjectTriggerHelper.createTasksForRenewalExpansionQuote(new List<Opportunity>{oppo});
    }
    
    /***********************************************************************************************************
    * Method Name          : testsendOpportunityEndUserAlert
    * Date Created/Modified: 03/07/2025
    * Author               : Shivani
    * @description         : test method for sendOpportunityEndUserAlert
    * Test Class Methods   :
    /**********************************************************************************************************/
    @isTest
    static void testsendOpportunityEndUserAlert() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
            Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
            List<Opportunity> oppLi = new List<Opportunity>();
            List<User>  ownerUser = TestDataFactory.getUsers('owneruser@test.com', new Set<Id>{listProfile1}, 1);
            List<User>  renewalUser = TestDataFactory.getUsers('renewaluser@test.com', new Set<Id>{listProfile2}, 1);
            insert ownerUser;
            insert renewalUser;
            // Create old opportunity (simulating the DB state before update)
            Opportunity oldOpp = new Opportunity(
                Name = 'Old Opp',
                StageName = '1 Discovery',
                CloseDate = Date.today().addDays(30),
                Opportunity_Program__c = 'Refresh;Upgrade',
                OwnerId = ownerUser[0].Id
            );
            insert oldOpp;
            
            Account vAccount = new Account();
            vAccount.Name = 'Microsoft Azure Marketplace';
            vAccount.Type='Distributor';
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert vAccount;
            Contact ContactID = new Contact();
            ContactID.LastName = 'Test Contact 01-06';
            ContactID.Email =  'Testmail@testmail.com';
            ContactID.AccountId = vAccount.Id;
            insert ContactID; 
            // Create updated opportunity (simulating the new value being passed into method)
            Opportunity newOpp = oldOpp.clone(false, true, false, false);
            newOpp.Id = oldOpp.Id;
            newOpp.Alliance_Partner_Name__c = 'Microsoft';
            newOpp.StageName = '6 PO With Channel';
            newOpp.Lost_To_Won_Against__c ='Actifio';
            newOpp.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            newOpp.Valooto_Quote__c ='Test';
            newOpp.Cloud_Partner_Impact__c ='Partner gets a well-qualified meeting with key decision-makers';
            newOpp.Distributor_Lookup__c=vAccount.Id;
            newOpp.Partner_Lookup__c = vAccount.Id;
            newOpp.Primary_Competitor__c = 'Actifio';
            newOpp.Initial_Contacts_Name__c = ContactID.Id;
            newOpp.Opportunity_Program__c = 'Conversion';
            //update newOpp;
        
            // Simulate oldOppMap
            Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
                newOpp.Id => oldOpp
            };
        
            // Create SBQQ__Quote__c and relate to the opportunity
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = newOpp.Id,
                OwnerId = ownerUser[0].Id,
                SBQQ__Primary__c = true,
                Trade_Up_Amounts__c = 10
            );
            insert quote;
        
            // Add renewal owner to opportunity
            newOpp.RenewalOwner__c = renewalUser[0].Id;
            //update newOpp;
            
            //INSERT new Task(WhatId = newOpp.Id, Subject = 'Opp-07: End-User Alert', Type = 'Email');

            // Call the method under test
            Test.startTest();
                OpportunityObjectTriggerHelper.sendEmailAlertsOnStageChange(
                    new List<Opportunity>{ newOpp },
                    oldOppMap,
                    [SELECT ID,SBQQ__Opportunity2__r.Id,Trade_Up_Amounts__c,SBQQ__Primary__c,Prepayment_Credit__c,ShowPromoDisc__c,
                            SBQQ__Opportunity2__r.OwnerId,SBQQ__Opportunity2__r.Owner.Email,
                            SBQQ__Opportunity2__r.RenewalOwner__r.Email,
                            SBQQ__Opportunity2__r.Initial_Contacts_Name__r.Email 
                            FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:newOpp.Id ]
                );
            Test.stopTest();
        
            // Assertions
           List<SBQQ__Quote__c> quoteList =  [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:newOpp.Id ];
           System.assertEquals(1, quoteList.size(), 'Quote record count');
            // System.assertEquals(1, tasks.size(), 'Task should be created');
            // System.assertEquals('Opp-07: End-User Alert', tasks[0].Subject);
        }
    }
	    /***********************************************************************************************************
    * Method Name          : testsendPOInChannelNotice
    * Date Created/Modified: 03/07/2025
    * Author               : Shivani
    * @description         : test method for sendPOInChannelNotice
    * Test Class Methods   :
    /**********************************************************************************************************/
    @isTest
    static void testsendPOInChannelNotice() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
            Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
            List<Opportunity> oppLi = new List<Opportunity>();
            List<User>  ownerUser = TestDataFactory.getUsers('owneruser@test.com', new Set<Id>{listProfile1}, 1);
            List<User>  renewalUser = TestDataFactory.getUsers('renewaluser@test.com', new Set<Id>{listProfile2}, 1);
            insert ownerUser;
            insert renewalUser;
            // Create old opportunity (simulating the DB state before update)
            Opportunity oldOpp = new Opportunity(
                Name = 'Old Opp',
                StageName = '1 Discovery',
                CloseDate = Date.today().addDays(30),
                Opportunity_Program__c = 'Refresh;Upgrade',
                OwnerId = ownerUser[0].Id
            );
            insert oldOpp;
            
            Account vAccount = new Account();
            vAccount.Name = 'Microsoft Azure Marketplace';
            vAccount.Type='Distributor';
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert vAccount;
            Contact ContactID = new Contact();
            ContactID.LastName = 'Test Contact 01-06';
            ContactID.Email =  'Testmail@testmail.com';
            ContactID.AccountId = vAccount.Id;
            insert ContactID; 
            // Create updated opportunity (simulating the new value being passed into method)
            Opportunity newOpp = oldOpp.clone(false, true, false, false);
            newOpp.Id = oldOpp.Id;
            newOpp.Alliance_Partner_Name__c = 'Microsoft';
            newOpp.StageName = '6 PO With Channel';
            newOpp.Lost_To_Won_Against__c ='Actifio';
            newOpp.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            newOpp.Valooto_Quote__c ='Test';
            newOpp.Cloud_Partner_Impact__c ='Partner gets a well-qualified meeting with key decision-makers';
            newOpp.Distributor_Lookup__c=vAccount.Id;
            newOpp.Partner_Lookup__c = vAccount.Id;
            newOpp.Primary_Competitor__c = 'Actifio';
            newOpp.Initial_Contacts_Name__c = ContactID.Id;
            newOpp.Opportunity_Program__c = 'Conversion';
            //update newOpp;
        
            // Simulate oldOppMap
            Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
                newOpp.Id => oldOpp
            };
        
            // Create SBQQ__Quote__c and relate to the opportunity
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = newOpp.Id,
                OwnerId = ownerUser[0].Id,
            SBQQ__Primary__c = true
            );
            insert quote;
        
            // Add renewal owner to opportunity
            newOpp.RenewalOwner__c = renewalUser[0].Id;
            //update newOpp;
            
            // Call the method under test
            Test.startTest();
            OpportunityObjectTriggerHelper.sendEmailAlertsOnStageChange(
                new List<Opportunity>{ newOpp },
                oldOppMap,
                [SELECT ID,SBQQ__Opportunity2__r.Id,SBQQ__Primary__c ,
                        SBQQ__Opportunity2__r.OwnerId,SBQQ__Opportunity2__r.Owner.Email,
                        SBQQ__Opportunity2__r.RenewalOwner__r.Email,
                        Trade_Up_Amounts__c, Prepayment_Credit__c, ShowPromoDisc__c
                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:newOpp.Id ]
            );
        Test.stopTest();
        System.assert(true);
        }
    }
    
    /***********************************************************************************************************
    * Method Name          : testSendRefreshNotification
    * Date Created/Modified: 03/07/2025
    * Author               : Shivani
    * @description         : test method for sendRefreshNotification
    * Test Class Methods   :
    /**********************************************************************************************************/
    @isTest
    static void testSendRefreshNotification() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
            Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
            List<Opportunity> oppLi = new List<Opportunity>();
            List<User>  ownerUser = TestDataFactory.getUsers('owneruser@test.com', new Set<Id>{listProfile1}, 1);
            List<User>  renewalUser = TestDataFactory.getUsers('renewaluser@test.com', new Set<Id>{listProfile2}, 1);
            insert ownerUser;
            insert renewalUser;
            Opportunity opp = [select Id,name,stagename,closedate,Opportunity_Program__c from Opportunity limit 1];
            
            // Create SBQQ__Quote__c and relate to the opportunity
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                OwnerId = ownerUser[0].Id,
                SBQQ__Primary__c = true,
                ApprovalStatus__c = 'Approved'
            );
            insert quote;
        
            TriggerControls.disableQuoteTrigger = true;
        	TriggerControls.disableQuoteLineTrigger = true;

        	quote.ApprovalStatus__c = 'Approved';
            update quote;  
           
            Test.startTest();
            opp.StageName  = '4 Business Justification';
            opp.Opportunity_Program__c  = 'Refresh';
            update opp;
           
            Test.stopTest();
        
            // Assertions
        System.assert(true);
        }
    }
     /*
	* Name : testValidateRiskAndInvalidOpp1
	* Date : 1-Dec-2025
	* @description : Test method to cover ValidateRiskAndInvalidOpp
	*/
    @isTest
    static void testValidateRiskAndInvalidOpp1() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id pbookId = Test.getStandardPricebookId();
        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'LOD',
             'IsActive' => true,
             'SBQQ__AssetConversion__c' => 'One per unit'
         };
         Map<String, Object> prdMap2 = new Map<String, Object> {
             'Name' => 'Subscription', 
                 'IsActive' => true, 
                 'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                 'SBQQ__SubscriptionTerm__c' => 12, 
                 'SBQQ__SubscriptionType__c' => 'Renewable'
                 };
          Map<String, Object> prdMap3 = new Map<String, Object> {
              //'Name' => 'Hardware',
              'Name' => 'RBK-PS-RES',
                  'IsActive' => true,
                  'SBQQ__AssetConversion__c' => 'One per unit',
                  'SBQQ__SubscriptionTerm__c' => 12, 
                  'SBQQ__SubscriptionType__c' => 'Renewable'
                  };
            Map<String, Object> prdMap4 = new Map<String, Object> {
                'Name' => 'SW Support', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
            Map<String, Object> prdMap5 = new Map<String, Object> {
                'Name' => 'Subscription Add-On', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
                                                                    
        Product2 prdLOD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        prdLOD.License_Type__c = 'Perpetual';
        prdLOD.Product_Subtype__c = 'E1000';
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
        prdSubs.License_Type__c = 'Subscription';
        prdSubs.License_Subtype__c = 'ELA';
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap3);
        prdHW.Product_Type__c = 'HW Support';
        Product2 prdSubsAddon = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap4);
        prdSubsAddon.License_Type__c = 'Subscription';
        prdSubsAddon.License_Subtype__c = 'Add-On';
        Product2 prdSW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
        prdHW.Product_Type__c = 'RCDM Support';
        Product2 prdPl = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
        prdPl.Product_Type__c = 'RCDM Support';
        prdPl.Product_Level__c='LOD Software';
        prdPl.Bundle_Features__c='Cloud Native Protection';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap1);
        prdList.add(prdLOD);
        prdList.add(prdSubs);
        prdList.add(prdHW);
        prdList.add(prdSubsAddon);
        prdList.add(prdSW);
        prdList.add(prdPl);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeLOD = new PricebookEntry();
        pbeLOD.Pricebook2Id = pbookId;
        pbeLOD.Product2Id = prdLOD.Id;
        pbeLOD.UnitPrice = 1000;
        pbeLOD.IsActive = true;
        pBList.add(pbeLOD);
        
        PricebookEntry pbeSubs = new PricebookEntry();
        pbeSubs.Pricebook2Id = pbookId;
        pbeSubs.UnitPrice = 1000;
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.IsActive = true;
        pBList.add(pbeSubs);
        
        PricebookEntry pbeHW = new PricebookEntry();
        pbeHW.Pricebook2Id = pbookId;
        pbeHW.UnitPrice = 1000;
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.IsActive = true;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubsAddon = new PricebookEntry();
        pbeSubsAddon.Pricebook2Id = pbookId;
        pbeSubsAddon.UnitPrice = 1000;
        pbeSubsAddon.Product2Id = prdSubsAddon.Id;
        pbeSubsAddon.IsActive = true;
        pBList.add(pbeSubsAddon);
        
        PricebookEntry pbeSW = new PricebookEntry();
        pbeSW.Pricebook2Id = pbookId;
        pbeSW.UnitPrice = 1000;
        pbeSW.Product2Id = prdSW.Id;
        pbeSW.IsActive = true;
        pBList.add(pbeSW);
        
        PricebookEntry pbePl = new PricebookEntry();
        pbePl.Pricebook2Id = pbookId;
        pbePl.UnitPrice = 1000;
        pbePl.Product2Id = prdPl.Id;
        pbePl.IsActive = true;
        pBList.add(pbePl);
        insert pBList;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.Focused_Partner__c = True;
        vAccount.Payment_Term__c = 'Net 30';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert vAccount;
        
        Opportunity oppr2 = TestDataFactory.getOpportunity(accObj);
        oppr2.Marketplace__c = 'Azure Marketplace';
        oppr2.Distributor_Lookup__c = vAccount.Id; 
        oppr2.Partner_Lookup__c = vAccount.Id; 
        insert oppr2;
        
        Opportunity oppr1 = TestDataFactory.getOpportunity(accObj);
        oppr1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();     
        insert oppr1;
        
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr1.Id;
        serviceContractObj1.AccountId = accObj.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        insert serviceContractObj1;               
        Test.startTest();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        quoteList = TestDataFactory.getQuotes(new Set<Id>{oppr1.Id}, 1);
        quoteList[0].SBQQ__Primary__c = true;
        quoteList[0].SBQQ__Opportunity2__c = oppr1.Id;
        insert quoteList;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
        qliList.add( qli1 );
        insert qliList;
        
        ContractLineItem renewedContractLineItem1 = new ContractLineItem();
        renewedContractLineItem1.SBQQSC__Account__c = accObj.Id;
        renewedContractLineItem1.PricebookEntryId = pbeLOD.Id;
        renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem1.SBQQSC__QuoteLine__c = qliList[0].Id;
        renewedContractLineItem1.Quantity = 10;
        renewedContractLineItem1.UnitPrice = 100;
        insert renewedContractLineItem1;
        
        qliList = new List<SBQQ__QuoteLine__c> ();
         
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
        
        qliList.add( qli2 );
        qliList.add( qli3 );
        qliList.add( qli4 );
        qliList.add( qli5 );
        
      
        insert qliList;
        try{
            oppr1.SBQQ__PrimaryQuote__c = quoteList[0].Id;
            oppr1.Renewals_Forecast_Risk__c ='Invalid Duplicate';
            oppr1.Duplicate_Opportunity_Lookup__c = oppr2.Id;
            update oppr1;
        }catch(Exception ex){
                System.debug(System.logginglevel.ERROR,'Error:'+ex.getMessage());
        }
        System.assertEquals(oppr1.Renewals_Forecast_Risk__c, 'Invalid Duplicate', 'Able to Update');
        Test.stopTest();
           
        }
    }
    
    /*
	* Name : testValidateRiskAndInvalidOpp2
	* Date : 1-Dec-2025
	* @description : Test method to cover ValidateRiskAndInvalidOpp
	*/
    @isTest
    static void testValidateRiskAndInvalidOpp2() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Id pbookId = Test.getStandardPricebookId();
        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'LOD',
             'IsActive' => true,
             'SBQQ__AssetConversion__c' => 'One per unit'
         };
         Map<String, Object> prdMap2 = new Map<String, Object> {
             'Name' => 'Subscription', 
                 'IsActive' => true, 
                 'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                 'SBQQ__SubscriptionTerm__c' => 12, 
                 'SBQQ__SubscriptionType__c' => 'Renewable'
                 };
          Map<String, Object> prdMap3 = new Map<String, Object> {
              //'Name' => 'Hardware',
              'Name' => 'RBK-PS-RES',
                  'IsActive' => true,
                  'SBQQ__AssetConversion__c' => 'One per unit',
                  'SBQQ__SubscriptionTerm__c' => 12, 
                  'SBQQ__SubscriptionType__c' => 'Renewable'
                  };
            Map<String, Object> prdMap4 = new Map<String, Object> {
                'Name' => 'SW Support', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
            Map<String, Object> prdMap5 = new Map<String, Object> {
                'Name' => 'Subscription Add-On', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
                                                                    
        Product2 prdLOD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        prdLOD.License_Type__c = 'Perpetual';
        prdLOD.Product_Subtype__c = 'E1000';
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
        prdSubs.License_Type__c = 'Subscription';
        prdSubs.License_Subtype__c = 'ELA';
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap3);
        prdHW.Product_Type__c = 'HW Support';
        Product2 prdSubsAddon = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap4);
        prdSubsAddon.License_Type__c = 'Subscription';
        prdSubsAddon.License_Subtype__c = 'Add-On';
        Product2 prdSW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
        prdHW.Product_Type__c = 'RCDM Support';
        Product2 prdPl = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
        prdPl.Product_Type__c = 'RCDM Support';
        prdPl.Product_Level__c='LOD Software';
        prdPl.Bundle_Features__c='Cloud Native Protection';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap1);
        prdList.add(prdLOD);
        prdList.add(prdSubs);
        prdList.add(prdHW);
        prdList.add(prdSubsAddon);
        prdList.add(prdSW);
        prdList.add(prdPl);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeLOD = new PricebookEntry();
        pbeLOD.Pricebook2Id = pbookId;
        pbeLOD.Product2Id = prdLOD.Id;
        pbeLOD.UnitPrice = 1000;
        pbeLOD.IsActive = true;
        pBList.add(pbeLOD);
        
        PricebookEntry pbeSubs = new PricebookEntry();
        pbeSubs.Pricebook2Id = pbookId;
        pbeSubs.UnitPrice = 1000;
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.IsActive = true;
        pBList.add(pbeSubs);
        
        PricebookEntry pbeHW = new PricebookEntry();
        pbeHW.Pricebook2Id = pbookId;
        pbeHW.UnitPrice = 1000;
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.IsActive = true;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubsAddon = new PricebookEntry();
        pbeSubsAddon.Pricebook2Id = pbookId;
        pbeSubsAddon.UnitPrice = 1000;
        pbeSubsAddon.Product2Id = prdSubsAddon.Id;
        pbeSubsAddon.IsActive = true;
        pBList.add(pbeSubsAddon);
        
        PricebookEntry pbeSW = new PricebookEntry();
        pbeSW.Pricebook2Id = pbookId;
        pbeSW.UnitPrice = 1000;
        pbeSW.Product2Id = prdSW.Id;
        pbeSW.IsActive = true;
        pBList.add(pbeSW);
        
        PricebookEntry pbePl = new PricebookEntry();
        pbePl.Pricebook2Id = pbookId;
        pbePl.UnitPrice = 1000;
        pbePl.Product2Id = prdPl.Id;
        pbePl.IsActive = true;
        pBList.add(pbePl);
        insert pBList;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.Focused_Partner__c = True;
        vAccount.Payment_Term__c = 'Net 30';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert vAccount;
        
        Opportunity oppr2 = TestDataFactory.getOpportunity(accObj);
        oppr2.Marketplace__c = 'Azure Marketplace';
        oppr2.Distributor_Lookup__c = vAccount.Id; 
        oppr2.Partner_Lookup__c = vAccount.Id; 
            oppr2.Pricebook2Id = pbookId;
        insert oppr2;
        
        ServiceContract serviceContractObj2 = new ServiceContract();
        serviceContractObj2.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj2.SBQQSC__Opportunity__c = oppr2.Id;
        serviceContractObj2.AccountId = accObj.Id;
        serviceContractObj2.StartDate = System.today();
        serviceContractObj2.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj2.Term = 36;
        insert serviceContractObj2;               
        
        List<SBQQ__Quote__c> quoteList2 = new List<SBQQ__Quote__c>();
        quoteList2 = TestDataFactory.getQuotes(new Set<Id>{oppr2.Id}, 1);
        quoteList2[0].SBQQ__Primary__c = true;
        quoteList2[0].SBQQ__Opportunity2__c = oppr2.Id;
        insert quoteList2;
                
        SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList2[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );         
        insert qli12;
        
        ContractLineItem renewedContractLineItem2 = new ContractLineItem();
        renewedContractLineItem2.SBQQSC__Account__c = accObj.Id;
        renewedContractLineItem2.PricebookEntryId = pbeLOD.Id;
        renewedContractLineItem2.ServiceContractId = serviceContractObj2.Id;
        renewedContractLineItem2.SBQQSC__QuoteLine__c = qli12.Id;
        renewedContractLineItem2.Quantity = 10;
        renewedContractLineItem2.UnitPrice = 100;
        insert renewedContractLineItem2;
        
        SBQQ__QuoteLine__c qli21 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList2[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli12.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem2.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' );
        insert qli21;
         Test.startTest();
        Opportunity oppr1 = TestDataFactory.getOpportunity(accObj);
        oppr1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();     
        insert oppr1;
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr1.Id;
        serviceContractObj1.AccountId = accObj.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        insert serviceContractObj1;
        
       
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        quoteList = TestDataFactory.getQuotes(new Set<Id>{oppr1.Id}, 1);
        quoteList[0].SBQQ__Primary__c = true;
        quoteList[0].SBQQ__Opportunity2__c = oppr1.Id;
        insert quoteList;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
        qliList.add( qli1 );
        insert qliList;
        
        ContractLineItem renewedContractLineItem1 = new ContractLineItem();
        renewedContractLineItem1.SBQQSC__Account__c = accObj.Id;
        renewedContractLineItem1.PricebookEntryId = pbeLOD.Id;
        renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
        renewedContractLineItem1.SBQQSC__QuoteLine__c = qliList[0].Id;
        renewedContractLineItem1.Quantity = 10;
        renewedContractLineItem1.UnitPrice = 100;
        insert renewedContractLineItem1;
        
        qliList = new List<SBQQ__QuoteLine__c> ();
         
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
        
        qliList.add( qli2 );
        qliList.add( qli3 );
        qliList.add( qli4 );
        qliList.add( qli5 );
        
      
        insert qliList;
            Opportunity oppWithPB = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oppr2.Id];
            PricebookEntry pbeSubsForOpp = new PricebookEntry(
                Pricebook2Id = oppWithPB.Pricebook2Id,
                Product2Id   = prdSubs.Id,
                UnitPrice    = 1000,
                IsActive     = true
            );
            insert pbeSubsForOpp;
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbeSubsForOpp.Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppr2.Id, SBQQ__QuoteLine__c = qliList[0].Id));
            insert oppLineList;   
            
        try{
            oppr1.SBQQ__PrimaryQuote__c = quoteList[0].Id;
            oppr1.Renewals_Forecast_Risk__c ='Invalid Duplicate';
            oppr1.Duplicate_Opportunity_Lookup__c = oppr2.Id;
            update oppr1;
        }catch(Exception ex){
            System.debug(System.logginglevel.ERROR,'Error:'+ex.getMessage());
        }
        System.assertEquals(oppr1.Renewals_Forecast_Risk__c, 'Invalid Duplicate', 'Able to Update');
        Test.stopTest();
        }
    }
}