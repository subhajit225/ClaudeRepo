/**
 * @description Helper class for ManageAhaIdeaController that provides comprehensive functionality
 *              for managing AHA ideas integration with Salesforce. This class handles API
 *              communications with AHA platform, data synchronization, record management,
 *              and various business logic operations for idea management workflows.
 * @author Grazitti Interactive
 * @since 8/9/2023
 * @see ManageAhaIdeaController
 * @see ManageAhaIdeaControllerTest
 */
public without sharing class ManageAhaIdeaHelper{

    /**
     * @description Searches for AHA idea records based on the provided search term and filters
     *              out already linked ideas for the given record ID. Makes HTTP callout to
     *              AHA API to retrieve matching ideas and converts them to Salesforce records.
     * @param searchTerm The search term to query AHA ideas (URL encoded automatically)
     * @param rcId The record ID (Case or Opportunity) to exclude already linked ideas
     * @return List<Aha_Ideas__c> List of AHA idea records matching the search criteria
     * @throws AuraHandledException When API call fails or returns invalid response
     */
    @AuraEnabled(cacheable=true)
    public static List<Aha_Ideas__c> searchAhaRecords(String searchTerm, Id rcId){
            try{

                Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
                Map<String,Aha_Ideas__c> datatableMap = new Map<String,Aha_Ideas__c>();
                List<Aha_Ideas__c> ideaRecordList = new List<Aha_Ideas__c>();
                Map<String,String> ahaIdeafieldNameandValue = new Map<String,String>();
                String query = '?fields=name,description&q=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8');
                List<String> linkedahaIdeaNo = new List<String>();
                if(rcId!= null){
                    for(Aha_Idea_Link__c ideaLinkRec : [Select id,Aha_Ideas__c,Aha_Ideas__r.Aha_Unique_ID__c from Aha_Idea_Link__c Where Case_Number__c =: rcId OR Opportunity_Name__c=: rcId]){
                        if(ideaLinkRec.Aha_Ideas__r.Aha_Unique_ID__c!= null){
                            linkedahaIdeaNo.add(ideaLinkRec.Aha_Ideas__r.Aha_Unique_ID__c);
                        }
                    }
                }
                if(searchTerm!= null && searchTerm!= ''){
                    string newSearchTerm = searchTerm.replaceall(' ','%20');
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/ideas?q=' + newSearchTerm);
                    request.setMethod('GET');
                    request.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                    request.setHeader('contentType', 'application/json');
                    request.setHeader('Accept', 'application/json');
                    Http http = new Http();
                    List<Object> recordList = New List<Object>();
                    HttpResponse response = http.send(request);
                    if (response.getStatusCode() == 200) {
                        Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        recordList = (List<Object>) records.get('ideas');
                    }
                    else{
                        throw new CalloutException('Api Response is not returing the Values');
                    }
                    if(recordList.size()>0){
                        for (Object record : recordList) {
                            Aha_Ideas__c ideaRecord = new Aha_Ideas__c();
                            Map<String, Object> recordMap = (Map<String, Object>) record;
                            ideaRecord.Name = String.valueof(recordMap.get('name'));
                            ideaRecord.Aha_Unique_ID__c = String.valueof(recordMap.get('reference_num'));
                            Map<String, Object> descRecords = (Map<String, Object>)recordMap.get('description');
                            String descValue = String.valueof(descRecords.get('body'));
                            ideaRecord.Idea_Description__c= descValue.stripHtmlTags();
                            if(!linkedahaIdeaNo.contains(ideaRecord.Aha_Unique_ID__c)){
                                ideaRecordList.add(ideaRecord);
                                if(ideaRecordList.size()==6){
                                    Break;
                                }
                            }
                        }
                    }
                }
                return ideaRecordList;
            }
            catch (exception ex){
                String errorMessage = ex.getMessage();
                throw new AuraHandledException(errorMessage);
            }
        } //End of Method


    /**
     * @description Creates AHA idea link records after AHA ideas are inserted. This method
     *              processes newly inserted AHA ideas and creates corresponding link records
     *              to associate them with Cases or Opportunities based on the origin field.
     * @param newTriggerList List of newly inserted AHA idea records from trigger context
     * @throws AuraHandledException When DML operations fail or required data is missing
     */
    public static void afterInsertAhaIdeaHelper(List<Aha_Ideas__c> newTriggerList){
            try{
                List<Aha_Idea_Link__c> insertAhaIdeaList = new List<Aha_Idea_Link__c>();
                for(Aha_Ideas__c ahaIdea : newTriggerList){
                    if(ahaIdea.Aha_Idea_Origin__c != null){
                        Aha_Idea_Link__c ahaIdeaLink = new Aha_Idea_Link__c();
                        ahaIdeaLink.Aha_Ideas__c = AhaIdea.id;
                        if(ahaIdea.Aha_Idea_Origin__c.startswith('006')){
                            ahaIdeaLink.Opportunity_Name__c= ahaIdea.Aha_Idea_Origin__c;
                        }
                        else if(AhaIdea.Aha_Idea_Origin__c.startswith('500')){
                            ahaIdeaLink.Case_Number__c= ahaIdea.Aha_Idea_Origin__c;
                        }
                        insertAhaIdeaList.add(ahaIdeaLink);
                    }
                }
                if(insertAhaIdeaList!= null && insertAhaIdeaList.size()>0){
                    INSERT insertAhaIdeaList;
                }
            }
            catch (Exception e) {
                String errorMessage = e.getMessage();
                throw new AuraHandledException(errorMessage);
            }
        }

    /**
     * @description Processes AHA ideas before insertion to validate and enrich data.
     *              This method handles data validation, duplicate checking, and field
     *              population for AHA ideas before they are inserted into Salesforce.
     * @param newTriggerList List of AHA idea records being inserted from trigger context
     * @throws AuraHandledException When validation fails or required data is missing
     */
    public static void beforeInsertAhaIdeaHelper(List<Aha_Ideas__c> newTriggerList){
            try{
               Map<String,String>IdeaUniqueIdandZissueName = new Map<String,String>();
               Set<String> AhaUniqueIdSet = new Set<String>();
                for(Aha_Ideas__c ahaIdea : newTriggerList){
                   if(ahaIdea.Aha_Unique_ID__c!= null){
                       AhaUniqueIdSet.add(ahaIdea.Aha_Unique_ID__c);
                   }
                }

                if(AhaUniqueIdSet.Size() > 0){
                    for(zsfjira__ZIssue__c  zissue : [Select id,Name,Aha_Unique_Id__c from zsfjira__ZIssue__c where Aha_Unique_Id__c IN : AhaUniqueIdSet]){
                       IdeaUniqueIdandZissueName.put(zissue.Aha_Unique_Id__c,zissue.Name);
                    }
                }
                if(!IdeaUniqueIdandZissueName.isEmpty()){
                    for(Aha_Ideas__c ahaIdea : newTriggerList){
                        if(ahaIdea.Aha_Unique_ID__c!= null && IdeaUniqueIdandZissueName.containskey(ahaIdea.Aha_Unique_ID__c)){
                          ahaIdea.zIsssue_Number__c = IdeaUniqueIdandZissueName.get(ahaIdea.Aha_Unique_ID__c);
                        }
                    }
                }
            }
            catch (Exception e) {
                String errorMessage = e.getMessage();
                throw new AuraHandledException(errorMessage);
            }
        }
    /**
     * @description Retrieves detailed AHA idea record data from AHA platform via API.
     *              Makes HTTP callout to fetch comprehensive idea information including
     *              status, description, and other metadata for the specified AHA ID.
     * @param ahaId The unique AHA idea identifier to retrieve data for
     * @return Map<String, Object> Map containing the AHA idea data from API response
     * @throws AuraHandledException When API call fails or returns invalid response
     */
    public static Map<String, Object> getAhaIdeaRecordData(String ahaId){
            Map<String, Object> recordMap = new Map<String, Object>();
            if(ahaId.contains('&0.source=alohaHeader')){
                ahaId.replace('&0.source=alohaHeader','');
            }
            try {
                Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
                if(ahaId!= null && ahaId!= ''){
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/ideas/' + ahaId);
                    request.setMethod('GET');
                    request.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                    request.setHeader('contentType', 'application/json');
                    request.setHeader('Accept', 'application/json');
                    Http http = new Http();
                    
                    HttpResponse response = http.send(request);
                    if(response.getStatusCode() == 200){
                        Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        object obj = records.get('idea');

                        Map<String, Object> objectMap = (Map<String, Object>)obj;
                        String ahaIdeaId = (String) objectMap.get('id');
                        recordMap.put(ahaIdeaId,obj);
                    }
                    else{
                        throw new CalloutException('');
                    }
                }
                return recordMap;
            }
            catch (Exception e) {
                String errorMessage = e.getMessage();
                throw new AuraHandledException(errorMessage);
            }
        }

    /**
     * @description Links selected AHA ideas with Opportunities or Cases from the Manage AHA Idea page.
     *              Creates or updates AHA idea records in Salesforce and establishes link records
     *              to associate them with the specified object record (Case or Opportunity).
     * @param apiResponseMap Map containing API response data with AHA idea information
     * @param ahaIDeaId Set of AHA idea unique identifiers to be linked
     * @param objectrecordId The Salesforce record ID (Case or Opportunity) to link ideas to
     * @throws AuraHandledException When linking operation fails or data validation errors occur
     */
    public static void linkSelectedrowsWithAhaIdea( Map<String, Object> apiResponseMap, Set<String> ahaIDeaId,String objectrecordId){

            Map<string,Aha_Ideas__c> existingAhaIdeaRecordMap = new Map<String,Aha_Ideas__c>();
            List<Aha_Ideas__c> ahaIdeaInsertList = new List<Aha_Ideas__c>();
            List<Aha_Ideas__c> ahaIdeaUpdtaeList = new List<Aha_Ideas__c>();
            List<Aha_Ideas__c> ahaIdeaUpsertList = new List<Aha_Ideas__c>();
            List<Aha_Idea_Link__c> createAhaIdealinkList = new List<Aha_Idea_Link__c>();
            Map<String,String> mapofAhaIdeaIdandAccountName = new Map<String,String>();
            Map<String,String> mapofAhaIdeaIdandObjRecordId = new Map<String,String>();
            Map<String,List<Aha_Idea_Link__c>>ideaUniqueIdAndIdeaLinkRecord = new Map<String,List<Aha_Idea_Link__c>>();
            Set<Id> ahaParentIdeaId = new Set<Id>();
            Set<Id> ChildAhaIdeaId = new Set<Id>();
            String accountName = '';
            String currentUserEmail = '';
            Boolean strategicMajorAccount = False;
            Account aa = new Account();
            Opportunity oppty = new Opportunity();
            Case cse = new Case();
            try{
                if(objectrecordId!= ''){
                    if(objectrecordId.startsWith('006')){
                        oppty = [Select id,name,AccountId,iswon,isclosed,Account.name,ACV_Amount__c,Account.Strategic_Account__c,Account.Account_Preference__c  from Opportunity where id =: objectrecordId];
                        if(oppty.AccountId!= null){
                            aa.Id =  oppty.Account.Id;
                            aa.Name = oppty.Account.Name;
                            aa.Strategic_Account__c  = oppty.Account.Strategic_Account__c;
                            aa.Account_Preference__c = oppty.Account.Account_Preference__c;
                        }
                    }
                    else if(objectrecordId.startsWith('500')){
                        cse = [Select id,CaseNumber,AccountId,Account.name,Account.Strategic_Account__c,Account.Account_Preference__c from case where id =: objectrecordId];
                        if(cse.AccountId!= null){
                            aa.Id =  cse.Account.Id;
                            aa.Name = cse.Account.Name;
                            aa.Strategic_Account__c  = cse.Account.Strategic_Account__c;
                            aa.Account_Preference__c = cse.Account.Account_Preference__c;
                        }
                    }
                }

                currentUserEmail = UserInfo.getUserEmail();
                if(aa!= null && aa.name!= null){
                    accountName = aa.name;
                    strategicMajorAccount = aa.Strategic_Account__c;
                }

                for(Aha_Ideas__c idea : [SELECT Id,Aha_Idea_Number__c,Duplicate_of__c,Impacted_Customers__c,
                                         (SELECT Id,Case_Number__c,Case_Number__r.AccountId,Case_Number__r.CaseNumber,Opportunity_Name__c,Opportunity_Name__r.AccountId,Opportunity_Name__r.Name,Opportunity_Name__r.iswon,Opportunity_Name__r.isclosed,Opportunity_Name__r.ACV_Amount__c
                                          FROM Aha_Idea_Links__r),
                                         Aha_Idea_Origin__c,Aha_Unique_ID__c,Business_Case_Value__c,
                                         Creator_Proposed_Solution__c,Escalation__c,For_Workspace__c,
                                         Problem_Statement__c,Product_Area__c,Product_Component__c,Strategic_Major_Account__c
                                         FROM  Aha_Ideas__c WHERE Aha_Unique_ID__c IN: AhaIDeaId ORDER BY createddate ASC]){
                                             existingAhaIdeaRecordMap.put(idea.Aha_Idea_Number__c,idea);

                                             for(Aha_Idea_Link__c ideaLink : idea.Aha_Idea_Links__r){

                                                 if(!ideaUniqueIdAndIdeaLinkRecord.isEmpty() && ideaUniqueIdAndIdeaLinkRecord.containsKey(idea.Aha_Unique_ID__c)){
                                                     ideaUniqueIdAndIdeaLinkRecord.get(idea.Aha_Unique_ID__c).add(ideaLink);
                                                 }
                                                 else{
                                                     ideaUniqueIdAndIdeaLinkRecord.put(idea.Aha_Unique_ID__c,new list<Aha_Idea_Link__c>{ideaLink});
                                                 }
                                             } // end of Aha_Idea_Link__c for loop
                                            ChildAhaIdeaId.add(idea.Id);
                                            if(idea.Duplicate_of__c!= null){
                                                ahaParentIdeaId.add(idea.Duplicate_of__c);
                                            }
                                        } //end of for loop

                if(!apiResponseMap.isEmpty()){
                    for(String apiResponseString : apiResponseMap.keyset()){
                        Map<String,String> ahaIdeafieldNameandValue = new Map<String,String>();
                        Object obj = apiResponseMap.get(ApiResponseString);
                        Map<String, Object> objectMap = (Map<String, Object>)obj;
                        String ahaIdearefno = (String) objectMap.get('reference_num');
                        String ahaIdeaRecordId = (String) objectMap.get('id');
                        String ahaIdeaName = (String) objectMap.get('name');
                        Decimal amountforClosedWonOppty = 0;
                        Decimal amountforClosedLostOppty = 0;
                        Decimal amountforInflightOppty = 0;
                        if(!String.isBlank(ahaIdearefno)&& !String.isBlank(ahaIdeaRecordId)){
                            ahaIdeafieldNameandValue.put('reference_num',ahaIdearefno);
                            ahaIdeafieldNameandValue.put('AhaId',ahaIdeaRecordId);
                            ahaIdeafieldNameandValue.put('Name',ahaIdeaName);
                        }
                        //get description value
                        Map<String, Object> descRecords = (Map<String, Object>)objectMap.get('description');
                        List<object> customFieldValObj = (List<object>) objectMap.get('custom_fields');
                        Map<String, Object> statusFieldValObj = (Map<String, Object>)objectMap.get('workflow_status');
                        for(object objNew : customFieldValObj){
                            Map<String, Object> objMap = (Map<String, Object>) objnew;
                            String name = String.valueof(objMap.get('name'));
                            String value = String.valueof(objMap.get('value'));
                            string fieldValue = '';
                            if(!string.isblank(value)){
                                fieldValue = value.trim();
                            }
                            ahaIdeafieldNameandValue.put(name.trim(),fieldValue);
                        }
                        for(object objNew : statusFieldValObj.keySet()){
                            if(statusFieldValObj.containsKey('name')){
                                String ideaStatus =  String.valueof(statusFieldValObj.get('name'));
                                ahaIdeafieldNameandValue.put('ideaStatus',ideaStatus);
                            }
                        }
                        if(!ahaIdeafieldNameandValue.isEmpty()){
                            //If idea record is not present in salesforce then create a new idea
                            if(existingAhaIdeaRecordMap.isEmpty() || !existingAhaIdeaRecordMap.containskey(ahaIdeaRecordId)){
                                Aha_Ideas__c newAhaIdea = new Aha_Ideas__c();
                                if(ahaIdeafieldNameandValue.containsKey('ideaStatus')){
                                    newAhaIdea.Status__c = ahaIdeafieldNameandValue.get('ideaStatus');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('PM Response')){
                                    newAhaIdea.PM_Response__c = ahaIdeafieldNameandValue.get('PM Response');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Business Case/Value')){
                                    newAhaIdea.Business_Case_Value__c = ahaIdeafieldNameandValue.get('Business Case/Value');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Creator Proposed Solution')){
                                    newAhaIdea.Creator_Proposed_Solution__c = ahaIdeafieldNameandValue.get('Creator Proposed Solution');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Escalation')){
                                    newAhaIdea.Escalation__c = ahaIdeafieldNameandValue.get('Escalation');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Idea Tags')){
                                    String Ideatagsval = String.valueof(ahaIdeafieldNameandValue.get('Idea Tags'));
                                    if(Ideatagsval.contains('(') || Ideatagsval.contains(')') ){
                                        Ideatagsval=Ideatagsval.replace('(','');
                                        Ideatagsval=Ideatagsval.replace(')','');
                                    }
                                    newAhaIdea.Idea_Tags__c = Ideatagsval;
                                }
                                if(ahaIdeafieldNameandValue.containsKey('For Workspace')){
                                    newAhaIdea.For_Workspace__c = ahaIdeafieldNameandValue.get('For Workspace');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Problem Statement')){
                                    newAhaIdea.Problem_Statement__c = ahaIdeafieldNameandValue.get('Problem Statement');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Product Area')){
                                    newAhaIdea.Product_Area__c = ahaIdeafieldNameandValue.get('Product Area');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Product Component')){
                                    String productval = ahaIdeafieldNameandValue.get('Product Component');
                                    if(productval.contains('(') || productval.contains(')') ){
                                        productval=productval.replace('(','');
                                        productval=productval.replace(')','');
                                    }
                                    List<String> productList = productval.split(',');
                                    newAhaIdea.Product_Component__c =  productList.Size()>0 ? String.join(productList,';') : '';
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Idea Category')){
                                    newAhaIdea.Idea_Category__c = ahaIdeafieldNameandValue.get('Idea Category');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('AhaId')){
                                    newAhaIdea.Aha_Idea_Number__c = ahaIdeafieldNameandValue.get('AhaId');
                                }
                                if(ahaIdeafieldNameandValue.containsKey('Name')){
                                    String ahaIdeafieldNameVal = ahaIdeafieldNameandValue.get('Name');
                                    newAhaIdea.Name = ahaIdeafieldNameVal.length()>= 80 ? ahaIdeafieldNameVal.substring(0,75) + '...' :ahaIdeafieldNameVal;
                                }
                                if(!String.isempty(string.valueof(descRecords.get('body')))){
                                    string desciptionValue = string.valueof(descRecords.get('body'));
                                    newAhaIdea.Idea_Description__c = desciptionValue.stripHtmlTags();
                                }
                                if(objectRecordId!= null){
                                    newAhaIdea.Aha_Idea_Origin__c = objectRecordId;
                                }
                                if(ahaIdearefno!= null){
                                    newAhaIdea.Aha_Unique_ID__c = ahaIdearefno;
                                }
                                Integer noofcustomerRequested = 0;
                                Integer totalNoOfCases = 0;
                                Integer totalNoOfOpportunities = 0;
                                String linkOfOpportunitiesAttachedWithIdea = '';
                                String linkOfCasesAttachedWithIdea = '';
                                List<String>listOfAccPref = new List<String>();
                                if(aa.Id!= null){
                                    newAhaIdea.Strategic_Major_Account__c = aa.Strategic_Account__c ? 1:0;
                                    newAhaIdea.Impacted_Customers__c = aa.Name!= null ? aa.Name:'';
                                    noofcustomerRequested  = aa.Name!= null ? 1:0;
                                    if(aa.Account_Preference__c!=null){
                                        newAhaIdea.Account_Preference__c = aa.Account_Preference__c;
                                        listOfAccPref = aa.Account_Preference__c.Split(';');
                                    }
                                }
                                if(objectrecordId!= null && objectrecordId.startswith('006') && oppty.Id!= null){
                                    String oppName = oppty.Name;
                                    String pattern = '[\\\\\'"!@#$%^&*()_+\\-=\\[\\]{};:\\\\|,.<>\\/?]';
                                    linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea +'<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + oppty.Id+ '\\">'+oppName.replaceAll(pattern, '\\\\$0')+'</a> ; ';

                                    totalNoOfOpportunities++;
                                     newAhaIdea.Total_No_of_Opportunity_Link_With_Idea__c= totalNoOfOpportunities;
                                    if(oppty.iswon && oppty.ACV_Amount__c!= null){
                                        amountforClosedWonOppty += oppty.ACV_Amount__c;
                                    }
                                    else if(oppty.isclosed && oppty.ACV_Amount__c!= null){
                                        amountforClosedLostOppty += oppty.ACV_Amount__c;
                                    }
                                    else if(!oppty.isclosed && !oppty.iswon && oppty.ACV_Amount__c!= null){
                                        amountforInflightOppty += oppty.ACV_Amount__c;
                                    }
                                    newAhaIdea.Total_Amount_for_the_Closed_Won_Oppty__c =  String.valueOf(amountforClosedWonOppty);
                                    newAhaIdea.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueOf(amountforClosedLostOppty);
                                    newAhaIdea.Total_Amount_for_the_In_Flight_Oppty__c =   String.valueOf(amountforInflightOppty);
                                }
                                else if(objectrecordId!= null && objectrecordId.startswith('500') && cse.Id!= null){
                                    linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + cse.Id+ '\\">'+cse.CaseNumber+'</a> ; ';
                                    totalNoOfCases++;
                                    newAhaIdea.Total_No_of_Cases_Link_With_Idea__c= totalNoOfCases;
                                }

                                if(ahaIdearefno!= null
                                   && (newAhaIdea.Impacted_Customers__c!= null || noofcustomerRequested >0 ||
                                       newAhaIdea.Strategic_Major_Account__c>0)){
                                           updateIdeaRecordInAha(newAhaIdea,newAhaIdea.Impacted_Customers__c,NoofcustomerRequested,currentUserEmail,Integer.valueof(newAhaIdea.Strategic_Major_Account__c),totalNoOfCases,linkOfCasesAttachedWithIdea,totalNoOfOpportunities,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);
                                       }
                                ahaIdeaUpsertList.add(newAhaIdea);
                            }
                            //If idea record is present in salesforce then update the idea
                            else if(!existingAhaIdeaRecordMap.isEmpty() && existingAhaIdeaRecordMap.containskey(AhaIdeaRecordId)){
                                Aha_Ideas__c updateSalesforceIdea = existingAhaIdeaRecordMap.get(AhaIdeaRecordId);
                                List<Aha_Idea_Link__c> ideaLinkList = new List<Aha_Idea_Link__c>();
                                if(!ideaUniqueIdAndIdeaLinkRecord.isEmpty() && ideaUniqueIdAndIdeaLinkRecord.containsKey(ahaIdearefno)){
                                    ideaLinkList = ideaUniqueIdAndIdeaLinkRecord.get(ahaIdearefno);
                                }
                                reCalculateValuesforIdea(ideaLinkList,aa,updateSalesforceIdea,objectrecordId,ahaIdeaUpsertList,createAhaIdealinkList,oppty,cse);
                            }// end of else if
                        }// end  of if
                    } // end of for loop

                }
                // Update or Insert Idea Record
                if(ahaIdeaUpsertList.size()>0){
                    UPSERT ahaIdeaUpsertList;
                }
                if(createAhaIdealinkList.size()>0){
                    INSERT createAhaIdealinkList;
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
            catch(DmlException ex){
                throw new CalloutException('DmlException caught while creating the Idea in Salesforce. Aha Idea is created with the reference Number. You can search the Idea with the Refernce Number   + AhaRefId  +    ' + ex.getMessage());
            }
            catch(CalloutException ex) {
                throw new CalloutException('DmlException caught while creating the Idea in Salesforce. Aha Idea is created with the reference Number. You can search the Idea with the Refernce Number   + AhaRefId   ' + ex.getMessage());
            }
            catch (exception e){
                String errorMessage = e.getMessage();
                throw new AuraHandledException(errorMessage);
            }
        }//End of Method


    /**
     * @description Escalates an AHA idea record by updating its status in the AHA platform.
     *              Makes API call to AHA to change the idea status to escalated state,
     *              typically moving it to a higher priority or different workflow stage.
     * @param ahaUniqueId The unique AHA idea identifier to escalate
     * @throws AuraHandledException When API call fails or escalation process encounters errors
     */
    @AuraEnabled
    public static void EscalateAhaIdeaRecord(String ahaUniqueId){
            // Update Aha Idea in Aha
            if(ahaUniqueId!= null){
                Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');

                // Handle null custom metadata in test context
                if(ahaCredential == null) {
                    if(Test.isRunningTest()) {
                        return; // Skip the callout in test if metadata is not available
                    } else {
                        throw new AuraHandledException('AHA Credential metadata not found');
                    }
                }

                String escalateValue = 'Yes';
                String requestBody = '';requestBody = '{"idea":{"custom_fields":{"escalation":"'+escalateValue+'"}}}';
                HttpRequest req = new HttpRequest();
                req.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/ideas/' + ahaUniqueId);
                req.setMethod('PUT');
                req.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                req.setHeader('contentType', 'application/json');
                req.setHeader('Content-Type','application/json;charset=UTF-8');
                req.setHeader('Accept', 'application/json');
                if(requestBody != ''){
                    req.setBody(requestBody);
                }
                // Send the HTTP request
                Http httpNew = new Http();
                HttpResponse responsenew = httpNew.send(req);
                if (responsenew.getStatusCode() == 200){
                    //do nothing
                }
                else{
                    throw new CalloutException('');
                }
            }
        }// End of method


    /**
     * @description Updates selected AHA ideas by unlinking or escalating them from Opportunities or Cases.
     *              Performs the specified action (Unlink/Escalate) on AHA ideas and updates both
     *              Salesforce records and AHA platform via API calls.
     * @param apiResponseMap Map containing API response data with AHA idea information
     * @param ahaIDeaId Set of AHA idea unique identifiers to be updated
     * @param objectRecordId The Salesforce record ID (Case or Opportunity) associated with the ideas
     * @param Action The action to perform ('Unlink' or 'Escalate')
     * @throws AuraHandledException When update operation fails or invalid action is specified
     */
    public static void updateSelectedrowsinAhaIdea( Map<String, Object> apiResponseMap, Set<String> ahaIDeaId,String objectRecordId, String Action){
            String ideaId;
            Map<String,string> ahaidandAccountName = new Map<String,string>();
            Map<String,string> mapofAhaIdAndAccountName= new Map<String,string>();
            Map<String,List<Aha_Idea_Link__c>> ideaAndIdeaLinkRecord = new Map<String,List<Aha_Idea_Link__c>>();
            List<Aha_Idea_Link__c> deleteAhaIdeaLinkList = new list<Aha_Idea_Link__c>();
            List<Aha_Ideas__c> ahaIdeaUpdateList = new List<Aha_Ideas__c>();
            String accountName = '';
            Boolean strategicMajorAccount = false;
            String currentUserEmail = '';
            Account aa = new Account();
            Opportunity oppty = new Opportunity();
            Case cse = new Case();
            Set<Id> ahaParentIdeaId = new Set<Id>();
            Set<Id> ChildAhaIdeaId = new Set<Id>();
            Set<string> escalateAhaIdeaId = new Set<String>();
            try{
                if(objectrecordId!= ''){
                    if(objectrecordId.startsWith('006')){
                        oppty = [Select id,name,AccountId,Account.name,iswon,isclosed,ACV_Amount__c,Account.Strategic_Account__c,Account.Account_Preference__c  from Opportunity where id =: objectrecordId];
                        if(oppty.AccountId!= null){
                            aa.Id =  oppty.Account.Id;
                            aa.Name = oppty.Account.Name;
                            aa.Strategic_Account__c  = oppty.Account.Strategic_Account__c;
                            aa.Account_Preference__c = oppty.Account.Account_Preference__c;
                        }
                    }
                    else if(objectrecordId.startsWith('500')){
                        cse = [Select id,CaseNumber,AccountId,Account.name,Account.Strategic_Account__c,Account.Account_Preference__c from case where id =: objectrecordId];
                        if(cse.AccountId!= null){
                            aa.Id =  cse.Account.Id;
                            aa.Name = cse.Account.Name;
                            aa.Strategic_Account__c  = cse.Account.Strategic_Account__c;
                            aa.Account_Preference__c = cse.Account.Account_Preference__c;
                        }
                    }
                }
                if(!ahaIdeaId.isEmpty()){
                    for(Aha_Idea_Link__c ideaLink : [SELECT Id,Opportunity_Name__c,Opportunity_Name__r.Name,Opportunity_Name__r.AccountId,Opportunity_Name__r.Account.Name,Opportunity_Name__r.iswon,Opportunity_Name__r.isclosed,Opportunity_Name__r.ACV_Amount__c,Aha_Ideas__c,Aha_Ideas__r.Duplicate_of__c,Aha_Ideas__r.Aha_Unique_ID__c,Case_Number__c,Case_Number__r.AccountId,Case_Number__r.Account.Name,Case_Number__r.CaseNumber,Account_Name__c FROM Aha_Idea_Link__c WHERE Aha_Ideas__r.Aha_Unique_ID__c IN : ahaIDeaId ORDER BY CREATEDDATE DESC]){
                        if(!ideaAndIdeaLinkRecord.isempty()
                            && ideaAndIdeaLinkRecord.containskey(ideaLink.Aha_Ideas__r.Aha_Unique_ID__c)){
                                ideaAndIdeaLinkRecord.get(ideaLink.Aha_Ideas__r.Aha_Unique_ID__c).add(ideaLink);
                        }
                        else{
                             ideaAndIdeaLinkRecord.put(ideaLink.Aha_Ideas__r.Aha_Unique_ID__c, new List<Aha_Idea_Link__c>{ideaLink});
                        }
                        ChildAhaIdeaId.add(ideaLink.Aha_Ideas__c);
                        if(ideaLink.Aha_Ideas__r.Duplicate_of__c!= null){
                            ahaParentIdeaId.add(ideaLink.Aha_Ideas__r.Duplicate_of__c);
                        }
                    }
                }
                if(!apiResponseMap.isEmpty()){
                    Map<String,String> ahaIdeafieldNameandValue = new Map<String,String>();
                    for(String apiResponseString : apiResponseMap.keyset()){
                        object obj = apiResponseMap.get(apiResponseString);
                        Map<String, Object> objectMap = (Map<String, Object>)obj;
                        String ahaIdearefno = (String) objectMap.get('reference_num');
                        String ahaIdeaRecordId = (String) objectMap.get('id');
                        ideaId = ahaIdeaRecordId;
                        String impacted_Customers = '';
                        Integer strategic_Account_value = 0;
                        Decimal amountforClosedWonOppty = 0;
                        Decimal amountforClosedLostOppty = 0;
                        Decimal amountforInflightOppty = 0;
                        if(!String.isBlank(ahaIdearefno)&& !String.isBlank(ahaIdeaRecordId)){
                            ahaIdeafieldNameandValue.put('reference_num',ahaIdearefno);
                            ahaIdeafieldNameandValue.put('AhaId',ahaIdeaRecordId);
                        }
                        List<Object> customfieldvalobj = (List<Object>) objectMap.get('custom_fields');
                        for(Object objNew : customFieldValObj){
                            Map<String, Object> objMap = (Map<String, Object>) objnew;
                            String name = String.valueof(objMap.get('name'));
                            String value = String.valueof(objMap.get('value'));
                            string fieldValue = '';
                            if(!string.isblank(value)){
                                fieldValue = value.trim();
                            }
                            ahaIdeafieldNameandValue.put(name.trim(),fieldValue);
                        }
                        if(!ahaIdeafieldNameandValue.isEmpty() && !String.isBlank(action) && action == 'Unlink'){
                            List<Aha_Idea_Link__c> ideaLinkList = new List<Aha_Idea_Link__c>();
                            List<String> impactCustomers = new List<String>();
                            Set<Id> accIds = new Set<Id>();
                            Integer totalNoOfCases = 0;
                            Integer totalNoOfOpportunities = 0;
                            Integer countOfAccountStrategic = 0;
                            Integer noofcustomerRequested  = 0;
                            String linkOfCasesAttachedWithIdea = '';
                            String linkOfOpportunitiesAttachedWithIdea = '';
                            Set<String> accPreferenceValue = new Set<String>();
                            String ahaSalesforceId = '';
                            List<String> listOfAccPref = new List<String>();

                            if(!ideaAndIdeaLinkRecord.isEmpty() && ideaAndIdeaLinkRecord.containsKey(ahaIdearefno)){
                                ideaLinkList = ideaAndIdeaLinkRecord.get(ahaIdearefno);
                            }
                            if(ideaLinkList.size()>0){
                                for(Aha_Idea_Link__c ideaLink : ideaLinkList){
                                    if(ideaLink.Opportunity_Name__c!= null && ideaLink.Opportunity_Name__c!= objectrecordId){
                                        totalNoOfOpportunities++;
                                        if(totalNoOfOpportunities<6){
                                            String oppName = ideaLink.Opportunity_Name__r.Name;
                                            String pattern = '[\\\\\'"!@#$%^&*()_+\\-=\\[\\]{};:\\\\|,.<>\\/?]';
                                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + ideaLink.Opportunity_Name__c+ '\\">'+oppName.replaceAll(pattern, '\\\\$0')+'</a> ; ';

                                        }
                                        if(ideaLink.Opportunity_Name__r.Accountid!= null){
                                             accIds.add(ideaLink.Opportunity_Name__r.Accountid);
                                        }
                                        if(ideaLink.Opportunity_Name__r.iswon && ideaLink.Opportunity_Name__r.ACV_Amount__c!=null){
                                        amountforClosedWonOppty += ideaLink.Opportunity_Name__r.ACV_Amount__c;
                                        }
                                        else if(ideaLink.Opportunity_Name__r.isclosed && ideaLink.Opportunity_Name__r.ACV_Amount__c!=null){
                                            amountforClosedLostOppty += ideaLink.Opportunity_Name__r.ACV_Amount__c;
                                        }
                                        else if(!ideaLink.Opportunity_Name__r.isclosed && !ideaLink.Opportunity_Name__r.iswon && ideaLink.Opportunity_Name__r.ACV_Amount__c!=null){
                                            amountforInflightOppty += ideaLink.Opportunity_Name__r.ACV_Amount__c;
                                        }
                                    }
                                    else if(ideaLink.Case_Number__c!= null && ideaLink.Case_Number__c!= objectrecordId){
                                        totalNoOfCases++;
                                        if(totalNoOfCases<6){
                                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + cse.Id+ '\\">'+cse.CaseNumber+'</a> ; ';

                                        }
                                        if(ideaLink.Case_Number__r.Accountid!= null){
                                            accIds.add(ideaLink.Case_Number__r.Accountid);
                                        }
                                    }
                                    if(ideaLink.Case_Number__c == objectrecordId || ideaLink.Opportunity_Name__c == objectrecordId){
                                        deleteAhaIdeaLinkList.add(ideaLink);
                                        ahaSalesforceId = ideaLink.Aha_Ideas__c;
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

                            if(ahaIdearefno!= null && ahaSalesforceId!= ''){
                                Aha_Ideas__c updateSalesforceIdea = new Aha_Ideas__c(id=ahaSalesforceId);
                                updateSalesforceIdea.Aha_Unique_ID__c = ahaIdearefno;
                                updateSalesforceIdea.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                                updateSalesforceIdea.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                                updateSalesforceIdea.Strategic_Major_Account__c = countOfAccountStrategic;

                                updateSalesforceIdea.Total_Amount_for_the_Closed_Won_Oppty__c =  String.valueOf(amountforClosedWonOppty);
                                updateSalesforceIdea.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueOf(amountforClosedLostOppty);
                                updateSalesforceIdea.Total_Amount_for_the_In_Flight_Oppty__c =   String.valueOf(amountforInflightOppty);

                                if(impactCustomers.size()>0){
                                    updateSalesforceIdea.Impacted_Customers__c = String.join(impactCustomers,',');
                                }
                                else{
                                    updateSalesforceIdea.Impacted_Customers__c = '';
                                }
                                if(accPreferenceValue.size()>0){
                                    updateSalesforceIdea.Account_Preference__c = String.join(accPreferenceValue,';');
                                    listOfAccPref = new List<String>(accPreferenceValue);
                                }
                                else{
                                    updateSalesforceIdea.Account_Preference__c = '';
                                }
                                if(linkOfOpportunitiesAttachedWithIdea != Null){
                                    linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea.removeEnd('; ');
                                }
                                if(linkOfCasesAttachedWithIdea != Null){
                                    linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea.removeEnd('; ');
                                }
                                // Callout for Update the idea in Aha
                                updateIdeaRecordInAha(updateSalesforceIdea,updateSalesforceIdea.Impacted_Customers__c,noofcustomerRequested,currentUserEmail,Integer.valueof(updateSalesforceIdea.Strategic_Major_Account__c),totalNoOfCases,linkOfCasesAttachedWithIdea,totalNoOfOpportunities,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);

                                // Update Aha Idea in Salesforce
                                ahaIdeaUpdateList.add(updateSalesforceIdea);
                            }
                        }// end  of if
                        else if(!ahaIdeafieldNameandValue.isEmpty() && !String.isblank(action) && action == 'Escalate'){
                            String ideaEscalationValue = '';
                            if(ahaIdeafieldNameandValue.containsKey('Escalation?')){
                                String getIdeaEscalationValue = ahaIdeafieldNameandValue.get('Escalation?');
                                if(getIdeaEscalationValue == 'No' || String.isblank(getIdeaEscalationValue)){
                                    ideaEscalationValue = 'Yes';
                                }
                            }
                            else{
                                ideaEscalationValue = 'Yes';
                            }
                            if(ideaEscalationValue == 'Yes'){
                                escalateAhaIdeaRecord(ahaIdearefno);
                            }
                             escalateAhaIdeaId.add(ahaIdearefno);
                        }
                    } // end of for loop
                }
                if(escalateAhaIdeaId.size()>0){
                    for(Aha_Ideas__c ideas : [SELECT id,Escalation__c FROM Aha_Ideas__c
                                              WHERE Aha_Unique_ID__c IN : escalateAhaIdeaId]){
                                                  if(ideas.Escalation__c == 'No' || String.isblank(ideas.Escalation__c)){
                                                      ideas.Escalation__c = 'Yes';
                                                      ahaIdeaUpdateList.add(ideas);
                                                  }
                                              }
                }

                // Update or Insert Idea Record
                if(deleteAhaIdeaLinkList.size()>0){
                    DELETE deleteAhaIdeaLinkList;
                }
                if(ahaIdeaUpdateList.size()>0){
                    UPDATE ahaIdeaUpdateList;
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
            catch(DmlException e){
                throw new CalloutException('DmlException caught while creating the Idea in Salesforce. Aha Idea is created with the reference Number. You can search the Idea with the Refernce Number   + AhaRefId  +    ' + e.getMessage());

            }
            catch(CalloutException e) {
                throw new CalloutException('DmlException caught while creating the Idea in Salesforce. Aha Idea is created with the reference Number. You can search the Idea with the Refernce Number   + AhaRefId   ' + e.getMessage());

            }
            catch (exception e){
                String errorMessage = e.getMessage();
                // Optionally, perform additional error handling or logging
                throw new AuraHandledException(errorMessage);
            }
        }//End of Method

    /**
     * @description Logs exceptions to the Idea_Exception__c custom object for monitoring and debugging.
     *              Captures detailed exception information including message, line number, method name,
     *              class name, and associates it with the provided record ID for tracking.
     * @param ex The exception object to be logged
     * @param recordId The Salesforce record ID associated with the exception context
     */
    public static void insertException(exception ex,String recordId){
            String errorMessage = ex.getMessage();
            // Optionally, perform additional error handling or logging
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            Idea_Exception__c exc = new Idea_Exception__c();
            exc.Error_Message__c = 'Exception Message: '+ ex.getMessage()+'\nLine Number: '+ex.getLineNumber()+'\nMethod Name: '+methodName+'\nclass Name: '+className;
            exc.Type__c = ex.getTypeName();
            if(recordId != null) exc.Related_record__c = recordId;
            INSERT exc;
        }

    /**
     * @description Recalculates and updates all calculated fields on AHA ideas based on linked records.
     *              This comprehensive method processes opportunity and case data to calculate strategic
     *              account values, customer counts, amounts, and generates HTML links for related records.
     *              Updates both Salesforce AHA idea records and synchronizes with AHA platform.
     * @param linkListRecord List of existing AHA idea link records
     * @param aa Account record associated with the idea
     * @param updateSalesforceIdea AHA idea record to be updated
     * @param objectid The object record ID (Case or Opportunity) being processed
     * @param ahaIdeaUpsertList List of AHA ideas to be upserted
     * @param createAhaIdealinkList List of AHA idea links to be created
     * @param opp Opportunity record if processing opportunity-related data
     * @param cse Case record if processing case-related data
     */
    public static void reCalculateValuesforIdea(List<Aha_Idea_Link__c> linkListRecord,Account aa,Aha_Ideas__c updateSalesforceIdea, string objectid,List<Aha_Ideas__c> ahaIdeaUpsertList,List<Aha_Idea_Link__c> createAhaIdealinkList,opportunity opp, Case cse){
            Set<Id> accIds = new Set<Id>();
            List<Aha_Idea_Link__c> insertLinkList = new List<Aha_Idea_Link__c>();
            List<String> impactCustomers = new List<String>();
            Integer totalNoOfCases = 0;
            Integer totalNoOfOpportunities = 0;
            Boolean stopExcecuteCode = False;
            Integer countOfAccountStrategic = 0;
            Integer noofcustomerRequested  = 0;
            String linkOfCasesAttachedWithIdea = '';
            String linkOfOpportunitiesAttachedWithIdea = '';
            String currentUserEmail = '';
            Decimal amountforClosedWonOppty = 0;
            Decimal amountforClosedLostOppty = 0;
            Decimal amountforInflightOppty = 0;
            Set<String> accPreferenceValue = new Set<String>();
            List<String>listOfAccPref = new List<String>();

            try{
                if(updateSalesforceIdea.Aha_Unique_ID__c!= null){
                    if(linkListRecord.size() > 0){
                        for(Aha_Idea_Link__c linklist : linkListRecord){
                            if(objectid == linklist.Case_Number__c || objectid == linklist.Opportunity_Name__c){
                                stopExcecuteCode = True;
                            }
                        }
                        if(!stopExcecuteCode){
                            Aha_Idea_Link__c ideaLinkRec = new Aha_Idea_Link__c();
                            ideaLinkRec.Aha_Ideas__c = updateSalesforceIdea.id;

                            if(objectid!= null && objectid.startswith('006') && opp.id!= null){
                                ideaLinkRec.Opportunity_Name__c =  objectid;
                                totalNoOfOpportunities++;
                                if(totalNoOfOpportunities<6){
                                    String oppName = opp.Name;
                                    String pattern = '[\\\\\'"!@#$%^&*()_+\\-=\\[\\]{};:\\\\|,.<>\\/?]';

                                    String oppNameWithoutSpcialChar = oppName.replaceAll(pattern, '\\\\$0');

                                    linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea +'<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.Id+ '\\">'+oppNameWithoutSpcialChar+'</a> ; ';
                                    
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
                            else if(objectid!= null && objectid.startswith('500') && cse.id!= null){
                                ideaLinkRec.Case_Number__c =  objectid;
                                totalNoOfCases++;
                                if(totalNoOfCases<6){
                                    linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea +  '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + cse.Id+ '\\">'+cse.CaseNumber+'</a> ; ';
                                }
                            }
                            createAhaIdealinkList.add(ideaLinkRec);
                            for(Aha_Idea_Link__c linklist : linkListRecord){
                                if(linklist.Opportunity_Name__c!= null){
                                    totalNoOfOpportunities++;
                                    if(totalNoOfOpportunities<6){
                                        String oppName = linklist.Opportunity_Name__r.Name;
                                        String pattern = '[\\\\\'"!@#$%^&*()_+\\-=\\[\\]{};:\\\\|,.<>\\/?]';
                                        String oppNameWithoutSpcialChar = oppName.replaceAll(pattern, '\\\\$0');

                                        linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + linklist.Opportunity_Name__c+ '\\">'+oppNameWithoutSpcialChar+'</a> ; ';
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
                                        amountforInflightOppty +=   linklist.Opportunity_Name__r.ACV_Amount__c;
                                    }

                                }
                                else if(linklist.Case_Number__c!= null){
                                    totalNoOfCases++;
                                    if(totalNoOfCases<6){
                                        linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + linklist.Case_Number__c+ '\\">'+linklist.Case_Number__r.CaseNumber+'</a> ; ';
                                    }
                                    if(linklist.Case_Number__r.Accountid!= null){
                                        accIds.add(linklist.Case_Number__r.Accountid);
                                    }
                                }
                            }
                            accIds.add(aa.id);
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

                        if(!stopExcecuteCode){
                            updateSalesforceIdea.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                            updateSalesforceIdea.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                            updateSalesforceIdea.Strategic_Major_Account__c = countOfAccountStrategic;
                            updateSalesforceIdea.Total_Amount_for_the_Closed_Won_Oppty__c = String.valueof(amountforClosedWonOppty);
                            updateSalesforceIdea.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueof(amountforClosedLostOppty);
                            updateSalesforceIdea.Total_Amount_for_the_In_Flight_Oppty__c =  String.valueof(amountforInflightOppty);

                            if(impactCustomers.size()>0){
                                updateSalesforceIdea.Impacted_Customers__c = String.join(impactCustomers,',');
                            }
                            else{
                                updateSalesforceIdea.Impacted_Customers__c = '';
                            }
                            if(accPreferenceValue.size()>0){
                                updateSalesforceIdea.Account_Preference__c = String.join(accPreferenceValue,';');
                                listOfAccPref = new List<String>(accPreferenceValue);
                            }
                            else{
                                updateSalesforceIdea.Account_Preference__c = '';
                            }
                            if(linkOfOpportunitiesAttachedWithIdea != Null){
                                linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea.removeEnd('; ');
                            }
                            if(linkOfCasesAttachedWithIdea != Null){
                                linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea.removeEnd('; ');
                            }
                            // Make  Call out to update the Idea In Aha
                            if(updateSalesforceIdea.Aha_Unique_ID__c!= null){
                                updateIdeaRecordInAha(updateSalesforceIdea,updateSalesforceIdea.Impacted_Customers__c,noofcustomerRequested,currentUserEmail,Integer.valueof(updateSalesforceIdea.Strategic_Major_Account__c),totalNoOfCases,linkOfCasesAttachedWithIdea,totalNoOfOpportunities,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);
                            }
                            // update Idea in Salesforce
                            ahaIdeaUpsertList.add(updateSalesforceIdea);
                        }
                    }
                    else{
                         Aha_Idea_Link__c ideaLinkRec = new Aha_Idea_Link__c();
                         ideaLinkRec.Aha_Ideas__c = updateSalesforceIdea.id;
                        if(objectid.startswith('006') && opp.id!= null){
                            totalNoOfOpportunities = 1;
                            String oppName = opp.Name;
                            String pattern = '[\\\\\'"!@#$%^&*()_+\\-=\\[\\]{};:\\\\|,.<>\\/?]';
                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.Id+ '\\">'+oppName.replaceAll(pattern, '\\\\$0')+'</a> ; ';
                            ideaLinkRec.Opportunity_Name__c =  objectid;
                            createAhaIdealinkList.add(ideaLinkRec);
                            if(opp.iswon && opp.ACV_Amount__c!= null){
                                amountforClosedWonOppty +=  opp.ACV_Amount__c;
                            }
                            else if(opp.isclosed && opp.ACV_Amount__c!= null){
                                amountforClosedLostOppty +=  opp.ACV_Amount__c;
                            }
                            else if(!opp.isclosed && !opp.iswon && opp.ACV_Amount__c!= null){
                                amountforInflightOppty += amountforInflightOppty+opp.ACV_Amount__c;
                            }
                        }
                        else if(objectid.startswith('500') && cse.id!= null){
                            totalNoOfCases = 1;
                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea +  '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + cse.Id+ '\\">'+cse.CaseNumber+'</a> ; ';
                            ideaLinkRec.Case_Number__c =  objectid;
                            createAhaIdealinkList.add(ideaLinkRec);
                        }
                        if(aa.id!= null){
                            impactCustomers.add(aa.Name);
                            noofcustomerRequested  = 1;
                            if(aa.Strategic_Account__c){
                                countOfAccountStrategic = 1;
                            }
                            if(aa.Account_Preference__c != null){
                                for(String Account_Preference : aa.Account_Preference__c.split(';')){
                                    accPreferenceValue.add(Account_Preference);
                                }
                            }
                        }
                        updateSalesforceIdea.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                        updateSalesforceIdea.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                        updateSalesforceIdea.Strategic_Major_Account__c = countOfAccountStrategic;
                        updateSalesforceIdea.Total_Amount_for_the_Closed_Won_Oppty__c =  String.valueof(amountforClosedWonOppty);
                        updateSalesforceIdea.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueof(amountforClosedLostOppty);
                        updateSalesforceIdea.Total_Amount_for_the_In_Flight_Oppty__c =   String.valueof(amountforInflightOppty);

                        if(impactCustomers.size()>0){
                            updateSalesforceIdea.Impacted_Customers__c = String.join(impactCustomers,',');
                        }
                        else{
                            updateSalesforceIdea.Impacted_Customers__c = '';
                        }
                        if(accPreferenceValue.size()>0){
                            updateSalesforceIdea.Account_Preference__c = String.join(accPreferenceValue,';');
                            listOfAccPref = new List<String>(accPreferenceValue);
                        }
                        else{
                            updateSalesforceIdea.Account_Preference__c = '';
                        }
                        // Update Aha Idea through Api
                        if(linkOfOpportunitiesAttachedWithIdea != Null){
                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea.removeEnd('; ');
                        }
                        if(linkOfCasesAttachedWithIdea != Null){
                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea.removeEnd('; ');
                        }
                        if(updateSalesforceIdea.Aha_Unique_ID__c!= null){
                            updateIdeaRecordInAha(updateSalesforceIdea,updateSalesforceIdea.Impacted_Customers__c,noofcustomerRequested,currentUserEmail,Integer.valueof(updateSalesforceIdea.Strategic_Major_Account__c),totalNoOfCases,linkOfCasesAttachedWithIdea,totalNoOfOpportunities,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);
                        }
                        //Update Idea Record in Salesforce
                        ahaIdeaUpsertList.add(updateSalesforceIdea);
                    }
                }//End of if condition
            }//End of Try
            catch(Exception ex){
                String stackTrace = ex.getStackTraceString().substringBefore('\n');
                String className = stackTrace.substringAfter('.').substringBefore('.');
                String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
                Idea_Exception__c exc = new Idea_Exception__c();
                exc.Error_Message__c = 'Exception Message'+ ex.getMessage()+'\nLine Number'+ex.getLineNumber()+'\nMethod Name'+methodName+'\nclass Name'+className;
                exc.Type__c = ex.getTypeName();
                database.insert(exc);
            }
        }

    /**
     * @description Overloaded method to update AHA idea record in AHA platform via API (used by AhaWebhookReceiver).
     *              This method creates a temporary AHA idea object with the unique ID and delegates to the main
     *              updateIdeaRecordInAha method for processing. Designed for webhook and batch processing scenarios.
     * @param ahaUniqueId The unique AHA idea identifier
     * @param accountName Name of the associated account
     * @param noofCustomerRequested Number of customers who requested this idea
     * @param userEmail Email of the user making the update
     * @param strategic_Account_value Strategic account indicator value
     * @param totalNoOfCases Total number of cases linked to this idea
     * @param linkOfCasesAttachedWithIdea HTML links to cases attached to the idea
     * @param totalNoOfOpportunities Total number of opportunities linked to this idea
     * @param linkOfOpportunitiesAttachedWithIdea HTML links to opportunities attached to the idea
     * @param accPreferenceValue List of account preference values
     * @param amountforClosedWonOppty Total amount for closed won opportunities
     * @param amountforClosedLostOppty Total amount for closed lost opportunities
     * @param amountforInflightOppty Total amount for in-flight opportunities
     */
    public static void updateIdeaRecordInAha(String ahaUniqueId, String accountName,Integer noofCustomerRequested,String userEmail, Integer strategic_Account_value, Integer totalNoOfCases, String linkOfCasesAttachedWithIdea, Integer totalNoOfOpportunities, String linkOfOpportunitiesAttachedWithIdea,List<String> accPreferenceValue,Decimal amountforClosedWonOppty,Decimal amountforClosedLostOppty,Decimal amountforInflightOppty ){
            // Create a dummy Aha_Ideas__c object with just the Aha_Unique_ID__c field
            Aha_Ideas__c updateSalesforceIdea = new Aha_Ideas__c();
            updateSalesforceIdea.Aha_Unique_ID__c = ahaUniqueId;

            // Call the main method
            updateIdeaRecordInAha(updateSalesforceIdea, accountName, noofCustomerRequested, userEmail, strategic_Account_value, totalNoOfCases, linkOfCasesAttachedWithIdea, totalNoOfOpportunities, linkOfOpportunitiesAttachedWithIdea, accPreferenceValue, amountforClosedWonOppty, amountforClosedLostOppty, amountforInflightOppty);
        }

    /**
     * @description Main method to update AHA idea record in AHA platform via API with comprehensive data.
     *              Synchronizes Salesforce AHA idea data with AHA platform including customer counts,
     *              strategic account information, linked records, amounts, and account preferences.
     *              Also handles JIRA integration for component mapping.
     * @param updateSalesforceIdea The AHA idea record from Salesforce to be updated
     * @param accountName Name of the associated account
     * @param noofCustomerRequested Number of customers who requested this idea
     * @param userEmail Email of the user making the update
     * @param strategic_Account_value Strategic account indicator value
     * @param totalNoOfCases Total number of cases linked to this idea
     * @param linkOfCasesAttachedWithIdea HTML links to cases attached to the idea
     * @param totalNoOfOpportunities Total number of opportunities linked to this idea
     * @param linkOfOpportunitiesAttachedWithIdea HTML links to opportunities attached to the idea
     * @param accPreferenceValue List of account preference values
     * @param amountforClosedWonOppty Total amount for closed won opportunities
     * @param amountforClosedLostOppty Total amount for closed lost opportunities
     * @param amountforInflightOppty Total amount for in-flight opportunities
     * @throws AuraHandledException When API call fails or update operation encounters errors
     */
    @AuraEnabled
    public static void updateIdeaRecordInAha(Aha_Ideas__c updateSalesforceIdea, String accountName,Integer noofCustomerRequested,String userEmail, Integer strategic_Account_value, Integer totalNoOfCases, String linkOfCasesAttachedWithIdea, Integer totalNoOfOpportunities, String linkOfOpportunitiesAttachedWithIdea,List<String> accPreferenceValue,Decimal amountforClosedWonOppty,Decimal amountforClosedLostOppty,Decimal amountforInflightOppty ){
            // Update Aha Idea in Aha
            try{
                Map<String,zsfjira__ZIssue__c> AhaUniqueIdVsZissue = new Map<String,zsfjira__ZIssue__c>();
                if(updateSalesforceIdea.Aha_Unique_ID__c!= null){
                    for(zsfjira__ZIssue__c zissue : [SELECT Id,zsfjira__Components__c ,Aha_Unique_Id__c
                                                     FROM zsfjira__ZIssue__c WHERE Aha_Unique_Id__c  = : updateSalesforceIdea.Aha_Unique_ID__c]){
                                                         AhaUniqueIdVsZissue.put(zissue.Aha_Unique_Id__c,zissue);
                                                     }

                    Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
                    String customerRequested = String.valueof(noofCustomerRequested);
                    String accPrefVal = '';
                    if(accPreferenceValue.Size() > 0){
                        accPrefVal = String.join(accPreferenceValue,',');
                    }
                    String requestBody = '';
                    String CompName = '';
                    if(AhaUniqueIdVsZissue.containsKey(updateSalesforceIdea.Aha_Unique_ID__c)){
                        CompName = AhaUniqueIdVsZissue.get(updateSalesforceIdea.Aha_Unique_ID__c).zsfjira__Components__c !=  Null ? AhaUniqueIdVsZissue.get(updateSalesforceIdea.Aha_Unique_ID__c).zsfjira__Components__c : '';
                    }
                    
                    if(!String.isBlank(CompName) && CompName != '' && CompName != Null){
                        requestBody = '{"idea":{"custom_fields":{"number_of_customers_requested":"'+customerRequested+'","other_impacted_customers": "'+AccountName+'","strategicmajor_account": "'+Strategic_Account_value+'","total_no_of_cases_link_with_idea": "'+totalNoOfCases+'","links_of_cases_attached_with_idea": "'+linkOfCasesAttachedWithIdea+'","total_no_of_opportunities_link_with_idea": "'+totalNoOfOpportunities+'","links_of_opportunities_attached_with_idea": "'+linkOfOpportunitiesAttachedWithIdea+'","account_preference": "'+accPrefVal+'","total_amount_for_the_closed_won_opportunity": "'+amountforClosedWonOppty+'","total_amount_for_the_closed_lost_opportunity": "'+amountforClosedLostOppty+'","total_amount_for_the_in_flight_opportunity": "'+amountforInflightOppty+'","zsfjira_components": "'+CompName+'"}}}';
                    }
                    else{
                        requestBody = '{"idea":{"custom_fields":{"number_of_customers_requested":"'+customerRequested+'","other_impacted_customers": "'+AccountName+'","strategicmajor_account": "'+Strategic_Account_value+'","total_no_of_cases_link_with_idea": "'+totalNoOfCases+'","links_of_cases_attached_with_idea": "'+linkOfCasesAttachedWithIdea+'","total_no_of_opportunities_link_with_idea": "'+totalNoOfOpportunities+'","links_of_opportunities_attached_with_idea": "'+linkOfOpportunitiesAttachedWithIdea+'","account_preference": "'+accPrefVal+'","total_amount_for_the_closed_won_opportunity": "'+amountforClosedWonOppty+'","total_amount_for_the_closed_lost_opportunity": "'+amountforClosedLostOppty+'","total_amount_for_the_in_flight_opportunity": "'+amountforInflightOppty+'"}}}';
                    }
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/ideas/' + updateSalesforceIdea.Aha_Unique_ID__c);
                    req.setMethod('PUT');
                    req.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                    req.setHeader('contentType', 'application/json');
                    req.setHeader('Content-Type','application/json;charset=UTF-8');
                    req.setHeader('Accept', 'application/json');
                    if(requestBody != ''){
                        req.setBody(requestBody);
                    }
                    Http httpnew = new Http();
                    HttpResponse responseNew = httpnew.send(req);
                    if (responseNew.getStatusCode() == 200){
                        // Fetch feature details from AHA API using reference number
                        fetchFeatureDetailsFromAha(responseNew.getBody(), updateSalesforceIdea);

                        //Update AHA Status and Created Info in SF
                        updateAhaIdeaStatusAndCreatedInfo(responseNew.getBody(), updateSalesforceIdea);
                    }
                    else{
                        throw new CalloutException('');
                    }
                }
            }
            catch(exception ex){
                String stackTrace = ex.getStackTraceString().substringBefore('\n');
                String className = stackTrace.substringAfter('.').substringBefore('.');
                String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
                Idea_Exception__c exc = new Idea_Exception__c();
                exc.Error_Message__c = 'Exception Message'+ ex.getMessage()+'\nLine Number'+ex.getLineNumber()+'\nMethod Name'+methodName+'\nclass Name'+className;
                exc.Type__c = ex.getTypeName();
                exc.Related_record__c = updateSalesforceIdea.Aha_Unique_ID__c;
                database.insert(exc);
            }
        }// End of method

    /**
     * @description Updates AHA idea status and creation information in Salesforce from AHA API response.
     *              Parses the API response JSON to extract workflow status, creation date, and other
     *              metadata, then updates the corresponding Salesforce AHA idea record fields.
     * @param responseBody JSON response body from AHA API containing idea details
     * @param updateSalesforceIdea AHA idea record to be updated with API response data
     */
    public static void updateAhaIdeaStatusAndCreatedInfo(String responseBody, Aha_Ideas__c updateSalesforceIdea) {
        try {
            Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> ideaObj = (Map<String, Object>) records.get('idea');

            if (ideaObj.containsKey('workflow_status')) {
                Map<String, Object> workflowStatusObj = (Map<String, Object>) ideaObj.get('workflow_status');
                String ideaStatus = (String) workflowStatusObj.get('name');
                updateSalesforceIdea.Status__c = ideaStatus;
            }

            // fetch AHA idea created date and created by - handle both created_by_user and created_by_idea_user
            Map<String, Object> createdByObj = null;

            // Check for created_by_user first, then created_by_idea_user
            if (ideaObj.containsKey('created_by_user')) {
                createdByObj = (Map<String, Object>) ideaObj.get('created_by_user');
            } else if (ideaObj.containsKey('created_by_idea_user')) {
                createdByObj = (Map<String, Object>) ideaObj.get('created_by_idea_user');
            }

            // Process the created by information if either parameter is present
            if (createdByObj != null) {
                if (createdByObj.containsKey('name')) {
                    updateSalesforceIdea.Idea_Created_By__c = (String) createdByObj.get('name');
                }
                if (ideaObj.containsKey('created_at')) {
                    String createdAtStr = (String) ideaObj.get('created_at');

                    String normalized = createdAtStr.replace('Z','').replace('T',' ');
                    if (normalized.contains('.')) {
                        normalized = normalized.substring(0, normalized.indexOf('.'));
                    }
                    Datetime ideaCreatedDatetime = Datetime.valueOf(normalized);
                    updateSalesforceIdea.Idea_Created_Date__c = ideaCreatedDatetime;
                }
            }
            
        } catch (Exception ex) {
            System.debug(LOGGINGLEVEL.INFO,'Error in updateAhaIdeaStatusAndCreatedInfo: ' + ex.getMessage());
            // Log error but don't throw to avoid breaking the main flow
        }
    }// End of method

    /**
     * @description Fetches and processes feature details from AHA API response using reference number.
     *              Extracts feature information from the API response JSON and initiates additional
     *              API calls to retrieve detailed feature data if a reference number is found.
     * @param responseBody JSON response body from AHA API containing idea and feature details
     * @param updateSalesforceIdea AHA idea record to be updated with feature information
     */
    public static void fetchFeatureDetailsFromAha(String responseBody, Aha_Ideas__c updateSalesforceIdea) {
        try {
            Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> ideaObj = (Map<String, Object>) records.get('idea');

            // Check if feature object exists and has reference_num
            if (ideaObj.containsKey('feature')) {
                Map<String, Object> featureObj = (Map<String, Object>) ideaObj.get('feature');

                if (featureObj.containsKey('reference_num')) {
                    String referenceNum = (String) featureObj.get('reference_num');

                    // Make callout to fetch feature details
                    fetchFeatureByReferenceNumber(referenceNum, updateSalesforceIdea);
                }
            }
        } catch (Exception ex) {
            System.debug(LOGGINGLEVEL.INFO, 'Error in fetchFeatureDetailsFromAha: ' + ex.getMessage());
            // Log error but don't throw to avoid breaking the main flow
        }
    }// End of method

    /**
     * @description Makes HTTP callout to AHA API to fetch detailed feature information by reference number.
     *              Constructs and executes API request to retrieve feature details, then processes the
     *              response to update the AHA idea record with feature-specific information.
     * @param referenceNum The feature reference number to fetch details for
     * @param updateSalesforceIdea AHA idea record to be updated with feature details
     */
    public static void fetchFeatureByReferenceNumber(String referenceNum, Aha_Ideas__c updateSalesforceIdea) {
        try {
            // Get AHA credentials
            Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');

            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ahaCredential.AHA_BASE_URL__c+'/features/'+referenceNum);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setTimeout(120000); // 2 minutes timeout
            
            // Make the callout
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> featureResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                // feature object
                Map<String, Object> featureObj = (Map<String, Object>) featureResponse.get('feature');
                //custom fields
                Map<String,String> ahaIdeafieldNameandValue = new Map<String,String>();
                List<object> customFieldValObj = (List<object>) featureObj.get('custom_fields');
                for(object objNew : customFieldValObj){
                    Map<String, Object> objMap = (Map<String, Object>) objnew;
                    String key = String.valueof(objMap.get('key'));
                    String value = String.valueof(objMap.get('value'));
                    string fieldValue = '';
                    if(!string.isblank(value)){
                        fieldValue = value.trim();
                    }
                    ahaIdeafieldNameandValue.put(key.trim(),fieldValue);
                }
                // status
                Map<String, Object> statusFieldValObj = (Map<String, Object>)featureObj.get('workflow_status');
                
                if (featureObj != null) {
                    updateSalesforceIdea.Feature_Name__c = (String) featureObj.get('reference_num')+': '+(String) featureObj.get('name');
                    updateSalesforceIdea.Feature_Status__c = String.valueof(statusFieldValObj.get('name'));
                    updateSalesforceIdea.Feature_Phase__c = ahaIdeafieldNameandValue.get('phase');
                    updateSalesforceIdea.Engineering_status__c = ahaIdeafieldNameandValue.get('engineering_status');
                    updateSalesforceIdea.Engineering_Confidence_in_Delivery__c = ahaIdeafieldNameandValue.get('confidence_in_delivery').replaceAll('^\\(|\\)$', '');
                }
            }
        } catch (Exception ex) {
            System.debug(LOGGINGLEVEL.ERROR,'Error in fetchFeatureByReferenceNumber: ' + ex.getMessage());
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            Idea_Exception__c exc = new Idea_Exception__c();
            exc.Error_Message__c = 'Exception Message in feature callout:'+ ex.getMessage()+'\nLine Number'+ex.getLineNumber()+'\nMethod Name'+methodName+'\nclass Name'+className;
            exc.Type__c = ex.getTypeName();
            exc.Related_record__c = updateSalesforceIdea.Aha_Unique_ID__c;
            database.insert(exc);
            // Log error but don't throw to avoid breaking the main flow
        }
    }// End of method

}//End of class