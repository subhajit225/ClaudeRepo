/***********************************************************************************************************
* Class Name           : ConvertToSaasRenewalBatchTest
* Date Created/Modified: 27/07/2025
* Author               : Sumedha
* @description         : Test class for ConvertToSaasRenewalBatch
* Test Class           :

/**********************************************************************************************************/

@isTest
private class ConvertToSaasRenewalBatchTest {
    
    /***********************************************************************************************************
* Method Name          : newSaasTestProBundle
* Date Created/Modified: 25/07/2025
* @description         : Test conversion
/**********************************************************************************************************/
    static  testMethod void newSaasTestProBundle(){
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Entitlement';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(
            Disable_SBQQ_Quote_Validation_Rules__c = True,
            Disable_SBQQ_Quote_Triggers__c = True,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
            //     Disable_SBQQ_QuoteLine_Triggers__c = True,
            Disable_Opportunity_Validation_Rules__c = True,
            Disable_Opportunity_Triggers__c = True,
            Disable_Campaign_Member_Triggers__c = true,
            Disable_Campaign_Trigger__c = true,
            Disable_Campaign_Validation_Rules__c = true,
            Disable_Order_Validation_Rules__c=true, 
            Disable_ServiceContract_Trigger__c=true,
            Disable_Entitlement_Usage_Trigger__c=true,
            Disable_Entitlement_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c = true,
            Disable_Entitlement_Validation_Rules__c = true,
            setupownerid = usr1.Id,
            Disable_Asset_Triggers__c=true,
            Disable_SBQQ_QuoteLine_Triggers__c = true
        );    
        insert cdf;
        /*User runningUser = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];
UPSERT new ShGl_DisableBusinessLogic__c(
SetupOwnerId = runningUser.Id,
Disable_Entitlement_Validation_Rules__c = true,
Disable_Order_Validation_Rules__c=true
); */
        System.runAs(usr1) {
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Eligible_for_RCDM_T__c = true;
            insert act; 
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c =pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                     PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__RenewalTerm__c = 12);
            
