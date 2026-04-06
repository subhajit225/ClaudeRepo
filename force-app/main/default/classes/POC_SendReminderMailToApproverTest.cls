@isTest
public class POC_SendReminderMailToApproverTest {
    
    
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
		
        Id adminUser = UserInfo.getUserId();
        
        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act :: '+act);
        insert act;

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
            
            act.OwnerId = usr.Id;
            update act;
            
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
            o.Rubrik_Sales_Engineer__c = adminUser;
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
        Product2 objP1 = new Product2();
        objP1.ProductCode = 'RS-BT-RCDM-T';
        objP1.Name = 'Default product code';
        objP1.IsActive = true;
        lstProduct2.add( objP1 );
        return lstProduct2;
    }

   static testMethod void testMailSentToApprover(){
        
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'CSAT Loaner';
        newPOCRequest.Approval_Status__c='Pending';
        newPOCRequest.Product_Categories__c = 'Rubrik Appliance;Edge;M365;NAS Cloud Direct;'; 

       // newPOCRequest.Product_Categories__c = 'Rubrik Appliance;Edge;Cloud Cluster;Polaris GPS and Radar;Polaris Sonar;Polaris Cloud Native Protection;Polaris M365;NAS Cloud Direct;';
        newPOCRequest.M365_Hosting_environment__c = 'Rubrik Hosted';
        newPOCRequest.Cloud_Cluster_Location__c = 'Azure';
        newPOCRequest.Number_of_Users__c = 50;
        newPOCRequest.NAS_CloudDirect_Site_Name__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_Timezone__c = 'Test 1';
        newPOCRequest.NAS_CloudDirect_VM_Type__c = 'VMWare';
        newPOCRequest.SAP_Hana__c = true;
        newPOCRequest.Kubernetes__c = true;
        newPOCRequest.Polaris_Region__c = 'Europe';
        newPOCRequest.Polaris_Contact__c = null;
        newPOCRequest.POC_Relocation__c = 'No';
        newPOCRequest.Shipping_Contact__c = 'Test';
        newPOCRequest.Shipping_Contact_Phone__c = '12121212';
        newPOCRequest.Shipping_State__c = 'AA';
        newPOCRequest.Shipping_Country__c = 'United States';
        newPOCRequest.Ship_To_Country__c = 'United States';
        newPOCRequest.Shipping_Contact_Email__c = 'tets@testemail.com';
        newPOCRequest.Shipping_City__c = 'Mum';
        newPOCRequest.Shipping_Street__c = 'TestStreet';
        newPOCRequest.Approval_Status__c = 'Approved';
        newPOCRequest.Has_Hardware__c = true;
        newPOCRequest.Order_Shipped__c = 'Yes';
        newPOCRequest.Shipping_Zip_Postal_Code__c = '123456';
        newPOCRequest.Rubrik_Appliance_Products__c = '[{"productName":"SFP+ NIC (Fiber)","switchType":"r6412s","Quantity":"1"}]';
        newPOCRequest.Rubrik_Appliance_Accessories__c = '[{"accessoryName":"25/10GbE SFP+ (RBK-SFP28-TSR-01) - pack of 4","Quantity":"1"}]';
        newPOCRequest.Planned_Installation_Date_Time__c = Datetime.now().addDays(10);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(10);	
        newPOCRequest.New_Expected_End_Date__c = Date.today().addDays(12);	
        newPOCRequest.Planned_Installation_Date__c = Date.today().addDays(12);
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        
      
        insert newPOCRequest;
    
      Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();                 
      req.setObjectId(newPOCRequest.id);
      req.setProcessDefinitionNameOrId('POC_Request_Loaner_Unit_v6'); 
       req.setSkipEntryCriteria(true);
      Approval.ProcessResult result = Approval.process(req);
      system.debug('result>>>>'+result);
        List<Id> POCID = new List<Id>();
        POCID.add(newPOCRequest.id);
        
       Test.startTest();
        //POCSendPendingNoticationController ba= new POCSendPendingNoticationController();
        POCSendPendingNoticationController.sendEmailNotification(POCID);
        Test.stopTest();
    } 
  
    
    
}