public without sharing class CustomerReportController {
    public Map<ID, Account> AccountClusterMap{get;set;}
    public List<Account> fetchAcc{get;set;}
    
    public CustomerReportController(){
        fetchAcc = new List<Account>();
        List<Opportunity> ClosedOpp = New List<Opportunity>();
        Set<Id> AccOppId = new  Set<Id>();
        ClosedOpp=[select id,AccountId,name from Opportunity where StageName ='7 Closed Won'];
    
        for(Opportunity opp :ClosedOpp)
        {
            AccOppId.add(opp.AccountId);
        }
        
        
        fetchAcc = [select id,name,(select id ,name,account__r.Id,is_callhome_on__c from Clusters__r ),(select id,name,AccountID,CloseDate from Opportunities where StageName ='7 Closed Won' )from  Account where id IN : AccOppId];
        
        
        AccountClusterMap = new Map<ID, Account>();
     
       if (fetchAcc.size() > 0)
        {
                for (Account acc :fetchAcc)
                {
                    if(acc.Clusters__r.size() < 1)
                    {
                        AccountClusterMap.put(acc.Id,acc);
                    }
                    
                    for(cluster__C clust :Acc.Clusters__r)
                      {
                            if(clust.is_callhome_on__c == false)
                            {
                                AccountClusterMap.put(acc.Id,acc);
                            }
                        }
                  
                 }
                
            }
 
    }
    
    }