            insert serviceContractObj;
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size());
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};    
                
                Map<String, Object> testProd = new Map<String, Object> {
                    'Name' => 'RBK-SUB-PRO-R6410S-01-RENEW',
                        'ProductCode' => 'RBK-SUB-PRO-R6410S-01-RENEW',
                        'IsActive' => true,
                        'After_Conversion_Product_Level__c' => 'Support' //5388
                        };
                            Map<String, Object> p1 = new Map<String, Object> {
                                'Name' => 'RS-BT-RCDM-T',
                                    'ProductCode' => 'RS-BT-RCDM-T',
                                    'IsActive' => true,
                                    'Usable_Capacity__c' => 75
                                    
                                    }; 
                                        
                                        Map<String, Object> p2 = new Map<String, Object> {
                                            'Name' => 'RBK-SUB-PRO-R6410S-01-RENEWAL',
                                                'ProductCode' => 'RBK-SUB-PRO-R6410S-01-RENEWAL',
                                                'IsActive' => true,
                                                'After_Conversion_Product_Level__c' => 'PROBUNDLE' //PROBUNDLE
                                                };
                                                    
                                                    Map<String, Object> p3 = new Map<String, Object> {
                                                        'Name' => 'RBK-NAS-D-A',
                                                            'ProductCode' => 'RBK-NAS-D-A',
                                                            'IsActive' => true,
                                                            'After_Conversion_Product_Level__c' =>  'SaaS Software Addon'
                                                            };
                                                                Map<String, Object> hwSupp = new Map<String, Object> {
                                                                    'Name' => 'RBK-SVC-PREM-SW',
                                                                        'ProductCode' => 'RBK-SVC-PREM-SW',
                                                                        'IsActive' => true,
                                                                        'After_Conversion_Product_Level__c' => 'Support',
                                                                        'Product_Type__c' => 'RCDM Support'
                                                                        };
                                                                            
                                                                            Map<String, Object> mulMap1 = new Map<String, Object> {
                                                                                'Name' => 'RS-BT-BE-PE-PP',
                                                                                    'ProductCode' => 'RS-BT-BE-PE-PP',
                                                                                    'IsActive' => true,
                                                                                    'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                    'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                    //   'Usable_Capacity__c'=> 12,
                                                                                    'Product_level__c' => 'Hybrid Software',
                                                                                    'Product_type__c' => 'Business Edition',
                                                                                    'Product_Payment_Option__c'=> 'Prepay',
                                                                                    'Support_Type__c'=>'Premium',
                                                                                    'Eligible_for_RCDM_T__c'=> true
                                                                                    };
                                                                                        Map<String, Object> p4 = new Map<String, Object> {
                                                                                            'Name' => 'RS-HW-SVC-PE-SE1',
                                                                                                'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                                                                'IsActive' => true,
                                                                                                //      'Usable_Capacity__c'=> 12,
                                                                                                'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                'Product_level__c' => 'Support',
                                                                                                'Product_type__c' => 'HW Support',
                                                                                                //    'Payment_Options__c'=> 'Prepay',
                                                                                                'Support_Type__c'=>'Premium',
                                                                                                'Support_Tier__c' => 'SE1'
                                                                                                // 'SBQQ__RenewalProduct__c' => ''
                                                                                                }; 
                                                                                                    Map<String, Object> mulMap2 = new Map<String, Object> {
                                                                                                        'Name' => 'RH-6304S-01',
                                                                                                            'ProductCode' => 'RH-6304S-01',
                                                                                                            'IsActive' => true,
                                                                                                            'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                            'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                            //   'Usable_Capacity__c'=> 12,
                                                                                                            'Product_level__c' => 'Hardware',
                                                                                                            'Product_type__c' => 'Hardware',
                                                                                                            'Product_Payment_Option__c'=> 'Prepay',
                                                                                                            'Support_Type__c'=>'Premium',
                                                                                                            'Usable_Capacity__c' => 75
                                                                                                            // 'SBQQ__RenewalProduct__c' => ''
                                                                                                            };
                                                                                                                
                                                                                                                
                                                                                                                Map<String, Object> mulMap3 = new Map<String, Object> {
                                                                                                                    'Name' => 'RS-HW-SVC-PE-S1',
                                                                                                                        'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                                                                                        'IsActive' => true,
                                                                                                                        //      'Usable_Capacity__c'=> 12,
                                                                                                                        'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                        'Product_level__c' => 'Support',
                                                                                                                        'Product_type__c' => 'HW Support',
                                                                                                                        'Product_Payment_Option__c'=> 'Prepay',
                                                                                                                        'Support_Type__c'=>'Premium'
                                                                                                                        // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                        }; 
                                                                                                                            
                                                                                                                            
                                                                                                                            Map<String, Object> mulMap4 = new Map<String, Object> {
                                                                                                                                'Name' => 'RS-BE-ADN-PE-PP',
                                                                                                                                    'ProductCode' => 'RS-BE-ADN-PE-PP',
                                                                                                                                    'IsActive' => true,
                                                                                                                                    'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                    'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                    //   'Usable_Capacity__c'=> 12,
                                                                                                                                    'Product_level__c' => 'SaaS Software Addon',
                                                                                                                                    'Product_type__c' => 'Business Edition',
                                                                                                                                    'Product_Payment_Option__c'=> 'Prepay',
                                                                                                                                    'Support_Type__c'=>'Premium'
                                                                                                                                    // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                    };   
                                                                                                                                        
                                                                                                                                        
                                                                                                                                        Map<String, Object> mulMap5 = new Map<String, Object> {
                                                                                                                                            'Name' => 'RS-HW-SVC-L3-S1',
                                                                                                                                                'ProductCode' => 'RS-HW-SVC-L3-S1',
                                                                                                                                                'IsActive' => true,
                                                                                                                                                'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                //  'Usable_Capacity__c'=> 12,
                                                                                                                                                'Product_level__c' => 'Support',
                                                                                                                                                'Product_type__c' => 'HW Support',
                                                                                                                                                //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                'Support_Type__c'=>'L3'
                                                                                                                                                // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                };
                                                                                                                                                    
                                                                                                                                                    Map<String, Object> mulMap6 = new Map<String, Object> {
                                                                                                                                                        'Name' => 'RS-BT-SW-SVC-L3',
                                                                                                                                                            'ProductCode' => 'RRS-BT-SW-SVC-L3',
                                                                                                                                                            'IsActive' => true,
                                                                                                                                                            'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                            'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                            //   'Usable_Capacity__c'=> 12,
                                                                                                                                                            'Product_level__c' => 'Support',
                                                                                                                                                            'Product_type__c' => 'RCDM Support',
                                                                                                                                                            //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                            'Support_Type__c'=>'Premium'
                                                                                                                                                            // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                            };
                                                                                                                                                                
                                                                                                                                                                Map<String, Object> mulMap7 = new Map<String, Object> { 
                                                                                                                                                                    'Name' => 'RS-BT-SW-SVC-PE',
                                                                                                                                                                        'ProductCode' => 'RS-BT-SW-SVC-PE',
                                                                                                                                                                        'IsActive' => true,
                                                                                                                                                                        'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                        //    'Usable_Capacity__c'=> 12,
                                                                                                                                                                        'Product_level__c' => 'Support',
                                                                                                                                                                        'Product_type__c' => 'RCDM Support',
                                                                                                                                                                        //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                        'Support_Type__c'=>'Premium',
                                                                                                                                                                        'Eligible_for_RCDM_T__c'=> true
                                                                                                                                                                        // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                        };
                                                                                                                                                                            
                                                                                                                                                                            Map<String, Object> mulMap8 = new Map<String, Object> { 
                                                                                                                                                                                'Name' => 'RH-6304S-01',
                                                                                                                                                                                    'ProductCode' => 'RH-6304S-01',
                                                                                                                                                                                    'IsActive' => true,
                                                                                                                                                                                    'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                    'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                    //   'Usable_Capacity__c'=> 12,
                                                                                                                                                                                    'Product_level__c' => 'Hardware',
                                                                                                                                                                                    'Product_type__c' => 'Hardware',
                                                                                                                                                                                    'Usable_Capacity__c' => 75,
                                                                                                                                                                                    //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                    'Support_Type__c'=>'Premium'
                                                                                                                                                                                    // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                    };
                                                                                                                                                                                        
                                                                                                                                                                                        Map<String, Object> mulMap9 = new Map<String, Object> {    
                                                                                                                                                                                            'Name' => 'RS-HW-SVC-PE-S1',
                                                                                                                                                                                                'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                                                                                                                                                                'IsActive' => true,
                                                                                                                                                                                                'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                //   'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                'Product_level__c' => 'Support',
                                                                                                                                                                                                'Product_type__c' => 'HW Support',
                                                                                                                                                                                                //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                'Support_Type__c'=>'Premium'
                                                                                                                                                                                                // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                };   
                                                                                                                                                                                                    
                                                                                                                                                                                                    Map<String, Object> mulMap10 = new Map<String, Object> {   
                                                                                                                                                                                                        'Name' => 'RS-BE-ADN-PE-PA',
                                                                                                                                                                                                            'ProductCode' => 'RS-BE-ADN-PE-PA',
                                                                                                                                                                                                            'IsActive' => true,
                                                                                                                                                                                                            'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                            'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                            //  'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                            'Product_level__c' => 'SaaS Software Addon',
                                                                                                                                                                                                            'Product_type__c' => 'Business Edition',
                                                                                                                                                                                                            //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                            'Support_Type__c'=>'Premium'
                                                                                                                                                                                                            // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                            };     
                                                                                                                                                                                                                
                                                                                                                                                                                                                Map<String, Object> mulMap11 = new Map<String, Object> {    
                                                                                                                                                                                                                    'Name' => 'RH-6304S-01',
                                                                                                                                                                                                                        'ProductCode' => 'RH-6304S-01',
                                                                                                                                                                                                                        'IsActive' => true,
                                                                                                                                                                                                                        'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                        //  'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                        'Product_level__c' => 'Hardware',
                                                                                                                                                                                                                        'Product_type__c' => 'Hardware',
                                                                                                                                                                                                                        //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                        'Support_Type__c'=>'Premium',
                                                                                                                                                                                                                        'Usable_Capacity__c' => 75
                                                                                                                                                                                                                        // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                        }; 
                                                                                                                                                                                                                            
                                                                                                                                                                                                                            Map<String, Object> mulMap12 = new Map<String, Object> {   
                                                                                                                                                                                                                                'Name' => 'RS-HW-SVC-PE-S1',
                                                                                                                                                                                                                                    'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                                                                                                                                                                                                    'IsActive' => true,
                                                                                                                                                                                                                                    'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                                    'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                                    //  'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                                    'Product_level__c' => 'Support',
                                                                                                                                                                                                                                    'Product_type__c' => 'HW Support',
                                                                                                                                                                                                                                    //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                                    'Support_Type__c'=>'Premium'
                                                                                                                                                                                                                                    // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                                    }; 
                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                        Map<String, Object> mulMap13 = new Map<String, Object> {   
                                                                                                                                                                                                                                            'Name' => 'RS-BE-ADN-L3-PP',
                                                                                                                                                                                                                                                'ProductCode' => 'RS-BE-ADN-L3-PP',
                                                                                                                                                                                                                                                'IsActive' => true,
                                                                                                                                                                                                                                                'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                                                'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                                                //   'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                                                'Product_level__c' => 'OnPrem',
                                                                                                                                                                                                                                                'Product_type__c' => 'Business Edition',
                                                                                                                                                                                                                                                //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                                                'Support_Type__c'=>'Premium'
                                                                                                                                                                                                                                                // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                                                };
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    Map<String, Object> mulMap14 = new Map<String, Object> {   
                                                                                                                                                                                                                                                        'Name' => 'RH-6304S-01',
                                                                                                                                                                                                                                                            'ProductCode' => 'RH-6304S-01',
                                                                                                                                                                                                                                                            'IsActive' => true,
                                                                                                                                                                                                                                                            'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                                                            'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                                                            //   'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                                                            'Product_level__c' => 'Hardware',
                                                                                                                                                                                                                                                            'Product_type__c' => 'Hardware',
                                                                                                                                                                                                                                                            'Usable_Capacity__c' => 75,
                                                                                                                                                                                                                                                            //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                                                            'Support_Type__c'=>'Premium'
                                                                                                                                                                                                                                                            // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                                                            };    
                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                Map<String, Object> mulMap15 = new Map<String, Object> {   
                                                                                                                                                                                                                                                                    'Name' => 'RS-HW-SVC-L3-S1',
                                                                                                                                                                                                                                                                        'ProductCode' => 'RS-HW-SVC-L3-S1',
                                                                                                                                                                                                                                                                        'IsActive' => true,
                                                                                                                                                                                                                                                                        'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                                                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                                                                        //   'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                                                                        'Product_level__c' => 'Support',
                                                                                                                                                                                                                                                                        'Product_type__c' => 'HW Support',
                                                                                                                                                                                                                                                                        //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                                                                        'Support_Type__c'=>'Premium'
                                                                                                                                                                                                                                                                        // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                                                                        }; 
                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                            Map<String, Object> mulMap16 = new Map<String, Object> {    
                                                                                                                                                                                                                                                                                'Name' => 'RS-BT-SW-SVC-PE',
                                                                                                                                                                                                                                                                                    'ProductCode' => 'RS-BT-SW-SVC-PE',
                                                                                                                                                                                                                                                                                    'IsActive' => true,
                                                                                                                                                                                                                                                                                    'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                                                                                    'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                                                                                    //  'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                                                                                    'Product_level__c' => 'Support',
                                                                                                                                                                                                                                                                                    'Product_type__c' => 'RCDM Support',
                                                                                                                                                                                                                                                                                    //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                                                                                    'Support_Type__c'=>'Premium'
                                                                                                                                                                                                                                                                                    // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                                                                                    };   
                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                        Map<String, Object> mulMap17 = new Map<String, Object> {   
                                                                                                                                                                                                                                                                                            'Name' => 'RS-BT-SW-SVC-L3',
                                                                                                                                                                                                                                                                                                'ProductCode' => 'RS-BT-SW-SVC-L3',
                                                                                                                                                                                                                                                                                                'IsActive' => true,
                                                                                                                                                                                                                                                                                                'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                                                                                                                                                                                                'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                                                                                                                                                                                                // 'Usable_Capacity__c'=> 12,
                                                                                                                                                                                                                                                                                                'Product_level__c' => 'Support',
                                                                                                                                                                                                                                                                                                'Product_type__c' => 'RCDM Support',
                                                                                                                                                                                                                                                                                                //   'Payment_Options__c'=> 'Prepay',
                                                                                                                                                                                                                                                                                                'Support_Type__c'=>'Premium'
                                                                                                                                                                                                                                                                                                // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                                                                                                                                                                                                };       
                                                                                                                                                                                                                                                                                                    Product2 prdMul2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap2);      
            Product2 prdMul3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap3);
            Product2 prdMul4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap4);
            Product2 prdMul5 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap5);
            Product2 prdMul6 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap6);
            Product2 prdMul7 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap7);
            Product2 prdMul8 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap8);
            Product2 prdMul9 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap9);
            Product2 prdMul10 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap10);
            Product2 hwSuppSKU = (Product2) ShGl_TestFactory.createSObject(new Product2(), hwSupp);
            
            Product2 prdMul11 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap11);
            Product2 prdMul12 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap12);
            Product2 prdMul13 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap13);
            Product2 prdMul14 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap14);
            Product2 prdMul15 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap15);
            Product2 prdMul16 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap16);
            Product2 prdMul17 = (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap17);       
            Product2 Product1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p1);
            Product2 Product21 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p2); 
            Product2 Product3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p3); 
            Product2 prdMul1=  (Product2) ShGl_TestFactory.createSObject(new Product2(), mulMap1);  
            Product2 Product4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p4); 
            Product2 productTest = (Product2) ShGl_TestFactory.createSObject(new Product2(), testProd);  //5388
            
            insert new List<Product2>{Product1,Product21,Product3,prdMul2,prdMul3,prdMul4,prdMul5,prdMul6,prdMul7,prdMul8,prdMul9,
                prdMul10,prdMul11,prdMul12,prdMul13,prdMul14,prdMul15,prdMul16,prdMul17, prdMul1, hwSuppSKU, Product4, productTest};
                    
                    List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            PricebookEntry pbHWSup = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbHWSup.Product2Id = hwSuppSKU.Id;
            pBList.add(pbHWSup);
            PricebookEntry pb4 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb4.Product2Id = Product4.Id;
            pBList.add(pb4);
            
            PricebookEntry pb1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb1.Product2Id = Product1.Id;
            pBList.add(pb1);
            
            PricebookEntry pb2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb2.Product2Id = Product21.Id;
            pBList.add(pb2);
            
            PricebookEntry pb3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb3.Product2Id = Product3.Id;
            pBList.add(pb3);
            
            PricebookEntry pbeSubsub = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubsub.Product2Id = prdMul3.Id;
            pBList.add(pbeSubsub);
            
            PricebookEntry pbeSub4 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub4.Product2Id = prdMul4.Id;
            pBList.add(pbeSub4);
            
            PricebookEntry pbeSub5 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub5.Product2Id = prdMul5.Id;
            pBList.add(pbeSub5);
            
            PricebookEntry pbeSub6 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub6.Product2Id = prdMul6.Id;
            pBList.add(pbeSub6);
            
            PricebookEntry pbeSub7 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub7.Product2Id = prdMul7.Id;
            pBList.add(pbeSub7);
            
            
            PricebookEntry pbeSub8 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub8.Product2Id = prdMul8.Id;
            pBList.add(pbeSub8);
            
            
            PricebookEntry pbeSub9 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub9.Product2Id = prdMul9.Id;
            pBList.add(pbeSub9);
            
            
            PricebookEntry pbeSub10 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub10.Product2Id = prdMul10.Id;
            pBList.add(pbeSub10);
            
            
            PricebookEntry pbeSub11 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub11.Product2Id = prdMul11.Id;
            pBList.add(pbeSub11);
            
            PricebookEntry pbeSub12 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub12.Product2Id = prdMul12.Id;
            pBList.add(pbeSub12);
            
            PricebookEntry pbeSub13 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub13.Product2Id = prdMul13.Id;
            pBList.add(pbeSub13);
            
            PricebookEntry pbeSub14 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub14.Product2Id = prdMul14.Id;
            pBList.add(pbeSub14);
            
            PricebookEntry pbeSub15 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub15.Product2Id = prdMul15.Id;
            pBList.add(pbeSub15);
            
            PricebookEntry pbeSub16 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub16.Product2Id = prdMul16.Id;
            pBList.add(pbeSub16);
            
            PricebookEntry pbeSub17 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub17.Product2Id = prdMul17.Id;
            pBList.add(pbeSub17);
            
            PricebookEntry pbeSub1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSub1.Product2Id = prdMul1.Id;
            pBList.add(pbeSub1);
            
            PricebookEntry testpb2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            testpb2.Product2Id = productTest.Id;
            pBList.add(testpb2); //5388
            insert pBList;
            
            Asset newAsset = new Asset(Name = 'AA185263040113', SerialNumber = 'AA185263040113', Product2Id = Product1.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = '8021COMKEY');
            insert newAsset;
            
            List<Multi_Mapping_V2_Conversion__c> multList = new List<Multi_Mapping_V2_Conversion__c>();
            
            Multi_Mapping_V2_Conversion__c m111 = new Multi_Mapping_V2_Conversion__c();
            m111.Source_Product__c = Product21.id;
            m111.Target_Product__c = hwSuppSKU.id;//RH-6304S-01
            m111.After_Conversion_Product_Level__c = 'SubPRO'; 
            m111.Payment_Option__c = 'Prepay';
            
            // m11.Support_Tier__c = 'E1';
            m111.Support_Type__c = 'Premium';
            //insert m11;
            multList.add(m111);
            
            Multi_Mapping_V2_Conversion__c m10 = new Multi_Mapping_V2_Conversion__c();
            m10.Source_Product__c = Product21.id;
            m10.Target_Product__c = prdMul1.id;//RS-BT-BE-PE-PA
            m10.After_Conversion_Product_Level__c = 'SubPRO'; 
            m10.Payment_Option__c = 'Prepay';
            m10.Support_Type__c = 'Premium';
            //insert m10;
            multList.add(m10);
            
            Multi_Mapping_V2_Conversion__c m20 = new Multi_Mapping_V2_Conversion__c();
            m20.Source_Product__c = Product21.id;
            m20.Target_Product__c = prdMul1.id;//RS-BT-BE-PE-PA
            m20.After_Conversion_Product_Level__c = 'SubPRO'; 
            m20.Payment_Option__c = 'Prepay';
            m20.Support_Type__c = 'Premium';
            //insert m10;
            multList.add(m20);
            
            Multi_Mapping_V2_Conversion__c m11 = new Multi_Mapping_V2_Conversion__c();
            m11.Source_Product__c = Product21.id;
            m11.Target_Product__c = prdMul2.id;//RH-6304S-01
            m11.After_Conversion_Product_Level__c = 'SubPRO'; 
            m11.Payment_Option__c = 'Prepay';
            
            // m11.Support_Tier__c = 'E1';
            m11.Support_Type__c = 'Premium';
            //insert m11;
            multList.add(m11);
            
            Multi_Mapping_V2_Conversion__c m21= new Multi_Mapping_V2_Conversion__c();
            m21.Source_Product__c = Product21.id;
            m21.Target_Product__c = prdMul3.id;//RS-HW-SVC-PE-S1
            m21.After_Conversion_Product_Level__c = 'SubPRO'; 
            m21.Payment_Option__c = 'Prepay';
            // m21.Support_Tier__c = 'E1';
            m21.Support_Type__c = 'Premium';
            //insert m21;
            multList.add(m21);
            
            Multi_Mapping_V2_Conversion__c m31= new Multi_Mapping_V2_Conversion__c();
            m31.Source_Product__c = Product21.id;
            m31.Target_Product__c = prdMul4.id;//RS-BE-ADN-PE-PA
            m31.After_Conversion_Product_Level__c = 'SubPRO'; 
            m31.Payment_Option__c = 'Prepay';
            // m21.Support_Tier__c = 'E1';
            m31.Support_Type__c = 'Premium';
            //insert m31;
            multList.add(m31);
            
            Multi_Mapping_V2_Conversion__c m71= new Multi_Mapping_V2_Conversion__c();
            m71.Source_Product__c = Product21.id;
            m71.Target_Product__c = prdMul8.id;
            m71.After_Conversion_Product_Level__c = 'PROBUNDLE'; 
            m71.Payment_Option__c = 'Prepay';
            // m21.Support_Tier__c = 'E1';
            m71.Support_Type__c = 'Premium';
            //insert m71;
            multList.add(m71);
            
            Multi_Mapping_V2_Conversion__c m81= new Multi_Mapping_V2_Conversion__c();
            m81.Source_Product__c = Product21.id;
            m81.Target_Product__c = prdMul9.id;
            m81.After_Conversion_Product_Level__c = 'PROBUNDLE'; 
            m81.Payment_Option__c = 'Prepay';
            // m21.Support_Tier__c = 'E1';
            m81.Support_Type__c = 'Premium';
            //insert m81;
            multList.add(m81);
            
            Multi_Mapping_V2_Conversion__c m101= new Multi_Mapping_V2_Conversion__c();
            m101.Source_Product__c = Product21.id;
            m101.Target_Product__c = prdMul11.id;
            m101.After_Conversion_Product_Level__c = 'PROBUNDLE'; //Support
            m101.Payment_Option__c = 'Prepay';
            // m21.Support_Tier__c = 'E1';
            m101.Support_Type__c = 'Premium';
            // insert m101;
            multList.add(m101);
            
            //test Prod
            Multi_Mapping_V2_Conversion__c mTest= new Multi_Mapping_V2_Conversion__c();
            mTest.Source_Product__c = productTest.id;
            mTest.Target_Product__c = prdMul9.id;
            mTest.After_Conversion_Product_Level__c = 'Support'; 
            mTest.Payment_Option__c = 'Prepay';
            mTest.Support_Type__c = 'Premium';
            multList.add(mTest);
            
            Multi_Mapping_V2_Conversion__c mTest1= new Multi_Mapping_V2_Conversion__c();
            mTest1.Source_Product__c = productTest.id;
            mTest1.Target_Product__c = prdMul7.id;
            mTest1.After_Conversion_Product_Level__c = 'Support'; 
            mTest1.Payment_Option__c = 'Prepay';
            mTest1.Support_Type__c = 'Premium';
            multList.add(mTest1);
            
            /*Multi_Mapping_V2_Conversion__c mTest1= new Multi_Mapping_V2_Conversion__c();
mTest1.Source_Product__c = productTest.id;
mTest1.Target_Product__c = productNRD.id;
mTest1.After_Conversion_Product_Level__c = 'Support'; 
mTest1.Payment_Option__c = 'Prepay';
mTest1.Support_Type__c = 'Premium';
multList.add(mTest1);*/
            
            insert multList;
            
            ContractLineItem ContractLineItemObjMul5 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul5.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul5.PricebookEntryId = pb2.Id;
            ContractLineItemObjMul5.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul5.Quantity = 10;
            ContractLineItemObjMul5.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul5.Support_Type__c = 'Premium';
            ContractLineItemObjMul5.AssetId = newAsset.Id;
            ContractLineItemObjMul5.UnitPrice = 100;
            ContractLineItemObjMul5.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul5.SBQQSC__Product__c = Product21.Id;
            ContractLineItemObjMul5.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul5.StartDate = System.today();
            ContractLineItemObjMul5.EndDate =System.today() + 150;
            ContractLineItemObjMul5.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul5.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul5.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul5;
            
            
            ContractLineItem ContractLineItemObjMul7 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul7.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul7.PricebookEntryId = pb2.Id;
            ContractLineItemObjMul7.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul7.Quantity = 10;
            ContractLineItemObjMul7.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul7.Support_Type__c = 'Premium';
            ContractLineItemObjMul7.AssetId = newAsset.Id;
            ContractLineItemObjMul7.UnitPrice = 100;
            ContractLineItemObjMul7.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul7.SBQQSC__Product__c = Product21.Id;
            ContractLineItemObjMul7.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul7.StartDate = System.today();
            ContractLineItemObjMul7.EndDate =System.today() + 150;
            ContractLineItemObjMul7.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul7.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul7.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul7; 
            
            ContractLineItem ContractLineItemObjMul6 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul6.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul6.PricebookEntryId = pb3.Id;
            ContractLineItemObjMul6.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul6.Quantity = 10;
            ContractLineItemObjMul6.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul6.Support_Type__c = 'Premium';
            ContractLineItemObjMul6.UnitPrice = 100;
            ContractLineItemObjMul6.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul6.SBQQSC__Product__c = Product3.Id;
            ContractLineItemObjMul6.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul6.StartDate = System.today();
            ContractLineItemObjMul6.EndDate =System.today() + 150;
            ContractLineItemObjMul6.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul6.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul6.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul6;
            
            ContractLineItem ContractLineItemObjMul9 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul9.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul9.PricebookEntryId = pbHWSup.Id;
            ContractLineItemObjMul9.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul9.Quantity = 10;
            ContractLineItemObjMul9.Support_Type__c = 'Premium';
            ContractLineItemObjMul9.UnitPrice = 100;
            ContractLineItemObjMul9.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul9.SBQQSC__Product__c = hwSuppSKU.Id;
            ContractLineItemObjMul9.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul9.StartDate = System.today();
            ContractLineItemObjMul9.EndDate =System.today() + 150;
            ContractLineItemObjMul9.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul9.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul9.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul9;
            
            ContractLineItem ContractLineItemObjMulNRD = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMulNRD.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMulNRD.PricebookEntryId = testpb2.Id;
            ContractLineItemObjMulNRD.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMulNRD.Quantity = 10;
            ContractLineItemObjMulNRD.Payment_Options__c = 'Prepay';
            ContractLineItemObjMulNRD.Support_Type__c = 'Premium';
            ContractLineItemObjMulNRD.UnitPrice = 100;
            ContractLineItemObjMulNRD.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMulNRD.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMulNRD.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMulNRD.StartDate = System.today();
            ContractLineItemObjMulNRD.EndDate =System.today() + 150;
            ContractLineItemObjMulNRD.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMulNRD.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMulNRD.SBQQSC__RenewalQuantity__c = 20;    
            ContractLineItemObjMulNRD.SBQQSC__RequiredById__c = ContractLineItemObjMul9.Id;   
            insert ContractLineItemObjMulNRD;
            
            ContractLineItem ContractLineItemObjMulNRD1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMulNRD1.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMulNRD1.PricebookEntryId = testpb2.Id;
            ContractLineItemObjMulNRD1.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMulNRD1.Quantity = 10;
            ContractLineItemObjMulNRD1.Payment_Options__c = 'Prepay';
            ContractLineItemObjMulNRD1.Support_Type__c = 'Premium';
            ContractLineItemObjMulNRD1.UnitPrice = 100;
            ContractLineItemObjMulNRD1.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMulNRD1.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMulNRD1.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMulNRD1.StartDate = System.today();
            ContractLineItemObjMulNRD1.EndDate =System.today() + 150;
            ContractLineItemObjMulNRD1.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMulNRD1.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMulNRD1.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMulNRD1;
            
            Entitlement enttitlementNewObj7 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj7.AccountId = act.Id;
            enttitlementNewObj7.StartDate = Date.today().addDays(-365);
            enttitlementNewObj7.EndDate = Date.today().addDays(+900);
            enttitlementNewObj7.ContractLineItemId = ContractLineItemObjMul9.Id;
            enttitlementNewObj7.Renewable__c = true;
            enttitlementNewObj7.AssetId =newAsset.Id ;
            enttitlementNewObj7.Type = 'Phone Support';
            enttitlementNewObj7.Renewal_Category__c = '';
            enttitlementNewObj7.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj7.Product__c = Product21.Id; 
            enttitlementNewObj7.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj7.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            
            
            
            Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj6.AccountId = act.Id;
            enttitlementNewObj6.StartDate = Date.today().addDays(-365);
            enttitlementNewObj6.EndDate = Date.today().addDays(+900);
            enttitlementNewObj6.ContractLineItemId = ContractLineItemObjMul9.Id;
            enttitlementNewObj6.Renewable__c = true;
            enttitlementNewObj6.AssetId =newAsset.Id ;
            enttitlementNewObj6.Type = 'Phone Support';
            enttitlementNewObj6.Renewal_Category__c = '';
            enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj6.Product__c = hwSuppSKU.Id; 
            enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj6.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj6;
            
            Entitlement enttitlementNewObj8 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj8.AccountId = act.Id;
            enttitlementNewObj8.StartDate = Date.today().addDays(-365);
            enttitlementNewObj8.EndDate = Date.today().addDays(+900);
            enttitlementNewObj8.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj8.Renewable__c = true;
            enttitlementNewObj8.AssetId =newAsset.Id ;
            enttitlementNewObj8.Type = 'Phone Support';
            enttitlementNewObj8.Renewal_Category__c = '';
            enttitlementNewObj8.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj8.Product__c = Product21.Id; 
            enttitlementNewObj8.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj8.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj8;
            
            Entitlement enttitlementNewObjNRD = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObjNRD.AccountId = act.Id;
            enttitlementNewObjNRD.StartDate = Date.today().addDays(-365);
            enttitlementNewObjNRD.EndDate = Date.today().addDays(+900);
            enttitlementNewObjNRD.ContractLineItemId = ContractLineItemObjMulNRD.Id;
            enttitlementNewObjNRD.Renewable__c = true;
            enttitlementNewObjNRD.AssetId =newAsset.Id ;
            enttitlementNewObjNRD.Type = 'Phone Support';
            enttitlementNewObjNRD.Renewal_Category__c = '';
            enttitlementNewObjNRD.Name = 'EntitlementTriggerHelper';
            enttitlementNewObjNRD.Product__c = productTest.Id; 
            enttitlementNewObjNRD.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObjNRD.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObjNRD;
            
            Entitlement enttitlementNewObjNRD1 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObjNRD1.AccountId = act.Id;
            enttitlementNewObjNRD1.StartDate = Date.today().addDays(-365);
            enttitlementNewObjNRD1.EndDate = Date.today().addDays(+900);
            enttitlementNewObjNRD1.ContractLineItemId = ContractLineItemObjMulNRD1.Id;
            enttitlementNewObjNRD1.Renewable__c = true;
            enttitlementNewObjNRD1.AssetId =newAsset.Id ;
            enttitlementNewObjNRD1.Type = 'Phone Support';
            enttitlementNewObjNRD1.Renewal_Category__c = '';
            enttitlementNewObjNRD1.Name = 'EntitlementTriggerHelper';
            enttitlementNewObjNRD1.Product__c = productTest.Id; 
            enttitlementNewObjNRD1.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObjNRD1.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObjNRD1;
            
            Entitlement enttitlementNewObj9 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj9.AccountId = act.Id;
            enttitlementNewObj9.StartDate = Date.today().addDays(-365);
            enttitlementNewObj9.EndDate = Date.today().addDays(+900);
            enttitlementNewObj9.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj9.Renewable__c = true;
            enttitlementNewObj9.AssetId =newAsset.Id ;
            enttitlementNewObj9.Type = 'Phone Support';
            enttitlementNewObj9.Renewal_Category__c = 'Renew later';
            enttitlementNewObj9.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj9.Product__c = Product3.Id; 
            enttitlementNewObj9.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj9.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj9;
            
            
            
            Entitlement enttitlementNewObj10 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj10.AccountId = act.Id;
            enttitlementNewObj10.StartDate = Date.today().addDays(-365);
            enttitlementNewObj10.EndDate = Date.today().addDays(+900);
            enttitlementNewObj10.ContractLineItemId = ContractLineItemObjMul7.Id;
            enttitlementNewObj10.Renewable__c = true;
            enttitlementNewObj10.AssetId =newAsset.Id ;
            enttitlementNewObj10.Type = 'Phone Support';
            enttitlementNewObj10.Renewal_Category__c = 'Renew later';
            enttitlementNewObj10.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj10.Product__c = Product1.Id; 
            enttitlementNewObj10.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj10.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj10;
            
            // AutoQuoteCreationBatch1 obj = new AutoQuoteCreationBatch1(new Set<Id>{opp.Id});
            // Database.executeBatch(obj,1);
            List<SBQQ__Quote__c> qList = [Select Id From SBQQ__Quote__c LIMIT 1];
            
            test.startTest();
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal+Expansion';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            insert qt;
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,SBQQ__Product__c = product1.Id, SBQQ__RenewedAsset__c = newAsset.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', SBQQ__Existing__c = true);
            TriggerControls.disableQuoteLineTrigger = true;
            insert qli1; 
            
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = product21.Id, SBQQSC__RenewedContractLine__c = ContractLineItemObjMul5.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =enttitlementNewObj8.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard',SBQQ__SubscribedAssetIds__c = newAsset.id,
                                                             SBQQ__StartDate__c = Date.newInstance(2022, 11, 11));
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = product21.Id,SBQQSC__RenewedContractLine__c =ContractLineItemObjMul7.Id, SBQQ__Quantity__c = 20, SBQQ__Number__c = 3, required_by_ext_Id__c =enttitlementNewObj10.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard',SBQQ__SubscribedAssetIds__c = newAsset.id,
                                                             SBQQ__StartDate__c = Date.newInstance(2022, 11, 11));
            SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = hwSuppSKU.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 4, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul7.Id,Storage_Region_Bundle__c = 'Standard' , SBQQ__SubscribedAssetIds__c = newAsset.id);
            
            //5388
            SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = productTest.Id, SBQQSC__RenewedContractLine__c = ContractLineItemObjMulNRD.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =enttitlementNewObjNRD.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard',SBQQ__SubscribedAssetIds__c = newAsset.id,
                                                             SBQQ__StartDate__c = Date.newInstance(2022, 11, 11)); //NRD
            SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = productTest.Id, SBQQSC__RenewedContractLine__c = ContractLineItemObjMulNRD1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =enttitlementNewObjNRD1.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard',SBQQ__SubscribedAssetIds__c = newAsset.id,
                                                             SBQQ__StartDate__c = Date.newInstance(2022, 11, 11)); //NRD
            
            qliList.add( qli2 );
            qliList.add( qli3 );
            qliList.add( qli4 );
            qliList.add( qli5 );
            qliList.add( qli6 );
            insert qliList;
            TriggerControls.disableQuoteLineTrigger = false;
            qList.add(qt);
            ConvertToSaasRenewalBatch qUpdate = new ConvertToSaasRenewalBatch(qList);
            Database.executeBatch(qupdate,1);
            test.stoptest(); 
        }
    }  
    /***********************************************************************************************************
* Method Name          : newSaasTest
* Date Created/Modified: 25/07/2025
* Author               : 
* @description         : Test conversion
/**********************************************************************************************************/
    
    static testMethod void newSaasTest() {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
        custsetting.DisableTrigger__c = true;
        insert custsetting;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            //   Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                            Disable_Campaign_Trigger__c = true,
                                                                            Disable_Campaign_Validation_Rules__c = true,
                                                                            Disable_Order_Validation_Rules__c=true, 
                                                                            Disable_ServiceContract_Trigger__c=true,
                                                                            Disable_Entitlement_Usage_Trigger__c=true,
                                                                            Disable_Entitlement_Trigger__c=true,
                                                                            Disable_Contract_Line_Item_Triggers__c = true,
                                                                            Disable_Entitlement_Validation_Rules__c = true,
                                                                            SetupOwnerId = usr1.Id,
                                                                            Disable_Asset_Triggers__c=true,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = true);    
        insert cdf;
        /*User runningUser = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];
UPSERT new ShGl_DisableBusinessLogic__c(
SetupOwnerId = runningUser.Id,
Disable_Entitlement_Validation_Rules__c = true,
Disable_Order_Validation_Rules__c=true
);*/
        System.runAs(usr1) {
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Eligible_for_RCDM_T__c = true;
            insert act; 
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c =pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                     PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150);
            insert serviceContractObj;
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size());
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};    
                
                Map<String, Object> p1 = new Map<String, Object> {
                    'Name' => 'RBK-GO-FNDN-R6404',
                        'ProductCode' => 'RBK-GO-FNDN-R6404',
                        'IsActive' => true,
                        'After_Conversion_Product_Level__c' => 'Hybrid Software'
                        
                        };
                            
                            Map<String, Object> fndnSKU = new Map<String, Object> {
                                'Name' => 'RBK-GO-FNDN-R6304',
                                    'ProductCode' => 'RBK-GO-FNDN-R6304',
                                    'IsActive' => true,
                                    'After_Conversion_Product_Level__c' => 'Hybrid Software'
                                    
                                    };
                                        Map<String, Object> pp2 = new Map<String, Object> {
                                            'Name' => 'RBK-R6412S-HW-01',
                                                'ProductCode' => 'RBK-R6412S-HW-01',
                                                'IsActive' => true,
                                                'Support_Tier__c' => 'S2',
                                                'Usable_Capacity__c' => 75,
                                                'After_Conversion_Product_Level__c' => 'Hardware'
                                                };
                                                    
                                                    Map<String, Object> hwSupp = new Map<String, Object> {
                                                        'Name' => 'RBK-SVC-PREM-HW',
                                                            'ProductCode' => 'RBK-SVC-PREM-HW',
                                                            'IsActive' => true,
                                                            'After_Conversion_Product_Level__c' => 'Support',
                                                            'Product_Type__c' => 'HW Support'
                                                            };
                                                                Map<String, Object> rcdmSupp = new Map<String, Object> {
                                                                    'Name' => 'RBK-SVC-PREM-SW',
                                                                        'ProductCode' => 'RBK-SVC-PREM-SW',
                                                                        'IsActive' => true,
                                                                        'After_Conversion_Product_Level__c' => 'Support',
                                                                        'Product_Type__c' => 'RCDM Support',
                                                                        'Eligible_for_RCDM_T__c' => true
                                                                        };
                                                                            
                                                                            Map<String, Object> pp1 = new Map<String, Object> {
                                                                                'Name' => 'RS-BT-EE-PE-PP',
                                                                                    'ProductCode' => 'RS-BT-EE-PE-PP',
                                                                                    'IsActive' => true,
                                                                                    'Product_Level__c' => 'Hybrid Software'
                                                                                    };
                                                                                        
                                                                                        
                                                                                        Map<String, Object> p3 = new Map<String, Object> {
                                                                                            'Name' => 'RH-6412S-01',
                                                                                                'ProductCode' => 'RH-6412S-01',
                                                                                                'IsActive' => true,
                                                                                                'Product_Level__c' => 'Hardware',
                                                                                                'Usable_Capacity__c' => 75
                                                                                                };
                                                                                                    
                                                                                                    Map<String, Object> p4 = new Map<String, Object> {
                                                                                                        'Name' => 'RS-HW-SVC-PE-S2',
                                                                                                            'ProductCode' => 'RS-HW-SVC-PE-S2',
                                                                                                            'IsActive' => true,
                                                                                                            //      'Usable_Capacity__c'=> 12,
                                                                                                            'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                            'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                            'Product_level__c' => 'Support',
                                                                                                            'Product_type__c' => 'HW Support',
                                                                                                            //    'Payment_Options__c'=> 'Prepay',
                                                                                                            'Support_Type__c'=>'Premium',
                                                                                                            'Support_Tier__c' => 'S2'
                                                                                                            // 'SBQQ__RenewalProduct__c' => ''
                                                                                                            }; 
                                                                                                                Map<String, Object> rcdmSKUv2 = new Map<String, Object> {
                                                                                                                    'Name' => 'RS-BT-SW-SVC-PE',
                                                                                                                        'ProductCode' => 'RS-BT-SW-SVC-PE',
                                                                                                                        'IsActive' => true,
                                                                                                                        //      'Usable_Capacity__c'=> 12,
                                                                                                                        'SBQQ__AssetConversion__c' => 'One per unit',
                                                                                                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                                                                                                        'Product_level__c' => 'Support',
                                                                                                                        'Product_type__c' => 'RCDM Support',
                                                                                                                        //    'Payment_Options__c'=> 'Prepay',
                                                                                                                        'Support_Type__c'=>'Premium',
                                                                                                                        'Eligible_for_RCDM_T__c'=> true
                                                                                                                        // 'SBQQ__RenewalProduct__c' => ''
                                                                                                                        };   
                                                                                                                            
                                                                                                                            
                                                                                                                            //Radar1
                                                                                                                            Map<String, Object> radarSKU = new Map<String, Object> {
                                                                                                                                'Name' => 'RBK-RADAR',
                                                                                                                                    'ProductCode' => 'RBK-RADAR',
                                                                                                                                    'IsActive' => true,
                                                                                                                                    'After_Conversion_Product_Level__c' => 'SaaS Software Addon',
                                                                                                                                    'Product_Type__c' => 'RADAR'
                                                                                                                                    };
                                                                                                                                        
                                                                                                                                        
                                                                                                                                        //Radar2
                                                                                                                                        Map<String, Object> radarV2 = new Map<String, Object> {
                                                                                                                                            'Name' => 'RS-BT-RAD-PE-PP',
                                                                                                                                                'ProductCode' => 'RS-BT-RAD-PE-PP',
                                                                                                                                                'IsActive' => true,
                                                                                                                                                'Product_Level__c' => 'SaaS Software Addon'
                                                                                                                                                };
                                                                                                                                                    
                                                                                                                                                    Map<String, Object> prodNRD = new Map<String, Object> {
                                                                                                                                                        'Name' => 'RBK-NRD-R6000',
                                                                                                                                                            'ProductCode' => 'RBK-NRD-R6000',
                                                                                                                                                            'IsActive' => true,
                                                                                                                                                            'After_Conversion_Product_Level__c' => 'Support' 
                                                                                                                                                            }; 
                                                                                                                                                                Map<String, Object> prodNRDNew = new Map<String, Object> {
                                                                                                                                                                    'Name' => 'RS-NRD-R6000',
                                                                                                                                                                        'ProductCode' => 'RS-NRD-R6000',
                                                                                                                                                                        'IsActive' => true,
                                                                                                                                                                        'After_Conversion_Product_Level__c' => 'Support' 
                                                                                                                                                                        };    
                                                                                                                                                                            
                                                                                                                                                                            List<Product2> prodList = new List<Product2>();
            Product2 Product1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p1);
            Product2 Product3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p3); 
            Product2 Product4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p4); 
            Product2 ParentProduct1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), pp1);
            Product2 ParentProduct2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), pp2);
            Product2 hwSuppSKU = (Product2) ShGl_TestFactory.createSObject(new Product2(), hwSupp);
            Product2 fndn = (Product2) ShGl_TestFactory.createSObject(new Product2(), fndnSKU);
            Product2 rcdmSuppSKU = (Product2) ShGl_TestFactory.createSObject(new Product2(), rcdmSupp);
            Product2 rcdmSKUv2SKU = (Product2) ShGl_TestFactory.createSObject(new Product2(), rcdmSKUv2);
            Product2 radar1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), radarSKU);
            Product2 radar2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), radarV2);
            Product2 productNRD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodNRD);
            Product2 productNRDNew = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodNRDNew);
            
            prodList.add(Product1);
            prodList.add(Product3);
            prodList.add(Product4);
            prodList.add(ParentProduct1);
            prodList.add(ParentProduct2);
            prodList.add(hwSuppSKU);
            prodList.add(fndn);
            prodList.add(rcdmSuppSKU);
            prodList.add(rcdmSKUv2SKU);
            prodList.add(radar1);
            prodList.add(radar2);
            prodList.add(productNRD);
            prodList.add(productNRDNew);
            
            
            insert prodList;
            
            List<Product2> listOldProduct = new List<Product2>();
            List<Product2> newProductList = new List<Product2>();
            listOldProduct.add(Product1);//GO-FNDN - 0
            listOldProduct.add(ParentProduct2);//HW - 1
            listOldProduct.add(hwSuppSKU);//HW Supp - 2
            listOldProduct.add(rcdmSuppSKU); //- 3
            listOldProduct.add(radar1); // 4
            listOldProduct.add(productNRD); // 5
            
            newProductList.add(ParentProduct1);//BT-PE-PP
            newProductList.add(Product3);//HW
            newProductList.add(Product4);//HW supp
            newProductList.add(rcdmSKUv2SKU);
            newProductList.add(radar2);
            newProductList.add(productNRDNew); //5
            
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            
            PricebookEntry radar1PBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            radar1PBE.Product2Id = radar1.Id;
            pBList.add(radar1PBE);
            
            PricebookEntry radar2PBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            radar2PBE.Product2Id = radar2.Id;
            pBList.add(radar2PBE);   
            
            PricebookEntry fndnPBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            fndnPBE.Product2Id = fndn.Id;
            pBList.add(fndnPBE);
            
            PricebookEntry pb1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb1.Product2Id = Product1.Id;
            pBList.add(pb1);
            
            PricebookEntry pb3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb3.Product2Id = Product3.Id;
            pBList.add(pb3);
            
            PricebookEntry pb4 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb4.Product2Id = Product4.Id;
            pBList.add(pb4);
            
            PricebookEntry pbPP1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbPP1.Product2Id = ParentProduct1.Id;
            pBList.add(pbPP1);
            
            PricebookEntry pbPP2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbPP2.Product2Id = ParentProduct2.Id;
            pBList.add(pbPP2);
            
            PricebookEntry pbHWSup = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbHWSup.Product2Id = hwSuppSKU.Id;
            pBList.add(pbHWSup);
            
            PricebookEntry rcdmSKUv2SKUPBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            rcdmSKUv2SKUPBE.Product2Id = rcdmSKUv2SKU.Id;
            pBList.add(rcdmSKUv2SKUPBE);
            
            PricebookEntry rcdmSuppSKUPBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            rcdmSuppSKUPBE.Product2Id = rcdmSuppSKU.Id;
            pBList.add(rcdmSuppSKUPBE);
            
            PricebookEntry pbeNRD = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeNRD.Product2Id = productNRD.Id;
            pBList.add(pbeNRD);
            PricebookEntry pbeNRDNew = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeNRDNew.Product2Id = productNRDNew.Id;
            pBList.add(pbeNRDNew);
            insert pBList;
            
            List<Polaris_SKU_Mapping_V2__c> polarisMappingList = new List<Polaris_SKU_Mapping_V2__c>();
            
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingFNDN = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[0], newProductList[0]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingHW = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[1], newProductList[1]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingHWSupp = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[2], newProductList[2]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingRCDMSupp = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[3], newProductList[3]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingRadar = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[4], newProductList[4]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingNRD = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[5], newProductList[5]);
            
            polarisSKUMappingFNDN.After_Conversion_Product_Level__c = 'Hybrid Software';
            polarisSKUMappingFNDN.Quantity_Mapping_Type__c = 'Ratio Based';
            polarisSKUMappingFNDN.Quantity_Ratio__c = 1;
            polarisSKUMappingFNDN.Support_Tier__c = '';
            
            polarisSKUMappingHW.After_Conversion_Product_Level__c = 'Hardware';
            polarisSKUMappingHW.Quantity_Mapping_Type__c = 'Appliance Based';
            polarisSKUMappingHW.Quantity_Ratio__c = 10;
            polarisSKUMappingHW.Support_Tier__c = '';
            
            polarisSKUMappingHWSupp.After_Conversion_Product_Level__c = 'Support';
            polarisSKUMappingHWSupp.Quantity_Mapping_Type__c = 'Ratio Based';
            polarisSKUMappingHWSupp.Quantity_Ratio__c = 1;
            
            polarisSKUMappingRCDMSupp.After_Conversion_Product_Level__c = 'Support';
            polarisSKUMappingRCDMSupp.Quantity_Mapping_Type__c = 'Appliance Based';
            polarisSKUMappingRCDMSupp.Quantity_Ratio__c = 1;
            polarisSKUMappingRCDMSupp.Support_Tier__c = '';
            
            polarisSKUMappingRadar.After_Conversion_Product_Level__c = 'SaaS Software Addon';
            polarisSKUMappingNRD.After_Conversion_Product_Level__c = 'Support';
            
            polarisMappingList.add(polarisSKUMappingFNDN);
            polarisMappingList.add(polarisSKUMappingHW);
            polarisMappingList.add(polarisSKUMappingHWSupp);
            polarisMappingList.add(polarisSKUMappingRCDMSupp);
            polarisMappingList.add(polarisSKUMappingRadar);
            polarisMappingList.add(polarisSKUMappingNRD);
            
            insert polarisMappingList;
            Asset newAsset = new Asset(Name = 'AA165203480078', SerialNumber = 'AA210964120095', Product2Id = ParentProduct2.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = '8026COMKEY');
            insert newAsset;
            
            
            
            ContractLineItem ContractLineItemObjMul4 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul4.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul4.PricebookEntryId = rcdmSuppSKUPBE.Id;
            ContractLineItemObjMul4.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul4.Quantity = 10;
            ContractLineItemObjMul4.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul4.Support_Type__c = 'Premium';
            ContractLineItemObjMul4.UnitPrice = 100;
            ContractLineItemObjMul4.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul4.SBQQSC__Product__c = rcdmSuppSKU.Id;
            ContractLineItemObjMul4.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul4.StartDate = System.today();
            ContractLineItemObjMul4.EndDate =System.today() + 150;
            ContractLineItemObjMul4.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul4.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul4.SBQQSC__RenewalQuantity__c = 20;     
            insert ContractLineItemObjMul4;
            
            ContractLineItem ContractLineItemObjMul5 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul5.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul5.PricebookEntryId = pb1.Id;
            ContractLineItemObjMul5.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul5.Quantity = 10;
            ContractLineItemObjMul5.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul5.Support_Type__c = 'Premium';
            ContractLineItemObjMul5.UnitPrice = 100;
            ContractLineItemObjMul5.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul5.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMul5.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul5.StartDate = System.today();
            ContractLineItemObjMul5.EndDate =System.today() + 150;
            ContractLineItemObjMul5.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul5.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul5.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul5;
            
            ContractLineItemObjMul4.SBQQSC__RequiredById__c = ContractLineItemObjMul5.Id;  
            update ContractLineItemObjMul4;
            
            ContractLineItem ContractLineItemObjMul6 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul6.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul6.PricebookEntryId = pbHWSup.Id;
            ContractLineItemObjMul6.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul6.Quantity = 10;
            ContractLineItemObjMul6.Support_Type__c = 'Premium';
            ContractLineItemObjMul6.UnitPrice = 100;
            ContractLineItemObjMul6.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul6.SBQQSC__Product__c = hwSuppSKU.Id;
            ContractLineItemObjMul6.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul6.StartDate = System.today();
            ContractLineItemObjMul6.EndDate =System.today() + 150;
            ContractLineItemObjMul6.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul6.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul6.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul6;
            
            ContractLineItem ContractLineItemObjMul7 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul7.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul7.PricebookEntryId = pb4.Id;
            ContractLineItemObjMul7.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul7.Quantity = 10;
            ContractLineItemObjMul7.AssetId = newAsset.Id;
            ContractLineItemObjMul7.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul7.Support_Type__c = 'Premium';
            ContractLineItemObjMul7.UnitPrice = 100;
            ContractLineItemObjMul7.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul7.SBQQSC__Product__c = Product4.Id;
            ContractLineItemObjMul7.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul7.StartDate = System.today();
            ContractLineItemObjMul7.EndDate =System.today() + 150;
            ContractLineItemObjMul7.SBQQSC__RootId__c = newAsset.Id;
            ContractLineItemObjMul7.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul7.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul7.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul7;
            
            ContractLineItem ContractLineItemObjMul8 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul8.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul8.PricebookEntryId = pb1.Id;
            ContractLineItemObjMul8.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul8.Quantity = 10;
            ContractLineItemObjMul8.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul8.Support_Type__c = 'Premium';
            ContractLineItemObjMul8.UnitPrice = 100;
            ContractLineItemObjMul8.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul8.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMul8.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul8.StartDate = System.today();
            ContractLineItemObjMul8.EndDate =System.today() + 150;
            ContractLineItemObjMul8.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul8.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul8.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul8;
            
            //Radar 1
            ContractLineItem ContractLineItemObjMul9 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul9.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul9.PricebookEntryId = radar1PBE.Id;
            ContractLineItemObjMul9.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul9.Quantity = 10;
            ContractLineItemObjMul9.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul9.Support_Type__c = 'Premium';
            ContractLineItemObjMul9.UnitPrice = 100;
            ContractLineItemObjMul9.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul9.SBQQSC__Product__c = radar1.Id;
            ContractLineItemObjMul9.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul9.StartDate = System.today();
            ContractLineItemObjMul9.EndDate =System.today() + 150;
            ContractLineItemObjMul9.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul9.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul9.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul9;
            
            //Radar 2
            ContractLineItem ContractLineItemObjMul10 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul10.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul10.PricebookEntryId = radar2PBE.Id;
            ContractLineItemObjMul10.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul10.Quantity = 10;
            ContractLineItemObjMul10.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul10.Support_Type__c = 'Premium';
            ContractLineItemObjMul10.UnitPrice = 100;
            ContractLineItemObjMul10.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul10.SBQQSC__Product__c = radar2.Id;
            ContractLineItemObjMul10.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul10.StartDate = System.today();
            ContractLineItemObjMul10.EndDate =System.today() + 150;
            ContractLineItemObjMul10.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul10.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul10.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul10;
            
            //NRD
            ContractLineItem ContractLineItemObjMul11 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul11.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul11.PricebookEntryId = pbeNRD.Id;
            ContractLineItemObjMul11.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul11.Quantity = 10;
            ContractLineItemObjMul11.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul11.Support_Type__c = 'Premium';
            ContractLineItemObjMul11.UnitPrice = 100;
            ContractLineItemObjMul11.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul11.SBQQSC__Product__c = productNRD.Id;
            ContractLineItemObjMul11.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul11.StartDate = System.today();
            ContractLineItemObjMul11.EndDate =System.today() + 150;
            ContractLineItemObjMul11.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul11.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul11.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul11;
            
            //RCDMT SKU
            ContractLineItem ContractLineItemObjMul12 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul12.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul12.PricebookEntryId = rcdmSKUv2SKUPBE.Id;
            ContractLineItemObjMul12.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul12.Quantity = 10;
            ContractLineItemObjMul12.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul12.Support_Type__c = 'Premium';
            ContractLineItemObjMul12.UnitPrice = 100;
            ContractLineItemObjMul12.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul12.SBQQSC__Product__c = rcdmSKUv2SKU.Id;
            ContractLineItemObjMul12.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul12.StartDate = System.today();
            ContractLineItemObjMul12.EndDate =System.today() + 150;
            ContractLineItemObjMul12.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul12.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul12.SBQQSC__RenewalQuantity__c = 20;                                                                                               
            ContractLineItemObjMul12.SBQQSC__RequiredById__c = ContractLineItemObjMul11.Id;
            insert ContractLineItemObjMul12;
            
            Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj6.AccountId = act.Id;
            enttitlementNewObj6.StartDate = Date.today().addDays(-365);
            enttitlementNewObj6.EndDate = Date.today().addDays(+900);
            enttitlementNewObj6.ContractLineItemId = ContractLineItemObjMul4.Id;
            enttitlementNewObj6.Renewable__c = true;
            enttitlementNewObj6.Type = 'Phone Support';
            enttitlementNewObj6.Renewal_Category__c = 'Renew later';
            enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj6.Product__c = Product1.Id; 
            enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj6.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj6; 
            
            Entitlement enttitlementNewObj7 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj7.AccountId = act.Id;
            enttitlementNewObj7.StartDate = Date.today().addDays(-365);
            enttitlementNewObj7.EndDate = Date.today().addDays(+900);
            enttitlementNewObj7.ContractLineItemId = ContractLineItemObjMul4.Id;
            enttitlementNewObj7.Renewable__c = true;
            enttitlementNewObj7.Type = 'Phone Support';
            enttitlementNewObj7.Renewal_Category__c = 'Renew later';
            enttitlementNewObj7.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj7.Product__c = Product1.Id; 
            enttitlementNewObj7.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj7.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj7; 
            
            Entitlement enttitlementNewObj8 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj8.AccountId = act.Id;
            enttitlementNewObj8.StartDate = Date.today().addDays(-365);
            enttitlementNewObj8.EndDate = Date.today().addDays(+900);
            enttitlementNewObj8.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj8.Renewable__c = true;
            enttitlementNewObj8.Type = 'Phone Support';
            enttitlementNewObj8.Renewal_Category__c = 'Renew later';
            enttitlementNewObj8.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj8.Product__c = Product1.Id; 
            enttitlementNewObj8.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj8.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj8; 
            
            Entitlement enttitlementNewObj9 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj9.AccountId = act.Id;
            enttitlementNewObj9.StartDate = Date.today().addDays(-365);
            enttitlementNewObj9.EndDate = Date.today().addDays(+900);
            enttitlementNewObj9.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj9.Renewable__c = true;
            enttitlementNewObj9.AssetId = newAsset.id;
            enttitlementNewObj9.Type = 'Phone Support';
            enttitlementNewObj9.Renewal_Category__c = 'Renew later';
            enttitlementNewObj9.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj9.Product__c = Product4.Id; 
            enttitlementNewObj9.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj9.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj9; 
            
            Entitlement enttitlementNewObj10 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj10.AccountId = act.Id;
            enttitlementNewObj10.StartDate = Date.today().addDays(-365);
            enttitlementNewObj10.EndDate = Date.today().addDays(+900);
            enttitlementNewObj10.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj10.Renewable__c = true;
            enttitlementNewObj10.AssetId = newAsset.id;
            enttitlementNewObj10.Type = 'Phone Support';
            enttitlementNewObj10.Renewal_Category__c = 'Renew later';
            enttitlementNewObj10.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj10.Product__c = Product4.Id; 
            enttitlementNewObj10.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj10.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj10; 
            
            Entitlement enttitlementNewObj11 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj11.AccountId = act.Id;
            enttitlementNewObj11.StartDate = Date.today().addDays(-365);
            enttitlementNewObj11.EndDate = Date.today().addDays(+900);
            enttitlementNewObj11.ContractLineItemId = ContractLineItemObjMul9.Id;
            enttitlementNewObj11.Renewable__c = true;
            enttitlementNewObj11.AssetId = newAsset.id;
            enttitlementNewObj11.Type = 'Phone Support';
            enttitlementNewObj11.Renewal_Category__c = 'Renew later';
            enttitlementNewObj11.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj11.Product__c = radar1.Id; 
            enttitlementNewObj11.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj11.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj11;
            
            Entitlement enttitlementNewObj12 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj12.AccountId = act.Id;
            enttitlementNewObj12.StartDate = Date.today().addDays(-365);
            enttitlementNewObj12.EndDate = Date.today().addDays(+900);
            enttitlementNewObj12.ContractLineItemId = ContractLineItemObjMul10.Id;
            enttitlementNewObj12.Renewable__c = true;
            enttitlementNewObj12.AssetId = newAsset.id;
            enttitlementNewObj12.Type = 'Phone Support';
            enttitlementNewObj12.Renewal_Category__c = 'Renew later';
            enttitlementNewObj12.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj12.Product__c = radar2.Id; 
            enttitlementNewObj12.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj12.ServiceContractId = serviceContractObj.Id;
            
            
            Entitlement enttitlementNewObj13 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj13.AccountId = act.Id;
            enttitlementNewObj13.StartDate = Date.today().addDays(-365);
            enttitlementNewObj13.EndDate = Date.today().addDays(+900);
            enttitlementNewObj13.ContractLineItemId = ContractLineItemObjMul11.Id;
            enttitlementNewObj13.Renewable__c = true;
            enttitlementNewObj13.AssetId = newAsset.id;
            enttitlementNewObj13.Type = 'Phone Support';
            enttitlementNewObj13.Renewal_Category__c = 'Renew later';
            enttitlementNewObj13.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj13.Product__c = productNRD.Id; 
            enttitlementNewObj13.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj13.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj13;
            
            List<SBQQ__Quote__c> qList = new List<SBQQ__Quote__c>();
            test.startTest();
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal+Expansion';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            insert qt;
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = ParentProduct2.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,SBQQ__RenewedAsset__c =newAsset.id);
            TriggerControls.disableQuoteLineTrigger = true;
            insert qli1; 
            
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,SBQQ__Product__c = product1.Id,  SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =enttitlementNewObj6.id, Storage_Region_Bundle__c = 'Standard', SBQQ__RequiredBy__c = qli1.id , SBQQSC__RenewedContractLine__c =ContractLineItemObjMul5.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id); 
            SBQQ__QuoteLine__c qli7 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = radar1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id, SBQQ__RequiredBy__c = qli2.Id, SBQQSC__RenewedContractLine__c = ContractLineItemObjMul9.Id, required_by_ext_Id__c =qli2.id );
            
            SBQQ__QuoteLine__c qli22 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,SBQQ__Product__c = product1.Id,  SBQQ__Quantity__c = 10, SBQQ__Number__c = 7, required_by_ext_Id__c =enttitlementNewObj7.id, Storage_Region_Bundle__c = 'Standard', SBQQ__RequiredBy__c = qli1.id , SBQQSC__RenewedContractLine__c =ContractLineItemObjMul8.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id); 
            SBQQ__QuoteLine__c qli8 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = radar1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 8, SBQQ__RequiredBy__c = qli22.Id,required_by_ext_Id__c =enttitlementNewObj8.id, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul4.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id );
            qliList.add( qli22 );
            qliList.add( qli8 );
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = hwSuppSKU.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 4, SBQQ__RequiredBy__c = qli2.Id,required_by_ext_Id__c =enttitlementNewObj9.id, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul6.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id );
            qliList.add( qli2 );
            SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = rcdmSuppSKU.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 5, SBQQ__RequiredBy__c = qli1.Id,required_by_ext_Id__c =enttitlementNewObj10.id, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul4.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id );
            SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = fndn.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 6, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id );
            SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = rcdmSuppSKU.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 7, SBQQ__RequiredBy__c = qli1.Id,required_by_ext_Id__c =enttitlementNewObj11.id, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul4.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id );
            SBQQ__QuoteLine__c qli9 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = productNRD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 7, SBQQ__RequiredBy__c = qli1.Id,required_by_ext_Id__c =enttitlementNewObj13.id, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul11.Id, SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id, Subscribed_Asset_Name__c = 'AA165203480078, AA184203000122' );
            
            
            qliList.add( qli7 );
            qliList.add( qli3 );
            qliList.add( qli4 );
            qliList.add( qli5 );
            qliList.add( qli6 );
            qliList.add( qli9 );
            insert qliList;
            TriggerControls.disableQuoteLineTrigger = false;
            qList.add(qt);
            ConvertToSaasRenewalBatch qUpdate = new ConvertToSaasRenewalBatch(qList);
            Database.executeBatch(qupdate,1);
            test.stoptest();
        }
        
        
    }
    /***********************************************************************************************************
* Method Name          : noMappings
* Date Created/Modified: 25/07/2025
* Author               : 
* @description         : Test conversion
/**********************************************************************************************************/
    
    static testMethod void noMappings() {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
        custsetting.DisableTrigger__c = true;
        insert custsetting;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            //   Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                            Disable_Campaign_Trigger__c = true,
                                                                            Disable_Campaign_Validation_Rules__c = true,
                                                                            Disable_Order_Validation_Rules__c=true, 
                                                                            Disable_ServiceContract_Trigger__c=true,
                                                                            Disable_Entitlement_Usage_Trigger__c=true,
                                                                            Disable_Entitlement_Trigger__c=true,
                                                                            Disable_Contract_Line_Item_Triggers__c = true,
                                                                            Disable_Entitlement_Validation_Rules__c = true,
                                                                            SetupOwnerId = usr1.Id,
                                                                            Disable_Asset_Triggers__c=true,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = true);    
        insert cdf;
        /*User runningUser = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];
UPSERT new ShGl_DisableBusinessLogic__c(
SetupOwnerId = runningUser.Id,
Disable_Entitlement_Validation_Rules__c = true,
Disable_Order_Validation_Rules__c=true
);*/
        System.runAs(usr1) {
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Eligible_for_RCDM_T__c = true;
            insert act; 
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c =pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                     PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150, Renew_to_Old_SKUs__c = true);
            insert serviceContractObj;
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size());
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};    
                
                Map<String, Object> p1 = new Map<String, Object> {
                    'Name' => 'RBK-GO-FNDN-R6404',
                        'ProductCode' => 'RBK-GO-FNDN-R6404',
                        'IsActive' => true
                        };
                            
                            Map<String, Object> pp2 = new Map<String, Object> {
                                'Name' => 'RBK-R6412S-HW-01',
                                    'ProductCode' => 'RBK-R6412S-HW-01',
                                    'IsActive' => true,
                                    'Support_Tier__c' => 'S1'
                                    };
                                        
                                        
                                        
                                        List<Product2> prodList = new List<Product2>();
            Product2 Product1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p1);
            Product2 ParentProduct2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), pp2);
            
            prodList.add(Product1);
            prodList.add(ParentProduct2);
            
            insert prodList;
            
            
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            PricebookEntry pb1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb1.Product2Id = Product1.Id;
            pBList.add(pb1);
            PricebookEntry pbPP2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbPP2.Product2Id = ParentProduct2.Id;
            pBList.add(pbPP2);
            insert pBList;
            
            Asset newAsset = new Asset(Name = 'AA185263040113', SerialNumber = 'AA185263040113', Product2Id = ParentProduct2.Id, AccountId = act.Id, ContactId = cnt.Id,
                                       SBQQ__CombineKey__c = '8021COMKEY');
            insert newAsset;
            
            ContractLineItem ContractLineItemObjMul5 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul5.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul5.PricebookEntryId = pb1.Id;
            ContractLineItemObjMul5.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul5.Quantity = 10;
            ContractLineItemObjMul5.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul5.Support_Type__c = 'Premium';
            ContractLineItemObjMul5.UnitPrice = 100;
            ContractLineItemObjMul5.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul5.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMul5.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul5.StartDate = System.today();
            ContractLineItemObjMul5.EndDate =System.today() + 150;
            ContractLineItemObjMul5.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul5.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul5.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul5;
            
            Entitlement enttitlementNewObj8 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj8.AccountId = act.Id;
            enttitlementNewObj8.StartDate = Date.today().addDays(-365);
            enttitlementNewObj8.EndDate = Date.today().addDays(+900);
            enttitlementNewObj8.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj8.Renewable__c = true;
            enttitlementNewObj8.Type = 'Phone Support';
            enttitlementNewObj8.Renewal_Category__c = 'Renew later';
            enttitlementNewObj8.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj8.Product__c = Product1.Id; 
            enttitlementNewObj8.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj8.ServiceContractId = serviceContractObj.Id;
            enttitlementNewObj8.Assetid = newAsset.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj8; 
            
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal+Expansion';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            Test.startTest();
            insert qt;
            List<SBQQ__Quote__c> qList = new List<SBQQ__Quote__c>();
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = ParentProduct2.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1);
            insert qli1;
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = product1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SBQQ__RequiredBy__c = qli1.Id);
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = product1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, SBQQSC__RenewedContractLine__c =ContractLineItemObjMul5.Id );
            qliList.add(qli3);
            qliList.add(qli2);
            
            TriggerControls.disableQuoteLineTrigger = true;
            insert qliList; 
            TriggerControls.disableQuoteLineTrigger = false;
            qList.add(qt);
            ConvertToSaasRenewalBatch qUpdate = new ConvertToSaasRenewalBatch(qList);
            Database.executeBatch(qupdate,1);
            test.stoptest();
        }
    }
    
    
    /***********************************************************************************************************
* Method Name          : testForCNV
* Date Created/Modified: 25/07/2025
* Author               : 
* @description         : Test conversion
/**********************************************************************************************************/
    
    public static testMethod void  testForCNV()
    {    
        
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Entitlement';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        /*User runningUser = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];
UPSERT new ShGl_DisableBusinessLogic__c(
SetupOwnerId = runningUser.Id,
Disable_Entitlement_Validation_Rules__c = true,
Disable_Order_Validation_Rules__c=true
); */
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(
            Disable_Contract_Line_Item_Triggers__c = true,
            Disable_Entitlement_Validation_Rules__c = true,
            SetupOwnerId = usr1.Id,
            Disable_Asset_Triggers__c=true,
            Disable_SBQQ_QuoteLine_Triggers__c = true); 
        insert cdf;
        System.runAs(usr1) {
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Eligible_for_RCDM_T__c = true;
            act.Is_Customer_Fully_Transitioned__c = false;
            act.RCDMT_EOL_Date__c = Date.newInstance(2040, 1, 1);
            
            insert act; 
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c =pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                     PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150);
            insert serviceContractObj;
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size());
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};    
                
                
                List<Product2> listParentProduct = new List<Product2>();
            Product2 parentProductOne = new Product2(
                Name = 'RBK-R6404S-01',
                ProductCode = 'RBK-R6404S-01',
                Eligible_for_RCDM_T__c = true,
                Category__c = 'Platform',
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = null,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__SubscriptionTerm__c = null,
                SBQQ__SubscriptionBase__c = null,
                SBQQ__SubscriptionType__c = null,
                IsActive = true,
                Asset_Priority__c = 0,
                New_CPQ_Product__c = true,
                After_Conversion_Product_Level__c = 'Hardware',
                Support_Tier__c = 'S2'
            );
            listParentProduct.add(parentProductOne);
            
            Product2 parentProductTwo = new Product2(
                Name = 'RBK-R6408S-HW-01',
                ProductCode = 'RBK-R6408S-HW-01',
                Category__c = 'Hardware',
                SBQQ__AssetConversion__c = null,
                Eligible_for_RCDM_T__c = true,
                SBQQSC__EntitlementConversion__c = null,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__SubscriptionTerm__c = null,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = null,
                IsActive = true,
                Asset_Priority__c = 0,
                New_CPQ_Product__c = true,
                After_Conversion_Product_Level__c = 'Hardware',
                Support_Tier__c = 'S3'
            );
            listParentProduct.add(parentProductTwo);
            insert listParentProduct;
            
            List<Product2> listOldProduct = new List<Product2>();
            Product2 productOne = new Product2(
                Name = 'RBK-GO-EE-6404-CNV',
                ProductCode = 'RBK-GO-EE-6404-CNV',
                Category__c = 'Bundle',
                Eligible_for_RCDM_T__c = true,
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = null,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = null,
                New_CPQ_Product__c = false,
                After_Conversion_Product_Level__c = 'Hybrid Software'
            );
            listOldProduct.add(productOne);
            
            Product2 productTwo = new Product2(
                Name = 'RBK-GO-FE-6408-CNV',
                ProductCode = 'RBK-GO-FE-6408-CNV',
                Eligible_for_RCDM_T__c = true,
                Category__c = 'Bundle',
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = 'One per quote line',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = null,
                New_CPQ_Product__c = false,
                After_Conversion_Product_Level__c = 'Hybrid Software'
            );
            listOldProduct.add(productTwo);
            
            Product2 productThree = new Product2(
                Name = 'RBK-HW-SUP-PE-CNV',
                ProductCode = 'RBK-HW-SUP-PE-CNV',
                Category__c = 'Support',
                Eligible_for_RCDM_T__c=true,
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = null,
                New_CPQ_Product__c = false,
                After_Conversion_Product_Level__c = 'Support'
            );
            listOldProduct.add(productThree);
            
            Product2 product4 = new Product2(
                Name = 'RS-BT-RCDM-T',
                ProductCode = 'RS-BT-RCDM-T',
                Category__c = 'Platform',
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = null,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__SubscriptionTerm__c = null,
                SBQQ__SubscriptionBase__c = null,
                SBQQ__SubscriptionType__c = null,
                IsActive = true
            );
            listOldProduct.add(product4);
            insert listOldProduct;
            
            List<Product2> listNewProduct = new List<Product2>();
            Product2 product1 = new Product2(
                Name = 'RS-HW-SVC-PE-S2',
                ProductCode = 'RS-HW-SVC-PE-S2',
                Category__c = 'Support',
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = null,
                New_CPQ_Product__c = false,
                Support_Tier__c = 'S2',
                Product_Level__c = 'HW Support'
            );
            listNewProduct.add(product1);
            
            Product2 product21 = new Product2(
                Name = 'RS-HW-SVC-PE-S3',
                ProductCode = 'RS-HW-SVC-PE-S3',
                Category__c = 'Support',
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = null,
                New_CPQ_Product__c = false,
                Support_Tier__c = 'S3',
                Product_Level__c = 'HW Support'
            );
            listNewProduct.add(product21);
            
            Product2 product3 = new Product2(
                Name = 'RS-HW-SVC-PE-E1',
                ProductCode = 'RS-HW-SVC-PE-E1',
                Category__c = 'Support',
                SBQQ__AssetConversion__c = null,
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = null,
                New_CPQ_Product__c = false
            );
            listNewProduct.add(product3);
            
            
            
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            PricebookEntry pbPP1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbPP1.Product2Id = parentProductOne.Id;
            pBList.add(pbPP1);
            
            PricebookEntry pbPP2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbPP2.Product2Id = parentProductTwo.Id;
            pBList.add(pbPP2);
            
            PricebookEntry pb1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb1.Product2Id = productOne.Id;
            pBList.add(pb1);
            
            PricebookEntry pb2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb2.Product2Id = productTwo.Id;
            pBList.add(pb2);
            
            PricebookEntry pb3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb3.Product2Id = productThree.Id;
            pBList.add(pb3);
            
            PricebookEntry pb4 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pb4.Product2Id = product4.Id;
            pBList.add(pb4);
            insert pBList;
            
            List<Asset> listAsset = new List<Asset>();
            Asset newAsset1 = new Asset(Name = 'AA184864040119', SerialNumber = 'AA184864040119', Product2Id = parentProductTwo.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = '8021WCOMKEY');
            listAsset.add(newAsset1);
            
            Asset newAsset2 = new Asset(Name = 'AA184864040126', SerialNumber = 'AA184864040126', Product2Id = parentProductTwo.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = '8021WCOMKEY');
            listAsset.add(newAsset2);
            
            Asset newAsset3 = new Asset(Name = 'AA191364080094', SerialNumber = 'AA191364080094', Product2Id = parentProductOne.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = '8021W0COMKEY');
            listAsset.add(newAsset3);
            
            insert listAsset;
            
            Polaris_SKU_Mapping_V2__c polMap1 = new Polaris_SKU_Mapping_V2__c();
            polMap1.Old_Product__c = productThree.id;
            polMap1.New_Product__c = product1.Id;
            polMap1.After_Conversion_Product_Level__c = 'Support';
            polMap1.Support_Tier__c = 'S2';
            polMap1.Payment_Option__c = 'Prepay';
            polMap1.Support_Type__c = 'Premium';
            insert polMap1;
            
            Polaris_SKU_Mapping_V2__c polMap2 = new Polaris_SKU_Mapping_V2__c();
            polMap2.Old_Product__c = productThree.id;
            polMap2.New_Product__c = product21.Id;
            polMap2.After_Conversion_Product_Level__c = 'Support';
            polMap2.Support_Tier__c = 'S3';
            polMap2.Support_Type__c = 'Premium';
            polMap2.Payment_Option__c = 'Prepay';
            insert polMap2;
            
            Polaris_SKU_Mapping_V2__c polMap3 = new Polaris_SKU_Mapping_V2__c();
            polMap3.Old_Product__c = productThree.id;
            polMap3.New_Product__c = product3.Id;
            polMap3.After_Conversion_Product_Level__c = 'Support';
            polMap3.Support_Tier__c = 'E1';
            polMap3.Payment_Option__c = 'Prepay';
            polMap2.Support_Type__c = 'Premium';
            insert polMap3;
            
            ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj1.SBQQSC__Account__c = act.Id;
            ContractLineItemObj1.PricebookEntryId = pb1.Id;
            ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj1.Quantity = 2;
            ContractLineItemObj1.Payment_Options__c = null;
            ContractLineItemObj1.Support_Type__c = 'Premium';
            //ContractLineItemObj1.AssetId = newAsset1.Id;
            ContractLineItemObj1.UnitPrice = 100;
            ContractLineItemObj1.SBQQSC__RequiredById__c = newAsset1.Id;
            ContractLineItemObj1.SBQQSC__SubscriptionPricing__c=null;
            ContractLineItemObj1.SBQQSC__Product__c = productTwo.Id;//RBK-GO-EE-6404-CNV - 2
            ContractLineItemObj1.Licensing_Model__c = null;
            ContractLineItemObj1.StartDate = System.today();
            ContractLineItemObj1.EndDate =System.today() + 150;
            ContractLineItemObj1.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObj1.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObj1.SBQQSC__RenewalQuantity__c = 2;       
            insert ContractLineItemObj1;
            
            ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj2.SBQQSC__Account__c = act.Id;
            ContractLineItemObj2.PricebookEntryId = pb2.Id;
            ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj2.Quantity = 1;
            ContractLineItemObj2.Payment_Options__c = 'Prepay';
            ContractLineItemObj2.Support_Type__c = 'Premium';
            //ContractLineItemObj2.AssetId = newAsset2.Id;
            ContractLineItemObj2.UnitPrice = 100;
            ContractLineItemObj2.SBQQSC__RequiredById__c = newAsset3.Id;
            ContractLineItemObj2.SBQQSC__SubscriptionPricing__c=null;
            ContractLineItemObj2.SBQQSC__Product__c = productOne.Id;
            ContractLineItemObj2.Licensing_Model__c = null;
            ContractLineItemObj2.StartDate = System.today();
            ContractLineItemObj2.EndDate =System.today() + 150;
            ContractLineItemObj2.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObj2.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 1;       
            insert ContractLineItemObj2;
            
            
            ContractLineItem ContractLineItemObj3 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj3.SBQQSC__Account__c = act.Id;
            ContractLineItemObj3.PricebookEntryId = pb3.Id;
            ContractLineItemObj3.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj3.Quantity = 3;
            ContractLineItemObj3.Payment_Options__c = 'Prepay';
            ContractLineItemObj3.Support_Type__c = 'Premium';
            //ContractLineItemObj3.AssetId = newAsset3.Id;
            ContractLineItemObj3.UnitPrice = 100;
            ContractLineItemObj3.SBQQSC__RequiredById__c = ContractLineItemObj2.Id;
            ContractLineItemObj3.SBQQSC__SubscriptionPricing__c=null;
            ContractLineItemObj3.SBQQSC__Product__c = productThree.Id;
            ContractLineItemObj3.Licensing_Model__c = null;
            ContractLineItemObj3.StartDate = System.today();
            ContractLineItemObj3.EndDate =System.today() + 150;
            ContractLineItemObj3.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObj3.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObj3.SBQQSC__RenewalQuantity__c = 3;       
            insert ContractLineItemObj3;
            
            ContractLineItem ContractLineItemObj4 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj4.SBQQSC__Account__c = act.Id;
            ContractLineItemObj4.PricebookEntryId = pb4.Id;
            ContractLineItemObj4.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj4.Quantity = 3;
            ContractLineItemObj4.Payment_Options__c = 'Prepay';
            ContractLineItemObj4.Support_Type__c = 'Premium';
            //ContractLineItemObj3.AssetId = newAsset3.Id;
            ContractLineItemObj4.UnitPrice = 100;
            ContractLineItemObj4.SBQQSC__RequiredById__c = ContractLineItemObj2.Id;
            ContractLineItemObj4.SBQQSC__SubscriptionPricing__c=null;
            ContractLineItemObj4.SBQQSC__Product__c = product4.Id;
            ContractLineItemObj4.Licensing_Model__c = null;
            ContractLineItemObj4.StartDate = System.today();
            ContractLineItemObj4.EndDate =System.today() + 150;
            //ContractLineItemObj4.SBQQSC__ProductSubscriptionType__c='Renewable';
            // ContractLineItemObj4.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObj4.SBQQSC__RenewalQuantity__c = 3;       
            insert ContractLineItemObj4;
            
            
            
            Entitlement enttitlementNewObj1 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj1.AccountId = act.Id;
            enttitlementNewObj1.StartDate = Date.today().addDays(-365);
            enttitlementNewObj1.EndDate = Date.today().addDays(+900);
            enttitlementNewObj1.ContractLineItemId = ContractLineItemObj1.Id;//RBK-GO-EE-6404-CNV - 2
            enttitlementNewObj1.Renewable__c = true;
            enttitlementNewObj1.AssetId =newAsset1.Id ;
            enttitlementNewObj1.Type = 'Phone Support';
            enttitlementNewObj1.Renewal_Category__c = 'Renew later';
            enttitlementNewObj1.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj1.Product__c = productTwo.Id; 
            
            enttitlementNewObj1.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj1.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj1;
            
            Entitlement enttitlementNewObj11 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj11.AccountId = act.Id;
            enttitlementNewObj11.StartDate = Date.today().addDays(-365);
            enttitlementNewObj11.EndDate = Date.today().addDays(+900);
            enttitlementNewObj11.ContractLineItemId = ContractLineItemObj1.Id;//RBK-GO-EE-6404-CNV - 2
            enttitlementNewObj11.Renewable__c = true;
            enttitlementNewObj11.AssetId =newAsset2.Id ;
            enttitlementNewObj11.Type = 'Phone Support';
            enttitlementNewObj11.Renewal_Category__c = 'Renew later';
            enttitlementNewObj11.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj11.Product__c = productTwo.Id; 
            
            enttitlementNewObj11.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj11.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj11;
            
            
            
            
            Entitlement enttitlementNewObj2 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj2.AccountId = act.Id;
            enttitlementNewObj2.StartDate = Date.today().addDays(-365);
            enttitlementNewObj2.EndDate = Date.today().addDays(+150);
            enttitlementNewObj2.ContractLineItemId = ContractLineItemObj2.Id;//RBK-GO-FE-6408-CNV - 1
            enttitlementNewObj2.Renewable__c = true;
            enttitlementNewObj2.AssetId =newAsset2.Id ;
            enttitlementNewObj2.Type = 'Phone Support';
            enttitlementNewObj2.Renewal_Category__c = 'Renew later';
            enttitlementNewObj2.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj2.Product__c = productOne.Id; 
            enttitlementNewObj2.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj2.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj2;
            
            Entitlement enttitlementNewObj3 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj3.AccountId = act.Id;
            enttitlementNewObj3.StartDate = Date.today().addDays(-365);
            enttitlementNewObj3.EndDate = Date.today().addDays(+900);
            enttitlementNewObj3.ContractLineItemId = ContractLineItemObj3.Id;//HW-SUP-CNV - 3
            enttitlementNewObj3.Renewable__c = true;
            enttitlementNewObj3.AssetId =newAsset3.Id ;
            enttitlementNewObj3.Type = 'Phone Support';
            enttitlementNewObj3.Renewal_Category__c = 'Renew later';
            enttitlementNewObj3.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj3.Product__c = productThree.Id; 
            enttitlementNewObj3.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj3.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj3;
            
            Entitlement enttitlementNewObj31 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj31.AccountId = act.Id;
            enttitlementNewObj31.StartDate = Date.today().addDays(-365);
            enttitlementNewObj31.EndDate = Date.today().addDays(+900);
            enttitlementNewObj31.ContractLineItemId = ContractLineItemObj3.Id;//HW-SUP-CNV - 3
            enttitlementNewObj31.Renewable__c = true;
            enttitlementNewObj31.AssetId =newAsset3.Id ;
            enttitlementNewObj31.Type = 'Phone Support';
            enttitlementNewObj31.Renewal_Category__c = 'Renew later';
            enttitlementNewObj31.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj31.Product__c = productThree.Id; 
            enttitlementNewObj31.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj31.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj31;
            
            
            Entitlement enttitlementNewObj32 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj32.AccountId = act.Id;
            enttitlementNewObj32.StartDate = Date.today().addDays(-365);
            enttitlementNewObj32.EndDate = Date.today().addDays(+900);
            enttitlementNewObj32.ContractLineItemId = ContractLineItemObj3.Id;//HW-SUP-CNV - 3
            enttitlementNewObj32.Renewable__c = true;
            enttitlementNewObj32.AssetId =newAsset3.Id ;
            enttitlementNewObj32.Type = 'Phone Support';
            enttitlementNewObj32.Renewal_Category__c = 'Renew later';
            enttitlementNewObj32.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj32.Product__c = productThree.Id; 
            enttitlementNewObj32.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj32.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj32;
            
            Entitlement enttitlementNewObj34 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj34.AccountId = act.Id;
            enttitlementNewObj34.StartDate = Date.today().addDays(-365);
            enttitlementNewObj34.EndDate = Date.today().addDays(+900);
            enttitlementNewObj34.ContractLineItemId = ContractLineItemObj4.Id;//RCDMT
            enttitlementNewObj34.Renewable__c = false;
            //enttitlementNewObj34.AssetId =newAsset3.Id ;
            enttitlementNewObj34.Type = 'Phone Support';
            enttitlementNewObj34.Renewal_Category__c = 'Renew later';
            enttitlementNewObj34.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj34.Product__c = productThree.Id; 
            enttitlementNewObj34.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj34.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj34;
            
            List<SBQQ__Quote__c> qList = [Select Id From SBQQ__Quote__c LIMIT 1];
            
            test.startTest();
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal+Expansion';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.RCDMT_EOL_Date__c  = Date.newInstance(2040, 1, 1);
            insert qt;
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            
            
            SBQQ__QuoteLine__c qliHW11 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,SBQQ__Product__c = parentProductTwo.Id,SBQQ__RenewedAsset__c =newAsset2.Id,  SBQQ__Quantity__c = 2, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'AA184864040119, AA184864040126',SBQQ__SubscribedAssetIds__c = '02i1W00000SJbIMQA1, 02i1W00000SJbLHQA1');
            qliList.add(qliHW11);
            SBQQ__QuoteLine__c qliHW22 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,SBQQ__Product__c = parentProductOne.Id,SBQQ__RenewedAsset__c =newAsset1.Id,  SBQQ__Quantity__c = 1, SBQQ__Number__c = 3, SubscribedAssetNames__c = 'AA191364080094',  SBQQ__SubscribedAssetIds__c = '02i1W00000TcbfPQAR, 02i1W00000SJbLHQA1');
            qliList.add(qliHW22);
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Prior_Net_Total__c = 30,Prior_Net_Total_With_Uplift__c = 30,SBQQ__Product__c = productTwo.Id , SBQQ__Quantity__c = 2, SBQQ__Number__c = 2, 
                                                             SubscribedAssetNames__c = 'AA184864040119, AA184864040126', SBQQ__RequiredBy__c = qliHW11.Id , SBQQ__SubscribedAssetIds__c = '02i1W00000SJbIMQA1, 02i1W00000SJbLHQA1');
            TriggerControls.disableQuoteLineTrigger = true;
            insert qli1; 
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Prior_Net_Total__c = 30,Prior_Net_Total_With_Uplift__c = 30, SBQQ__Product__c = productOne.Id,SBQQSC__RenewedContractLine__c =ContractLineItemObj2.Id,  SBQQ__Quantity__c = 1, SBQQ__StartDate__c = System.Today(),
                                                             SBQQ__Number__c = 4,  SubscribedAssetNames__c = 'AA191364080094', SBQQ__RequiredBy__c = qliHW22.Id , SBQQ__SubscribedAssetIds__c = '02i1W00000TcbfPQAR, 02i1W00000SJbLHQA1');
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, Prior_Net_Total__c = 30,Prior_Net_Total_With_Uplift__c = 30,SBQQ__Product__c = productThree.Id, SBQQ__Quantity__c = 3, SBQQ__StartDate__c = System.Today(),
                                                             SBQQ__Number__c = 5,SubscribedAssetNames__c = 'AA191364080094, AA184864040126, AA184864040119', SBQQ__SubscribedAssetIds__c = '02i1W00000SJbIMQA1, 02i1W00000SJbLHQA1, 02i1W00000TcbfPQAR' , SBQQSC__RenewedContractLine__c = ContractLineItemObj4.Id);
            
            qliList.add( qli2 );
            qliList.add( qli3 );
            insert qliList;
            
            X0_RCDM_Dates__mdt rcdmDatesObj1 = new X0_RCDM_Dates__mdt(); 
            List<SBQQ__QuoteLineGroup__c> groupLst = new List<SBQQ__QuoteLineGroup__c>();
            
            TriggerControls.disableQuoteLineTrigger = false;
            qList.add(qt);
            ConvertToSaasRenewalBatch qUpdate = new ConvertToSaasRenewalBatch(qList);
            ConvertToSaasRenewalBatch.getRDCMTLine(qliHW11,rcdmDatesObj1, groupLst);
            Database.executeBatch(qupdate,1);
            test.stoptest();
        }
    } 
    /***********************************************************************************************************
* Method Name          : testConvertDSAAS
* Date Created/Modified: 25/07/2025
* Author               : 
* @description         : Test conversion
/**********************************************************************************************************/
    
    public static testMethod void  testConvertDSAAS(){
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_ServiceContract_Trigger__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        dbl.Disable_Contract_Line_Item_Triggers__c = true;
        dbl.Disable_Entitlement_Validation_Rules__c = true;
        dbl.Disable_Product2_Trigger__c = true;
        dbl.SetupOwnerId = usr1.Id;
        insert dbl;
        
        System.runAs(usr1) {
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act; 
            
            Id pbId = Test.getStandardPriceBookId();  
            
            //opportunity
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c = pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                     PriceBook2Id = pbId,Term = 12, EndDate = System.today() + 365);
            insert serviceContractObj;
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size()); 
            
            //create products
            List<Product2> listProducts = new List<Product2>();
            
            Product2 newDSAAS = new Product2(
                Name = 'RS-FT-EE-UDSB-PE-PP',
                ProductCode = 'RS-FT-EE-UDSB-PE-PP',
                IsActive = true,
                Support_Split_Percent__c = 0.9,
                Product_Type__c = 'DSAAS'
            );
            listProducts.add(newDSAAS);
            
            Product2 cvbProd = new Product2(
                Name = 'RS-BT-CVB-PE-PP',
                ProductCode = 'RS-BT-CVB-PE-PP',
                IsActive = true,
                Product_Type__c = 'Cloud Vault Backup'
            );
            listProducts.add(cvbProd);
            
            Product2 oldDSAAS = new Product2(
                Name = 'RS-FT-EE-UDS-PE-PP',
                ProductCode = 'RS-FT-EE-UDS-PE-PP',
                IsActive = true,
                Custom_Renewal_Type__c = 'DSAAS',
                Is_Split_in_Polaris_2_0__c = true,
                Eligible_for_RCDM_T__c = true
            );
            listProducts.add(oldDSAAS);
            
            insert listProducts;
            
            //create product option
            SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = newDSAAS.Id,
                SBQQ__OptionalSKU__c = cvbProd.Id,
                SBQQ__Number__c = 10,
                SBQQ__Type__c = 'Related Product'
            );
            insert prodOption;
            
            //add to pricebook
            List<PricebookEntry> pbList = new List<PricebookEntry>();
            
            PricebookEntry pbNewDSAAS = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbNewDSAAS.Product2Id = newDSAAS.Id;
            pbNewDSAAS.UnitPrice = 100;
            pbList.add(pbNewDSAAS);
            
            PricebookEntry pbCVB = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbCVB.Product2Id = cvbProd.Id;
            pbCVB.UnitPrice = 10;
            pbList.add(pbCVB);
            
            PricebookEntry pbOldDSAAS = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbOldDSAAS.Product2Id = oldDSAAS.Id;
            pbList.add(pbOldDSAAS);
            
            insert pbList;
            
            newDSAAS.Pricebook_Entry_Id__c = pbNewDSAAS.Id;
            oldDSAAS.Custom_Renewal_Product__c = newDSAAS.Id;
            oldDSAAS.Custom_Renewal_Attributes__c = '{"RCVProd":"'+cvbProd.Id+'", "RCVProdPricebook":"'+pbCVB.Id+'", "RCVProdOption":"'+prodOption.Id+'", "RCVQuantRatio":12}';
            
            update listProducts;
            
            //create contract lines
            ContractLineItem cliOldDSAAS = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            cliOldDSAAS.SBQQSC__Account__c = act.Id;
            cliOldDSAAS.PricebookEntryId = pbOldDSAAS.Id;
            cliOldDSAAS.ServiceContractId = serviceContractObj.Id;
            cliOldDSAAS.SBQQSC__ProrateMultiplier__c = 12;
            cliOldDSAAS.UnitPrice = 100;
            cliOldDSAAS.SBQQSC__Quantity__c = 1;
            insert cliOldDSAAS;
            
            test.startTest();
            
            //create quote
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};   
                SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__StartDate__c = Date.today();
            insert qt;
            
            
            //create quotlines
            SBQQ__QuoteLine__c qliOldDSAAS = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = oldDSAAS.Id, SBQQSC__RenewedContractLine__c = cliOldDSAAS.Id,  SBQQ__Quantity__c = 1, SBQQ__Number__c = 1,
                                                                    CPQ_Uplift__c = '7');
            insert qliOldDSAAS;
            
            ConvertToSaasRenewalBatch.convertDSAAS(qt);
            test.stoptest();
        }
    }
    /***********************************************************************************************************
* Method Name          : sonarV2ConversionTest
* Date Created/Modified: 25/07/2025
* Author               : 
* @description         : Test conversion
/**********************************************************************************************************/
    
    static testMethod void sonarV2ConversionTest() {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
        custsetting.DisableTrigger__c = true;
        insert custsetting;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        ShGl_DisableBusinessLogic__c cdf = 
            new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                             Disable_SBQQ_Quote_Triggers__c = True,
                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                             Disable_Opportunity_Validation_Rules__c = True,
                                             Disable_Opportunity_Triggers__c = True,
                                             Disable_Campaign_Member_Triggers__c = true,
                                             Disable_Campaign_Trigger__c = true,
                                             Disable_Campaign_Validation_Rules__c = true,
                                             Disable_Order_Validation_Rules__c=true, 
                                             Disable_ServiceContract_Trigger__c=true,
                                             Disable_Entitlement_Usage_Trigger__c=true,
                                             Disable_Entitlement_Trigger__c=true,
                                             Disable_Contract_Line_Item_Triggers__c = true,
                                             Disable_Entitlement_Validation_Rules__c = true,
                                             SetupOwnerId = usr1.Id,
                                             Disable_Asset_Triggers__c=true,
                                             Disable_SBQQ_QuoteLine_Triggers__c = true);    
        insert cdf;
        /*User runningUser = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];
UPSERT new ShGl_DisableBusinessLogic__c(
SetupOwnerId = runningUser.Id,
Disable_Entitlement_Validation_Rules__c = true,
Disable_Order_Validation_Rules__c=true
);*/
        System.runAs(usr1){
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Eligible_for_RCDM_T__c = true;
            insert act; 
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> { 'AccountId' => act.Id };
                Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c = pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = 
                new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                    PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150);
            insert serviceContractObj;
            
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size());
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};    
                
                Map<String, Object> p1 = new Map<String, Object> {
                    'Name' => 'RBK-BT-SNR-R6304' ,
                        'ProductCode' => 'RBK-BT-SNR-R6304',
                        'IsActive' => true,
                        'After_Conversion_Product_Level__c' => 'Hybrid Software',
                        'Product_Type__c' => 'Sonar',
                        'Add_on_Level__c' => 'RCDM Add-On',
                        'SBQQSC__EntitlementConversion__c' => 'One per quote line'
                        };
                            
                            Map<String, Object> p2 = new Map<String, Object> {
                                'Name' => 'RS-BT-SNR-PE-PP',
                                    'ProductCode' => 'RS-BT-SNR-PE-PP',
                                    'IsActive' => true,
                                    'After_Conversion_Product_Level__c' => 'Hybrid Software',
                                    'Product_Type__c' => 'Sonar',
                                    'Add_on_Level__c' => 'RCDM Add-On',
                                    'SBQQSC__EntitlementConversion__c' => 'One per quote line'
                                    };
                                        
                                        Map<String, Object> p3 = new Map<String, Object> {
                                            'Name' => 'RBK-R6412S-HW-01',
                                                'ProductCode' => 'RBK-R6412S-HW-01',
                                                'IsActive' => true,
                                                'Support_Tier__c' => 'S2',
                                                'Usable_Capacity__c' => 75,
                                                'After_Conversion_Product_Level__c' => 'Hardware'
                                                };
                                                    Map<String, Object> p4 = new Map<String, Object> {
                                                        'Name' => 'RBK-R6412S-HW-01Test',
                                                            'ProductCode' => 'RBK-R6412S-HW-01',
                                                            'IsActive' => true,
                                                            'Support_Tier__c' => 'S2',
                                                            'Usable_Capacity__c' => 75,
                                                            'After_Conversion_Product_Level__c' => 'Hardware'
                                                            };
                                                                
                                                                List<Product2> prodList = new List<Product2>();
            Product2 Product1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p1);
            Product1.Eligible_for_RCDM_T__c = true;
            Product2 Product2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p2); 
            Product2 Product3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p3 ); 
            Product2 Product4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p4 );
            
            prodList.add(Product1);
            prodList.add(Product2);
            prodList.add(Product3);
            prodList.add(Product4);
            
            insert prodList;
            
            List<Product2> listOldProduct = new List<Product2>();
            List<Product2> newProductList = new List<Product2>();
            listOldProduct.add(Product1);//GO-FNDN - 0
            listOldProduct.add(Product3);//HW Supp - 2
            listOldProduct.add(Product4);
            
            newProductList.add(Product2);//BT-PE-PP
            newProductList.add(Product3);//HW
            newProductList.add(Product4);
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            
            PricebookEntry sonarPBEv1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            sonarPBEv1.Product2Id = Product1.Id;
            pBList.add(sonarPBEv1);
            
            PricebookEntry sonarPBEv2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            sonarPBEv2.Product2Id = Product2.Id;
            pBList.add(sonarPBEv2);   
            
            PricebookEntry hwSupp = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            hwSupp.Product2Id = Product3.Id;
            pBList.add(hwSupp);
            
            PricebookEntry hwSuppTest = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            hwSuppTest.Product2Id = Product4.Id;
            pBList.add(hwSuppTest);
            
            insert pBList;
            
            List<Polaris_SKU_Mapping_V2__c> polarisMappingList = new List<Polaris_SKU_Mapping_V2__c>();
            
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingSNR = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[0], newProductList[0]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingHW = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[1], newProductList[1]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingHWTest = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[2], newProductList[2]);
            
            polarisSKUMappingSNR.After_Conversion_Product_Level__c = 'Hybrid Software';
            polarisSKUMappingSNR.Quantity_Mapping_Type__c = 'Ratio Based';
            polarisSKUMappingSNR.Quantity_Ratio__c = 1;
            polarisSKUMappingSNR.Support_Tier__c = '';
            
            polarisSKUMappingHW.After_Conversion_Product_Level__c = 'Hardware';
            polarisSKUMappingHW.Quantity_Mapping_Type__c = 'Appliance Based';
            polarisSKUMappingHW.Quantity_Ratio__c = 10;
            polarisSKUMappingHW.Support_Tier__c = '';
            
            polarisSKUMappingHWTest.After_Conversion_Product_Level__c = 'Hardware';
            polarisSKUMappingHWTest.Quantity_Mapping_Type__c = 'Appliance Based';
            polarisSKUMappingHWTest.Quantity_Ratio__c = 10;
            polarisSKUMappingHWTest.Support_Tier__c = '';
            
            polarisMappingList.add(polarisSKUMappingSNR);
            polarisMappingList.add(polarisSKUMappingHW);
            polarisMappingList.add(polarisSKUMappingHWTest);
            
            insert polarisMappingList;
            Asset newAsset = new Asset(Name = 'AA165203480078', SerialNumber = 'AA210964120095', Product2Id = Product1.Id, AccountId = act.Id, ContactId = cnt.Id, SBQQ__CombineKey__c = '8026COMKEY');
            insert newAsset;
            
            ContractLineItem ContractLineItemObjMul4 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul4.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul4.PricebookEntryId = sonarPBEv1.Id;
            ContractLineItemObjMul4.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul4.Quantity = 10;
            ContractLineItemObjMul4.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul4.Support_Type__c = 'Premium';
            ContractLineItemObjMul4.UnitPrice = 100;
            ContractLineItemObjMul4.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul4.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMul4.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul4.StartDate = System.today();
            ContractLineItemObjMul4.EndDate =System.today() + 150;
            ContractLineItemObjMul4.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul4.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul4.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul4;
            
            ContractLineItem ContractLineItemObjMul5 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul5.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul5.PricebookEntryId = hwSupp.Id;
            ContractLineItemObjMul5.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul5.Quantity = 10;
            ContractLineItemObjMul5.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul5.Support_Type__c = 'Premium';
            ContractLineItemObjMul5.UnitPrice = 100;
            ContractLineItemObjMul5.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul5.SBQQSC__Product__c = Product3.Id;
            ContractLineItemObjMul5.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul5.StartDate = System.today();
            ContractLineItemObjMul5.EndDate =System.today() + 150;
            ContractLineItemObjMul5.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul5.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul5.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul5;
            
            ContractLineItem ContractLineItemObjMul6 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul6.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul6.PricebookEntryId =  hwSuppTest.Id;
            ContractLineItemObjMul6.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul6.Quantity = 10;
            ContractLineItemObjMul6.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul6.Support_Type__c = 'Premium';
            ContractLineItemObjMul6.UnitPrice = 100;
            ContractLineItemObjMul6.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul6.SBQQSC__Product__c = Product4.Id;
            ContractLineItemObjMul6.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul6.StartDate = System.today();
            ContractLineItemObjMul6.EndDate =System.today() + 150;
            ContractLineItemObjMul6.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul6.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul6.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul6;
            
            Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj6.AccountId = act.Id;
            enttitlementNewObj6.StartDate = Date.today().addDays(-365);
            enttitlementNewObj6.EndDate = Date.today().addDays(+900);
            enttitlementNewObj6.ContractLineItemId = ContractLineItemObjMul4.Id;
            enttitlementNewObj6.Renewable__c = true;
            enttitlementNewObj6.Type = 'Phone Support';
            enttitlementNewObj6.Renewal_Category__c = 'Renew later';
            enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj6.Product__c = Product1.Id; 
            enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj6.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj6;      
            
            Entitlement enttitlementNewObj8 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj8.AccountId = act.Id;
            enttitlementNewObj8.StartDate = Date.today().addDays(-365);
            enttitlementNewObj8.EndDate = Date.today().addDays(+900);
            enttitlementNewObj8.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj8.Renewable__c = true;
            enttitlementNewObj8.Type = 'Phone Support';
            enttitlementNewObj8.Renewal_Category__c = 'Renew later';
            enttitlementNewObj8.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj8.Product__c = Product1.Id; 
            enttitlementNewObj8.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj8.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj8; 
            
            Entitlement enttitlementNewObj9 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj9.AccountId = act.Id;
            enttitlementNewObj9.StartDate = Date.today().addDays(-365);
            enttitlementNewObj9.EndDate = Date.today().addDays(+900);
            enttitlementNewObj9.ContractLineItemId = ContractLineItemObjMul6.Id;
            enttitlementNewObj9.Renewable__c = true;
            enttitlementNewObj9.Type = 'Phone Support';
            enttitlementNewObj9.Renewal_Category__c = 'Renew later';
            enttitlementNewObj9.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj9.Product__c = Product4.Id; 
            enttitlementNewObj9.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj9.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj9; 
            
            List<SBQQ__Quote__c> qList = new List<SBQQ__Quote__c>();
            test.startTest();
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            insert qt;
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = 
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = Product1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, 
                                       SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id,  
                                       SBQQSC__RenewedContractLine__c = ContractLineItemObjMul4.Id, required_by_ext_Id__c = qt.id );
            TriggerControls.disableQuoteLineTrigger = true;
            insert qli1;
            SBQQ__QuoteLine__c qli2 = 
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = Product3.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, 
                                       SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id, SBQQ__RequiredBy__c = qli1.Id, 
                                       SBQQSC__RenewedContractLine__c = ContractLineItemObjMul5.Id, required_by_ext_Id__c = qli1.id );
            insert qli2;
            SBQQ__QuoteLine__c qli3 = 
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = Product4.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, 
                                       SBQQ__StartDate__c = Date.newInstance(2022, 11, 11), SBQQ__SubscribedAssetIds__c = newAsset.id, SBQQ__RequiredBy__c = qli1.Id, 
                                       SBQQSC__RenewedContractLine__c = ContractLineItemObjMul6.Id, required_by_ext_Id__c = enttitlementNewObj9.id );
            insert qli3;
            
            TriggerControls.disableQuoteLineTrigger = false;
            qList.add(qt);
            ConvertToSaasRenewalBatch qUpdate = new ConvertToSaasRenewalBatch(qList);
            Database.executeBatch(qupdate,1);
            test.stoptest(); 
        }
    }/***********************************************************************************************************
* Method Name          : sonarV2ConversionTest
* Date Created/Modified: 25/07/2025
* Author               : 
* @description         : Test conversion
/**********************************************************************************************************/
    
    static testMethod void testRCDMScenario() {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
        custsetting.DisableTrigger__c = true;
        insert custsetting;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        ShGl_DisableBusinessLogic__c cdf = 
            new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                             Disable_SBQQ_Quote_Triggers__c = True,
                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                             Disable_Opportunity_Validation_Rules__c = True,
                                             Disable_Opportunity_Triggers__c = True,
                                             Disable_Campaign_Member_Triggers__c = true,
                                             Disable_Campaign_Trigger__c = true,
                                             Disable_Campaign_Validation_Rules__c = true,
                                             Disable_Order_Validation_Rules__c=true, 
                                             Disable_ServiceContract_Trigger__c=true,
                                             Disable_Entitlement_Usage_Trigger__c=true,
                                             Disable_Entitlement_Trigger__c=true,
                                             Disable_Contract_Line_Item_Triggers__c = true,
                                             Disable_Entitlement_Validation_Rules__c = true,
                                             SetupOwnerId = usr1.Id,
                                             Disable_Product2_Trigger__c = true,
                                             Disable_Asset_Triggers__c=true,
                                             Disable_SBQQ_QuoteLine_Triggers__c = true);    
        insert cdf;
        System.runAs(usr1){
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Eligible_for_RCDM_T__c = true;
            act.RCDMT_EOL_Date__c = Date.newInstance(2040, 1, 1);
            insert act; 
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> { 'AccountId' => act.Id };
                Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c = pbId;     
            insert opp;
            
            ServiceContract serviceContractObj = 
                new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                    PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150);
            insert serviceContractObj;
            
            List<ServiceContract> scList = new List<ServiceContract>();
            scList.add(serviceContractObj);
            Assert.areEqual(1, scList.size());
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};    
                
                Map<String, Object> p1 = new Map<String, Object> {
                    'Name' => 'RBK-BT-SNR-R6304' ,
                        'ProductCode' => 'RBK-BT-SNR-R6304',
                        'IsActive' => true,
                        'After_Conversion_Product_Level__c' => 'Hybrid Software',
                        'Product_Type__c' => 'Sonar',
                        'Add_on_Level__c' => 'RCDM Add-On',
                        'SBQQSC__EntitlementConversion__c' => 'One per quote line',
                        'Eligible_for_RCDM_T__c' => true
                        };
                            
                            Map<String, Object> p2 = new Map<String, Object> {
                                'Name' => 'RS-BT-SNR-PE-PP',
                                    'ProductCode' => 'RS-BT-SNR-PE-PP',
                                    'IsActive' => true,
                                    'After_Conversion_Product_Level__c' => 'Hybrid Software',
                                    'Product_Type__c' => 'Sonar',
                                    'Add_on_Level__c' => 'RCDM Add-On',
                                    'SBQQSC__EntitlementConversion__c' => 'One per quote line',
                                    'Eligible_for_RCDM_T__c' => true
                                    };
                                        
                                        Map<String, Object> p3 = new Map<String, Object> {
                                            'Name' => 'RBK-R6412S-HW-01',
                                                'ProductCode' => 'RBK-R6412S-HW-01',
                                                'IsActive' => true,
                                                'Support_Tier__c' => 'S2',
                                                'Usable_Capacity__c' => 75,
                                                'After_Conversion_Product_Level__c' => 'Hardware'
                                                };
                                                    Map<String, Object> p4 = new Map<String, Object> {
                                                        'Name' => 'RBK-R6412S-HW-01Test',
                                                            'ProductCode' => 'RBK-R6412S-HW-01Test',
                                                            'IsActive' => true,
                                                            'Support_Tier__c' => 'S2',
                                                            'Usable_Capacity__c' => 75,
                                                            'After_Conversion_Product_Level__c' => 'Hardware'
                                                            };
                                                                
                                                                List<Product2> prodList = new List<Product2>();
            Product2 Product1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p1);
            Product1.eligible_for_RCDM_T__c = true;
            Product2 Product2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p2); 
            Product2 Product3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p3 ); 
            Product2 Product4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), p4 );
            
            prodList.add(Product1);
            prodList.add(Product2);
            prodList.add(Product3);
            prodList.add(Product4);
            
            insert prodList;
            
            List<Product2> listOldProduct = new List<Product2>();
            List<Product2> newProductList = new List<Product2>();
            listOldProduct.add(Product1);//GO-FNDN - 0
            listOldProduct.add(Product3);//HW Supp - 2
            listOldProduct.add(Product4);
            
            newProductList.add(Product2);//BT-PE-PP
            newProductList.add(Product3);//HW
            newProductList.add(Product4);
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            
            PricebookEntry sonarPBEv1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            sonarPBEv1.Product2Id = Product1.Id;
            pBList.add(sonarPBEv1);
            
            PricebookEntry sonarPBEv2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            sonarPBEv2.Product2Id = Product2.Id;
            pBList.add(sonarPBEv2);   
            
            PricebookEntry hwSupp = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            hwSupp.Product2Id = Product3.Id;
            pBList.add(hwSupp);
            
            PricebookEntry hwSuppTest = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            hwSuppTest.Product2Id = Product4.Id;
            pBList.add(hwSuppTest);
            
            insert pBList;
            
            List<Polaris_SKU_Mapping_V2__c> polarisMappingList = new List<Polaris_SKU_Mapping_V2__c>();
            
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingSNR = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[0], newProductList[0]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingHW = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[1], newProductList[1]);
            Polaris_SKU_Mapping_V2__c  polarisSKUMappingHWTest = TestDataFactory.createPolarisSKUMappingRecord(listOldProduct[2], newProductList[2]);
            
            polarisSKUMappingSNR.After_Conversion_Product_Level__c = 'Hybrid Software';
            polarisSKUMappingSNR.Quantity_Mapping_Type__c = 'Ratio Based';
            polarisSKUMappingSNR.Quantity_Ratio__c = 1;
            polarisSKUMappingSNR.Support_Tier__c = '';
            
            polarisSKUMappingHW.After_Conversion_Product_Level__c = 'Hardware';
            polarisSKUMappingHW.Quantity_Mapping_Type__c = 'Appliance Based';
            polarisSKUMappingHW.Quantity_Ratio__c = 10;
            polarisSKUMappingHW.Support_Tier__c = '';
            //polarisSKUMappingHW.Eligible_for_RCDM_T__c = true;
            
            polarisSKUMappingHWTest.After_Conversion_Product_Level__c = 'Hardware';
            polarisSKUMappingHWTest.Quantity_Mapping_Type__c = 'Appliance Based';
            polarisSKUMappingHWTest.Quantity_Ratio__c = 10;
            polarisSKUMappingHWTest.Support_Tier__c = '';
            
            polarisMappingList.add(polarisSKUMappingSNR);
            polarisMappingList.add(polarisSKUMappingHW);
            polarisMappingList.add(polarisSKUMappingHWTest);
            
            insert polarisMappingList;
            Asset newAsset = new Asset(Name = 'AA165203480078', SerialNumber = 'AA210964120095', Product2Id = Product1.Id, AccountId = act.Id, ContactId = cnt.Id, SBQQ__CombineKey__c = '8026COMKEY');
            insert newAsset;
            
            ContractLineItem ContractLineItemObjMul4 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul4.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul4.PricebookEntryId = sonarPBEv1.Id;
            ContractLineItemObjMul4.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul4.Quantity = 10;
            ContractLineItemObjMul4.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul4.Support_Type__c = 'Premium';
            ContractLineItemObjMul4.UnitPrice = 100;
            ContractLineItemObjMul4.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul4.SBQQSC__Product__c = Product1.Id;
            ContractLineItemObjMul4.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul4.StartDate = System.today();
            ContractLineItemObjMul4.EndDate =System.today() + 150;
            ContractLineItemObjMul4.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul4.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul4.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul4;
            
            ContractLineItem ContractLineItemObjMul5 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul5.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul5.PricebookEntryId = hwSupp.Id;
            ContractLineItemObjMul5.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul5.Quantity = 10;
            ContractLineItemObjMul5.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul5.Support_Type__c = 'Premium';
            ContractLineItemObjMul5.UnitPrice = 100;
            ContractLineItemObjMul5.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul5.SBQQSC__Product__c = Product3.Id;
            ContractLineItemObjMul5.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul5.StartDate = System.today();
            ContractLineItemObjMul5.EndDate =System.today() + 150;
            ContractLineItemObjMul5.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul5.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul5.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul5;
            
            ContractLineItem ContractLineItemObjMul6 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObjMul6.SBQQSC__Account__c = act.Id;
            ContractLineItemObjMul6.PricebookEntryId =  hwSuppTest.Id;
            ContractLineItemObjMul6.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObjMul6.Quantity = 10;
            ContractLineItemObjMul6.Payment_Options__c = 'Prepay';
            ContractLineItemObjMul6.Support_Type__c = 'Premium';
            ContractLineItemObjMul6.UnitPrice = 100;
            ContractLineItemObjMul6.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObjMul6.SBQQSC__Product__c = Product4.Id;
            ContractLineItemObjMul6.Licensing_Model__c = 'Subscription';
            ContractLineItemObjMul6.StartDate = System.today();
            ContractLineItemObjMul6.EndDate =System.today() + 150;
            ContractLineItemObjMul6.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObjMul6.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObjMul6.SBQQSC__RenewalQuantity__c = 20;       
            insert ContractLineItemObjMul6;
            
            Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj6.AccountId = act.Id;
            enttitlementNewObj6.StartDate = Date.today().addDays(-365);
            enttitlementNewObj6.EndDate = Date.today().addDays(+900);
            enttitlementNewObj6.ContractLineItemId = ContractLineItemObjMul4.Id;
            enttitlementNewObj6.Renewable__c = true;
            enttitlementNewObj6.Type = 'Phone Support';
            enttitlementNewObj6.Renewal_Category__c = 'Renew later';
            enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj6.Product__c = Product1.Id; 
            enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj6.ServiceContractId = serviceContractObj.Id;
            //enttitlementNewObj7.Product_Usable_Capacity__c = 0;
            //    lstEntitlement.add(enttitlementNewObj5);
            insert enttitlementNewObj6;      
            
            Entitlement enttitlementNewObj8 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj8.AccountId = act.Id;
            enttitlementNewObj8.StartDate = Date.today().addDays(-365);
            enttitlementNewObj8.EndDate = Date.today().addDays(+900);
            enttitlementNewObj8.ContractLineItemId = ContractLineItemObjMul5.Id;
            enttitlementNewObj8.Renewable__c = true;
            enttitlementNewObj8.Type = 'Phone Support';
            enttitlementNewObj8.Renewal_Category__c = 'Renew later';
            enttitlementNewObj8.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj8.Product__c = Product1.Id; 
            enttitlementNewObj8.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj8.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj8; 
            
            Entitlement enttitlementNewObj9 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj9.AccountId = act.Id;
            enttitlementNewObj9.StartDate = Date.today().addDays(-365);
            enttitlementNewObj9.EndDate = Date.today().addDays(+900);
            enttitlementNewObj9.ContractLineItemId = ContractLineItemObjMul6.Id;
            enttitlementNewObj9.Renewable__c = true;
            enttitlementNewObj9.Type = 'Phone Support';
            enttitlementNewObj9.Renewal_Category__c = 'Renew later';
            enttitlementNewObj9.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj9.Product__c = Product4.Id; 
            enttitlementNewObj9.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj9.ServiceContractId = serviceContractObj.Id;
            insert enttitlementNewObj9; 
            
            List<SBQQ__Quote__c> qList = new List<SBQQ__Quote__c>();
            test.startTest();
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            //qt.Eligible_for_RCDM_T__c = true;
            qt.RCDMT_EOL_Date__c = Date.newInstance(2040, 1, 1);
            insert qt;
            
            SBQQ__QuoteLineGroup__c quoteLineGrp = new SBQQ__QuoteLineGroup__c(Name='Renewal Quote', SBQQ__Number__c= 2, 
                                                                               SBQQ__ListTotal__c= 100, SBQQ__CustomerTotal__c= 100,
                                                                               SBQQ__NetTotal__c= 200, SBQQ__Quote__c= qt.Id);
            insert quoteLineGrp;
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = 
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = Product1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, 
                                       SBQQ__StartDate__c = Date.newInstance(2022, 9, 9), SBQQ__SubscribedAssetIds__c = newAsset.id,  
                                       SBQQSC__RenewedContractLine__c = ContractLineItemObjMul4.Id, required_by_ext_Id__c = qt.id );
            TriggerControls.disableQuoteLineTrigger = true;
            insert qli1;
            SBQQ__QuoteLine__c qli2 = 
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = Product3.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, 
                                       SBQQ__StartDate__c = Date.newInstance(2022, 9, 9), SBQQ__SubscribedAssetIds__c = newAsset.id, SBQQ__RequiredBy__c = qli1.Id, 
                                       SBQQSC__RenewedContractLine__c = ContractLineItemObjMul5.Id, required_by_ext_Id__c = qli1.id );
            insert qli2;
            SBQQ__QuoteLine__c qli3 = 
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = Product4.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3, 
                                       SBQQ__StartDate__c = Date.newInstance(2022, 9, 9), SBQQ__SubscribedAssetIds__c = newAsset.id, SBQQ__RequiredBy__c = qli1.Id, 
                                       SBQQSC__RenewedContractLine__c = ContractLineItemObjMul6.Id, required_by_ext_Id__c = enttitlementNewObj9.id );
            insert qli3;
            
            TriggerControls.disableQuoteLineTrigger = false;
            qList.add(qt);
            ConvertToSaasRenewalBatch qUpdate = new ConvertToSaasRenewalBatch(qList);
            Database.executeBatch(qupdate,1);
            test.stoptest(); 
        }
    }
    
    /**
* @isTest
* Method Name - testV2ToV2Conversion
* Tests the V2 to V2 product conversion and renewal quote line creation process.
* Date:25/08/2025
* @description         : Test conversion v2 to v2
*/
    @isTest
    private static void testV2ToV2Conversion() {
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        System.runAs(usr1) {
            // Disable triggers and validation rules for test data creation
            ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(
                Disable_SBQQ_Quote_Validation_Rules__c = true,
                Disable_SBQQ_Quote_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
                Disable_Opportunity_Validation_Rules__c = true,
                Disable_Opportunity_Triggers__c = true,
                Disable_Campaign_Member_Triggers__c = true,
                Disable_Campaign_Trigger__c = true,
                Disable_Campaign_Validation_Rules__c = true,
                Disable_Order_Validation_Rules__c = true,
                Disable_ServiceContract_Trigger__c = true,
                Disable_Entitlement_Usage_Trigger__c = true,
                Disable_Entitlement_Trigger__c = true,
                Disable_Contract_Line_Item_Triggers__c = true,
                Disable_Entitlement_Validation_Rules__c = true,
                SetupOwnerId = usr1.Id,
                Disable_Asset_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Flows__c = true
            );
            insert cdf;
            
            // Create Account, Contact, Opportunity, and Service Contract
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), new Map<String, Object>{'AccountId' => act.Id});
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c = pbId;
            insert opp;
            
            // Create V2 to V2 source and target products
            List<Product2> listProducts = new List<Product2>();
            Product2 sourceProd = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MD-PE-PA',
                    ProductCode = 'RS-UR-FE-MD-PE-PA',
                    IsActive = true,
                    Custom_Renewal_Type__c = 'V2 To V2',
                    Product_Type__c = 'M365',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Storage_Tier__c = '20 GB',
                    CPQ_Uplift__c= '7',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            listProducts.add(sourceProd);
            Product2 sourceProd1 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MD-BS-PP',
                    ProductCode = 'RS-UR-FE-MD-BS-PP',
                    IsActive = true,
                    Custom_Renewal_Type__c = 'V2 To V2',
                    Product_Type__c = 'M365',
                    Product_Level__c = '',
                    License_per_Qty__c= 2,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Storage_Tier__c = 'Unlimited GB',
                    CPQ_Uplift__c= '7',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            
            listProducts.add(sourceProd1);            
            
            Product2 sourceProd2 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MD-BS-PsP',
                    ProductCode = 'RS-UR-FE-MD-BS-PsP',
                    IsActive = true,
                    Product_Type__c = 'Hardware',
                    Product_Level__c = '',
                    License_per_Qty__c= 2,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Storage_Tier__c = 'Unlimited GB',
                    CPQ_Uplift__c= '7',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            
            listProducts.add(sourceProd2);            
            
            Product2 targetProd1 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MS-PE-PA',
                    ProductCode = 'RS-UR-FE-MS-PE-PA',
                    IsActive = true,
                    Product_Type__c = 'M365',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Support_Tier__c = 'S1',
                    CPQ_Uplift__c= '7',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            listProducts.add(targetProd1);
            Product2 targetProd2 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-GB-MS-PE-PA',
                    ProductCode = 'RS-GB-MS-PE-PA',
                    IsActive = true,
                    Product_Type__c = 'M365 Storage',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Support_Tier__c = 'S1',
                    CPQ_Uplift__c= '7',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            listProducts.add(targetProd2);
            Product2 targetProd3 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-USL-PE-PP',
                    ProductCode = 'RS-UR-FE-USL-PE-PP',
                    IsActive = true,
                    Product_Type__c = 'M365',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Support_Tier__c = 'S1',
                    CPQ_Uplift__c= '7',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            listProducts.add(targetProd3);
            Product2 bundleParentProd = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'V2-To-V2-Parent-Product',
                    ProductCode = 'V2-V2-PARENT',
                    IsActive = true,
                    Product_Level__c = 'Hybrid Software',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price'
                ), null
            );
            listProducts.add(bundleParentProd);
            insert listProducts;
            
            // Create Pricebook Entries
            PricebookEntry pbeSource = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSource.Product2Id = sourceProd.Id; 
            pbeSource.UnitPrice = 100;
            PricebookEntry pbesource1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbesource1.Product2Id = sourceProd1.Id; 
            pbesource1.UnitPrice = 100;
            PricebookEntry pbesource2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbesource2.Product2Id = sourceProd2.Id; 
            pbesource2.UnitPrice = 100;
            PricebookEntry pbeTarget1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeTarget1.Product2Id = targetProd1.Id; 
            pbeTarget1.UnitPrice = 100;
            PricebookEntry pbeTarget2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeTarget2.Product2Id = targetProd2.Id; 
            pbeTarget2.UnitPrice = 100;
            PricebookEntry pbeParent = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeParent.Product2Id = bundleParentProd.Id; 
            pbeParent.UnitPrice = 10;
            PricebookEntry pbeTarget3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeTarget3.Product2Id = targetProd3.Id; 
            pbeTarget3.UnitPrice = 50;
            insert new List<PricebookEntry>{pbeSource,pbeSource1,pbeSource2, pbeTarget1,pbeTarget2,pbeTarget3, pbeParent};
                
                sourceProd.Pricebook_Entry_Id__c = pbeSource.Id;
            sourceProd1.Pricebook_Entry_Id__c = pbeSource1.Id;
            sourceProd2.Pricebook_Entry_Id__c = pbeSource2.Id;
            targetProd1.Pricebook_Entry_Id__c = pbeTarget1.Id;
            targetProd2.Pricebook_Entry_Id__c = pbeTarget2.Id;
            targetProd3.Pricebook_Entry_Id__c = pbeTarget3.Id;
            bundleParentProd.Pricebook_Entry_Id__c = pbeParent.Id;
            
            cdf.Disable_Product2_Trigger__c =true;
            update cdf;
            update listProducts;
            cdf.Disable_Product2_Trigger__c =false;
            update cdf;
            
            
            // Link the parent and child products via Product Option
            List<SBQQ__ProductOption__c> prodopsList = new List<SBQQ__ProductOption__c>();
            // Link the parent and child products via Product Option
            SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = bundleParentProd.Id,
                SBQQ__OptionalSKU__c = sourceProd.Id,
                SBQQ__Number__c = 10,
                SBQQ__Type__c = 'Related Product'
            );
            prodopsList.add(prodOption);
            SBQQ__ProductOption__c prodOption1 = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = targetProd1.Id,
                SBQQ__OptionalSKU__c = targetProd2.Id,
                SBQQ__Number__c = 10,
                SBQQ__Type__c = 'Related Product'
            );
            prodopsList.add(prodOption1);
            insert prodopsList;
            
            // Create Multi Mapping
            Multi_Mapping_V2_Conversion__c multiMap1 = new Multi_Mapping_V2_Conversion__c(
                Source_Product__c = sourceProd.Id,
                Target_Product__c = targetProd1.Id,
                After_Conversion_Product_Level__c = 'SaaS Software Addon',
                Storage_Tier__c = '20',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Option__c = 'Annual',
                Option_Level__c = 0,
                Renewal_Type__c = 'V2 To V2',
                Active__c = true
            );
            Multi_Mapping_V2_Conversion__c multiMap2 = new Multi_Mapping_V2_Conversion__c(
                Source_Product__c = sourceProd.Id,
                Target_Product__c = targetProd2.Id,
                After_Conversion_Product_Level__c = 'SaaS Software Addon',
                Storage_Tier__c = '20',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Option__c = 'Annual',
                Renewal_Type__c = 'V2 To V2',
                Option_Level__c = 1,
                Quantity_Multiplier__c=50,
                Active__c = true
            );
            Multi_Mapping_V2_Conversion__c multiMap3 = new Multi_Mapping_V2_Conversion__c(
                Source_Product__c = sourceProd.Id,
                Target_Product__c = targetProd2.Id,
                After_Conversion_Product_Level__c = 'SaaS Software Addon',
                Storage_Tier__c = 'Unlimited',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Option__c = 'Annual',
                Renewal_Type__c = 'V2 To V2',
                Option_Level__c = 0,
                Quantity_Multiplier__c=1,
                Active__c = true
            );
            insert new List<Multi_Mapping_V2_Conversion__c>{multiMap1, multiMap2,multiMap3};
                
                List<Multi_Mapping_V2_Conversion__c> mappings = [ SELECT Id, Target_Product__c, Target_Product__r.Pricebook_Entry_Id__c,Source_Product__r.Pricebook_Entry_Id__c
                                                                 FROM Multi_Mapping_V2_Conversion__c WHERE Source_Product__c = :sourceProd.Id ];
            System.assertNotEquals(null, mappings[0].Target_Product__r.Pricebook_Entry_Id__c);
            
            SBQQ__Quote__c qtN = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), new Map<String, Object>{'SBQQ__Account__c' => act.Id, 'SBQQ__Opportunity2__c' => opp.Id});
            qtN.SBQQ__Primary__c = true;
            qtN.SBQQ__PriceBook__c = pbId;
            qtN.SBQQ__Type__c = 'Quote';
            qtN.SBQQ__StartDate__c = Date.today();
            qtN.Manual_Billing__c = false;
            qtN.SBQQ__SubscriptionTerm__c = 12;
            insert qtN;
            List<SBQQ__QuoteLine__c> newQLs = new List<SBQQ__QuoteLine__c>();
            // Create Quote Line for the New Quote
            SBQQ__QuoteLine__c parentQLN = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qtN.Id,
                SBQQ__Product__c = bundleParentProd.Id,
                SBQQ__Quantity__c = 1,
                Do_not_Renew__c = true,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ListPrice__c = 100,
                SBQQ__Discount__c = 10,
                SBQQ__ProrateMultiplier__c = 12,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__ProratedListPrice__c = 100,
                SBQQ__NetPrice__c = 2000
            );
            newQLs.add(parentQLN);
            
            // Create Quote Line for the New Quote
            SBQQ__QuoteLine__c parentQLN1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qtN.Id,
                SBQQ__Product__c = bundleParentProd.Id,
                SBQQ__Quantity__c = 1,
                Do_not_Renew__c = true,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ListPrice__c = 100,
                SBQQ__Discount__c = 10,
                SBQQ__ProrateMultiplier__c = 12,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__ProratedListPrice__c = 100,
                SBQQ__NetPrice__c = 2000
            );
            newQLs.add(parentQLN1);
            insert newQLs;
            
            ServiceContract serviceContractObj = new ServiceContract(
                Name = 'Sample V2V2 SC',
                SBQQSC__Opportunity__c = opp.Id,
                AccountId = act.Id,
                StartDate = System.today(),
                PriceBook2Id = pbId,
                Term = 36,
                EndDate = System.today().addDays(150),
                SBQQSC__Quote__c = qtN.Id
            );
            insert serviceContractObj;
            // Create Contract Line Item and Quote
            List <ContractLineItem> cliList = new List <ContractLineItem>();
            ContractLineItem cli = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            cli.SBQQSC__Account__c = act.Id;
            cli.PricebookEntryId = pbeSource.Id;
            cli.ServiceContractId = serviceContractObj.Id;
            cli.SBQQSC__Product__c = sourceProd.Id;
            cli.SBQQSC__Quantity__c = 10;
            cli.SBQQSC__ProrateMultiplier__c = 12;
            cli.UnitPrice = 100;
            cli.SBQQSC__SubscriptionPricing__c='Fixed Price';
            cli.SBQQSC__QuoteLine__c = newQLs[1].Id;
            cliList.add(cli);
            
            ContractLineItem cli2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            cli2.SBQQSC__Account__c = act.Id;
            cli2.PricebookEntryId = pbeSource1.Id;
            cli2.ServiceContractId = serviceContractObj.Id;
            cli2.SBQQSC__Product__c = sourceProd1.Id;
            cli2.SBQQSC__Quantity__c = 10;
            cli2.SBQQSC__ProrateMultiplier__c = 12;
            cli2.UnitPrice = 100;
            cli2.SBQQSC__SubscriptionPricing__c='Fixed Price';
            cli2.SBQQSC__QuoteLine__c = newQLs[0].Id;
            cliList.add(cli2);
            insert cliList;
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), new Map<String, Object>{'SBQQ__Account__c' => act.Id, 'SBQQ__Opportunity2__c' => opp.Id});
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            insert qt;
            
            // Create Quote Line for the renewal
            SBQQ__QuoteLine__c parentQL = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = bundleParentProd.Id,
                SBQQ__Quantity__c = 1,
                Do_not_Renew__c = true,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                SBQQ__ListPrice__c = 100,
                SBQQ__Discount__c = 10,
                SBQQSC__RenewedContractLine__c = cli.Id,
                PriorACVwithUplift__c = 100,
                RTAwithoutUplift__c = 100,
                Prior_Net_Total_With_Uplift__c = 1000,
                Discount_Margin__c = 10,
                DMA__c = 10,
                SBQQ__NetPrice__c =2000
            );
            insert parentQL;
            list<SBQQ__QuoteLine__c> listrenewalQL = new list<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c renewalQL = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd.Id,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__ListPrice__c = 100,
                SBQQ__RequiredBy__c = parentQL.Id,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = '20 GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Prior_Net_Total__c = 1000,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                PriorACVwithUplift__c = 100,
                RTAwithoutUplift__c = 100,
                Prior_Net_Total_With_Uplift__c = 1000,
                Discount_Margin__c = 10,
                DMA__c = 10,
                SBQQ__NetPrice__c =2000
            );
            
            SBQQ__QuoteLine__c renewalQL4 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd1.Id,
                SBQQSC__RenewedContractLine__c = cli2.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__ListPrice__c = 100,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = 'Unlimited GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Do_not_Renew__c = true,
                Prior_Net_Total__c = 1000,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                PriorACVwithUplift__c = 100,
                RTAwithoutUplift__c = 100,
                Prior_Net_Total_With_Uplift__c = 1000,
                Discount_Margin__c = 10,
                DMA__c = 10,
                SBQQ__NetPrice__c =2000
            );
            
            SBQQ__QuoteLine__c renewalQL5 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd2.Id,
                SBQQ__Quantity__c = 10,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = 'Unlimited GB',
                SBQQ__ListPrice__c = 100,
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Do_not_Renew__c = true,
                Prior_Net_Total__c = 1000,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                PriorACVwithUplift__c = 100,
                RTAwithoutUplift__c = 100,
                Prior_Net_Total_With_Uplift__c = 1000,
                Discount_Margin__c = 10,
                DMA__c = 10,
                SBQQ__NetPrice__c =2000
            );
            
            SBQQ__QuoteLine__c renewalQL1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd.Id,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__ListPrice__c = 100,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = '20 GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Product_Level__c = 'Hybrid Software',
                Do_not_Renew__c = true,
                Prior_Net_Total__c = 1000,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                PriorACVwithUplift__c = 100,
                RTAwithoutUplift__c = 100,
                Prior_Net_Total_With_Uplift__c = 1000,
                Discount_Margin__c = 10,
                DMA__c = 10,
                SBQQ__NetPrice__c =2000
            );
            SBQQ__QuoteLine__c renewalQL2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd.Id,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__ListPrice__c = 100,
                SBQQ__RequiredBy__c = parentQL.Id,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = '20 GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Product_Type__c = 'HW Support',
                Do_not_Renew__c = true,
                Prior_Net_Total__c = 1000,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                PriorACVwithUplift__c = 100,
                RTAwithoutUplift__c = 100,
                Prior_Net_Total_With_Uplift__c = 1000,
                Discount_Margin__c = 10,
                DMA__c = 10,
                SBQQ__NetPrice__c =2000
            );
            listrenewalQL.add(renewalQL2);
            listrenewalQL.add(renewalQL1);
            listrenewalQL.add(renewalQL);
            listrenewalQL.add(renewalQL4);
            listrenewalQL.add(renewalQL5);
            insert listrenewalQL;
            renewalQL2.SBQQ__RequiredBy__c = renewalQL5.Id;
            update renewalQL2;
            renewalQL = [ SELECT Id, SBQQ__Quote__r.SBQQ__PriceBook__c,SBQQ__Product__r.Pricebook_Entry_Id__c,SBQQSC__RenewedContractLine__r.Id 
                         FROM SBQQ__QuoteLine__c WHERE Id = :renewalQL.Id];
            System.assertNotEquals(null, renewalQL.SBQQ__Quote__r.SBQQ__PriceBook__c);
            Test.startTest();
            // Execute the batch job
            ConvertToSaasRenewalBatch batch = new ConvertToSaasRenewalBatch(new List<SBQQ__Quote__c>{qt});
            Database.executeBatch(batch);
            Map<Id, Decimal> qliListTotal = new Map<Id, Decimal>();
            qliListTotal.put(listrenewalQL[0].Id,10000); 
            qliListTotal.put(listrenewalQL[1].Id,10200); 
            qliListTotal.put(listrenewalQL[2].Id,10200); 
            ConvertToSaasRenewalBatch.convertV2ToV2(qt,true,listrenewalQL);
            for (SBQQ__QuoteLine__c ql : listrenewalQL) {
                ConvertToSaasRenewalBatch.populatePriorNetTotalOnQuoteLine(ql, qliListTotal,null);///ITNPI-3207
            }
            Test.stopTest();
            
            // Assertions to verify the conversion
            List<SBQQ__QuoteLine__c> newQuoteLines = [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, SBQQ__Discount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :qt.Id AND SBQQ__Product__c != :bundleParentProd.Id];
            System.assert(newQuoteLines.size() > 0, 'At least one new quote line should have been created.');
        }
    }
    
    /**
* @isTest
* Method Name - testV2ToV2Conversion
* Tests the V2 to V2 product conversion and renewal quote line creation process.
* Date:25/08/2025
* @description         : Test conversion v2 to v2
*/
    @isTest
    private static void testV2ToV2ConversionExtraCoverage() {
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        System.runAs(usr1) {
            // Disable triggers and validation rules for test data creation
            ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(
                Disable_SBQQ_Quote_Validation_Rules__c = true,
                Disable_SBQQ_Quote_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
                Disable_Opportunity_Validation_Rules__c = true,
                Disable_Opportunity_Triggers__c = true,
                Disable_Campaign_Member_Triggers__c = true,
                Disable_Campaign_Trigger__c = true,
                Disable_Campaign_Validation_Rules__c = true,
                Disable_Order_Validation_Rules__c = true,
                Disable_ServiceContract_Trigger__c = true,
                Disable_Entitlement_Usage_Trigger__c = true,
                Disable_Entitlement_Trigger__c = true,
                Disable_Contract_Line_Item_Triggers__c = true,
                Disable_Entitlement_Validation_Rules__c = true,
                SetupOwnerId = usr1.Id,
                Disable_Asset_Triggers__c = true,
                Disable_SBQQ_QuoteLine_Triggers__c = true
            );
            insert cdf;
            
            // Create Account, Contact, Opportunity, and Service Contract
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Is_Customer_Fully_Transitioned__c = false;
            act.Eligible_for_RCDM_T__c = true;
            insert act;
            
            Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), new Map<String, Object>{'AccountId' => act.Id});
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();
            
            Opportunity opp = TestDataFactory.getOpportunity(act);
            opp.SBQQ__QuotePricebookId__c = pbId;
            insert opp;
            
            ServiceContract serviceContractObj = new ServiceContract(
                Name = 'Sample V2V2 SC',
                SBQQSC__Opportunity__c = opp.Id,
                AccountId = act.Id,
                StartDate = System.today(),
                PriceBook2Id = pbId,
                Term = 36,
                EndDate = System.today().addDays(150)
            );
            insert serviceContractObj;
            
            // Create V2 to V2 source and target products
            List<Product2> listProducts = new List<Product2>();
            Product2 sourceProd = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MD-PE-PA',
                    ProductCode = 'RS-UR-FE-MD-PE-PA',
                    IsActive = true,
                    Custom_Renewal_Type__c = 'V2 To V2',
                    Product_Type__c = 'M365',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
