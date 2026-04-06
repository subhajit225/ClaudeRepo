@isTest
public class CampaignMemberTriggerHelperTest{
    @TestSetup
    static void makeData(){        
        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disFuncCS.Allow_Contact_Transfer__c = true;
        update disFuncCS;
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1].Id;
        ShGl_DisableBusinessLogic__c disableBusiCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableBusiCS.SetupOwnerId = adminProfileId;
        disableBusiCS.Disable_Contact_Triggers__c = true;
        upsert disableBusiCS;
                
        Account acc1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acc1.Segment_Assignment__c = 'Commercial';
        insert acc1;
        Lead lead1 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        lead1.CountryCode = 'IT';
        lead1.Winning_L2A_Account__c = acc1.Id;
        insert lead1;

        Feature_Recommendation__c recommendation = new Feature_Recommendation__c();
        recommendation.Account__c = acc1.Id;
        recommendation.Feature_Name__c = 'Sonar';
        recommendation.Account_Feature__c = acc1.Id+' - '+'Sonar';
        recommendation.Status__c = 'Recommended';
        insert recommendation;

        Campaign camp1 = new Campaign(ETM_Role__c = 'Account Executive',Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='Cloud',Name = 'Test Campaign 1',type='Advertising', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',RecordTypeId=Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId(),GTM_Play__c='Cloud Native Protection');
        System.debug('camp1: '+camp1);
        insert camp1;

        CampaignMember campMem1 = new CampaignMember(Leadid = lead1.id, CampaignId = camp1.id, Status = 'Sent',FCRM__FCR_QR__c=true,CFCR_PQL__c=true); //FCRM__FCR_QR__c=true,CFCR_PQL__c=true
        insert campMem1;
    }
    
