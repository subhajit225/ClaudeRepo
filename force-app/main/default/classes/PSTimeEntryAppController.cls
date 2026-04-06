/**************************************************************************
Name: PSTimeCard
Type: Apex Class  
Purpose: Apex Class  for  lightning component  PSTimeCardController.cmp
***************************************************************************/

public class PSTimeEntryAppController{
    private static final Integer CUTOFFDAY = 26;
    private static final Integer DAYSTOADD = 24;
    //fetch top 10 time card for login user
    //
    /**
     * @description Retrieves the 10 most recent Time Card records for the current user.
     * Calculates total admin hours from related time entries and determines if each time card
     * falls within a specific approval and date range. Each time card is wrapped in a
     * TimeCardWrapper object along with permission and cutoff eligibility flags.
     *
     * @return A list of TimeCardWrapper objects containing time card data, permission flag, 
     *         and eligibility flag based on time card status and submission period.
    */
    @AuraEnabled
    public static List<TimeCardWrapper> GetTimeCards(){
        
        List<TimeCardWrapper> wrp = new List<TimeCardWrapper>();
        boolean perCheck = false;
        Map<Id, Boolean> timecardIdToHasAdminProjectMap = new Map<Id, Boolean>();
        //CHANGES EGN - 170 START
        List<String> timeEntryTaskTypes = new List<String>{'Admin','Admin Travel','CSAT','Admin PTO','Admin Internal','Admin Enablement','Non-Billable Admin','Non-Billable Admin Travel','Non-Billable CSAT','Non-Billable Admin PTO','Non-Billable Admin Internal','Non-Billable Admin Enablement','Non-Billable PreSales'};
        List<PS_Time_Card__c> PStimeCard = [SELECT id,Name, Time_Card_Start_Date__c,Time_Card_End_Date__c,
                                            Status__c,Assignee__c,Total_Billable_Hours__c,Total_Non_Billable_Hours__c,Total_Admin_Hours__c,
                                            (SELECT id,Hours_Spent__c,PS_Task__r.Project__r.Has_Admin_Project__c FROM PS_Time_Entries__r WHERE TaskType__c IN: timeEntryTaskTypes AND Billable__c = false) FROM PS_Time_Card__c 
                                            WHERE Assignee__c=: UserInfo.getUserId() 
                                            ORDER BY Time_Card_End_Date__c DESC NULLS LAST limit 10];
        for(PS_Time_Card__c psCard : PStimeCard){
            if(!psCard.PS_Time_Entries__r.isEmpty()){
                psCard.Total_Admin_Hours__c = 0;
                for(PS_Time_Entry__c entry : psCard.PS_Time_Entries__r){
                    psCard.Total_Admin_Hours__c += entry.Hours_Spent__c;
                    if(!timecardIdToHasAdminProjectMap.containsKey(psCard.Id) && entry.PS_Task__r.Project__r.Has_Admin_Project__c){
                        timecardIdToHasAdminProjectMap.put(psCard.Id , true);
                    }
                }
            }
        }
        //CHANGES EGN - 170 END
        /*User u = [select id, Profile.id, Name, userRole.Name from User where id =: userInfo.getUserId()];
        List<PermissionSetAssignment> lstcurrentUserPerSet = [SELECT Id, PermissionSet.Name, AssigneeId FROM PermissionSetAssignment 
                                                              WHERE AssigneeId = :Userinfo.getUserId() AND 
                                                              PermissionSet.Name ='PS_Time_Management_Admin_User'];
        if(u.userRole.Name == 'Admin' || !lstcurrentUserPerSet.IsEmpty()){
            perCheck = true;
        }*/
        perCheck = true;
        date weekStart = date.today().toStartofWeek();
        date past2week = weekStart.AddDays(-14);
        date future1week = weekStart.AddDays(7);        
        Date startOfThisMonth = Date.today().toStartOfMonth();
        Date twentyFifthLastMonth = startOfThisMonth.addMonths(-1).addDays(DAYSTOADD);
        Date twentyFifthThisMonth = startOfThisMonth.addDays(DAYSTOADD);

        for(PS_Time_Card__c pst : PStimeCard){
            if((pst.Status__c == 'Submitted' || pst.Status__c == 'Approval In Progress' || pst.Status__c == 'Approved') 
                && pst.Time_Card_Start_Date__c > twentyFifthLastMonth && pst.Time_Card_Start_Date__c <= twentyFifthThisMonth &&  Date.Today().Day()< CUTOFFDAY){ 
                wrp.add( new TimeCardWrapper(pst, perCheck, true, timecardIdToHasAdminProjectMap.containsKey(pst.Id) ? true : false)) ;
            }else{
                wrp.add( new TimeCardWrapper(pst, perCheck, false, timecardIdToHasAdminProjectMap.containsKey(pst.Id) ? true : false)) ;
            }
        }
        
        return wrp;        
    }
    
