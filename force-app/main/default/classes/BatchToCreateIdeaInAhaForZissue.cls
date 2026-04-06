/**
* @Author       :   Grazitti Interactive
* @CreatedDate  :   4/Sep/2023
* @Jira Ticket  :   AS-19 - Jira Migration
* @Description  :   Below Batch class is used to Create a Aha Idea in SFDC and in Aha through Migration of Zissue.
* @TestClass    :   JiraCSVUploadControllerTest
*/

global class BatchToCreateIdeaInAhaForZissue implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts {

    Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
    private Map<String,Set<String>> jiraNumberVsCaseNumbers = new Map<String,Set<String>>();
    private Map<String,Set<String>> zissuewhereAhaRecordfound = new Map<String,Set<String>>();
    private Map<String,Set<String>> zissuewhereAhaRecordNotfound = new Map<String,Set<String>>();
    public Set<String> setRecordIds = new Set<String>();
    String csvColumnHeader = 'Zissue Id, CaseId, Status\n';
    List<String> csvRowValues = new List<String>();
    public class IdeaFields {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String product_id { get; set; }
        @AuraEnabled public String visibility { get; set; }
        @AuraEnabled public String created_by { get; set; }
        @AuraEnabled public CustomFields custom_fields { get; set; }
    }
    // Below Wrapper used to store the custom field value of the Aha Idea.
    public class CustomFields {

        @AuraEnabled public Integer strategicmajor_account{ get; set; }
        @AuraEnabled public String number_of_customers_requested { get; set; }
        @AuraEnabled public String other_impacted_customers { get; set; }
        @AuraEnabled public String account_preference { get; set; }
        @AuraEnabled public Integer total_no_of_cases_link_with_idea { get; set; }
        @AuraEnabled public String links_of_cases_attached_with_idea { get; set; }
        @AuraEnabled public String zsfjira_components { get; set; }
        @AuraEnabled public String rfe_link { get; set; }

    }

    public class InsertIdeaandLinkRecords{
        @AuraEnabled public Aha_Ideas__c sfdcidea { get; set; }
        @AuraEnabled public Map<String,Set<String>> AhaIdAndSetCaseids { get; set; }
        @AuraEnabled public Map<String,zsfjira__ZIssue__c> ZissueRec { get; set; }
    }


    public BatchToCreateIdeaInAhaForZissue(Map<string,Set<String>> jiraNumberVsCaseNumbersParams,Map<string,Set<String>> noRecordFoundofZissueinAha,Map<string,Set<String>> RecordFoundofZissueinAha) {
        jiraNumberVsCaseNumbers = jiraNumberVsCaseNumbersParams;
        setRecordIds = jiraNumberVsCaseNumbersParams.keySet();
        zissuewhereAhaRecordfound = RecordFoundofZissueinAha;
        zissuewhereAhaRecordNotfound = noRecordFoundofZissueinAha;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Name,Aha_Unique_Id__c,zsfjira__Status__c,zsfjira__Project__c,zsfjira__IssueType__c,zsfjira__Summary__c,zsfjira__Description__c,zsfjira__IssueKey__c,zsfjira__IssueId__c,zsfjira__Components__c FROM zsfjira__ZIssue__c WHERE Name IN : setRecordIds';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<zsfjira__ZIssue__c> scope){
        List<Aha_Idea_Link__c> ideaLinkInsertList = new List<Aha_Idea_Link__c>();
        List<zsfjira__ZIssue__c> updateZissue = new List<zsfjira__ZIssue__c>();
        Map<String,Case> caseMap = new Map<String,Case>();
        Map<Id,Account> accMap = new Map<Id,Account>();
        Set<String>caseNumberSet = new Set<String>();
        Set<Id>accountIdSet = new Set<Id>();
        Set<Id> zissueid = new Set<Id>();
        String currentZissueid = '';
        List<InsertIdeaandLinkRecords> createIdeaAndLinkRecords = new List<InsertIdeaandLinkRecords>();
        Map<String,Set<String>> zsfjiraAndCaseMap = new Map<String,Set<String>>();
        try{

            for(zsfjira__ZIssue__c zissue : scope){
                 zissueid.add(zissue.Id);
            }

            if(zissueid.Size() > 0){
                for(zsfjira__ZIssue_Case__c zsfjira : [Select id,zsfjira__CaseId__c,zsfjira__CaseId__r.CaseNumber,zsfjira__ZIssueId__c,zsfjira__ZIssueId__r.Name from zsfjira__ZIssue_Case__c where zsfjira__ZIssueId__c IN : zissueid]){

                    if(zsfjiraAndCaseMap.isEmpty() || !zsfjiraAndCaseMap.containsKey(zsfjira.zsfjira__ZIssueId__c)){
                       zsfjiraAndCaseMap.put(zsfjira.zsfjira__ZIssueId__c, new Set<String>{zsfjira.zsfjira__CaseId__r.CaseNumber});
                    }
                    else{
                        zsfjiraAndCaseMap.get(zsfjira.zsfjira__ZIssueId__c).add(zsfjira.zsfjira__CaseId__r.CaseNumber);
                    }
                }
            }

            for(zsfjira__ZIssue__c zissue : scope){
                currentZissueid = zissue.name;
                Set<String>cseNumberList = new Set<String>();
                if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containsKey(zissue.name)){
                    cseNumberList = jiraNumberVsCaseNumbers.get(zissue.Name);
                }
                if(cseNumberList.Size() > 0){
                    for(String csNum : cseNumberList){
                        String casenum = csNum.trim();
                        caseNumberSet.add(casenum );
                    }
                }
                if(!zsfjiraAndCaseMap.isEmpty() && zsfjiraAndCaseMap.containskey(zissue.id)){
                    Set<String> caseids = zsfjiraAndCaseMap.get(zissue.id);
                    if(caseids.size() > 0){
                        for(String cseNum : caseids){
                            caseNumberSet.add(cseNum);
                        }
                    }
                }
            }
            if(caseNumberSet.size() > 0){
                for(Case cc : [Select id,CaseNumber,AccountId from Case where CaseNumber IN : caseNumberSet]){
                    caseMap.put(cc.CaseNumber,cc);
                    accountIdSet.add(cc.AccountId);
                }
            }

            if(accountIdSet.Size() > 0){
                for(Account acc : [Select id,name,Account_Preference__c,Strategic_Account__c from Account where Id IN : accountIdSet]){
                    accMap.put(acc.Id,acc);
                }
            }

            for(zsfjira__ZIssue__c zissue : scope){
                currentZissueid = zissue.name;
                Aha_Ideas__c ahaIdea = New Aha_Ideas__c();
                Integer totalnoofcases = 0;
                String linkOfCasesAttachedWithIdea = '';
                Set<Id> caserelatedAccId = new Set<Id>();
                List<String> impactCustomers = new List<String>();
                Set<String> accPreferenceValue = new Set<String>();
                List<String>listOfAccPref = new List<String>();
                Set<String> cseNumberList = new Set<String>();
                Integer noofcustomerRequested  = 0;
                Integer strategic_Account_value = 0;

                if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containsKey(zissue.name)){
                    for(String cseno : jiraNumberVsCaseNumbers.get(zissue.name)){
                        cseNumberList.add(cseno.trim());
                    }
                }
                if(cseNumberList.Size() >= 0){
                    for(String csNumber : cseNumberList){
                        String cseNumber = csNumber.trim();
                        if(!caseMap.isEmpty() && caseMap.containsKey(cseNumber)){
                            Case cc = caseMap.get(cseNumber);
                            caserelatedAccId.add(cc.AccountId);
                            totalnoofcases++;
                            if(totalnoofcases<=5){
                                linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+Url.getOrgDomainURL().toExternalForm() + '/' + cc.Id + '\\">'+ cc.CaseNumber +'</a> ; ';
                            }
                        }
                    }
                }

                if(caserelatedAccId.Size() > 0){
                    for(Id accids : caserelatedAccId){
                        if(!accMap.isEmpty() && accMap.containskey(accids)){
                            Account aa = accMap.get(accids);
                            impactCustomers.add(aa.name);
                            noofcustomerRequested++;
                            if(aa.Account_Preference__c!= null){
                                for(String Account_Preference : aa.Account_Preference__c.split(';')){
                                    accPreferenceValue.add(Account_Preference);
                                }
                            }
                            if(aa.Strategic_Account__c){
                                strategic_Account_value++;
                            }
                        }
                    }
                }


                Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
                String customerRequested = String.valueof(noofCustomerRequested);
                String accPrefVal = '';
                String AccountName = '';
                String rfe_link = Label.Jira_Base_Url+ zissue.name;
                if(impactCustomers.size()>0){
                    AccountName = String.join(impactCustomers,',');
                }
                if(accPreferenceValue.Size() > 0){
                    accPrefVal = String.join(accPreferenceValue,',');
                }

                IdeaFields idea_fields = new IdeaFields();
                idea_fields.created_by = UserInfo.getUserEmail();
                idea_fields.visibility = 'public';
                // CS21-2200: Fix the Batch migration of the Jira RFEs to use the Jira summary to Idea's Name, instead of Jira number to Idea.name
                idea_fields.name = zissue.zsfjira__Summary__c;
                idea_fields.product_id = ahaCredential.aha_ProductID__c;
                idea_fields.description = zissue.zsfjira__Description__c;

                CustomFields customFields = new CustomFields();
                customFields.strategicmajor_account = Strategic_Account_value;
                customFields.other_impacted_customers = AccountName;
                customFields.number_of_customers_requested = customerRequested;
                customFields.account_preference = accPrefVal;
                customFields.total_no_of_cases_link_with_idea = totalNoOfCases;
                customFields.links_of_cases_attached_with_idea = linkOfCasesAttachedWithIdea;
                customFields.rfe_link = rfe_link;
                customFields.zsfjira_components = zissue.zsfjira__Components__c;
                idea_fields.custom_fields = customFields;

                String jsonString = JSON.serialize(idea_fields);
                String jsonStringfinal  = '{"idea":' + jsonString + '}';
                HttpRequest req = new HttpRequest();
                req.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/products/' + ahaCredential.Aha_ProductID__c + '/ideas');
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                req.setHeader('contentType', 'application/json');
                req.setHeader('Content-Type','application/json;charset=UTF-8');
                req.setHeader('Accept', 'application/json');
                req.setBody(jsonStringfinal);
                Http httpnew = new Http();
                    List<Object> recordList = New List<Object>();
                    Map<String,Object> recordMap = new Map<String,Object>();
                    HttpResponse response = httpnew.send(req);
                    if(response.getStatusCode() == 200){
                        Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        recordMap = (Map<String,Object>) records.get('idea');
                        if(!recordMap.isEmpty()){
                            ahaIdea.Aha_Unique_ID__c = String.valueof(recordMap.get('reference_num'));
                            ahaIdea.Aha_Idea_Number__c =  String.valueof(recordMap.get('id'));
                             String ZissueSummary =  zissue.zsfjira__Summary__c;
                             ahaIdea.Name = ZissueSummary.length()>= 80 ? ZissueSummary.substring(0,75)+'...':ZissueSummary;

                            if(zissue.zsfjira__IssueType__c!= null && zissue.zsfjira__IssueType__c.containsIgnoreCase('Usability')){
                                ahaIdea.Idea_Category__c = 'Usability';
                            }
                            else if(zissue.zsfjira__IssueType__c!= null && zissue.zsfjira__IssueType__c.containsIgnoreCase('Supportability')){
                                ahaIdea.Idea_Category__c = 'Supportability';
                            }
                            else{
                                ahaIdea.Idea_Category__c = 'New Feature/Feature Enhancement';
                            }

                            if(zissue.zsfjira__Project__c!= null && zissue.zsfjira__Project__c.containsIgnoreCase('CDM')){
                                ahaIdea.For_Workspace__c = 'Data Management Platform';
                            }
                            else if(zissue.zsfjira__Project__c!= null && zissue.zsfjira__Project__c.containsIgnoreCase('SPARK')){
                                ahaIdea.For_Workspace__c = 'Polaris 2.0';
                            }

                            ahaIdea.zsfjira_Components__c = zissue.zsfjira__Components__c;
                            ahaIdea.zIsssue_Number__c = zissue.name;
                            ahaIdea.Total_No_of_Cases_Link_With_Idea__c = totalnoofcases;
                            ahaIdea.Strategic_Major_Account__c = Strategic_Account_value;
                            ahaIdea.Account_Preference__c = accPreferenceValue.Size() > 0 ? String.join(accPreferenceValue,';'): '';
                            ahaIdea.Impacted_Customers__c = AccountName;

                            Map<String,Set<String>> ideaIdandCaseSet = new Map<String,Set<String>>();
                            ideaIdandCaseSet.put(ahaIdea.Aha_Unique_ID__c,cseNumberList);
                            Map<String,zsfjira__ZIssue__c> ideaIdandZissueRec = new Map<String,zsfjira__ZIssue__c>();
                            ideaIdandZissueRec.put(ahaIdea.Aha_Unique_ID__c,zissue);
                            InsertIdeaandLinkRecords insideaandlink = new InsertIdeaandLinkRecords();
                            insideaandlink.sfdcidea = ahaIdea;
                            insideaandlink.AhaIdAndSetCaseids = ideaIdandCaseSet;
                            insideaandlink.ZissueRec = ideaIdandZissueRec;
                            createIdeaAndLinkRecords.add(insideaandlink);
                        }
                    }

            }// End of For Loop

            List<Aha_Ideas__c> createsfdcidea = new List<Aha_Ideas__c>();
            Map<String,String> ahaUniqueIdAndId = new Map<String,String>();
            if(createIdeaAndLinkRecords.size() > 0){
                for(InsertIdeaandLinkRecords rec :  createIdeaAndLinkRecords){
                    createsfdcidea.add(rec.sfdcidea);
                }
            }
            if(createsfdcidea.Size() > 0){
                INSERT createsfdcidea;
            }

            if(createsfdcidea.size() > 0 ){
                for(Aha_Ideas__c idea : createsfdcidea){
                    ahaUniqueIdAndId.put(idea.Aha_Unique_ID__c,idea.id);
                }
            }

            if(createIdeaAndLinkRecords.size() > 0){
                for(InsertIdeaandLinkRecords rec :  createIdeaAndLinkRecords){
                    String AhauniqueId = rec.sfdcidea.Aha_Unique_ID__c;
                    String AhaSfdcId = '';
                    if(!ahaUniqueIdAndId.isEmpty() && ahaUniqueIdAndId.containskey(AhauniqueId)){
                        AhaSfdcId = ahaUniqueIdAndId.get(AhauniqueId);
                    }
                    Map<String,zsfjira__ZIssue__c> AhaIdAndZissueRec = rec.ZissueRec;
                    Map<String,Set<String>> AhaidandCseSet = rec.AhaIdAndSetCaseids;
                    zsfjira__ZIssue__c zissuerec = new zsfjira__ZIssue__c();

                    if(!AhaIdAndZissueRec.isEmpty() && !String.isBlank(AhauniqueId)){
                        zissuerec = AhaIdAndZissueRec.get(AhauniqueId);
                        zissuerec.Aha_Unique_Id__c = AhauniqueId;
                        updateZissue.add(zissuerec);
                    }

                    for(String ahaid : AhaidandCseSet.keySet()){
                        for(String csNumber : AhaidandCseSet.get(ahaid)){
                            String cseNumber = csNumber.trim();
                            csvColumnHeader+= zissuerec.Name + ',' + cseNumber + ',' + 'Success' + '\n';
                                if(!caseMap.isEmpty() && caseMap.containsKey(cseNumber) && !String.isBlank(AhaSfdcId)){
                                    Case cc = caseMap.get(cseNumber);
                                    Aha_Idea_Link__c  insertAhaIdeaLink = new Aha_Idea_Link__c();
                                    insertAhaIdeaLink.Case_Number__c = cc.Id;
                                    insertAhaIdeaLink.Aha_Ideas__c = AhaSfdcId;
                                    ideaLinkInsertList.add(insertAhaIdeaLink);

                                }
                        }
                    }
                }
            }
            if(ideaLinkInsertList.size() > 0){
                INSERT ideaLinkInsertList;
            }

            if(updateZissue.size() > 0){
                UPDATE updateZissue;
            }
        }//End of try
        catch(Exception e){
            if(!String.isBlank(currentZissueid) && !jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containsKey(currentZissueid)){
                for(String cseNumber : jiraNumberVsCaseNumbers.get(currentZissueid)){
                    csvColumnHeader+= currentZissueid + ',' + cseNumber + ',' + 'Exception Occured' + '\n';
                }
            }

        }
    }//End of method

    global void finish(Database.BatchableContext BC){

            if(!zissuewhereAhaRecordfound.isEmpty()){
                for(String zissueid : zissuewhereAhaRecordfound.KeySet()){
                    for(String caseid : zissuewhereAhaRecordfound.get(zissueid)){
                         csvColumnHeader+= zissueid + ',' + caseid + ',' + 'Success' + '\n';
                    }
                }
            }
            if(!zissuewhereAhaRecordNotfound.isEmpty()){
                for(String zissueid : zissuewhereAhaRecordNotfound.KeySet()){
                    for(String caseid : zissuewhereAhaRecordNotfound.get(zissueid)){
                         csvColumnHeader+= zissueid + ',' + caseid + ',' + 'No Record Found In ZIssue related to Id' + '\n';
                    }
                }
            }

            String currentUserEmail = UserInfo.getUserEmail();
            String csvFile = csvColumnHeader;

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment attach1 = new Messaging.EmailFileAttachment();

            blob b;
            if(Test.isRunningTest()) {
                b = blob.valueOf('Unit.Test');
            } else {
                b = Blob.valueOf(csvFile);
            }

            attach1.setFileName('Import File Status of Zissues.csv');
            attach1.setBody(b);
            message.setFileAttachments(new Messaging.EmailFileAttachment[]{attach1});
            String[] toAddresses = new String[] {currentUserEmail};
            message.setToAddresses(toAddresses);
            message.setSubject('Status File of the Import Zissue Records');
            message.setHtmlBody('');
            OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = 'donotreply@rubrik.com' LIMIT 1];
            if ( owea != Null) {
                message.setOrgWideEmailAddressId(owea.Id);
            }
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });

    }
}