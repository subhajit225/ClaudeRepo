@isTest
public class OpportunityManualOverrideTest {
 
    static testMethod void getDetails(){
        list<user> lstUser = new List<user>();
        String ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloper1', Name = 'My Role');
       // insert vUserRole;
        for(integer i = 0; i<10; i++){
            User u = new User(
                ProfileId = ProfileId,
                LastName = 'last'+i,
                Email = 'TestUser' +i +'@rubrik.com',
                Username = 'TestUser' +i +'@rubrik.com.test',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'TestUser'.substring(0,5),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                //UserRoleId = vUserRole.Id,
                isActive = true,
                Start_Date__c=System.Today().adddays(-30)            
            );
            lstUser.add(u);
        }
        insert lstUser;
        PermissionSet ps = [SELECT Id  FROM PermissionSet WHERE Name = 'Opportunity_Amount_Override'];
        insert new PermissionSetAssignment(AssigneeId = lstUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(lstUser[0]) {
            Account acc = TestDataFactory.getAccount();
        insert acc;
        Contact cont = new Contact(firstname='first', lastname='last', accountId=acc.id);
        insert cont;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acc.Id
                };
                    
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert opp;
        
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Subscription', 
                'IsActive' => true, 
                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                'SBQQ__SubscriptionTerm__c' => 12, 
                'SBQQ__SubscriptionType__c' => 'Renewable'
                };
                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prdHW.License_Type__c = 'Perpetual';
        prdHW.Product_Subtype__c = 'E1000';
        prdHW.Sales_Comp_Category__c = 'CONSUMPTION';
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        
        insert prdList;   
        
        Id standardPBId = test.getStandardPricebookId();
        
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        PriceBookEntry pbEntry1 = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = standardPBId,
            Product2Id = prdList[0].Id,
            IsActive = true,
            UseStandardPrice=false);
        
        pBList.add(pbEntry1); 
        insert pBList;
        
        opp.Pricebook2Id=standardPBId;
        opp.ACV_Amount__c=250;
        opp.Renewal_Subsumed_ACV__c = 50;
		opp.Subsumed_Renewal_TCV__c = 50;
        opp.New_Expansion_ACV__c = 50;
        opp.New_Expansion_TCV__c = 50;    
        opp.Initial_Contacts_Name__c = cont.Id;
        opp.Opportunity_Amount_Override__c = true;    
        update opp;
        
        ShGl_DisableBusinessLogic__c sbl = new ShGl_DisableBusinessLogic__c(Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Old_Trigger__c=true,Disable_Opportunity_Triggers__c=true,SetupOwnerId=UserInfo.getOrganizationId());
        insert sbl;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLine1 = new OpportunityLineItem(Line_type_text__c='New',product2Id=prdList[0].Id,TotalPrice=2000,
                                                               Quantity = 2,OpportunityID = opp.Id,ACV_Amount__c=250,
           Subsumed_Renewal_Amount__c = 50,Subsumed_Renewal_TCV__c = 50,New_Expansion_ACV__c = 50,New_Expansion_TCV__c = 50);
        
        oppLineList.add(oppLine1);
        insert oppLineList;
            test.startTest();
            OpportunityManualOverride.getDetails(opp.Id);
            OpportunityManualOverride.getDetails(oppLineList[0].Id);
            OpportunityManualOverride.saveItem(opp.Id,100,100, 100, 100, 100, 100, 100, 100,100,100,100, 90); //SAL26-1291//SAL26-1277
            OpportunityManualOverride.saveItem(oppLineList[0].Id,100,100, 100, 100, 100, 100, 100, 100,100,100,100, 90); //SAL26-1291//SAL26-1277
            test.stopTest();
        }
    }
}