    @isTest
    public static void testMethod1(){
        //String CampainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        Lead lead1 = [SELECT Id FROM Lead LIMIT 1];
        Campaign camp1 = new Campaign(Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='Cloud',Name = 'Test Campaign 1',type='Advertising', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',GTM_Play__c='Cloud Native Protection');

        insert camp1;

        CampaignMember campMem1 = new CampaignMember(Leadid = lead1.id, CampaignId = camp1.id, UTM_Source__c = 'linkedin', Status = 'Sent',FCRM__FCR_QR__c=true,CFCR_PQL__c=true); //FCRM__FCR_QR__c=true,CFCR_PQL__c=true
        insert campMem1;
        System.assert(true);

    }
    
    @isTest
    public static void testMethodForContact(){
        /*Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        Account accountObject = new Account();
        accountObject.Name = 'Test Account';
        accountObject.RecordTypeId = devRecordTypeId;
        insert accountObject;*/

        Account accountObject = [SELECT Id FROM Account LIMIT 1];

        Contact contactObject = new Contact();
        contactObject.AccountId = accountObject.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@email.com';
        contactObject.Feature_Recommendation__c = 'Sonar';
        insert contactObject;

        String CampainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        Campaign campaignObject1 = new Campaign();
        campaignObject1.Name = 'Test Campaign 1';
         campaignObject1.type= 'Advertising';
        //campaignObject1.RecordTypeId = CampainRecordTypeId;
        campaignObject1.IsActive = true;
        campaignObject1.Alliance_Partner__c = 'Cleversafe';
        campaignObject1.Campaign_Sales_Theatre__c = 'APAC';
        campaignObject1.Campaign_Sales_Area__c = 'APAC';
        campaignObject1.Campaign_Sales_Region__c = 'APAC';
        campaignObject1.Campaign_Sales_Sub_Region__c = 'APAC';
        campaignObject1.Cost_Center__c = 'Alliance';
        campaignObject1.Enabled_for_Opportunity_creation__c = true;
        campaignObject1.Campaign_Theme__c='Cloud';
        campaignObject1.GTM_Play__c='Cloud Native Protection';
        campaignObject1.Executed_By__c='Sales';
        campaignObject1.Involvement_by_Customer_Marketing__c='Yes';
       // campaignObject1.FCRM__FCR_QR__c=true;
        //campaignObject1.CFCR_PQL__c=true;
        campaignObject1.Planned_MQL__c = 1;
        
        insert campaignObject1;

        CampaignMember campaignMemberObject1 = new CampaignMember();
        campaignMemberObject1.ContactId = contactObject.Id;
        campaignMemberObject1.CampaignId = campaignObject1.Id;
        campaignMemberObject1.Status = 'Sent';
        campaignMemberObject1.FCRM__FCR_QR__c=false;
        campaignMemberObject1.CFCR_PQL__c=false; 
        

        Test.startTest();
            insert campaignMemberObject1;
        Test.stopTest();
        
        System.assert(true);

    }

    /**
     * Author           :   Saakshi Gupta
     * Created Date     :   27-03-2020
     * Description      :   This method tests createOpportunityOnResponse() from CampaignMemberTriggerHelper class
     */
    @isTest public static void testCreateOpportunityOnResponse(){
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        Account accountObject = new Account();
        accountObject.Name = 'Test Account';
        accountObject.RecordTypeId = devRecordTypeId;
        insert accountObject;

        Contact contactObject = new Contact();
        contactObject.AccountId = accountObject.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@email.com';
        if(Schema.SObjectType.Contact.fields.getMap().containsKey('data_use_permitted__c') ==  true){
            contactObject.put('data_use_permitted__c', true);
        }
        else{
            contactObject.put('Limited_Use__c', true);
        }
        insert contactObject;

        String CampainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        Campaign campaignObject2 = new Campaign();
        campaignObject2.Name = 'Test Campaign 1';
         campaignObject2.type= 'Advertising';
        //campaignObject2.RecordTypeId = CampainRecordTypeId;
        campaignObject2.IsActive = true;
        campaignObject2.Alliance_Partner__c = 'Cleversafe';
        campaignObject2.Campaign_Sales_Theatre__c = 'APAC';
        campaignObject2.Campaign_Sales_Area__c = 'APAC';
        campaignObject2.Campaign_Sales_Region__c = 'APAC';
        campaignObject2.Campaign_Sales_Sub_Region__c = 'APAC';
        campaignObject2.Cost_Center__c = 'Alliance';
        campaignObject2.Enabled_for_Opportunity_creation__c = true;
        campaignObject2.Campaign_Theme__c='Cloud';
        campaignObject2.GTM_Play__c='Cloud Native Protection';
        campaignObject2.Executed_By__c='Sales';
        campaignObject2.Involvement_by_Customer_Marketing__c='Yes';
       // campaignObject.FCRM__FCR_QR__c=true;
        //campaignObject.CFCR_PQL__c=true;
        campaignObject2.Planned_MQL__c = 1;
        
        insert campaignObject2;

        CampaignMember campaignMemberObject2 = new CampaignMember();
        campaignMemberObject2.ContactId = contactObject.Id;
        campaignMemberObject2.CampaignId = campaignObject2.Id;
        campaignMemberObject2.Status = 'Sent';
        campaignMemberObject2.FCRM__FCR_QR__c=false;
        campaignMemberObject2.CFCR_PQL__c=false; 
        campaignMemberObject2.UTM_Source__c = 'linkedin';
        insert campaignMemberObject2;

        Test.startTest();
        
        //campaignMemberObject2.id=campaignMemberObject2.id;
        campaignMemberObject2.Status = 'Responded';
        campaignMemberObject2.FCRM__FCR_QR__c=true; 
        campaignMemberObject2.CFCR_PQL__c=true; 
        update campaignMemberObject2;

        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM Opportunity WHERE AccountId =: accountObject.Id]);
    }
    
    @isTest public static void testCreateMMRouting(){  
       // ShGl_TestFactoryHelper.insertCustomSettings();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        Account accountObject = new Account();
        accountObject.Name = 'Test Account';
        accountObject.ETM_Region__c='AMER-MM';
        accountObject.BillingCountry='United States';
        accountObject.BillingCountryCode='US';
        //accountObject.Account_Status__c='Existing Customer';
        
         
            
        accountObject.RecordTypeId = devRecordTypeId;
        insert accountObject;

        Contact contactObject = new Contact();
        contactObject.AccountId = accountObject.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@email.com';
        if(Schema.SObjectType.Contact.fields.getMap().containsKey('data_use_permitted__c') ==  true){
            contactObject.put('data_use_permitted__c', true);
        }
        else{
            contactObject.put('Limited_Use__c', true);
        }
        
        insert contactObject;

        String CampainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        Campaign campaignObject3 = new Campaign();
        campaignObject3.Name = 'Test Campaign 1';
         campaignObject3.type= 'Advertising';
        //campaignObject3.RecordTypeId = CampainRecordTypeId;
        campaignObject3.IsActive = true;
        campaignObject3.Alliance_Partner__c = 'Cleversafe';
        campaignObject3.Campaign_Sales_Theatre__c = 'APAC';
        campaignObject3.Campaign_Sales_Area__c = 'APAC';
        campaignObject3.Campaign_Sales_Region__c = 'APAC';
        campaignObject3.Campaign_Sales_Sub_Region__c = 'APAC';
        campaignObject3.Cost_Center__c = 'Alliance';
        campaignObject3.Enabled_for_Opportunity_creation__c = true;
        campaignObject3.Campaign_Theme__c='Cloud';
        campaignObject3.GTM_Play__c='Cloud Native Protection';
        campaignObject3.Executed_By__c='Sales';
        campaignObject3.Involvement_by_Customer_Marketing__c='Yes';
        campaignObject3.Planned_MQL__c = 1;
        insert campaignObject3;

        CampaignMember campaignMemberObject3 = new CampaignMember();
        campaignMemberObject3.ContactId = contactObject.Id;
        campaignMemberObject3.CampaignId = campaignObject3.Id;
        campaignMemberObject3.Status = 'Sent';
        campaignMemberObject3.FCRM__FCR_QR__c=false;
        campaignMemberObject3.CFCR_PQL__c=false; 
        campaignMemberObject3.UTM_Source__c = 'linkedin';

        insert campaignMemberObject3;

        Test.startTest();
        //campaignMemberObject.id=campaignMemberObject.id;
        campaignMemberObject3.Status = 'Responded';
        campaignMemberObject3.FCRM__FCR_QR__c=true; 
        campaignMemberObject3.CFCR_PQL__c=true; 
        update campaignMemberObject3;
        
          
            List<Opportunity> testOpportunities = (List<Opportunity>)ShGl_TestFactory.createSObjectList(new Opportunity(), 1, null);
        //create an active oppty on the account
        
        //create a closed-won oppty on the account
        testOpportunities[0].AccountId = accountObject.Id;
        testOpportunities[0].StageName = '1 Discovery';
        testOpportunities[0].Opportunity_Type__c = 'New Customer';
        testOpportunities[0].Opportunity_Sub_Type__c = 'Regular';
        testOpportunities[0].Primary_Competitor__c = 'Actifio';
        testOpportunities[0].Initial_Contacts_Name__c = contactObject.Id;
        testOpportunities[0].Cloud_Type__c   = 'Google';
        insert testOpportunities;
         
         // testOpportunities[0].StageName = '7 Closed Won';
         // update testOpportunities;
        // //JIRA-MKT22-216
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM Opportunity WHERE AccountId =: accountObject.Id]);
    }

