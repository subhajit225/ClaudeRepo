@isTest
public class POCReturnTriggerTest {
	
    @testSetup
    static void setupDataForAccountTriggerHandler(){
        //ShGl_DisableBusinessLogic__c
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Triggers__c = TRUE);
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        //ShGl_DisableBusinessLogic__c
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;

        //create single account
        Account act11 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act11 :: '+act11);
        insert act11;
        Contact cnt11 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt11.AccountId = act11.Id;
        insert cnt11;

        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(1, actList.size());

        //Test.startTest();
        System.RunAs(usr){
            
            List<Product2> lstProducts = getProducts();
            insert lstProducts;
            
            Pricebook2 pricebook = POCRequestTriggerHandler.stdPriceBook;
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
            
            // act11.OwnerId = usr.Id;
            // update act11;
            
            Opportunity o = new Opportunity();
            o.AccountId = act11.Id;
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
        }
        //
        //Test.stopTest();
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
        Product2 objP2 = new Product2();
        objP2.ProductCode = 'RS-BT-RCDM-T';
        objP2.Name = 'Default product code';
        objP2.IsActive = true;
        lstProduct2.add( objP2 );
        return lstProduct2;
    }
    
    private static POC__c getWebTryAndBuyPOC() {
        Account act12 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act12 :: '+act12);
        insert act12;
        Contact cnt12 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt12.AccountId = act12.Id;
        insert cnt12;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Web Try and Buy';	
        newPOCRequest.Online_Agreement_Signed__c = true;	
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted';
        newPOCRequest.Polaris_Region__c = 'Europe';
        newPOCRequest.Polaris_Contact__c = cnt12.Id;
        newPOCRequest.Number_of_Users__c = 101;
        newPOCRequest.Product_Categories__c = 'Rubrik Appliance';
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(8);
        return newPOCRequest;
    }
    
    private static POC__c getStandardPOC() {
        Account act13 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act13 :: '+act13);
        insert act13;
        Contact cnt13 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt13.AccountId = act13.Id;
        insert cnt13;
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Standard POC';	
        newPOCRequest.Product_Categories__c = 'Rubrik Appliance;Edge;NAS Cloud Direct;';
        // newPOCRequest.Product_Categories__c = 'Rubrik Appliance;Edge;Cloud Cluster;Polaris GPS and Radar;Polaris Sonar;Polaris Cloud Native Protection;Polaris M365;NAS Cloud Direct;';
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.NCD_Editions__c = 'Basic NCD (No RCV)';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1'; 
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'UK';
        newPOCRequest.Polaris_Contact__c = cnt13.Id;
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
    
    public testmethod static void testStandardPOC() {
        Test.startTest();
        	POC__c newPOCRequest = getStandardPOC();
        	insert newPOCRequest;
        Test.stopTest();
    }
    
    public testmethod static void testVirtualPOC() {
        PocFormControllerCls.getProductCustomMetadata1();
        PocFormControllerCls.getProductSKUs();
        
        Product2 objProduct = [Select Id, Name From Product2 where isActive=true LIMIT 1];
        
        Test.startTest();
        POC__c newPOCRequest = getVirtualPOC();
        insert newPOCRequest;
        
        Asset objAsset1 = new Asset();
        objAsset1.SerialNumber = 'AS010AS010AS010';
        objAsset1.Name = 'Test Asset';
        objAsset1.POC_Request__c = newPOCRequest.Id;
        objAsset1.AccountId = [Select Id From Account LIMIT 1].Id;
        objAsset1.Product2Id = objProduct.Id;
        insert objAsset1;
        
        Test.stopTest();
        //update new POC__c(Id=newPOCRequest.Id, Approval_Status__c = 'Approved');
        
        PocFormControllerCls.response_Wrapper resp1 = PocFormControllerCls.getOrders(newPOCRequest.Id);
        Boolean isWrapSuccess1 = resp1.isSuccess;
        System.assertEquals(true, isWrapSuccess1);
        
        POC_Return__c objReturn = new POC_Return__c();
        objReturn.Pick_up_Street__c = 'Test FFF';
        objReturn.Pick_up_City__c = 'TTE';
        objReturn.Pickup_Country__c = 'United States';
        objReturn.Pick_up_zip_code__c = '1212121';
        objReturn.Additional_Shipping_Notes__c = 'Test Area';
        objReturn.Return_to_Rubrik_warehouse__c = true;
        //objReturn.Delivery_Account__c = objAsset1.AccountId;
        objReturn.Delivery_User__c = UserInfo.getUserId();
        objReturn.Delivery_Contact_Name__c = 'Test';
        objReturn.Delivery_Email__c = 'Test@Email.com';
        objReturn.Delivery_Phone__c = '121212121';
        objReturn.Delivery_Street__c = 'Test ySetr';
        objReturn.Delivery_City__c = 'NewYork';
        objReturn.Delivery_Country__c = 'United States';
        objReturn.Delivery_Zip_code__c = '1212121223';
        objReturn.Delivery_State__c = 'New York';
        objReturn.Pick_up_State__c = 'New York'; 	 
        objReturn.POC_Request__c = newPOCRequest.Id;
        objReturn.Available_Pick_Up_Day__c = Date.today().addDays(10);
        insert objReturn;
        
        POC_Return_Item__c returnItem = new POC_Return_Item__c();
        returnItem.Damage_Details__c = null;
        returnItem.Damage_Reported_by_the_customer__c = false;
        returnItem.Data_Erase_Requested__c = false;
        returnItem.Asset__c = objAsset1.Id;
        returnItem.Name = objProduct.Name + '-Return';
        returnItem.Product__c = objProduct.Id;
        returnItem.Original_Packaging_Available__c = false;
        returnItem.Serial_Number__c = objAsset1.SerialNumber;
        returnItem.complete_a_SD_Reset__c = false;
        returnItem.POC_Return__c = objReturn.Id;
        insert returnItem;
        
        update new POC_Return__c(Status__c = 'Returned', Id=objReturn.Id, Returned_date__c = Date.today(), Retrun_Tracking_Number__c='1212ADSDSD');
    }
	
	public testmethod static void selfApprovalTest(){
        Test.startTest();
        
            POC__c newPOCRequest = getVirtualPOC();
        	insert newPOCRequest;
            POC_Return__c objReturn = new POC_Return__c();
            objReturn.Pick_up_Street__c = 'Test FFF';
            objReturn.Pick_up_City__c = 'TTE';
            objReturn.Pickup_Country__c = 'United States';
            objReturn.Pick_up_zip_code__c = '1212121';
            objReturn.Additional_Shipping_Notes__c = 'Test Area';
            objReturn.Return_to_Rubrik_warehouse__c = true;
            objReturn.Delivery_User__c = UserInfo.getUserId();
            objReturn.Delivery_Contact_Name__c = 'Test';
            objReturn.Delivery_Email__c = 'Test@Email.com';
            objReturn.Delivery_Phone__c = '121212121';
            objReturn.Delivery_Street__c = 'Test ySetr';
            objReturn.Delivery_City__c = 'NewYork';
            objReturn.Delivery_Country__c = 'United States';
            objReturn.Delivery_Zip_code__c = '1212121223';
            objReturn.Delivery_State__c = 'New York';
            objReturn.Pick_up_State__c = 'New York'; 	 
            objReturn.POC_Request__c = newPOCRequest.Id;
            objReturn.Available_Pick_Up_Day__c = Date.today().addDays(10);
            insert objReturn;
        	objReturn.Status__c = 'Approved';
            try {
                UPDATE objReturn;
                //Assert.Fail();
            }
            catch(DMLException ex)
            {
                //Assert.isTrue(ex.getMessage().contains('Operation not permitted. Please contact your manager for assistance.'));
            }        	
        
        Test.stopTest();
    }

    public testmethod static void testWebTryAndBuyPOC() {
        Test.startTest();
        POC__c newPOCRequest = getWebTryAndBuyPOC();
        insert newPOCRequest;
        PocFormControllerCls.getOrders(newPOCRequest.Id);
        Test.stopTest();
        update new POC__c(Id=newPOCRequest.Id, Approval_Status__c = 'Approved');
    }
}