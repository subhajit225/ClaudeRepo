public with sharing class SandboxRefreshUtil {
    public static final String EMAIL_SUFFIX = '.sandbox';
    public static final Map<String, Integer> PRIORITY_MAP = new Map<String, Integer>{'Contact' => 210, 'Account' => 220, 'Opportunity' => 230, 'Lead' => 260, 'Case' => 270, 'EmailMessage' => 280};
    public static final Map<String, Integer> SPLIT_BATCH = new Map<String, Integer>{'Contact' => 3, 'Opportunity' => 2, 'Lead' => 4, 'Case' => 4};
    public static final Map<Integer, Integer> BATCH_SIZE_SESET_MAP = new Map<Integer, Integer>{200 => 200, 100 => 100, 50 => 50, 20 => 20, 1 => 1};
    public static final Integer MAX_ERROR_COUNTS = 20;

    
    public static ID scheduleNextBatch(Integer scheduleInMinutes){
        SandboxRefreshUtil.updateSandboxRefreshConfig('Initiate Email Masking', 'Completed', '');
        return scheduleNextBatch(scheduleInMinutes, null);
    }
    public static ID scheduleNextBatch(Integer scheduleInMinutes, String objectApiName){
        ID jobID = null;
        List<Sandbox_Refresh_Config__c> sandboxRefreshConfigList = getObjectForMasking(objectApiName);
        if(!sandboxRefreshConfigList.isEmpty()){
            Sandbox_Refresh_Config__c sandboxRefreshConfigObj = sandboxRefreshConfigList[0];          
            
            sandboxRefreshConfigObj.BatchSize__c = (sandboxRefreshConfigObj.Status__c != 'Not Started') ? (SandboxRefreshUtil.BATCH_SIZE_SESET_MAP.get(Integer.valueOf(sandboxRefreshConfigObj.BatchSize__c)) ): sandboxRefreshConfigObj.BatchSize__c;
            sandboxRefreshConfigObj.BatchSize__c = sandboxRefreshConfigObj.BatchSize__c == null ? 100 : sandboxRefreshConfigObj.BatchSize__c;
            Datetime dt = Datetime.now().addMinutes(scheduleInMinutes);
            
            SandboxRefreshEmailMaskingScheduler scheduleClass  = String.isBlank(objectApiName) ? new SandboxRefreshEmailMaskingScheduler() : new SandboxRefreshEmailMaskingScheduler(objectApiName);
            String jobName = 'EmailMasking: ' + sandboxRefreshConfigObj.ObjectLabel__c + '-' + sandboxRefreshConfigObj.BatchSize__c + dt.format('~dd-HH_mm_ss') + (String.isBlank(objectApiName) ? 'A' : 'M');
            jobID = System.Schedule(jobName, dt.format('s m H d M \'?\' yyyy'), scheduleClass);
        }
            
        return jobID;
    }

    public static void scheduleParallelBatch(Sandbox_Refresh_Config__c sandboxRefreshConfigObj){
        System.debug(sandboxRefreshConfigObj);
        if(!sandboxRefreshConfigObj.isInitiatedManually__c && sandboxRefreshConfigObj.Status__c == 'Not Started' && sandboxRefreshConfigObj.BatchSize__c == 200){
            if(sandboxRefreshConfigObj.Name == 'Contact-0'){
                scheduleNextBatch(1, 'Contact-2');
                scheduleNextBatch(2, 'Contact-3');
            }
            if(sandboxRefreshConfigObj.Name == 'Account'){
                scheduleNextBatch(1, 'Lead-4');
                scheduleNextBatch(2, 'Lead-1');
                scheduleNextBatch(3, 'Case-4');
                scheduleNextBatch(4, 'Opportunity-2');
            }
            if(sandboxRefreshConfigObj.Name == 'Opportunity-0'){
                scheduleNextBatch(1, 'Lead-2');
                scheduleNextBatch(2, 'Lead-3');
                scheduleNextBatch(3, 'Lead-0');

                scheduleNextBatch(1, 'Case-0');
                scheduleNextBatch(1, 'Case-1');
                scheduleNextBatch(3, 'Case-2');
                scheduleNextBatch(4, 'Case-3');
            }
        }
    }

    
    public static List<Sandbox_Refresh_Config__c> getObjectForMasking(String objectApiName){
        String query = 'SELECT Id, Name, ObjectLabel__c, isInitiatedManually__c, EmailFields__c,Execution_Order__c, Status__c, LastFailedRecordCount__c, BatchSize__c, Query__c, ProcessType__c, ParentTask__c, CreatedDate' +
            ' FROM Sandbox_Refresh_Config__c  WHERE Type__c = \'Email Mask\' AND  Status__c IN (\'Not Started\', \'Processing\') AND ';
        query += String.isBlank(objectApiName) ? ' isInitiatedManually__c = false' : ' Name = : objectApiName ';
        query += ' ORDER BY Execution_Order__c, Name ASC';
        List<Sandbox_Refresh_Config__c> sandboxRefreshConfigList = Database.query(query);
        return sandboxRefreshConfigList;
    }

    public static String getEmailObjectsFilter(String objectName, List<String> fieldNameList){
        String filterCondition = '';
        for(string fieldName : fieldNameList){
            if(String.isNotBlank(filterCondition)){
                filterCondition += ' OR ';
            }
            filterCondition += ' (' + fieldName + ' != null AND (NOT ' + fieldName + ' LIKE \'%' + SandboxRefreshUtil.EMAIL_SUFFIX + '\'))';
        }

        system.debug('======filterCondition======='+filterCondition);
        return filterCondition;
    }

    public static List<Sandbox_Refresh_Config__c> splitConfig(Sandbox_Refresh_Config__c configObj, Integer noOfParts){
        List<Sandbox_Refresh_Config__c> splitConfigList = new List<Sandbox_Refresh_Config__c>();
        Integer yr = System.today().year();
        for(Integer i = 1; i <= noOfParts; i++){
            Sandbox_Refresh_Config__c splitConfigObj = configObj.clone();
            splitConfigObj.Execution_Order__c = configObj.Execution_Order__c + i;
            splitConfigList.add(splitConfigObj);
            splitConfigObj.Name = splitConfigObj.Name + '-' + i;
            if(i < noOfParts){
                splitConfigObj.ObjectLabel__c = splitConfigObj.ObjectLabel__c + ' Created in Y' + (yr - i);
                splitConfigObj.Query__c = splitConfigObj.Query__c + ' AND CALENDAR_YEAR(CreatedDate) = ' + (yr - i) + ' ';
            }else{
                splitConfigObj.ObjectLabel__c = splitConfigObj.ObjectLabel__c + ' Created till Y' + (yr - i);
                splitConfigObj.Query__c = splitConfigObj.Query__c + ' AND CALENDAR_YEAR(CreatedDate) <= ' + (yr - i) + ' ';
            }
        }
        configObj.Name = configObj.Name + '-0';
        configObj.ObjectLabel__c = configObj.ObjectLabel__c + ' Created in Y' + yr;
        configObj.Query__c = configObj.Query__c + ' AND CALENDAR_YEAR(CreatedDate) = ' + yr + ' ';

        return splitConfigList;
    }

    public static Sandbox_Refresh_Config__c getEmailMaskingObject(String objectName){
        System.debug('~~~~objectName:' + objectName);
        Sandbox_Refresh_Config__c obj = null;
        List<String> fieldNameList = new List<String>();
        Schema.DescribeSObjectResult objResult = ((SObject)Type.forName(objectName).newInstance()).getSobjectType().getDescribe();
        String emailFields = '';
        for(Schema.SObjectField field : objResult.fields.getMap().values()){
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if(Schema.DisplayType.EMAIL == fieldDescribe.getType() && fieldDescribe.isUpdateable() && !(objectName == 'User' && fieldDescribe.getName() == 'Email')){
                
                emailFields += fieldDescribe.getName() + ', ';
                fieldNameList.add(fieldDescribe.getName());
            }
        }
        if(String.isNotBlank(emailFields)){
            String filterCondition = SandboxRefreshUtil.getEmailObjectsFilter(objectName, fieldNameList);
            emailFields = emailFields.removeEnd(', ');
            obj = new Sandbox_Refresh_Config__c();
            obj.Name = objectName;
            obj.ObjectLabel__c = objResult.getLabel();
            obj.BatchSize__c = 200;
            obj.EmailFields__c = emailFields;
            obj.ObjectCode__c = objResult.getKeyPrefix();
            obj.Description__c = 'This record is required email masking.';
            obj.Type__c = 'Email Mask';
            obj.Status__c = 'Not Started';
            obj.ProcessType__c = 'Automated';
            obj.Execution_Order__c = PRIORITY_MAP.containsKey(objectName) ? PRIORITY_MAP.get(objectName) : 250;
            String queryStr = ' FROM ' + objectName + ' WHERE (' + filterCondition + ')';
            obj.Query__c = 'Select ID, ' + String.escapeSingleQuotes(String.join(fieldNameList, ', ')) + queryStr;
        
        }
        return obj;
    }

    public static List<User> getUsersToActivate(Sandbox_Refresh_Config__c newSrConfig) {
        List<User> userList = new List<User>();
        String groupNameCSV = newSrConfig.EmailFields__c;
        if(String.isNotBlank(groupNameCSV)){
            List<String> groupNameList = groupNameCSV.split(',');
            Map<Id, User> userMap = new Map<Id, User>();
            String errorMsg = '';
            for(String groupProfileName: groupNameList){
                List<String> groupProfileNameList = groupProfileName.split(':');
                if(groupProfileNameList.size() == 2 && String.isNotBlank(groupProfileNameList[0]) && String.isNotBlank(groupProfileNameList[1])){
                    userMap.putAll(SandboxRefreshUtil.getUsersFromGroup(groupProfileNameList[0].trim(), groupProfileNameList[1].trim()));
                }else{
                    errorMsg += 'Invalid GroupName:ProfileName setup for :' + groupProfileName + '. ';
                }
            }
            
            if(String.isBlank(errorMsg) && userMap.size() > 0){
                System.debug( newSrConfig.id + '~~~~~' + userMap);
                newSrConfig.Status__c = 'Processing';
                userList.addAll(userMap.values());
            }else{
                if(String.isNotBlank(errorMsg)){
                    newSrConfig.addError(errorMsg);
                    newSrConfig.Status__c = 'Failed';
                    newSrConfig.isInitiatedManually__c = false;
                }
            }
            update newSrConfig;
        }
        return userList;
    }


    private static List<User> getUsersFromGroup(String groupName, String profileName){
        System.System.debug(groupName+ '~~~~profileName: ' + profileName);
        List<User> userList = new List<User>();
        if(String.isNotEmpty(groupName)){
            Set<String> userIdSet = new Set<String>();    
            Group groupDetails = [Select id, name from group where name =:groupName];
            Profile profileInfo = [Select id,Name from profile where Name=:profileName];
            List<GroupMember> groupMemeber = [SELECT id, UserOrGroupId from GroupMember where GroupId =:groupDetails.Id];
            for(GroupMember rs :groupMemeber) {
                if(String.valueOf(rs.UserOrGroupId).subString(0,3)=='005') {
                    userIdSet.add(rs.UserOrGroupId);
                }
            }
            if(userIdSet.size()>0) {
                userList =[Select id, Name, Email, ProfileId from user  where id IN:userIdSet and isActive=true];
                if(userList.size()>0){
                    for(User userObj: userList){
                        userObj.email= userObj.email.removeEnd('.invalid');
                        userObj.profileId = profileInfo.id;
                    }
                }
            }
        }
        return userList;
    }

    
    public static void updateUsers(List<User> userList, Sandbox_Refresh_Config__c srConfigObj){
        Map<String, ID> errorMessages = new Map<String, ID>();
        Set<Id> failedRecordIDSet = new Set<Id>();
        if(userList.size()>0){
            Database.SaveResult[] results = Database.Update(userList, false); 
            Integer index = 0;
            for(Database.SaveResult result : results){
                if(!result.isSuccess()){ 
                    String errorMesaage = '';
                    Integer iCount = 1;
                    for(Database.Error error : result.getErrors()){
                        errorMesaage += error.getMessage() + '. ';
                        if(iCount++ == 3){
                            break;
                        }
                    }
                    if(errorMessages.size() <= SandboxRefreshUtil.MAX_ERROR_COUNTS){
                        errorMessages.put(errorMesaage, userList[index].id);
                    }
                    failedRecordIDSet.add(userList[index].id);
                }
                index++;
            }
        }
        String eMessage = JSON.serialize(errorMessages);
        eMessage = eMessage.length() > 5 ? eMessage : '';
        srConfigObj.NoOfRecords__c = userList.size();
        srConfigObj.LastFailedRecordCount__c = failedRecordIDSet.size();
        srConfigObj.ErrorDetails__c = eMessage.replaceAll('"', '');
        if(srConfigObj.NoOfRecords__c > 0 && srConfigObj.LastFailedRecordCount__c == srConfigObj.NoOfRecords__c){
            srConfigObj.Status__c = 'Error'; 
        }else{
            srConfigObj.Status__c = 'Completed';   
        }
    }
    public static void updateCustomActionURL (){
        List<SBQQ__CustomAction__c> actionList = new List<SBQQ__CustomAction__c>([Select Id, Name, SBQQ__URL__c from SBQQ__CustomAction__c LIMIT 1000]);
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        //baseURL = baseURL.replace('.my.salesforce.com','--c.visual.force.com');
        baseURL = baseURL.replace('.my.salesforce.com','--c.vf.force.com');
        for(SBQQ__CustomAction__c ac : actionList){
            if(ac.SBQQ__URL__c != null){
                String existingURl = ac.SBQQ__URL__c.substringBefore('/apex');
                if(existingURl != null){
                    ac.SBQQ__URL__c = ac.SBQQ__URL__c.replace(existingURl,baseURL);
                }
            }
        }
        if(!actionList.isEmpty()){
            update actionList;
        }
    }
    public static void updateTemplateContentURL (){
        List<SBQQ__TemplateContent__c> templateContentList = new List<SBQQ__TemplateContent__c>([Select Id,Name,SBQQ__CustomSource__c from SBQQ__TemplateContent__c LIMIT 1000]);
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
       // baseURL = baseURL.replace('.my.salesforce.com','--c.visual.force.com');
       baseURL = baseURL.replace('.my.salesforce.com','--c.vf.force.com'); 
        for(SBQQ__TemplateContent__c ac : templateContentList){
            if(ac.SBQQ__CustomSource__c != null){
                String existingURl = ac.SBQQ__CustomSource__c.substringBefore('/apex');
                if(existingURl != null){
                    ac.SBQQ__CustomSource__c = ac.SBQQ__CustomSource__c.replace(existingURl,baseURL);
                }
            }
        }
        if(!templateContentList.isEmpty()){
            update templateContentList;
        }
    }
    public static void disableBusinessLogicCustomSetting (){    
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_SBQQ_QuoteLine_Triggers__c=true,
            Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Lead_Validation_Rules__c=true,
            Disable_Opportunity_Triggers__c=true,
            Disable_Opportunity_Validation_Rules__c=true,
            Disable_Opportunity_Workflow_Rules__c=true,
            Disable_SBQQ_Quote_Validation_Rules__c=true,
            Disable_Opportunity_Email_Alerts__c=true,
            Disable_Task_Validation_Rules__c=true,
            Disable_Account_Triggers__c=true,
            Disable_Order_Triggers__c=true,
            Disable_Order_Validation_Rules__c=true,
            Disable_Opportunity_Old_Trigger__c=true,
            TriggerMaxLoopCount__c=1,
            Disable_Asset_Triggers__c=true,
            Disable_Task_Triggers__c=true,
            Disable_Integration_Error_Log_Trigger__c=true,
            Disable_Campaign_Member_Triggers__c=true,
            Disable_Lead_Triggers__c=true,
            Disable_Territory_Triggers__c=true,
            Disable_User_Territory_Trigger__c=true,
            Disable_Product2_Trigger__c=true,
            Disable_Product_Change_Req_Trigger__c=true,
            Disable_Entitlement_Usage_Trigger__c=true,
            Trigger_Max_Loop_Count__c=1,
            Disable_Failure_Triggers__c=true,
            Disable_CCR_Triggers__c=true,
            Disable_UpgradeSource_Trigger__c=true,
            Disable_Order_Email_Alerts__c=true,
            Disable_Quote_Email_Alerts__c=true,
            Disable_Campaign_Trigger__c=true,
            Disable_Campaign_Validation_Rules__c=true,
            Disable_ServiceContract_Trigger__c=true,
            Disable_CCR_Validation_Rules__c=true,
            Disable_Order_Old_Trigger__c=true, 
            Disable_POC_Trigger__c=true,
            Disable_OrderItem_Old_Trigger__c=true,
            Disable_Contact_Process_Builders__c = true,
            Disable_POC_Validation_Rules__c = true,            
            Disable_Case_Triggers__c = true,
            Disable_Case_Validation_Rules__c = true,
            Disable_Case_Workflow_Rules__c = true,
            Disable_ETMStageMonitoring_Triggers__c = true,
            Disable_Case_Comment_Trigger__c = true,
            Disable_Case_Comment_Workflow_Rules__c = true,
            Disable_Contact_Triggers__c = true,
            Disable_RMA_Trigger__c = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
            Disable_StagePO_Trigger__c = true
        );
        ShGl_DisableBusinessLogic__c disableBusinessLogicSavedCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
       
        if(disableBusinessLogicSavedCS.SetupOwnerId == UserInfo.getUserId()){
            disableBusinessLogicCS.id = disableBusinessLogicSavedCS.id;
        } 
        upsert disableBusinessLogicCS;
    } 

    public static void disableFunctionalityLogicCustomSetting (){    
        ShGl_DisableFunctionalityLogic__c disableFunctionalityLogic = new ShGl_DisableFunctionalityLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_Account_Old_Trigger__c=true,
            Disable_Opportunity_Old_Trigger__c=true,
            Disable_Order_Old_Trigger__c=true,
            Disable_Rubrik_Specific_Validation_Rules__c=true,
            Allow_Updating_Closed_Won_Oppty__c=true,
            Allow_Asset_Product_Account_Updates__c=true,
            DisableHoldOffLogic__c=true,
            Allow_Updating_Closed_Lost_Oppty__c=true,
            Disable_OpportunityValidationRules__c=true
        );
        ShGl_DisableFunctionalityLogic__c disableFunctionalityLogicSaved = ShGl_DisableFunctionalityLogic__c.getInstance(UserInfo.getUserId());
       
        if(disableFunctionalityLogicSaved.SetupOwnerId == UserInfo.getUserId()){
            disableFunctionalityLogic.id = disableFunctionalityLogicSaved.id;
        } 
        upsert disableFunctionalityLogic;
    } 

    public static void changeCustomSettingTriggerControl (boolean isEnabled){    
        List<TriggerControl__c> triggerControlList = TriggerControl__c.getAll().values();
        if(!triggerControlList.isEmpty()){
            for(TriggerControl__c cs: triggerControlList){
                cs.DisableTrigger__c = isEnabled;
            }
            update triggerControlList;
        }
    } 

    public static Sandbox_Refresh_Config__c updateSandboxRefreshConfig(String srConfigName, String status, String errorMsg){
        List<Sandbox_Refresh_Config__c> sandboxRefreshConfigList = [Select ID, LastBatchExecutedOn__c, Status__c from Sandbox_Refresh_Config__c where Name = :srConfigName];
        if(sandboxRefreshConfigList.size() == 1){
            if(sandboxRefreshConfigList[0].Status__c == 'Not Started' && sandboxRefreshConfigList[0].LastBatchExecutedOn__c == null){
                sandboxRefreshConfigList[0].LastBatchExecutedOn__c = System.now();
            }
            sandboxRefreshConfigList[0].Status__c = status;
            sandboxRefreshConfigList[0].ErrorDetails__c = errorMsg;
            update sandboxRefreshConfigList;
            return sandboxRefreshConfigList[0];
        }
        return null;
    }

    private static Sandbox_Refresh_Config__c createSandboxRefreshConfig(Integer Execution_Order, String ObjName, String ObjectLabel, String Status, String ObjectCode,  String Type,  String Description, String EmailFields, String processType, ID parentTaskId){
        return new Sandbox_Refresh_Config__c(Execution_Order__c = Execution_Order, Name = ObjName, ObjectLabel__c = ObjectLabel, Status__c = Status, ObjectCode__c = ObjectCode,  Type__c = Type,  Description__c = Description, EmailFields__c = EmailFields, ProcessType__c = processType, ParentTask__c = parentTaskId);
    }
    public static void createDataInDeveloperSandbox(){
        List<Sandbox_Refresh_Config__c> sandboxRefreshConfigList = [Select ID, Status__c from Sandbox_Refresh_Config__c LIMIT 1];
        if(sandboxRefreshConfigList.isEmpty()){
            List<Sandbox_Refresh_Config__c> configList = new List<Sandbox_Refresh_Config__c>();
            List<Sandbox_Refresh_Config__c> configChildList = new List<Sandbox_Refresh_Config__c>();
            //Execution_Order__c', 'Name', 'ObjectLabel__c', 'Status__c', 'ObjectCode__c', 'Type__c', 'Description__c', 'EmailFields__c');
            Sandbox_Refresh_Config__c firstConfig = createSandboxRefreshConfig(100, 'Execute Sandbox Post Refresh Script', 'Post Sandbox Refresh Tasks', 'Not Started', 'a35', 'Configuration', 'This step will initiate automatically after Sandbox Refresh, once user selected "SandboxRefreshMaster" class while Sandbox refresh.', '', 'Start Manually', null);
            configList.add(firstConfig);
            configList.add(createSandboxRefreshConfig(400, 'Confirm: Are all integration up and running?', 'All Set? Are we Ready?', 'Not Started', 'a35', 'Configuration', 'Confirm: Are all integration up and running?', '', 'Manual Changes', null));
            insert configList;
            configList.add(createSandboxRefreshConfig(110, 'Disable Triggers & Validation Rules', 'Disabled Custom Setting', 'Not Started', 'a2j/o', 'Configuration', 'It will block some of the Triggers, Validation Rules, Workflow Rules & Process Builders for login user.', '', 'Automated', firstConfig.id));
            configList.add(createSandboxRefreshConfig(120, 'Masking on Workflow Email Alerts', 'Workflow Email Alerts', 'Not Started', '01W', 'Configuration', 'Masking CC Emails in Email alerts. These are the emails that workflow rules send when triggered.', '', 'Start Manually', firstConfig.id));
            configList.add(createSandboxRefreshConfig(130, 'Email Masking in Email Preference Custom Metadata', 'Email Preference', 'Not Started', 'm0N', 'Configuration', 'Email Masking in Email Preference Custom Metadata', 'Receipient__c, cc__c', 'Automated', firstConfig.id));
            configList.add(createSandboxRefreshConfig(140, 'Update URLs', 'URL Setup', 'Not Started', 'a5n', 'Configuration', 'Change URLs in Custom Action (Go Refresh, Preview Approvals) and Template Content (Custom 7 year Payments, Line Items MDQ, Line Items MDQ Non Disti)', 'Go Refresh, Preview Approvals, Custom 7 year Payments, Line Items MDQ, Line Items MDQ Non Disti', 'Manual Changes', firstConfig.id));
            configList.add(createSandboxRefreshConfig(150, 'Delete Scheduled Reports', 'Scheduled Reports', 'Not Started', '08e?fcf=00B6f00000A0HV5', 'Configuration', 'Deletion of scheduled reports of reporty type = report run', '', 'Automated', firstConfig.id));
            configList.add(createSandboxRefreshConfig(160, 'Update URL in Admin Tab', 'APTS_UIPageConfig', 'Not Started', 'a77', 'Configuration', 'Update sandcoxs base URL in XML (given in Field Column) and set on  APTS_UIPageConfig records Code field.', '<UIPageConfig customPageURL="https://rubrikinc--rbkdev1.my.salesforce.com/"><UIAction name="publish_chatter"> <CustomPage> <Name>Apttus__PublishChatter</Name> </CustomPage></UIAction> </UIPageConfig>', 'Automated', firstConfig.id));
            configList.add(createSandboxRefreshConfig(200, 'Initiate Email Masking', 'Scheduled Jobs', 'Not Started', '08e?fcf=00B6f00000A0HRw', 'Configuration', 'In case of Email masking batch got stop due to some reason, You can continue from here.', '', 'Automated', firstConfig.id));

            configList.add(createSandboxRefreshConfig(310, 'Email-to-Case setting', 'Email-to-Case', 'Not Started', '02t', 'Configuration', 'Change Email-to-Case setting', 'Email Address', 'Manual Changes', configList[1].id));
            configList.add(createSandboxRefreshConfig(320, 'Publish Rubrik Partner Community', 'Rubrik Partner Community', 'Not Started', '_ui/networks/setup/SetupNetworksPage', 'Configuration', 'Digital Experiences -> Rubrik Partner Community -> Builder (On Top-Right corner, click on Publish Button)', '', 'Manual Changes', configList[1].id));
            configList.add(createSandboxRefreshConfig(330, 'Update Connected app configurations', 'Connected App', 'Not Started', 'app/mgmt/forceconnectedapps/forceInstalledConnectedAppList.apexp', 'Configuration', 'Update Connected app configurations to remove connection for other prod systems', '', 'Manual Changes', configList[1].id));
            configList.add(createSandboxRefreshConfig(340, 'Update Tokens (Custom Labels)', 'Update Tokens', 'Not Started', 'a35', 'Configuration', 'Update Tokens (Custom Labels)', '', 'Manual Changes', configList[1].id));
            configList.add(createSandboxRefreshConfig(350, 'Net-Suite-Update Tokens', 'Update Tokens genetated in NetSuite', 'Not Started', 'a35', 'Configuration', 'Net-Suite-Update Tokens', '', 'Manual Changes', configList[1].id));
            configList.add(createSandboxRefreshConfig(360, 'Replace Remote site settings', 'Replace Remote site settings', 'Not Started', '0rp', 'Configuration', 'Update Remote site settings as given in Fields (CSV).', 'https://apitest.rubrik.com', 'Not Required', null));
            configList.add(createSandboxRefreshConfig(370, 'API Order Automation reset Password', 'API Order Automation', 'Not Started', '005', 'Configuration', 'Now, on Every Sandbox refresh, we will not reset the password for any of the API Order Automation and Circle-CI Users. Let it reset in all other references.', '', 'Not Required', null));
            configList.add(createSandboxRefreshConfig(380, 'Update Email Address on Email service', 'Email service', 'Not Started', 'email-admin/services/listEmailServicesFunction.apexp?setupid=EmailToApexFunction', 'Configuration', 'Email service', 'Route Error Emails to This Email Address', 'Manual Changes', configList[1].id));
            configList.add(createSandboxRefreshConfig(450, 'Enable Triggers & Validation Rules', 'Enabled Custom Setting', 'Not Started', 'a2j/o', 'Configuration', 'It should be the next step after  all email masking tasks. It will turn on all the Triggers and VR.', '', 'Start Manually', null));
            configList.add(createSandboxRefreshConfig(500, 'Activate Users', 'User List', 'Not Started', '005', 'Configuration', 'Activate all the active Developer and QA users.', 'DEVELOPER_GROUP:System Administrator', 'Start Manually', null));

            configList[0].ParentTask__c = configList[1].id;
            System.debug(configList);
            upsert configList;
        }
    }

    public static void abortScheduleReportJob(){
        List<CronTrigger> reportNotificationJobs = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger where CronJobDetail.JobType IN ('A', '8') AND State = 'WAITING' ORDER BY CreatedDate ASC LIMIT 1000];
        if (!reportNotificationJobs.isEmpty() && !Test.isRunningTest()) {
            for (CronTrigger cronTriggerItem : reportNotificationJobs) {
                System.abortJob(cronTriggerItem.Id);
            }
        }
    }
    /*
    public static void updateUrlInAdminTab(){
        
        List<Apttus__APTS_Admin__c> adminList = [Select ID, Apttus__Code__c from Apttus__APTS_Admin__c where Name = 'APTS_UIPageConfig'];
        if(adminList.size() == 1){
            String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
            update new Apttus__APTS_Admin__c(ID = adminList[0].id, Apttus__Code__c = adminList[0].Apttus__Code__c.replace('https://rubrikinc.my.salesforce.com', baseURL));
        }
    }*/
}