SBQQ__SubscriptionTerm__c = 1,
                    Storage_Tier__c = '20 GB',
                    CPQ_Uplift__c= '7',
                    Eligible_for_RCDM_T__c = true
                ), null
            );
            listProducts.add(sourceProd);
            Product2 sourceProd1 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MD-BS-PP',
                    ProductCode = 'RS-UR-FE-MD-BS-PP',
                    IsActive = true,
                    Custom_Renewal_Type__c = 'V2 To V2',
                    Product_Type__c = 'M365',
                    Product_Level__c = '',
                    License_per_Qty__c= 2,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Storage_Tier__c = 'Unlimited GB',
                    CPQ_Uplift__c= '7'
                ), null
            );
            
            listProducts.add(sourceProd1);            
            
            Product2 sourceProd2 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MD-BS-PsP',
                    ProductCode = 'RS-UR-FE-MD-BS-PsP',
                    IsActive = true,
                    Product_Type__c = 'Hardware',
                    Product_Level__c = '',
                    License_per_Qty__c= 2,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Storage_Tier__c = 'Unlimited GB',
                    CPQ_Uplift__c= '7'
                ), null
            );
            
            listProducts.add(sourceProd2);            
            
            Product2 targetProd1 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-MS-PE-PA',
                    ProductCode = 'RS-UR-FE-MS-PE-PA',
                    IsActive = true,
                    Product_Type__c = 'M365',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Support_Tier__c = 'S1',
                    CPQ_Uplift__c= '7',
                    Eligible_for_RCDM_T__c = true
                ), null
            );
            listProducts.add(targetProd1);
            Product2 targetProd2 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-GB-MS-PE-PA',
                    ProductCode = 'RS-GB-MS-PE-PA',
                    IsActive = true,
                    Product_Type__c = 'M365 Storage',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Support_Tier__c = 'S1',
                    CPQ_Uplift__c= '7'
                ), null
            );
            listProducts.add(targetProd2);
            Product2 targetProd3 = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-UR-FE-USL-PE-PP',
                    ProductCode = 'RS-UR-FE-USL-PE-PP',
                    IsActive = true,
                    Product_Type__c = 'M365',
                    Product_Level__c = 'SaaS Software Addon',
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    Support_Tier__c = 'S1',
                    CPQ_Uplift__c= '7'
                ), null
            );
            listProducts.add(targetProd3);
            Product2 bundleParentProd = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'V2-To-V2-Parent-Product',
                    ProductCode = 'V2-V2-PARENT',
                    IsActive = true,
                    Product_Level__c = 'Hybrid Software'
                ), null
            );
            listProducts.add(bundleParentProd);
            
            Product2 rcdmT = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RS-BT-RCDM-T',
                    ProductCode = 'RS-BT-RCDM-T',
                    IsActive = true,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    CPQ_Uplift__c= '7'
                ), null
            );
            listProducts.add(rcdmT);
            
            Product2 entProd = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RBK-SUB-PRO-R6410S-01-RENEWAL',
                    ProductCode = 'RBK-SUB-PRO-R6410S-01-RENEWAL',
                    IsActive = true,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    CPQ_Uplift__c= '7',
                    After_Conversion_Product_Level__c = 'PROBUNDLE'
                ), null
            );
            listProducts.add(entProd);
            
            Product2 assetProd = (Product2) ShGl_TestFactory.createSObject(
                new Product2(
                    Name = 'RBK-SUB-PRO-R6410S-01-RENEWAL',
                    ProductCode = 'RBK-SUB-PRO-R6410S-01-RENEWAL',
                    IsActive = true,
                    Support_Type__c = 'Premium',
                    Product_Payment_Option__c = 'Annual',
                    CPQ_Uplift__c= '7',
                    After_Conversion_Product_Level__c = 'PROBUNDLE'
                ), null
            );
            listProducts.add(assetProd);
            
            insert listProducts;
            
            // Create Pricebook Entries
            PricebookEntry pbeSource = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSource.Product2Id = sourceProd.Id; 
            pbeSource.UnitPrice = 100;
            PricebookEntry pbesource1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbesource1.Product2Id = sourceProd1.Id; 
            pbesource1.UnitPrice = 100;
            PricebookEntry pbesource2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbesource2.Product2Id = sourceProd2.Id; 
            pbesource2.UnitPrice = 100;
            PricebookEntry pbeTarget1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeTarget1.Product2Id = targetProd1.Id; 
            pbeTarget1.UnitPrice = 100;
            PricebookEntry pbeTarget2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeTarget2.Product2Id = targetProd2.Id; 
            pbeTarget2.UnitPrice = 100;
            PricebookEntry pbeParent = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeParent.Product2Id = bundleParentProd.Id; 
            pbeParent.UnitPrice = 10;
            PricebookEntry pbeTarget3 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeTarget3.Product2Id = targetProd3.Id; 
            pbeTarget3.UnitPrice = 50;
            PricebookEntry rcdmTPBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            rcdmTPBE.Product2Id = rcdmT.Id; 
            rcdmTPBE.UnitPrice = 50;
            
            PricebookEntry assetProdPBE = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            assetProdPBE.Product2Id = assetProd.Id; 
            assetProdPBE.UnitPrice = 50;
            insert new List<PricebookEntry>{pbeSource,pbeSource1,pbeSource2, pbeTarget1,pbeTarget2,pbeTarget3, pbeParent,rcdmTPBE, assetProdPBE };
                
                sourceProd.Pricebook_Entry_Id__c = pbeSource.Id;
            sourceProd1.Pricebook_Entry_Id__c = pbeSource1.Id;
            sourceProd2.Pricebook_Entry_Id__c = pbeSource2.Id;
            targetProd1.Pricebook_Entry_Id__c = pbeTarget1.Id;
            targetProd2.Pricebook_Entry_Id__c = pbeTarget2.Id;
            targetProd3.Pricebook_Entry_Id__c = pbeTarget3.Id;
            bundleParentProd.Pricebook_Entry_Id__c = pbeParent.Id;
            rcdmT.Pricebook_Entry_Id__c = rcdmTPBE.Id;
            assetProd.Pricebook_Entry_Id__c = assetProdPBE.Id;
            
            cdf.Disable_Product2_Trigger__c =true;
            update cdf;
            update listProducts;
            cdf.Disable_Product2_Trigger__c =false;
            update cdf;
            
            
            // Link the parent and child products via Product Option
            List<SBQQ__ProductOption__c> prodopsList = new List<SBQQ__ProductOption__c>();
            // Link the parent and child products via Product Option
            SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = bundleParentProd.Id,
                SBQQ__OptionalSKU__c = sourceProd.Id,
                SBQQ__Number__c = 10,
                SBQQ__Type__c = 'Related Product'
            );
            prodopsList.add(prodOption);
            SBQQ__ProductOption__c prodOption1 = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = targetProd1.Id,
                SBQQ__OptionalSKU__c = targetProd2.Id,
                SBQQ__Number__c = 10,
                SBQQ__Type__c = 'Related Product'
            );
            prodopsList.add(prodOption1);
            insert prodopsList;
            
            // Create Multi Mapping
            Multi_Mapping_V2_Conversion__c multiMap1 = new Multi_Mapping_V2_Conversion__c(
                Source_Product__c = sourceProd.Id,
                Target_Product__c = targetProd1.Id,
                After_Conversion_Product_Level__c = 'SaaS Software Addon',
                Storage_Tier__c = '20',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Option__c = 'Annual',
                Option_Level__c = 0,
                Renewal_Type__c = 'V2 To V2',
                Active__c = true
            );
            Multi_Mapping_V2_Conversion__c multiMap2 = new Multi_Mapping_V2_Conversion__c(
                Source_Product__c = sourceProd.Id,
                Target_Product__c = targetProd2.Id,
                After_Conversion_Product_Level__c = 'SaaS Software Addon',
                Storage_Tier__c = '20',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Option__c = 'Annual',
                Renewal_Type__c = 'V2 To V2',
                Option_Level__c = 1,
                Quantity_Multiplier__c=50,
                Active__c = true
            );
            Multi_Mapping_V2_Conversion__c multiMap3 = new Multi_Mapping_V2_Conversion__c(
                Source_Product__c = sourceProd.Id,
                Target_Product__c = targetProd2.Id,
                After_Conversion_Product_Level__c = 'SaaS Software Addon',
                Storage_Tier__c = 'Unlimited',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Option__c = 'Annual',
                Renewal_Type__c = 'V2 To V2',
                Option_Level__c = 0,
                Quantity_Multiplier__c=1,
                Active__c = true
            );
            insert new List<Multi_Mapping_V2_Conversion__c>{multiMap1, multiMap2,multiMap3};
                
                List<Multi_Mapping_V2_Conversion__c> mappings = [ SELECT Id, Target_Product__c, Target_Product__r.Pricebook_Entry_Id__c,Source_Product__r.Pricebook_Entry_Id__c
                                                                 FROM Multi_Mapping_V2_Conversion__c WHERE Source_Product__c = :sourceProd.Id ];
            System.assertNotEquals(null, mappings[0].Target_Product__r.Pricebook_Entry_Id__c);
            
            
            // Create Contract Line Item and Quote
            List <ContractLineItem> cliList = new List <ContractLineItem>();
            ContractLineItem cli = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            cli.SBQQSC__Account__c = act.Id;
            cli.PricebookEntryId = pbeSource.Id;
            cli.ServiceContractId = serviceContractObj.Id;
            cli.SBQQSC__Product__c = sourceProd.Id;
            cli.SBQQSC__Quantity__c = 10;
            cli.SBQQSC__ProrateMultiplier__c = 12;
            cliList.add(cli);
            
            ContractLineItem cli2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            cli2.SBQQSC__Account__c = act.Id;
            cli2.PricebookEntryId = pbeSource1.Id;
            cli2.ServiceContractId = serviceContractObj.Id;
            cli2.SBQQSC__Product__c = sourceProd1.Id;
            cli2.SBQQSC__Quantity__c = 10;
            cli2.SBQQSC__ProrateMultiplier__c = 12;
            cliList.add(cli2);
            
            ContractLineItem cli3 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            cli3.SBQQSC__Account__c = act.Id;
            cli3.PricebookEntryId = rcdmTPBE.Id;
            cli3.ServiceContractId = serviceContractObj.Id;
            cli3.SBQQSC__Product__c = rcdmT.Id;
            cli3.SBQQSC__Quantity__c = 10;
            cli3.SBQQSC__ProrateMultiplier__c = 12;
            cli3.EndDate = System.today().addDays(30);
            cli3.StartDate = System.today();
            cliList.add(cli3);
            
            insert cliList;
            
            /*Asset newAsset = new Asset(Name = 'AA185263040113', SerialNumber = 'AA185263040113', Product2Id = assetProd.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = '8021COMKEY');
insert newAsset;

Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
enttitlementNewObj6.AccountId = act.Id;
enttitlementNewObj6.StartDate = Date.today().addDays(-365);
enttitlementNewObj6.EndDate = Date.today().addDays(+900);
enttitlementNewObj6.ContractLineItemId = cli.Id;
enttitlementNewObj6.Renewable__c = true;
enttitlementNewObj6.AssetId =newAsset.Id ;
enttitlementNewObj6.Type = 'Phone Support';
enttitlementNewObj6.Renewal_Category__c = '';
enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
enttitlementNewObj6.Product__c = sourceProd.Id; 
enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
enttitlementNewObj6.ServiceContractId = serviceContractObj.Id;
//enttitlementNewObj7.Product_Usable_Capacity__c = 0;
//    lstEntitlement.add(enttitlementNewObj5);
insert enttitlementNewObj6;*/
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), new Map<String, Object>{'SBQQ__Account__c' => act.Id, 'SBQQ__Opportunity2__c' => opp.Id});
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            qt.RCDMT_EOL_Date__c  = Date.newInstance(2040, 1, 1);
            insert qt;
            
            cli2.SBQQSC__RequiredById__c = cli.Id;
            update cli2;
            cli3.SBQQSC__RequiredById__c = cli.Id;
            update cli3;
            
            // Create Quote Line for the renewal
            SBQQ__QuoteLine__c parentQL = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = bundleParentProd.Id,
                SBQQ__Quantity__c = 1
            );
            insert parentQL;
            list<SBQQ__QuoteLine__c> listrenewalQL = new list<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c renewalQL = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd.Id,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__RequiredBy__c = parentQL.Id,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = '20 GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                SBQQ__StartDate__c = System.today(),
                Disposition_Reason__c = 'Renewing',
                Prior_Net_Total__c = 1000.00,
                PriorACVwithUplift__c = 1000.00,
                Prior_Net_Total_With_Uplift__c = 500.00,
                RTAwithoutUplift__c = 400
            );
            
            SBQQ__QuoteLine__c renewalQL4 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd1.Id,
                SBQQSC__RenewedContractLine__c = cli2.Id,
                SBQQ__Quantity__c = 10,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = 'Unlimited GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                SBQQ__StartDate__c = System.today(),
                Disposition_Reason__c = 'Renewing',
                Prior_Net_Total__c = 1000.00,
                PriorACVwithUplift__c = 1000.00,
                Prior_Net_Total_With_Uplift__c = 500.00,
                RTAwithoutUplift__c = 400
            );
            
            SBQQ__QuoteLine__c renewalQL5 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd2.Id,
                SBQQ__Quantity__c = 10,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = 'Unlimited GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                SBQQ__StartDate__c = System.today(),
                Disposition_Reason__c = 'Renewing',
                Prior_Net_Total__c = 1000.00,
                PriorACVwithUplift__c = 1000.00,
                Prior_Net_Total_With_Uplift__c = 500.00,
                RTAwithoutUplift__c = 400
            );
            
            SBQQ__QuoteLine__c renewalQL1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd.Id,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__Quantity__c = 10,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = '20 GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Product_Level__c = 'Hybrid Software',
                SBQQ__StartDate__c = System.today(),
                Disposition_Reason__c = 'Renewing',
                Prior_Net_Total__c = 1000.00,
                PriorACVwithUplift__c = 1000.00,
                Prior_Net_Total_With_Uplift__c = 500.00,
                RTAwithoutUplift__c = 400
            );
            SBQQ__QuoteLine__c renewalQL2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = sourceProd.Id,
                SBQQSC__RenewedContractLine__c = cli.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__RequiredBy__c = parentQL.Id,
                CPQ_Uplift__c ='7', // 10% uplift
                Storage_Tier__c = '20 GB',
                Support_Tier__c = 'S1',
                Support_Type__c = 'Premium',
                Payment_Options__c = 'Annual',
                Product_Type__c = 'HW Support',
                SBQQ__StartDate__c = System.today(),
                Disposition_Reason__c = 'Renewing',
                Prior_Net_Total__c = 0.00,
                PriorACVwithUplift__c = 1000.00,
                Prior_Net_Total_With_Uplift__c = 500.00,
                RTAwithoutUplift__c = 400
            );
            listrenewalQL.add(renewalQL2);
            listrenewalQL.add(renewalQL1);
            listrenewalQL.add(renewalQL);
            listrenewalQL.add(renewalQL4);
            listrenewalQL.add(renewalQL5);
            insert listrenewalQL;
            renewalQL2.SBQQ__RequiredBy__c = renewalQL5.Id;
            update renewalQL2;
            renewalQL = [ SELECT Id, SBQQ__Quote__r.SBQQ__PriceBook__c,SBQQ__Product__r.Pricebook_Entry_Id__c,SBQQSC__RenewedContractLine__r.Id 
                         FROM SBQQ__QuoteLine__c WHERE Id = :renewalQL.Id];
            System.assertNotEquals(null, renewalQL.SBQQ__Quote__r.SBQQ__PriceBook__c);
            Test.startTest();
            // Execute the batch job
            ConvertToSaasRenewalBatch batch = new ConvertToSaasRenewalBatch(new List<SBQQ__Quote__c>{qt});
            Database.executeBatch(batch);
            ConvertToSaasRenewalBatch.forceTestException = true;
            ConvertToSaasRenewalBatch.convertV2ToV2(qt,true,listrenewalQL);
            Test.stopTest();
            
            // Assertions to verify the conversion
            List<SBQQ__QuoteLine__c> newQuoteLines = [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, SBQQ__Discount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :qt.Id AND SBQQ__Product__c != :bundleParentProd.Id];
            System.assert(newQuoteLines.size() > 0, 'At least one new quote line should have been created.');
        }
    }
}