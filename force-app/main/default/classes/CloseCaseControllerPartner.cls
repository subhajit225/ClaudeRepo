/*
* Class Name :- CloseCaseControllerPartner
* Test Class :- CloseCaseControllerPartnerTest
* Author :- Sushant Arora
* Created Date :- 26-08-2023
* Description : This Class is used in the closeCaseCmpPartner.
*/

public with sharing class CloseCaseControllerPartner {
   
    @AuraEnabled
    public static String getPartnerRecordTypeId(){
        String partnerRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Case').getRecordTypeId();
        return partnerRecordTypeId;
    }
}