    /**
     * @description Retrieves the 10 most recent Time Card records for the current user.
     * Calculates total admin hours from related time entries and determines if each time card
     * falls within a specific approval and date range. Each time card is wrapped in a
     * TimeCardWrapper object along with permission and cutoff eligibility flags.
     *
     * @return A list of TimeCardWrapper objects containing time card data, permission flag, 
     *         and eligibility flag based on time card status and submission period.
     */
    @AuraEnabled
    public static list<PS_Time_Card__c> GetTimeCard(){
        return [select id,Name, Time_Card_Start_Date__c,Time_Card_End_Date__c,
                Status__c,Assignee__c,Total_Billable_Hours__c from PS_Time_Card__c 
                WHERE Assignee__c=: UserInfo.getUserId() 
                ORDER BY Time_Card_End_Date__c DESC NULLS LAST limit 10];  
    }
    
    @AuraEnabled
    public static List<TimeCardWrapper> UnlockRecordMethod(String TimeCardIdList)
    {      
        if(TimeCardIdList!= null){
            List<PS_Time_Card__c> PSTimeCardListUpdate = new List<PS_Time_Card__c>();
            List<PS_Time_Entry__c> PSTimeEntryListUpdate = new List<PS_Time_Entry__c>();
            List<PS_Time_Card__c> PSTimeCardList = [select id,Name, Time_Card_Start_Date__c,Time_Card_End_Date__c,
                                                   Status__c,Assignee__c,Total_Billable_Hours__c from PS_Time_Card__c where id=:TimeCardIdList LIMIT 1];
            
            if(!PSTimeCardList.isEmpty() && Approval.isLocked(PSTimeCardList[0].Id)){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setAction('Removed');
                ProcessInstanceWorkitem pItem = [Select Id from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =: TimeCardIdList];
                req.setWorkitemId(pItem.id);
                if(pItem != null){
                    Approval.ProcessResult result = Approval.process(req);
                }            
            } else {
                for(PS_Time_Card__c PS : PSTimeCardList){
                    PS.Status__c = 'Recalled';
                    PSTimeCardListUpdate.add(PS);  
                }
            }
            
            List<PS_Time_Entry__c> PSTimeEntryList = [SELECT id,Status__C FROM PS_Time_Entry__c WHERE PS_Time_Card__c =: TimeCardIdList];
            if(PSTimeEntryList.size() > 0){
                for(PS_Time_Entry__c PTE :PSTimeEntryList){
                    PTE.Status__C = 'Recalled';
                    PSTimeEntryListUpdate.add(PTE);
                    
                }
            }
            if(PSTimeCardListUpdate.size()>0){ update PSTimeCardListUpdate;
            }
            if(PSTimeEntryListUpdate.size()>0){
                update PSTimeEntryListUpdate;
            }
            
        }
        return GetTimeCards();
    }
    
    
    //fetch login user full name
    @AuraEnabled 
    public static String getUserName(){
        return userinfo.getName();
    }
    
    //fetch all project worked by login user 
    //All and Weekly basis

