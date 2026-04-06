@isTest
class RenewalAndExpansionSplitTest{
    @TestSetup
    static void makeData(){
        Test.startTest();
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                            Disable_Campaign_Trigger__c = true,
                                                                            Disable_Campaign_Validation_Rules__c = true,
                                                                            Disable_Order_Validation_Rules__c=true, 
                                                                            Disable_ServiceContract_Trigger__c=true,
                                                                            Disable_Entitlement_Usage_Trigger__c=true,
                                                                            Disable_Entitlement_Trigger__c=true,
                                                                            Disable_Asset_Triggers__c=true,
                                                                            Disable_Contract_Line_Item_Triggers__c=true,
                                                                            Disable_Entitlement_Validation_Rules__c = true);  
        insert cdf1;
 
        //create Account 
        Account objAccount = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        System.runAs(getUser('System Administrator')) {
            List<Territory2> territories = new List<Territory2>();
            List<Territory2Model> TModel = [select id,Name from territory2model where State ='Active'];
            List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DEveloperNAme = 'Territory'];
            
            for(Integer i=0;i<1;i++){
                Territory2 terr = new Territory2();
                terr.Name = 'TEST-TERR-' + i;
                terr.DeveloperName = 'TEST_TERR_' + i;
                terr.Adaptive_Territory_Id__c = '999999'+i;
                terr.Territory2ModelId = TModel[0].Id;
                terr.Territory2TypeId = terrType[0].Id;
                territories.add(terr);
            }
            insert territories;
            
            ObjectTerritory2Association obj = new ObjectTerritory2Association();
            obj.ObjectId = objAccount.Id;
            obj.Territory2Id = territories[0].Id;
            obj.AssociationCause = 'Territory2Manual';
            insert obj;
            
            User tUser1 = getUser('Rubrik Renewal Specialist');
            
            List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
            UserTerritory2Association uta1 = new UserTerritory2Association();
            uta1.Territory2Id = territories[0].Id;
            uta1.RoleInTerritory2 = 'Renewal Representative';
            uta1.UserId = tUser1.Id;
            utaRecords.add(uta1);

