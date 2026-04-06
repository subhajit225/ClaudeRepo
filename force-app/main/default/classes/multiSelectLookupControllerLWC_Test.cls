/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
**/

@isTest
public class multiSelectLookupControllerLWC_Test {
	@isTest
    public static  void testFetchLookUpValues() {
        List<sObject> li = multiSelectLookupControllerLWC.retriveSearchData('User','Id','Rajat Jain',null);
        system.assert(li.size()>0);
    }
}