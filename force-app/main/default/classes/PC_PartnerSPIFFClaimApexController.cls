public without sharing class PC_PartnerSPIFFClaimApexController {
    @AuraEnabled(cacheable=true)
    public static List<CCR__c> getPartnerSPIFFClaims(String partnerAccountId, String startDate, String endDate, String searchText, List<String> accIds, String status, String incentiveType){
        List<CCR__c> partnerCCRList = new List<CCR__c>();
        String spiffRecordType = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Partner Claim Form').getRecordTypeId();

        User partnerUser = [SELECT ID,Name,Contact.AccountId,Profile.Name
                            FROM User
                            WHERE ID =:partnerAccountId];

        if(partnerUser != null){
            String partnerAccId = partnerUser.Contact.AccountId;
            String partnerUserId = partnerUser.Id;
            String query = 'SELECT Id,Customer_Company__c,Partner_Company_Name__c,User__c,Incentive__r.Name,Deal_Registration_Number__c,Approval_Date__c,Partner_Rep_Name__c,Partner_REP_Amount__c,Partner_SE_Name__c,Partner_SE_Amount__c FROM CCR__c WHERE RecordTypeId =: spiffRecordType AND Incentive__c != null';
            if(!partnerUser.Profile.Name.contains('Community Manager') && accIds.isEmpty()){
                query = query + ' AND CreatedById =: partnerUserId';
            }else if(!partnerUser.Profile.Name.contains('Community Manager') && accIds != null && !accIds.isEmpty()){
                query = query + ' AND CreatedById =: partnerUserId AND Partner_Company_Name__c IN: accIds';
            }
            if(partnerUser.Profile.Name.contains('Community Manager') && accIds != null && !accIds.isEmpty()){
                query = query + ' AND Partner_Company_Name__c IN: accIds';
            }else if(partnerUser.Profile.Name.contains('Community Manager') && accIds.isEmpty()){
                query = query + ' AND Partner_Company_Name__c =: partnerAccId';
            }
            if(!String.isBlank(status)){
                query = query + ' AND User__c =: status';
            }
            if(!String.isBlank(incentiveType)){
                String incentiveToSearch = '%' + incentiveType + '%';
                query = query + ' AND Incentive__r.Name LIKE :incentiveToSearch';
            }
            if(!String.isBlank(startDate)){
                Date startDateConv = Date.valueOf(startDate);
                query = query + ' AND CreatedDate >= :startDateConv';
            }
            if(!String.isBlank(endDate)){
                Date endDateConv = Date.valueOf(endDate);
                query = query + ' AND CreatedDate <= :endDateConv';
            }
            if(!String.isBlank(searchText)){
                String stringToSearch = '%' + searchText + '%';
                query = query + ' AND Customer_Company__c LIKE :stringToSearch';
            }
            query = query + ' ORDER BY createddate DESC';
            System.debug('query'+query);
            partnerCCRList = Database.query(query);
        }
        return partnerCCRList;
    }
}