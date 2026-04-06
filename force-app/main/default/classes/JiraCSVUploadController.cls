/**
* @Author       :   Grazitti
* @CreatedDate  :   10/11/2023
* @Jira Ticket  :   AS-19 - Jira Migration
* @Description  :   This class is used to Migrate Zissue Records to Aha through Csv File form Migrate zissue to Aha Idea Page.
* @TestClass    :   JiraCSVUploadControllerTest
*/
public class JiraCSVUploadController {
    @AuraEnabled
    public static void processCsvData(List<String> csvLines){
        Set<String> zIssueIdalreadyExsistInAha = New Set<String>();
        Set<Id> AhaIds = New Set<Id>();
        Set<String> noIdeaIdPresentOnZissueSet = New Set<String>();
        Map<String,Set<String>> jiraNumberVsCaseNumbers = New Map<String,Set<String>>();
        Map<String,Set<String>> noIdeaIdPresentOnZissueMap = New Map<String,Set<String>>();
        Map<String,Case> caseMap = new Map<String,Case>();
        Map<Id,Map<String,Aha_Idea_Link__c>> AhaIdandlistofAhaLink = new Map<Id,Map<String,Aha_Idea_Link__c>>();
        Set<String> allCaseNumberList = new Set<String>();
        List<Aha_Ideas__c> ideaList = new List<Aha_Ideas__c>();
        Set<String>zIssueIdnotExsistInAha = new Set<String>();
        Boolean excecuteBatch = false;
        Map<String,Set<String>> noRecordFoundofZissueinAha = new Map<String,Set<String>>();
        Map<String,Set<String>> RecordFoundofZissueinAha = new Map<String,Set<String>>();
        Map<String,Set<String>> createnewIdeaInsfdc = new Map<String,Set<String>>();
        Set<Id> zissueIdSet = new Set<id>();
        Map<String,Set<String>> zsfjiraAndCaseMap = new Map<String,Set<String>>();
        // Process the CSV data here
        try{
            if(csvLines.size()>0){
                Integer i = 0;
                for(String line : csvLines){
                    list<String> caseNumberList = New list<String>();
                    List<String> columns = line.split(',');
                    list<String> caseNumbers = New list<String>();
                    if(i != 0){
                            if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containskey(columns[0].trim())){
                                jiraNumberVsCaseNumbers.get(columns[0]).add(columns[1].trim());
                                allCaseNumberList.add(columns[1].trim());
                                zIssueIdnotExsistInAha.add(columns[0].trim());
                            }
                            else{
                                jiraNumberVsCaseNumbers.put(columns[0].trim(),new Set<String>{columns[1].trim()});
                                allCaseNumberList.add(columns[1].trim());
                                zIssueIdnotExsistInAha.add(columns[0].trim());
                            }
                    }
                    i++;
                }
            }
            if(!zIssueIdnotExsistInAha.isEmpty()){
                for(zsfjira__ZIssue__c Zissue : [Select id,name,Aha_Unique_Id__c from zsfjira__ZIssue__c where name IN :  jiraNumberVsCaseNumbers.keySet()]){
                    zIssueIdnotExsistInAha.remove(Zissue.name);
                    if(Zissue.Aha_Unique_Id__c != null){
                         zIssueIdalreadyExsistInAha.add(Zissue.name);
                    }
                    else{
                         noIdeaIdPresentOnZissueSet.add(Zissue.name);
                    }
                    zissueIdSet.add(Zissue.id);

                }
            }

            if(zissueIdSet.Size() > 0){
                for(zsfjira__ZIssue_Case__c zsfjira : [Select id,zsfjira__CaseId__c,zsfjira__CaseId__r.CaseNumber,zsfjira__ZIssueId__c,zsfjira__ZIssueId__r.Name from zsfjira__ZIssue_Case__c where zsfjira__ZIssueId__c IN : zissueIdSet]){
                    allCaseNumberList.add(zsfjira.zsfjira__CaseId__r.CaseNumber);
                    if(zsfjiraAndCaseMap.isEmpty() || !zsfjiraAndCaseMap.containsKey(zsfjira.zsfjira__ZIssueId__r.Name)){
                       zsfjiraAndCaseMap.put(zsfjira.zsfjira__ZIssueId__r.Name, new Set<String>{zsfjira.zsfjira__CaseId__r.CaseNumber});
                    }
                    else{
                        zsfjiraAndCaseMap.get(zsfjira.zsfjira__ZIssueId__r.Name).add(zsfjira.zsfjira__CaseId__r.CaseNumber);
                    }
                }
            }
            if(allCaseNumberList.size() > 0){
                for(Case cc : [Select id,CaseNumber from Case where CaseNumber IN : allCaseNumberList]){
                    caseMap.put(cc.CaseNumber,cc);
                }
            }

            if(zIssueIdalreadyExsistInAha.size() > 0){
                for(String zissueNo : zIssueIdalreadyExsistInAha){
                    if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containskey(zissueNo)){
                        Set<String> setcaseids = jiraNumberVsCaseNumbers.get(zissueNo);
                         RecordFoundofZissueinAha.put(zissueNo,setcaseids);
                    }
                }
            }

