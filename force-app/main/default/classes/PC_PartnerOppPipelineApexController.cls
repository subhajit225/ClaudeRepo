public without sharing class PC_PartnerOppPipelineApexController {
    @AuraEnabled(cacheable=true)
    public static oppPipelineAllWrapper getPartnerOppPipeline(String partnerAccountId, String startDate, String endDate, String searchText, List<String> accIds, List<String> dealInitiatedType){
        List<Opportunity> parterOppList = new List<Opportunity>();
        String partnerAccId = '';
        String salesRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Opportunity').getRecordTypeId();
        User partnerUser = [SELECT ID,Name,Contact.AccountId,Contact.Account.Channel_Program_Level_Name__c,Contact.Account.ETM_Theatre__c
                            FROM User
                            WHERE ID =:partnerAccountId];

        if(partnerUser != null)
        {
            partnerAccId = partnerUser.Contact.AccountId;
            String query = 'SELECT ID,Name,Account.Name,Account.Owner.Name,Amount,ACV_Amount__c,CloseDate,StageName,Deal_Registration_Number__c,Deal_Registration_Type__c,Opportunity_Type__c,Sourcing_Partner__c,Sourcing_Partner__r.Name,Account.Parent_Tier__c,Partner_Lookup__r.Name FROM Opportunity WHERE RecordTypeId =: salesRecId';//prit25-11
            if(accIds != null && accIds.size() > 0)
            { 
                query = query + ' AND Partner_Lookup__c IN: accIds';
            }
            if(dealInitiatedType != null && dealInitiatedType.size() > 0){
                query = query + ' AND Deal_Registration_Type__c IN : dealInitiatedType';
            }
            if(!String.isBlank(startDate)){
                Date startDateConv = Date.valueOf(startDate);
                query = query + ' AND CloseDate >= :startDateConv';
            }
            if(!String.isBlank(endDate)){
                Date endDateConv = Date.valueOf(endDate);
                query = query + ' AND CloseDate <= :endDateConv';
            }
            if(!String.isBlank(searchText)){
                String stringToSearch = '%' + searchText + '%';
                query = query + ' AND Account.Name LIKE :stringToSearch';
            }

            query = query + ' ORDER BY CloseDate DESC';

            //System.debug('query'+query);
            parterOppList = Database.query(query);
        }
        //System.debug('parterOppList'+parterOppList);
        oppPipelineAllWrapper oppWrap = new oppPipelineAllWrapper();
        oppWrap.oppAllList = parterOppList;
        oppWrap.accountID = partnerAccId;
        oppWrap.partnerAccLevel = partnerUser.Contact.Account.Channel_Program_Level_Name__c;
        oppWrap.partnerAccTheatre = partnerUser.Contact.Account.ETM_Theatre__c;
        return oppWrap;
    }

    @AuraEnabled
    public static oppPipelineWrapper getOpportunityData(){
        List<Opportunity> oppList = new List<Opportunity>();
        oppPipelineWrapper oppWrapper = new oppPipelineWrapper();
        Integer openOppCount = 0;
        Integer closedOppCount = 0;

        try{
            User partnerUser = [SELECT Id, Name, Contact.AccountId, Contact.Primary_Role__c
                                FROM User
                                WHERE Id=:UserInfo.getUserId()];
            Id partnerAccountId = partnerUser != null ? partnerUser.Contact.AccountId : null;

            if(partnerAccountId != null){
                for(Opportunity opp : [SELECT Id, Account.Name, Owner.Name, Owner.Email, Amount, StageName, CloseDate
                                        FROM Opportunity
                                        WHERE Partner_Lookup__c =: partnerAccountId
                                        ORDER BY CloseDate DESC])
                {
                    if(opp.StageName == '7 Closed Won'){
                        closedOppCount = closedOppCount + 1;
                    }else if(opp.StageName != '7 Closed Lost'){
                        openOppCount = openOppCount + 1;
                    }

                    if(opp.StageName != '7 Closed Won' && opp.StageName != '7 Closed Lost' && oppList.size() < 6){
                        oppList.add(opp);
                    }
                }
            }
        }
        catch(Exception e){
            system.debug('error'+ e.getMessage());
        }
        oppWrapper.closedOppCount = closedOppCount;
        oppWrapper.openOppCount = openOppCount;
        oppWrapper.oppList = oppList;
        return oppWrapper;
    }

    public class oppPipelineWrapper{
        @AuraEnabled
        public List<Opportunity> oppList;
        @AuraEnabled
        public Integer closedOppCount;
        @AuraEnabled
        public Integer openOppCount;
    }

    public class oppPipelineAllWrapper{
        @AuraEnabled
        public List<Opportunity> oppAllList;
        @AuraEnabled
        public String accountID;
        @AuraEnabled
        public String partnerAccTheatre;
        @AuraEnabled
        public String partnerAccLevel;
    }
}