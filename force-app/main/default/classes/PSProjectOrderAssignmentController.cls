public class PSProjectOrderAssignmentController { 
    
    
    //Get Account Records
    @AuraEnabled
    public static List<Order> getOrders(String pageSize, String pageNumber, String projectId){
        //String project2Id =ApexPages.currentPage().getParameters().get('projectId');
        system.debug('projectId--'+projectId);
        list<PS_Project__c> newPsList = new list<PS_Project__c>();
        newPsList = [select ID,Account__c,opportunity__c from PS_Project__c where ID =: projectId LIMIT 1];//update by grazitti
        String accountId;
        String oppoId;
        if(newPsList[0] !=NULL){
            if(newPsList[0].Account__c !=NULL){    
                accountId =  newPsList[0].Account__c;
            }
            if(newPsList[0].opportunity__c !=NULL){
                oppoId = newPsList[0].opportunity__c;
            }
        }  
        
        Integer psize = Integer.valueOf(pageSize);
        Integer pnumber = Integer.valueOf(pageNumber)-1;
        system.debug('psize--'+psize);
        system.debug('pnumber--'+pnumber);
        List<Order> ordersList = [SELECT Id,OrderNumber, AccountId , Account.Name, Ship_To_Name__c, Order_Status__c, PS_Project__r.Name,
                                  PS_Project__C,Opportunityid,Opportunity.Name from Order Where AccountId =: accountId AND Opportunityid =:oppoId AND Order_Status__c IN ('Order Accepted', 'Shipped', 'Activated')
                                  order by createdDate LIMIT :Integer.valueOf(psize) OFFSET :(psize*pnumber)];
        return ordersList;
    }
    
    //Delete Account
    @AuraEnabled
    public static void deleteAccount(Account acc){
        Delete acc;
    } 
    
    @AuraEnabled
    public static List<Account> getAccountsWithOffset(String pageSize, String pageNumber){
        Integer ps = Integer.valueOf(pageSize);
        Integer pn = Integer.valueOf(pageNumber)-1;
        
        List<Account> accounts = [SELECT
                                  Id, Name, Phone, Rating, Industry
                                  FROM Account LIMIT :Integer.valueOf(ps) OFFSET :(ps*pn)];
        return accounts;
    }
    
    @AuraEnabled
    public static void assignOrdersToProject(String projectId, List<String> orderIDs){
        Set<String> orderIdsSet = new Set<String>();
        system.debug('project--'+projectId);
        try {
            system.debug('project--'+projectId);
    
            orderIdsSet.addAll(OrderIds);
            system.debug('orderIdsSet--'+orderIdsSet);
            system.debug('orderIdsSet--'+orderIdsSet.size());
            if(orderIdsSet.isEmpty()) {return;}
            else {
                List<Id> projectIds = new List<Id>();
                //update project on order
                List<Order> orderToUpdateList = new List<Order>();
                for(Order order : [SELECT Id, PS_Project__c FROM Order where ID IN: orderIdsSet]) {
                    projectIds.add(order.PS_Project__c);
                    order.PS_Project__c = projectId;
                    orderToUpdateList.add(order);
                }
                system.debug('orderToUpdateList--'+orderToUpdateList.size());
                if(!orderToUpdateList.isEmpty()) {update orderToUpdateList;}
               
                
                //update project on task
                if(!projectIds.isEmpty()) {
                    List<PS_Task__c> psTaskToUpdateList = new List<PS_Task__c>();
                    for(PS_Task__c task : [SELECT Id, Project__c FROM PS_Task__c WHERE Project__c IN: projectIds]) {
                        task.Project__c = projectId;
                        psTaskToUpdateList.add(task);
                    }
                    system.debug('psTaskToUpdateList--'+psTaskToUpdateList.size());
                    if(!psTaskToUpdateList.isEmpty()) {
                        update psTaskToUpdateList;
                    }
                }
            }
        }
        catch(Exception e) {
            // Utils_Methods.writeErrorLog(e, 'CreateMassBadgeValidityRangesController.searchBadges');
            // System.debug('Error occured while creating Badge Validity Ranges from Mass Creation Tool - CreateMassBadgeValidityRangesController class : ' + e.getStackTraceString() );
        }
    }
    
}