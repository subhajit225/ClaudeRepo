/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
* Test Class : multiSelectLookupControllerLWC_Test
**/
public with sharing class multiSelectLookupControllerLWC {
    @AuraEnabled(cacheable=true)
    public static List<sObject> retriveSearchData(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<sObject> sObjectResultList = new List<sObject>();
        if(selectedRecId == null)
            selectedRecId = new List<String>();
        if(String.isNotEmpty(value)) {
            String query = 'Select '+fieldName+' FROM '+ObjectName+' WHERE Name LIKE \'' + value.trim() + '%\' and ID NOT IN: selectedRecId and UserType =\'Standard\' order by createdDate DESC LIMIT 10';
            for(sObject so : Database.Query(query)) {
                sObjectResultList.add(so);
            }
        }
        return sObjectResultList;
    }
}