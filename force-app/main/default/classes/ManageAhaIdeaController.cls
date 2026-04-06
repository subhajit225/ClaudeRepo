/**
* @Author       :   Grazitti Interactive
* @CreatedDate  :   8/9/2023
* @Jira Ticket  :   AS-4 - Idea Form - Manage idea form in SF
* @description  :   Below Batch class is used to Link Or Unlink IDea from Case or Opportunity.
* @TestClass    :   ManageAhaIdeaControllerTest
*/
public without sharing class ManageAhaIdeaController{

    /**
     * @description Wrapper Class used to create a Aha Idea Record with in Aha
     */
    public class IdeaFields {
        /**
         * @description Name of the idea
         */
        @AuraEnabled public String name { get; set; }

        /**
         * @description Description of the idea
         */
        @AuraEnabled public String description { get; set; }

        /**
         * @description Product ID in Aha
         */
        @AuraEnabled public String product_id { get; set; }

        /**
         * @description User who created the idea
         */
        @AuraEnabled public String created_by { get; set; }

        /**
         * @description Visibility setting for the idea
         */
        @AuraEnabled public String visibility { get; set; }

        /**
         * @description Custom fields for the idea
         */
        @AuraEnabled public CustomFields custom_fields { get; set; }
    }
    /**
    * @description  :   Below Wrapper used to store the custom field value of the Aha Idea.
    */
    public class CustomFields {
        /**
        * @description business_casevalue API name in AHA
        */
        @AuraEnabled public String business_casevalue{ get; set; }

        /**
        * @description Proposed solution for the idea
        */
        @AuraEnabled public String proposed_solution{ get; set; }

        /**
        * @description Escalation information
        */
        @AuraEnabled public string escalation{ get; set; }

        /**
        * @description Workspace identifier
        */
        @AuraEnabled public String for_workspace{ get; set; }

        /**
        * @description Problem statement for the idea
        */
        @AuraEnabled public String problem_statement{ get; set; }
        /**
        * @description API name in AHA
        */
        @AuraEnabled public String product_area{ get; set; }
        /**
        * @description priority API name in AHA
        */
        @AuraEnabled public String priority{ get; set; }

        /**
        * @description Area component for the idea
        */
        @AuraEnabled public String areacomponent{ get; set; }

        /**
        * @description Strategic major account indicator
        */
        @AuraEnabled public Integer strategicmajor_account{ get; set; }

        /**
        * @description Number of customers who requested this idea
        */
        @AuraEnabled public Integer number_of_customers_requested { get; set; }

        /**
        * @description Category of the idea
        */
        @AuraEnabled public String idea_category{ get; set; }

        //@AuraEnabled public String idea_tags{ get; set; }

        /**
        * @description Other customers impacted by this idea
        */
        @AuraEnabled public String other_impacted_customers { get; set; }

        /**
        * @description Account preference information
        */
        @AuraEnabled public String account_preference { get; set; }

        /**
        * @description Total number of cases linked with this idea
        */
        @AuraEnabled public Integer total_no_of_cases_link_with_idea { get; set; }

        /**
        * @description Total number of opportunities linked with this idea
        */
        @AuraEnabled public Integer total_no_of_opportunities_link_with_idea { get; set; }

        /**
        * @description Links of cases attached with this idea
        */
        @AuraEnabled public String links_of_cases_attached_with_idea { get; set; }

        /**
        * @description Links of opportunities attached with this idea
        */
        @AuraEnabled public String links_of_opportunities_attached_with_idea { get; set; }

        /**
        * @description Total amount for closed lost opportunities
        */
        @AuraEnabled public Decimal total_amount_for_the_closed_lost_opportunity { get; set; }

        /**
        * @description Total amount for closed won opportunities
        */
        @AuraEnabled public Decimal total_amount_for_the_closed_won_opportunity { get; set; }

        /**
        * @description Total amount for in-flight opportunities
        */
        @AuraEnabled public Decimal total_amount_for_the_in_flight_opportunity { get; set; }
    }

     /**
    * @Author       :   Grazitti Interactive
    * @CreatedDate  :   08/09/2023
    * @Description  :   Below method is used to display the Idea from the Aha on the basis of the search term on the case or opportunity object.
    */

    /**
     * @description Get Aha records based on search term and record ID
     * @param searchTerm Search term to filter Aha records
     * @param rcId Record ID for filtering
     * @return List<Aha_Ideas__c> List of matching Aha Ideas records
     */
    @AuraEnabled(cacheable=true)
    public static List<Aha_Ideas__c> getAhaRecords(String searchTerm, Id rcId) {
        try{
            List<Aha_Ideas__c> ahaRecorddetails = ManageAhaIdeaHelper.searchAhaRecords(searchTerm,rcId);
            return ahaRecorddetails;
        }
        catch (exception ex){
            String errorMessage = ex.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
    * @description Below method is used to create the Aha Link Record respect to the Opportunity or Case which is linked to the particular Aha Idea
    * @param newTriggerMap Map of newly inserted Aha Ideas records
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    public static void afterInsertAhaIdea(Map<Id,Aha_Ideas__c> newTriggerMap){
        try{
            ManageAhaIdeaHelper.afterInsertAhaIdeaHelper(newTriggerMap.Values());
        }
        catch(exception ex){
            ManageAhaIdeaHelper.insertException(ex,null);
        }
    }

     /**
    * @description Below method is used to update the Zissue No on the Aha Idea
    * @param newTriggerList List of Aha Ideas records being inserted
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    public static void beforeInsertAhaIdea(List<Aha_Ideas__c> newTriggerList){
        try{
            ManageAhaIdeaHelper.beforeInsertAhaIdeaHelper(newTriggerList);
        }
        catch(exception ex){
            ManageAhaIdeaHelper.insertException(ex,null);
        }
    } 
    /**
    * @description Below Method Is Used to Create a Aha Idea record in Salesforce and in Aha through Form
    * @param formInputFieldNameAndValues Map of form input field names and values
    * @author Grazitti Interactive
    * @createdDate 08/09/2023
    */
    @AuraEnabled
    public static void createIdeaInAha(Map<String,String> formInputFieldNameAndValues){
        String ahaRefId = '';
        String salesforceobjectrecordid = '';
        Integer totalNoOfCases = 0;
        Integer totalNoOfOpportunities = 0;
        String linkOfCasesAttachedWithIdea = '';
        String linkOfOpportunitiesAttachedWithIdea = '';
        try{
            Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
            if(!formInputFieldNameAndValues.isempty()){
                Decimal amountforClosedWonOppty = 0;
                Decimal amountforClosedLostOppty = 0;
                Decimal amountforInflightOppty = 0;
                String accountName = '';
                String currentUserEmail = UserInfo.getUserEmail();
                List<String> account_Preference = new List<String>();
                // List<String> ProductComponentList = new List<String>();
                Account aa = new Account();
                if(formInputFieldNameAndValues.containskey('Ideaorigin')){
                    salesforceobjectrecordid = formInputFieldNameAndValues.get('Ideaorigin');
                    Opportunity oppty = new Opportunity();
                    Case cse = new Case();
                    if(salesforceobjectrecordid!= ''){
                        if(salesforceobjectrecordid.startsWith('006')){
                        oppty = [Select id,name,StageName,iswon,isclosed,ACV_Amount__c,AccountId,Account.name,Account.Strategic_Account__c,Account.Account_Preference__c  from Opportunity where id =: salesforceobjectrecordid];
                            if(oppty.AccountId!= null){
                                aa.Id =  oppty.Account.Id;
                                aa.Name = oppty.Account.Name;
                                aa.Strategic_Account__c  = oppty.Account.Strategic_Account__c;
                                aa.Account_Preference__c = oppty.Account.Account_Preference__c;
                                if(aa.Account_Preference__c!= null){
                                    account_Preference = aa.Account_Preference__c.split(';');
                                }
                            }
                            if(oppty.iswon && oppty.ACV_Amount__c!= null){
                                amountforClosedWonOppty = amountforClosedWonOppty+oppty.ACV_Amount__c;
                            }
                            else if(oppty.isclosed && oppty.ACV_Amount__c!= null){
                                amountforClosedLostOppty = amountforClosedLostOppty+oppty.ACV_Amount__c;
                            }
                            else if(!oppty.isclosed && !oppty.iswon && oppty.ACV_Amount__c!= null){
                                amountforInflightOppty = amountforInflightOppty+oppty.ACV_Amount__c;
                            }
                            totalNoOfOpportunities++;
                            linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea +'<a href ="'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + oppty.Id+ '">'+oppty.Name+'</a> ; ';

                        }
                        else if(salesforceobjectrecordid.startsWith('500')){
                        cse = [Select id,CaseNumber,AccountId,Account.name,Account.Strategic_Account__c,Account.Account_Preference__c from case where id =: salesforceobjectrecordid];
                            if(cse.AccountId!= null){
                                aa.Id =  cse.Account.Id;
                                aa.Name = cse.Account.Name;
                                aa.Strategic_Account__c  = cse.Account.Strategic_Account__c;
                                aa.Account_Preference__c = cse.Account.Account_Preference__c;
                                if(aa.Account_Preference__c!= null){
                                    account_Preference = aa.Account_Preference__c.split(';');
                                }
                            }
                            totalNoOfCases++;
                            linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea + '<a href ="'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + cse.Id+ '">'+cse.CaseNumber+'</a> ; ';

                        }
                    }
                }
                if(linkOfOpportunitiesAttachedWithIdea != Null){
                    linkOfOpportunitiesAttachedWithIdea = linkOfOpportunitiesAttachedWithIdea.removeEnd('; ');
                }
                if(linkOfCasesAttachedWithIdea != Null){
                    linkOfCasesAttachedWithIdea = linkOfCasesAttachedWithIdea.removeEnd('; ');
                }

                Aha_Ideas__c ahaIdea = new Aha_Ideas__c();
                ahaIdea.Name = formInputFieldNameAndValues.get('nameval');
                ahaIdea.Aha_Idea_Origin__c = formInputFieldNameAndValues.get('Ideaorigin');
                ahaIdea.Business_Case_Value__c = formInputFieldNameAndValues.get('BusinessCaseValue');
                ahaIdea.Creator_Proposed_Solution__c = formInputFieldNameAndValues.get('CreatorProposedSolution');
                ahaIdea.Escalation__c = formInputFieldNameAndValues.get('Escalation');
                ahaIdea.For_Workspace__c = formInputFieldNameAndValues.get('ForWorkspace');
                ahaIdea.Problem_Statement__c = formInputFieldNameAndValues.get('ProblemStatement');
                ahaIdea.Product_Area__c = formInputFieldNameAndValues.get('ProductArea');
                ahaIdea.Priority__c = formInputFieldNameAndValues.get('Priority');
                // ProductComponentList =  formInputFieldNameAndValues.get('ProductComponent').split(';');
                // ahaIdea.Product_Component__c = formInputFieldNameAndValues.get('ProductComponent');
                ahaIdea.Strategic_Major_Account__c = aa.Strategic_Account__c ? 1 : 0;
                ahaIdea.Idea_Description__c = formInputFieldNameAndValues.get('IdeaDescription');
                ahaIdea.Account_Preference__c = aa.Account_Preference__c;
                ahaIdea.Idea_Category__c = formInputFieldNameAndValues.get('IdeaCategory');
                ahaIdea.Impacted_Customers__c = String.isBlank(aa.Name)?aa.Name:'';
                ahaIdea.Total_No_of_Cases_Link_With_Idea__c = totalNoOfCases;
                ahaIdea.Total_No_of_Opportunity_Link_With_Idea__c = totalNoOfOpportunities;
                ahaIdea.Total_Amount_for_the_Closed_Won_Oppty__c = String.valueOf(amountforClosedWonOppty);
                ahaIdea.Total_Amount_for_the_Closed_Lost_Oppty__c = String.valueOf(amountforClosedLostOppty);
                ahaIdea.Total_Amount_for_the_In_Flight_Oppty__c =   String.valueOf(amountforInflightOppty);

                IdeaFields idea_fields = new IdeaFields();
                idea_fields.created_by = currentUserEmail;
                idea_fields.name = ahaIdea.name;
                idea_fields.product_id = ahaCredential.aha_ProductID__c;
                idea_fields.description = ahaIdea.Idea_Description__c;
                idea_fields.visibility = 'public';

                CustomFields customFields = new CustomFields();
                customFields.business_casevalue = ahaIdea.Business_Case_Value__c;
                customFields.proposed_solution = ahaIdea.Creator_Proposed_Solution__c;
                customFields.escalation = ahaIdea.Escalation__c;
                customFields.for_workspace = ahaIdea.For_Workspace__c;
                customFields.problem_statement = ahaIdea.Problem_Statement__c;
                customFields.product_area = ahaIdea.Product_Area__c;
                customFields.priority = ahaIdea.Priority__c;
                // customFields.areacomponent =  ProductComponentList.Size()>0 ? String.join(ProductComponentList,',') : '';
                customFields.strategicmajor_account = aa.Strategic_Account__c ? 1 : 0;
                customFields.other_impacted_customers = aa.Name;
                customFields.number_of_customers_requested = !String.isBlank(aa.Name)?1:0;
                customFields.idea_category = ahaIdea.Idea_Category__c;
                customFields.account_preference = account_Preference.Size()>0 ? String.join(account_Preference,',') : '';
                customFields.total_no_of_cases_link_with_idea = totalNoOfCases;
                customFields.total_no_of_opportunities_link_with_idea = totalNoOfOpportunities;
                customFields.links_of_cases_attached_with_idea = linkOfCasesAttachedWithIdea;
                customFields.links_of_opportunities_attached_with_idea = linkOfOpportunitiesAttachedWithIdea;
                customFields.total_amount_for_the_closed_won_opportunity = amountforClosedWonOppty;
                customFields.total_amount_for_the_closed_lost_opportunity = amountforClosedLostOppty;
                customFields.total_amount_for_the_in_flight_opportunity =   amountforInflightOppty;

                idea_fields.custom_fields = customFields;
                String jsonString = JSON.serialize(idea_fields);
                String jsonStringfinal = '{"idea":' + jsonString + '}';
                //Call Out to create idea
                HttpRequest request = new HttpRequest();
                request.setEndpoint(ahaCredential.AHA_BASE_URL__c + '/products/' + ahaCredential.Aha_ProductID__c + '/ideas');
                request.setMethod('POST');
                request.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                request.setHeader('contentType', 'application/json');
                request.setHeader('Content-Type','application/json;charset=UTF-8');
                request.setHeader('Accept', 'application/json');
                request.setBody(jsonStringfinal);

                // Send the HTTP request to create an Idea
                Http http = new Http();
                System.debug(LoggingLevel.ERROR,'request: '+request);

                HttpResponse response = http.send(request);
                String responseString = response.getBody();
                System.debug(LoggingLevel.ERROR,'response: '+response+': responseString: '+responseString+'  :getStatusCode: '+response.getStatusCode()+ 'getBody' +response.getBody());

                if (response.getStatusCode() == 200){
                    Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    object obj = responseData.get('idea');
                    Map<String, Object> recordMap = (Map<String, Object>)obj;
                    String ahaIdearefno = (String) recordMap.get('reference_num');
                    String ahaIdeaId = (String) recordMap.get('id');
                    ahaIdea.Aha_Idea_Number__c = (String) recordMap.get('id');
                    ahaIdea.Aha_Unique_ID__c = (String) recordMap.get('reference_num');
                    AhaRefId = (String) recordMap.get('reference_num');
                    System.debug(LoggingLevel.ERROR,'AhaRefId: '+AhaRefId);
                    ManageAhaIdeaHelper.updateAhaIdeaStatusAndCreatedInfo(response.getBody(), ahaIdea);
                    insert ahaIdea;
                }
                else{
                    System.debug(LoggingLevel.ERROR,'CalloutException:  Status: '+response.getStatusCode()+' res: '+response.getBody());
                    throw new CalloutException('');
                }
            }
        }
        catch(DmlException ex) {
            String errStr = 'DmlException caught while creating the Idea in Salesforce. Aha Idea is ';
            errStr += 'created with the reference Number. ';
            errStr += 'You can search the Idea with the Refernce Number  '  + ahaRefId  + '   ' + ex.getMessage();
            System.debug(LoggingLevel.ERROR,'DmlException:: '+errStr);
            throw new DmlException(errStr);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,'Exception:: '+ahaRefId);
            if(ahaRefId!= ''){
                String errStr = 'Callout Exception occured. Aha Idea is created with the reference Number.';
                errStr += ' You can search the Idea with the ';
                errStr += 'Refernce Number  '  + ahaRefId + '  ' + ex.getMessage();
                System.debug(LoggingLevel.ERROR,'Exception:1: '+errStr);
                throw new DmlException(errStr);
            }
            else{
                System.debug(LoggingLevel.ERROR,'Exception:2: '+ex.getMessage());
                throw new CalloutException('Callout Exception occured while creating the Aha Idea.' + '   ' + ex.getMessage());
            }
        }

    } //  End of Method

    /**
    * @description Below Method is used to link Aha idea record within the Salesforce if Idea record exists within the salesforce otherwise create a new Idea in Salesforce and link it with the Opportunity or case
    * @param selectedAhaIdeaRecord Map of selected Aha idea record data
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    @AuraEnabled
    public static void getAhaIdeaSelectedRows(Map<String,String> selectedAhaIdeaRecord){
        String objectrecordId = '';
        try{
            if(!selectedAhaIdeaRecord.isEmpty()){
                Map<String, Object> apiResponseMap = new Map<String, Object>();
                Set<String> ideaIdSet = new Set<String>();
                for(String ahaId : selectedAhaIdeaRecord.keyset()){
                    objectrecordId = selectedAhaIdeaRecord.get(ahaId);
                    ideaIdSet.add(AhaId);
                    Map<String, Object> responseMap = ManageAhaIdeaHelper.getAhaIdeaRecordData(ahaId);
                    if(!responseMap.isEmpty()){
                        for(String  stringValue : ResponseMap.keySet()){
                            Object obj = responseMap.get(stringValue);
                            Map<String, Object> objectMap = (Map<String, Object>)obj;
                            apiResponseMap.put(stringValue,obj);
                        }
                    }
                }
                ManageAhaIdeaHelper.linkSelectedrowsWithAhaIdea(apiResponseMap,ideaIdSet,objectrecordId);
            }
        }
        catch (exception ex){
            String errorMessage = ex.getMessage();
            // Optionally, perform additional error handling or logging
            throw new AuraHandledException(errorMessage);
        }
    }//End of method

    /**
    * @description Below Method is used to get the Aha idea record from the Salesforce Idea which is linked to the Opportunity or Case
    * @param objectRecordId Record ID of the Opportunity or Case
    * @return List<Aha_Ideas__c> List of linked Aha Ideas records
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    @AuraEnabled
    public static List<Aha_Ideas__c> getLinkedAhaIdeaRecords(String objectRecordId){
        try{
            List<Aha_Ideas__c> ahaIdeaList = new List<Aha_Ideas__c>();
            Map<String, String> ahaLinkedMap = new Map<String, String>();
            if(!String.isEmpty(objectRecordId)){
                Set<Id> ahaIdeaId = new Set<Id>();
                for(Aha_Idea_Link__c ideaLink : [SELECT id,Aha_Ideas__c, Aha_Ideas__r.Aha_Idea_Number__c,
                                                 Aha_Ideas__r.Idea_Description__c,Aha_Ideas__r.Name,
                                                 Aha_Ideas__r.Aha_Unique_ID__c FROM Aha_Idea_Link__c
                                                 WHERE (Case_Number__c=: objectRecordId OR Opportunity_Name__c=: objectRecordId)]){
                                                     if(ideaLink.Aha_Ideas__c!= null
                                                        && ideaLink.Aha_Ideas__r.Aha_Unique_ID__c!= null){
                                                            Aha_Ideas__c ahaidea = new Aha_Ideas__c(id=ideaLink.Aha_Ideas__c);
                                                            ahaidea.Aha_Unique_ID__c = ideaLink.Aha_Ideas__r.Aha_Unique_ID__c;
                                                            ahaidea.Name = ideaLink.Aha_Ideas__r.Name;
                                                            ahaidea.Idea_Description__c = ideaLink.Aha_Ideas__r.Idea_Description__c;
                                                            ahaIdeaList.add(ahaidea);
                                                        }
                                                 }
            }
            return AhaIdeaList;
        }
        catch (exception ex){
            String errorMessage = ex.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }//End of method

    /**
    * @description Below Method is used to get the Escalated Aha idea record from the Salesforce Aha Idea Link Record which is linked to the Opportunity or Case
    * @param objectRecordId Record ID of the Opportunity or Case
    * @return List<Aha_Ideas__c> List of escalated Aha Ideas records
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    @AuraEnabled
    public static List<Aha_Ideas__c> getEscalateAhaIdeaRecords(String objectRecordId){
        try{

            Map<String, String> ahaLinkedMap = new Map<String, String>();
            List<Aha_Ideas__c> ahaIdeaList = new List<Aha_Ideas__c>();
            if(!String.isEmpty(objectRecordId)){
                Set<Id> AhaIdeaId = new Set<Id>();
                for(Aha_Idea_Link__c ideaLink : [SELECT Id,Aha_Ideas__c,Aha_Ideas__r.Name,Aha_Ideas__r.Aha_Idea_Number__c,
                                                 Aha_Ideas__r.Idea_Description__c,
                                                 Aha_Ideas__r.Aha_Unique_ID__c FROM Aha_Idea_Link__c
                                                 WHERE (Case_Number__c=: objectRecordId OR Opportunity_Name__c=: objectRecordId)
                                                 AND (Aha_Ideas__r.Escalation__c = 'No' OR Aha_Ideas__r.Escalation__c = null)]){
                                                     if(ideaLink.Aha_Ideas__c!= null
                                                        && ideaLink.Aha_Ideas__r.Aha_Unique_ID__c!= null){
                                                            Aha_Ideas__c ahaIdea = new Aha_Ideas__c(id=ideaLink.Aha_Ideas__c);
                                                            ahaIdea.Aha_Unique_ID__c = ideaLink.Aha_Ideas__r.Aha_Unique_ID__c;
                                                            ahaIdea.Name = ideaLink.Aha_Ideas__r.Name;
                                                            ahaIdea.Idea_Description__c = ideaLink.Aha_Ideas__r.Idea_Description__c;
                                                            ahaIdeaList.add(ahaIdea);
                                                        }
                                                 }
            }
            return ahaIdeaList;
        }
        catch (exception ex){
            String errorMessage = ex.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }//End of method

    /**
    * @description Below Method is used to Unlink the idea from the opportunity or Case
    * @param selectedAhaIdeaRecord Map of selected Aha idea record data
    * @param action Action to perform on the Aha idea record
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    @AuraEnabled
    public static void performActionOnAhaIdeaRecord(Map<String,String> selectedAhaIdeaRecord, String action){
        Map<String, Object> apiResponseMap = new Map<String, Object>();
        String objectrecordId = '';
        String ahaRefId = '';
        Set<String> ahaIDeaId = new Set<String>();
        try{
            if(!selectedAhaIdeaRecord.isEmpty()){
                for(String ahaId : selectedAhaIdeaRecord.keyset()){
                    ahaRefId = ahaId;
                    objectrecordId = selectedAhaIdeaRecord.get(ahaId);
                    ahaIdeaId.add(ahaId);
                    Map<String, Object> responseMap = ManageAhaIdeaHelper.getAhaIdeaRecordData(ahaId);
                    if(!responseMap.isEmpty()){
                        for(String stringValue : responseMap.keySet()){
                            Object obj = responseMap.get(stringValue);
                            Map<String, Object> objectMap = (Map<String, Object>)obj;
                            apiResponseMap.put(stringValue,obj);
                        }
                    }
                }
                if(!String.isBlank(action) && action == 'Unlink'){
                    ManageAhaIdeaHelper.updateSelectedrowsinAhaIdea(apiResponseMap,ahaIDeaId,objectrecordId,action);
                }
                else if(!String.isBlank(action) && action == 'Escalate'){
                    ManageAhaIdeaHelper.updateSelectedrowsinAhaIdea(apiResponseMap,ahaIDeaId,objectrecordId,action);
                }
            }
        }
        catch (exception ex){
            String errorMessage = ex.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
    * @description Below method is used to show the Idea Detail Page on Preview Button and called from ahaIdeaCustomDetailPage Lwc Component
    * @param ahaId Aha Idea record ID
    * @return Aha_Ideas__c Aha Ideas record
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    @AuraEnabled
    public static Aha_Ideas__c getAhaIdeaRecord(String ahaId){
        Aha_Ideas__c newAhaIdea = new Aha_Ideas__c();
        try{
            if(!String.isEmpty(ahaId)){
                Map<String, Object> apiResponseMap = ManageAhaIdeaHelper.getAhaIdeaRecordData(ahaId);
                String objectId = '';
                if(!apiResponseMap.isEmpty()){
                    Map<String,String> AhaIdeafieldNameandValue = new Map<String,String>();
                    for(String apiResponseString : apiResponseMap.keyset()){
                        object obj = apiResponseMap.get(apiResponseString);
                        Map<String, Object> objectMap = (Map<String, Object>)obj;

                        string ahaIdearefno = (String) objectMap.get('reference_num');
                        string ahaIdeaRecordId = (String) objectMap.get('id');
                        String ahaIdeaName = (String) objectMap.get('name');
                        if(!String.isBlank(ahaIdearefno)&& !String.isBlank(ahaIdeaRecordId)){
                            newAhaIdea.Aha_Unique_ID__c = ahaIdearefno;
                            newAhaIdea.Name = ahaIdeaName;
                            newAhaIdea.Aha_Idea_Number__c = ahaIdeaRecordId;
                        }
                        //get description value
                        Map<String, Object> descrecords = (Map<String, Object>)objectMap.get('description');
                        List<Object> customfieldvalobj = (List<Object>) objectMap.get('custom_fields');
                        Map<String, Object> statusFieldValObj = (Map<String, Object>)objectMap.get('workflow_status');
                        for(Object objNew : customfieldvalobj){
                            Map<String, Object> objMap = (Map<String, Object>) objNew;
                            String name = String.valueof(objMap.get('name'));
                            String value = String.valueof(objMap.get('value'));
                            string fieldValue = '';
                            if(!String.isblank(value)){
                                fieldValue = value.trim();
                            }
                            else{
                                fieldValue = 'N/A';
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
                            if(ahaIdeafieldNameandValue.containsKey('Escalation?')){
                                newAhaIdea.Escalation__c = ahaIdeafieldNameandValue.get('Escalation?');
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
                            if(ahaIdeafieldNameandValue.containsKey('Priority')){
                                newAhaIdea.Priority__c = ahaIdeafieldNameandValue.get('Priority');
                            }
                            // if(ahaIdeafieldNameandValue.containsKey('Product Component')){
                            //    newAhaIdea.Product_Component__c = ahaIdeafieldNameandValue.get('Product Component');
                            // }
                            if(ahaIdeafieldNameandValue.containsKey('Strategic/Major Account?')){
                                newAhaIdea.Strategic_Major_Account__c = Integer.valueof(ahaIdeafieldNameandValue.get('Strategic/Major Account?'));
                            }
                            if(ahaIdeafieldNameandValue.containsKey('Idea Category')){
                                newAhaIdea.Idea_Category__c = ahaIdeafieldNameandValue.get('Idea Category');
                            }
                            if(ahaIdeafieldNameandValue.containsKey('Idea Tags')){
                                String ideavalue = String.valueof(ahaIdeafieldNameandValue.get('Idea Tags'));
                                if(ideavalue.contains('(') || ideavalue.contains(')') ){
                                    ideavalue=ideavalue.replace('(','');
                                    ideavalue=ideavalue.replace(')','');
                                }
                                newAhaIdea.Idea_Tags__c = ideavalue;
                            }
                            if(ahaIdeafieldNameandValue.containsKey('Account Preference')){
                                String acc_Preferenceval = ahaIdeafieldNameandValue.get('Account Preference');
                                if(acc_Preferenceval.contains('(') || acc_Preferenceval.contains(')') ){
                                    acc_Preferenceval=acc_Preferenceval.replace('(','');
                                    acc_Preferenceval=acc_Preferenceval.replace(')','');
                                }
                                newAhaIdea.Account_Preference__c = acc_Preferenceval ;
                            }
                            if(!String.isempty(String.valueof(descrecords.get('body')))){
                                String desciptionValue = String.valueof(descrecords.get('body'));
                                newAhaIdea.Idea_Description__c = desciptionValue.stripHtmlTags();
                            }
                        }
                    }
                }//End of main if
            }//end of If
            return newAhaIdea;
        }//End of try
        catch (exception ex){
            String errorMessage = ex.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }//End of Method

     /**
    * @description Below Method is used to get the Escalate idea records which is linked with the opportunity or Case
    * @param rcId Record ID of the Aha Ideas record
    * @return Aha_Ideas__c Aha Ideas record with escalation information
    * @Author Grazitti Interactive
    * @CreatedDate 08/09/2023
    */
    @AuraEnabled
    public static Aha_Ideas__c getAhaIdeaRecordValue(Id rcId){
        if(!String.isBlank(rcId)){
             Aha_Ideas__c ideaRec = [Select id,name,Aha_Unique_ID__c,Escalation__c from Aha_Ideas__c where Id =: rcId];
             return ideaRec;
        }
        return null;
    }


}// End of Class