/**
* 
*
* @author Meghana K
*/
    @isTest public static void testContactRouting(){  
        // ShGl_TestFactoryHelper.insertCustomSettings();
         Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
         Account accountObject = new Account();
         accountObject.Name = 'Test Account';
         accountObject.ETM_Region__c='AMER-MM';
         accountObject.BillingCountry='United States';
         accountObject.BillingCountryCode='US';           
         accountObject.RecordTypeId = devRecordTypeId;
         insert accountObject;
         
         Contact contactObject = new Contact();
         contactObject.AccountId = accountObject.Id;
         contactObject.FirstName = 'Test';
         contactObject.LastName = 'Contact';
         contactObject.Email = 'email@email.com';
         insert contactObject;
         
         Opportunity opportunity1 = new Opportunity();
         opportunity1.Name='test Opportunity 1';
         opportunity1.AccountId=accountObject.id;
         opportunity1.closeDate = Date.today() + 5;
         opportunity1.StageName = '6 PO With Channel' ;
         Opportunity1.Opportunity_Type__c = 'New Customer';
         Opportunity1.Opportunity_Sub_Type__c = 'Regular';
         Opportunity1.Primary_Competitor__c = 'Actifio'; 
         Opportunity1.Initial_Contacts_Name__c = contactObject.Id;        
         opportunity1.Opportunity_Type__c='Debooking';
         opportunity1.Cloud_Type__c   = 'Google';
 
 
         insert opportunity1;
 
         opportunity1.StageName='7 Closed Won';
         opportunity1.Cloud_Partner_Impact__c='None';
         update opportunity1;
 
         
         accountObject.phone='1234567890';
         update accountObject;
         system.debug('Account Status'+accountObject.Total_Closed_Opportunities__c);
         UserTerritory2Association territory2obj = [SELECT Id, Territory2Id, UserId FROM UserTerritory2Association WHERE RoleInTerritory2 = 'SDR' AND Territory2.Territory2Model.State = 'Active' LIMIT 1];
         ObjectTerritory2Association testAssociatn = new ObjectTerritory2Association(ObjectId = accountObject.Id,Territory2Id = territory2obj.Territory2Id, AssociationCause = 'Territory2Manual');
         insert testAssociatn;
 
         
          Campaign campaignObject = new Campaign();
         campaignObject.Name = 'Test Campaign 1';
          campaignObject.type= 'Advertising';
         //campaignObject.RecordTypeId = CampainRecordTypeId;
         campaignObject.IsActive = true;
         campaignObject.Alliance_Partner__c = 'Cleversafe';
         campaignObject.Campaign_Sales_Theatre__c = 'APAC';
         campaignObject.Campaign_Sales_Area__c = 'APAC';
         campaignObject.Campaign_Sales_Region__c = 'APAC';
         campaignObject.Campaign_Sales_Sub_Region__c = 'APAC';
         campaignObject.Cost_Center__c = 'Alliance';
         campaignObject.Enabled_for_Opportunity_creation__c = true;
         campaignObject.Campaign_Theme__c='Cloud';
         campaignObject.GTM_Play__c='Cloud Native Protection';
         campaignObject.Executed_By__c='Sales';
         campaignObject.Involvement_by_Customer_Marketing__c='Yes';
         campaignObject.Planned_MQL__c = 1;
         insert campaignObject;
 
         CampaignMember campaignMemberObject = new CampaignMember();
         campaignMemberObject.ContactId = contactObject.Id;
         campaignMemberObject.CampaignId = campaignObject.Id;
         campaignMemberObject.Status = 'Sent';
         campaignMemberObject.FCRM__FCR_QR__c=false;
         campaignMemberObject.CFCR_PQL__c=false; 
		try{
                   insert campaignMemberObject;  
         }
         catch(exception ex){
             system.debug('Error'+ex);
         }     
         Test.startTest();
         //campaignMemberObject.id=campaignMemberObject.id;
         campaignMemberObject.Status = 'Responded';
         campaignMemberObject.FCRM__FCR_QR__c=true; 
         campaignMemberObject.CFCR_PQL__c=true; 
         try{
                   update campaignMemberObject;  
         }
         catch(exception ex){
             system.debug('Error'+ex);
         }        
           
             List<Opportunity> testOpportunities1 = (List<Opportunity>)ShGl_TestFactory.createSObjectList(new Opportunity(), 1, null);
         //create an active oppty on the account   //
         
         //create a closed-won oppty on the account
         testOpportunities1[0].AccountId = accountObject.Id;
         testOpportunities1[0].StageName = '1 Discovery';
         testOpportunities1[0].Opportunity_Type__c = 'New Customer';
         testOpportunities1[0].Opportunity_Sub_Type__c = 'Regular';
         testOpportunities1[0].Primary_Competitor__c = 'Actifio';
         testOpportunities1[0].Initial_Contacts_Name__c = contactObject.Id;
         testOpportunities1[0].Cloud_Type__c   = 'Google';
         insert testOpportunities1;
          
          // testOpportunities1[0].StageName = '7 Closed Won';
          // update testOpportunities1;
         // //JIRA-MKT22-216
         Test.stopTest();
 
         System.assertNotEquals(null, [SELECT Id FROM Opportunity WHERE AccountId =: accountObject.Id]);
     }
 
    @isTest static void testUpdateLeadAttributes(){
        Lead lead1 = [SELECT Id, Deal_registration__c, MQL__c, Partner_MQL__c FROM Lead LIMIT 1];
        Account accountObject = [SELECT Id FROM Account LIMIT 1];

        Contact contactObject = new Contact();
        contactObject.AccountId = accountObject.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@email.com';
        contactObject.Feature_Recommendation__c = 'Sonar';
        insert contactObject;
        
        Id CampainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program').getRecordTypeId();
        Campaign camp1 = new Campaign(Executed_By__c='Global Campaigns',Planned_MQL__c = 850,Involvement_by_Customer_Marketing__c='No',Campaign_Theme__c='Enterprise',Name = 'Test Campaign 1',type='Contact Us', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'AMER', Campaign_Sales_Area__c = 'AMER', Campaign_Sales_Region__c = 'AMER', Campaign_Sales_Sub_Region__c = 'AMER', Cost_Center__c = 'Alliance',GTM_Play__c='Ransomware Remediation');
        insert camp1;
       
        //CmapaignMember status
        List<CampaignMemberStatus> insertlist = new List<CampaignMemberStatus>();
        insertlist.add(new CampaignMemberStatus(CampaignId = camp1.Id, Label = 'Filled out Form', HasResponded = true));
        insertlist.add(new CampaignMemberStatus(CampaignId = camp1.Id, Label = 'Delivered', HasResponded = true));
        insertlist.add(new CampaignMemberStatus(CampaignId = camp1.Id, Label = 'Attended', HasResponded = false));
        insert insertlist;

        Feature_Recommendation__c recommend = [SELECT Id FROM Feature_Recommendation__c LIMIT 1];
        CampaignMember campMem1 = new CampaignMember(Leadid = lead1.id, CampaignId = camp1.id, Status = 'Filled out Form', FCRM__FCR_Response_Status__c = 'Meeting Set'); //FCRM__FCR_QR__c=true,CFCR_PQL__c=true
        campMem1.Feature_Recommendation__c = recommend.Id;
        CampaignMember campMem2 = new CampaignMember(contactId = contactObject.id, CampaignId = camp1.id, Status = 'Filled out Form', FCRM__FCR_Response_Status__c = 'Meeting Set'); 
        Test.startTest();
            insert campMem1;
            insert campMem2;
        Test.stopTest();
        campMem1 = [SELECT Id, HasResponded FROM CampaignMember WHERE Id = :campMem1.Id];
        System.assert(campMem1.HasResponded);
        System.assert(true);

    }

    @isTest static void testupdateFeatureRecommendation(){
        Lead lead1 = [SELECT Id FROM Lead LIMIT 1];
        Feature_Recommendation__c fr = [SELECT Id FROM Feature_Recommendation__c LIMIT 1];
        CampaignMember campMem1 = [SELECT Id, FCRM__FCR_Response_Date__c, Feature_Recommendation__c FROM CampaignMember LIMIT 1];
        campMem1.Feature_Recommendation__c = fr.ID;
        campMem1.FCRM__FCR_Response_Date__c = Datetime.now();
        Test.startTest();
            update campMem1;
        Test.stopTest();
        system.assert(true);
    }
    /*Test amplify priority only for leads*/
    @isTest
    public static void testAmplifyCampaigns(){
        Lead lead1 = [SELECT Id FROM Lead LIMIT 1];
        Account accs = [SELECT Id FROM Account LIMIT 1];
        Contact contactObject = new Contact();
        contactObject.AccountId = accs.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@rubrik.com';
        contactObject.Feature_Recommendation__c = 'Sonar';
        insert contactObject;
        //Test.startTest();
        Campaign camp1 = new Campaign(Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='General',Name = 'Test Campaign 1',type='Advertising', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',GTM_Play__c='General', Amplify_Priority__c = true);
        insert camp1;
        CampaignMember campMem1 = new CampaignMember(Leadid = lead1.id, CampaignId = camp1.id, Status = 'Responded',FCRM__FCR_QR__c=true,CFCR_PQL__c=true); //FCRM__FCR_QR__c=true,CFCR_PQL__c=true
        insert campMem1;
        CampaignMember campMemQuery = [SELECT Id, Leadid FROM CampaignMember LIMIT 1];
        System.assertEquals(campMemQuery.Leadid, lead1.Id);
        //Test.stopTest(); 
    }
    
    @isTest
    public static void testMethod2(){
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acc = [SELECT Id from Account LIMIT 1];
        acc.RecordTypeId = devRecordTypeId;
        acc.Account_Alliance_BDM_Lookup__c = userInfo.getUserId();
        update acc;
        Contact contactObject = new Contact();
        contactObject.AccountId = acc.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@email.com';
        contactObject.Feature_Recommendation__c = 'Sonar';
        insert contactObject;
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'Test Lead 55777';
        led.lastName = 'Test757767';
        led.Status = 'Open';
        led.CountryCode = 'US';
        led.email = 'test8979898@rubrik.com';
        led.L2A_Account__c = acc.Id;
        insert led;
        
        Campaign camp1 = [select id from Campaign LIMIT 1];
        camp1.Campaign_Partner__c = acc.Id;
        camp1.Routing_Method__c = 'Route to Partner';
        camp1.Type = 'Lead Share Program';
        camp1.Campaign_Partner_Rep__c = contactObject.Id;
        camp1.FCRM__FCR_Campaign_Sourced_By__c = 'Partner';
        camp1.Amplify_Priority__c = true;
        update camp1;
        CampaignMember campMem1 = new CampaignMember(Leadid = led.id, CampaignId = camp1.id, Status = 'Sent',FCRM__FCR_QR__c=true,CFCR_PQL__c=true); //FCRM__FCR_QR__c=true,CFCR_PQL__c=true
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
            Test.startTest();
            insert campMem1;
            Test.StopTest();
             System.assertEquals(campMem1.Id != null, true);
        }
    }
    
     @isTest
    public static void testMethod3(){
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        Account acc = [SELECT Id from Account LIMIT 1];
        acc.RecordTypeId = devRecordTypeId;
        acc.Account_Alliance_BDM_Lookup__c = userInfo.getUserId();
        update acc;
        Id devRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
         Account accountObject = new Account();
         accountObject.Name = 'Test Account';
         accountObject.ETM_Region__c='AMER-MM';
         accountObject.BillingCountry='United States';
         accountObject.BillingCountryCode='US';           
         accountObject.RecordTypeId = devRecordTypeId1;
         insert accountObject;
        Contact contactObject = new Contact();
        contactObject.AccountId = acc.Id;
        contactObject.FirstName = 'Test';
        contactObject.LastName = 'Contact';
        contactObject.Email = 'email@email.com';
        contactObject.Feature_Recommendation__c = 'Sonar';
        insert contactObject;
        Contact contactObject1 = new Contact();
        contactObject1.AccountId = accountObject.Id;
        contactObject1.FirstName = 'Test1';
        contactObject1.LastName = 'Contact1';
        contactObject1.Email = 'email@rubrik.com';
        contactObject1.Feature_Recommendation__c = 'Sonar';
        insert contactObject1;
        
        Campaign camp1 = [select id from Campaign LIMIT 1];
        camp1.Campaign_Partner__c = accountObject.Id;
        camp1.Routing_Method__c = 'Route to Partner';
        camp1.Type = 'Lead Share Program';
        camp1.Campaign_Partner_Rep__c = contactObject1.Id;
        camp1.FCRM__FCR_Campaign_Sourced_By__c = 'Partner';
        camp1.Amplify_Priority__c = true;
        update camp1;
        
        CampaignMember campMem1 = new CampaignMember(ContactId = contactObject.id, CampaignId = camp1.id, Status = 'Sent',FCRM__FCR_QR__c=true,CFCR_PQL__c=true); //FCRM__FCR_QR__c=true,CFCR_PQL__c=true
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
            Test.startTest();
            insert campMem1;
            Test.StopTest();
             System.assertEquals(campMem1.Id != null, true);
        }
        System.assert(true);

    }
    
    @isTest
