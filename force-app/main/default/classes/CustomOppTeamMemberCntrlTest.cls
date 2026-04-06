@isTest
public class CustomOppTeamMemberCntrlTest{


@isTest
public static void testmethod1(){
   ShGl_TestFactoryHelper.insertCustomSettings();
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
         Map < String, Object > cntMap = new Map < String, Object > {
            'AccountId' => act.Id,
                'Email' => 'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt1;
        
        //Generate the Opportunity
        Map < String, Object > oppMap = new Map < String, Object > {
            'AccountId' => act.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'StageName' => '4 Business Justification'
                };
                    
                    List < Opportunity > opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
        opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com';
        opptyList[0].Converted_From_Lead__c = true;
        //opptyList[0].split__c = true;
        opptyList[0].SBQQ__Ordered__c = true;
        opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
        opptyList[0].Primary_Competitor__c = 'Other';
        opptyList[0].ForecastCategoryName = 'Best Case';
        opptyList[0].Other_Competitor_Field__c = 'Testing';
        insert opptyList;
        
        
        Pagereference custOpppg = Page.CustomOppTeamMember;
        custOpppg.getparameters().put('oppId',opptyList[0].id);
        Test.setCurrentPage(custOpppg);
        CustomOppTeamMemberCntrl cc = new CustomOppTeamMemberCntrl();
        cc.OppTeamMember.UserId = Userinfo.getuserid();
        cc.addOppTeamMember();
        LCC_Credit_SDRISR_Opportunity_Controller.opportunityApproval(opptyList[0].id);

}

}