    /**
     * @description Retrieves project information for the current user based on their team membership
     * and returns it wrapped in a WeeklytWrapper object. The method filters only active ("Open")
     * projects where the user is listed as a team member.
     *
     * @param cmpStartDate The comparison start date used for filtering or processing project data.
     * @param weekType A string indicating the type of week (e.g., "Current", "Previous") to tailor the data returned.
     * 
     * @return A WeeklytWrapper object containing filtered project details relevant to the user and week type.
     */
    @AuraEnabled 
    public static WeeklytWrapper getProject(date cmpStartDate, string weekType){
        
        
        map<Id, PS_Project__c> PSMultipledDropDown = new map<Id, PS_Project__c>([Select id,Name,Account__C,Project_Manager__c, 
                                                                                 Account__r.Name,Project_Status__c,Total_Billable_Hours_Remaining__c,Consult_Hours_Billed__c,Install_Hours_Billed__c,
                                                                                 Opportunity__c,Opportunity__r.Name,Total_Billable_Hours_Expected__c,Actual_Billable_hours_logged__c  From PS_Project__C 
                                                                                 WHERE Id IN (select PS_Project__c from PS_Project_Team_Member__c where Team_Member__c =: UserInfo.getUserId()) AND Project_Status__c = 'Open']);
        
        list<Id> projIds = new list<Id>();
        projIds.addAll(PSMultipledDropDown.keyset());
        return getProjList(projIds, cmpStartDate, weekType, true);
    }
    