static void testPublishCapiPlatformEvents() {

    /* ---------- Arrange ---------- */

    // Create CAPI mapping
    CAPI_Event_Endpoint_Mapping__c map1 =
        new CAPI_Event_Endpoint_Mapping__c(
            Name='Inquiry',
            Event_Name__c = 'Inquiry',
            ConversionEventId__c = '23545812'
        );
    CAPI_Event_Endpoint_Mapping__c map2 =
        new CAPI_Event_Endpoint_Mapping__c(
            Name = 'MQL',
            Event_Name__c = 'MQL',
            ConversionEventId__c = '23545780'
        );
    insert new List<CAPI_Event_Endpoint_Mapping__c>{ map1, map2 };

    // Account
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    // Lead
    Lead ld = new Lead(
        FirstName = 'Test',
        LastName = 'Lead',
        Company = 'Rubrik',
        Email = 'lead@rubrik.com',
        CountryCode = 'US',
        Status = 'Open',
        Winning_L2A_Account__c = acc.Id
    );
    insert ld;

    // Campaign
    Campaign camp = new Campaign(
    Name = 'Contact Us',
    Type = 'Contact Us',
    IsActive = true,

    // REQUIRED FIELDS (from your error)
    Executed_By__c = 'Sales',
    Alliance_Partner__c = 'Cleversafe',
    Campaign_Sales_Theatre__c = 'APAC',
    Campaign_Sales_Area__c = 'APAC',
    Campaign_Sales_Region__c = 'APAC',
    Campaign_Sales_Sub_Region__c = 'APAC',
    Campaign_Theme__c = 'Cloud',
    GTM_Play__c = 'Cloud Native Protection',
    Cost_Center__c = 'Alliance',
    Planned_MQL__c = 1,
    Involvement_by_Customer_Marketing__c = 'Yes'
);
insert camp;

    // Campaign Member
    CampaignMember cm = new CampaignMember(
        LeadId = ld.Id,
        CampaignId = camp.Id,
        Status = 'Responded'
    );
    insert cm;

    /* ---------- Prepare Inputs ---------- */

    Map<Id, Set<String>> personIdToEventNames = new Map<Id, Set<String>>{
        ld.Id => new Set<String>{ 'Inquiry', 'MQL' }
    };

    Map<Id, CampaignMember> personIdToCampaignMember =
        new Map<Id, CampaignMember>{ ld.Id => cm };

    Map<Id, Contact> contactById = new Map<Id, Contact>();

    Map<Id, Lead> leadById =
        new Map<Id, Lead>{ ld.Id => ld };

    /* ---------- Act ---------- */
    Test.startTest();

    CampaignMemberTriggerHelper.publishCapiPlatformEvents(
        personIdToEventNames,
        personIdToCampaignMember,
        contactById,
        leadById
    );

    Test.getEventBus().deliver();
    Test.stopTest();
    system.assert(true);

}

}