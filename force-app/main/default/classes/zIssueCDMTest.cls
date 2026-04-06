@isTest
public class zIssueCDMTest {
    static testMethod void Method1() {
        insert new TriggerControl__c(Name='Entitlement');
        insert new TriggerControl__c(Name='zIssueCDM');
        ZJIRACaseWebservice.byPassCallout = true;
        List<string> memberIdList = new List<string>();
        insert new TriggerControl__c(Name='Case'); 
        Account testAccount = new Account(name='Test Company Name');
        insert testAccount;
        Contact testContactDummy = new Contact();
        Contact testContact = new Contact(AccountId=testAccount.Id, FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test@test.com');
        insert testContact;
        
        Profile prof = [Select Id,Name from Profile where name=:'Rubrik Customer Community Login User (No Cases)' Limit 1];
        User u = new User(Alias = 'standt1', email='standarduser1@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = prof.Id, 
                          TimeZoneSidKey='America/Los_Angeles', username='standarduser@testorg131saurv.com');
        u.ContactId= testContact.Id;
        insert u;
        Case ca = new Case(Subject='Test Controller Acct Case',Priority = 'P1');
        insert ca;
        insert new zsfjira__ZIssue__c(name='CDM-124',zsfjira__IssueKey__c='CDM-124',zsfjira__IssueId__c=124);
        zsfjira__ZIssue__c zissue = new zsfjira__ZIssue__c(name='CDM-123',zsfjira__IssueKey__c='CDM-123',zsfjira__IssueId__c=123);
        insert zissue;
        insert new zsfjira__ZIssue_Case__c(Name='CDM-123',zsfjira__CaseId__c=ca.Id,zsfjira__ZIssueId__c=zissue.Id);
        insert new zsfjira__ZIssue_SF__c(Name='CDM-123',zsfjira__Case__c=ca.Id,zsfjira__ZIssue__c=zissue.Id,zsfjira__IssueId__c =zissue.zsfjira__IssueId__c);
        
        zissue.Duplicate_of__c = 'CDM-124';
        update zissue;
    }

}