            if(zIssueIdalreadyExsistInAha.Size() > 0){
                for(Aha_Ideas__c ai : [SELECT Id,name,Aha_Unique_ID__c,(Select id,Aha_Ideas__c,Case_Number__c,Case_Number__r.CaseNumber from Aha_Idea_Links__r where Case_Number__c!= null),zIsssue_Number__c FROM Aha_Ideas__c WHERE zIsssue_Number__c IN : zIssueIdalreadyExsistInAha]){
                    ideaList.add(ai);
                    Map<String,Aha_Idea_Link__c> caseAndIdeaLinkMap = new Map<String,Aha_Idea_Link__c>();
                    for(Aha_Idea_Link__c IdeaLink : ai.Aha_Idea_Links__r){
                        caseAndIdeaLinkMap.put(IdeaLink.Case_Number__r.CaseNumber,IdeaLink);
                    }
                    AhaIdandlistofAhaLink.put(ai.id,caseAndIdeaLinkMap);
                    zIssueIdalreadyExsistInAha.remove(ai.zIsssue_Number__c);

                }
            }
            List<Aha_Idea_Link__c> insertAhaLinkListRecord = new List<Aha_Idea_Link__c>();
            Integer totalNoOfCases;
            Set<Id> accIds = new Set<Id>();
            String linkOfCasesAttachedWithIdea = '';

            if(ideaList.Size() > 0){
                for(Aha_Ideas__c ai : ideaList){
                    Set<String> cseNumberList = new Set<String>();

                    if(jiraNumberVsCaseNumbers.containsKey(ai.zIsssue_Number__c)){
                        for(String csenum : jiraNumberVsCaseNumbers.get(ai.zIsssue_Number__c)){
                            cseNumberList.add(csenum.trim());
                        }
                    }
                    if(!zsfjiraAndCaseMap.isEmpty() && zsfjiraAndCaseMap.containsKey(ai.zIsssue_Number__c)){
                        Set<string> caserelatedtoZissue = zsfjiraAndCaseMap.get(ai.zIsssue_Number__c);
                        if(caserelatedtoZissue.size() > 0){
                            cseNumberList.addAll(caserelatedtoZissue);
                        }
                    }

                    if(cseNumberList.Size() > 0 && !caseMap.isEmpty()){
                        Map<String,Aha_Idea_Link__c> caseAndIdeaLinkMap = new Map<String,Aha_Idea_Link__c>();
                        if(!AhaIdandlistofAhaLink.isEmpty() && AhaIdandlistofAhaLink.containskey(ai.id)){
                            caseAndIdeaLinkMap =  AhaIdandlistofAhaLink.get(ai.id);
                        }
                        for(String csNumber : cseNumberList){
                            String cseNumber = csNumber.trim();
                            case cc = new Case();
                            if(caseMap.containsKey(cseNumber)){
                                cc = caseMap.get(cseNumber);
                            }
                            if(cc.Id!= null && (caseAndIdeaLinkMap.isEmpty() || !caseAndIdeaLinkMap.containsKey(cc.CaseNumber))){
                                    Aha_Idea_Link__c insertIdeaLink = new Aha_Idea_Link__c();
                                    insertIdeaLink.Aha_Ideas__c = ai.Id;
                                    insertIdeaLink.Case_Number__c = cc.id;
                                    insertAhaLinkListRecord.add(insertIdeaLink);
                                    AhaIds.add(ai.Id);
                            }
                        }
                    }
                }
                if(insertAhaLinkListRecord.size()>0){
                     INSERT insertAhaLinkListRecord;
                     AhaWebhookReceiver.updateLinkedRelatedRecord(AhaIds);
                }
            }

