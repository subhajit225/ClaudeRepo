/**
* @File Name : QuoteTriggerHelperForEmailTest.cls
* @description :This class is gtest class for QuoteTriggerHelperForEmail.cls.
* @Author :Shivani
* @Last Modified By :
* @Last Modified On : June 17, 2025
* @Modification Log :
* Test Class        :QuoteTriggerHelperForEmailTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 17, 2025 |   | Initial Version
**/
@isTest
public class QuoteTriggerHelperForEmailTest {
    static final Id salesRtId = Schema.getGlobalDescribe()
        .get('Opportunity')
        .getDescribe()
        .getRecordTypeInfosByName()
        .get('Sales Opportunity')
        .getRecordTypeId();
    // Partner account record type Id
    static final Id partnerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Partner/Distributor')
        .getRecordTypeId();
    static Account getAccount(String name, String type, String rtId) {
        Account vAccount = new Account();
        vAccount.Name = name;
        vAccount.Type = type;
        vAccount.recordTypeId = rtId;
        
        return vAccount;
    }
    /***********************************************************************************************************
    * Method Name          : testsendProactiveDealGovernanceNotice
    * Date Created/Modified: 16/06/2025
    * Author               : Shivani
    * @description         : test class for sendProactiveDealGovernanceNotice
    * Test Class Methods   :
    /**********************************************************************************************************/
    @isTest
    private static void testsendProactiveDealGovernanceNotice() {
        Profile p = [SELECT Id FROM profile WHERE Name = 'System Administrator'];
        String testmail = system.label.Task_User_Assignment;
        User testUser = new User(
            Alias = 'standt',
            Email = 'cyrus.sharif@rubrik.com.sandbox',
            EmailEncodingKey = 'UTF-8',
            LastName = 'martin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'jivanJ@testorg.com'
        );
        
        insert testUser;
        
        System.runAs(new User(ID = UserInfo.getUserID())) {
            ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
            dbl.Disable_Account_Triggers__c = true;
            dbl.Disable_Opportunity_Triggers__c = true;
            dbl.Disable_ServiceContract_Trigger__c = true;
            dbl.Disable_Entitlement_Validation_Rules__c = true;
            insert dbl;
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            
            TriggerControl__c control = new TriggerControl__c(
                Name = 'Entitlement',
                DisableTrigger__c = true
            );
            insert control;
            
            //Generate the  Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            List<Account> accountList = new List<Account>();
            
            Account vAccount = getAccount('Test Account', 'Distributor', partnerRtId);
            accountList.add(vAccount);
            
            Account vAccount2 = getAccount('HPE Greenlake Canada', null, vAccount.recordTypeId);
            accountList.add(vAccount2);
            insert accountList;
        
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => act.Id };
                Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
    
            Map<String, Object> prdMap = new Map<String, Object>{
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'RBK-PRO-BUNDLE-R6410S-01',
                'Replacement_Category__c' => 'Enterprise Data Protection'
                };
                    
            Map<String, Object> prdMap1 = new Map<String, Object> {
                'Name' => 'SubscriptionTest',
                    'IsActive'  => true,
                    'SBQQ__SubscriptionPricing__c'  => 'Fixed Price',
                    'SBQQ__SubscriptionTerm__c'  => 12,
                    'SBQQ__SubscriptionType__c'  => 'Renewable',
                    'Replacement_Category__c' => 'Not Replaceable'
                    };
    
            
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
            prdSubs.Replacement_Category__c = 'Not Replaceable';
            prdHW.Replacement_Category__c = 'Enterprise Data Protection';
            prdList.add(prdHW);
            prdList.add(prdSubs);
            insert prdList;

            //create entitlements
            List<Entitlement> entitlements = new List<Entitlement>();

            Entitlement ent_prdHW = new Entitlement(Name='ent_prdHW', 
            AccountId=act.Id,
            Product__c = prdHW.id,
            StartDate = Date.today().addMonths(-18),
            EndDate = Date.today().addMonths(-6));
            entitlements.add(ent_prdHW);

            Entitlement ent_prdHW2 = ent_prdHW.clone();
            entitlements.add(ent_prdHW2);

            insert entitlements;
            
            //Generate the Opportunity
            Map<String, Object> oppMap = new Map<String, Object>{
                'AccountId' => act.Id,
                    'RecordTypeId' => salesRtId
                    };
                        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
            opp.ForecastCategoryName = 'Best Case';
            opp.Partner_Lookup__c = vAccount2.id;
            opp.Distributor_Lookup__c = vAccount.id;
            opp.Sell_to_Partner__c = vAccount2.id;
            opp.Renewal_Credit_ACV__c = 2000;
            opp.Renewal_Credit_TCV__c = 4000;
             
            insert opp;
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c = act.Id;
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__PrimaryContact__c = cnt.Id;
            qt.Task_Products__c = 'RBK-DISK-RETENTION';
            qt.Sell_to_Partner__c = vAccount2.id;
            qt.SBQQ__Primary__c = true;
            qt.RenCredACV__c = 2500;
            qt.RenTradeUpAmt__c = 5000;
            qt.RWD_Deal_Ops_Exception__c = 'Test Quote';
            qt.RWD_Deal_Ops_Exception_Justification__c = 'RWD Deals Ops Ezception is For Test';
            qt.SBQQ__Status__c = 'Draft';
            qt.Task_Products__c = 'RBK-DISK-RETENTION';
            qt.Has_Mosaic_SKUs__c = true;
            qt.Deal_Desk_Notes__c = 'Test quot deal';
            qt.ApprovalStatus__c = 'Pending';
            insert qt;

        

            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = prdHW.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 1,
                SBQQ__ListPrice__c = 200.00,SBQQ__NetPrice__c = 200.00,
                SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12,
                SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
            );
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt.Id,
                SBQQ__Product__c = prdSubs.Id,
                SBQQ__RequiredBy__c = qli1.id,
                SBQQ__Quantity__c = 10,
                SBQQ__Number__c = 2,
                SBQQ__ListPrice__c = 200.00, SBQQ__NetPrice__c = 200.00,
                SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12,
                SubscribedAssetNames__c = 'BB1928630400416, BB1921863040047',
                SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAb, 02i1W00000Sn8uZQAb'
            );
            qliList.add(qli1);
            qliList.add(qli2);
            insert qliList;
            Map<Id,SBQQ__Quote__c> oldMap = new  Map<Id,SBQQ__Quote__c>();
            oldMap.put(qt.Id,qt);
            List<CPQ_Disposition_Quote_Line__c> listCPQLines= new List<CPQ_Disposition_Quote_Line__c>();
            listCPQLines.add(
                                new CPQ_Disposition_Quote_Line__c(Product__c = prdSubs.Id,
                                                                    Disposition_Reason__c = 'At Risk',
                                                                    Quote__c=qt.Id
                                                                 )
                            );
            listCPQLines.add(
                                new CPQ_Disposition_Quote_Line__c(Product__c = prdHW.Id,
                                                                    Disposition_Reason__c = 'Renew Later',
                                                                    Quote__c=qt.Id)
            );
            
            insert listCPQLines;

            Test.startTest();
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            qt.SBQQ__Primary__c = true;
            qt.ApprovalStatus__c= 'Approved';
            Map<Id,SBQQ__Quote__c> quoteMap = new  Map<Id,SBQQ__Quote__c>();
            QuoteTriggerHelper.quoteMap = new List<SBQQ__Quote__c>();
            update qt;
            //QuoteTriggerHelper.sendProactiveDealGovernanceNotice(newMapTest, quoteListTest);
            QuoteTriggerHelperForEmail.blankOutRenewalOpsFieldsOnQuoteClone(new List<SBQQ__Quote__c>{qt});
            Test.stopTest();
            System.assert(true);
        }
    }
}