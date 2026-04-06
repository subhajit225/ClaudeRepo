/**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Jira Ticket  :   AS-15, AS-13, AS-11, AS-9, AS-10,
    * @Description  :   Web Service Class for updating the Records of Aha Idea in Salesforce.
    *this apex class invokes every time on single field update on Aha.
    * @TestClass    :   AhaWebhookReceiver_Test
    */
    @RestResource(urlMapping='/webhook/*')
    global class AhaWebhookReceiver{

        public class InsertIdeaandLinkRecords {
            @AuraEnabled public Aha_Ideas__c sfdcidea { get; set; }
            @AuraEnabled public Map<String,Set<String>> AhaIdAndSetCaseids { get; set; }
            @AuraEnabled public Map<String,zsfjira__ZIssue__c> ZissueRec { get; set; }
        }
        /**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Description  :   getting the webhook response from aha.
    */
        @HttpPost
        global static void receiveWebhook(){
            String payload,ideaId,ahaIdeaUrl;
            try{
                RestResponse response;
                //getting the response from aha
                RestRequest request = RestContext.request;
                response = RestContext.response;
                payload = request.requestBody.toString();
                Object ahaRecordList = (Object)JSON.deserializeUntyped(payload);
                Map < String , Object > mapstr = (Map < String , Object > ) ahaRecordList;
                Map < String , Object > prodMap = (Map < String , Object > ) mapstr.get('audit');
                for (String s: (Set < String > ) prodMap.keySet()){
                    if (s == 'auditable_url' && prodMap.containsKey('auditable_url') && prodMap.get('auditable_url') != Null) {
                        ahaIdeaUrl = String.valueOf(prodMap.get('auditable_url'));
                    }
                    if (s == 'associated_id' && prodMap.containsKey('associated_id') && prodMap.get('associated_id') != Null) {
                        ideaId = String.valueOf(prodMap.get('associated_id'));
                    }
                    else if(s == 'auditable_id' && prodMap.containsKey('auditable_id') && prodMap.get('auditable_id') != Null){
                        ideaId = String.valueOf(prodMap.get('auditable_id'));
                    }
                }
                if(ideaId != null){
                    List<Aha_Ideas__c> ahaIdeaRecords = New List<Aha_Ideas__c>();
                    if(ahaIdeaUrl != null && ahaIdeaUrl.contains('/')){
                        String[] ahaId = ahaIdeaUrl.split('/');
                        String externalUniqueId = ideaId+ahaId[ahaId.size() - 1];
                        // getting the aha idea from SFDC
                        ahaIdeaRecords = [SELECT Id,OwnerId,Aha_Idea_Owner__c,PM_Response__c,Feature_Target_Release__c,Feature_Reference__c,
                                          Engineering_Reference_Number__c,Duplicate_of__c, Name, CreatedDate,
                                          CreatedById, LastModifiedDate, LastModifiedById,Aha_Idea_Number__c,
                                          Status__c, Aha_Idea_Origin__c, Aha_Unique_ID__c, Business_Case_Value__c,
                                          Creator_Proposed_Solution__c, Escalation__c, For_Workspace__c,
                                          Idea_Description__c,Problem_Statement__c, Product_Area__c,
                                          Strategic_Major_Account__c, Product_Component__c,Impacted_Customers__c,
                                          Idea_Tags__c,External_Unique_Id__c, Idea_Category__c
                                          FROM Aha_Ideas__c WHERE External_Unique_Id__c =: externalUniqueId
                                          ORDER BY Createddate DESC  LIMIT 1];

                    }
                    else{
                        ahaIdeaRecords = [SELECT Id,OwnerId,Aha_Idea_Owner__c,PM_Response__c,Feature_Target_Release__c,Feature_Reference__c,
                                          Engineering_Reference_Number__c,Duplicate_of__c, Name, CreatedDate,
                                          CreatedById, LastModifiedDate, LastModifiedById,Aha_Idea_Number__c,
                                          Status__c, Aha_Idea_Origin__c, Aha_Unique_ID__c, Business_Case_Value__c,
                                          Creator_Proposed_Solution__c, Escalation__c, For_Workspace__c,
                                          Idea_Description__c,Problem_Statement__c, Product_Area__c,
                                          Strategic_Major_Account__c, Product_Component__c,Impacted_Customers__c,
                                          Idea_Tags__c,External_Unique_Id__c, Idea_Category__c
                                          FROM Aha_Ideas__c WHERE Aha_Idea_Number__c =: ideaId
                                          ORDER BY Createddate DESC  LIMIT 1];
                    }
                    if(ahaIdeaRecords.size() > 0){
                        // getting the record from Aha
                        Map<String , Object> recordMap = ManageAhaIdeaHelper.getAhaIdeaRecordData(ahaIdeaRecords[0].Aha_Unique_ID__c);
                        if(!recordMap.isEmpty()){
                            updateSalesforceIdeaRecord(recordMap,ahaIdeaRecords);
                        }
                    }
                }
                response.statusCode = 200;
                response.responseBody = Blob.valueOf('Record Updated Successfully');
            }
            catch(exception ex){
                ManageAhaIdeaHelper.insertException(ex,ideaId);
                system.debug('Exeption__'+ 'Exception Message: '+ ex.getMessage()+'\nLine Number: '+ex.getLineNumber());
            }
        }//End of Method

        /**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Description  :   //updating the record of aha idea in Salesforce.
    */
        public static void updateSalesforceIdeaRecord(Map<String , Object> apiResponseMap, List<Aha_Ideas__c> ahaIdeaRecord){
            Map<string , Aha_Ideas__c> exsistingAhaIdeaRecordMap = new Map<String , Aha_Ideas__c>();
            List<Aha_Ideas__c> childAhaIdeaList = New List<Aha_Ideas__c>();
            String DupId;
            Map<String, String> ahaIdeaIdVsStatusMap = New Map<String, String>();
            for(Aha_Ideas__c idea : ahaIdeaRecord){
                exsistingAhaIdeaRecordMap.put(idea.Aha_Idea_Number__c,idea);
            }
            if(!apiResponseMap.isEmpty()){
                List<Aha_Ideas__c> ahaIdeaUpdateList = new List<Aha_Ideas__c>();
                List<Aha_Ideas__c> ahaIdeaList = New List<Aha_Ideas__c>();
                Set<Id> duplicateIdeaSet = New Set<Id>();
                Boolean isDuplicate = False;
                Map<String, Object> featureMap = New Map<String, Object> ();
                Map<String,String> DuplicateAhaIdVsUniqueKeyMap = new Map<String,String>();
                Map<String,String> ahaIdeafieldNameandValue = new Map<String,String>();
                Map<String,String> AhaDuplicateIdVsAhaIdMap = new Map<String,String>();
                Map<String,String> AhaIdVsDuplicateIdeaIdMap = new Map<String,String>();
                for(String ApiResponseString : apiResponseMap.keyset()){
                    object obj = apiResponseMap.get(ApiResponseString);
                    Map<String, Object> objectMap = (Map<String, Object>)obj;
                    String ahaIdeaRecordId = (String) objectMap.get('id');
                    Map<String , Object> duplicateOfMap = (Map<String , Object>)objectMap.get('duplicate_of');
                    //getting the parent record in Salesforce
                    if(duplicateOfMap != Null && duplicateOfMap.size()>0
                       && !String.isEmpty(String.valueof(duplicateOfMap.get('reference_num')))){
                           String dupliIdeaId = string.valueof(duplicateOfMap.get('reference_num'));
                           if(dupliIdeaId != Null){
                               DupId = dupliIdeaId;
                               AhaDuplicateIdVsAhaIdMap.put(dupliIdeaId,ahaIdeaRecordId);
                           }
                       }
                }
                if(AhaDuplicateIdVsAhaIdMap.size() > 0){
                    for(Aha_Ideas__c ahaIdea : [SELECT Id, Aha_Unique_ID__c,PM_Response__c,Idea_Tags__c,Aha_Idea_Number__c,Duplicate_of__c
                                                FROM Aha_Ideas__c WHERE Aha_Unique_ID__c IN : AhaDuplicateIdVsAhaIdMap.keySet()]){
                                                    if(AhaDuplicateIdVsAhaIdMap.ContainsKey(ahaIdea.Aha_Unique_ID__c)){
                                                        AhaIdVsDuplicateIdeaIdMap.put(AhaDuplicateIdVsAhaIdMap.get(ahaIdea.Aha_Unique_ID__c),ahaIdea.Id);
                                                        DuplicateAhaIdVsUniqueKeyMap.put(ahaIdea.Id,ahaIdea.Aha_Unique_ID__c);
                                                    }
                                                }
                }
                for(String ApiResponseString : apiResponseMap.keyset()){
                    object obj = apiResponseMap.get(ApiResponseString);
                    Map<String, Object> objectMap = (Map<String, Object>)obj;
                    String ahaIdeaRecordId = (String) objectMap.get('id');
                    String ahaIdeaName = (String) objectMap.get('name');
                    String ahaIdeaVoteCount = String.valueOf(objectMap.get('votes'));
                    if(!exsistingAhaIdeaRecordMap.isEmpty() ||  exsistingAhaIdeaRecordMap.containskey(ahaIdeaRecordId)){
                        Aha_Ideas__c newAhaIdea = exsistingAhaIdeaRecordMap.get(ahaIdeaRecordId);
                        Map<String, Object> descrecords = (Map<String, Object>)objectMap.get('description');
                        Map<String, Object> statusMap = (Map<String, Object>)objectMap.get('workflow_status');
                        featureMap = (Map<String, Object>)objectMap.get('feature');
                        Map<String, Object> AhaOwnerMap = (Map<String, Object>)objectMap.get('assigned_to_user');
                        List<Object> customfieldvalobj = (List<Object>) objectMap.get('custom_fields');
                        //getting the custom field value in Salesforce
                        for(Object objnew : customfieldvalobj){
                            Map<String, Object> objMap = (Map<String, Object>) objnew;
                            String name = String.valueof(objMap.get('name'));
                            String value = String.valueof(objMap.get('value'));
                            String fieldvalue = '';
                            if(!String.isblank(value)){
                                fieldvalue = value.trim();
                            }
                            if(name == 'PM Response'){
                                ahaIdeafieldNameandValue.put(String.valueof(objMap.get('name')),String.valueof(objMap.get('body')));
                            }
                            else{
                                ahaIdeafieldNameandValue.put(name.trim(),fieldvalue);
                            }
                        }
                        //updating the name of Idea in Salesforce
                        if(ahaIdeaName != Null && newAhaIdea.Name != ahaIdeaName){
                            newAhaIdea.Name = ahaIdeaName.length()>= 80 ? ahaIdeaName.substring(0,75) + '...' :ahaIdeaName;
                        }
                        //updating the parentId of Idea in Salesforce
                        if(AhaIdVsDuplicateIdeaIdMap.ContainsKey(newAhaIdea.Aha_Idea_Number__c)
                           && newAhaIdea.Duplicate_of__c != AhaIdVsDuplicateIdeaIdMap.get(newAhaIdea.Aha_Idea_Number__c)){
                               if(newAhaIdea.Duplicate_of__c != Null){
                                   duplicateIdeaSet.add(newAhaIdea.Duplicate_of__c);
                               }
                               newAhaIdea.Duplicate_of__c = AhaIdVsDuplicateIdeaIdMap.get(newAhaIdea.Aha_Idea_Number__c);
                               duplicateIdeaSet.add(AhaIdVsDuplicateIdeaIdMap.get(newAhaIdea.Aha_Idea_Number__c));
                               duplicateIdeaSet.add(newAhaIdea.Id);
                           }
                        else{
                            if(AhaIdVsDuplicateIdeaIdMap.isEmpty() && newAhaIdea.Duplicate_of__c !=  null){
                                duplicateIdeaSet.add(newAhaIdea.Duplicate_of__c);
                                duplicateIdeaSet.add(newAhaIdea.Id);
                                newAhaIdea.Duplicate_of__c = null;
                            }
                        }
                        if(ahaIdeafieldNameandValue.containsKey('Business Case/Value')
                           && newAhaIdea.Business_Case_Value__c != ahaIdeafieldNameandValue.get('Business Case/Value')){
                               newAhaIdea.Business_Case_Value__c = ahaIdeafieldNameandValue.get('Business Case/Value');
                           }
                        if(ahaIdeafieldNameandValue.containsKey('Creator Proposed Solution')
                           && newAhaIdea.Creator_Proposed_Solution__c != ahaIdeafieldNameandValue.get('Creator Proposed Solution')){
                               newAhaIdea.Creator_Proposed_Solution__c = ahaIdeafieldNameandValue.get('Creator Proposed Solution');
                           }
                        if(ahaIdeafieldNameandValue.containsKey('Escalation?')
                           && newAhaIdea.Escalation__c != ahaIdeafieldNameandValue.get('Escalation?')){
                               newAhaIdea.Escalation__c = ahaIdeafieldNameandValue.get('Escalation?');
                               List<String> fieldValueList = ahaIdeafieldNameandValue.get('Escalation?').split(';');

                           }
                        if(ahaIdeafieldNameandValue.containsKey('For Workspace')
                           && newAhaIdea.For_Workspace__c != ahaIdeafieldNameandValue.get('For Workspace')){
                               newAhaIdea.For_Workspace__c = ahaIdeafieldNameandValue.get('For Workspace');
                               List<String> fieldValueList = ahaIdeafieldNameandValue.get('For Workspace').split(';');

                           }
                        if(ahaIdeafieldNameandValue.containsKey('Problem Statement')
                           && newAhaIdea.Problem_Statement__c != ahaIdeafieldNameandValue.get('Problem Statement')){
                               newAhaIdea.Problem_Statement__c = ahaIdeafieldNameandValue.get('Problem Statement');
                           }
                        if(ahaIdeafieldNameandValue.containsKey('Product Area')
                           && newAhaIdea.Product_Area__c != ahaIdeafieldNameandValue.get('Product Area')){
                               newAhaIdea.Product_Area__c = ahaIdeafieldNameandValue.get('Product Area');

                           }
                        if(ahaIdeafieldNameandValue.containsKey('Product Component')){
                            List<String> productList = New List<String>();
                            String productval = ahaIdeafieldNameandValue.get('Product Component');
                            if(productval.contains('(') || productval.contains(')')){
                                productval=productval.replace('(','');
                                productval=productval.replace(')','');
                            }
                            productList = productval.split(',');
                            newAhaIdea.Product_Component__c =  productList.Size()>0 ? String.join(productList,';') : '';
                        }
                        if(ahaIdeafieldNameandValue.containsKey('Idea Category')
                           && newAhaIdea.Idea_Category__c != ahaIdeafieldNameandValue.get('Idea Category')){
                               newAhaIdea.Idea_Category__c = ahaIdeafieldNameandValue.get('Idea Category');

                           }
                        if(ahaIdeafieldNameandValue.containsKey('Idea Tags')
                           && newAhaIdea.Idea_Tags__c != ahaIdeafieldNameandValue.get('Idea Tags')){
                               newAhaIdea.Idea_Tags__c = ahaIdeafieldNameandValue.get('Idea Tags');

                           }
                        if(ahaIdeafieldNameandValue.containsKey('Name')){
                            newAhaIdea.Name = ahaIdeafieldNameandValue.get('Name').length()>= 80 ? ahaIdeafieldNameandValue.get('Name').substring(0,75) + '...' :ahaIdeafieldNameandValue.get('Name');
                        }
                        if(!String.isempty(String.valueof(descrecords.get('body')))
                           && newAhaIdea.Idea_Description__c != String.valueof(descrecords.get('body'))){
                               String desciptionvalue = String.valueof(descrecords.get('body'));
                               newAhaIdea.Idea_Description__c = desciptionvalue.stripHtmlTags();
                           }
                        if(objectMap.get('assigned_to_user') != null && AhaOwnerMap != NUll && !String.isempty(String.valueof(AhaOwnerMap.get('name')))
                           && newAhaIdea.Aha_Idea_Owner__c != String.valueof(AhaOwnerMap.get('name'))){
                               String Ownervalue = String.valueof(AhaOwnerMap.get('name'));
                               newAhaIdea.Aha_Idea_Owner__c = Ownervalue;
                           }
                        if(ahaIdeafieldNameandValue.containsKey('PM Response')
                           && newAhaIdea.PM_Response__c != ahaIdeafieldNameandValue.get('PM Response')){
                               newAhaIdea.PM_Response__c = ahaIdeafieldNameandValue.get('PM Response');
                           }
                        if(childAhaIdeaList.size() == 0 && featureMap != null && featureMap.size() > 0 && !String.isempty(String.valueof(featureMap.get('name')))){
                            String featureRefNumber = String.valueof(featureMap.get('reference_num'));
                            Map<String , Object> featurerecordMap = getFeatureRecordData(featureRefNumber);
                            if(featurerecordMap.size()>0){
                                for(String featureResponseString : featurerecordMap.keyset()){
                                    object objFeature = featurerecordMap.get(featureResponseString);
                                    Map<String, Object> objectMapFeature = (Map<String, Object>)objFeature;
                                    Map<String, Object> realeseNameMap = (Map<String, Object>)objectMapFeature.get('release');
                                    Map<String, Object> featureStatusMap = (Map<String, Object>)objectMapFeature.get('workflow_status');
                                    newAhaIdea.Feature_Reference__c = String.valueof(objectMapFeature.get('url'));
                                    if(!String.isempty(String.valueof(featureStatusMap .get('name')))
                                       && newAhaIdea.Status__c != String.valueof(featureStatusMap.get('name'))){
                                           String statusMapvaluefeature = String.valueof(featureStatusMap.get('name'));
                                           newAhaIdea.Status__c = statusMapvaluefeature ;
                                       }
                                    if(!String.isempty(String.valueof(realeseNameMap.get('name')))
                                       && newAhaIdea.Feature_Target_Release__c != String.valueof(realeseNameMap.get('name'))){
                                           String realseName = String.valueof(realeseNameMap.get('name'));
                                           newAhaIdea.Feature_Target_Release__c= realseName;
                                       }
                                    if(objectMapFeature.get('integration_fields') != null){
                                        List<Object> integration_fieldsobj = (List<Object>) objectMapFeature.get('integration_fields');
                                        if(integration_fieldsobj.size()>0){
                                            Integer i = 0;
                                            String integrationField;
                                            for(Object objIntegration : integration_fieldsobj ){
                                                Map<String, Object> objMap = (Map<String, Object>) objIntegration;
                                                String value = String.valueof(objMap.get('value'));
                                                String serviceName = String.valueof(objMap.get('service_name'));
                                                String fieldName = String.valueof(objMap.get('name'));
                                                if(serviceName == 'jira' && (fieldName == 'url' || fieldName == 'key')){
                                                    if(i == 0){
                                                        integrationField = value;
                                                    }
                                                    else{
                                                        integrationField = integrationField+', '+ value;
                                                    }
                                                    i++;
                                                }
                                            }
                                            newAhaIdea.Engineering_Reference_Number__c = integrationField;
                                        }
                                    }
                                }
                            }
                        }
                        else if(!String.isempty(String.valueof(statusMap.get('name')))
                                && newAhaIdea.Status__c != String.valueof(statusMap.get('name'))){
                                    String statusMapvalue = String.valueof(statusMap.get('name'));
                                    newAhaIdea.Status__c = statusMapvalue;
                                    newAhaIdea.Feature_Target_Release__c= '';
                                    newAhaIdea.Feature_Reference__c = '';

                                }
                        ahaIdeaUpdateList.add(newAhaIdea);
                    }
                }
                //updating the Aha Idea record in Salesforce
                if(ahaIdeaUpdateList.size() > 0){
                    if(dupId != Null){
                        childAhaIdeaList = getFeatureStatusData(dupId,ahaIdeaUpdateList,apiResponseMap);
                        if(childAhaIdeaList.size()>0){
                            UPDATE childAhaIdeaList;
                            ahaIdeaUpdateList[0].status__c = childAhaIdeaList[0].status__c;

                        }
                    }
                    else{
                        childAhaIdeaList = getFeatureStatusData(dupId,ahaIdeaUpdateList,apiResponseMap);
                        if(childAhaIdeaList.size()>0){
                            UPDATE childAhaIdeaList;
                        }
                    }
                    UPDATE ahaIdeaUpdateList;
                    if(duplicateIdeaSet.size()>0){
                        updateLinkedRelatedRecord(duplicateIdeaSet);
                    }
                }
            }
        }//End of Method

        /**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Description  :   //Calculating the total link cases, Opportunity on Linked record.
    */
        @future(callout=true)
        public static void updateLinkedRelatedRecord(set<Id> ahaIdeas){
            Map<Id,List<Id>> parentIdandItsChildIds = new Map<Id,List<Id>>();
            Set<id> allChildIds = new Set<id>();
            Map<Id,List<Aha_Idea_Link__c>> parentIdAndItsIdeaLinkRecord = new Map<Id,List<Aha_Idea_Link__c>>();
            Map<Id,List<Aha_Idea_Link__c>> childIdAndItsIdeaLinkRecord = new Map<Id,List<Aha_Idea_Link__c>>();
            Map<Id,List<Aha_Idea_Link__c>> parentandChildCombinedLinkRecord = new Map<Id,List<Aha_Idea_Link__c>>();
            Map<Id,Account> accountMap = new Map<Id,Account>();
            Map<Id,String> parentIdeaIdVsUniqueId = new Map<Id,String>();
            Map<String,zsfjira__ZIssue__c> AhaUniqueIdVsZissue = new Map<String,zsfjira__ZIssue__c>();
            List<Aha_Ideas__c> ahaIdeaUpdateList = new List<Aha_Ideas__c>();
            Set<id> parentIdSet = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            for(Aha_Ideas__c ideaRec : [SELECT Id,Aha_Unique_ID__c,Total_No_of_Cases_Link_With_Idea__c,
                                        (SELECT Id,Total_No_of_Cases_Link_With_Idea__c,Total_No_of_Opportunity_Link_With_Idea__c
                                         FROM Aha_Ideas__r),
                                        (SELECT Id,Account_Name__c,Is_Account_Strategic__c,Case_Number__c,Case_Number__r.AccountId,
                                         Case_Number__r.CaseNumber,Opportunity_Name__r.Name,Opportunity_Name__r.AccountId,Opportunity_Name__r.iswon,Opportunity_Name__r.isclosed,Opportunity_Name__r.ACV_Amount__c,
                                         Aha_Ideas__c,Opportunity_Name__c FROM Aha_Idea_Links__r),
                                        Total_No_of_Opportunity_Link_With_Idea__c
                                        FROM Aha_Ideas__c WHERE Id IN : ahaIdeas]){
                                            parentIdeaIdVsUniqueId.put(ideaRec.id,ideaRec.Aha_Unique_ID__c);
                                            parentIdSet.add(ideaRec.id);
                                            //Get parent and its Child RecordIds
                                            if(ideaRec.Aha_Ideas__r.size()>0){
                                                for(Aha_Ideas__c childAha : ideaRec.Aha_Ideas__r){
                                                    allChildIds.add(childAha.Id);
                                                    if(!parentIdandItsChildIds.isEmpty() && parentIdandItsChildIds.containsKey(ideaRec.Id)){
                                                        parentIdandItsChildIds.get(ideaRec.Id).add(childAha.Id);
                                                    }
                                                    else{
                                                        parentIdandItsChildIds.put(ideaRec.Id,new List<Id>{childAha.Id});
                                                    }

                                                }
                                            }

                                            //Get Parent Record and its Aha Idea Link Record
                                            if(ideaRec.Aha_Idea_Links__r.size()>0){
                                                for(Aha_Idea_Link__c ail : ideaRec.Aha_Idea_Links__r){
                                                    if(!parentIdAndItsIdeaLinkRecord.isEmpty() && parentIdAndItsIdeaLinkRecord.containsKey(ideaRec.Id)){
                                                        parentIdAndItsIdeaLinkRecord.get(ideaRec.Id).add(ail);
                                                    }
                                                    else{
                                                        parentIdAndItsIdeaLinkRecord.put(ideaRec.Id,new list<Aha_Idea_Link__c>{ail});
                                                    }

                                                    //get account id from the Idea Link Record
                                                    if(ail.Opportunity_Name__c != null && ail.Opportunity_Name__r.AccountId!= null){
                                                        accountIds.add(ail.Opportunity_Name__r.AccountId);
                                                    }
                                                    else if(ail.Case_Number__c != null && ail.Case_Number__r.AccountId!= null){
                                                        accountIds.add(ail.Case_Number__r.AccountId);
                                                    }
                                                }
                                            }
                                        }


            if(parentIdeaIdVsUniqueId.values().size()>0){
                for(zsfjira__ZIssue__c zissue : [SELECT Id,zsfjira__Components__c ,Aha_Unique_Id__c
                                                 FROM zsfjira__ZIssue__c WHERE Aha_Unique_Id__c IN : parentIdeaIdVsUniqueId.values()]){
                                                     AhaUniqueIdVsZissue.put(zissue.Aha_Unique_Id__c,zissue);
                                                 }
            }

            if(allChildIds.size()>0){
                for(Aha_Idea_Link__c idealinkRec : [SELECT Id,Account_Name__c,Is_Account_Strategic__c,Case_Number__c,Case_Number__r.AccountId,Case_Number__r.Account.Name,Case_Number__r.CaseNumber,Opportunity_Name__r.Name,Opportunity_Name__r.AccountId,Opportunity_Name__r.iswon,Opportunity_Name__r.isclosed,Opportunity_Name__r.ACV_Amount__c,
                                                    Aha_Ideas__c,Opportunity_Name__c FROM Aha_Idea_Link__c Where Aha_Ideas__c IN : allChildIds]){

                                                        if(!childIdAndItsIdeaLinkRecord.isEmpty() && childIdAndItsIdeaLinkRecord.containskey(idealinkRec.Aha_Ideas__c)){
                                                            childIdAndItsIdeaLinkRecord.get(idealinkRec.Aha_Ideas__c).add(idealinkRec);
                                                        }
                                                        else{
                                                            childIdAndItsIdeaLinkRecord.put(idealinkRec.Aha_Ideas__c, new List<Aha_Idea_Link__c>{idealinkRec});
                                                        }

                                                        //get account id from the Idea Link Record
                                                        if(idealinkRec.Opportunity_Name__c != null && idealinkRec.Opportunity_Name__r.AccountId!= null){
                                                            accountIds.add(idealinkRec.Opportunity_Name__r.AccountId);
                                                        }
                                                        else if(idealinkRec.Case_Number__c != null && idealinkRec.Case_Number__r.AccountId!= null){
                                                            accountIds.add(idealinkRec.Case_Number__r.AccountId);
                                                        }

                                                    }
            }
            //Get all the Account Details

            if(accountIds!= null){
                for(Account aa : [Select id,name,Account_Preference__c,Strategic_Account__c from Account where Id IN : accountIds]){
                    accountMap.put(aa.id,aa);
                }
            }
            //Club all parnet and child Link List Records
            if(!parentIdSet.isEmpty()){
                for(Id ids: parentIdSet){
                    List<Aha_Idea_Link__c> parentIdeaLinkList = new List<Aha_Idea_Link__c>();
                    if(!parentIdAndItsIdeaLinkRecord.isEmpty() && parentIdAndItsIdeaLinkRecord.containskey(ids)){
                        parentIdeaLinkList = parentIdAndItsIdeaLinkRecord.get(ids);
                    }
                    if(parentIdandItsChildIds.containsKey(ids)){
                        for(Id idlist : parentIdandItsChildIds.get(ids)){
                            if(!childIdAndItsIdeaLinkRecord.isEmpty() && childIdAndItsIdeaLinkRecord.containsKey(idlist)){
                                parentIdeaLinkList.addall(childIdAndItsIdeaLinkRecord.get(idlist));
                                parentandChildCombinedLinkRecord.put(ids,parentIdeaLinkList);
                            }
                        }
                    }
                    else if(parentIdeaLinkList.Size() > 0){
                        parentandChildCombinedLinkRecord.put(ids,parentIdeaLinkList);
                    }
                }
            }

            if(!parentandChildCombinedLinkRecord.isEmpty()){
                for(Id ids : parentandChildCombinedLinkRecord.keySet()){
                    Integer totalnoofoppty = 0;
                    Integer totalnoofCases = 0;
                    Decimal amountforClosedWonOppty = 0;
                    Decimal amountforClosedLostOppty = 0;
                    Decimal amountforInflightOppty = 0;
                    Set<Id> accIds = new Set<Id>();
                    Set<String> accPreferenceValue = new Set<String>();
                    Map<Id,Aha_Idea_Link__c> checkduplicates = new Map<Id,Aha_Idea_Link__c>();
                    String linkOfCasesAttachedWithIdea = '';
                    String linkOfOpportunitiesAttachedWithIdea = '';
                    Integer countOfAccountStrategic = 0;
                    Integer noofcustomerRequested  = 0;
                    List<String> impactCustomers = new List<String>();
                    List<String>listOfAccPref = new List<String>();
                    String currentUserEmail = UserInfo.getUserEmail();
                    if(parentandChildCombinedLinkRecord.containsKey(ids)){
                        for(Aha_Idea_Link__c idelinkrec : parentandChildCombinedLinkRecord.get(ids)){
                            if(!checkduplicates.isEmpty() && checkduplicates.containskey(idelinkrec.Opportunity_Name__c)){
                                //do nothing
                            }
                            else if(idelinkrec.Opportunity_Name__c!= null){
                                checkduplicates.put(idelinkrec.Opportunity_Name__c,idelinkrec);
                                totalnoofoppty++;
                                if(idelinkrec.Opportunity_Name__r.AccountId!= null){
                                    accIds.add(idelinkrec.Opportunity_Name__r.AccountId);
                                }
                                if(totalnoofoppty < 6){
                                    linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + idelinkrec.Opportunity_Name__c+ '\\">'+idelinkrec.Opportunity_Name__r.Name+'</a> ; ';
                                }
                                if(idelinkrec.Opportunity_Name__r.iswon && idelinkrec.Opportunity_Name__r.ACV_Amount__c!= null){
                                    amountforClosedWonOppty += idelinkrec.Opportunity_Name__r.ACV_Amount__c;
                                }
                                else if(idelinkrec.Opportunity_Name__r.isclosed && idelinkrec.Opportunity_Name__r.ACV_Amount__c!= null){
                                    amountforClosedLostOppty += idelinkrec.Opportunity_Name__r.ACV_Amount__c;
                                }
                                else if(!idelinkrec.Opportunity_Name__r.isclosed && !idelinkrec.Opportunity_Name__r.iswon && idelinkrec.Opportunity_Name__r.ACV_Amount__c!= null){
                                    amountforInflightOppty += idelinkrec.Opportunity_Name__r.ACV_Amount__c;
                                }
                            }

                            if(!checkduplicates.isEmpty() && checkduplicates.containskey(idelinkrec.Case_Number__c)){
                                //do nothing
                            }
                            else if(idelinkrec.Case_Number__c!= null){
                                checkduplicates.put(idelinkrec.Case_Number__c,idelinkrec);
                                totalnoofCases++;
                                if(idelinkrec.Case_Number__r.AccountId!= null){
                                    accIds.add(idelinkrec.Case_Number__r.AccountId);
                                }
                                if(totalnoofCases < 6){
                                    linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + idelinkrec.Case_Number__c + '\\">'+idelinkrec.Case_Number__r.CaseNumber +'</a> ; ';
                                }
                            }
                        }
                        if(accIds!= null){
                            for(Id accountid : accIds){
                                if(!accountMap.isEmpty() && accountMap.containskey(accountid)){
                                    Account acc = accountMap.get(accountid);
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
                        }//end of acc if
                        if(linkOfOpportunitiesAttachedWithIdea != Null){
                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea.removeEnd('; ');
                        }
                        if(linkOfCasesAttachedWithIdea != Null){
                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea.removeEnd('; ');
                        }
                        Aha_Ideas__c updateSalesforceIdea = new Aha_Ideas__c(id=ids);
                        String ahaIdeaUniqueId = parentIdeaIdVsUniqueId.get(ids);
                        if(AhaUniqueIdVsZissue.containskey(ahaIdeaUniqueId)){
                            updateSalesforceIdea.zsfjira_Components__c = AhaUniqueIdVsZissue.get(ahaIdeaUniqueId).zsfjira__Components__c;
                        }
                        updateSalesforceIdea.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                        updateSalesforceIdea.Total_No_of_Opportunity_Link_With_Idea__c = totalnoofoppty;
                        updateSalesforceIdea.Strategic_Major_Account__c = countOfAccountStrategic;
                        updateSalesforceIdea.Total_Amount_for_the_Closed_Won_Oppty__c = String.valueOf(amountforClosedWonOppty);
                        updateSalesforceIdea.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueOf(amountforClosedLostOppty);
                        updateSalesforceIdea.Total_Amount_for_the_In_Flight_Oppty__c =   String.valueOf(amountforInflightOppty);
                        if(!parentIdeaIdVsUniqueId.isEmpty() && parentIdeaIdVsUniqueId.containsKey(ids)){
                            updateSalesforceIdea.Aha_Unique_ID__c = parentIdeaIdVsUniqueId.get(ids);
                        }
                        if(impactCustomers.size() > 0){
                            updateSalesforceIdea.Impacted_Customers__c = String.join(impactCustomers,',');
                        }
                        else{
                            updateSalesforceIdea.Impacted_Customers__c = '';
                        }
                        if(accPreferenceValue.size() > 0){
                            listOfAccPref = new List<String>(accPreferenceValue);
                            updateSalesforceIdea.Account_Preference__c = String.join(listOfAccPref,';');
                        }
                        else{
                            updateSalesforceIdea.Account_Preference__c = '';
                        }
                        // Update Aha Idea through Api
                        if(updateSalesforceIdea.Aha_Unique_ID__c!= null){
                            ManageAhaIdeaHelper.updateIdeaRecordInAha(updateSalesforceIdea.Aha_Unique_ID__c,updateSalesforceIdea.Impacted_Customers__c,noofcustomerRequested,currentUserEmail,Integer.valueof(updateSalesforceIdea.Strategic_Major_Account__c),totalNoOfCases,linkOfCasesAttachedWithIdea,totalnoofoppty,linkOfOpportunitiesAttachedWithIdea,listOfAccPref,amountforClosedWonOppty,amountforClosedLostOppty,amountforInflightOppty);
                        }
                        //Update Idea Record in Salesforce
                        ahaIdeaUpdateList.add(updateSalesforceIdea);
                    }
                } //End of Parent for loop
            }//End of Parnet If
            if(ahaIdeaUpdateList.Size()>0){
                UPDATE ahaIdeaUpdateList;
            }
        }

        /**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Description  :   Create New Idea Record in Saleforce while Migrating Zissue Records through CSV
    */
        @future(callout=true)
        public static void createNewIdeaInSfdc(String serializedMap){
            Map<String,Set<String>>ZissueNoandCaseIdSet = (Map<String, Set<String>>)JSON.deserialize(serializedMap, Map<String,Set<String>>.class);
            List<InsertIdeaandLinkRecords> createIdeaAndLinkRecords = new List<InsertIdeaandLinkRecords>();
            Map<String,String>ZissueNoandAhaUniqueId = new Map<String,String>();
            String csvColumnHeader = 'Zissue Id, CaseId, Status\n';
            Map<String,zsfjira__ZIssue__c> zissueNoandZissueRecord = new Map<String,zsfjira__ZIssue__c>();
            Set<String> allCaseNumber = new Set<String>();
            Map<String,Case> caseMap = new Map<String,Case>();
            Set<Id> accountIdSet = new Set<Id>();
            Map<Id,Account> accMap = new Map<Id,Account>();
            Map<String,Set<String>> zsfjiraAndCaseMap = new Map<String,Set<String>>();
            try{
                if(!ZissueNoandCaseIdSet.isEmpty()){
                    for(zsfjira__ZIssue__c Zissue : [Select id,name,Aha_Unique_Id__c,zsfjira__Description__c,zsfjira__Summary__c,zsfjira__IssueType__c,zsfjira__Project__c,zsfjira__Components__c from zsfjira__ZIssue__c where name IN :  ZissueNoandCaseIdSet.keySet()]){
                        zissueNoandZissueRecord.put(Zissue.Name,Zissue);
                    }
                }
                if(!ZissueNoandCaseIdSet.isEmpty()){
                    for(String zissueNo : ZissueNoandCaseIdSet.keyset()){
                        Set<String>cseNum =  ZissueNoandCaseIdSet.get(zissueNo);
                        if(cseNum.Size()>0){
                            for(String caseNum : cseNum){
                                allCaseNumber.add(caseNum.trim());
                            }
                        }
                    }
                }
                if(allCaseNumber.size()>0){
                    for(Case cc : [Select id,CaseNumber,AccountId from Case where CaseNumber IN : allCaseNumber]){
                        caseMap.put(cc.CaseNumber,cc);
                        accountIdSet.add(cc.AccountId);
                    }
                }
                if(accountIdSet.Size() > 0){
                    for(Account acc : [Select id,name,Account_Preference__c,Strategic_Account__c from Account where Id IN : accountIdSet]){
                        accMap.put(acc.Id,acc);
                    }
                }
                if(!ZissueNoandCaseIdSet.isEmpty()){
                    for(String zissueNo : ZissueNoandCaseIdSet.keyset()){
                        Integer totalnoofcases = 0;
                        String linkOfCasesAttachedWithIdea = '';
                        List<String> impactCustomers = new List<String>();
                        Set<String> accPreferenceValue = new Set<String>();
                        List<String>listOfAccPref = new List<String>();
                        Set<String> cseNumberList = new Set<String>();
                        Integer noofcustomerRequested  = 0;
                        Integer strategic_Account_value = 0;
                        Set<Id> caserelatedAccId = new Set<Id>();
                        zsfjira__ZIssue__c zissue = new zsfjira__ZIssue__c();
                        if(!zissueNoandZissueRecord.isEmpty() && zissueNoandZissueRecord.containskey(zissueNo)){
                            zissue = zissueNoandZissueRecord.get(zissueNo);
                        }
                        Set<string> casenum = new Set<String>(); //ZissueNoandCaseIdSet.get(zissueNo);
                        for(String cseNum : ZissueNoandCaseIdSet.get(zissueNo)){
                            casenum.add(cseNum.trim());
                        }
                        Map<String, Object> apiResponseMap = new Map<String, Object>();
                        if(zissue.Name!= null && zissue.Aha_Unique_Id__c!= null && casenum.size() > 0){
                            Aha_Ideas__c  ahaIdea = ManageAhaIdeaController.getAhaIdeaRecord(zissue.Aha_Unique_Id__c);
                            if(casenum.size() > 0 && zissue.Name!= null){
                                for(String csNumber : casenum){
                                    if(!caseMap.isEmpty() && caseMap.containsKey(csNumber)){
                                        Case cc =  caseMap.get(csNumber);
                                        totalnoofcases++;
                                        caserelatedAccId.add(cc.AccountId);
                                        if(totalnoofcases<=5){
                                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href =\\"'+Url.getOrgDomainURL().toExternalForm() + '/' + cc.Id + '\\">'+ cc.CaseNumber +'</a> ; ';
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
                                String requestBody = '';
                                String prodCom = zissue.zsfjira__Components__c != null ? zissue.zsfjira__Components__c : '';
                                if(!String.isBlank(prodCom) && prodCom != '' && prodCom != Null){
                                    requestBody = '{"idea":{"custom_fields":{"number_of_customers_requested":"'+customerRequested+'","other_impacted_customers": "'+AccountName+'","strategicmajor_account": "'+Strategic_Account_value+'","total_no_of_cases_link_with_idea": "'+totalNoOfCases+'","links_of_cases_attached_with_idea": "'+linkOfCasesAttachedWithIdea+'","account_preference": "'+accPrefVal+'","zsfjira_components": "'+prodCom+'"}}}';
                                }
                                else{
                                    requestBody = '{"idea":{"custom_fields":{"number_of_customers_requested":"'+customerRequested+'","other_impacted_customers": "'+AccountName+'","strategicmajor_account": "'+Strategic_Account_value+'","total_no_of_cases_link_with_idea": "'+totalNoOfCases+'","links_of_cases_attached_with_idea": "'+linkOfCasesAttachedWithIdea+'","account_preference": "'+accPrefVal+'"}}}';
                                }
                                HttpRequest req = new HttpRequest();
                                req.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/ideas/' + ahaIdea.Aha_Unique_ID__c);
                                req.setMethod('PUT');
                                req.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                                req.setHeader('contentType', 'application/json');
                                req.setHeader('Content-Type','application/json;charset=UTF-8');
                                req.setHeader('Accept', 'application/json');
                                req.setBody(requestBody);
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
                                        ideaIdandCaseSet.put(ahaIdea.Aha_Unique_ID__c,casenum);
                                        Map<String,zsfjira__ZIssue__c> ideaIdandZissueRec = new Map<String,zsfjira__ZIssue__c>();
                                        ideaIdandZissueRec.put(ahaIdea.Aha_Unique_ID__c,zissue);
                                        InsertIdeaandLinkRecords insideaandlink = new InsertIdeaandLinkRecords();
                                        insideaandlink.sfdcidea = ahaIdea;
                                        insideaandlink.AhaIdAndSetCaseids = ideaIdandCaseSet;
                                        insideaandlink.ZissueRec = ideaIdandZissueRec;
                                        createIdeaAndLinkRecords.add(insideaandlink);
                                    }
                                }
                                else{
                                    system.debug('Exception in Callout-->');
                                }

                            }
                        }//End of If
                    }//End of For Loop
                }//End of Main If
                if(createIdeaAndLinkRecords.size() > 0){
                    handleIdeaInsertWrapper(createIdeaAndLinkRecords,caseMap);
                }
            }//end of try
            catch(Exception e){

            }
        }//End of Method

        public Static void handleIdeaInsertWrapper(List<InsertIdeaandLinkRecords> createIdeaAndLinkRecords,Map<String,Case> caseMap){
            try{
                String csvColumnHeader = 'Zissue Id, CaseId, Status\n';
                List<Aha_Ideas__c> createsfdcidea = new List<Aha_Ideas__c>();
                List<zsfjira__ZIssue__c> updateZissue = new List<zsfjira__ZIssue__c>();
                List<Aha_Idea_Link__c> ideaLinkInsertList = new List<Aha_Idea_Link__c>();
                Map<String,String> ahaUniqueIdAndId = new Map<String,String>();
                if(createIdeaAndLinkRecords.size() > 0){
                    for(InsertIdeaandLinkRecords rec :  createIdeaAndLinkRecords){
                        createsfdcidea.add(rec.sfdcidea);
                    }
                }
                if(createsfdcidea.Size() > 0){
                    INSERT createsfdcidea;
                }
                if(createsfdcidea.size() > 0){
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
            }//end of try
            catch(Exception e){

            }
        }//End of Method
        /**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Description  :   getting the related feature record of idea .
    */
        public static Map<String, Object> getFeatureRecordData(String FeatureId){
            Map<String, Object> recordMap = new Map<String, Object>();
            try {
                Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
                if(FeatureId!= null && FeatureId!= ''){
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/features/' + FeatureId);
                    request.setMethod('GET');
                    request.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                    request.setHeader('contentType', 'application/json');
                    request.setHeader('Accept', 'application/json');
                    Http http = new Http();
                    HttpResponse response = http.send(request);
                    if(response.getStatusCode() == 200){
                        Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        object obj = records.get('feature');
                        Map<String, Object> objectMap = (Map<String, Object>)obj;
                        String featuresId = (String) objectMap.get('id');
                        recordMap.put(featuresId,obj);
                    }
                }

            }
            catch (Exception e) {
                String errorMessage = e.getMessage();
            }
            return recordMap;
        }//End of Method

        /**
    * @Author       :   Grazitti
    * @CreatedDate  :   13/07/2023
    * @Description  :   updating the child record of merged idea ib salesforce.
    */
        public static List<Aha_Ideas__c> getFeatureStatusData(String DuplicateId, List<Aha_Ideas__c> currentIdeaList, Map<String , Object> currentApiResponseMap){
            Map<String, String> AhaIdVsFeatureStatusMap = New Map<String, String>();
            Map<String, String> DupicateAhaIdVsStatusMap = New Map<String, String>();
            Set<Id> IdeaIds = New Set<Id>();
            List<Aha_Ideas__c> childAhaIdeaList = New List<Aha_Ideas__c>();
            List<Aha_Ideas__c> updateChildAhaIdeaList = New List<Aha_Ideas__c>();
            for(Aha_Ideas__c ais : currentIdeaList){
                IdeaIds.add(ais.Id);
                DupicateAhaIDVsStatusMap.put(ais.Id,ais.status__c);
            }
            if(DuplicateId != Null){
                Map<String , Object> recordMap = ManageAhaIdeaHelper.getAhaIdeaRecordData(DuplicateId);
                List<String> currentAhaUniqueIds = New List<String>();
                String statusMapvalue;
                if(currentApiResponseMap != null && currentApiResponseMap.size() > 0){
                    for(String currentApiResponseString : currentApiResponseMap.keyset()){
                        object currentObj = currentApiResponseMap.get(currentApiResponseString);
                        Map<String, Object> currentObjectMap = (Map<String, Object>)currentObj;
                        if(!currentObjectMap.ContainsKey('feature')){
                            String ahaIdeaUniqueId = (String) currentObjectMap.get('reference_num');
                            if(ahaIdeaUniqueId != Null){
                                currentAhaUniqueIds.add(ahaIdeaUniqueId);
                            }
                        }
                    }
                }
                childAhaIdeaList = [SELECT Id,Status__c,DupliCate_of__r.Aha_Unique_ID__c FROM Aha_Ideas__c WHERE
                                    (Duplicate_of__r.Aha_Unique_ID__c =: DuplicateId OR Id IN : IdeaIds)
                                    AND (Feature_Target_Release__c = null OR Aha_Unique_ID__c IN : currentAhaUniqueIds)];
                if(recordMap != null && recordMap.size() > 0){
                    for(String ApiResponseString : recordMap.keyset()){
                        object obj = recordMap.get(ApiResponseString);
                        Map<String, Object> objectMap = (Map<String, Object>)obj;
                        Map<String, Object> featureMap = (Map<String, Object>)objectMap.get('feature');
                        if(featureMap != null && featureMap.size() > 0 && !String.isempty(String.valueof(featureMap.get('name')))){
                            String featureRefNumber = String.valueof(featureMap.get('reference_num'));
                            Map<String , Object> featurerecordMap = getFeatureRecordData(featureRefNumber);
                            if(featureRecordMap.size()>0){
                                for(String featureResponseString : featureRecordMap.keyset()){
                                    object objFeature = featureRecordMap.get(featureResponseString);
                                    Map<String, Object> objectMapFeature = (Map<String, Object>)objFeature;
                                    Map<String, Object> featureStatusMap = (Map<String, Object>)objectMapFeature.get('workflow_status');
                                    if(!String.isempty(String.valueof(featureStatusMap.get('name'))))
                                        statusMapvalue = String.valueof(featureStatusMap.get('name'));
                                }
                            }
                        }
                        else{
                            Map<String, Object> duplicateStatusMap = (Map<String, Object>)objectMap.get('workflow_status');
                            if(!String.isempty(String.valueof(duplicateStatusMap.get('name'))))
                                statusMapvalue = String.valueof(duplicateStatusMap.get('name'));
                        }
                    }
                    if(childAhaIdeaList != Null && childAhaIdeaList.size()>0){
                        for(Aha_Ideas__c ai : childAhaIdeaList){
                            if(ai.status__c != statusMapvalue){
                                ai.status__c = statusMapvalue;//AhaIdVsFeatureStatusMap.get(ai.DupliCate_of__r.Aha_Unique_ID__c);
                                updateChildAhaIdeaList.add(ai);
                            }
                        }
                    }
                }
            }
            else{
                childAhaIdeaList = [SELECT Id,Status__c,DupliCate_of__r.Aha_Unique_ID__c FROM Aha_Ideas__c WHERE Duplicate_of__c IN : IdeaIds AND Feature_Target_Release__c = null];
                if(childAhaIdeaList != Null && childAhaIdeaList.size()>0){
                    for(Aha_Ideas__c ai : childAhaIdeaList){
                        if(ai.status__c != DupicateAhaIDVsStatusMap.get(ai.DupliCate_of__c)){
                            ai.status__c = DupicateAhaIDVsStatusMap.get(ai.DupliCate_of__c);
                            updateChildAhaIdeaList.add(ai);
                        }
                    }
                }
            }
            return updateChildAhaIdeaList;
        }

        /*   @Author       :   Grazitti
    * @CreatedDate  :   11/06/2023
    * @Description  :   Insert Picklist Field Value through Metadata
    */
        public static void updatePicklistValues(String fieldApiName, String ObjectApiName, Set<String> fieldValue){
            try{
                String fieldName = fieldApiName.trim();
                String ObjectApi = ObjectApiName.trim();
                Set<String> pickListFieldValues = new Set<String>();
                Set<String> allFieldValue = new Set<String>();
                allFieldValue.addall(fieldValue);
                String fieldLabel = Schema.getGlobalDescribe().get(ObjectApi).getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel();
                Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(ObjectApi) ;
                Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
                Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap();
                Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
                List<Schema.PicklistEntry> lstPickListValues = fieldResult.getPickListValues();
                for (Schema.PicklistEntry objPickList : lstPickListValues){
                    pickListFieldValues.add(objPickList.getLabel());
                    allFieldValue.add(objPickList.getLabel());
                }
                if(fieldValue.Size() > 0){
                    for(String ss : fieldValue){
                        if(!pickListFieldValues.contains(ss)){
                            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
                            service.SessionHeader = new MetadataService.SessionHeader_element();
                            service.SessionHeader.sessionId = UserInfo.getSessionId();
                            MetadataService.CustomField customField = new MetadataService.CustomField();
                            customField.fullName = 'Aha_Ideas__c.' + fieldName;
                            customField.label = fieldLabel;
                            customField.type_x = 'Picklist';

                            // Define the Value Set and Value Set Definitions
                            MetadataService.ValueSet vs = new MetadataService.ValueSet();
                            MetadataService.ValueSetValuesDefinition vd = new MetadataService.ValueSetValuesDefinition();

                            // Define the picklist values
                            List<MetadataService.CustomValue> customValues = new List<MetadataService.CustomValue>();
                            for(String allfldval : allFieldValue){
                                String fldval = allfldval;
                                // if(fldval.length() > 40){
                                // fldval = fldval;
                                //}
                                MetadataService.CustomValue cv1 = new MetadataService.CustomValue();
                                cv1.label = fldval;
                                cv1.fullName = fldval;
                                cv1.isActive = true;
                                cv1.default_x = false;
                                customValues.add(cv1);
                            }
                            vd.value = customValues;
                            vd.sorted = true;
                            vs.valueSetDefinition = vd;
                            customField.valueSet  = vs;
                            List<MetadataService.SaveResult> results = service.updateMetadata(new MetadataService.Metadata[] {customField});
                            break;
                        }
                    }
                }
            }
            Catch(Exception ex){
                system.debug('Message ============='+ex.getMessage());
                system.debug('Line Number ============='+ex.getLineNumber());
                system.debug('Stack Trace ============='+ex.getStackTraceString());
            }
        }

    }//End of Class