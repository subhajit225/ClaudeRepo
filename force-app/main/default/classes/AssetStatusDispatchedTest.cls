@isTest(seeAllData=false)
    public class AssetStatusDispatchedTest {
        
        @testSetup static void createTestData() {
            TriggerControl__c custsetting = new TriggerControl__c();
            TestDataFactory.setWorkflowTriggerBypassCS(true);
            custsetting.Name = 'Opportunity';
            //custsetting.Disable_Trigger__c =
            custsetting.DisableTrigger__c = true;
            insert custsetting; 
            FlowControll.LeadTriggerHandler = false;
            FlowControll.opportunityTriggerHandler = false;
                       
            TriggerControl__c PortalUserCreation = new TriggerControl__c();
            PortalUserCreation.Name = 'PortalUserCreation';
            // PortalUserCreation.DisableTrigger__c = true;
            insert PortalUserCreation; 
            
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
            disableFuncCS.Disable_Order_Old_Trigger__c = true;
            insert disableFuncCS;
            StateNameCode__c custset = new StateNameCode__c();
            custset.Name = 'California';
            custset.Code__c = 'US-CA';
            insert custset;
            Date closeDt = System.Today()+30;
            String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
            Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            acct.RecordTypeId = partnerRecordTypeId;
            acct.Name = 'Test';
            insert acct;
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => acct.Id,
                    'Email'  =>'leademail@hidden.com'
                    };
            Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
            insert cnt1;
            //Generate the Opportunity
            Map<String, Object>  oppMap = new Map<String, Object> {
                'AccountId' => acct.Id,
                    'Initial_Contacts_Name__c' => cnt1.Id,
                    'Primary_Competitor__c' => 'Other',
                    'Other_Primary_Competitor__c' => 'Other',
                    'Other_Competitor_Field__c' => 'Other',
                    'Lost_To_Won_Against__c' => 'Other',
                    'Polaris_Region__c' => 'US'
                    };
                        List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 1, oppMap);
            insert opptyList;
            
            List<POC__c> pList = new List<POC__c>();
            POC__c pocobj = new POC__c();
            pocobj.POC_Duration__c = '60 Days';//30 Days
            pocobj.Planned_Installation_Date__c = closeDt;
            pocobj.Support_Awareness_needed__c = 'Yes';
            pocobj.POC_Type__c= 'Standard POC';
            pList.add(pocobj);
            POC__c pocobj2 = new POC__c();
            pocobj2.POC_Duration__c = '30 Days';//30 Days
            pocobj2.Planned_Installation_Date__c = closeDt;
            pocobj2.Support_Awareness_needed__c = 'Yes';
            pocobj2.POC_Type__c= 'EA Unit';
            pList.add(pocobj2);
            insert pList;
            List<Product2> prodlist = new List<Product2>();
            Map<String, Object>  prodMap = new Map<String, Object> {
                'Name' => 'X-0001-01',
                    'ProductCode' => 'ProductXYZ',
                    'isActive' => true,
                    'Family' => 'POLARIS',
                    'Product_Type__c' => 'Appliance'
                    };
            Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
            prodlist.add(pd);
            Map<String, Object>  prodMap2 = new Map<String, Object> {
                'Name' => 'X-0001-01',
                    'ProductCode' => 'ProductXYZ',
                    'isActive' => true,
                    'Family' => 'POLARIS',
                    'Product_Type__c' => 'GPS'
                    };
            Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
            prodlist.add(pd2);
            Map<String, Object>  prodMap3 = new Map<String, Object> {
                'Name' => 'X-0001-01',
                    'ProductCode' => 'ProductXYZ',
                    'isActive' => true,
                    'Family' => 'POLARIS',
                    'Product_Type__c' => 'RADAR'
                    };
                        Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);  
            prodlist.add(pd3);
            insert prodlist;
            Id pricebookId = Test.getStandardPricebookId();
            Map<String, Object>  quoteMap = new Map<String, Object> {
                'SBQQ__Account__c' => acct.Id,
                    'SBQQ__Opportunity2__c' => opptyList[0].Id
                    };
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt1.SBQQ__Opportunity2__c = opptyList[0].Id;
            qt1.SBQQ__Primary__c = true;
            qt1.SBQQ__PriceBook__c = pricebookId;
            qt1.ApprovalStatus__c = 'Approved';
            insert qt1;
        
            Lead objlead = TestDataFactory.insertLead();
            insert objlead;
        
            opptyList[0].Deal_Registration_Link__c = objlead.Id;
            opptyList[0].Partner_Lookup__c = acct.Id; 
            opptyList[0].pricebook2Id = pricebookId;
            opptyList[0].StageName = System.Label.Order_Creation_Stage;
            opptyList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
            opptyList[0].SBQQ__PrimaryQuote__c = qt1.Id;
            opptyList[0].Installation_Assigned_To__c = 'Partner Install';
            opptyList[0].Opportunity_Type__c = 'New Customer';
            opptyList[0].Opportunity_Sub_Type__c = 'Regular';
            opptyList[0].Primary_Competitor__c = 'Actifio';
            opptyList[0].Installation_Assigned_To__c = 'FE Install';
            opptyList[0].ForecastCategoryName = 'Best Case';
            update opptyList;
            
            List<order> listorder = new List<order>();
            Order od = new Order();
            od.Status = 'Draft';
            od.AccountId = acct.Id;
            od.OpportunityId =opptyList[0].Id;
            od.EffectiveDate = Date.Today();
            od.ShippingStreet ='Test Street';
            od.ShippingCity ='Test City';
            od.ShippingState ='California';
            od.ShippingCountry ='United States';
            od.ShippingPostalcode ='94820';
            //od.ship_To_Name__c=acct.id;
            od.Type = 'RMA';
            od.Est_Ship_Date__c = system.today();
            od.Order_Status__c = 'Pending';
            //od.Hold_Code__c = 'Delayed Ship Date';
            od.POC_Request__c = pocobj2.id;
            od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order').getRecordTypeId();
            od.Pricebook2Id = pricebookId;
            listorder.add(od);
            insert listorder;
