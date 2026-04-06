public class projectSubTasksController {
    public static List<subtaskWrapperClass> subtasksWrapperList;
    public static List<innerWrapperClass> innerWrapperList;
    @AuraEnabled
    public static List<subtaskWrapperClass> getsubtasksList(string projId,Date startdate,Date enddate){
        //string startdate = '7/1/2019';
        //string enddate = '7/7/2019';
        string dstr1 = startdate.month()+'/'+startdate.day()+'/'+startdate.year();
        string dstr2 = enddate.month()+'/'+enddate.day()+'/'+enddate.year();
        Date d1 = Date.parse(dstr1);
        Date d2 = Date.parse(dstr2);
        startdate = d1;
        enddate = d2;
        subtasksWrapperList = new List<subtaskWrapperClass>();
        innerWrapperList = new List<innerWrapperClass>();
        List<PS_Task__c> taskList = new List<PS_Task__c>();
        List<PS_SubTask__c> subtaskList = new List<PS_SubTask__c>();
        List<PS_Time_Entry__c> psoList = new List<PS_Time_Entry__c>();
        
        List<string> wrappertaskList = new List<string>();
        Integer startday;
        Integer startmonth;
        Integer endday;
        Integer endmonth;
        Integer startyear;
        Integer endyear;
        string psoconcatId = '';
        Integer size;
        Double totalhrs = 0;
        string notes = '';
        Id userId = userinfo.getUserId();
        Map<string,string> hoursMap = new Map<string,string>();
        if(startdate != null){
            startday = startdate.day();
            startmonth = startdate.month();
            startyear = startdate.year();
        }
        if(enddate != null){
            endday = enddate.day();
            endmonth = enddate.month();
            endyear = enddate.year();
        }
        if(!string.isBlank(projId)){
            taskList = [select Id,Name,Project__c,Task_Status__C,
                        Order_Item__c, Order_Item__r.Order.ShippingCountryCode, 
                        Order_Item__r.Order.ShippingCity, Order_Item__r.Order.ShippingStateCode
                        from PS_Task__c where Project__c =: projId AND Task_Status__C ='Open'];
            for(PS_task__C ss : taskList){
            }
        }
        if(!taskList.isEmpty()){
            subtaskList = [select Id,Name,Task__c, Task__r.Order_Item__c,Task__r.Order_Item__r.Order.OrderNumber, Task__r.Order_Item__r.Order.ShippingCountryCode, Task__r.Order_Item__r.Order.ShippingCity, Task__r.Order_Item__r.Order.ShippingStateCode,
                           Task__r.Name,Task__r.Task_Type__c,Subtask_Type__c,(select Id,Name,Time_Entry_Date__c,Hours_Spent__c,PS_SubTask__c,PS_Subtask__r.Task__c,PS_Subtask__r.Name,Backend_Id__c,Comments__c from PS_Time_Entries__r where CreatedById =:userId AND Time_Entry_Date__c>=:startdate AND Time_Entry_Date__c <=:enddate  order by Time_Entry_Date__c asc) from PS_SubTask__c where PS_Assignee__c =: userId AND Task__c IN: taskList order by Task__c asc];
            for(PS_Subtask__C ss : subtaskList){
            }
            
        }
        
        Date recordpsoEnddate;
        Date iterationDate = startdate;
        Integer diff;
        Date d;
        
        for(PS_SubTask__c subtask : subtaskList){
            recordpsoEnddate = null;
            iterationDate = startdate;
            totalhrs = 0;
            notes = '';
            List<PS_Time_Entry__c> psotempList = new List<PS_Time_Entry__c>();
            for(PS_Time_Entry__c pso : subtask.PS_Time_Entries__r){
                if((pso.Time_Entry_Date__c.month() == startmonth || pso.Time_Entry_Date__c.month() == endmonth) &&  pso.Time_Entry_Date__c >= startdate &&  pso.Time_Entry_Date__c <= enddate){
                    if(pso.Time_Entry_Date__c == iterationDate){
                        PS_Time_Entry__c psotemp = new PS_Time_Entry__c();
                        psotemp.Backend_Id__c = pso.Id;
                        psotemp.Hours_Spent__c = pso.Hours_Spent__c;
                        psotempList.add(psotemp);
                        //hoursMap.put(pso.Id,string.valueOf(pso.Hours_Spent__c));
                        iterationDate = iterationDate.addDays(1);
                        if(!string.isBlank(pso.comments__c))
                            notes = pso.comments__c;
                        recordpsoEnddate = pso.Time_Entry_Date__c;
                    }else if(iterationDate< pso.Time_Entry_Date__c){
                        diff = iterationDate.daysBetween(pso.Time_Entry_Date__c);
                        for(Integer count=0;count<diff;count++){
                            d = iterationDate.addDays(count);
                            PS_Time_Entry__c psotemp = new PS_Time_Entry__c();
                            psotemp.Backend_Id__c = 'null'+d;
                            psotempList.add(psotemp);
                            // hoursMap.put('null'+d,'');
                        }
                        PS_Time_Entry__c psotemp1 = new PS_Time_Entry__c();
                        psotemp1.Backend_Id__c = pso.Id;
                        psotemp1.Hours_Spent__c = pso.Hours_Spent__c;
                        psotempList.add(psotemp1);
                        // hoursMap.put(pso.Id,string.valueOf(pso.Hours_Spent__c));
                        iterationDate = pso.Time_Entry_Date__c.addDays(1);
                        if(!string.isBlank(pso.comments__c))
                            notes = pso.comments__c;
                        recordpsoEnddate = pso.Time_Entry_Date__c;
                    }
                }
            }
            if(psotempList.isEmpty() && recordpsoEnddate == null){
                for(Integer count=0;count<7;count++){
                    d = startdate.addDays(count);
                    PS_Time_Entry__c psotemp = new PS_Time_Entry__c();
                    psotemp.Backend_Id__c = 'null'+d;
                    psotempList.add(psotemp);
                    //hoursMap.put('null'+d,'');
                }
            }
            if(!psotempList.isEmpty()){
                if(psotempList.size() < 7 && recordpsoEnddate != null && recordpsoEnddate.day() != endday){
                    diff = 7 - psotempList.size();
                    for(Integer count=1;count<=diff;count++){
                        d = recordpsoEnddate.addDays(count);
                        PS_Time_Entry__c psotemp = new PS_Time_Entry__c();
                        psotemp.Backend_Id__c = 'null'+d;
                        psotempList.add(psotemp);
                        //hoursMap.put('null'+d,'');
                    }
                }
               
                for(PS_Time_Entry__c psotemp : psotempList){
                    if(psotemp.Hours_Spent__c != null)
                        totalhrs = totalhrs+psotemp.Hours_Spent__c;
                }
                String taskNamePostFix ='';
                if(subtask.Task__r.Order_Item__c != null && subtask.Task__r.Task_Type__c != 'Admin') {
                    if(subtask.Task__r.Order_Item__r.order.ShippingCity != null ) {
                        taskNamePostFix += '(' +subtask.Task__r.Order_Item__r.order.ShippingCity;
                    }
                    if(subtask.Task__r.Order_Item__r.order.ShippingCountryCode != null && (subtask.Task__r.Order_Item__r.order.ShippingCountryCode != 'US' && subtask.Task__r.Order_Item__r.order.ShippingCountryCode != 'CA')){
                        if(taskNamePostFix == '') {
                            taskNamePostFix += '('+subtask.Task__r.Order_Item__r.order.ShippingCountryCode;
                        }
                        else {
                            taskNamePostFix +=  '-'+subtask.Task__r.Order_Item__r.order.ShippingCountryCode;
                        }
                    }
                    else {
                        if(taskNamePostFix == '') {
                            taskNamePostFix += '('+subtask.Task__r.Order_Item__r.order.ShippingStateCode;
                        }
                        else {
                            taskNamePostFix +=  +'-'+subtask.Task__r.Order_Item__r.order.ShippingStateCode;
                        }
                    }
                    if(taskNamePostFix.contains('(')) {
                        taskNamePostFix = taskNamePostFix + ')';
                    }
                    
                    
                }
                String taskName = string.valueOf(subtask.Task__r.Task_Type__c) +'-'+ subtask.Task__r.Order_Item__r.Order.OrderNumber+'-'+taskNamePostFix;
                innerWrapperList.add(new innerWrapperClass(string.valueOf(subtask.Task__c),taskName,string.valueOf(subtask.Id),subtask.Subtask_Type__c,notes,totalhrs,psotempList));
                recordpsoEnddate = null;
            }
            
        }
        Map<string,List<innerWrapperClass>> wrapperMap = new Map<string,List<innerWrapperClass>>();
        for(innerWrapperClass iw : innerWrapperList){
            List<innerWrapperClass> MaininnerWrapperList = new List<innerWrapperClass>();
            if(!wrapperMap.isEmpty() && wrapperMap.containsKey(iw.taskname)){
                MaininnerWrapperList = wrapperMap.get(iw.taskname);
                MaininnerWrapperList.add(iw);
                wrapperMap.put(iw.taskname,MaininnerWrapperList);
            }else{
                MaininnerWrapperList.add(iw);
                wrapperMap.put(iw.taskname,MaininnerWrapperList);
            }
        }
        for(string taskname : wrapperMap.keySet()){
            subtasksWrapperList.add(new subtaskWrapperClass(taskname,wrapperMap.get(taskname)));
        }
        
        system.debug('@@final subtasksWrapperList '+subtasksWrapperList);
        return subtasksWrapperList;
    }
    @AuraEnabled
    public static String savePSOtime(string saveList, String buttonClicked){
        Savepoint sp;
        try{
            List<subtaskWrapperClass> wrappersaveList = (List<subtaskWrapperClass>)JSON.deserialize(saveList, List<subtaskWrapperClass>.class);
            system.debug('@@ wrappersaveList '+wrappersaveList);
            List<PS_Time_Entry__c> psoteList = new List<PS_Time_Entry__c>();
            Set<Id> subTaskIdSet = new Set<Id>();
            for(subtaskWrapperClass wc : wrappersaveList){
                for(innerWrapperClass ic : wc.innerWrapperList){
                    for(PS_Time_Entry__c pso : ic.psoList){
                        PS_Time_Entry__c psote = new PS_Time_Entry__c();
                        if(!pso.Backend_Id__c.contains('null')){
                            psote.Id = pso.Backend_Id__c;
                            psote.Hours_Spent__c = pso.Hours_Spent__c;
                            psote.Comments__c = ic.notes;
                            if(buttonClicked == 'saveandsubmit') {
                                psote.Status__c = 'Submitted'; 
                            }
                            psoteList.add(psote);
                            subTaskIdSet.add(ic.subtaskId);//SAL-1264
                        }else if(pso.Hours_Spent__c != null){
                            string d = pso.Backend_Id__c.replace('null','');
                            psote.Time_Entry_Date__c = Date.valueOf(d);
                            psote.PS_SubTask__c = ic.subtaskId;
                            psote.Hours_Spent__c = pso.Hours_Spent__c;
                            psote.Comments__c = ic.notes;
                            if(buttonClicked == 'saveandsubmit') {
                                psote.Status__c = 'Submitted'; 
                            }
                            psoteList.add(psote);
                            subTaskIdSet.add(ic.subtaskId);
                        }
                    }
                }
            }
            if(!psoteList.isEmpty()){
                sp = Database.setSavepoint();
                upsert psoteList;
                System.debug('subTaskIdSet--'+subTaskIdSet);
                if(!subTaskIdSet.isEmpty()) {
                    updateSubtaskHours(subTaskIdSet);
                }
                
            }
            return 'SUCCESS';
        }
        catch(exception ex){
            Database.rollback( sp );
            if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                return 'You cannot log time more than expected hours on Project. Please contact your Project Manager to override.';
            }else if(ex.getMessage().contains('This record is currently in an approval process')){
                return 'Below Time Entry Card(s) already in Approval process. So please approve pending time entry card(s) before proceeding further';
            }else {
                return 'Error occured while saving';
            }
        }
    }
    
    Public Static Boolean runonce = false;
    
    public static void createOrUpdateTimeCard(List<PS_Time_Entry__c> timeEntryList) {
        
        Set<string> timeCardList = new Set<string>();
        Set<Id> assigneeIds = new Set<Id>();
        for(PS_Time_Entry__c te : timeEntryList) {
            if(te.PS_Time_Card__c == null && te.Time_Entry_Date__c != null){
                Date weekStart = te.Time_Entry_Date__c.toStartofWeek();
                timeCardList.add( weekStart.format() +' - '+ weekStart.addDays(6).format());
                AssigneeIds.add(te.Assignee__c);
            }
        }
        
        if(!assigneeIds.isEmpty()){
            map<string,Id> timeCardMap = new map<string,Id>();
            set<string> timeCardSet = new set<string>();
            for(PS_Time_Card__c tc : [SELECT Name, Assignee__c, Time_Card_Start_Date__c, Time_Card_End_Date__c, Account__c 
                                      FROM PS_Time_Card__c 
                                      WHERE Assignee__c IN :assigneeIds AND Name IN :timeCardList]){
                                          timeCardMap.put(tc.Name+' - '+tc.Assignee__c, tc.id);
                                      }
            List<PS_Time_Card__c> InsertPStimeCard = new List<PS_Time_Card__c>();
            string timeCardKey;
            
            for(PS_Time_Entry__c te : timeEntryList){           
                if(te.PS_Time_Card__c == null && te.Time_Entry_Date__c != null){
                    Date weekStart = te.Time_Entry_Date__c.toStartofWeek();
                    timeCardKey =  weekStart.format() +' - '+ weekStart.addDays(6).format() +' - '+te.Assignee__c;         
                    if(!timeCardMap.ContainsKey(timeCardKey)){
                        PS_Time_Card__c pstc         = new PS_Time_Card__c();
                        pstc.Name                    = weekStart.format() +' - '+ weekStart.addDays(6).format();
                        pstc.Assignee__c             = te.Assignee__c;
                        pstc.Time_Card_Start_Date__c = weekStart;
                        pstc.Time_Card_End_Date__c   = weekStart.addDays(6);
                        pstc.Approver__c = te.Approver_Id__c;
                        
                        InsertPStimeCard.add(pstc);
                        timeCardMap.put(timeCardKey, null);
                    }
                }
            }
            if(!InsertPStimeCard.IsEmpty()){
                insert InsertPStimeCard;
                for(PS_Time_Card__c tc : InsertPStimeCard){
                    timeCardMap.put(tc.Name+' - '+tc.Assignee__c, tc.id);
                }
            }
            for(PS_Time_Entry__c te : timeEntryList){
                if(te.PS_Time_Card__c == null && te.Time_Entry_Date__c != null){
                    Date weekStart = te.Time_Entry_Date__c.toStartofWeek();
                    timeCardKey = weekStart.format() +' - '+ weekStart.addDays(6).format() +' - '+te.Assignee__c;         
                    if(timeCardMap.ContainsKey(timeCardKey)){
                        te.PS_Time_Card__c = timeCardMap.get(timeCardKey);
                    }
                }
            }
            
        }
    }
    
    
    public static void calculateTimeCardHours(List<PS_Time_Entry__c> timeEntryList, Map<Id, sobject> oldTimeEntryMap ){
        List<PS_Time_Card__c> queriedTimeCardList = new List<PS_Time_Card__c>();
        Map<string,PS_Time_Entry__c> teMap = new Map<string,PS_Time_Entry__c>();
        List<PS_Time_Entry__c> queriedtimeEntryList = new List<PS_Time_Entry__c>();
        Set<Id> timcardId = new Set<Id>();
        for(PS_Time_Entry__c pe: timeEntryList){
            timcardId.add(pe.PS_Time_Card__c);
            teMap.put(pe.Id,pe);
        }
        queriedtimeEntryList = [select Id,PS_Time_Card__c,Status__c,PS_Task__c,PS_Task__r.Task_Type__c, Billable__c, Hours_Spent__c from PS_Time_Entry__c where Id IN: timeEntryList];
        if(!timcardId.isEmpty()){
            queriedTimeCardList = [select Id,PS_Project__c,Approver__c,Status__c, Total_Admin_Hours__c ,Total_Non_Billable_Consult_Hours__c,Total_Billable_Install_Hours__c,Total_Non_Billable_Install_Hours__c,Total_Billable_Consult_Hours__c,Time_Card_End_Date__c,Time_Card_Start_Date__c,Assignee__c,Total_Non_Billable_Hours_New__c,Total_Billable_Hours_New__c from PS_Time_Card__c where Id IN:timcardId];
            queriedtimeEntryList = [select Id,PS_Time_Card__c,Status__c,PS_Subtask__c,PS_Task__r.Task_Type__c,PS_Task__r.Project__r.Has_Admin_Project__c,Billable__c,Hours_Spent__c from PS_Time_Entry__c where PS_Time_Card__c IN:timcardId];
        }
	    Set<String> appliedConsult = new Set<String>();
        appliedConsult.add('Consult');
        for(PS_Time_Card__c tc : queriedTimeCardList){
            tc.Total_Billable_Consult_Hours__c = 0;
            tc.Total_Non_Billable_Consult_Hours__c = 0;
            tc.Total_Billable_Install_Hours__c = 0;
            tc.Total_Non_Billable_Install_Hours__c = 0;
			tc.Total_Non_Billable_Hours_New__c = 0;
            tc.Total_Billable_Hours_New__c = 0; //added for MKT26-953
            tc.Total_Admin_Hours__c  = 0;
            Boolean isHoursChanged = false;
            Boolean isStatusSubmitted = false;
            for(PS_Time_Entry__c te : queriedtimeEntryList){
                if(te.PS_Time_Card__c == tc.Id && appliedConsult.contains(te.PS_Task__r.Task_Type__c) && te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Billable_Consult_Hours__c = tc.Total_Billable_Consult_Hours__c+teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Billable_Consult_Hours__c = te.Hours_Spent__c != null?tc.Total_Billable_Consult_Hours__c+te.Hours_Spent__c:tc.Total_Billable_Consult_Hours__c;
                    }
                }else if(te.PS_Time_Card__c == tc.Id && te.PS_Task__r.Task_Type__c == 'Consult - Non Billable' && !te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Non_Billable_Consult_Hours__c = tc.Total_Non_Billable_Consult_Hours__c+teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Non_Billable_Consult_Hours__c = te.Hours_Spent__c != null?tc.Total_Billable_Consult_Hours__c+te.Hours_Spent__c:tc.Total_Billable_Consult_Hours__c;
                    }
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Consult-Onsite' || te.PS_Task__r.Task_Type__c == 'Consult-Onsite-PD') && te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Billable_Consult_Hours__c = tc.Total_Billable_Consult_Hours__c +teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Billable_Consult_Hours__c = te.Hours_Spent__c != null?tc.Total_Billable_Consult_Hours__c +te.Hours_Spent__c:tc.Total_Billable_Consult_Hours__c;
                    }
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Consult-Remote' || te.PS_Task__r.Task_Type__c == 'Consult-Remote-PD' || te.PS_Task__r.Task_Type__c == 'Accelerator' || te.PS_Task__r.Task_Type__c == 'Resident Engineer' || te.PS_Task__r.Task_Type__c == 'Resident Engineer-PD') && te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Billable_Consult_Hours__c = tc.Total_Billable_Consult_Hours__c +teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Billable_Consult_Hours__c = te.Hours_Spent__c != null?tc.Total_Billable_Consult_Hours__c +te.Hours_Spent__c:tc.Total_Billable_Consult_Hours__c;
                    }
                }
                //added for MKT26-953
                else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Rubrik University') && te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Billable_Hours_New__c = tc.Total_Billable_Hours_New__c + teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Billable_Hours_New__c = te.Hours_Spent__c != null? tc.Total_Billable_Hours_New__c + te.Hours_Spent__c : tc.Total_Billable_Hours_New__c;
                    }
                }
 
                //CHANGES CS21-489
                else if(te.PS_Time_Card__c == tc.Id && ( te.PS_Task__r.Task_Type__c == 'Install'|| te.PS_Task__r.Task_Type__c == 'Install-PD' || te.PS_Task__r.Task_Type__c == 'RCDM-Install') && te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null ){
                        tc.Total_Billable_Install_Hours__c = tc.Total_Billable_Install_Hours__c+teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Billable_Install_Hours__c = te.Hours_Spent__c != null?tc.Total_Billable_Install_Hours__c+te.Hours_Spent__c:tc.Total_Billable_Install_Hours__c;
                    }
                }else if(te.PS_Time_Card__c == tc.Id && te.PS_Task__r.Task_Type__c == 'Install - Non Billable' && !te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Non_Billable_Install_Hours__c = tc.Total_Non_Billable_Install_Hours__c+teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Non_Billable_Install_Hours__c = te.Hours_Spent__c != null? tc.Total_Billable_Install_Hours__c+te.Hours_Spent__c:tc.Total_Billable_Install_Hours__c;
                    }
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Non-Billable (Product)' || te.PS_Task__r.Task_Type__c == 'Non-Billable (PS)' || te.PS_Task__r.Task_Type__c == 'Non-Billable (Sales)' || te.PS_Task__r.Task_Type__c == 'Non-Billable (Expired)') && !te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Non_Billable_Hours_New__c = tc.Total_Non_Billable_Hours_New__c+teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Non_Billable_Hours_New__c = te.Hours_Spent__c != null? tc.Total_Non_Billable_Hours_New__c+te.Hours_Spent__c:tc.Total_Non_Billable_Hours_New__c;
                    }
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Admin' || te.PS_Task__r.Task_Type__c == 'CSAT' || te.PS_Task__r.Task_Type__c =='Non-Billable PreSales') && !te.Billable__c){
                    if(!teMap.isEmpty() && teMap.containsKey(te.Id) && teMap.get(te.Id).Hours_Spent__c != null){
                        tc.Total_Admin_Hours__c = tc.Total_Admin_Hours__c+teMap.get(te.Id).Hours_Spent__c;
                    }else{
                        tc.Total_Admin_Hours__c = te.Hours_Spent__c != null? tc.Total_Admin_Hours__c+te.Hours_Spent__c:tc.Total_Admin_Hours__c;
                    }
                }
                if(te.PS_Time_Card__c == tc.Id && te.PS_Task__r.Project__r.Has_Admin_Project__c){
                    tc.Total_Admin_Hours__c = te.Hours_Spent__c != null? tc.Total_Admin_Hours__c+te.Hours_Spent__c:tc.Total_Admin_Hours__c;
                    tc.Total_Non_Billable_Hours_New__c = te.Hours_Spent__c != null? tc.Total_Non_Billable_Hours_New__c+te.Hours_Spent__c:tc.Total_Non_Billable_Hours_New__c;
                }
                
                if(oldTimeEntryMap != null && oldTimeEntryMap.containsKey(te.id)){
                    PS_Time_Entry__c oldTe = (PS_Time_Entry__c) oldTimeEntryMap.get(te.id);
                    if(te.Hours_Spent__c != oldTe.Hours_Spent__c && isHoursChanged ==false){
                        isHoursChanged= true;
                    }
                }
                if(te.Status__c == 'Submitted' ) {
                    isStatusSubmitted = true;
                }
                
            }
            if(isStatusSubmitted && tc.Status__c != 'Submitted') {
                tc.Status__c = 'Submitted';
            }
            /*for(PS_Time_Entry__c te : queriedtimeEntryList){
                if((te.Status__c == 'Draft')  && isStatusSubmitted) {
                    te.Status__c = 'Submitted';
                }
            }
            
            if((tc.Status__c == 'Approved' || tc.Status__c == 'Rejected') && isHoursChanged) {
                tc.Status__c = 'Draft';
            }
            
            if(isStatusSubmitted && tc.Status__c != 'Submitted') {
                tc.Status__c = 'Submitted';
                
            } 
            
            if(isStatusSubmitted && tc.Status__c != 'Submitted') {
                tc.Status__c = 'Submitted';
            }else if(tc.Status__c != 'Approved' && tc.Status__c != 'Rejected') {
                tc.Status__c = 'Draft';
            }*/
        }
        update queriedTimeCardList;
        for(PS_time_Card__c tc: queriedTimeCardList){
            if(tc.Status__c == 'Submitted') {
                if(!runOnce){
                    submitForApproval(tc.Id);
                    runOnce = true;
                }    
            }
            
        }
    }
    
    public static void calculateTimeCardHoursDelete(List<PS_Time_Entry__c> timeEntryList){
        List<PS_Time_Card__c> queriedTimeCardList = new List<PS_Time_Card__c>();
        Map<string,PS_Time_Entry__c> teMap = new Map<string,PS_Time_Entry__c>();
        List<PS_Time_Entry__c> queriedtimeEntryList = new List<PS_Time_Entry__c>();
        Set<Id> timcardId = new Set<Id>();
        for(PS_Time_Entry__c pe: timeEntryList){
            timcardId.add(pe.PS_Time_Card__c);
            teMap.put(pe.Id,pe);
        }
        queriedtimeEntryList = [select Id,PS_Time_Card__c,Status__c,PS_Task__c,PS_Task__r.Task_Type__c, Billable__c, Hours_Spent__c from PS_Time_Entry__c where Id IN: timeEntryList];
        if(!timcardId.isEmpty()){
            queriedTimeCardList = [select Id,PS_Project__c,Approver__c,Status__c, Total_Admin_Hours__c, Total_Non_Billable_Consult_Hours__c,Total_Billable_Install_Hours__c,Total_Non_Billable_Install_Hours__c,Total_Billable_Consult_Hours__c,Time_Card_End_Date__c,Time_Card_Start_Date__c,Assignee__c,Total_Non_Billable_Hours_New__c from PS_Time_Card__c where Id IN:timcardId];
            // queriedtimeEntryList = [select Id,PS_Time_Card__c,Status__c,PS_Subtask__c,PS_Task__r.Task_Type__c,Billable__c,Hours_Spent__c from PS_Time_Entry__c where PS_Time_Card__c IN:timcardId];
        }
        Set<String> appliedConsult = new Set<String>();
        appliedConsult.add('Consult');
        for(PS_Time_Card__c tc : queriedTimeCardList){
            Boolean isHoursChanged = false;
            Boolean isStatusSubmitted = false;
            for(PS_Time_Entry__c te : queriedtimeEntryList){
                if(te.PS_Time_Card__c == tc.Id && appliedConsult.contains(te.PS_Task__r.Task_Type__c) && te.Billable__c){
                    tc.Total_Billable_Consult_Hours__c = tc.Total_Billable_Consult_Hours__c-teMap.get(te.Id).Hours_Spent__c;
                    
                }else if(te.PS_Time_Card__c == tc.Id && te.PS_Task__r.Task_Type__c == 'Consult - Non Billable' && !te.Billable__c){
                    tc.Total_Non_Billable_Consult_Hours__c = tc.Total_Non_Billable_Consult_Hours__c-teMap.get(te.Id).Hours_Spent__c;
                    
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Consult-Onsite' || te.PS_Task__r.Task_Type__c == 'Consult-Onsite-PD')  && te.Billable__c){
                    tc.Total_Billable_Consult_Hours__c = tc.Total_Billable_Consult_Hours__c -teMap.get(te.Id).Hours_Spent__c;
                    
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Consult-Remote' || te.PS_Task__r.Task_Type__c == 'Consult-Remote-PD'|| te.PS_Task__r.Task_Type__c == 'Accelerator' || te.PS_Task__r.Task_Type__c == 'Resident Engineer' || te.PS_Task__r.Task_Type__c == 'Resident Engineer-PD') && te.Billable__c){
                    tc.Total_Billable_Consult_Hours__c = tc.Total_Billable_Consult_Hours__c -teMap.get(te.Id).Hours_Spent__c;
                       
                }else if(te.PS_Time_Card__c == tc.Id && ( te.PS_Task__r.Task_Type__c == 'Install'|| te.PS_Task__r.Task_Type__c == 'Install-PD' || te.PS_Task__r.Task_Type__c == 'RCDM-Install') && te.Billable__c){
                    
                    tc.Total_Billable_Install_Hours__c = tc.Total_Billable_Install_Hours__c-teMap.get(te.Id).Hours_Spent__c;
                    
                }else if(te.PS_Time_Card__c == tc.Id && te.PS_Task__r.Task_Type__c == 'Install - Non Billable' && !te.Billable__c){
                    
                    tc.Total_Non_Billable_Install_Hours__c = tc.Total_Non_Billable_Install_Hours__c-teMap.get(te.Id).Hours_Spent__c;
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Non-Billable (Product)' || te.PS_Task__r.Task_Type__c == 'Non-Billable (PS)' || te.PS_Task__r.Task_Type__c == 'Non-Billable (Sales)' || te.PS_Task__r.Task_Type__c == 'Non-Billable (Expired)') && !te.Billable__c){
                    
                    tc.Total_Non_Billable_Hours_New__c = tc.Total_Non_Billable_Hours_New__c-teMap.get(te.Id).Hours_Spent__c;
                }else if(te.PS_Time_Card__c == tc.Id && (te.PS_Task__r.Task_Type__c == 'Admin' || te.PS_Task__r.Task_Type__c == 'CSAT') && !te.Billable__c){
                    tc.Total_Admin_Hours__c = tc.Total_Admin_Hours__c-teMap.get(te.Id).Hours_Spent__c;
                }
                if(te.Status__c == 'Submitted' ) {
                    isStatusSubmitted = true;
                }
                
            }
            for(PS_Time_Entry__c te : queriedtimeEntryList){
                if((te.Status__c == 'Draft')  && isStatusSubmitted) {
                    te.Status__c = 'Submitted';
                }
            }
            
            if((tc.Status__c == 'Approved' || tc.Status__c == 'Rejected')) {
                tc.Status__c = 'Draft';
            }
            
            if(isStatusSubmitted && tc.Status__c != 'Submitted') {
                tc.Status__c = 'Submitted';
                
            }
            else if(tc.Status__c != 'Approved' && tc.Status__c != 'Rejected') {
                tc.Status__c = 'Draft';
            }
        }
        update queriedTimeCardList;
        for(PS_time_Card__c tc: queriedTimeCardList){
            if(tc.Status__c == 'Submitted' /*|| tc.Status__c == 'Pending'*/) {
                if(!runOnce){
                    submitForApproval(tc.Id);
                    runOnce = true;
                }    
            }
            
        }
    }
    public static void updateSubtaskHours(Set<Id> subTaskIdSet) {
        
        List<PS_SubTask__c> subTaskUpdateList = new List<PS_SubTask__c>();
        for (PS_Subtask__C subtask : [select id, Hours_logged__c, (select id, Hours_Spent__c from PS_Time_Entries__r)  from PS_Subtask__C where ID IN : subTaskIdSet])
        {   
            Decimal totalHours =0;
            System.debug('subtask--'+subtask);
            System.debug('subtask ps--'+subtask.PS_Time_Entries__r);
            for(PS_Time_Entry__c psote : subtask.PS_Time_Entries__r) {
                totalHours += psote.Hours_Spent__c != null?psote.Hours_Spent__c :0;
            }
            subtask.Hours_logged__c = totalHours;
            subTaskUpdateList.add(subtask);
        }
        if(!subTaskUpdateList.isEmpty()) {
            update subTaskUpdateList;
        }
    }
    public class subtaskWrapperClass{
        @AuraEnabled public string taskName;
        @AuraEnabled public List<innerWrapperClass> innerWrapperList; 
        public subtaskWrapperClass(string taskName, List<innerWrapperClass> innerWrapperList1){
            this.taskName = taskName;
            innerWrapperList = innerWrapperList1;
        }
    }
    public class innerWrapperClass{
        @AuraEnabled public string taskId;  
        @AuraEnabled public string taskName;  
        @AuraEnabled public string subtaskId;
        @AuraEnabled public string subtaskName;
        @AuraEnabled public string notes;
        @AuraEnabled public Double totalhours;
        @AuraEnabled public List<PS_Time_Entry__c> psoList;   
        public innerWrapperClass(string taskId, string taskName,string subtaskId,string subtaskName,string notes,Double totalhours,List<PS_Time_Entry__c> psoList1){
            this.taskId = taskId;
            this.taskName = taskName;
            this.subtaskId = subtaskId;
            this.subtaskName = subtaskName;
            this.notes = notes;
            this.totalhours = totalhours;
            psoList = psoList1;
        }
    }
    
    public static void submitForApproval(Id recordId){
        If(!Approval.isLocked(recordId)){
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Auto-Submitted for weekly approval');
            approvalRequest.setObjectId(recordId);
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            System.debug('offer submitted for approval successfully: '+approvalResult .isSuccess());
        }
        System.debug('Already in approval');
    }
    
    @InvocableMethod
    public static void updateTasksFromProject(List<Id> psProjectIds){
        if(psProjectIds.isEmpty()) {
            return;
        }
        try{
            List<PS_Task__c> psTasksTobeUpdatedList = new List<PS_Task__c>();
            for(PS_Project__c project :[select id, Project_Status__c  , 
                                        	(select id, Task_Status__c , Task_Type__c, End_Date__c, Order_Product__c, Approved_Hours__c, Order_Item__r.TotalPrice, Project_Expiration_SKU__c, Line_Value__c 
                                             	from PS_Tasks__r Where Task_Status__c != 'Completed' AND Task_Status__c != 'Closed Short'
                                             	) //WHERE Order_Product__c NOT IN :PSTaskExpiryNotificationBatch.setExemptProductSKUs
                                        from PS_Project__c where ID IN : psProjectIds]) {
                                            for(PS_Task__c task : project.PS_Tasks__r) {
                                                if( task.Project_Expiration_SKU__c && task.Approved_Hours__c < 100 && task.Line_Value__c != 0) {
                                                    task.Task_Status__c = 'Closed Short';
                                                } else {
                                                    task.Task_Status__c = 'Completed';
                                                }
                                                if(task.End_Date__c  == null) {
                                                    task.End_Date__c  = System.Today();
                                                }
                                                psTasksTobeUpdatedList.add(task);
                                            }                                
                                        }
            if(!psTasksTobeUpdatedList.isEmpty()) {
                update psTasksTobeUpdatedList;
            }
        }
        catch(Exception ex){
        }
    }
    
    public class SubtaskRollUpAsyncJob implements Queueable {
        
        private List<PS_SubTask__c> subTaskUpdateList = new List<PS_SubTask__c>();
        
        
        public SubtaskRollUpAsyncJob(Set<Id> subTaskIdSet) {
            
            
            for (PS_Subtask__C subtask : [select id, Hours_logged__c, (select id, Hours_Spent__c from PS_Time_Entries__r)  from PS_Subtask__C where ID IN : subTaskIdSet])
            {   
                Decimal totalHours =0;
                System.debug('subtask--'+subtask);
                System.debug('subtask ps--'+subtask.PS_Time_Entries__r);
                for(PS_Time_Entry__c psote : subtask.PS_Time_Entries__r) {
                    totalHours += psote.Hours_Spent__c != null?psote.Hours_Spent__c :0;
                }
                subtask.Hours_logged__c = totalHours;
                subTaskUpdateList.add(subtask);
            }
            
        }
        
        public void execute(QueueableContext context) {
            if(!subTaskUpdateList.isEmpty()) {
                update subTaskUpdateList;
            }      
        }
    }    
    
}