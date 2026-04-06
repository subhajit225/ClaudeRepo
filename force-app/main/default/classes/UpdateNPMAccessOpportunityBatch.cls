/**
 * @Author      :  
 * @CreatedDate : 
 * @TstClass    : UpdateNPMAccessOpportunityBatchTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * SAL4-679
 * SAL25-234
 * -------------------------------------------------------------------------
 */
public class UpdateNPMAccessOpportunityBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    String queryStr;
    List<Account_To_Users__c> atuList = new List<Account_To_Users__c>();
    public UpdateNPMAccessOpportunityBatch(String queryStr){
        this.queryStr = queryStr;
    }

    public Database.queryLocator start(Database.BatchableContext batchContext){
        Set<Id> accIdSet = new Set<Id>();
        if(queryStr == null){
            for(Account_To_Users__c atu : [select Id,Account__c,User__c,Old_User__c,Sync_NationalPartnerManager__c from Account_To_Users__c where Sync_NationalPartnerManager__c = TRUE and User__r.IsActive = TRUE and Relationship_Type__c ='National Partner Manager']){
                accIdSet.add(atu.Account__c);
                atuList.add(atu);
            }
        }
        //SAL25-234
        String queryStrStart = 'SELECT Id, Name, Partner_Lookup__c, Sourcing_Partner__c, Teaming_Partner__c, IsClosed ' +
                                ' FROM Opportunity WHERE ' + 
                                //' IsClosed = FALSE AND ' +
                                ' (Partner_Lookup__c in :accIdSet OR ' +
                                ' Sourcing_Partner__c in :accIdSet OR ' +
                                ' Teaming_Partner__c in :accIdSet) ';
        queryStrStart = queryStr != null ? queryStr : queryStrStart;
        return Database.getQueryLocator(queryStrStart); 
    }

    public void execute(Database.BatchableContext batchContext, List<Opportunity> oppList){
        List<OpportunityShare> insertOpptyShareList = new List<OpportunityShare>();
        List<OpportunityShare> deleteOpptyShareList = new List<OpportunityShare>();
        Set<String> delOpptyShareKeyset = new Set<String>();
        Set<Id> delOpptyIdSet = new Set<Id>();
        Set<Id> delUsrIdSet = new Set<Id>();
        Map<Id, Set<Id>> oppNPMAccMap = new Map<Id, Set<Id>>();
        Map<Id,Set<Id>> accToNewNPMMap = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> accToOldNPMMap = new Map<Id,Set<Id>>();
        
        //Create map of OppId to NPM accounts.
        for(Opportunity opp : oppList){
            Set<Id> accSet = new Set<Id>();
            accSet.add(opp.Partner_Lookup__c);
            accSet.add(opp.Sourcing_Partner__c);
            accSet.add(opp.Teaming_Partner__c);
            oppNPMAccMap.put(opp.Id,accSet);
        }

        //Fetch list of NPMs for each account
        for(Account_To_Users__c atu : [select Id,Account__c,User__c,Old_User__c,Sync_NationalPartnerManager__c,Disable_Account_User_Relationship__c from Account_To_Users__c where User__r.IsActive = TRUE and Relationship_Type__c ='National Partner Manager']){
            Set<Id> userSet = new Set<Id>();
            //New user set
            if(accToNewNPMMap.containsKey(atu.Account__c)) userSet = accToNewNPMMap.get(atu.Account__c);
            if(!atu.Disable_Account_User_Relationship__c) userSet.add(atu.User__c);
            accToNewNPMMap.put(atu.Account__c,userSet);
            //Old user set
            userSet = new Set<Id>();
            if(accToOldNPMMap.containsKey(atu.Account__c)) userSet = accToOldNPMMap.get(atu.Account__c);
            userSet.add(atu.Old_User__c);
            if(atu.Disable_Account_User_Relationship__c) userSet.add(atu.User__c);
            accToOldNPMMap.put(atu.Account__c,userSet);
        }

        for(Opportunity opp : oppList){
            Id oppId = opp.Id;
            if(!oppNPMAccMap.isEmpty() && oppNPMAccMap.containsKey(oppId)){
                //create list of insert opportunity share records
                for(Id accId : oppNPMAccMap.get(oppId)){
                    if(!accToNewNPMMap.isEmpty() && accToNewNPMMap.containsKey(accId)){
                        for(Id uId : accToNewNPMMap.get(accId)){
                            insertOpptyShareList.add(new OpportunityShare(
                                                                OpportunityId = oppId, 
                                                                UserOrGroupId = uId, 
                                                                OpportunityAccessLevel = opp.IsClosed ? 'Read' : 'Edit',
                                                                RowCause = Schema.OpportunityShare.RowCause.Manual
                                                            ));
                        }
                    }
                }
                //create list of delete opportunity share records with unique key
                for(Id accId : oppNPMAccMap.get(oppId)){
                    if(!accToOldNPMMap.isEmpty() && accToOldNPMMap.containsKey(accId)){
                        for(Id uId : accToOldNPMMap.get(accId)){
                            delOpptyIdSet.add(oppId);
                            delUsrIdSet.add(uId);
                            delOpptyShareKeyset.add(oppId+'-'+uId);
                        }
                    }
                }
            }
        }

        //fetch existing account share records to be deleted
        for(OpportunityShare ashare : [SELECT Id, OpportunityId, UserOrGroupId 
                                FROM OpportunityShare 
                                WHERE OpportunityId IN :delOpptyIdSet AND UserOrGroupId IN :delUsrIdSet AND RowCause = 'Manual']){
            String delOppShareKey = ashare.OpportunityId + '-' + ashare.UserOrGroupId;
            //map with deleteOpportunityShare unique key and add it delete list
            if(delOpptyShareKeyset.contains(delOppShareKey)) deleteOpptyShareList.add(ashare);
        }
        //delete old manual opportunity share records
        if(!deleteOpptyShareList.isEmpty()){
            List<Database.DeleteResult> drList = Database.delete(deleteOpptyShareList, false);
            LogError.deleteDMLErrorLog((List<SObject>)deleteOpptyShareList, drList, 'UpdateNPMAccessOpportunityBatch','Delete NPM OpportunityShare in batch');
        }
        //insert new manual opportunity share records
        if(!insertOpptyShareList.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(insertOpptyShareList, false);
            LogError.createDMLErrorLog((List<SObject>)insertOpptyShareList, srList, 'UpdateNPMAccessOpportunityBatch','Insert NPM OpportunityShare in batch');
        }
        
    }

    public void finish(Database.BatchableContext batchContext){
        //SAL25-234
        if(queryStr == null){
            for(Account_To_Users__c ATUser : [select Id from Account_To_Users__c where Sync_NationalPartnerManager__c = TRUE and User__r.IsActive = FALSE and Relationship_Type__c ='National Partner Manager']){
                atuList.add(ATUser);
            }
        }
        for(Account_To_Users__c atu :atuList){
            atu.Sync_NationalPartnerManager__c = FALSE;
            atu.Old_User__c = null;
        }
        //SAL25-234
        if(!atuList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(atuList, false);
            LogError.createDMLErrorLog((List<SObject>)atuList, srList, 'UpdateNPMAccessOpportunityBatch','Update AccountToUsers');
        }
    }

    public void execute(SchedulableContext sc){
        Database.executeBatch(new UpdateNPMAccessOpportunityBatch(null),50);
    }
}