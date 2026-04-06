/*
* @Author           :   Shiva Sharma
* @CreatedDate      :   
* @Jira Ticket      :   
* @Description      :   
* @TestClass        :   CS_InsightMatchesControllerTest.cls
* Modified History  :   CS21-886 by vijay.kr@rubrik.com, June 23 2022
*/
trigger DomainTrigger on WL_Domain__c (before insert, after insert, before update, after update, before delete, after delete) {
    new DomainTriggerHandler().run();
}