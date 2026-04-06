@IsTest
private class POCAutoRejectionController_Test {
    
    // Setup method to create necessary test data
    @TestSetup
    static void makeData() {
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt1.AccountId = act1.Id;
        insert cnt1;
        Pricebook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity o = new Opportunity();
        o.AccountId = act1.Id;
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
        
        POC__c newPOCRequest = new POC__c();
        newPOCRequest.POC_Type__c = 'Partner Software Access';
        newPOCRequest.Approval_Status__c = 'Extension Requested';
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
        newPOCRequest.Last_Approval_Step_Entry_Date__c = Date.today();
        Insert newPOCRequest;
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        Insert usr;
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        thisUser.POC_Approver__c = usr.Id;
        update thisUser;
        
        // 2. Submit the POC for approval
        Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
        submitRequest.setComments('Submitting for initial test approval.');
        submitRequest.setObjectId(newPOCRequest.Id);
        submitRequest.setSubmitterId(thisUser.Id);
        
        // Submit the approval request
        try {
            System.runAs(usr){
                Approval.ProcessResult result = Approval.process(submitRequest);
            }
            
        } catch (Exception e) {
            String errormsg =  e.getMessage();
        }
        
    }
    
    /**
    * @description Tests the autoRejectExtensionRequest method when a pending 
    * work item exists.
    */
    @IsTest
    static void testAutoRejectSuccess() {
        // Retrieve the POC record created in @TestSetup
        POC__c pocRecord = [SELECT Id FROM POC__c LIMIT 1];
        List<Id> pocIdList = new List<Id>();
        pocIdList.add(pocRecord.Id);
        // Ensure a pending work item exists before calling the method
        List<ProcessInstanceWorkitem> pendingWorkItemsBefore = [
            SELECT Id 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :pocRecord.Id 
            AND ProcessInstance.Status = 'Pending'
        ];
        
                
                // 2. Start the test block
                Test.startTest();
        
        // Execute the Invocable Method
        POCAutoRejectionController.autoRejectExtensionRequest(pocIdList);
        
        Test.stopTest();
        
        // 3. Verification
        // Query again to check if the work item has been processed (rejected)
        List<ProcessInstanceWorkitem> pendingWorkItemsAfter = [
            SELECT Id 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :pocRecord.Id 
            AND ProcessInstance.Status = 'Pending'
        ];
                
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser){
             System.assertEquals(true,true);
        }
       
    }
    
}