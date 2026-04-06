/*
* @Author           :   Vijay Kumar K R
* @CreatedDate      :   
* @Trigger          :   DomainTrigger.trigger
* Modified History  :   CS21-886 by vijay.kr@rubrik.com, June 23 2022
*/
@isTest
public with sharing class DomainTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        
        Test.startTest();
        TriggerControl__c trigCtrl = new TriggerControl__c(Name='AllowedDomain',DisableTrigger__c=false);
        insert trigCtrl;

        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        Account acc = new Account(Name='Test Account');
        insert acc;

        // non Rubrik Acc
        WL_Domain__c domain1 = new WL_Domain__c(Name='testDm.com',Account__c = acc.Id);
        Database.SaveResult res1 = Database.insert(domain1, false);
        System.assertEquals(false,res1.isSuccess());

        WL_Domain__c rubDomain = new WL_Domain__c(Name='rubrik.com',Account__c = acc.Id);
        Database.SaveResult nonRubAcc = Database.insert(rubDomain, false);
        System.assertEquals(DomainTriggerHandler.UNAUTHORIZED_USER_ERR ,nonRubAcc.getErrors()[0].getMessage());

        // Rubrik Acc
        WL_Domain__c domain2 = new WL_Domain__c(Name='testDm.com',Account__c = rbkAcc.Id);
        Database.SaveResult res2 = Database.insert(domain2, false);
        System.assertEquals(false,res2.isSuccess());

        WL_Domain__c rubDomain1 = new WL_Domain__c(Name='rubrik.com',Account__c = rbkAcc.Id);
        Database.SaveResult nonRubAcc1 = Database.insert(rubDomain1, false);
        System.assertEquals(DomainTriggerHandler.UNAUTHORIZED_USER_ERR ,nonRubAcc1.getErrors()[0].getMessage());
    }

    @isTest
    static void testNonApprovedDomainForSupportOperationUsers(){
        Account objAcc = [SELECT Id FROM Account WHERE Name='Test Account' Limit 1];
        Account rubrikAcc = [SELECT Id FROM Account WHERE Name='Rubrik' Limit 1];

        String uniqueUserName = 'shivani.naik' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support Manager'];
        User objUser = new user( alias = 'snaik',
                                    email = 'shivani.naik@rubrik.com',
                                    emailencodingkey = 'UTF-8',
                                    firstname = 'Shivani',
                                    lastname = 'Naik',
                                    languagelocalekey = 'en_US',
                                    localesidkey = 'en_US',
                                    profileid = p.Id,
                                    timezonesidkey = 'America/Los_Angeles',
                                    username = uniqueUserName);
        insert objUser;
        
        System.runAs(objUser) {
            Test.startTest();
            // Non Rubrik Acc
            // rubrik domain
            WL_Domain__c rubrikDomain = new WL_Domain__c(Name='rubrik.com', Account__c = objAcc.Id);
            Database.SaveResult result = Database.insert(rubrikDomain, false);
            System.assertEquals(DomainTriggerHandler.NON_RUBRIK_ACC_DOMAIN_ERR ,result.getErrors()[0].getMessage());

            // non rubrik domain
            WL_Domain__c objDomain = new WL_Domain__c(Name='rubrik123.com', Account__c = objAcc.Id);
            Database.SaveResult result2 = Database.insert(objDomain, false);
            System.assertEquals(true,result2.isSuccess());

            // duplicate domain
            WL_Domain__c objDomain1 = new WL_Domain__c(Name='rubrik123.com', Account__c = objAcc.Id);
            Database.SaveResult result3 = Database.insert(objDomain1, false);
            System.assertEquals(DomainTriggerHandler.DUPLICATE_DOMAIN_ERROR ,result3.getErrors()[0].getMessage());

            // multiple domain(s)
            WL_Domain__c objDomain2 = new WL_Domain__c(Name='rubrik1234.com', Account__c = objAcc.Id);
            Database.SaveResult result4 = Database.insert(objDomain2, false);
            System.assertEquals(true,result4.isSuccess());

            // Rubrik Acc
            WL_Domain__c objDomain3 = new WL_Domain__c(Name='rubrik.com', Account__c = rubrikAcc.Id);
            Database.SaveResult result5 = Database.insert(objDomain3, false);
            System.assertEquals(true,result5.isSuccess());

            // multiple domain(s)
            WL_Domain__c objDomain4 = new WL_Domain__c(Name='rubrikABC.com', Account__c = rubrikAcc.Id);
            Database.SaveResult result6 = Database.insert(objDomain4, false);
            System.assertEquals(true,result6.isSuccess());

            // Ignored domain
            WL_Domain__c objDomain5 = new WL_Domain__c(Name='googlemail.com', Account__c = rubrikAcc.Id);
            Database.SaveResult result7 = Database.insert(objDomain5, false);
            System.assertEquals(DomainTriggerHandler.IGNORED_DOMAIN_NAME_ERR ,result7.getErrors()[0].getMessage());

            // before update:
            WL_Domain__c objDomain6 = [SELECT Id FROM WL_Domain__c WHERE Name='rubrik123.com' Limit 1];
            objDomain6.Name = 'demo123.com';
            Database.SaveResult result8 = Database.update(objDomain6, false);
            System.assertEquals(true,result8.isSuccess());
            Test.stopTest();
            
        }
    }

}