    //fetch selected project login user on weekly basis
    /**
     * @description Retrieves detailed weekly project data for a given list of project IDs and returns it 
     * as a WeeklytWrapper object. The results are customized based on the provided date, week type, 
     * and whether the call is triggered on component load.
     *
     * @param listOfProjId A list of project record IDs (PS_Project__c) to retrieve data for.
     * @param cmpStartDate The reference date used to determine the start of the week or comparison window.
     * @param weekType A string indicating the context of the week (e.g., "Current", "Previous", etc.).
     * @param onload A boolean flag indicating whether the data fetch is part of an initial page/component load.
     * 
     * @return A WeeklytWrapper instance containing the relevant project and time entry data for the specified inputs.
     */
    @AuraEnabled 
    public static WeeklytWrapper getProjList(list<id> listOfProjId, date cmpStartDate, string weekType, boolean onload){
        
        List<ProjectWrapper> memberWrapperList = new List<ProjectWrapper>();
        boolean readAccess = false;
        
        date myDate = date.today(); // This needs to be updates in case of previous n next week
        
        If(cmpStartDate != null){
            myDate = cmpStartDate;
        }
        If(weekType == 'Next Week'){
            
            myDate = cmpStartDate.addDays(7);
        }else if(weekType == 'Previous Week'){
            myDate = cmpStartDate.addDays(-7);
        }
        
        date weekStart = myDate.toStartofWeek();
        date weekEnd = weekStart.addDays(6);
        
        
        date todayDate = system.today();
        date weekSrt = todayDate.toStartofWeek();
        date past2week = weekSrt.AddDays(-14);
        date future1week = weekSrt.AddDays(7);
        
        boolean disablePrev = false;
        boolean disableNext = false;
        if(weekStart <= past2week){ disablePrev = true;
        }  
        if(weekStart >= future1week){
            disableNext = true;
        } 
        if(weekStart < past2week || weekStart > future1week){
            readAccess = true;
            disablePrev = true;
            disableNext = true;
        }     
        
        List<PS_Task__c> PSTaskList = new List<PS_Task__c>();
        Map<Id, List<TaskWrapper>> ProIdPSTaskListMap = new  Map<Id, List<TaskWrapper>>();
        Map<Id, PS_Project__C> ProejctMap = new Map<Id, PS_Project__C>();
        set<Id> workingProjIds = workedProjects(weekStart, weekEnd); //Already working project ids
        if(!onload) workingProjIds.AddAll(listOfProjId);
      //  listOfProjId.AddAll(workingProjIds);
        list<PS_Project__C> ProjectList = new list<PS_Project__C>([select id,Name,Account__C,Project_Manager__c, 
                                                                   Account__r.Name,Project_Status__c,Total_Billable_Hours_Remaining__c,Consult_Hours_Billed__c,Install_Hours_Billed__c,
                                                                   Opportunity__c,Opportunity__r.Name,Total_Billable_Hours_Expected__c,Actual_Billable_hours_logged__c 
                                                                   FROM PS_Project__C where id IN : listOfProjId]); 
        if(ProjectList.size() > 0) {
            Set<Id> ProejctIds = new Set<Id>();
            for(PS_Project__C PP : ProjectList) {
                ProejctIds.add(PP.Id);
                ProejctMap.put(PP.Id, PP);
            }
            
            set<Id> workingTaskIds = workedTasks(weekStart, weekEnd); //Already working project ids
            PSTaskList = [SELECT id,Name,Order_Product__c, Billable_Hours_Expected__c,Billable_Hours_Actual__c,Total_Hours_Delivered__c,Billable_Hours_Approved__c,
                          Task_Type__c,Task_Subtype__c,Project__c, Comments__c,
                          (SELECT Id, PS_Task__c, Hours_Spent__c, Time_Entry_Date__c, Assignee__c, Status__c, 
                           Read_Only__c, Comments__c FROM PS_Time_Entries__r 
                           WHERE Assignee__c =:UserInfo.getUserId() AND Time_Entry_Date__c >= :weekStart
                           AND Time_Entry_Date__c <= :weekEnd 
                           ORDER BY Time_Entry_Date__c LIMIT 7) 
                           FROM PS_Task__c WHERE (Task_Status__c = 'Open' OR Id IN :workingTaskIds) AND Task_Type__c != 'T&E' AND Project__c IN : ProejctIds];
            
        }
        Decimal totalHo = 0;
        Decimal hrsExclCurrWeek = 0;
        if(PSTaskList.size() > 0) {
            for(PS_Task__c PT : PSTaskList) {
                string comment = '';
                totalHo =0;
                date recordpsoEnddate = null;
                list<PS_Time_Entry__c> psteList = new list<PS_Time_Entry__c>();
                // fill Time Entries start                
                date iterationDate = weekStart;
                integer diff;
                for(PS_Time_Entry__c PSTE : PT.PS_Time_Entries__r){
                    comment = PSTE.comments__c;
                    if(PSTE.Read_Only__c) readAccess = true;
                    totalHo += PSTE.Hours_Spent__c != null ? PSTE.Hours_Spent__c :0;
                    if(PSTE.Time_Entry_Date__c < weekStart || PSTE.Time_Entry_Date__c > weekEnd){ hrsExclCurrWeek += PSTE.Hours_Spent__c != null ? PSTE.Hours_Spent__c :0;
                    }
                    if(PSTE.Time_Entry_Date__c == iterationDate){
                        psteList.Add(PSTE);
                        iterationDate = iterationDate.addDays(1);
                        recordpsoEnddate = PSTE.Time_Entry_Date__c;    
                    }else if(iterationDate < PSTE.Time_Entry_Date__c){
                        diff = iterationDate.daysBetween(PSTE.Time_Entry_Date__c);
                        
                        for(Integer count = 0; count < diff; count++){
                            PS_Time_Entry__c PSTE2 = new PS_Time_Entry__c(
                                Time_Entry_Date__c = iterationDate.addDays(count),
                                PS_Task__c = PT.Id,
                                Assignee__c = UserInfo.getUserId()                
                            );
                            psteList.Add(PSTE2);
                        }
                        psteList.Add(PSTE);
                        iterationDate = PSTE.Time_Entry_Date__c.addDays(1);
                        recordpsoEnddate = PSTE.Time_Entry_Date__c;
                    }
                }
                // Decimal TotalHoursOfEntry = decimal.valueOf(totalHo); 
                
                if(PT.PS_Time_Entries__r.isEmpty() && recordpsoEnddate == null){
                    for(Integer count = 0; count < 7; count++){                        
                        PS_Time_Entry__c PSTE2 = new PS_Time_Entry__c(
                            Time_Entry_Date__c = iterationDate.addDays(count),
                            PS_Task__c = PT.Id,
                            Assignee__c = UserInfo.getUserId()                
                        );
                        psteList.Add(PSTE2);
                    }
                }
                
                if(!psteList.isEmpty()){
                    if(psteList.size() < 7 && recordpsoEnddate != null && recordpsoEnddate.day() != weekEnd.day()){
                        diff = 7 - psteList.size();
                        for(Integer count = 1; count <= diff; count++){
                            PS_Time_Entry__c PSTE3 = new PS_Time_Entry__c(
                                Time_Entry_Date__c = recordpsoEnddate.addDays(count),
                                PS_Task__c = PT.Id,
                                Assignee__c = UserInfo.getUserId()                
                            );
                            psteList.Add(PSTE3);
                        }
                    }
                }
                
                TaskWrapper tw = new TaskWrapper(PT, comment,psteList,totalHo, hrsExclCurrWeek);
                if(!ProIdPSTaskListMap.containsKey(PT.Project__c)){
                    ProIdPSTaskListMap.put(PT.Project__c, new List<TaskWrapper>());
                }
                ProIdPSTaskListMap.get(PT.Project__c).add(tw);
            }
            for(Id PTEId : ProIdPSTaskListMap.keySet()) {
                memberWrapperList.add(
                    new ProjectWrapper(ProejctMap.get(PTEId), ProIdPSTaskListMap.get(PTEId), workingProjIds.contains(PTEId))
                );
            }
        }
               
        return new WeeklytWrapper(weekStart, weekEnd, readAccess, disablePrev, disableNext, memberWrapperList);
    }  