            if(zIssueIdalreadyExsistInAha.size() > 0){
                for(String zissueNo : zIssueIdalreadyExsistInAha){
                    if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containskey(zissueNo)){
                        Set<String> setcaseids = jiraNumberVsCaseNumbers.get(zissueNo);
                        if(!zsfjiraAndCaseMap.isEmpty() && zsfjiraAndCaseMap.containskey(zissueNo)){
                            Set<String> ZissueRelatedCases = zsfjiraAndCaseMap.get(zissueNo);
                            if(ZissueRelatedCases.Size() > 0){
                                setcaseids.addall(ZissueRelatedCases);
                            }
                        }
                        createnewIdeaInsfdc.put(zissueNo,setcaseids);
                    }
                }
            }

            if(!createnewIdeaInsfdc.isempty()){
                AhaWebhookReceiver.createNewIdeaInSfdc(JSON.serialize(createnewIdeaInsfdc));
            }

            if(zIssueIdnotExsistInAha.size()>0){
                for(String zissueId : zIssueIdnotExsistInAha){
                    if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containskey(zissueId)){
                        noRecordFoundofZissueinAha.put(zissueId,jiraNumberVsCaseNumbers.get(zissueId));
                    }
                }
            }

            if(noIdeaIdPresentOnZissueSet.size()>0){
                for(String zissueName : noIdeaIdPresentOnZissueSet){
                    if(!jiraNumberVsCaseNumbers.isEmpty() && jiraNumberVsCaseNumbers.containskey(zissueName)){
                        Set<String> caseidset = jiraNumberVsCaseNumbers.get(zissueName);
                        if(!zsfjiraAndCaseMap.isEmpty() && zsfjiraAndCaseMap.containsKey(zissueName)){
                            Set<string> caserelatedtoZissue = zsfjiraAndCaseMap.get(zissueName);
                            if(caserelatedtoZissue.size() > 0){
                                caseidset.addAll(caserelatedtoZissue);
                            }
                        }
                        noIdeaIdPresentOnZissueMap.put(zissueName,caseidset);
                    }
                }
            }

            if(noIdeaIdPresentOnZissueMap.size() > 0){
                excecuteBatch = true;
            }
            if(excecuteBatch){
                  BatchToCreateIdeaInAhaForZissue batchforcreateidea = new BatchToCreateIdeaInAhaForZissue(noIdeaIdPresentOnZissueMap,noRecordFoundofZissueinAha,RecordFoundofZissueinAha);
                  Database.executeBatch(batchforcreateidea,1);
            }
            else if(!noRecordFoundofZissueinAha.isEmpty() || !RecordFoundofZissueinAha.isEmpty()){
                 String csvColumnHeader = 'Zissue Id, CaseId, Status\n';
                if(!noRecordFoundofZissueinAha.isEmpty()){
                    for(String Zissueid : noRecordFoundofZissueinAha.keySet()){
                        for(String cseNumb : noRecordFoundofZissueinAha.get(Zissueid)){
                            csvColumnHeader+= Zissueid.trim() + ',' + cseNumb.trim() + ',' + 'No Record Found In ZIssue related to Id' + '\n';
                        }
                    }
                }
                if(!RecordFoundofZissueinAha.isEmpty()){
                    for(String Zissueid : RecordFoundofZissueinAha.keySet()){
                        for(String cseNumb : RecordFoundofZissueinAha.get(Zissueid)){
                           csvColumnHeader+= Zissueid.trim() + ',' + cseNumb.trim() + ',' + 'Success'+ '\n';
                        }
                    }
                }

                String csvFile = csvColumnHeader;
                SendEmailToCurrentUser(csvFile);

            }
        }//end of try
        catch(Exception e){
            if(csvLines.size()>0){
                Integer i = 0;
                String csvColumnHeader = 'Zissue Id, CaseId, Status\n';
                for(String line : csvLines){
                    List<String> columns = line.split(',');
                    if(i != 0){
                        csvColumnHeader+= columns[0].trim() + ',' + columns[1].trim() + ',' + 'Error Occured' + '\n';
                    }
                    i++;
                }
                if(!String.isBlank(csvColumnHeader)){
                    String csvFile = csvColumnHeader;
                    SendEmailToCurrentUser(csvFile);
                }
            }
        }

    }//End of method
    public static void SendEmailToCurrentUser(String csvfile){
        if(!String.isBlank(csvfile)){
            String currentUserEmail = UserInfo.getUserEmail();
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
            //message.setSenderDisplayName('Batch Class Status File');
            OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = 'donotreply@rubrik.com' LIMIT 1];
            //if(!Test.isRunningTest()){
            if ( owea != Null) {
                message.setOrgWideEmailAddressId(owea.Id);
            }
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
            //}

        }
    }//End of Method
}//end of class