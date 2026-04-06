/*********************************************************************************
  *@description  : SF-3567
  *@Name         : RollupSummaryUtility
  *@Created Date : 29th Nov 2019
  *@Author       : Santosh G
  *TestClass     : RollupSummaryUtilityTest
**********************************************************************************/
public without sharing class RollupSummaryUtility {
    
    private static final String BLOCKER_SEVERITY = 'Blocker';
    private static final String MAJOR_SEVERITY = 'Major';

    /**
       *@description Perform aggregation of Issue Tracker on Opportunity
       *@param issueTrackerList new record
       *@param issueTrackerOldMap Map<Id,Opportunity> old record
    */
    public static void rollupIssueTrackerOnOppty(List<Opportunity_Debrief__c> issueTrackerList, Map<Id, Opportunity_Debrief__c> issueTrackerOldMap) {
        
        Map<Id,Opportunity> updateOpptyMap = new Map<Id,Opportunity>();
        //populate updateOpptyMap for default values
        for(Opportunity_Debrief__c it : issueTrackerList) {
            if(issueTrackerOldMap == null 
                || (it.PM_Review_Status__c != issueTrackerOldMap.get(it.Id).PM_Review_Status__c)
                || (it.Severity__c != issueTrackerOldMap.get(it.Id).Severity__c)) {
                
                updateOpptyMap.put(it.Opportunity__c, new Opportunity (
                                                        Id = it.Opportunity__c, 
                                                        Issue_Tracker_Count_Open_Blocker__c = 0,
                                                        Issue_Tracker_Count_Open_Major__c = 0 
                                                    )
                                  );
            }
        }
        for(AggregateResult ar : [SELECT Count(Id) issueTrackerCount, Opportunity__c,Severity__c 
                                    FROM Opportunity_Debrief__c 
                                    WHERE Opportunity__c IN :updateOpptyMap.keySet() 
                                    AND PM_Review_Status__c != 'Review Completed - Resolution Identified'
                                    AND PM_Review_Status__c != 'Review Completed - No Current Resolution'
                                    GROUP BY Opportunity__c, Severity__c]) {
            Id oppId = (Id)ar.get('Opportunity__c');
            Integer cCount =  (Integer)ar.get('issueTrackerCount');
            String cSeverity = (String) ar.get('Severity__c');
            
            if(String.isNotBlank(cSeverity) && BLOCKER_SEVERITY.equalsIgnoreCase(cSeverity)) {
                updateOpptyMap.get(oppId).Issue_Tracker_Count_Open_Blocker__c = (updateOpptyMap.get(oppId).Issue_Tracker_Count_Open_Blocker__c + cCount);
            } else if(String.isNotBlank(cSeverity) && MAJOR_SEVERITY.equalsIgnoreCase(cSeverity)) {
                updateOpptyMap.get(oppId).Issue_Tracker_Count_Open_Major__c = (updateOpptyMap.get(oppId).Issue_Tracker_Count_Open_Major__c + cCount);
            }           
                                    
        }
        
        
        if(!updateOpptyMap.isEmpty()) {
            Database.update(updateOpptyMap.values(), false);
        }
    }

    /**
    * @description  perform roll up summary of Case count in Account, To count the total no. of support cases 
				   and total no. of open support cases under an account as per CS-428 - Anmol Baweja - 11 Dec, 2019
    * @param newCaseList  List<Case> new Cases, Trigger contect variable
    * @param caseOldMap Map<Id,Case> Old Case Map, Trigger contect variable
    */
    public static void rollupCasesOnAccount(List<Case> newCaseList, Map<Id, Case> caseOldMap) {
        Map<Id, Account> accounts = new Map<Id, Account>();
        
        for(Case newCase : newCaseList) {
            if(newCase.accountId != null && (caseOldMap == null 
                                             || (newCase.Priority != caseOldMap.get(newCase.Id).Priority)
                                             || (newCase.IsClosed != caseOldMap.get(newCase.Id).IsClosed)))
            {
                accounts.put(newCase.AccountId, new Account (Id = newCase.AccountId,
                                                                Cases_Count__c = 0,
                                                                No_Of_Open_Support_Cases__c= 0,
                                                                Cases_Open_P1__c = 0,
                                                                Cases_Open_P2__c = 0));
            }
        }
        
        for(AggregateResult result : [SELECT Count(Id) caseCount, AccountId, Priority, IsClosed 
                                      FROM Case 
                                      WHERE AccountId IN :accounts.keySet() AND (RecordType.DeveloperName = 'Support_Case' OR RecordType.DeveloperName = 'Support_Case_Customer_Community'
                                                                                 OR RecordType.DeveloperName = 'Customer_Success')
                                      GROUP BY AccountId, Priority, IsClosed])
        {
            Id accountId = (Id)result.get('AccountId');
            Integer caseCount =  (Integer)result.get('caseCount');
            
            if (!(Boolean)result.get('IsClosed')) {
                String priority = (String)result.get('Priority');
                
                accounts.get(accountId).No_Of_Open_Support_Cases__c +=  caseCount;
                
                if(String.isNotBlank(priority) && priority.startsWithIgnoreCase('P1')) {
                    accounts.get(accountId).Cases_Open_P1__c += caseCount;
                } else if(String.isNotBlank(priority) && priority.startsWithIgnoreCase('P2')) {
                    accounts.get(accountId).Cases_Open_P2__c += caseCount;
            }
            } 
            
            accounts.get(accountId).Cases_Count__c += caseCount;
        }
        
        if (!accounts.isEmpty()) {
            List<Database.SaveResult> results = Database.update(accounts.values(), false);
        }
    }


}