    /**
     * @description Processes and saves PS Time Entry records from a serialized JSON input.
     *    - Deserializes the input to extract time entry records for upsert or delete.
     *    - Deletes entries with zero or null Hours Spent.
     *    - Upserts (insert or update) valid entries, setting their Status based on the button clicked.
     *    - Ensures no duplicate entries exist based on Time Entry Date, PS Task, and Assignee.
     *    - Rolls back the transaction and returns an error map if any error occurs during delete or upsert.
     *
     * @param saveList Serialized JSON string representing the list of PS projects, tasks, and time entries.
     * @param buttonClicked String indicating which button was clicked ('Save' or 'SaveSubmit'), controlling Status field values.
     * @return A Map containing:
     *    - On failure: 'Id' (task id that failed) and 'Error' (error message).
     *    - Returns null if the operation completes successfully.
     */
    
     @AuraEnabled
    public static Map<string, string> savePSEntries(string saveList, string buttonClicked) {
        List<PS_Time_Entry__c> timeEntryListToUpsert = new List<PS_Time_Entry__c>();
        List<PS_Time_Entry__c> timeEntryListToDelete = new List<PS_Time_Entry__c>();
        Map<String, PS_Time_Entry__c> existingTimeEntryMap = new Map<String, PS_Time_Entry__c>();
        Date minDate ;
        Date maxDate ;
        List<object> projList = (List<object>)JSON.deserializeUntyped(saveList);
        List<Date> listPSTimeEntryDate = new List<Date>();
        
        for(object projt : projList){
            Map<String, object> proj = (Map<String, object>) projt;
            if(proj.containsKey('taskWrapperList')){
                List<object> tasks = (List<object>) proj.get('taskWrapperList');
                for(object tsk : tasks) {
                    Map<String,object> finalMap = (Map<String,object>) tsk;
                    if(finalMap.containsKey('timeEntryList')) {
                        string JsonStr = JSON.serialize(finalMap.get('timeEntryList'));
                        List<PS_Time_Entry__c>  timeEntryList = (List<PS_Time_Entry__c>) JSON.deserializeStrict(JsonStr , List<PS_Time_Entry__c>.class);
                        for(PS_Time_Entry__c timeEntry : timeEntryList){
                            if(((timeEntry.Hours_Spent__c == 0 || timeEntry.Hours_Spent__c == null) 
                                && timeEntry.Id == Null) || timeEntry.Read_Only__c) continue;
                            
                            if(timeEntry.Hours_Spent__c == 0 || timeEntry.Hours_Spent__c == null){ timeEntryListToDelete.add(timeEntry);                             
                            } else {
                                listPSTimeEntryDate.add(timeEntry.Time_Entry_Date__c);
                                if(minDate == null || minDate > timeEntry.Time_Entry_Date__c){
                                    mindate = Date.valueOf(String.valueOf(timeEntry.Time_Entry_Date__c).substring(0,10));
                                }
                                if(maxDate == null  || maxDate < timeEntry.Time_Entry_Date__c){
                                    maxDate = Date.valueOf(String.valueOf(timeEntry.Time_Entry_Date__c).substring(0,10));
                                }
                                if(finalMap.containsKey('comment'))
                                    timeEntry.Comments__c = String.valueOf(finalMap.get('comment'));
                                timeEntry.Status__c = (buttonClicked == 'SaveSubmit') ? 'Submitted' : 'Draft';
                                timeEntryListToUpsert.add(timeEntry);
                            }
                        }
                    }
                }
            }
        }
        if (!listPSTimeEntryDate.isEmpty()) {
            for (PS_Time_Entry__c entry : [SELECT Id, Status__c, Time_Entry_Date__c, Assignee__c, PS_Task__c, PS_Task__r.Project__c 
                                        FROM PS_Time_Entry__c 
                                        WHERE Time_Entry_Date__c >= :minDate AND Time_Entry_Date__c <= :maxDate]) {
                existingTimeEntryMap.put(entry.Time_Entry_Date__c + '-' + entry.PS_Task__c + '-' + entry.Assignee__c  , entry);

            }
            
        }

        Savepoint sp = Database.setSavepoint();
        Map<String, String> errorMap = new Map<String, String>();
        if(!timeEntryListToDelete.isEmpty()){
            List<Database.DeleteResult> res = Database.delete(timeEntryListToDelete, false);
            Boolean hasError = false;
            String errorMessage = '';
            String errorId = '';
            for (Integer i = 0; i < timeEntryListToDelete.size(); i++) {
                if (!res[i].isSuccess()) {
                    Database.Error errors = res[i].getErrors()[0];
                    errorId = timeEntryListToDelete[i].PS_Task__c;
                    errorMessage = errors.getMessage();
                    hasError = true;
                    break; 
                }
            }
            if (hasError) {
                Database.rollback(sp);
                errorMap.put('Id', errorId);
                errorMap.put('Error', errorMessage);
                return errorMap;
            }
        }

        if (!timeEntryListToUpsert.isEmpty()) {
            List<PS_Time_Entry__c> finalUpsertList = new List<PS_Time_Entry__c>();
            for (PS_Time_Entry__c timeEntry : timeEntryListToUpsert) {
                String key = timeEntry.Time_Entry_Date__c + '-' + timeEntry.PS_Task__c+ '-' + timeEntry.Assignee__c;
                if (existingTimeEntryMap.containsKey(key)) {
                    // If record exists, update it
                    PS_Time_Entry__c existingEntry = existingTimeEntryMap.get(key);
                    existingEntry.Hours_Spent__c = timeEntry.Hours_Spent__c;
                    existingEntry.Comments__c = timeEntry.Comments__c;
                    existingEntry.Status__c =  (buttonClicked == 'SaveSubmit') ? 'Submitted' : 'Draft';
                    finalUpsertList.add(existingEntry);
                } else {
                    finalUpsertList.add(timeEntry);
                }
            }

            List<Database.UpsertResult> res = Database.upsert(finalUpsertList, false);
            Boolean hasError = false;
            String errorMessage = '';
            String errorId = '';
            for (Integer i = 0; i < finalUpsertList.size(); i++) {
                if (!res[i].isSuccess()) {
                    Database.Error errors = res[i].getErrors()[0];
                    errorId = finalUpsertList[i].PS_Task__c;
                    errorMessage = errors.getMessage();
                    hasError = true;
                    break; 
                }
            }
            if (hasError) {
                Database.rollback(sp);
                errorMap.put('Id', errorId);
                errorMap.put('Error', errorMessage);
                return errorMap;
            }
        }
        return null;
    }


    
    //Project ids worked on a specific week by current user
    public static set<Id> workedProjects(date weekStart, date weekEnd){
        AggregateResult[] SelectedProjectsQry =  [SELECT Count(Id), PS_Task__r.Project__c proj FROM PS_Time_Entry__c 
                                                  WHERE Assignee__c = : UserInfo.getUserId() AND Time_Entry_Date__c >= :weekStart 
                                                  AND Time_Entry_Date__c <= :weekEnd 
                                                  GROUP BY PS_Task__r.Project__c];
        
        set<Id> workingProjIds = new set<Id>();
        for (AggregateResult ar : SelectedProjectsQry)  {
            workingProjIds.add(string.valueOf(ar.get('proj')));
        }
        return workingProjIds;
    }
    
