/**
 * @description PQLOpptyReminder SAL25-939 - Send email notification to managers if stage is not changed withing 7 days for PQL oppty
 * @Developer    Rubrik Dev
 * @Date         03/18/2025
 * @Test Class   PQLOpptyReminderTest
 */
public class PQLOpptyReminder implements Database.Batchable<sObject>,Database.Stateful{
    public string CLASS_NAME = 'PQLOpptyReminder';
    public string ERROR_FUNCTIONALITY = 'PQL';
    Integer pqlLastOwnerChangeDay = Integer.ValueOf(System.Label.PQL_Stage_Change_Reminder_Day);
    public Map<string,Custom_Error_Log__c> errorLogs = new Map<string,Custom_Error_Log__c>();
    public static ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
    /**
     * @description start method to get pql records to send reminder email
     * @param BC
     * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string query;
        String stageToInclude = '0 Nurture';
        String opptySource = 'Product Qualified Lead (PQL)';
        try{
            query = 'SELECT Id,Account.Adaptive_Territory_Id__c,Opportunity_Source__c,OwnerId, Owner.ManagerId,Co_Owner__c,Co_Owner__r.ManagerId FROM Opportunity WHERE StageName =: stageToInclude'+
            ' and PQL_Reminder_Email_Sent__c = false and Opportunity_Source__c =:opptySource and Days_in_Current_Stage__c  >=:pqlLastOwnerChangeDay and RecordTypeId =:oppRecTypeIdSalesOpp';
        }catch(exception e){
            insert LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY);
        }
        return Database.getQueryLocator(query);
    }
    /**
     * @description execute method to send pql remonder email
     * @param BC
     * @param OppList
     * @retun void
    */
    public void execute(Database.BatchableContext BC,List<Opportunity> OppList){
        Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
        Set<string> territoryAdaptiveIds = new Set<string>();
        List<Opportunity> opptyWithBlankManager = new List<Opportunity>();
        Map<Id,Id> recipientMap = new Map<Id,Id>();
        try{           
            List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();   
                Email_Preferences__mdt EmailPreference = Email_Preferences__mdt.getInstance('PQL_Sender_Email');
                if(EmailPreference.From__c!=null){
                    owea  = [select Id from OrgWideEmailAddress where Address =: EmailPreference.From__c];
                }
            EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Markup  from EmailTemplate where DeveloperName ='Notify_if_PQL_oppty_no_change_notice'];
            for(Opportunity opp : OppList){
                if(opp.Owner.ManagerId != null){
                    messaging.singleEmailMessage mail = setMailAttributes(opp.Owner.ManagerId,emailTemplate.Id,opp.Id,owea);
                    mails.add(mail);
                    opp.PQL_Reminder_Email_Sent__c = true;
                    updateOppMap.put(opp.Id,opp);
                }else{
                    territoryAdaptiveIds.add(opp.Account.Adaptive_Territory_Id__c);
                    opptyWithBlankManager.add(opp);
                }
                if(opp.Co_Owner__c !=null && opp.Co_Owner__r.ManagerId != null){
                    messaging.singleEmailMessage mail = setMailAttributes(opp.Co_Owner__r.ManagerId,emailTemplate.Id,opp.Id,owea);
                    mails.add(mail);
                    opp.PQL_Reminder_Email_Sent__c = true;
                    updateOppMap.put(opp.Id,opp);
                }
            }
            if(!territoryAdaptiveIds.IsEmpty()){
                List<string> territoryTypes = new List<string>{'Region','Area','Theatre'};
                Map<String, String> TerrType_OwnerRole = getTerritoryOwnerMapping(territoryTypes);   
                recipientMap = getmultiLevelTerritoryMap(territoryAdaptiveIds,TerrType_OwnerRole,opptyWithBlankManager);
            }

            for(Id opptyId : recipientMap.keySet()){
                messaging.singleEmailMessage mail = setMailAttributes(recipientMap.get(opptyId),emailTemplate.Id,opptyId,owea);
                mails.add(mail);
                if(!updateOppMap.containsKey(opptyId)){
                    opportunity opp = new Opportunity(Id = opptyId,PQL_Reminder_Email_Sent__c = true);
                    updateOppMap.put(opp.Id,opp);
                }                
            }
            if(!mails.IsEmpty()) Messaging.sendEmail(mails);
            If(!updateOppMap.values().IsEmpty()) update updateOppMap.values();

        }catch(exception err){
            if(errorLogs.isEmpty() || !errorLogs.containskey(err.getMessage())){
                errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = err.getMessage(),Class__c = CLASS_NAME,FailedRecords__c=null, ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+err.getTypeName(),'Trace : '+err.getStackTraceString()})));
            }            
        }
        
    }
    /**
     * @description finish method to insert error log if exist
     * @param BC
    */
    public void finish(Database.BatchableContext BC) {
        List<Custom_Error_Log__c> customErrorLogs = new List<Custom_Error_Log__c>();        
        try{
            if(!errorLogs.values().isEmpty()){
                List<Database.SaveResult> errList = database.insert(errorLogs.values(),false);
                for (Database.SaveResult sr : errList) {
                    if (sr.isSuccess()) {
                        customErrorLogs.add(new Custom_Error_Log__c(Id = sr.getId()));
                    }
                }
                if(!customErrorLogs.IsEmpty()){
                    string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(customErrorLogs);
                    EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                                     'PQLOpptyReminder salesopsbatcherror - ' + Date.today().format(),
                                                     emailDetail); 
                }
            }
        }catch(Exception e){
            system.debug(LoggingLevel.DEBUG, '@@ exception '+e.getMessage());
        }
    }
    /**
     * @description setMailAttributes method to set email attribute
     * @param recipientId
     * @param emailTemplateId
     * @param OpptyId 
     * @param owea
     * @return mail
    */
    public  messaging.singleEmailMessage setMailAttributes(Id recipientId, Id emailTemplateId, Id OpptyId, List<OrgWideEmailAddress> owea){
        messaging.singleEmailMessage mail = messaging.renderStoredEmailTemplate(emailTemplateId,recipientId,OpptyId);
        if (!owea.isEmpty()) {
            mail.setOrgWideEmailAddressId(owea[0].Id);
        }
        mail.setTemplateID(emailTemplateId);
        mail.setSaveAsActivity(false);
        mail.setHtmlBody(mail.getHTMLBody());
        mail.setTargetObjectId(recipientId);
        mail.setWhatId(OpptyId);
        mail.setSubject(mail.getSubject());
        return mail;
    }

    /**
     * @description getmultiLevelTerritoryMap method to set email attribute
     * @param territoryAdaptiveIds
     * @param TerrType_OwnerRole
     * @param opptyWithBlankManager 
     * @return opptyVSuserMap
    */
    public Map<Id,Id> getmultiLevelTerritoryMap(Set<string> territoryAdaptiveIds, Map<String, String> TerrType_OwnerRole,List<Opportunity> opptyWithBlankManager){
        Map<string,Territory2> terr_Map = new Map<string,Territory2>();
        Map<string,string> multiLevelTerritoryMap = new Map<string,string>();
        Map<string,Map<string,string>> terrUserMap = new Map<string,Map<string,string>>();
        Map<Id,Id> opptyVSuserMap = new Map<Id,Id>();
        List<Territory2> territoryList = [Select id, Territory2Type.DeveloperName, Adaptive_Territory_Id__c,ParentTerritory2Id, ParentTerritory2.Territory2Type.DeveloperName, ParentTerritory2.Adaptive_Territory_Id__c, ParentTerritory2.ParentTerritory2Id, ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName,ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c ,
        ParentTerritory2.ParentTerritory2.ParentTerritory2Id, ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c,ParentTerritory2.ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName from Territory2 where Adaptive_Territory_Id__c IN:territoryAdaptiveIds and Territory2Type.DeveloperName = 'Territory' and Territory2Model.state='Active'];
        for (Territory2 territoryObj : territoryList) {
            if(territoryObj.ParentTerritory2Id != null && !String.isBlank(territoryObj.ParentTerritory2.Adaptive_Territory_Id__c) && TerrType_OwnerRole.ContainsKey(territoryObj.ParentTerritory2.Territory2Type.DeveloperName)){
                multiLevelTerritoryMap.put(territoryObj.ParentTerritory2.Adaptive_Territory_Id__c,TerrType_OwnerRole.get(territoryObj.ParentTerritory2.Territory2Type.DeveloperName));
            }
            if(territoryObj.ParentTerritory2.ParentTerritory2 != null && !String.isBlank(territoryObj.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c) && TerrType_OwnerRole.ContainsKey(territoryObj.ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName)){
                multiLevelTerritoryMap.put(territoryObj.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c,TerrType_OwnerRole.get(territoryObj.ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName));
            }
            if(territoryObj.ParentTerritory2.ParentTerritory2.ParentTerritory2 != null && !String.isBlank(territoryObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c) && TerrType_OwnerRole.ContainsKey(territoryObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName)){
                multiLevelTerritoryMap.put(territoryObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c,TerrType_OwnerRole.get(territoryObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName));
            }          
            terr_Map.put(territoryObj.Adaptive_Territory_Id__c,territoryObj);
        }
        if(!multiLevelTerritoryMap.KeySet().IsEmpty()){
            List<UserTerritory2Association> userTerritoryList = [Select id,UserId,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2 from UserTerritory2Association where Territory2.Territory2Model.state='Active' AND User.IsActive = true and Territory2.Adaptive_Territory_Id__c IN : multiLevelTerritoryMap.KeySet() and RoleInTerritory2 IN :TerrType_OwnerRole.Values()];          
            for(UserTerritory2Association userterr : userTerritoryList){
                if(terrUserMap.containsKey(userterr.Territory2.Adaptive_Territory_Id__c)){
                    if(!terrUserMap.get(userterr.Territory2.Adaptive_Territory_Id__c).containsKey(userterr.RoleInTerritory2)){
                        Map<string,Id> mp = terrUserMap.get(userterr.Territory2.Adaptive_Territory_Id__c);
                        mp.put(userterr.RoleInTerritory2,userterr.UserId);
                        terrUserMap.put(userterr.Territory2.Adaptive_Territory_Id__c,mp);
                    }
                }else{
                    Map<string,Id> mp = new Map<string,string>();
                    mp.put(userterr.RoleInTerritory2,userterr.UserId);
                    terrUserMap.put(userterr.Territory2.Adaptive_Territory_Id__c,mp);
                } 
            }
        }
        for(Opportunity opp : opptyWithBlankManager){
            if(terr_Map.ContainsKey(opp.Account.Adaptive_Territory_Id__c)){
                Territory2 trrObj = terr_Map.get(opp.Account.Adaptive_Territory_Id__c);
                if(terrUserMap.ContainsKey(trrObj.ParentTerritory2.Adaptive_Territory_Id__c) && multiLevelTerritoryMap.containskey(trrObj.ParentTerritory2.Adaptive_Territory_Id__c)){
                    map<string,string> terrmap = terrUserMap.get(trrObj.ParentTerritory2.Adaptive_Territory_Id__c);
                    Id userId = terrmap.get(multiLevelTerritoryMap.get(trrObj.ParentTerritory2.Adaptive_Territory_Id__c));
                    opptyVSuserMap.put(opp.Id,userId);
                    continue;
                }
                if(terrUserMap.ContainsKey(trrObj.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c) && multiLevelTerritoryMap.containskey(trrObj.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c)){
                    map<string,string> terrmap = terrUserMap.get(trrObj.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c);
                    Id userId = terrmap.get(multiLevelTerritoryMap.get(trrObj.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c));
                    opptyVSuserMap.put(opp.Id,userId);
                    continue;
                }
                if(terrUserMap.ContainsKey(trrObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c) && multiLevelTerritoryMap.containskey(trrObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c)){
                    map<string,string> terrmap = terrUserMap.get(trrObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c);
                    Id userId = terrmap.get(multiLevelTerritoryMap.get(trrObj.ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c));
                    opptyVSuserMap.put(opp.Id,userId);
                    continue;
                }
            }
            
        } 
        return opptyVSuserMap; 
    }
    /**
     * @description getTerritoryOwnerMapping method to get map of territory user role
     * @param territoryTypes
     * @return roleMapping
    */
    private Map<String, String> getTerritoryOwnerMapping(List<string> territoryTypes) {
        Map<String, String> roleMapping = new Map<String, String>();
        for(Territory_Management_Setup__mdt fielSalesMdt : [select DeveloperName,Field_API_Name__c,Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName = 'Con_UTA_RoleInTerritory2' Limit 1]){
            if(fielSalesMdt.Field_Value__c != null){
                for(string userRoleList: fielSalesMdt.Field_Value__c.split(';')){
                    if(userRoleList.contains(':')){
                        List<String> roleParts = userRoleList.split(':');
                        if (roleParts.size() == 2) {
                            if(territoryTypes.contains(roleParts[0])){
                                roleMapping.put(roleParts[0].trim(), roleParts[1].trim());
                            }                            
                        }
                       
                    }
                }
            }
        }
        return roleMapping;
    }

}