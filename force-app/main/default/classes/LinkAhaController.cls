/**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below class is used to Link,Unlink the Opportunity or Case with the Salesforce Idea.
    * @TestClass    :   LinkAhaController_Test
    */

public without sharing class LinkAhaController{

    public class SearchResult {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Type { get; set; }
        @AuraEnabled
        public String Status { get; set; }
        @AuraEnabled
        public String Subject { get; set; }
        @AuraEnabled
        public String AccountId { get; set; }
    }

    /**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below method is used to show the opportunity or case which is linked with the Aha Idea Record.
    */

    @AuraEnabled(cacheable=true)
    public static List<SearchResult> searchRecords(String searchTerm, Id rcId) {
        List<SearchResult> results = new List<SearchResult>();
        try{
            List<Id> excludeOppsAndCases = new List<Id>();
            //to get the opportunity and case id which is attached on aha idea link.
            for(Aha_Idea_Link__c ahaIdeaLink : [SELECT Id, Aha_Ideas__c, Case_Number__c, Opportunity_Name__c
                                                FROM Aha_Idea_Link__c WHERE Aha_Ideas__c =: rcId]){
                                                    if(String.isNotBlank(ahaIdeaLink.Opportunity_Name__c)){
                                                        excludeOppsAndCases.add(ahaIdeaLink.Opportunity_Name__c );
                                                    }else if(String.isNotBlank(ahaIdeaLink.Case_Number__c)){
                                                        excludeOppsAndCases.add(ahaIdeaLink.Case_Number__c);
                                                    }
                                                }
            if(String.isNotBlank(searchTerm) && String.isNotBlank(rcId)){
                // Search for Opportunities
                List<List<SObject>> searchList = [FIND :searchTerm IN ALL FIELDS
                                                  RETURNING Opportunity(Id, Name, AccountId, StageName
                                                                        WHERE Id NOT IN : excludeOppsAndCases LIMIT 5),
                                                  Case(Id, CaseNumber, AccountId, Status, Subject
                                                       WHERE Id NOT IN : excludeOppsAndCases LIMIT 5)];

                Opportunity[] searchedOpportunity = (Opportunity[]) searchList[0];
                Case[] searchedCases = (Case[]) searchList[1];
                for(Opportunity opp : searchedOpportunity){
                    if(!excludeOppsAndCases.contains(opp.id)){
                        SearchResult result = new SearchResult();
                        result.Id = opp.Id;
                        result.Name = opp.Name;
                        result.Type = 'Opportunity';
                        result.Status = opp.StageName;
                        result.Subject ='';
                        result.AccountId = opp.AccountId;
                        results.add(result);
                    }
                }

                for (Case cas : searchedCases) {
                    if(!excludeOppsAndCases.contains(cas.id)){
                        SearchResult result = new SearchResult();
                        result.Id = cas.Id;
                        result.Name = cas.CaseNumber;
                        result.Type = 'Case';
                        result.Status = cas.Status;
                        result.Subject = cas.Subject;
                        result.AccountId = cas.AccountId;
                        results.add(result);
                    }
                }
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            throw new AuraHandledException(errorMessage);
        }
        return results;
    }

/*
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below method is used to link the opportunity/case with the Idea Record.
*/

    @AuraEnabled
    public static void linkAhaIdeaRecord(Id rcId, Map<String,String> objectRecordIdAndAccountId){
        try{
            Aha_Ideas__c ahaIdeaRecord = new Aha_Ideas__c();
            Map<Id,Aha_Ideas__c> updateAhaIdeaMap = new Map<Id,Aha_Ideas__c>();
            Map<String,Aha_Idea_Link__c> ahaIdeaLinkRecord = new Map<String,Aha_Idea_Link__c>();
            List<Aha_Idea_Link__c> listAIL = new List<Aha_Idea_Link__c>();
            Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
            Set<Id> opptyIds = new Set<Id>();
            Set<Id> caseIds = new Set<Id>();
            Set<Id> accIds = new Set<Id>();
            Integer totalNoOfCases = 0;
            Integer totalNoOfOpportunities = 0;
            Integer countOfAccountStrategic = 0;
            Integer noofcustomerRequested  = 0;
            String linkOfCasesAttachedWithIdea = '';
            String linkOfOpportunitiesAttachedWithIdea = '';
            String currentUserEmail = '';
            List<String> impactCustomers = new List<String>();
            Set<String> accPreferenceValue = new Set<String>();
            List<String>listOfAccPref = new List<String>();
            Set<Id> ahaParentIdeaId = new Set<Id>();
            Set<Id> childAhaIdeaId = new Set<Id>();
            Decimal amountforClosedWonOppty = 0;
            Decimal amountforClosedLostOppty = 0;
            Decimal amountforInflightOppty = 0;

            if(rcId!= null){
                ahaIdeaRecord = getAhaRecord(rcId);
            }
            childAhaIdeaId.add(ahaIdeaRecord.Id);
            if(ahaIdeaRecord.Aha_Unique_ID__c!= null){
                ahaIdeaLinkRecord = getAhaIdeaLinkObjectIdandRecord(ahaIdeaRecord.Aha_Unique_ID__c);
            }

            if(ahaIdeaRecord.Duplicate_of__c!= null){
                ahaParentIdeaId.add(ahaIdeaRecord.Duplicate_of__c);
            }

            if(!objectRecordIdAndAccountId.isEmpty()){
                for(String objId : objectRecordIdAndAccountId.keySet()){
                    if(ahaIdeaLinkRecord.isEmpty() || !ahaIdeaLinkRecord.containsKey(objId)){
                        if(objId.startswith('006')){
                            opptyIds.add(objId);
                        }
                        else{
                            caseIds.add(objId);
                        }
                    }
                }
            }
            if(opptyIds.Size() > 0){
                for(Opportunity opp : [Select id,name,iswon,isclosed,AccountId,ACV_Amount__c from Opportunity where Id IN : opptyIds]){
                    Aha_Idea_Link__c insertIdeaLink = new Aha_Idea_Link__c();
                    insertIdeaLink.Aha_Ideas__c = rcId;
                    insertIdeaLink.Opportunity_Name__c = opp.id;
                    listAIL.add(insertIdeaLink);
                    totalNoOfOpportunities++;
                    if(totalNoOfOpportunities<6){
                        linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.Id+ '\\">'+opp.Name+'</a> ; ';
                    }
                    if(opp.AccountId!= null){
                        accIds.add(opp.AccountId);
                    }
                    if(opp.iswon && opp.ACV_Amount__c!= null){
                        amountforClosedWonOppty += opp.ACV_Amount__c;
                    }
                    else if(opp.isclosed && opp.ACV_Amount__c!= null){
                        amountforClosedLostOppty += opp.ACV_Amount__c;
                    }
                    else if(!opp.isclosed && !opp.iswon && opp.ACV_Amount__c!= null){
                        amountforInflightOppty += opp.ACV_Amount__c;
                    }
                }
            }
            if(caseIds.Size() > 0){
                for(Case cc : [Select id,CaseNumber,AccountId from Case where Id IN : caseIds]){
                    Aha_Idea_Link__c insertIdeaLink = new Aha_Idea_Link__c();
                    insertIdeaLink.Aha_Ideas__c = rcId;
                    insertIdeaLink.Case_Number__c = cc.id;
                    listAIL.add(insertIdeaLink);
                    totalNoOfCases++;
                    if(totalNoOfCases<6){
                        linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() +
                            '/' + cc.Id+ '\\">'+cc.CaseNumber+'</a> ; ';
                    }
                    if(cc.AccountId!= null){
                        accIds.add(cc.AccountId);
                    }
                }
            }

            if(!ahaIdeaLinkRecord.isEmpty()){
                for(Aha_Idea_Link__c linklist : ahaIdeaLinkRecord.values()){
                    if(linklist.Opportunity_Name__c!= null){
                        totalNoOfOpportunities++;
                        if(totalNoOfOpportunities<6){
                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea + '<br/>'+'<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + linklist.Opportunity_Name__c+ '\\">'+linklist.Opportunity_Name__r.Name+'</a>';
                            //linkOfOpportunitiesAttachedWithIdea += '<br/>';
                        }
                        if(linklist.Opportunity_Name__r.Accountid!= null){
                            accIds.add(linklist.Opportunity_Name__r.Accountid);
                        }
                        if(linklist.Opportunity_Name__r.iswon && linklist.Opportunity_Name__r.ACV_Amount__c!= null){
                            amountforClosedWonOppty += linklist.Opportunity_Name__r.ACV_Amount__c;
                        }
                        else if(linklist.Opportunity_Name__r.isclosed && linklist.Opportunity_Name__r.ACV_Amount__c!= null){
                            amountforClosedLostOppty += linklist.Opportunity_Name__r.ACV_Amount__c;
                        }
                        else if(!linklist.Opportunity_Name__r.isclosed && !linklist.Opportunity_Name__r.iswon && linklist.Opportunity_Name__r.ACV_Amount__c!= null){
                            amountforInflightOppty += linklist.Opportunity_Name__r.ACV_Amount__c;
                        }
                    }
                    else if(linklist.Case_Number__c!= null){
                        totalNoOfCases++;
                        if(totalNoOfCases<6){
                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<br/>'+ '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() +
                                '/' + linklist.Case_Number__c+ '\\">'+linklist.Case_Number__r.CaseNumber+'</a>';
                        }
                        if(linklist.Case_Number__r.Accountid!= null){
                            accIds.add(linklist.Case_Number__r.Accountid);
                        }
                    }
                }
            }
            if(accIds.size() > 0){
                for(Account acc : [Select id,name,Strategic_Account__c,Account_Preference__c FROM Account WHERE Id IN : accIds ]){
                    impactCustomers.add(acc.Name);
                    noofcustomerRequested++;
                    if(acc.Strategic_Account__c == True){
                        countOfAccountStrategic++;
                    }
                    if(acc.Account_Preference__c!= null){
                        for(String Account_Preference : acc.Account_Preference__c.split(';')){
                            accPreferenceValue.add(Account_Preference);
                        }
                    }
                }

            }
            if(ahaIdeaRecord.id!= null){
                ahaIdeaRecord.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                ahaIdeaRecord.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                ahaIdeaRecord.Strategic_Major_Account__c = countOfAccountStrategic;
                ahaIdeaRecord.Total_Amount_for_the_Closed_Won_Oppty__c =  String.valueOf(amountforClosedWonOppty);
                ahaIdeaRecord.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueOf(amountforClosedLostOppty);
                ahaIdeaRecord.Total_Amount_for_the_In_Flight_Oppty__c  =  String.valueOf(amountforInflightOppty);

                if(impactCustomers.size()>0){
                    ahaIdeaRecord.Impacted_Customers__c = String.join(impactCustomers,',');
                }
                else{
                    ahaIdeaRecord.Impacted_Customers__c = '';
                }
                if(accPreferenceValue.size()>0){
                    ahaIdeaRecord.Account_Preference__c = String.join(accPreferenceValue,';');
                    listOfAccPref = new List<String>(accPreferenceValue);
                }
                else{
                    ahaIdeaRecord.Account_Preference__c = '';
                }

                ManageAhaIdeaHelper.updateIdeaRecordInAha(ahaIdeaRecord,ahaIdeaRecord.Impacted_Customers__c,noofcustomerRequested,currentUserEmail,countOfAccountStrategic,totalNoOfCases,linkOfCasesAttachedWithIdea,totalNoOfOpportunities,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);

                updateAhaIdeaMap.put(ahaIdeaRecord.id,ahaIdeaRecord);
            }
            if(!updateAhaIdeaMap.isEmpty()){
                UPDATE updateAhaIdeaMap.values();
            }
            if(listAIL.size() > 0){
                INSERT listAIL;
            }
            if(ChildAhaIdeaId.size()>0){
                for(Aha_Ideas__c ai : [SELECT Id,Duplicate_of__c FROM Aha_Ideas__c WHERE Duplicate_of__c IN : ChildAhaIdeaId]){
                    ahaParentIdeaId.add(ai.Duplicate_of__c);
                }
            }
            //Update Parent Aha Idea in Salesforce or Aha
            if(ahaParentIdeaId.size() > 0){
                AhaWebhookReceiver.updateLinkedRelatedRecord(ahaParentIdeaId);
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            // Optionally, perform additional error handling or logging
            throw new AuraHandledException(errorMessage);
        }
    }//End of Method

/**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below method is used to get the opportunity and case id which is attached on aha idea link.
*/
    @AuraEnabled
    public static List<SearchResult> getOpptyandCaseRecords(Id rcId){
        Set<Id> opptyIds = new Set<Id>();
        Set<Id> caseIds = new  Set<Id>();
        List<SearchResult> results = new List<SearchResult>();
        try{
            if(!String.isblank(rcId)){
                for(Aha_Idea_Link__c ahaIdeaLink : [SELECT Id, Aha_Ideas__c, Case_Number__c,Opportunity_Name__c
                                                    FROM Aha_Idea_Link__c
                                                    WHERE Aha_Ideas__c =: rcId]){
                                                        if(String.isNotBlank(ahaIdeaLink.Opportunity_Name__c)){
                                                            opptyIds.add(ahaIdeaLink.Opportunity_Name__c );
                                                        }else if(String.isNotBlank(ahaIdeaLink.Case_Number__c)){
                                                            caseIds.add(ahaIdeaLink.Case_Number__c);
                                                        }
                                                    }
            }

            if(opptyIds!= null){
                for(Opportunity opp : [SELECT Id, Name, StageName, AccountId, Account.Name FROM Opportunity
                                       WHERE Id IN :opptyIds]){
                                           SearchResult result = new SearchResult();
                                           result.Id = opp.Id;
                                           result.Name = opp.Name;
                                           result.Type = 'Opportunity';
                                           result.Status = opp.StageName;
                                           result.Subject ='';
                                           result.AccountId = opp.AccountId;
                                           results.add(result);
                                       }
            }
            if(caseIds!= null){
                for(Case cas : [SELECT Id, CaseNumber, Status, Subject, AccountId, Account.Name FROM Case
                                WHERE Id IN :caseIds]){
                                    SearchResult result = new SearchResult();
                                    result.Id = cas.Id;
                                    result.Name = cas.CaseNumber;
                                    result.Type = 'Case';
                                    result.Status = cas.Status;
                                    result.Subject =cas.Subject;
                                    result.AccountId = cas.AccountId;
                                    results.add(result);
                                }
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            // Optionally, perform additional error handling or logging
            throw new AuraHandledException(errorMessage);
        }
        return results;
    }

 /**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below method is used to get the idea record.
*/
    public static Aha_Ideas__c getAhaRecord(String ahaIdeaRecordId){
        Aha_Ideas__c ahaIdeaRecord = new Aha_Ideas__c();
        try{
            if(!String.isBlank(ahaIdeaRecordId)){
                List<Aha_Ideas__c> ahaRecordList =  new List<Aha_Ideas__c>();
                if(!String.isBlank(ahaIdeaRecordId)){
                    ahaRecordList = [Select id,Aha_Unique_ID__c,Duplicate_of__c FROM Aha_Ideas__c where Id =: ahaIdeaRecordId limit 1];
                    if(ahaRecordList.size()>0){
                        ahaIdeaRecord = ahaRecordList[0];
                    }
                }
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            throw new AuraHandledException(errorMessage);
        }
        return ahaIdeaRecord;
    }

  /**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below method is used to get the get Account Details.
*/
    public static Map<Id,Account> getAccountDetails(Set<String> accIds){
        Map<Id,Account> accountMap = new Map<Id,Account>();
        try{
            if(accIds!= null){
                for(Account aa : [SELECT Id,name,Strategic_Account__c FROM Account WHERE Id IN : accIds]){
                    accountMap.put(aa.Id,aa);
                }
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            throw new AuraHandledException(errorMessage);
        }
        return accountMap;
    }

  /**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Get Aha Idea Link Record related to the Aha Id .
*/
    public static Map<String,Aha_Idea_Link__c> getAhaIdeaLinkObjectIdandRecord(String ahaIdeaUniqueId){
        Map<String,Aha_Idea_Link__c> ideaLinkObjectIdAndRecord = new Map<String,Aha_Idea_Link__c>();
        try{
            if(!String.isblank(ahaIdeaUniqueId)){
                for(Aha_Idea_Link__c ahaIdealink : [Select id,name,Case_Number__c,Case_Number__r.AccountId,Case_Number__r.CaseNumber,Opportunity_Name__c,Opportunity_Name__r.AccountId,Opportunity_Name__r.Name,Account_Name__c,Opportunity_Name__r.iswon,Opportunity_Name__r.isclosed,Opportunity_Name__r.ACV_Amount__c,Aha_Ideas__c,
                                                    Aha_Ideas__r.Aha_Unique_ID__c from Aha_Idea_Link__c where Aha_Ideas__r.Aha_Unique_ID__c =: ahaIdeaUniqueId]){
                                                        if(ahaIdealink.Opportunity_Name__c!= null){
                                                            ideaLinkObjectIdAndRecord.put(ahaIdealink.Opportunity_Name__c,ahaIdealink);
                                                        }
                                                        else{
                                                            ideaLinkObjectIdAndRecord.put(ahaIdealink.Case_Number__c,ahaIdealink);
                                                        }
                                                    }
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            throw new AuraHandledException(errorMessage);
        }
        return ideaLinkObjectIdAndRecord;
    }

  /**
    * @Author       :   Grazitti
    * @CreatedDate  :   27/6/2023
    * @Description  :   Below method is used to Unlink the idea with the Opportunity or Case from the Idea Record.
*/

    @AuraEnabled
    public static void unlinkIdeaWithCaseOrOppty(String rcId, List<sobject> recordlist, Map<String,String> objectRecordIdandAccountId){
        try{
            Aha_Ideas__c ahaIdeaRecord = new Aha_Ideas__c();
            String ahaUniqueId = '';
            Map<String,String> ahaIdeaFieldNameandValue = new Map<String,String>();
            Map<String,Aha_Idea_Link__c> ahaIdeaLinkRecord = new Map<String,Aha_Idea_Link__c>();
            Map<Id,Aha_Ideas__c> updateAhaIdeaMap = new Map<Id,Aha_Ideas__c>();
            List<Aha_Idea_Link__c> deleteAha_IdeaLink_Record = new List<Aha_Idea_Link__c>();
            Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
            Set<Id> accIds = new Set<Id>();
            Integer totalNoOfCases = 0;
            Integer totalNoOfOpportunities = 0;
            Integer countOfAccountStrategic = 0;
            Integer noofcustomerRequested  = 0;
            String linkOfCasesAttachedWithIdea = '';
            String linkOfOpportunitiesAttachedWithIdea = '';
            String currentUserEmail = '';
            List<String> impactCustomers = new List<String>();
            Set<String> accPreferenceValue = new Set<String>();
            Set<Id> childAhaIdeaId = new Set<Id>();
            List<String>listOfAccPref = new List<String>();
            Set<Id> ahaParentIdeaId = new Set<Id>();
            Decimal amountforClosedWonOppty = 0;
            Decimal amountforClosedLostOppty = 0;
            Decimal amountforInflightOppty = 0;
            if(rcId!= null && recordlist.size()>0){
                ahaIdeaRecord = getAhaRecord(rcId);
                if(ahaIdeaRecord!= null){
                    //Below line get the idea record through Api's
                    Map<String, Object> apiResponseMap = ManageAhaIdeaHelper.getAhaIdeaRecordData(ahaIdeaRecord.Aha_Unique_ID__c);
                    for(String apiResponseString : apiResponseMap.keyset()){
                        object obj = apiResponseMap.get(apiResponseString);
                        Map<String, Object> objectMap = (Map<String, Object>)obj;
                        AhaUniqueID = (String) objectMap.get('reference_num');
                    } // End of for loop for getting the record through API
                }
            }// End of if
            childAhaIdeaId.add(ahaIdeaRecord.Id);
            if(ahaIdeaRecord.Duplicate_of__c!= null){
                ahaParentIdeaId.add(ahaIdeaRecord.Duplicate_of__c);
            }

            //get all the idea link record with Respect to the Idea
            if(!String.isblank(ahaUniqueID)){
                ahaIdeaLinkRecord = getAhaIdeaLinkObjectIdandRecord(ahaUniqueId);
            }

            if(!objectRecordIdandAccountId.isEmpty()){
                for(String objectId : objectRecordIdandAccountId.keySet()){
                    if(!ahaIdeaLinkRecord.isEmpty() && ahaIdeaLinkRecord.containsKey(objectId)){
                        deleteAha_IdeaLink_Record.add(ahaIdeaLinkRecord.get(objectId));
                        ahaIdeaLinkRecord.remove(objectId);
                    }
                }
            }

            if(!ahaIdeaLinkRecord.isEmpty()){
                for(Aha_Idea_Link__c linklist : ahaIdeaLinkRecord.values()){
                    if(linklist.Opportunity_Name__c!= null){
                        totalNoOfOpportunities++;
                        if(totalNoOfOpportunities<6){
                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea +'<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + linklist.Opportunity_Name__c+ '\\">'+ linklist.Opportunity_Name__r.Name+'</a> ; ';
                        }
                        if(linklist.Opportunity_Name__r.Accountid!= null){
                            accIds.add(linklist.Opportunity_Name__r.Accountid);
                        }
                        if(linklist.Opportunity_Name__r.iswon && linklist.Opportunity_Name__r.ACV_Amount__c!= null){
                            amountforClosedWonOppty += linklist.Opportunity_Name__r.ACV_Amount__c;
                        }
                        else if(linklist.Opportunity_Name__r.isclosed && linklist.Opportunity_Name__r.ACV_Amount__c!= null){
                            amountforClosedLostOppty += linklist.Opportunity_Name__r.ACV_Amount__c;
                        }
                        else if(!linklist.Opportunity_Name__r.isclosed && !linklist.Opportunity_Name__r.iswon && linklist.Opportunity_Name__r.ACV_Amount__c!= null){
                            amountforInflightOppty += linklist.Opportunity_Name__r.ACV_Amount__c;
                        }
                    }
                    else if(linklist.Case_Number__c!= null){
                        totalNoOfCases++;
                        if(totalNoOfCases<6){
                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() +
                                '/' + linklist.Case_Number__c+ '\\">'+linklist.Case_Number__r.CaseNumber+'</a> ; ';
                            linkOfCasesAttachedWithIdea += '<br/>';
                        }
                        if(linklist.Case_Number__r.Accountid!= null){
                            accIds.add(linklist.Case_Number__r.Accountid);
                        }
                    }
                }

                if(accIds.size() > 0){
                    for(Account acc : [Select id,name,Strategic_Account__c,Account_Preference__c FROM Account WHERE Id IN : accIds]){
                        impactCustomers.add(acc.Name);
                        noofcustomerRequested++;
                        if(acc.Strategic_Account__c == True){
                            countOfAccountStrategic++;
                        }
                        if(acc.Account_Preference__c!= null){
                            for(String Account_Preference : acc.Account_Preference__c.split(';')){
                                accPreferenceValue.add(Account_Preference);
                            }
                        }
                    }
                }
                ahaIdeaRecord.Total_Amount_for_the_Closed_Won_Oppty__c =  String.valueOf(amountforClosedWonOppty);
                ahaIdeaRecord.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueOf(amountforClosedLostOppty);
                ahaIdeaRecord.Total_Amount_for_the_In_Flight_Oppty__c =   String.valueOf(amountforInflightOppty);
                ahaIdeaRecord.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                ahaIdeaRecord.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                ahaIdeaRecord.Strategic_Major_Account__c = countOfAccountStrategic;
                if(impactCustomers.size()>0){
                    ahaIdeaRecord.Impacted_Customers__c = String.join(impactCustomers,',');
                }
                else{
                    ahaIdeaRecord.Impacted_Customers__c = '';
                }
                if(accPreferenceValue.size()>0){
                    ahaIdeaRecord.Account_Preference__c = String.join(accPreferenceValue,';');
                    listOfAccPref = new List<String>(accPreferenceValue);
                }
                else{
                    ahaIdeaRecord.Account_Preference__c = '';
                }
            }
            else{
                ahaIdeaRecord.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                ahaIdeaRecord.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                ahaIdeaRecord.Strategic_Major_Account__c = countOfAccountStrategic;
                ahaIdeaRecord.Impacted_Customers__c = '';
                ahaIdeaRecord.Account_Preference__c = '';
            }

            if(ahaIdeaRecord.Id!= null){
                // Make Callout to update Aha Idea in Aha
                ManageAhaIdeaHelper.updateIdeaRecordInAha(ahaIdeaRecord,ahaIdeaRecord.Impacted_Customers__c,noofcustomerRequested,currentUserEmail,countOfAccountStrategic,totalNoOfCases,linkOfCasesAttachedWithIdea,totalNoOfOpportunities,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);
                // update Idea in Salesforce
                updateAhaIdeaMap.put(ahaIdeaRecord.id,ahaIdeaRecord);
            }
            if(!updateAhaIdeaMap.isEmpty()){
                UPDATE updateAhaIdeaMap.values();
            }
            if(deleteAha_IdeaLink_Record.size()>0){
                DELETE deleteAha_IdeaLink_Record;
            }
            if(ChildAhaIdeaId.size()>0){
                for(Aha_Ideas__c ai : [SELECT Id,Duplicate_of__c FROM Aha_Ideas__c WHERE Duplicate_of__c IN : ChildAhaIdeaId]){
                    ahaParentIdeaId.add(ai.Duplicate_of__c);
                }
            }
            //Update Parent Aha Idea in Salesforce or Aha
            if(ahaParentIdeaId.size()>0){
                AhaWebhookReceiver.updateLinkedRelatedRecord(ahaParentIdeaId);
            }
        }
        catch (exception e){
            String errorMessage = e.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    } // End of Method
}