    //Task ids worked on a specific week by current user
    public static set<Id> workedTasks(date weekStart, date weekEnd){
        AggregateResult[] SelectedTasksQry =  [SELECT Count(Id), PS_Task__c task FROM PS_Time_Entry__c 
                                                  WHERE Assignee__c = : UserInfo.getUserId() AND Time_Entry_Date__c >= :weekStart 
                                                  AND Time_Entry_Date__c <= :weekEnd 
                                                  GROUP BY PS_Task__c];
        
        set<Id> workingTaskIds = new set<Id>();
        for (AggregateResult ar : SelectedTasksQry)  {
            workingTaskIds.add(string.valueOf(ar.get('task')));
        }
        return workingTaskIds;
    }
    
    //Wrapper with all projects based on weekStart and WeekEnd 
    public class WeeklytWrapper {
        @AuraEnabled public date weekStartDate {get;set;}
        @AuraEnabled public date weekEndDate {get;set;}
        @AuraEnabled public boolean readOnly {get;set;}
        @AuraEnabled public boolean disablePreviousWeek {get;set;}
        @AuraEnabled public boolean disableNextWeek {get;set;}
        @AuraEnabled public list<ProjectWrapper> allProjects {get;set;}
        
        WeeklytWrapper(date wkStrDate, date wkEndDate, boolean readAccess, boolean disPrev, boolean disNext, list<ProjectWrapper> allProjs){
            this.weekStartDate = wkStrDate;
            this.weekEndDate = wkEndDate;
            this.readOnly = readAccess;
            this.disablePreviousWeek = disPrev;
            this.disableNextWeek = disNext;
            this.allProjects = allProjs;
        }       
    }
    
