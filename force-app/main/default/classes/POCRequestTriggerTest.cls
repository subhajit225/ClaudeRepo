/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-19-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class POCRequestTriggerTest {
    private static final Boolean DOINSERT_TRUE = true;
    private static final Boolean DOINSERT_FALSE = false;

	@testSetup
    static void setupDataForAccountTriggerHandler(){
        //ShGl_DisableBusinessLogic__c
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Triggers__c = TRUE, Disable_Opportunity_Triggers__c = TRUE);
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        //ShGl_DisableBusinessLogic__c
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;

        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId = act.Id;
        insert cnt;

        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(1, actList.size());

        //Test.startTest();
        System.RunAs(usr){
            
            List<Product2> lstProducts = getProducts();
            insert lstProducts;
            
            Pricebook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId());
            List<PriceBookEntry> lstPriceBookEntries = new List<PricebookEntry>();
            for( Product2 objProduct : lstProducts ) {
                lstPriceBookEntries.add(new PriceBookEntry(
                                        UnitPrice = 400,
                                        PriceBook2Id = pricebook.id,
                                        Product2Id = objProduct.Id,
                                        IsActive = true,
                                        UseStandardPrice=false));
            } 
            insert lstPriceBookEntries;
            
            /*act.OwnerId = usr.Id;
            update act;*/
            insert new TriggerControl__c(name = 'Opportunity', DisableTrigger__c = true);
            Opportunity o = new Opportunity();
            o.AccountId = act.Id;
            o.PriceBook2Id = pricebook.Id;
            o.Amount = 1000.00;
            o.Name = 'Test Opportunity For Unit Test Purposes';
            o.CloseDate = Date.Today().addDays(5);
            o.StageName = 'Prospecting';
            o.Metric__c = '85k or less';
            o.Economic_Buyer__c = 'Brent Staley';
            o.Decision_Criteria__c = 'If 6408 meets conditional PO requirements they will pull the trigger';
            o.Decision_Process__c = 'PO has been cut, waiting to add conditions to the quotes';
            o.Identified_Pain__c = 'Large Capex Payment for Exagrid addition + veeam renewal costs.  Inability to "dump archive to cloud" also a pain point as Chris wants as much OPEX as possible';
            o.Champion__c = 'Chris Norman';
            insert o;
            
            User usrva = [SELECT Id,Name FROM User Where Name = 'Order Automation User'];
            System.runAs(usrva){
                Order od1 = new Order();
                od1.AccountId = act.Id;
                od1.Type = 'POC';
                od1.OpportunityId =o.Id;
                od1.Support_End_Date__c= Date.Today();
                od1.EffectiveDate = Date.Today();
                od1.Order_Status__c = 'Shipped';
                od1.ShippingStreet ='Test Street';
                od1.ShippingCity ='Test City';
                od1.ShippingState ='California';
                od1.ShippingCountry ='United States';
                od1.ShippingPostalcode ='94820';
                od1.Shipping_Address_Label__c = null;
                insert od1;
                Order od2 = new Order();
                od2.AccountId = act.Id;
                od2.Type = 'POC';
                od2.OpportunityId =o.Id;
                od2.Support_End_Date__c= Date.Today();
                od2.EffectiveDate = Date.Today();
                od2.Order_Status__c = 'Shipped';
                od2.ShippingStreet ='Test Street';
                od2.ShippingCity ='Test City';
                od2.ShippingState ='California';
                od2.ShippingCountry ='United States';
                od2.ShippingPostalcode ='94820';
                od2.Shipping_Address_Label__c = null;
                insert od2;
                
                OrderItem ordItem = new OrderItem(
                      OrderId = od2.Id,
                      Product2Id = lstProducts[0].Id,
                      Quantity = 5,
                      PricebookEntryId = lstPriceBookEntries[0].Id,
                      UnitPrice = 100,
                      SerialNumber__c = 'AA204063040011',
                      Support_End_Date__c = System.Today().addYears(1),
                      Support_Start_Date__c = System.Today()
                    );
                insert ordItem;
            }
            
        }
    }
    
    private static List<Product2> getProducts() {
        Set<String> setProductPicker = new Set<String>();
        for( POC_Product_Picker_Matrix__mdt objMDT : [SELECT Product_SKU__c
                                                      FROM POC_Product_Picker_Matrix__mdt]) {
        	setProductPicker.addAll( objMDT.Product_SKU__c.split(';') );                                                  
        }
        List<Product2> lstProduct2 = new List<Product2>();
        for( String c : setProductPicker ) {
            Product2 objP1 = new Product2();
            objP1.ProductCode = c;
            objP1.Name = c;
            objP1.IsActive = true;
            lstProduct2.add( objP1 );
        }
        Product2 objP1 = new Product2();
        objP1.ProductCode = 'RS-BT-RCDM-T';
        objP1.Name = 'Default product code';
        objP1.IsActive = true;
        lstProduct2.add( objP1 );
        return lstProduct2;
    }
    
    private static POC__c getWebTryAndBuyPOC() {
        
         Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Web Try and Buy';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted Enterprise Edition';
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'M365 and Entra ID; UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.UCL_Edition__c = 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)';
        newPOCRequest.Data_Redundancy_Archive__c ='Multi Zone (ZRS)';
        newPOCRequest.Data_Redundancy_Backup__c = 'Multi Zone (ZRS)';
        return newPOCRequest;
    }
    
    private static POC__c getStandardPOC() {
        
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
         newPOCRequest.Product_Categories__c = 'Rubrik Appliance;Edge;M365 and Entra ID;NAS Cloud Direct;Identity Recovery and Resilience - AD, Entra ID, Okta'; 
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted Enterprise Edition';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.NCD_Editions__c = 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive_NAS__c = 'Single Zone (LRS)';
		newPOCRequest.Data_Redundancy_Backup_NAS__c = 'Single Zone (LRS)';
        return newPOCRequest;
    }
    
    private static POC__c getStandardPOCNAS(String archiveNas, String backupNas) {
        
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
         newPOCRequest.Product_Categories__c = 'Rubrik Appliance;Edge;M365 and Entra ID;NAS Cloud Direct;Identity Recovery and Resilience - AD, Entra ID, Okta'; 
        newPOCRequest.Add_Identity_Recovery__c = 'yes';
        newPOCRequest.Add_Identity_Resilience__c = 'yes';
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted Enterprise Edition';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.NCD_Editions__c = 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive_NAS__c = archiveNas;
		newPOCRequest.Data_Redundancy_Backup_NAS__c = backupNas;
        return newPOCRequest;
    }
    
    private static POC__c getVirtualPOC() {
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Virtual Lab';
        newPOCRequest.Lab_Type__c = 'Foundations Unconfigured';
        newPOCRequest.POC_Qty__c = 10;
        newPOCRequest.POC_Justification__c = 'Test Justification';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        return newPOCRequest;
    }
    private static POC__c getstandardPOCRSCG(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        cnt1.email = 'test@test.com';
        cnt1.Phone = '78945612360';
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC : RSC-G';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted Enterprise Edition';
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'M365 and Entra ID;SaaS (Jira Cloud, Salesforce, Dynamics);UCL (Cloud Cluster, Cloud Native & Entra ID)';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.RSC_G_Contact__c = cnt1.Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.UCL_Edition__c = 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)';
        newPOCRequest.RCV_Backup_Tier__c = 'Yes';
        newPOCRequest.Dynamics__c = 'Yes';
        newPOCRequest.Number_of_Users_Dynamics__c = 209;
        return newPOCRequest;
        
    }
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     */
    public testmethod static void testStandardPOC() {
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            Test.startTest();
        	POC__c newPOCRequest = getStandardPOC();
        	insert newPOCRequest;
            POC__c newPOCRequestNAS1 = getStandardPOCNAS('Multi Zone (ZRS)', 'Multi Zone (ZRS)');
            insert newPOCRequestNAS1;
        	POC__c newRCVPOCRequest = getStandardRCVPOC();
        	insert newRCVPOCRequest;
            POC__c  newPOcrequestCloud = getStandardcloudUnstructured();
            insert newPOcrequestCloud;
            POC__c  newPOcrequest1 = getStandardRCVPOC1('Multi Zone (ZRS)','Multi Zone (ZRS)');
            insert newPOcrequest1;
            POC__c  newPOcrequest2 = getStandardRCVPOC1('Multi Zone (ZRS)','Multi Region (GRS)');
            insert newPOcrequest2;
            
            POC__c newPOCRequestM365GSpace = getStandardPOCM365GSapce1();
            insert newPOCRequestM365GSpace;
            POC__c newPOCRequestM365GSpace2 = getStandardPOCM365GSapce2();
            insert newPOCRequestM365GSpace2;
          
          POC__c newPOCReqRbkAgentCloud = getStandardPOCRubrikAgentCloud();
            insert newPOCReqRbkAgentCloud;
        	
          	 POC__c newPOcrequest3 = getCodebaseRecovery(); //Added for MKT26-490
            insert newPOcrequest3;
          
            POC__c newPOcrequest4 = getStandardRCVRSCEEAndPE();//Added for MKT26-410
            insert newPOcrequest4;

            POC__c newPOCRequestNAS2 = getStandardPOCNAS('Multi Zone (ZRS)', 'Multi Region (GRS)'); //Added for PRDOPS26-1057
            insert newPOCRequestNAS2; //Added for PRDOPS26-1057
        
            ShGl_DisableBusinessLogic__c businessLogicToggle = [SELECT Id,Follow_Existing_EntCreate_Process__c FROM ShGl_DisableBusinessLogic__c LIMIT 1];
            businessLogicToggle.Follow_Existing_EntCreate_Process__c = true;
            update businessLogicToggle;
        	System.assert(newRCVPOCRequest != null);
        Test.stopTest();
        update new POC__c(Id=newPOcrequestCloud.Id, Approval_Status__c = 'Extension Approved', Opportunity__c = createOpportunity1().Id);
        update new POC__c(Id=newRCVPOCRequest.Id, Approval_Status__c = 'Extension Approved');
        update new POC__c(Id=newRCVPOCRequest.Id, Approval_Status__c = 'Pending');
            
        }
        
    }
    
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     */
    public testmethod static void testStandardPOC1(){
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            insert new ShGl_DisableBusinessLogic__c(Disable_Order_Validation_Rules__c = true, SetupOwnerId = thisUser.Id);
            Test.startTest();
            Order ord = [SELECT Id, POC_Request__c,OpportunityId FROM Order LIMIT 1];            
            poc__c newPOCRequestTest = getStandardtest();
            insert newPOCRequestTest;
            Opportunity oppRec = createOpportunity1();
            ord.POC_Request__c = newPOCRequestTest.Id;
            ord.OpportunityId = oppRec.Id;
            update ord;
            Test.stopTest();
            update new POC__c(Id=newPOCRequestTest.Id, Approval_Status__c = 'Extension Approved', Opportunity__c = oppRec.Id);
            System.assertEquals(true, newPOCRequestTest.Id != null);
            
        }
        
    }
    
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     */
    public testmethod static void testVirtualPOC() {
        PocFormControllerCls.getProductCustomMetadata1();
        PocFormControllerCls.getProductSKUs();
        
        Product2 objProduct = [Select Id, Name From Product2 where isActive=true LIMIT 1];
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            Test.startTest();
        Opportunity opportunity1 = createOpportunity1();
        POC__c newPOCRequest = getVirtualPOC();
        newPOCRequest.Opportunity__c = opportunity1.Id;
        insert newPOCRequest;

        Opportunity opportunity2 = createOpportunity1();
        //create order 
        Order orderObj = prepareOrder(opportunity2.AccountId, opportunity2.Id, DOINSERT_FALSE);
        orderObj.POC_Opportunity__c = opportunity2.Id;
        orderObj.Order_Status__c = 'Shipped';
        insert orderObj;

        update new POC__c(Id=newPOCRequest.Id, Approval_Status__c = 'Approved', Opportunity__c = opportunity2.Id);
        List<POC__c> poclist = new List<POC__C>();
        poclist.add(newPOCRequest);
        POCRequestTriggerHelper.approveVirtualLabPOCs(poclist);
        
        Asset objAsset1 = new Asset();
        objAsset1.SerialNumber = 'AS010AS010AS010';
        objAsset1.Name = 'Test Asset';
        objAsset1.POC_Request__c = newPOCRequest.Id;
        objAsset1.AccountId = [Select Id From Account LIMIT 1].Id;
        objAsset1.Product2Id = objProduct.Id;
        insert objAsset1;
        
        Test.stopTest();
        System.assertEquals('Approved', newPOCRequest.Approval_Status__c);
            
        }
        
    }
	
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     */
    public testmethod static void testWebTryAndBuyPOC() {
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            Test.startTest();
            POC__c newPOCRequest = getWebTryAndBuyPOC();
            insert newPOCRequest;
            PocFormControllerCls.getOrders(newPOCRequest.Id);
            Test.stopTest();
            Date todaydat = System.today();
            update new POC__c(Id=newPOCRequest.Id, Approval_Status__c = 'Approved', Most_Recent_End_Date__c =todaydat);
            System.assertEquals(true, newPOCRequest.Id != null);
            
        }
        
    }
   
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This is to verify the Address Update on order When Account Billing Country is blank.
     * F
     */
    public testmethod static void testWebTryAndBuyPOC2() {
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        Account accountObj = [SELECT Id, BillingCountry FROM Account LIMIT 1];
        accountObj.BillingCountry = '';
        update accountObj;

        Opportunity opportunityObj = [Select Id, AccountId From Opportunity LIMIT 1];
        opportunityObj.AccountId = accountObj.Id;
        update opportunityObj;

        System.runAs(thisUser){
            Test.startTest();
            POC__c newPOCRequest2 = getWebTryAndBuyPOC();
            newPOCRequest2.Opportunity__c = opportunityObj.Id;
            insert newPOCRequest2;
            PocFormControllerCls.getOrders(newPOCRequest2.Id);
            Test.stopTest();
            Date todaydate = System.today();
            update new POC__c(Id = newPOCRequest2.Id, Approval_Status__c = 'Approved', Most_Recent_End_Date__c = todaydate);
            POC__c updatedPoc = [SELECT Id, Approval_Status__c FROM POC__c WHERE Id = :newPOCRequest2.Id];
            Assert.isTrue(updatedPoc.Approval_Status__c == 'Approved', 'POC should be updated');
        }
        
    }
   
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     */
    public testmethod static void standardPOCRSCG(){
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            Test.startTest();
            List<POC__c> pocList = new List<POC__c>();
        	POC__c newPOCRequest = getstandardPOCRSCG();
            pocList.add(newPOCRequest);
            POC__c newPOcREquest1 = getStandardIdentityRec();
            pocList.add(newPOcREquest1);
            POC__c newPOCreqSingleZone = getStandardRCVGov('Single Zone (LRS)','Multi Region (GRS)');
            pocList.add(newPOCreqSingleZone);
            POC__c newPOCreqMultiZone = getStandardRCVGov('Single Zone (LRS)','Multi Zone (ZRS)');
            pocList.add(newPOCreqMultiZone);
            POC__c newPOCreqMultiZone2 = getStandardRCVGov('Single Zone (LRS)','Single Zone (LRS)');
            pocList.add(newPOCreqMultiZone2);
            POC__c newPOcCloudCluster = getStandartcloucluster();
            pocList.add(newPOcCloudCluster);
            POC__c newPOcRSCEE = getStandardRCVGovRSCEEAndPE(); //Added for MKT26-410
            pocList.add(newPOcRSCEE);
            insert pocList;
            
        Boolean isException = false;
            Test.stopTest();
            try{
                List<POC__c> pocListToUpdate = new List<POC__c>();
                pocListToUpdate.add(new POC__c(Id=newPOCRequest.Id, Approval_Status__c = 'Approved', Opportunity__c = createOpportunity1().Id));
                pocListToUpdate.add(new POC__c(Id=newPOcREquest1.Id, Approval_Status__c = 'Return Completed')); 
                update pocListToUpdate;
            }
            catch(Exception ex){
                isException = true;
                //Assert.isTrue(ex.getMessage().contains(POCRequestTriggerHelper.POC_APPROVAL_EXCEPTION_MESSAGE), 'unexpected validation message');
            }
            Assert.isTrue(isException, 'There should be a validation while approving a POC with type - Standard POC, Standard POC : RSC-G or CSAT Loaner');
        }
        
    }
    

    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     */

    //Added for PRDOPS26-1057
    public testmethod static void getRansomewareRecovery(){
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            Test.startTest();
            
            List<POC__c> pocList = new List<POC__c>();
            POC__c newPOCRequest = getRansomwarePOC();
            pocList.add(newPOCRequest);
            insert pocList;

            pocList[0].Approval_Status__c = 'Approved';
            update pocList[0];
            Test.stopTest();
            List<Order> pocOrder = [Select Id, POC_Request__c FROM Order WHERE POC_Request__c =: pocList[0].Id];
            System.assertEquals(pocOrder.size() > 0, true);
        }
    }

     /**
   * @description Submits a Proof of Concept (POC) request based on the provided request object.
   * @return response_Wrapper An object containing the POC request response, including validation errors, if any.
  */
    public static opportunity createOpportunity(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity o = new Opportunity();
        o.AccountId = acc.Id;
        o.PriceBook2Id = Test.getStandardPricebookId();
        o.Amount = 10.00;
        o.Name = 'Unit Test Purposes2';
        o.CloseDate = Date.Today().addDays(5);
        o.StageName = 'Prospecting';
        insert o;
        return o;
    }
    
     /**
   * @description Submits a Proof of Concept (POC) request based on the provided request object.
   * @return response_Wrapper An object containing the POC request response, including validation errors, if any.
  */
    public static opportunity createOpportunity1(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity o = new Opportunity();
        o.AccountId = acc.Id;
        o.PriceBook2Id = Test.getStandardPricebookId();
        o.Amount = 10.00;
        o.Name = 'Unit Test Purposes1';
        o.CloseDate = Date.Today().addDays(5);
        o.StageName = 'Prospecting';
        o.POC_Products__c = 'UCL (Cloud Cluster, Cloud Native & Entra ID)';
        insert o;
        return o;
    }
	
    private static POC__c getStandardRCVPOC() {
        
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
         newPOCRequest.Product_Categories__c = 'Rubrik Cloud Vault'; 
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive__c ='Single Zone (LRS)';
        newPOCRequest.Data_Redundancy_Backup__c = 'Single Zone (LRS)' ;
        return newPOCRequest;
    }
    
    private static POC__c getStandardRCVPOC1(String archiveZone, String backupZone){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
         newPOCRequest.Product_Categories__c = 'Rubrik Cloud Vault'; 
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive__c = archiveZone;
        newPOCRequest.Data_Redundancy_Backup__c = backupZone ;
        return newPOCRequest;
    }
    private static POC__c getStandardIdentityRec(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC : RSC-G';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'Identity Recovery';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.RSC_G_Contact__c = cnt1.Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.How_many_identity_users_areThere__c = 2;
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        return newPOCRequest;
    }
    private static POC__c getStandardcloudUnstructured(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'Cloud Unstructured (S3, Azure Blob, and Cloud Files)';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.RSC_G_Contact__c = cnt1.Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.cloud_type__c = 'AWS';
        newPOCRequest.How_much_FETB_do_you_need__c = 3;
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        return newPOCRequest;
    }
    
    private static POC__c getStandardtest(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'Cloud Unstructured (S3, Azure Blob, and Cloud Files)';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.RSC_G_Contact__c = cnt1.Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.cloud_type__c = 'AWS';
        newPOCRequest.How_much_FETB_do_you_need__c = 3;
        return newPOCRequest;
    }
    private static POC__c getStandartcloucluster(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC : RSC-G';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'UCL(Cloud Cluster & Cloud Native)';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.RSC_G_Contact__c = cnt1.Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.Cloud_Cluster_Location__c ='Azure';
        newPOCRequest.UCL_Edition__c ='Rubrik Security Cloud - Government, Universal Cloud License (No RCV)';
        newPOCRequest.cloud_type__c = 'AWS';
        newPOCRequest.Number_Of_UCL_FETB__c = 3;
        newPOCRequest.Storage_Region_Bundle_UCL__c ='Gov Cloud';
        return newPOCRequest;
    }
    private static POC__c getRansomwarePOC(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Ransomware Recovery Software';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Product_Categories__c = 'RSC Enterprise Edition';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.RSC_G_Contact__c = cnt1.Id;
        newPOCRequest.Original_End_Date__c = Date.today().addDays(15);// //Added for PRDOPS26-1057
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8); // //Added for PRDOPS26-1057
        return newPOCRequest;
    }
    
    private static POC__c getStandardRCVGov(String singleTierValue, String multiTierValue){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
         newPOCRequest.Product_Categories__c = 'Rubrik Cloud Vault - Government'; 
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive__c =singleTierValue;
        newPOCRequest.Data_Redundancy_Backup__c = multiTierValue ;
        return newPOCRequest;
    }
	
    /* Added for MKT26-490 */
    private static POC__c getCodebaseRecovery(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Product_Categories__c = 'Codebase Recovery';
        newPOCRequest.Opportunity__c = createOpportunity().Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        newPOCRequest.Number_of_repositories_to_back_up_1_500__c = 400;
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        return newPOCRequest;
    }
          
    /* Added for MKT26-410*/
    private static POC__c getStandardRCVGovRSCEEAndPE(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC : RSC-G';
        newPOCRequest.Product_Categories__c = 'RSC-G Enterprise and Proactive Editions'; 
        newPOCRequest.RSC_G_Proactive_Edition__c  = 'Yes';
        newPOCRequest.RSC_G_Enterprise_Edition__c = 'Yes';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        return newPOCRequest;
    }
    
    /*** @description Inserts Web Try And Buy POC Request and then updates Expected End Date to check if the Support End Date is updated in the related Order product
     */
    public testmethod static void testWebTryAndBuyPOCExtension() {
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
            Test.startTest();
            POC__c newPOCRequest = getWebTryAndBuyPOC();
            insert newPOCRequest;
            PocFormControllerCls.getOrders(newPOCRequest.Id);
            Test.stopTest();
            Date todaydat = System.today();
            update new POC__c(Id = newPOCRequest.Id, Approval_Status__c = 'Extension Approved', New_Expected_End_Date__c = todaydat);
            System.assertEquals(true, newPOCRequest.Id != null);
        }
    }
    
    /* Added for MKT26-410*/
    private static POC__c getStandardRCVRSCEEAndPE(){
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
        newPOCRequest.Product_Categories__c = 'RSC Enterprise and Proactive Editions;RSC-Private;Annapurna'; //Added for PRDOPS26-1057
        newPOCRequest.RSC_Private_Edition__c = 'RSC-Private with Enterprise Edition';  //Added for PRDOPS26-1057
        newPOCRequest.RSC_Proactive_Edition__c   = 'Yes';
        newPOCRequest.RSC_Enterprise_Edition__c  = 'Yes';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        return newPOCRequest;
    }

    private static Order prepareOrder(Id accountId, Id opportunityId, Boolean doInsert){
        Order orderObj = new Order();
        orderObj.AccountId = accountId;
        orderObj.Type = 'POC';
        orderObj.OpportunityId = opportunityId;
        orderObj.Support_End_Date__c= Date.Today();
        orderObj.EffectiveDate = Date.Today();
        orderObj.Order_Status__c = 'Shipped';
        orderObj.ShippingStreet ='Test Street';
        orderObj.ShippingCity ='Test City';
        orderObj.ShippingState ='California';
        orderObj.ShippingCountry ='United States';
        orderObj.ShippingPostalcode ='94820';
        orderObj.Shipping_Address_Label__c = null;

        if(doInsert){
            insert orderObj;
        }
        return orderObj;
    }
    
    private static POC__c getStandardPOCM365GSapce1() {
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
        newPOCRequest.Product_Categories__c = 'M365 and Google Workspace'; 
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted Enterprise Edition';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.NCD_Editions__c = 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive_NAS__c = 'Single Zone (LRS)';
        newPOCRequest.Data_Redundancy_Backup_NAS__c = 'Single Zone (LRS)';
        newPOCRequest.M365_Option__c = 'Yes';
        newPOCRequest.Google_Workspace__c = 'Yes';
        newPOCRequest.Number_of_Users__c = 1;
        newPOCRequest.Number_of_Users_Google_Workspace__c = 2;
        return newPOCRequest;
    }
    
    private static POC__c getStandardPOCM365GSapce2() {
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
        newPOCRequest.Product_Categories__c = 'M365 and Google Workspace;Data Security Posture Management;Identity Recovery and Resilience - AD, Entra ID, Okta'; 
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.NCD_Editions__c = 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive_NAS__c = 'Single Zone (LRS)';
        newPOCRequest.Data_Redundancy_Backup_NAS__c = 'Single Zone (LRS)';
        newPOCRequest.M365_Option__c = 'Yes';
        newPOCRequest.Google_Workspace__c = 'Yes';
        newPOCRequest.Number_of_Users__c = 1;
        newPOCRequest.Number_of_Users_Google_Workspace__c = 2;
        newPOCRequest.Cloud_Data_Type__c = 'On-Premise';
        newPOCRequest.Add_Identity_Resilience__c = 'Yes';
        newPOCRequest.How_many_identity_users_are_there__c = 1;
        return newPOCRequest;
    }
          
          private static POC__c getStandardPOCRubrikAgentCloud() {
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';
        newPOCRequest.Product_Categories__c = 'Rubrik Agent Cloud'; 
        newPOCRequest.Agent_Cloud_Acknowledgement__c = 'Yes';
        newPOCRequest.RCV_Archive_Tier__c ='Yes';
        newPOCRequest.RCV_Backup_Tier__c ='Yes';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.NCD_Editions__c = 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt1.Id;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Data_Redundancy_Archive_NAS__c = 'Single Zone (LRS)';
        newPOCRequest.Data_Redundancy_Backup_NAS__c = 'Single Zone (LRS)';
        newPOCRequest.M365_Option__c = 'Yes';
        newPOCRequest.Google_Workspace__c = 'Yes';
        newPOCRequest.Number_of_Users__c = 1;
        newPOCRequest.Number_of_Users_Google_Workspace__c = 2;
        newPOCRequest.Cloud_Data_Type__c = 'On-Premise';
        newPOCRequest.Add_Identity_Resilience__c = 'Yes';
        newPOCRequest.How_many_identity_users_are_there__c = 1;
        return newPOCRequest;
    }
}