/*            
	    Order od1 = [ SELECT Id,Pricebook2Id FROM Order where id = :od.id LIMIT 1 ];
            od1.Pricebook2Id = pricebookId;
            update od1;
*/		
            Map<String, Object>  orderMap = new Map<String, Object> {
                'AccountId' => acct.Id,
                    'OpportunityId' => opptyList[0].Id
                    };
                        //Order objorder = (order) ShGl_TestFactory.createSObject(new order(), orderMap);
                        // insert objorder;
                        
                        //Create your pricebook entry
                        PricebookEntry pbEntry = new PricebookEntry(
                            Pricebook2Id = pricebookId,
                            Product2Id = prodlist[0].Id,
                            UnitPrice = 100.00,
                            IsActive = true
                        );
            insert pbEntry;
            
            
            //insert oritem;
            List<OrderItem> OrderItemlist = new List<OrderItem>();
            OrderItem oitem1 = new OrderItem();
            oitem1.product2Id = prodlist[0].id;
            oitem1.orderid = listorder[0].id;
            oitem1.Quantity = 2;
            oitem1.PricebookEntryId = pbEntry.id;
            oitem1.UnitPrice = pbEntry.UnitPrice;
            OrderItemlist.add(oitem1);
            // OrderItem oitem2 = new OrderItem();
            // oitem2.product2Id = prodlist[0].id;
            // oitem2.orderid = listorder[0].id;
            // oitem2.Quantity = 2;
            // oitem2.PricebookEntryId = pbEntry.id;
            // oitem2.UnitPrice = pbEntry.UnitPrice;
            // OrderItemlist.add(oitem2);
            insert OrderItemlist;
            FlowControll.LeadTriggerHandler = true;
            FlowControll.opportunityTriggerHandler = true;

            List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN123', SerialNumber = 'SN123', Serial_Number__c = 'SN123',Order_Service_Item__c = OrderItemlist[0].id, Accountid = acct.Id,Product2id = prodlist[0].id),
            new Asset(Name = 'SN234', SerialNumber = 'SN234', Serial_Number__c = 'SN234',Order_Service_Item__c = OrderItemlist[0].id,  Accountid = acct.Id,Product2id = prodlist[0].id)
            // new Asset(Name = 'SN356', SerialNumber = 'SN356', Serial_Number__c = 'SN356',Order_Service_Item__c = OrderItemlist[0].id,  Accountid = acct.Id,Product2id = prodlist[0].id),
            // new Asset(Name = 'SN476', SerialNumber = 'SN476', Serial_Number__c = 'SN476',Order_Service_Item__c = OrderItemlist[0].id,  Accountid = acct.Id,Product2id = prodlist[0].id),
            // new Asset(Name = 'SN523', SerialNumber = 'SN523', Serial_Number__c = 'SN523',Order_Service_Item__c = OrderItemlist[0].id,  Accountid = acct.Id,Product2id = prodlist[0].id),
            // new Asset(Name = 'SN6457', SerialNumber = 'SN6457', Serial_Number__c = 'SN6457',Order_Service_Item__c = OrderItemlist[0].id,  Accountid = acct.Id,Product2id = prodlist[0].id)
        };
        insert assets;  
        
        system.debug('result ='+[SELECT Id,Name,Status FROM Asset WHERE account.Name != 'Unassigned'  AND Order_Service_Item__c != null AND Order_Product_Name__c LIKE 'X-%' AND Order_Service_Item__r.Order.Type = 'RMA'] );   
        }  
        
         public static testMethod void AssetStatusDispatchedTest() {
     
            new AssetStatusDispatched().Schedulingmethod();
            database.executeBatch(new AssetStatusDispatched());
     
 }
        
        
    }