    // projects(selected/unselected) and related task
    public class ProjectWrapper {
        @AuraEnabled public PS_Project__C project {get;set;}
        @AuraEnabled public boolean selected {get;set;}
        @AuraEnabled public List<TaskWrapper> taskWrapperList {get;set;}
        
        public ProjectWrapper(PS_Project__c proj, List<TaskWrapper> intrstList, boolean sel) {
            this.project = proj;
            this.selected = sel;
            this.taskWrapperList  = intrstList;
        }
    }
    
    //Task and related time entries
    public class TaskWrapper {
        @AuraEnabled public PS_Task__c taskRec{get;set;}
        @AuraEnabled public string comment{get;set;}
        @AuraEnabled public List<PS_Time_Entry__c> timeEntryList {get;set;}
        @AuraEnabled public Decimal TotHours{get;set;}
        @AuraEnabled public Decimal hrsExclCurrWeek{get;set;}
        
        public TaskWrapper(PS_Task__c rec, string comm, List<PS_Time_Entry__c> timeList,Decimal TotHou, Decimal hrsExCurrWeek) {
            this.taskRec = rec;
            this.comment = comm;
            this.timeEntryList = timeList;
            this.TotHours = TotHou;
            this.hrsExclCurrWeek = hrsExCurrWeek;            
        }
    }
    
    public class TimeCardWrapper {
        @AuraEnabled public PS_Time_Card__c TimeCard {get;set;}
        @AuraEnabled public boolean PermissionCheck  {get;set;}
        @AuraEnabled public boolean enableUnlock     {get;set;}
        /**
         * @description Indicates whether the user has access to an administrative project.
         */
        @AuraEnabled public boolean hasAdminProject     {get;set;}
        