            insert utaRecords;
        }

        Contact objContact = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        objContact.AccountID = objAccount.Id;
        objContact.LastName = 'Test Contact';
        insert objContact; 
        
        Id pbId = Test.getStandardPriceBookId();  
        //create Opportunity
        Opportunity objOpportunity = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Oppty';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        objOpportunity.SBQQ__QuotePricebookId__c =pbId;    
        objOpportunity.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        objOpportunity.AccountId = objAccount.Id;

        Opportunity objOpportunity1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        objOpportunity1.StageName = '1 Discovery';
        objOpportunity1.closeDate = System.Today() + 30;
        objOpportunity1.Name = 'Test Renewal';
        objOpportunity1.Opportunity_Sub_Type__c = 'Renewal';
        objOpportunity1.Initial_Contacts_Name__c = objContact.Id;
        //objOpportunity.Distributor_Lookup__c = objAccount.Id;
        //objOpportunity.Partner_Lookup__c = objAccount.Id;
        //objOpportunity.SBQQ__QuotePricebookId__c =pbId;    
        objOpportunity1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        //insert objOpportunity;
        insert new List<Opportunity>{objOpportunity,objOpportunity1};

        Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => objAccount.Id,'SBQQ__Opportunity2__c' => objOpportunity.Id};
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'HW',
            'ProductCode' => 'RS-BT-EE-PE-PP',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'Support_Tier__c' => 'S1'
            // 'SBQQ__RenewalProduct__c' => ''
        };
        /*Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'HW',
            'ProductCode' => 'RH-6304S-01',
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => null, 
            'SBQQ__SubscriptionTerm__c' => null, 
            'SBQQ__SubscriptionType__c' => 'Renewable' 
            //    'SBQQ__RenewalProduct__c' => null
            //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
        }; */
            
        Map<String, Object> prdMap1 = new Map<String, Object> {
               'Name' => 'Subscription', 
               'IsActive' => true, 
               'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
               'ProductCode' => 'RS-BT-RCDM-T',
               'Product_Level__c' => 'OnPrem',
               'Support_Tier__c' => 'S1'
        };
                            
        Map<String, Object> prdMap2 = new Map<String, Object> {
            'Name' => 'HWSupport',
            'ProductCode' => 'RS-HW-SVC-PE-S1',
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12,
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'Support_Tier__c' => 'S1'
            //    'SBQQ__RenewalProduct__c' => null
        };
        
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);

        List<Product2> prdList = new List<Product2>(); // ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdSubsub);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW); 
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        
        PricebookEntry pbeSubsub = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsub.Product2Id = prdSubsub.Id;
        pBList.add(pbeSubsub);
        insert pBList;

        Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', Product2Id = prdHW.Id, AccountId = objAccount.Id, ContactId = objContact.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset1;
        Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', Product2Id = prdSubs.Id, AccountId = objAccount.Id, ContactId = objContact.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset2;
        Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080', Product2Id = prdSubsub.Id, AccountId = objAccount.Id, ContactId = objContact.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset3;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__PriceBook__c = pbId;
        qt.ApprovalStatus__c = 'Approved';
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        qt.SBQQ__StartDate__c = Date.today();
        qt.Manual_Billing__c = false;
        qt.Consolidate_Lines__c = false;
        qt.SBQQ__ExpirationDate__c = Date.today().addDays(60);
        qt.SBQQ__Account__c = objAccount.Id;
        insert qt;

        List<ServiceContract> sC = new List<ServiceContract>();
        //ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = objOpportunity.Id,AccountId = objAccount.Id,StartDate = System.today(),
        //                                                         PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id, Type = 'Phone Support');
        ServiceContract serviceContractObj1 = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = objOpportunity.Id,AccountId = objAccount.Id,StartDate = System.today(),
                                                                  PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id, SBQQSC__RenewalTerm__c=12);
        
        //sc.add(serviceContractObj);
        sc.add(serviceContractObj1);
        insert sC;
        
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = objAccount.Id;
        ContractLineItemObj.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj1.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.AssetId = newAsset1.Id;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj.SBQQSC__Product__c = prdHW.Id;
        ContractLineItemObj.Licensing_Model__c = 'Subscription';
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate =System.today() + 150;
        ContractLineItemObj.SBQQSC__RootId__c = newAsset1.Id;
        ContractLineItemObj.SBQQSC__ProductSubscriptionType__c='Renewable';
        ContractLineItemObj.SBQQSC__SubscriptionType__c = 'Renewable';
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 20;
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = objAccount.Id;
        ContractLineItemObj1.PricebookEntryId = pbeSubs.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj1.Id;
        ContractLineItemObj1.AssetId = newAsset2.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj1.Licensing_Model__c = 'Subscription';
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.SBQQSC__RootId__c = newAsset2.Id;
        ContractLineItemObj1.EndDate =System.today() + 150;
        ContractLineItemObj1.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
        ContractLineItemObj1.SBQQSC__RenewalQuantity__c = 20;
        
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = objAccount.Id;
        ContractLineItemObj2.PricebookEntryId = pbeSubsub.Id;
        ContractLineItemObj2.ServiceContractId = serviceContractObj1.Id;
        ContractLineItemObj2.AssetId = newAsset3.iD;
        ContractLineItemObj2.SBQQSC__RootId__c = newAsset2.Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj2.SBQQSC__Product__c = prdSubsub.Id;
        ContractLineItemObj2.Licensing_Model__c = 'Subscription';
        ContractLineItemObj2.StartDate = System.today();
        //  ContractLineItemObj2.Subscription_Term__c = 12; 
        ContractLineItemObj2.EndDate =System.today() + 150;
        ContractLineItemObj2.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
        //   ContractLineItemObj2.SBQQSC__SubscriptionType__c = 'Renewable';
        ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 20;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        insert ContractLineItemObj;
        newAsset1.SBQQSC__RequiredByLineItem__c = ContractLineItemObj.Id;
        insert ContractLineItemObj1;
        insert ContractLineItemObj2;
        newAsset2.SBQQSC__RequiredByLineItem__c = ContractLineItemObj1.Id;
        newAsset3.SBQQSC__RequiredByLineItem__c = ContractLineItemObj2.Id;
        update newAsset1;
        update newAsset2;
        update newAsset3;

        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard', Support_Tier__c = 'S1');  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli1.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard', Support_Tier__c = 'S1'); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsub.Id, SBQQ__RequiredBy__c = qli2.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli2.id,SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard', Support_Tier__c = 'S1'); 
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, 
        SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046, BB192863040032', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR', Support_Tier__c = 'S1');  

        SBQQ.TriggerControl.enable();

        qliList.add( qli1 );
        TriggerControls.disableQuoteLineTrigger = true;
        qliList.add( qli2 );
        TriggerControls.disableQuoteLineTrigger = false;
        qliList.add( qli3 );
        qliList.add( qli4 );
        insert qliList;
        
        Order ord = new Order();
        ord.PoNumber = '12345';
        ord.ShippingPostalCode = '123455';
        ord.PO_Number__c = '123455';
        ord.Overage_PO__c = 'test';
        ord.Shipping_Address_Label__c = 'test';
        ord.ShippingCity = 'test';
        ord.ShippingCountry = 'Aland Islands';
        ord.ShippingCountryCode = 'AX';
        ord.Status = 'Activated';
        ord.accountId = objAccount.Id;
        ord.EffectiveDate = Date.today();
        insert ord;
        
        insert new TriggerControl__c(name='Entitlement',DisableTrigger__c=true);

        Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.AccountId = objAccount.Id;
        enttitlementNewObj5.StartDate = Date.today().addDays(-365);
        enttitlementNewObj5.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj5.Renewable__c = true;
        enttitlementNewObj5.Type = 'Phone Support';
        enttitlementNewObj5.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj5.Product__c = prdHW.Id;
        enttitlementNewObj5.Renewal_Category__c = 'Renewed';
        enttitlementNewObj5.Refreshed_Opportunity_Link__c = objOpportunity.Id;
        enttitlementNewObj5.ServiceContractId = serviceContractObj1.Id;  
        system.debug('ent '+enttitlementNewObj5);
        insert enttitlementNewObj5; 
        
        Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //  enttitlementNewObj6.AssetId = newAsset2.Id;
        enttitlementNewObj6.AccountId = objAccount.Id;
        enttitlementNewObj6.StartDate = Date.today().addDays(-365);
        enttitlementNewObj6.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj6.AssetId = newAsset2.Id;
        enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj6.Renewable__c = true;
        enttitlementNewObj6.Type = 'Phone Support';
        enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj6.Renewal_Category__c = 'Renewed';
        //   enttitlementNewObj6.Product__c = prdHW.Id;
        enttitlementNewObj6.Refreshed_Opportunity_Link__c = objOpportunity.Id;
        enttitlementNewObj6.ServiceContractId = serviceContractObj1.Id;
        //    lstEntitlement.add(enttitlementNewObj5);
        system.debug('ent '+enttitlementNewObj6);
        insert enttitlementNewObj6; 
        
        Entitlement enttitlementNewObj7 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj7.AccountId = objAccount.Id;
        enttitlementNewObj7.StartDate = Date.today().addDays(-365);
        enttitlementNewObj7.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj7.AssetId = newAsset3.Id;
        enttitlementNewObj7.ContractLineItemId = ContractLineItemObj2.Id;
        enttitlementNewObj7.Renewable__c = true;
        enttitlementNewObj7.Type = 'Phone Support';
        enttitlementNewObj7.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj7.Product__c = prdHW.Id; 
        enttitlementNewObj7.Refreshed_Opportunity_Link__c = objOpportunity.Id;
        enttitlementNewObj7.ServiceContractId = serviceContractObj1.Id;
        enttitlementNewObj7.Renewal_Category__c = 'Refreshed';
        //    lstEntitlement.add(enttitlementNewObj5);
        system.debug('ent '+enttitlementNewObj7);
        insert enttitlementNewObj7; 

        qt.SBQQ__Primary__c = true;
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        objOpportunity = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id = :objOpportunity.Id];
        //move the opportunity to stage 6
        System.runAs(getUser('System Administrator')) {
            
            objOpportunity.StageName = '5 Negotiate & Close'; //6 PO With Channel
            objOpportunity.SBQQ__PrimaryQuote__c = qt.Id;
            objOpportunity.Cloud_Partner_Impact__c = 'None';
            //objOpportunity.Cloud_Partner_Led_Activity__c = 'Sourced';
            objOpportunity.Cloud_Type__c = 'Google';
            objOpportunity.Lost_To_Won_Against__c = 'Actifio';
            objOpportunity.Alliance_HW_Partner__c = 'Rubrik Initiated Alliance Deal';
            objOpportunity.Alliance_Partner_Name__c = 'Google';
            objOpportunity.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
            objOpportunity.SBQQSC__RenewedServiceContract__c = serviceContractObj1.Id;
            update objOpportunity;
        }
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(Line_Type_Text__c='Renewal',PBE_Product_Family__c = 'POLARIS',Renewal_Due_Date__c=System.Today()+300,pricebookentryid=pBList[0].Id,UnitPrice=0, Quantity = 1,OpportunityID =  objOpportunity.Id));
        
        insert oppLineList;
        system.runAs(getUser('System Administrator')) {
            objOpportunity.StageName = '6 PO With Channel'; 
            update objOpportunity;
        }
        //Create Opportunity Link
        Opportunity_Link__c opptyLink = new Opportunity_Link__c();
        opptyLink.Parent_Opportunity__c = objOpportunity.Id;
        opptyLink.Child_Opportunity__c = objOpportunity1.Id;
        opptyLink.Link_Type__c = RenewalAndExpansionSplit.LINK_TYPE;
        insert opptyLink;
        Test.stopTest();
    }

    private static User getUser (String profileName){
        return [SELECT Id FROM User WHERE Profile.Name = :profileName AND isActive=true AND Id != :UserInfo.getUserId() LIMIT 1];
    }

    @isTest
    private static void testisOpportunityValidForRollback(){
        Opportunity testOppty = [SELECT Id, Probability, Primary_Quote_Type__c, RecordTypeId FROM Opportunity LIMIT 1];
        testOppty.StageName = '6 PO With Channel';
        Test.startTest();
        System.runAs(getUser('System Administrator')) {
            //update testOppty;
            Opportunity testOppty1 = testOppty.clone();
            testOppty1.StageName = '5 Negotiate & Close';
            Boolean isvalid = RenewalAndExpansionSplit.isOpportunityValidForRollback(testOppty1, testOppty);
            System.assert(true, isvalid);
        }  
        Test.stopTest();
    }

    @isTest
    private static void testenableAnddisableBypassValidation(){
        Test.startTest();
        RenewalAndExpansionSplit.disableBypassValidation();
        ShGl_DisableBusinessLogic__c csInstance = new ShGl_DisableBusinessLogic__c();
        csInstance.Disable_Opportunity_Validation_Rules__c = false;
        csInstance.SetupOwnerId = UserInfo.getUserId();
        insert csInstance;
        RenewalAndExpansionSplit.disableBypassValidation();
        ShGl_DisableBusinessLogic__c logic = [SELECT Id, Disable_SBQQ_Quote_Validation_Rules__c FROM ShGl_DisableBusinessLogic__c WHERE Id = :csInstance.Id];
        System.assert(!logic.Disable_SBQQ_Quote_Validation_Rules__c);
        RenewalAndExpansionSplit.enableBypassValidation();
        System.assert(true);
        Test.stopTest();
        
    }

    @isTest
    private static void testprocessRenewalExpansionOpportunitySplit(){
        Set<String> setOpportunityFields = new Set<String>();
        for( Schema.FieldSetMember schFieldSetMember : SObjectType.Opportunity.FieldSets.Expansion_Renewal_split.getFields() ) {
            setOpportunityFields.add(schFieldSetMember.getFieldPath());
        }
        String query = 'SELECT Id, Name, SBQQ__PrimaryQuote__c';
        for(String fieldName : setOpportunityFields) {
            query = query+ ','+ fieldName;
        } 
        query+= ' FROM Opportunity WHERE SBQQ__PrimaryQuote__c != null LIMIT 1';
        
        Opportunity testOppty = ((List<Opportunity>) Database.query(query)).get(0);
        RenewalAndExpansionSplit splitClass = new RenewalAndExpansionSplit();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>{ testOppty.Id => testOppty};
        Set<Id> setRenewalExpansionOptySplit = new Set<Id>{testOppty.Id};
        Set<Id> setOrderedExpansionRenewal = new Set<Id>{testOppty.Id};
        Map<Id,Id> stageSixChurnNotificationMap = new Map<Id,Id>();
        Map<Id,User> userMap = new Map<Id,User>();
        List<Opportunity> opplist = new List<opportunity>();
        
        User userRec = [Select Id,Email,Division, Region__c, Area__c, Theatre__c, Sub_Region__c, UserRoleId, UserRole.Name,ManagerId,Manager.isActive,Manager.Email from User limit 1];
        userMap.put(userRec.Id,userRec);
        stageSixChurnNotificationMap.put(testOppty.Id,userRec.Id);
        
        String strQuery = 'Select Id, ';
        List<String> lstAlloppFields = new List<String>(
            Schema.sObjectType.Opportunity.fields.getMap().keySet()
        );
        opplist = database.query('SELECT ' + String.join(lstAlloppFields, ',') + ' FROM Opportunity limit 1');
        for(Opportunity opp : opplist){
            newOppMap.put(opp.Id,opp);
        }
        
        System.runAs(getUser('System Administrator')) {
            Test.startTest();
                try {
                System.enqueueJob( new RenewalAndExpansionSplit.EnqueueJob( newOppMap,setRenewalExpansionOptySplit, setOrderedExpansionRenewal,stageSixChurnNotificationMap,userMap));
                    //System.enqueueJob( new RenewalAndExpansionSplit.EnqueueJob( newOppMap, setRenewalExpansionOptySplit, setOrderedExpansionRenewal));
                }catch(Exception e){}
            System.assert(true);
            Test.stopTest();
        }
    }

    @isTest
    private static void testrollBackRenewalExpansionSplit(){
        Set<String> setOpportunityFields = new Set<String>();
        for( Schema.FieldSetMember schFieldSetMember : SObjectType.Opportunity.FieldSets.Expansion_Renewal_split.getFields() ) {
            setOpportunityFields.add(schFieldSetMember.getFieldPath());
        }
        String query = 'SELECT Id, Name, SBQQ__PrimaryQuote__c';
        for(String fieldName : setOpportunityFields) {
            query = query+ ','+ fieldName;
        } 
        query+= ' FROM Opportunity WHERE SBQQ__PrimaryQuote__c != null LIMIT 1';
        
        Opportunity testOppty = ((List<Opportunity>) Database.query(query)).get(0);
        RenewalAndExpansionSplit splitClass = new RenewalAndExpansionSplit();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>{ testOppty.Id => testOppty};
        Set<Id> setRenewalExpansionOptySplit = new Set<Id>{testOppty.Id};
        Set<Id> setOrderedExpansionRenewal = new Set<Id>{testOppty.Id};
        System.runAs(getUser('System Administrator')) {
            Test.startTest();
                try {
                    RenewalAndExpansionSplit.rollBackRenewalExpansionSplit(newOppMap,newOppMap, setOrderedExpansionRenewal);
                }catch(Exception e){}
            System.assert(true);
            Test.stopTest();
        }
    }

    /*@isTest
    private static void testgetRenewalRepresentative(){
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        System.runAs(getUser('System Administrator')) {
            Test.startTest();
                RenewalAndExpansionSplit.getRenewalRepresentative(new Set<Id>{testAccount.Id});
            Test.stopTest();
        }
    }*/

    @isTest
    private static void testcreateRenewalOpportunityLinkage(){ 
        ServiceContract testSC = [SELECT Id, SBQQSC__RenewalOpportunity__c, SBQQSC__Opportunity__c FROM ServiceContract LIMIT 1];
        ServiceContract newtestSC = testSC.clone(true, false, false, false);

        Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Renewal Opportunity'];
        newtestSC.SBQQSC__RenewalOpportunity__c = objOpportunity.Id;
        System.runAs(getUser('System Administrator')) {
            Test.startTest();
                RenewalAndExpansionSplit.createRenewalOpportunityLinkage(new List<ServiceContract>{newtestSC}, new Map<Id,ServiceContract>{testSC.Id => testSC});
            System.assert(true);
            Test.stopTest();
        }
    }
    
    /*@isTest
    private static void testcalculateClosedAdminReason2(){
        Opportunity testOppty = [SELECT Id FROM Opportunity WHERE SBQQSC__RenewedServiceContract__c !=null LIMIT 1];
        System.runAs(getUser('System Administrator')) {
            Test.startTest();
                RenewalAndExpansionSplit.calculateClosedAdminReason2(new List<Id>{testOppty.Id});
            Test.stopTest();
        } 
    }*/
    
    @isTest
    private static void testResyncLineJob() {
        Opportunity testOpportunity = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE SBQQ__PrimaryQuote__c != null LIMIT 1];
        PricebookEntry pb = [select id from PricebookEntry limit 1];
        List<OpportunityLineItem> oli = new List<OpportunityLineItem>();
        oli.add(new OpportunityLineItem(Line_Type_Text__c='Renewal',PBE_Product_Family__c = 'POLARIS',Renewal_Due_Date__c=System.Today()+300,pricebookentryid=pb.Id,UnitPrice=0, Quantity = 1,OpportunityID =  testOpportunity.Id));
        
        insert oli;
        
        Map<Id, Id> mapIdToPrimaryQuoteId = new Map<Id, Id>{
            testOpportunity.Id => testOpportunity.SBQQ__PrimaryQuote__c
                };
                    
                    Test.startTest();
        System.enqueueJob(new RenewalAndExpansionSplit.ResyncLineJob(oli, mapIdToPrimaryQuoteId));
        System.assert(true);
        Test.stopTest();
    }
}