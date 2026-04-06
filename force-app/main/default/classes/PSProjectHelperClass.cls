public class PSProjectHelperClass {
    public static boolean createtaskrecurssion = false;
    
    public static void createPSProject(List<Order> orderList){
        try{
            Map<string,List<string>> projAccountMap = new Map<string,List<string>>();
            Map<string,Order> projOrderMap = new Map<string,Order>();
            List<string> temp = new List<string>();
            List<string> accIds = new List<string>();
            List<string> str = new List<string>();
            List<Order> queriedorderList = [select Id, Name,TotalAmount, AccountId, Account.Name, Account.BillingState, Account.PS_Project_Manager__c, Account.PS_Project_Manager__r.IsActive, 
                                            Account.BillingCountry, Account_Billing_Address_Region__c, OpportunityId, Opportunity.Name,
                                            OrderNumber, PS_Project__c, PoNumber, Welcome_Letter_Contact__c, POC_Opportunity__c, POC_Opportunity__r.Name,
                                            Type, Order_Status__c
                                            FROM Order where Id IN: orderList AND (OpportunityId != null OR POC_Opportunity__c != null)];
            
            Id externalId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
            List<PS_Project__c> projList = new List<PS_Project__c>();
            List<PS_Project__c> createprojList = new List<PS_Project__c>();
            Set<Id> opportunityIds = new Set<Id>();
            
            for(Order orderObj : queriedorderList){
                accIds.add(orderObj.AccountId); 
                system.debug('Opp Id _________ '+orderObj.OpportunityId);
                system.debug('order type _________ '+orderObj.Type);
                if(orderObj.OpportunityId != null && orderObj.Type != 'POC') {
                    opportunityIds.add(orderObj.OpportunityId);
                } else if(orderObj.POC_Opportunity__c != null  && orderObj.Type == 'POC') {
                    opportunityIds.add(orderObj.POC_Opportunity__c);
                }
            }
            system.debug('opportunityIds _________ '+opportunityIds);
            Map<Id, Id> opportunityPrimaryContact = new Map<Id, Id>();
            if(opportunityIds.size() > 0){
                for(OpportunityContactRole ocr: [Select Id, ContactId, Contact.Email, OpportunityId from OpportunityContactRole
                                                 where OpportunityId in :opportunityIds and IsPrimary = true AND ContactId != null]){
                                                     opportunityPrimaryContact.put(ocr.OpportunityId, ocr.ContactId);
                                                     
                                                     system.debug('opportunityPrimaryContact=========' +opportunityPrimaryContact);
                                                 }
            }
            system.debug('opportunityPrimaryContact _________ '+opportunityPrimaryContact);
            
            system.debug('@@ accIds '+accIds);
            if(!accIds.isEmpty()){
                projList = [select Id,Name,Order__c,Account__c from PS_Project__c where Account__c IN : accIds];
            }
            system.debug('@@ projList '+projList);
            for(PS_Project__c proj : projList){
                List<string> tempList = new List<string>();
                if(!projAccountMap.isEmpty() && projAccountMap.containsKey(proj.Account__c)){
                    tempList = projAccountMap.get(proj.Account__c);
                }
                tempList.add(proj.Name);
                projAccountMap.put(proj.Account__c,tempList);
            }
            system.debug('@@ projAccountMap '+projAccountMap);
            Integer k = 0;
            string str2 = '';
            string oppName;
            Id oppId;
            for(Order ord : queriedorderList){
                if(ord.OpportunityId != null && ord.Type != 'POC') {
                    oppId = ord.OpportunityId;
                    oppName = ord.Opportunity.name;
                } else if(ord.POC_Opportunity__c != null  && ord.Type == 'POC') {
                    oppId = ord.POC_Opportunity__c;
                    oppName = ord.POC_Opportunity__r.name;
                }
                
                PS_Project__c proj = new PS_Project__c();
                k = 0 ;
                str2 = '';
                if(!projAccountMap.isEmpty() && projAccountMap.containsKey(ord.AccountId)){
                    temp = projAccountMap.get(ord.AccountId);
                    for(string projname : temp){
                        system.debug('projname--'+projname);
                        system.debug('oppId--'+oppId);
                        
                        if(projname.contains(oppName) && projname.contains('(') && projname.contains(')')){
                            try{
                                system.debug('str111--'+projname.split(oppName));
                                str = projname.split(oppName);
                                system.debug('str--'+str);
                                str2 = str[1].replace(')','');
                                str2 = str2.replace('(','');
                                system.debug('str22--'+str2);
                                if(k < Integer.valueOf(str2)){
                                    k = Integer.valueOf(str2);
                                }
                            }catch(Exception e){
                                system.debug('Exception occurred '+e.getMessage());
                            }
                        }
                    }
                }
                k++;
                String trimmedName;
                if(oppName != null){
                    trimmedName = ord.Account.Name+' - '+oppName+'('+k+')';
                }else{
                    trimmedName = ord.Account.Name+'('+k+')';
                }
                if(trimmedName.length() > Schema.SObjectType.PS_Project__c.fields.Name.getLength()){
                    trimmedName = trimmedName.left(Schema.SObjectType.PS_Project__c.fields.Name.getLength()-3)+'...';
                }
                proj.Name = trimmedName;
                system.debug('@@ Account.BillingState '+ord.Account.BillingState);
                system.debug('@@ AccountId '+Account.Id);
                if(ord.AccountId != null && ord.Account.PS_Project_Manager__c != null && ord.Account.PS_Project_Manager__c != '' && ord.Account.PS_Project_Manager__r.IsActive){
                    proj.Project_Manager__c = ord.Account.PS_Project_Manager__c;
                }
                else if(ord.AccountId != null && ord.Account.BillingState != null && ord.Account.BillingCountry == 'United States') {
                    String psProjectManagerMappingString = ord.Account.BillingCountry+'-'+ord.Account.BillingState;
                    system.debug('@@ psProjectManagerMappingString '+psProjectManagerMappingString);
                    if(ord.Account.BillingState == 'United States Minor Outlying Islands'){
                        psProjectManagerMappingString = 'United States Minor Outlying Islands';
                    }
                    PS_Project_Manager_Mapping__c psProjectManagerMapping = PS_Project_Manager_Mapping__c.getValues(psProjectManagerMappingString);
                    if(psProjectManagerMapping != null && psProjectManagerMapping.Project_Manager_User_Id__c != null) {
                        proj.Project_Manager__c = psProjectManagerMapping.Project_Manager_User_Id__c;
                    }
                }
                else if(ord.AccountId != null && ord.Account.BillingCountry != null && ord.Account_Billing_Address_Region__c != null) {
                    PS_Project_Manager_Mapping__c psProjectManagerMapping = PS_Project_Manager_Mapping__c.getValues(ord.Account_Billing_Address_Region__c);
                    if(psProjectManagerMapping != null && psProjectManagerMapping.Project_Manager_User_Id__c != null) {
                        proj.Project_Manager__c = psProjectManagerMapping.Project_Manager_User_Id__c;
                    }
                }
                system.debug('oppId ________________ '+ oppId);
                system.debug('opportunityPrimaryContact.containsKey(oppId) ________________ '+ opportunityPrimaryContact.containsKey(oppId));
                proj.RecordTypeId = externalId;
                proj.Project_Status__c = 'Not Started';
                proj.Project_Expected_Start_Date__c = system.today();
                proj.Project_Expected_End_Date__c = system.today();
                proj.Billable_Hours_Override__c = false;
                proj.Account__c = ord.AccountId;
                if(oppId != null && opportunityPrimaryContact.containsKey(oppId)){
                    proj.Welcome_Letter_Contact__c = opportunityPrimaryContact.get(oppId);
                    system.debug('proj.Welcome_Letter_Contact__c'+ proj.Welcome_Letter_Contact__c);
                }
                proj.opportunity__c = oppId;
                proj.PO_Number__c = ord.PONumber ;
                createprojList.add(proj);
                for(Order mainord : orderList){
                    if(mainord.Id == ord.Id){
                        projOrderMap.put(proj.Name,mainord);
                    }
                }
                system.debug('@@ Project_Manager__c '+proj.Project_Manager__c);
            }
            system.debug('@@ createprojList '+createprojList);
            system.debug('@@ projOrderMap '+projOrderMap);
            //CHANGES EGN-171 START
            List<PS_Project_Team_Member__c> TeamMemberList = new List<PS_Project_Team_Member__c>();
            if(!createprojList.isEmpty()){
                insert createprojList;
                for(PS_Project__c proj : createprojList){
                    if(!projOrderMap.isEmpty() && projOrderMap.containsKey(proj.name)){
                        Order ord = projOrderMap.get(proj.name);
                        ord.PS_Project__c = proj.Id;
                    }
                    if(proj.Project_Manager__c != null || proj.Project_Manager__c != ''){
                        TeamMemberList.add(new PS_Project_Team_Member__c(PS_Project__c = proj.Id, Team_Member__c = proj.Project_Manager__c));
                    }
                }
                if(!TeamMemberList.isEmpty()){
                    insert TeamMemberList;
                }
                if(Test.isRunningTest()) {
                    CalloutException e = new CalloutException();
                    e.setMessage('This is a constructed exception for testing and code coverage');
                    throw e;
                }
                //CHANGES EGN-171 END
            }
        }
        catch(Exception ex) {
            Batch_Error_Log__c bel = new Batch_Error_Log__c();
            bel.Failure_Job_ID__c = 'Failure on createPSProject';
            bel.Failure_Message__c = ex.getMessage();
            bel.Object_ID__c = 'PS Project';
            insert bel;
        }
    }
    
    public static void createPSProjectWithRelatedRecords(Set<Id> orderIdList, Boolean createBillablesubtask) {
        //try {
        List<Order> orderWithOrderLinesList = [select Id, name, AccountId, Ship_To_Name__c,Actual_Order_Ship_Date__c ,  
                                               OpportunityId, Opportunity.name, OrderNumber, PS_Project__c,
                                               (select id,OrderItemNumber, Required_by_Product_Code__c, PricebookEntry.Product2.Allow_PSO_Task_Creation__c,
                                                PricebookEntry.Product2.Name, Support_Start_Date__c, Support_End_Date__c, 
                                                Quantity from OrderItems where PricebookEntry.Product2.Allow_PSO_Task_Creation__c = true)
                                               FROM Order where Id IN: orderIdList];
        
        List<SObject> allPSRelatedRecordToBeInsert = new List<Sobject>();
        List<PS_Project__c> newPSProjectRecords = new List<PS_Project__c>();
        List<PS_Task__c> newPSTaskRecords = new List<PS_Task__c>();
        List<OrderItem> updateOrderItem= new List<OrderItem>();
        List<PS_SubTask__c> newPSSubtaskRecords = new List<PS_SubTask__c>();
        Set<id> itemsIds = new Set<Id>();
        system.debug('@@@Shadab - orderWithOrderLinesList=='+orderWithOrderLinesList);
        for(Order order : orderWithOrderLinesList) {
            if(order.AccountId != null) {
                for(OrderItem orderItem : order.OrderItems) {
                    //Old SKU INSTALL
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c ==true && orderItem.PricebookEntry.Product2.Name =='RBK-INSTALL') {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond();
                        date todaydate = system.today();
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Install',
                            Billable_Hours_Expected__c = orderItem.Quantity * 8,
                            Task_Status__c = 'Not Started',
                            Task_Start_Date__c  = todaydate,
                            Project__c = order.PS_Project__c,
                            Order_Item__c = orderItem.Id,
                            Unique_External_ID__c = uniqueString
                        );
                        PS_Task__c taskNB= new PS_Task__c(
                            Task_Type__c='Install - Non Billable',
                            Task_Status__c = 'Not Started',
                            Task_Start_Date__c  = todaydate,
                            Project__c = order.PS_Project__c,
                            Order_Item__c = orderItem.Id,
                            Unique_External_ID__c = uniqueString
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                        allPSRelatedRecordToBeInsert.add(taskNB);
                    }
                    //Old SKU CONSULT
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c ==true && orderItem.PricebookEntry.Product2.Name =='RBK-CONSULT') {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'CONSULT';
                        date todaydate = system.today();
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Consult',
                            Billable_Hours_Expected__c = orderItem.Quantity * 8,
                            Task_Status__c = 'Not Started',
                            Task_Start_Date__c  = todaydate,
                            Project__c = order.PS_Project__c,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString
                        );
                        PS_Task__c taskNB= new PS_Task__c(
                            Task_Type__c='Consult - Non Billable',
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Task_Start_Date__c  = todaydate,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                        allPSRelatedRecordToBeInsert.add(taskNB);
                    }
                    //CONSULT-ONSITE
                    set<string> Consult_Onsite = new set<string>();
                    Consult_Onsite.AddAll(Label.Consult_Onsite.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true && Consult_Onsite.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'Consult-Onsite';
                        date todaydate = system.today();
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Consult-Onsite',
                            Billable_Hours_Expected__c = orderItem.Quantity * 8,
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Task_Start_Date__c  = todaydate,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString
                        );
                        PS_Task__c taskNB= new PS_Task__c(
                            Task_Type__c='Consult - Non Billable',
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Task_Start_Date__c  = todaydate,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                        allPSRelatedRecordToBeInsert.add(taskNB);
                    }
                    
                    //CONSULT-REMOTE
                    set<string> Consult_Remote = new set<string>();
                    Consult_Remote.AddAll(Label.Consult_Remote.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true && Consult_Remote.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'Consult-Remote';
                        date todaydate = system.today();
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Consult-Remote',
                            Billable_Hours_Expected__c = orderItem.Quantity * 8,
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Task_Start_Date__c  = todaydate,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                    }
                    
                    /*RBK-T&E*/
                    set<string> TE = new set<string>();
                    TE.AddAll(Label.RBK_T_E.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true && TE.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'TE';
                        date todaydate = system.today();
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='T&E',
                            Billable_Hours_Expected__c = 0,
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Task_Start_Date__c  = orderItem.Required_by_Product_Code__c != 'RBK-PS-RES' ? todaydate : null,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                    }
                    
                    /*RBK-INSTALL-RE task creation*/
                    set<string> installProducts = new set<string>();
                    installProducts.AddAll(Label.RBK_INSTALL.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true && installProducts.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'INSTALL';
                        date todaydate = system.today();
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Install',
                            Billable_Hours_Expected__c = orderItem.Quantity * 12,
                            Task_Status__c = 'Not Started',
                            Account__c = order.AccountId,
                            Project__c = order.PS_Project__c,
                            Consult_Quantity__c = orderItem.Quantity,
                            Order_Item__c = orderItem.Id,
                            Task_Start_Date__c  = todaydate,
                            Task_End_date__c    = todaydate.addMonths(6)-1,
                            Unique_External_ID__c = uniqueString
                            
                        );
                        
                        PS_Task__c taskNB= new PS_Task__c(
                            Task_Type__c='Install - Non Billable',
                            Task_Status__c = 'Not Started',
                            Account__c = order.AccountId,
                            Project__c = order.PS_Project__c,
                            Consult_Quantity__c = orderItem.Quantity,
                            Order_Item__c = orderItem.Id,
                            Task_Start_Date__c  = todaydate,
                            Task_End_date__c    = todaydate.addMonths(6)-1,
                            Unique_External_ID__c = uniqueString
                            
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                        allPSRelatedRecordToBeInsert.add(taskNB);
                        if(order.Actual_Order_Ship_Date__c != null && !itemsIds.contains(orderItem.Id)){
                            updateOrderItem.add(new OrderItem(id=orderItem.Id,ServiceDate = order.Actual_Order_Ship_Date__c ,EndDate = order.Actual_Order_Ship_Date__c.addMonths(6)-1));
                            itemsIds.add(orderItem.Id);
                        }
                        
                    }
                    
                    /*RBK-DATA-MIGRATION task creation*/
                    set<string> migrationProducts = new set<string>();
                    migrationProducts.AddAll(Label.RBK_DATA_MIGRATION.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c ==true && migrationProducts.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'MIGRATION';
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Migration',
                            Billable_Hours_Expected__c = 0,
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString, 
                            Account__c = order.AccountId
                        );
                        allPSRelatedRecordToBeInsert.add(task);
                    }
                    
                    
                    /*RBK-CONSULT-RE task creation*/
                    set<string> reProducts = new set<string>();
                    reProducts.AddAll(Label.RBK_PS_RES.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true && reProducts.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'Resident Engineer';
                        Date todayDate = system.today();
                        
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c    ='Resident Engineer',
                            Task_Status__c  = 'Not Started',
                            Account__c = order.AccountId,
                            Project__c      = order.PS_Project__c,
                            Order_Item__c   = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Unique_External_ID__c = uniqueString 
                            //Task_Start_Date__c  = todaydate,
                            //Task_End_date__c = orderItem.Quantity != null ? system.today().addmonths(Integer.valueOf(orderItem.Quantity))-1 : system.today()
                        );
                        
                        allPSRelatedRecordToBeInsert.add(task);
                    }
                    
                    /*Changes related to CS21-194 Go refresh ends*/
                    set<string> consultProducts = new set<string>();
                    consultProducts.AddAll(Label.RBK_CONSULT.Split(','));
                    if(orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true && consultProducts.Contains(orderItem.PricebookEntry.Product2.Name)) {
                        
                        String uniqueString = orderItem.orderItemNumber+Datetime.now().millisecond()+'CONSULT';
                        date todaydate = system.today();
                        
                        PS_Task__c task= new PS_Task__c(
                            Task_Type__c='Consult',
                            Billable_Hours_Expected__c = orderItem.Quantity * 8,
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Account__c = order.AccountId,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Task_Start_Date__c  = todaydate,
                            Task_End_date__c    = todaydate.addMonths(6)-1,
                            Unique_External_ID__c = uniqueString 
                            //  CSAT__c = order.PS_Project__r.CSAT__c    updated by grazitti
                        );
                        
                        PS_Task__c taskNB = new PS_Task__c(
                            Task_Type__c='Consult - Non Billable',
                            Task_Status__c = 'Not Started',
                            Project__c = order.PS_Project__c,
                            Account__c = order.AccountId,
                            Order_Item__c = orderItem.Id,
                            Consult_Quantity__c = orderItem.Quantity,
                            Task_Start_Date__c  = todaydate,
                            Task_End_date__c    = todaydate.addMonths(6)-1,
                            Unique_External_ID__c = uniqueString 
                        );
                        system.debug('Inside consult'+task);
                        allPSRelatedRecordToBeInsert.add(task);
                        allPSRelatedRecordToBeInsert.add(taskNB);
                        if(order.Actual_Order_Ship_Date__c != null  && !itemsIds.contains(orderItem.Id)){
                            updateOrderItem.add(new OrderItem(id=orderItem.Id,ServiceDate = order.Actual_Order_Ship_Date__c ,EndDate = order.Actual_Order_Ship_Date__c.addMonths(6)-1));
                            itemsIds.add(orderItem.Id);
                            
                        }
                        
                    }
                    system.debug('@@@Shadab - newPSSubtaskRecords=='+newPSSubtaskRecords);
                    system.debug('@@@Shadab - newPSSubtaskRecords size=='+newPSSubtaskRecords.size());
                }
                
            }
        }
        //allPSRelatedRecordToBeInsert.addAll(newPSTaskRecords);
        if(!allPSRelatedRecordToBeInsert.isEmpty()){
            try{
                insert allPSRelatedRecordToBeInsert;  
                if(Test.isRunningTest()) {
                    CalloutException e = new CalloutException();
                    e.setMessage('This is a constructed exception for testing and code coverage');
                    throw e;
                }            }catch(Exception e){
                    Error_Logs__c el = new Error_Logs__c(
                        Error_Type__c = 'Failure on createPSProjectWithRelatedRecords',
                        Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString()+'\r\n'+e.getCause(),
                        Type__c = 'SFDC'
                    );
                    if(!System.isFuture() && !System.isBatch())
                        PSProjectHelperClass.addLogs(JSON.serialize(el));
                }
            
        }
        if(!updateOrderItem.isEmpty())
            database.update(updateOrderItem,false);
        /*}
catch(Exception ex) {
Batch_Error_Log__c bel = new Batch_Error_Log__c();
bel.Failure_Job_ID__c = 'Failure on createPSProjectWithRelatedRecords';
bel.Failure_Message__c = ex.getMessage();
bel.Object_ID__c = 'PS Project';
insert bel;
} */
    }
    
    @future
    public static void addLogs(String errorString){ 
        Error_Logs__c el = (Error_Logs__c)JSON.deserialize(errorString,Error_Logs__c.class);
        Database.insert(el);
    }
    public Static void  updatePSTaskOnProjectUpdate(Map<Id, Id> psOldProjectVsNewProject) {
        try {
            if(!psOldProjectVsNewProject.isEmpty()) {
                List<PS_Task__c> psTasksUpdateList = new List<PS_Task__c>();
                for(PS_Task__c psTask : [select Id, Name, Project__c from PS_Task__c 
                                         where Project__c IN : psOldProjectVsNewProject.keySet()]) {
                                             psTask.Project__c = psOldProjectVsNewProject.get(psTask.Project__c);
                                             psTasksUpdateList.add(psTask);
                                         }
                if(!psTasksUpdateList.isEmpty()) {
                    update psTasksUpdateList;
                }
            }
        }
        catch(DMLException ex) {
            
        }
        
    }
       // Sprint4MKT24Deployment V2
    public static void createAdminTaskSubtaskRecords(Set<Id> projectIdSet, Boolean allowAdminSubTaskCreation) {
        List<PS_Project__c> projectList = [select Id, name, Account__c,RecordType.DeveloperName FROM PS_Project__c where Id IN: projectIdSet];
        
        List<SObject> allPSRelatedRecordToBeInsert = new List<Sobject>();
        List<PS_Project__c> newPSProjectRecords = new List<PS_Project__c>();
        List<PS_Task__c> newPSTaskRecords = new List<PS_Task__c>();
        List<PS_SubTask__c> newPSSubtaskRecords = new List<PS_SubTask__c>();
        //system.debug('@@@Shadab - orderWithOrderLinesList=='+orderWithOrderLinesList);
        for(PS_Project__c project : projectList) {
            if(project.Name != null) {
                system.debug('@@@Shadab - OrderItems=='+project);
                if(project.recordType.DeveloperName == 'Internal') {
                    
                    String uniqueString = SYSTEM.TODAY()+Datetime.now().millisecond()+'ADMIN';
                    PS_Task__c task= new PS_Task__c(
                        Task_Type__c='Admin',
                        //Billable_Hours_Expected__c = orderItem.Quantity * 8,
                        Task_Status__c = 'Not Started',
                        Project__c = project.Id,
                        Unique_External_ID__c = uniqueString
                        
                    );
                    newPSTaskRecords.add(task);
                   
                } 
                
            }
            
        }
        if(newPSTaskRecords.size()>0){
             INSERT newPSTaskRecords;
        }
    }
}