        /**
         * @description Constructor for the TimeCardWrapper class.
         * @param tc The PS_Time_Card__c record being wrapped.
         * @param pc A boolean indicating the result of a specific permission check.
         * @param enable A boolean to determine if the 'unlock' functionality should be enabled.
         * @param isAdmin A boolean indicating if the user has access to an administrative project.
         */
        public TimeCardWrapper(PS_Time_Card__c tc, boolean pc, boolean enable, boolean isAdmin){
            this.TimeCard = tc;
            this.PermissionCheck = pc;
            this.enableUnlock = enable;
            this.hasAdminProject = isAdmin;
        }
    }    

     /**
     * @description Saves or updates a list of PS Time Entry records from new button.
     *   - Checks for existing time entries based on Time Entry Date, PS Task, and Assignee.
     *   - If an existing record is found, updates Hours Spent, Comments, and Status fields.
     *   - If no existing record is found, inserts a new record.
     *
     * @param timeEntryList List of PS_Time_Entry__c records to be inserted or updated.
     * @return A Map containing:
     *   - On success: a map with key 'Id' and the newly created or updated record's Id as value.
     *   - On failure: a map with 'Id' (task id that failed) and 'Error' (error message).
     */

    @AuraEnabled
    public static Map<String, String> saveDirectPSEntries(List<PS_Time_Entry__c> timeEntryList) {
        Map<String, String> errorMap = new Map<String, String>();
        Map<String, String> responseMap = new Map<String, String>();
        List<PS_Time_Entry__c> finalUpsertList = new List<PS_Time_Entry__c>();
        Map<String, PS_Time_Entry__c> existingTimeEntryMap = new Map<String, PS_Time_Entry__c>();

        Date minDate, maxDate;
        for (PS_Time_Entry__c entry : timeEntryList) {
            if (minDate == null || entry.Time_Entry_Date__c < minDate) minDate = entry.Time_Entry_Date__c;
            if (maxDate == null || entry.Time_Entry_Date__c > maxDate) maxDate = entry.Time_Entry_Date__c;
        }

        if (minDate != null && maxDate != null) {
            for (PS_Time_Entry__c existingEntry : [
                SELECT Id, Time_Entry_Date__c, PS_Task__c, Assignee__c, Hours_Spent__c, Comments__c
                FROM PS_Time_Entry__c
                WHERE Time_Entry_Date__c >= :minDate AND Time_Entry_Date__c <= :maxDate
            ]) {
                String key = existingEntry.Time_Entry_Date__c + '-' + existingEntry.PS_Task__c + '-' + existingEntry.Assignee__c;
                existingTimeEntryMap.put(key, existingEntry);
            }
        }

        for (PS_Time_Entry__c entry : timeEntryList) {
            String key = entry.Time_Entry_Date__c + '-' + entry.PS_Task__c + '-' + entry.Assignee__c;
            if (existingTimeEntryMap.containsKey(key)) {
                PS_Time_Entry__c existing = existingTimeEntryMap.get(key);
                existing.Hours_Spent__c = entry.Hours_Spent__c;
                existing.Comments__c = entry.Comments__c;
                existing.Status__c = entry.Status__c;
                finalUpsertList.add(existing);
            } else {
                entry.Status__c = entry.Status__c;
                finalUpsertList.add(entry);
            }
        }

        Savepoint sp = Database.setSavepoint();
        List<Database.UpsertResult> results = Database.upsert(finalUpsertList, false);

        Boolean hasError = false;
        String errorMessage = '';
        String errorId = '';
        for (Integer i = 0; i < finalUpsertList.size(); i++) {
            if (!results[i].isSuccess()) {
                Database.Error error = results[i].getErrors()[0];
                errorId = finalUpsertList[i].PS_Task__c;
                errorMessage = error.getMessage();
                hasError = true;
                break; 
            } else{
                responseMap.put('Id', finalUpsertList[i].Id);
            }
        }
        if (hasError) {
            Database.rollback(sp);
            errorMap.put('Id', errorId);
            errorMap.put('Error', errorMessage);
            return errorMap;
        }
        return responseMap;
    }
    
}