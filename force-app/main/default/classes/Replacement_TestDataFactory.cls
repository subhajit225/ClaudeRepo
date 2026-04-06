/***********************************************************************************************************
 * Class Name           : Replacement_TestDataFactory
 * Date Created/Modified: 19/06/2024
 * Author               : Garima
 * @description         : This class is used by Replacement Framework Components
 /**********************************************************************************************************/
 @isTest 
 public with sharing class Replacement_TestDataFactory {
    /***********************************************************************************************************
    * Method Name          : setTriggerSwitch
    * @description         : Trigger Switch - Custom Setting that enables or disable Triggers
    * @param vobject
    * @param value
    /**********************************************************************************************************/
    public static void setTriggerSwitch(String vobject, boolean value){
        TriggerControl__c se= TriggerControl__c.getValues(vobject);
        if(se == null){
            TriggerControl__c setting = new TriggerControl__c();
            setting.Name = vobject;
            setting.DisableTrigger__c = value;
            INSERT setting;
        }
    } 
    /***********************************************************************************************************
    * Method Name          : getUniqueName
    * @description         : creates a unique string 
    * @return              : Unique String for User record
    /**********************************************************************************************************/
    public static String getUniqueName(){
        //makes a unique email address
        String orgId= UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName= orgId + dateString + randomInt; 
        return uniqueName.toLowerCase();    
    }
    /***********************************************************************************************************
    * Method Name          : getAccount
    * @description         : Create Account 
    * @return              : Returns Account record
    * @param name
    * @param recordTypeId
    /**********************************************************************************************************/
    public static Account getAccount(String name, String recordTypeId){
        setTriggerSwitch('Account', false);
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account; 
        Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();

        Account acc= new Account();
        acc.Name = name;
        acc.recordTypeId = recordTypeId;//AccountRecordTypeInfo.get('Partner/Distributor').getRecordTypeId();
        acc.BillingCountry = 'United States';
        acc.BillingCountryCode = 'US';
        acc.BillingState = 'Washington';
        acc.BillingStateCode = 'WA';
        acc.BillingStreet = '521 E Mountain View Ave';
        acc.BillingCity = 'Ellensburg';
        acc.Is_Customer_Fully_Transitioned__c= false;
        acc.Selective_Account_Eligible_for_RCDM_T__c= true;
        acc.Eligible_for_RCDM_T__c= true;
        return acc;        
    }
    /***********************************************************************************************************
    * Method Name          : getContact
    * @description         : Primary Contact 
    * @return              : Returns Contact record
    * @param vAccount
    /**********************************************************************************************************/   
    public static Contact getContact(Account vAccount){
        setTriggerSwitch('Contact', false);
        Contact vContact = new Contact();
        vContact.LeadSource ='Email';
        vContact.LastName = 'Testlast';
        vContact.AccountId =vAccount.Id;
        String uniqueName = getUniqueName();        
        // vContact.Email= uniqueName+'@invalid.test'; - commented due to validation failure
        vContact.FirstName='firstTest'+vAccount.Id; 
        return vContact;
    }
    /***********************************************************************************************************
    * Method Name          : getOpportunity
    * @description         : Primary Opportunity creation Method
    * @return              : Returns Opportunity record
    * @param vAccount
    * @param vContact
    * @param priceBookId
    /**********************************************************************************************************/ 
    public static Opportunity getOpportunity(Account vAccount, Contact vContact, Id priceBookId){
        setTriggerSwitch('Opportunity', false);
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Opportunity; 
        Map<String,Schema.RecordTypeInfo> opportunityRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();

        Opportunity vOpportunity = new Opportunity();
        vOpportunity.Name ='New mAWS Deal';
        vOpportunity.recordTypeId = opportunityRecordTypeInfo.get('Renewal Opportunity').getRecordTypeId();
        vOpportunity.AccountId = vAccount.Id;
        vOpportunity.StageName = '1 Discovery';
        vOpportunity.Amount = 3000;
        vOpportunity.CloseDate = System.today()+30;
        vOpportunity.Type = 'New Customer';
        vOpportunity.Lead_Email_Hidden__c = vContact.Email;
        vOpportunity.Alliance_Partner_Name__c='Amazon';
        vOpportunity.Alliance_Source_Type__c='Alliance Initiated Deal';
        vOpportunity.Alliance_Source_Type_SW__c = 'Alliance Initiated Deal';
        vOpportunity.Initial_Contacts_Name__c = vContact.Id;
        vOpportunity.Deal_Registration_Type__c='Rubrik Sourced';
        vOpportunity.Champion__c = 'Champion';
        vOpportunity.Metric__c = 'Metric';
        vOpportunity.Economic_Buyer__c = 'Economic_Buyer';
        vOpportunity.Decision_Criteria__c = 'Decision_Criteria';
        vOpportunity.Decision_Process__c = 'Decision_Process';
        vOpportunity.Why_Rubrik__c = 'Why_Rubrik';
        vOpportunity.Why_do_anything__c = 'Why_do_anything';
        vOpportunity.Why_now__c = 'Why_now';
        vOpportunity.Partner_Representative__c = 'Partner_Representative';
        vOpportunity.Primary_Competitor__c = 'Avamar';
        vOpportunity.Alliance_HW_Partner__c = 'Cisco';
        vOpportunity.Alliance_Source_Type_HW__c = 'Why_do_anything';
        vOpportunity.Customer_AWS_Account_Number__c = 'Customer_AWS_Account_Number';
        vOpportunity.Customer_AWS_Account_Region__c = 'US East (N. Virginia)';
        vOpportunity.Lost_To_Won_Against__c = 'Arcserve';
        vOpportunity.Key_Feature_Needs__c = 'Other';
        vOpportunity.Other_Key_Feature_Need__c = 'Other_Key_Feature_Need';
        vOpportunity.Cloud_Type__c = 'Google';
        vOpportunity.Partner_Lookup__c= vAccount.Id;
        vOpportunity.Distributor_Lookup__c= vAccount.Id;
        vOpportunity.Pricebook2Id= priceBookId;
        return vOpportunity;
    }
    /***********************************************************************************************************
    * Method Name          : getQuote
    * @description         : Create Quote
    * @return              : Returns Quote record
    * @param accountId
    * @param opportunityId
    * @param pbId
    * @param quoteType
    /**********************************************************************************************************/ 
    public static SBQQ__Quote__c getQuote(Id accountId, Id opportunityId, Id pbId, String quoteType) {
        //setTriggerSwitch('SBQQ__Quote__c', false);
        return new SBQQ__Quote__c (
                SBQQ__Account__c = accountId,
                SBQQ__Opportunity2__c = opportunityId,
                SBQQ__Primary__c = true,
                SBQQ__PriceBook__c = pbId, //Test.getStandardPricebookId(),
                SBQQ__PricebookId__c = pbId,
                SBQQ__ExpirationDate__c = System.today(),
                SBQQ__StartDate__c = Date.Today(),
                Task_Products__c='RBK-DISK-RETENTION',
                SBQQ__SubscriptionTerm__c = 36 ,
                GPL_Deal__c='test',
                OpportunitySubType__c= 'test',
                RWD_Deal_Ops_Exception_Justification__c= 'Test Justification',
                RWD_Deal_Ops_Exception__c= 'Annual Products min/max 36',
                RCDMT_EOL_Date__c= System.today()+5,
                SBQQ__Type__c= quoteType
            );
    }
    /***********************************************************************************************************
    * Method Name          : getQuoteLine
    * @description         : Create QuoteLine
    * @return              : Returns Quote Line record
    * @param assetId
    * @param asst
    * @param quoteId
    * @param productId
    * @param contractLineItemId
    /**********************************************************************************************************/ 
    public static SBQQ__QuoteLine__c getQuoteLine(Id assetId, Asset asst, Id quoteId, Id productId, Id contractLineItemId ) {
        /*String replacementDetails = '{"rowValues":[{"selectedAssetList":["'+assetId
                                    + '"], "selectedQty": 1, "selectedAssetNames": ["'+asst.name+'"]}]}';*/

        String replacementDetails = '{"skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","InactiveLines":null,"entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12,"AnyToAnyFlag":null}],"mode":"1to1"}';
        
        SBQQ__QuoteLine__c qli= new SBQQ__QuoteLine__c(
                                                    SBQQ__SubscribedAssetIds__c=assetId,
                                                    SBQQ__Quote__c = quoteId, 
                                                    SBQQ__Product__c = productId, 
                                                    SBQQ__Quantity__c = 1, 
                                                    SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, 
                                                    SBQQSC__RenewedContractLine__c = contractLineItemId,
                                                    CCLI__c= String.valueOf(contractLineItemId),
                                                    SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,
                                                    Product_SubType__c= 'GO CNV', Product_Type__c = 'HW Support',
                                                    SBQQ__SubscriptionTerm__c= 12, Product_Level__c='Hybrid Software',
                                                    Subscribed_Asset_Name__c= asst.name, SubscribedAssetNames__c= asst.SerialNumber,
                                                    Replacement_Details__c= replacementDetails );
        return qli;
    }
    /***********************************************************************************************************
    * Method Name          : getQuoteLineGroup
    * @description         : Create QuoteLineGroup
    * @return              : Returns Quote Line Group record
    * @param quoteId
    /**********************************************************************************************************/ 
    public static SBQQ__QuoteLineGroup__c getQuoteLineGroup(Id quoteId) {
        return new SBQQ__QuoteLineGroup__c
            (Name='Test Group', SBQQ__Number__c= 2, 
            SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
            SBQQ__NetTotal__c= 200, SBQQ__Quote__c= quoteId);
    }
    /***********************************************************************************************************
    * Method Name          : getProduct
    * @description         : Create Product
    * @return              : Returns Product record
    * @param strName
    * @param proCode
    * @param edition
    * @param repCategory
    * @param licenseType
    * @param productType
    * @param licCategory
    /**********************************************************************************************************/
    public static Product2 getProduct(String strName, String proCode, String edition,String repCategory,String licenseType,String productType, String licCategory) {
        setTriggerSwitch('Product2', false);
        Product2 prod= new Product2 (
                Name = strName,
                ProductCode = proCode,
                Edition__c = edition,
                Replacement_Category__c = repCategory,
                License_Type__c =  licenseType,
                Product_Type__c = productType,
                License_Category__c = licCategory,
                isActive = True,
                SBQQ__SubscriptionType__c = 'Renewable',
                After_Conversion_Product_Level__c= 'Hybrid Software',
                Product_Level__c= 'LOD Software',
                Eligible_for_RCDM_T__c= true,
                Support_Type__c = 'Proactive',
                Product_Payment_Option__c = 'Annual'); 
        return prod;
    }
    /***********************************************************************************************************
    * Method Name          : getv1Product
    * @description         : Creates V1 Product
    * @return              : Returns Product record
    * @param strName
    * @param proCode
    * @param edition
    * @param repCategory
    * @param licenseType
    * @param productType
    * @param licCategory
    /**********************************************************************************************************/
    public static Product2 getv1Product(String strName, String proCode, String edition,String repCategory,String licenseType,String productType, String licCategory) {
        setTriggerSwitch('Product2', false);
        Product2 prod= new Product2 (
                Name = strName,
                ProductCode = proCode,
                Edition__c = edition,
                Replacement_Category__c = repCategory,
                License_Type__c =  licenseType,
                Product_Type__c = productType,
                License_Category__c = licCategory,
                isActive = True,
                SBQQ__SubscriptionType__c = 'Renewable',
                After_Conversion_Product_Level__c= 'Hybrid Software',
                Eligible_for_RCDM_T__c= true,
                Support_Type__c = 'Proactive',
                Product_Payment_Option__c = 'Annual'); 
        return prod;
    }
    /***********************************************************************************************************
    * Method Name          : getProductWithSubCategory
    * @description         : Creates Product
    * @return              : Returns Product record
    * @param strName
    * @param proCode
    * @param edition
    * @param repCategory
    * @param licenseType
    * @param productType
    * @param licCategory
    * @param subCategory 
    /**********************************************************************************************************/
    public static Product2 getProductWithSubCategory(String strName, String proCode, String edition,String repCategory,String licenseType,String productType, String licCategory, String subCategory) {
        setTriggerSwitch('Product2', false);
        Product2 prod= new Product2 (
                Name = strName,
                ProductCode = proCode,
                Edition__c = edition,
                Replacement_Category__c = repCategory,
                License_Type__c =  licenseType,
                Product_Type__c = productType,
                License_Category__c = licCategory,
                isActive = True,
                SBQQ__SubscriptionType__c = 'Renewable',
                After_Conversion_Product_Level__c= 'Hybrid Software',
                License_Sub_Category__c = subCategory,
                Product_Level__c= 'LOD Software',
                Eligible_for_RCDM_T__c= true,
                Support_Type__c = 'Proactive',
                Product_Payment_Option__c = 'Annual'); 
        return prod;
    }
    /***********************************************************************************************************
    * Method Name          : getProductWithSubCategory
    * @description         : Create Product - Used with different paramaters
    * @return              : Returns Product record
    * @param strName
    * @param proCode
    * @param productLevel
    * @param productType
    * @param supportType
    /**********************************************************************************************************/
    public static Product2 getProduct(String strName, String proCode, String productLevel, String productType, String supportType) {
        setTriggerSwitch('Product2', false);
        Product2 prod= new Product2 (
                Name= strName,
                ProductCode= proCode,
                Product_level__c= productLevel,
                Product_Type__c= productType,
                Support_Type__c= supportType,
                isActive = True); 
        return prod;
    }
    /***********************************************************************************************************
    * Method Name          : getPOC
    * @description         : Create POC
    * @return              : Returns POC record
    * @param accId
    * @param oppId
    /**********************************************************************************************************/
    public static POC__c getPOC(Id accId, Id oppId){
        POC__c pc = new POC__c();
        pc.POC_Duration__c = '60 Days';
        pc.Planned_Installation_Date__c = System.Today()+30;
        pc.Support_Awareness_needed__c = 'Yes';
        pc.POC_Type__c = 'Standard POC';
        pc.Planned_Installation_Date__c =  System.Today()+40;
        pc.Account__c = accId;
        pc.Opportunity__c = oppId;
        return pc;
    }
    /***********************************************************************************************************
    * Method Name          : getPriceBook
    * @description         : Create PriceBook
    * @return              : Returns PriceBook record
    /**********************************************************************************************************/
    public static Pricebook2 getPriceBook() {
        return new Pricebook2(Name = 'CPQ PriceBook', Description = 'Price Book 2024 Products 1', IsActive = true);
    }
    /***********************************************************************************************************
    * Method Name          : getPriceBookEntry
    * @description         : Create PriceBookEntry
    * @return              : Returns PriceBookEntry record
    * @param listProductId
    * @param pbId
    /**********************************************************************************************************/
    public static PriceBookEntry getPriceBookEntry(Id listProductId, Id pbId) {
        return new PricebookEntry (
                Product2Id = listProductId,
                Pricebook2Id = pbId,//Test.getStandardPricebookId(),
                UnitPrice = 100,
                IsActive = True,
                UseStandardPrice = false);
    }
    /***********************************************************************************************************
    * Method Name          : getOrder
    * @description         : Create Order
    * @return              : Returns Order record
    * @param accountId
    * @param opportunityId
    * @param pbId
    /**********************************************************************************************************/
    public static Order getOrder(Id accountId, Id opportunityId, Id pbId){
        setTriggerSwitch('Order', false);
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = accountId;
        od.OpportunityId = opportunityId;
        od.EffectiveDate = Date.Today();
        od.Type = 'Revenue';
       // od.Order_Status__c='Pending';
       // od.Hold_Code__c='Missing Distributor Acceptance of Addl Quote Terms';
        od.Est_Ship_Date__c = System.today();
        //od.POC_Request__c = pocId;
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pbId;//Test.getStandardPricebookId();
        return od;
    }
    /***********************************************************************************************************
    * Method Name          : getOrderItem
    * @description         : Create OrderItem
    * @return              : Returns Order Item record
    * @param prodId
    * @param orderId
    * @param entryId
    /**********************************************************************************************************/
    public static OrderItem getOrderItem(Id prodId, Id orderId, Id entryId) {
        
        return new OrderItem(product2Id = prodId,Support_Start_Date__c =System.today(),
                            Support_End_Date__c  =System.today()+2, orderid = orderId, 
                            Quantity = 2, PricebookEntryId = entryId, UnitPrice = 100, 
                            SBQQ__ProductSubscriptionType__c='Renewable', SBQQ__SubscriptionType__c ='Renewable');
    }
    /***********************************************************************************************************
    * Method Name          : getAsset
    * @description         : Create Asset
    * @return              : Returns Asset record
    * @param name
    * @param productId
    * @param accountId
    /**********************************************************************************************************/
    public static Asset getAsset(String name, Id productId, Id accountId) {
        
        return new Asset(AccountId =accountId,
                        Name = name,
                        Product2Id = productId,
                        licensed_capacity__c = 10,
                        Eligible_for_Free_HW__c = 'True',
                        Justification_for_HW_Eligibility_Overrid__c = '-',
                        SerialNumber = 'JAY8486304222');
    }  
    /***********************************************************************************************************
    * Method Name          : getServiceContract
    * @description         : Create ServiceContract
    * @return              : Returns Service Contract record
    * @param accountId
    * @param oppId
    * @param pbId
    /**********************************************************************************************************/  
    public static ServiceContract getServiceContract(Id accountId, Id oppId, Id pbId) {
        ServiceContract serviceContractObj= new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppId;
        serviceContractObj.AccountId = accountId;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = pbId;
        serviceContractObj.Term = 36;
        return serviceContractObj;
    }
    /***********************************************************************************************************
    * Method Name          : getContractLineItem
    * @description         : Create ContractLineItem
    * @return              : Returns Contract LineItem record
    * @param accountId
    * @param assetId
    * @param pbEntryId
    * @param serContractId
    /**********************************************************************************************************/  
    public static ContractLineItem getContractLineItem(Id accountId, Id assetId, Id pbEntryId, Id serContractId) {
        ContractLineItem ContractLineItemObj = new ContractLineItem();
        ContractLineItemObj.SBQQSC__Account__c = accountId;
        ContractLineItemObj.AssetId = assetId;
        ContractLineItemObj.PricebookEntryId = pbEntryId;
        ContractLineItemObj.ServiceContractId = serContractId;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 2;
        ContractLineItemObj.StartDate = System.Today();
        ContractLineItemObj.EndDate = System.Today().addDays(12);
        return ContractLineItemObj;
    }
    /***********************************************************************************************************
    * Method Name          : getEntitlement
    * @description         : Create Entitlement
    * @return              : Returns Entitlement record
    * @param name
    * @param accountId
    * @param productId
    * @param assetId
    * @param orderProductId
    * @param servContractId
    * @param contrLineItemId
    /**********************************************************************************************************/  
    public static Entitlement getEntitlement(String name, Id accountId, Id productId, Id assetId, Id orderProductId, Id servContractId, Id contrLineItemId) {
        setTriggerSwitch('Entitlement', false);
        String recordTypeEntId= Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        Entitlement ent = new Entitlement();
        ent.Name= name;
        ent.AccountId = accountId;
        ent.Product__c = productId;
        ent.AssetId= assetId;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.Type ='Phone Support';
        ent.Renewal_Category__c= null;
        //ent.Terminated_Date__c= null;
        ent.Order_Service_Item__c= orderProductId;
        ent.ServiceContractId= servContractId;
        ent.ContractLineItemId= contrLineItemId;
        ent.RecordTypeId=recordTypeEntId;
        return ent;
    }
    /***********************************************************************************************************
    * Method Name          : getScaleEntitlement
    * @description         : Create Scale Entitlement related to Entitlement
    * @return              : Returns Scale Entitlement record
    * @param entitlementId
    * @param assetId
    /**********************************************************************************************************/  
    public static Scale_Entitlement__c getScaleEntitlement(Id entitlementId, Id assetId) {
        setTriggerSwitch('Scale_Entitlement__c', false);
        Scale_Entitlement__c scaleEnt = new Scale_Entitlement__c();
        scaleEnt.Entitlement__c = entitlementId;
        scaleEnt.Asset__c = assetId;
        return scaleEnt;
    }
    /***********************************************************************************************************
    * Method Name          : getScaleEntitlement
    * @description         : Create Polaris SKU Mapping
    * @return              : Returns Polaris mapping record
    * @param oldProdId
    * @param newProdId
    /**********************************************************************************************************/  
    public static Polaris_SKU_Mapping_V2__c getPolarisSKUMapping(Id oldProdId, Id newProdId) {
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = new Polaris_SKU_Mapping_V2__c();
        polarisSKUMappingObj.Name= 'Test Polaris';
        polarisSKUMappingObj.Old_Product__c = oldProdId;
        polarisSKUMappingObj.New_Product__c = newProdId;
        polarisSKUMappingObj.Support_Tier__c= 'E1';
        polarisSKUMappingObj.Quantity_Mapping_Type__c= 'Ratio Based';
        polarisSKUMappingObj.Quantity_Ratio__c =2;
        polarisSKUMappingObj.Support_Type__c = 'L3';
        polarisSKUMappingObj.Payment_Option__c = 'Annual';
        return polarisSKUMappingObj;
    }
    /***********************************************************************************************************
    * Method Name          : getMultiMappingV2Conversion
    * @description         : Create Multi Mapping V2 Conversion
    * @return              : Returns Multi mapping record
    * @param oldProdId
    * @param newProdId
    /**********************************************************************************************************/
    public static Multi_Mapping_V2_Conversion__c getMultiMappingV2Conversion(Id oldProdId, Id newProdId) {
        Multi_Mapping_V2_Conversion__c mappingConvObj= new Multi_Mapping_V2_Conversion__c();
        mappingConvObj.Name= 'Test Mapping Conversion';
        mappingConvObj.Source_Product__c= oldProdId;
        mappingConvObj.Target_Product__c= newProdId;
        return mappingConvObj;
    }
    /***********************************************************************************************************
    * Method Name          : getPolicyGridValues
    * @description         : Create Replacement Support for policy grid
    * @return              : Returns Replacement Support record
    * @param srcRep
    * @param targetRep
    * @param stDate
    * @param EtDate
    /**********************************************************************************************************/
     public static Replacement_Support__c getPolicyGridValues(String srcRep, String targetRep, Date stDate, Date EtDate){
        Id recTypeId = Schema.getGlobalDescribe().get('Replacement_Support__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Replacement_Category_Matrix').getRecordTypeId();
        return new Replacement_Support__c(Source_Replacement_Category__c = srcRep,
                                  Target_Replacement_Category__c = targetRep,
                                  Start_Date__c = stDate,
                                  End_Date__c = EtDate,        
                                  RecordTypeId = recTypeId);
    }
    /***********************************************************************************************************
    * Method Name          : getDispositionChange
    * @description         : Create Replacement Support for Disposition change
    * @return              : Returns Replacement Support record
    * @param sourceEdition
    * @param targetEdition
    * @param Path
    * @param stDate
    * @param EtDate
    * @param recordtypeId
    /**********************************************************************************************************/
     public static Replacement_Support__c getDispositionChange(String sourceEdition, String targetEdition, String Path, Date stDate, Date EtDate, Id recordtypeId){    
         Replacement_Support__c rc = new Replacement_Support__c();
         rc.Source_Edition__c = sourceEdition;
         rc.Target_Edition__c = targetEdition;
         rc.Start_Date__c = stDate;
         rc.End_Date__c = EtDate;
         rc.Path__c = path;
         if(recordtypeId != NULL){
            rc.RecordTypeId = recordtypeId; 
         }         
        return rc;
    }
    /***********************************************************************************************************
    * Method Name          : getEntitlementLinks
    * @description         : To create Entitlement linkages
    * @return              : Returns Entitlement Link record
    * @param prevEntId
    * @param renewEntId
    /**********************************************************************************************************/
     public static Entitlement_Links__c getEntitlementLinks(Id prevEntId, Id renewEntId){
        Entitlement_Links__c entLink = new Entitlement_Links__c ();
        entLink.Previous_Entitlement__c = prevEntId;
        entLink.Renewed_Entitlement__c = renewEntId;
        return entLink;
     }
    /***********************************************************************************************************
    * Method Name          : getWrappers
    * @description         : To create Wrapper Instances
    * @return              : Returns Wrapper Instances
    * @param ent
    * @param typeofSKU
    * @param mapEntitlemmemntNameToScaleEntitlements
    * @param prodResult
    /**********************************************************************************************************/
    public static ReplacementRefreshWrapperData.WrapperData  getWrappers (Entitlement ent , String typeofSKU, Map<String, List<Scale_Entitlement__c>>  mapEntitlemmemntNameToScaleEntitlements, List<Product2> prodResult){
        Map<String, List<Entitlement>> dummyMap = new Map<String, List<Entitlement>>();
        List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
        ReplacementRefreshWrapperData.WrapperData wrapToReturn = new ReplacementRefreshWrapperData.WrapperData();
        ReplacementRefreshWrapperData.pickList objpickListAll = ReplacementRefreshWrapperData.createpicKlistValues('Full', 'Full',ent.Id,ent.Name,0,true,false,false,true);
        assetsAvailable.add(objpickListAll);
        ReplacementRefreshWrapperData.pickList objpickListAll1 = ReplacementRefreshWrapperData.createpicKlistValues(String.valueOf(ent.Asset.ID), 'Asset123',String.valueOf(ent.Id),ent.Name,0,true,false,false,true);
        assetsAvailable.add(objpickListAll1);
        
        if (typeofSKU == 'v1') {
            ReplacementRefreshWrapperData.WrapperData wrapv1Data = ReplacementRefreshUtility.formCommonWrapper (ent, mapEntitlemmemntNameToScaleEntitlements);
            //wrapv1Data.mapAssetEntitlements = dummyMap;
            wrapv1Data.consumedquantity = 1.0;
            wrapv1Data.disableDisposition = false;
            wrapv1Data.skuProductId = prodResult[1].Id;
            wrapv1Data.skuProdName = prodResult[1].Name;
            wrapv1Data.skuProdRepCategory = prodResult[1].Replacement_Category__c;
            wrapv1Data.skuProdLicenseSubCategory = prodResult[1].License_Sub_Category__c;
            wrapv1Data.skuStorBackBundleValue = '';
            wrapv1Data.skuStorFrontBundleValue = '';
            wrapv1Data.skuStorTierValue = '';
            wrapv1Data.skuProdCodeType = prodResult[1].Product_Code_Type__c;
            wrapv1Data.quantityAssetType = true; 
            wrapv1Data.targetProductType = 'Non-Hardware';
            wrapv1Data.assetsAvailable = new List<ReplacementRefreshWrapperData.pickList>(assetsAvailable);
            List<ReplacementRefreshWrapperData.pickList> lstAssetNonAsset = new List<ReplacementRefreshWrapperData.pickList>(); 
            if (wrapv1Data.assetsAvailable != null && !wrapv1Data.assetsAvailable.isEmpty()) {
                for (ReplacementRefreshWrapperData.pickList pick : wrapv1Data.assetsAvailable) {
                    pick.selected = true;
                  //  if(pick.value != 'Full'){
                 //      lstAssetNonAsset.add(pick);
                 //   }
                }
               // wrapv1Data.selectedAssetsFromNonAsset = lstAssetNonAsset;
            }
            /*ReplacementRefreshWrapperData.pickList pick1 = new ReplacementRefreshWrapperData.pickList();
            pick1.selected = true;
            pick1.label= ent.Asset.Name+' ('+ent.Asset.Product2.Name+') (10.00)';
            pick1.value=ent.AssetId;
            pick1.entitlementId = ent.Id;
            pick1.quantity= 10;
            lstAssetNonAsset.add(pick1);*/
            wrapv1Data.selectedAssetsFromNonAsset = lstAssetNonAsset;
            wrapToReturn = wrapv1Data;
        }
        else if (typeofSKU == 'HWSupp') {
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData = ReplacementRefreshUtility.formCommonWrapper (ent, mapEntitlemmemntNameToScaleEntitlements);
            wrapHWSuppData.isModified = true;
            wrapHWSuppData.rowSelected = true;
            wrapHWSuppData.selecteddisposition = 'Renewing';
            wrapHWSuppData.consumedquantity = 10;
            wrapHWSuppData.quantity = 10;
            wrapHWSuppData.selectedquantity = 10;
            wrapHWSuppData.quantityAssetType = false; 
            wrapHWSuppData.targetProductType = null;
            wrapToReturn = wrapHWSuppData;
        } else if (typeofSKU == 'InactiveEnt') {
            ReplacementRefreshWrapperData.WrapperData wrapInactiveData =  ReplacementRefreshUtility.formCommonWrapper (ent, mapEntitlemmemntNameToScaleEntitlements);
            wrapInactiveData.isModified = true;
            wrapInactiveData.rowSelected = true;
            wrapInactiveData.consumedquantity = 10;
            wrapInactiveData.quantity = 10;
            wrapInactiveData.selectedquantity = 10;
            wrapInactiveData.quantityAssetType = false; 
            wrapInactiveData.targetProductType = null;
            wrapToReturn = wrapInactiveData;
        } else if (typeofSKU == 'UpgradeSKU') {
            ReplacementRefreshWrapperData.WrapperData wrapUGData = ReplacementRefreshUtility.formCommonWrapper (ent, mapEntitlemmemntNameToScaleEntitlements);
            wrapUGData.isModified = true;
            wrapUGData.rowSelected = true;
            wrapUGData.skuProductId = prodResult[1].Id;
            wrapUGData.selecteddisposition = 'Renew Later';
            wrapUGData.consumedquantity = 10;
            wrapUGData.quantity = 10;
            wrapUGData.selectedquantity = 10;
            //wrapUGData.mapAssetEntitlements = dummyMap;
            wrapUGData.consumedquantity = 1.0;
            wrapUGData.disableDisposition = false;
            wrapUGData.skuProductId = prodResult[1].Id;
            wrapUGData.skuProdName = prodResult[1].Name;
            wrapUGData.skuProdRepCategory = prodResult[1].Replacement_Category__c;
            wrapUGData.skuProdLicenseSubCategory = prodResult[1].License_Sub_Category__c;
            wrapUGData.skuStorBackBundleValue = '';
            wrapUGData.skuStorFrontBundleValue = '';
            wrapUGData.skuStorTierValue = '';
            wrapUGData.skuProdCodeType = prodResult[1].Product_Code_Type__c;
            wrapUGData.assetsAvailable = new List<ReplacementRefreshWrapperData.pickList>(assetsAvailable);
            if (wrapUGData.assetsAvailable != null && !wrapUGData.assetsAvailable.isEmpty()) {
                for (ReplacementRefreshWrapperData.pickList pick : wrapUGData.assetsAvailable) {
                    pick.selected = true;
                }
            }
            wrapUGData.quantityAssetType = false; 
            wrapUGData.targetProductType = null;
            wrapToReturn = wrapUGData;
        }
        else if (typeofSKU == 'default') {
            ReplacementRefreshWrapperData.WrapperData wrapData = ReplacementRefreshUtility.formCommonWrapper (ent, mapEntitlemmemntNameToScaleEntitlements);
            wrapData.isModified = true;
            wrapData.rowSelected = true;
            wrapData.skuProductId = prodResult[1].Id;
            wrapData.selecteddisposition = 'Renew Later';
            wrapData.consumedquantity = 10;
            wrapData.quantity = 10;
            wrapData.selectedquantity = 10;
            //wrapData.mapAssetEntitlements = dummyMap;
            wrapData.consumedquantity = 1.0;
            wrapData.disableDisposition = false;
            wrapData.skuProductId = prodResult[1].Id;
            wrapData.skuProdName = prodResult[1].Name;
            wrapData.skuProdRepCategory = prodResult[1].Replacement_Category__c;
            wrapData.skuProdLicenseSubCategory = prodResult[1].License_Sub_Category__c;
            wrapData.skuStorBackBundleValue = '';
            wrapData.skuStorFrontBundleValue = '';
            wrapData.skuStorTierValue = '';
            wrapData.skuProdCodeType = prodResult[1].Product_Code_Type__c;
            List<ReplacementRefreshWrapperData.pickList> lstAssetNonAsset = new List<ReplacementRefreshWrapperData.pickList>();            
            wrapData.assetsAvailable = new List<ReplacementRefreshWrapperData.pickList>(assetsAvailable);
            if (wrapData.assetsAvailable != null && !wrapData.assetsAvailable.isEmpty()) {
                for (ReplacementRefreshWrapperData.pickList pick : wrapData.assetsAvailable) {
                    pick.selected = true;
                   // if(pick.value != 'Full'){
                  //      lstAssetNonAsset.add(pick);
                  //  }
                }  
                //lstAssetNonAsset.addAll(wrapData.assetsAvailable);
            }
          	/*ReplacementRefreshWrapperData.pickList pick1 = new ReplacementRefreshWrapperData.pickList();
            pick1.selected = true;
            pick1.label= ent.Asset.Name+' ('+ent.Asset.Product2.Name+') (10.00)';
            pick1.value=ent.AssetId;
            pick1.entitlementId = ent.Id;
            pick1.quantity= 10;
            lstAssetNonAsset.add(pick1);*/
            wrapData.selectedAssetsFromNonAsset = lstAssetNonAsset;
            wrapData.quantityAssetType = true;
            wrapData.targetProductType = 'Hardware';
            wrapToReturn = wrapData;
        }
        return wrapToReturn;
    }
    /***********************************************************************************************************
    * Method Name          : getUser
    * @description         : To create User
    * @return              : Returns User record
    /**********************************************************************************************************/
    public static User getUser(){
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr1 = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName,
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );
        return usr1;
    }
}