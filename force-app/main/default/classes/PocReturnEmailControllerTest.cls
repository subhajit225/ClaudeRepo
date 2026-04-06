@isTest
public class PocReturnEmailControllerTest {
    
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
        return lstProduct2;
    }
    
      public testmethod static void testVirtualPOC() {
     
        
        Product2 objProduct = [Select Id, Name From Product2 where isActive=true LIMIT 1];
        
        Test.startTest();
        POC__c newPOCRequest = getVirtualPOC();
        insert newPOCRequest;
        
        PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, 'ExpectedDateLogic', Date.today());
        PocFormControllerCls.validateExpectedEndDate(newPOCRequest.Id, 'ExpectedDateLogic', Date.today().addDays(21));
        PocFormControllerCls.response_Wrapper resp = PocFormControllerCls.getOrders(newPOCRequest.Id);
		Boolean isWrapSuccess = resp.isSuccess;
        System.assertEquals(false, isWrapSuccess);

        Asset objAsset1 = new Asset();
        objAsset1.SerialNumber = 'AS010AS010AS010';
        objAsset1.Name = 'Test Asset';
        objAsset1.POC_Request__c = newPOCRequest.Id;
        objAsset1.AccountId = [Select Id From Account LIMIT 1].Id;
        objAsset1.Product2Id = objProduct.Id;
        insert objAsset1;
        
        Test.stopTest();
        //update new POC__c(Id=newPOCRequest.Id, Approval_Status__c = 'Approved');
        
        /*try {
        	POC_FormController.updatePOCRequest( newPOCRequest );
        }catch(Exception e) {
            
        }*/
        
        POC_Return__c objReturn = new POC_Return__c();
        objReturn.Pick_up_Street__c = 'Test FFF';
        objReturn.Pick_up_City__c = 'TTE';
        objReturn.Pickup_Country__c = 'United States';
        objReturn.Pick_up_zip_code__c = '1212121';
        objReturn.Additional_Shipping_Notes__c = 'Test Area';
        objReturn.Return_to_Rubrik_warehouse__c = true;
        objReturn.POC_Request__c=newPOCRequest.id;
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
        returnItem.POC_Return__c=objReturn.id;
        returnItem.Damage_Reported_by_the_customer__c = false;
        returnItem.Data_Erase_Requested__c = false;
        returnItem.Asset__c = objAsset1.Id;
        returnItem.Name = objProduct.Name + '-Return';
        returnItem.Product__c = objProduct.Id;
        returnItem.Original_Packaging_Available__c = false;
        returnItem.Serial_Number__c = objAsset1.SerialNumber;
        returnItem.complete_a_SD_Reset__c = false;
        //returnItem.POC_Return__c = objReturn.Id;
        insert returnItem;
          
         PocReturnEmailController obj = new PocReturnEmailController();
         obj.PocReturnID=objReturn.id;
         obj.getPocReturnItem();
        
         obj.getOrderList();

      
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
        newPOCRequest.Most_Recent_End_Date__c = newPOCRequest.New_Expected_End_Date__c;	
        newPOCRequest.Opportunity__c = [Select Id From Opportunity LIMIT 1].Id;
        return newPOCRequest;
    }

}