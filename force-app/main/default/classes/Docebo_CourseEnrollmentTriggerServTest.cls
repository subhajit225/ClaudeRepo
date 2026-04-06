/********************************************************************
* $Id$: Docebo_CourseEnrollmentTriggerServiceTest 
* $Created Date$: 26-Sept-2019
* $Author$: Santosh Gore
* $Description$ : Test Class of the Docebo_CourseEnrollmentTriggerService
********************************************************************/
@isTest
private class Docebo_CourseEnrollmentTriggerServTest {
    
    /**
@Name        : setupTestData
@Description : Test data creation
*/
    @testSetup static void setupTestData() {
        user u = ShGl_TestFactory.createUserwithRole();

        //Create Account
        system.runas(u){
            Id accountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account docebo_Account = new Account(Name = 'DoceboTest', type='MSP', billingCountry = 'United States', recordtypeId=accountRecTypeId);
            insert docebo_Account;
            
            //insert contact
            Contact con = new Contact (
                AccountId = docebo_Account.id,
                LastName = 'doceboTestContact',
                PSE_Shadow_Completed__c = Date.today()
            );
            insert con;
            
            //UserRole ur = [SELECT Id, PortalAccountId From UserRole WHERE name = 'Rubrik Partner Community Manager' limit 1];
            Profile p = [SELECT Id,name FROM Profile  
                         WHERE name = 'Rubrik Partner Community Manager' LIMIT 1];
            
            //Create user
            User user = new User(alias = 'docebo', email='doceboTestUser@svg.com',
                                 emailencodingkey='UTF-8', lastname='doceboTest', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',IsActive = true,
                                 ContactId = con.Id,
                                 timezonesidkey='America/Los_Angeles', username='doceboTestUser@svg.com');
            
            insert user;
            
            //create Docebo user record
            docebo_v3__DoceboUser__c doceboUser = new docebo_v3__DoceboUser__c(
                Name = '322434',
                docebo_v3__User__c = user.Id,
                docebo_v3__UserId__c = 234234
            );
            
            insert doceboUser;
            
            //insert Docebo courses
            docebo_v3__Course__c dCourse1 = new docebo_v3__Course__c (
                name = 'C64',
                docebo_v3__Name__c = 'C64',
                docebo_v3__Code__c = 'C64',
                docebo_v3__CourseId__c = 10132,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            
            docebo_v3__Course__c dCourse2 = new docebo_v3__Course__c (
                name = 'C83',
                docebo_v3__Name__c = 'C83',
                docebo_v3__Code__c = 'C83',
                docebo_v3__CourseId__c = 10133,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            
            docebo_v3__Course__c dCourse3 = new docebo_v3__Course__c (
                name = 'PAR_C_Foundations',
                docebo_v3__Name__c = 'PAR_C_Foundations',
                docebo_v3__Code__c = 'PAR_C_Foundations',
                docebo_v3__CourseId__c = 10134,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            
            docebo_v3__Course__c dCourse4 = new docebo_v3__Course__c (
                name = 'PAR_C_Essentials',
                docebo_v3__Name__c = 'PAR_C_Essentials',
                docebo_v3__Code__c = 'PAR_C_Essentials',
                docebo_v3__CourseId__c = 10136,
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Language__c = 'English',
                docebo_v3__Effective__c = true
            );
            
            docebo_v3__Course__c dCourse5 = new docebo_v3__Course__c (
                name = 'PAR_E_RTP_Test',
                docebo_v3__Name__c = 'PAR_E_RTP_Test',
                docebo_v3__Code__c = 'PAR_E_RTP_Test',
                docebo_v3__CourseId__c = 10137,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            docebo_v3__Course__c dCourse6 = new docebo_v3__Course__c (
                name = 'Rubrik_Rewards_Sales_Accreditation_2024',
                docebo_v3__Name__c = 'Rubrik_Rewards_Sales_Accreditation_2024',
                docebo_v3__Code__c = 'Rubrik_Rewards_Sales_Accreditation_2024',
                docebo_v3__CourseId__c = 10138,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            docebo_v3__Course__c dCourse7 = new docebo_v3__Course__c (
                name = 'RCDP_Technical_OCT_2024',
                docebo_v3__Name__c = 'RCDP_Technical_OCT_2024',
                docebo_v3__Code__c = 'RCDP_Technical_OCT_2024',
                docebo_v3__CourseId__c = 10139,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            
            docebo_v3__Course__c dCourse8 = new docebo_v3__Course__c (
                name = 'RU-RCRS -V1-FinalExam',
                docebo_v3__Name__c = 'RU-RCRS -V1-FinalExam',
                docebo_v3__Code__c = 'RU-RCRS -V1-FinalExam',
                docebo_v3__CourseId__c = 10140,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            docebo_v3__Course__c dCourse9 = new docebo_v3__Course__c (
                name = 'RU-RCCS -V1-FinalExam',
                docebo_v3__Name__c = 'RU-RCCS -V1-FinalExam',
                docebo_v3__Code__c = 'RU-RCCS -V1-FinalExam',
                docebo_v3__CourseId__c = 10141,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            
            docebo_v3__Course__c dCourse10 = new docebo_v3__Course__c (
                name = 'RCDP Sales OCT 2024',
                docebo_v3__Name__c = 'RCDP Sales OCT 2024',
                docebo_v3__Code__c = 'RCDP Sales OCT 2024',
                docebo_v3__CourseId__c = 10142,
                docebo_v3__Language__c = 'English',
                docebo_v3__CreationDate__c = Date.today(),
                docebo_v3__Effective__c = true
            );
            
            insert new List<docebo_v3__Course__c> {dCourse1, dCourse2, dCourse3, dCourse4, dCourse5, dCourse6, dCourse7, dCourse8, dCourse9,dCourse10};
                }
    }
    
    /**
@Name        : doceboCousesEnrollment_alltest
@Description : Bulk MSP record creation and starting Approval process
*/
    @isTest static void doceboCousesEnrollment_alltest() {
        List<docebo_v3__DoceboUser__c> doceboUser = [SELECT Id, docebo_v3__User__c, docebo_v3__User__r.ContactId
                                                     FROM docebo_v3__DoceboUser__c];
        List<docebo_v3__CourseEnrollment__c> courseEnrollmentList = getCourseEnrollmentRecord(doceboUser[0]);
        
        Test.startTest();
        insert courseEnrollmentList;
        Test.stopTest();
        Id conId = doceboUser[0].docebo_v3__User__r.ContactId;
        List<Contact> contact = [SELECT Id,RTP_Accredited__c,RTP_Expiration__c,RPSE_Accredited__c,RPSE_Expiration__c,RSP_Accredited__c,RSP_Expiration__c FROM Contact WHERE Id = :conId];
        
        System.assert(contact[0].RTP_Accredited__c != null);
    }
    
    /**
@Name        : doceboCousesEnrollment_updatetest
@Description : Bulk MSP record creation and starting Approval process
*/
    @isTest static void doceboCousesEnrollment_updatetest() {
        List<docebo_v3__DoceboUser__c> doceboUser = [SELECT Id, docebo_v3__User__c, docebo_v3__User__r.ContactId
                                                     FROM docebo_v3__DoceboUser__c];
        List<docebo_v3__CourseEnrollment__c> courseEnrollmentList = getCourseEnrollmentRecord(doceboUser[0]);
        courseEnrollmentList[0].docebo_v3__Status__c = 'In_Progress';
        insert courseEnrollmentList;
        Test.startTest();
        courseEnrollmentList[0].docebo_v3__Status__c = 'Completed';
        update courseEnrollmentList[0];
        Test.stopTest();
        Id conId = doceboUser[0].docebo_v3__User__r.ContactId;
        List<Contact> contact = [SELECT Id,RTP_Accredited__c,RTP_Expiration__c,RPSE_Accredited__c,RPSE_Expiration__c,RSP_Accredited__c,RSP_Expiration__c FROM Contact WHERE Id = :conId];
        
        System.assert(contact[0].RTP_Accredited__c != null);
    }
    
    /**
@Name        : getCourseEnrollmentRecord
@Description : create course enrollment records
*/
    private static List<docebo_v3__CourseEnrollment__c> getCourseEnrollmentRecord(docebo_v3__DoceboUser__c doceboUser) {
        List<docebo_v3__CourseEnrollment__c> courseEnrollmentList = new List<docebo_v3__CourseEnrollment__c>();
        Integer enrollNo = 0;
        for(docebo_v3__Course__c dc : [SELECT Id FROM docebo_v3__Course__c ]){
            docebo_v3__CourseEnrollment__c ce = new docebo_v3__CourseEnrollment__c(
                docebo_v3__Course__c = dc.Id,
                docebo_v3__DoceboUser__c = doceboUser.Id,
                docebo_v3__EnrollmentStartDate__c = Date.today().addDays(-15),
                docebo_v3__EnrollmentCompletionDate__c = Date.today(),
                docebo_v3__EnrolmentId__c  = '34523'+enrollNo,
                docebo_v3__Status__c = 'Completed'
            );
            courseEnrollmentList.add(ce);
            enrollNo++;
        }
        return courseEnrollmentList;
    }
}