public with sharing class OpportunityStageDownGradeBatch implements Database.Batchable<SObject>, Database.Stateful{
    public List <Custom_Error_Log__c> errLogs = new List <Custom_Error_Log__c> ();
    public final string CLASS_NAME = 'OpportunityStageDownGradeBatch';
    public List<String> errorsnewSCList = new List<String>();
    public final string ERROR_FUNCTIONALITY = 'OpportunityStageDownGradeBatch';
     
    public Database.queryLocator start(Database.BatchableContext batchContext){
        Set<String> stageNameSet = new Set<String>{'0 Nurture', '1 Discovery', '2 Consensus','3 Technical Validation','4 Business Justification','5 Negotiate & Close'};
        Opportunity_Stage_Days__c stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
        Date lastStageChangeCutOffDate = stageDays.Stage_Change_Cut_Off_Date__c;
        ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        String queryStr = 'SELECT Id, StageName, Days_in_Current_Stage__c, Time_of_Last_Stage_Change__c,Next_Step_date_time__c, CloseDate, Technical_Validation_Completed__c, CreatedDate, Stage_2_RSM_Validation__c, Stage_3_Ready_for_TechnicalValidation__c, First_Stage_Changed_Date_Between_3to5__c, Stage_5_RSM_Validation__c FROM Opportunity WHERE RecordTypeId = :oppRecTypeIdSalesOpp AND StageName in :stageNameSet AND Opportunity_Type__c IN (\'Existing Customer\', \'New Customer\') AND Opportunity_Sub_Type__c IN (\'MSP\', \'Regular\')';
        if(lastStageChangeCutOffDate != null){
            queryStr = queryStr + (Test.isRunningTest() ? '' : ' AND Time_of_Last_Stage_Change__c != null and Time_of_Last_Stage_Change__c >= :lastStageChangeCutOffDate');
        }
        return Database.getQueryLocator(queryStr); 
    }
    public void execute(Database.BatchableContext batchContext, List<Opportunity> oppList){
        system.debug('oppList**'+ oppList);
        Opportunity_Stage_Days__c stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
        Date todayDate =System.Today();
        List<Period> periodList = [select Number, FiscalYearSettings.Name, Type, StartDate, EndDate from Period  where Type = 'Quarter' and StartDate <= TODAY and EndDate >= TODAY];
        Period currentQuarter = null;
        boolean is14thDayOfCurrentQuarter = false;
        if(!periodList.isEmpty()){
            currentQuarter = periodList[0];
            is14thDayOfCurrentQuarter = (currentQuarter.StartDate.daysBetween(todayDate) == stageDays.Day_of_Quarter_for_Close_Date_Extend__c);
        }
        System.debug(currentQuarter + '\n' + is14thDayOfCurrentQuarter + ' = is14thDayOfCurrentQuarter ~~~~1\n' + (currentQuarter.StartDate.daysBetween(todayDate))); 
        List<Opportunity> updateOppList = new List<Opportunity>();
        for(Opportunity opp : oppList){
            boolean isStageChangeRequired = false;
            //Date lastStageChangeDate = (opp.Time_of_Last_Stage_Change__c == null) ? opp.CreatedDate.date() : opp.Time_of_Last_Stage_Change__c.date();
            Date lastStageChangeDate = opp.Time_of_Last_Stage_Change__c.date();
            Integer stageAge = (Integer)opp.Days_in_Current_Stage__c;
            System.debug(lastStageChangeDate + ' = lastStageChangeDate ~~~~1\n' + opp); 
            switch on opp.StageName {
                when '0 Nurture' {
                    //Once an Opportunity has been at stage 0 Nurture for 24 months (stage duration) the system should automatically change the stage to “7 Closed Lost”.
                    isStageChangeRequired = ( stageAge  > stageDays.Max_Days_for_Stage_0__c );
                    opp.StageName = isStageChangeRequired ? '7 Closed Lost' : opp.StageName;
                    if(isStageChangeRequired){
                        opp.Lost_Reason__c = 'Sales Play Not Valid';
                    }
                }when '1 Discovery' {
                    //Next_Step_date_time__c: It get set on Next_Step__c changes with current Date-time.
                    Date changeDate = opp.Next_Step_date_time__c == null ? lastStageChangeDate : opp.Next_Step_date_time__c.date();                    
                    /** If Opportunity close date is < 12 months from the Opportunity creation date and 
                     *  Opportunity sits at Stage 1 for 60 days (stage duration) the system should move the Opportunity back to stage “0 Nurture.”*/
                    isStageChangeRequired =( 
                        (opp.CreatedDate.date().daysBetween(opp.CloseDate) <= 365 && (stageAge  > stageDays.Max_Days_for_Stage_1__c)) ||   
                        (
                            /** If Opportunity close date is ≥ 12 months from the Opportunity creation date and Opportunity Age is ≥ 90 days and 
                             * “Next_Step__c” has not been changed in the last 60 days, the system should automatically change the Opportunity Stage to “0 Nurture.”
                            */
                            opp.CreatedDate.date().daysBetween(opp.CloseDate) > 365 && 
                            ((opp.CreatedDate.date().daysBetween(todayDate)) >= 90 && 
                            changeDate.daysBetween(todayDate)  > stageDays.Max_Days_for_Stage_1__c))
                        );
                    opp.StageName = isStageChangeRequired ? '0 Nurture' : opp.StageName;
                    if(is14thDayOfCurrentQuarter && opp.CreatedDate < currentQuarter.StartDate 
                        && currentQuarter.StartDate <= opp.CloseDate && opp.CloseDate <= currentQuarter.EndDate){                        //Pre-existing Stage “1 Discovery” Opportunity is not created in the quarter, and today have 14th day of the current Quarter, system will update the close date by adding 90 days to the current Opportunity close date.
                        opp.CloseDate = opp.CloseDate + 90;
                        isStageChangeRequired = true;
                    }
                }when '2 Consensus' {
                   /** If the RSM of the Opportunity Owner does not mark “Stage 2 RSM Validation” checkbox as TRUE within 14 days of the Opportunity entering Stage 2 the system should change the Opportunity Stage back to “1 Discovery.”*/
                   isStageChangeRequired = !opp.Stage_2_RSM_Validation__c && (stageAge   > stageDays.Max_Days_for_Stage_2__c);
                   opp.StageName = isStageChangeRequired ? '1 Discovery' : opp.StageName;
                }when '3 Technical Validation' {
                   /** If the SE Leadership does not mark “Ready for Technical Validation” checkbox as TRUE within 14 days of the Opportunity entering Stage 3 the system should change the Opportunity Stage back to “2 Consensus”*/
                   isStageChangeRequired = (!opp.Stage_3_Ready_for_TechnicalValidation__c && ((stageAge   > stageDays.Max_Days_for_Stage_3__c) || (opp.First_Stage_Changed_Date_Between_3to5__c != null && (opp.First_Stage_Changed_Date_Between_3to5__c.daysBetween(todayDate) > stageDays.Max_Days_for_Stage_3__c))));
                   opp.StageName = isStageChangeRequired ? '2 Consensus' : opp.StageName;
                }when '4 Business Justification' {
                    /** If an Opportunity is moved to stage “4 Business Justification” and “Technical_Validation_Completed__c” is FALSE and 
                     * the SE Manager does not mark “Technical_Validation_Completed__c” as TRUE within 14 days of the stage change 
                     * the system should Move the stage back to “3 Technical Validation.”
                     */
                    if(!opp.Stage_3_Ready_for_TechnicalValidation__c && ((stageAge   > stageDays.Max_Days_for_Stage_3__c) || (opp.First_Stage_Changed_Date_Between_3to5__c != null && (opp.First_Stage_Changed_Date_Between_3to5__c.daysBetween(todayDate) > stageDays.Max_Days_for_Stage_3__c)))){
                        opp.StageName = '2 Consensus';
                        isStageChangeRequired = true;
                    }else{
                        isStageChangeRequired = !opp.Technical_Validation_Completed__c && ( stageAge   > stageDays.Max_Days_for_Stage_4__c );
                        opp.StageName = isStageChangeRequired ? '3 Technical Validation' : opp.StageName;
                    }
                
                }when '5 Negotiate & Close' {
                    /** If an Opportunity is moved to stage “5 Negotiate & Close” and the RSM of the Opportunity Owner does not mark “Stage 5 RSM Validation” 
                     * as TRUE within 7 days of the stage change the system should change the stage back to “4 Business Justification”.
                     */
                    if(!opp.Stage_3_Ready_for_TechnicalValidation__c && ((stageAge   > stageDays.Max_Days_for_Stage_3__c) || (opp.First_Stage_Changed_Date_Between_3to5__c != null && (opp.First_Stage_Changed_Date_Between_3to5__c.daysBetween(todayDate) > stageDays.Max_Days_for_Stage_3__c)))){
                        opp.StageName = '2 Consensus';
                        isStageChangeRequired = true;
                    }else{
                        isStageChangeRequired = !opp.Stage_5_RSM_Validation__c && ( stageAge   > stageDays.Max_Days_for_Stage_5__c );
                        opp.StageName = isStageChangeRequired ? '4 Business Justification' : opp.StageName;
                    }
                }when else { // default optional
                    //Error Case
                }
            }

            if(isStageChangeRequired){
                System.debug(stageAge + ' = stageAge ~~~~2\n' + opp);
                updateOppList.add(opp);
            }
        }
        if(!updateOppList.isEmpty()){
            handleSaveResults(updateOppList);
        }
        
    }

    public void finish(Database.BatchableContext batchContext){
        if(!errLogs.isEmpty()){
            database.insert(errLogs, false);
            sendErrorReport();
        }
    }

    //SAL25-625
    public void handleSaveResults(List<Opportunity> updateOppList) {
        Database.SaveResult[] sRlt = Database.update(updateOppList, false);
        
        for(Integer i = 0; i < sRlt.size(); i++){
            Database.SaveResult sr = sRlt[i];
            Opportunity originalOpp = updateOppList[i];
            
            if(sr.isSuccess()){
                System.debug('Successfully updated record: ' + originalOpp.Id);
            }else{
                for(Database.Error err : sr.getErrors()){
                    errLogs.add(LogError.CreateDMLErrorLog(CLASS_NAME, originalOpp.Id, err.getMessage(), ERROR_FUNCTIONALITY));
                    String recordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + originalOpp.Id;
                    errorsnewSCList.add('<b><a href="' + recordUrl + '">' + recordUrl + '</a></b> ::' + JSON.serialize(sr.getErrors()));
                    System.debug('The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields affected by this error: ' + err.getFields());
                }
            }
        }
    }

    //SAL25-625
    public void sendErrorReport() {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        String supportEmail = System.Label.SalesApps_Support_Email;
        String[] toAddresses = new List<String>{supportEmail};
        emailMessage.setToAddresses(toAddresses);
        emailMessage.setSubject('Opportunity Stage Downgrade Batch Errors - ' + Date.today().format());

        String messageBody = 'Below is a list of Opportunity Stage Downgrade errors: <br/><br/>';
        if(!errLogs.isEmpty() || Test.isRunningTest()){
            messageBody += '<b>Error Log Records:</b> <br/>';
            for (Custom_Error_Log__c log : errLogs) {
                String logRecordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;
                messageBody += '<b><a href="' + logRecordUrl + '">' + logRecordUrl + '</a></b><br/>';
            }
            messageBody += '<br/>';
        }

        messageBody += 'Thank you';
        emailMessage.setHtmlBody(messageBody);
        emailMessage.setSaveAsActivity(false);

        if(!Test.isRunningTest() && !errorsnewSCList.isEmpty()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailMessage});
            System.debug('Email sent successfully.');
        }
    }
}