@isTest
public class OpportunityCohesityDealBatch_Test {
    
  /*  @testSetup
    static void setup() {
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c=true, Bypass_Pricebook_Setting_on_Quote__c=true);
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId());
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
            User sysAdmin = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com',
                Alias = 'xmen',
                Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );
            Database.insert(sysAdmin);
        }
    }*/
    
    //Example Test Class Code
    static testMethod void testMethod_ContactCreation() {
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    
                    List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 6, oppMap);
        
        integer i=0;
        for(Opportunity opp: opptyList){            
            if(i==0){
                opp.Next_Step__c='c-co';
            }
            if(i==1){
                opp.Next_Step__c='TEST Cohesity';
            }
            if(i==2){
                opp.Primary_Competitor__c = 'Cohesity';
            }
            if(i==3){
                opp.Other_Primary_Competitor__c = 'Testing Cohesity Test';
            }
            if(i==4){
                opp.Win_Loss_Comments__c = 'Cohesity Test';
            }
            if(i==5){
                opp.Cohesity_Deal__c = true;
            }
            i++;
        }       
        
        insert opptyList;
        
        Test.startTest();        
        OpportunityCohesityDealBatch batch = new OpportunityCohesityDealBatch(); 
        database.executeBatch(batch,20);
        
        OpportunityCohesityDealBatchScheduler sh1 = new OpportunityCohesityDealBatchScheduler();
        String sch = '0 0 2 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1); 
        // add system asserts to check your expected behaviour
        Test.stopTest();
        
        Integer cdCount = [SELECT count() FROM Opportunity where Cohesity_Deal__c=true];
        system.assertEquals(5, cdCount);
    }
}