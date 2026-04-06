global class BatchCreatePSProject implements Database.Batchable<sObject>, Database.RaisesPlatformEvents, Database.Stateful {
    global String query;
    global Set<Id> setRubrikUOrderId; //Added for MKT26-773
    //global Boolean runAll;
    //V4 Deplouyment
    global BatchCreatePSProject (String query){
        this.query = query;
        //this.runAll = false;
    }
    /*global BatchCreatePSProject(String query, Boolean runAll){
        this.runAll = runAll;
        this.query = query;
    }*/
    
    /*global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCreatePSProject(query));
    }*/
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> ordersId = new Set<Id>();
        this.setRubrikUOrderId = new Set<Id>();//Added for MKT26-773
        Map<String, PS_Task_Meta__mdt> mapSKUtoMdt = new Map<String, PS_Task_Meta__mdt>();//Added for MKT26-773
        Map<Id, List<OrderItem>> mapIdToOrderItem = new Map<Id, List<OrderItem>>();//Added for MKT26-773
        if(query == ''){
            Set<String> supportedTasks = new Set<String>();
            for(PS_Task_Meta__mdt taskMeta : [SELECT Id, MasterLabel, Label, Task_Type__c FROM PS_Task_Meta__mdt]){
                supportedTasks.add(taskMeta.Label);
                mapSKUtoMdt.put( taskMeta.MasterLabel, taskMeta );
            }
            //List<Id> ordersId = new List<Id>();
            String orderItemQuery = 'Select Id, OrderId,(Select Id From PS_Tasks__r), Product2.ProductCode From OrderItem Where Allow_PSO_Task_Creation__c=true AND Product2.ProductCode In:supportedTasks And (Order.Order_Status__c=\'Order Accepted\' OR Order.Order_Status__c=\'Shipped\') And Order.Type=\'Revenue\' AND CreatedDate = THIS_YEAR';
            /*If( this.runAll == false ) {
                orderItemQuery+= ' And (Order.LastModifiedDate=TODAY OR Order.LastModifiedDate=YESTERDAY)';
            }*/
            //for(OrderItem oi : [SELECT id,OrderId FROM OrderItem WHERE Product2.ProductCode IN:supportedTasks  AND Order.Order_Status__c = 'Shipped' AND Order.Type = 'Revenue' AND Has_PSTask__c = false]){
            for(OrderItem oi : Database.query(orderItemQuery)){
                if(!ordersId.contains(oi.OrderId) && (oi.PS_Tasks__r ==null || oi.PS_Tasks__r.size() == 0)) {
                    ordersId.add(oi.OrderId);
                } 
                if( mapIdToOrderItem.containsKey(oi.OrderId) ) { //Added for MKT26-773
                    mapIdToOrderItem.get( oi.OrderId ).add( oi );
                } else {
                    mapIdToOrderItem.put( oi.OrderId, new List<OrderItem>{ oi });
                }
            }
            PSTaskService.setOrderswithRubrikU(mapIdToOrderItem, null, mapSKUtoMdt);//Added for 773
            this.setRubrikUOrderId = PSTaskService.setRubrikUOrderId;//Added for 773
            system.debug('===>><><' + ordersId);
            //ordersId.clear();
            //ordersId.add('80179000000Dj2B');
            //query ='SELECT ID, AccountId, Type,PS_Project__c, POC_Opportunity__c, Bill_To_Name__c, OpportunityId, Account_Billing_Address_Region__c, PONumber FROM Order Where ID IN (\''+String.join(ordersId, '\',\'')+'\')';
        }
        return Database.getQueryLocator('SELECT ID, AccountId, Type,PS_Project__c, POC_Opportunity__c, Bill_To_Name__c, OpportunityId, Account_Billing_Address_Region__c, PONumber, RSC_G_Enabled__c FROM Order Where ID In:ordersId');
    }
    global void execute(Database.BatchableContext BC, list<Order> odrList){
        
        Set<Id> oppIds = new Set<Id>();
        //Set<Id> pocOppIds = new Set<Id>();
        Set<Id> OrdaccIds = new Set<Id>();
         Set<Id> OppccIds = new Set<Id>();
        map<String,Integer> oppToPSProjectCount = new map<String,Integer>();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        Map<Id, OpportunityContactRole> oppId_OCRMap = new Map<Id, OpportunityContactRole>();
        Map<Id, List<PS_Project__c>> accIdPSProjects = new Map<Id, List<PS_Project__c>>();
        Map<Id,PS_Project__c> OrdPSProjToInsertMap = new Map<Id,PS_Project__c>();
        
        Id PSExternalRecId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
        PSTaskService psService = new PSTaskService();
        PSTaskService.setRubrikUOrderId = setRubrikUOrderId;//Added for MKT26-773
        
        for(Order ord:odrList){
            if (ord.OpportunityId != null) {
                oppIds.add(ord.OpportunityId);
            }
            if (ord.POC_Opportunity__c != null) {
                oppIds.add(ord.POC_Opportunity__c);
            }
            if (ord.accountId != null)
                OrdaccIds.add(ord.accountId);
            if (ord.Bill_To_Name__c != null) {
                OrdaccIds.add(ord.Bill_To_Name__c);
            }
        }
        
        if (!oppIds.isEmpty()) {
            for (OpportunityContactRole ocr : [SELECT Id, ContactId, Contact.Email, OpportunityId
                                               FROM OpportunityContactRole
                                               WHERE OpportunityId IN :oppIds AND IsPrimary = TRUE
                                              ]) {
                                                  oppId_OCRMap.put(ocr.OpportunityId, ocr);
                                              }
        }
        
        for(Opportunity opp:[SELECT Id,AccountId,StageName,Name,Distributor_Lookup__c FROM opportunity WHERE Id IN :oppIds]){
            oppMap.put(opp.Id,opp);
            if (opp.Distributor_Lookup__c != null)
                OrdaccIds.add(opp.Distributor_Lookup__c);
            if (opp.accountId != null) {
                 OrdaccIds.add(opp.accountId); 
                 OppccIds.add(opp.Id);
            }
                
        }
        if(OppccIds.size()>0) {
            for (AggregateResult ar : [SELECT Opportunity__c, count(Id)
                                        FROM PS_Project__c 
                                        WHERE Opportunity__c IN :OppccIds
                                        GROUP BY Opportunity__c]){
                oppToPSProjectCount.put(String.valueOf(ar.get('Opportunity__c')), Integer.valueOf(ar.get('expr0')));
            }
            
        }
         
        
        if (!OrdaccIds.isEmpty()) {
            for (PS_Project__c proj : [ SELECT Id, Name, Account__c, Opportunity__c FROM PS_Project__c WHERE Account__c IN :OrdaccIds
                                       ORDER BY createddate DESC]) {
                                           if (!accIdPSProjects.containsKey(proj.Account__c)) {
                                               accIdPSProjects.put(proj.Account__c,new List<PS_Project__c>());
                                           } 
                                           accIdPSProjects.get(proj.Account__c).add(proj);
                                       }
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id,Name,Type,Owner.Name,BillingState,BillingCountry,
                                                            BillingCountryCode, ETM_Area__c, PS_Project_Manager__c, PS_Project_Manager__r.IsActive FROM Account WHERE id IN :OrdaccIds]);
        Set<String> psProjectsIds = new Set<String>();
        //Creating PS Projects
        Set<Id> setNewProjectOrders = new Set<Id>();
        Set<Id> setOrderIdForExistingProjects = new Set<Id>();
        for(Order odr:odrList){
            if(odr.PS_Project__c != null){
                psProjectsIds.add((String)odr.PS_Project__c);
                setOrderIdForExistingProjects.add( odr.Id );
                OrdPSProjToInsertMap.put(odr.Id,new PS_Project__c(id= odr.PS_Project__c));
                continue;
            }
            try{
                Opportunity opp = odr.Type == 'POC' ? oppMap?.get(odr.POC_Opportunity__c) : oppMap?.get(odr.OpportunityId);
                Account acc = accountMap?.get(odr.accountId);
                OpportunityContactRole primaryOCR = opp != null ? oppId_OCRMap.get(opp.id) : null;
                
                Integer index = oppToPSProjectCount.containsKey(opp.Id)?oppToPSProjectCount.get(opp.Id):0;
                List<PS_Project__c> PSProjects = accIdPSProjects.get(odr.AccountId);
                Map<Id, List<PS_Project__c>> oppIdToPsProjectListMap = new Map<Id, List<PS_Project__c>>();
                if(PSProjects != null){ 
                    for(PS_Project__c proj : PSProjects){
                        if(!oppIdToPsProjectListMap.containsKey(proj.Opportunity__c)){
                            oppIdToPsProjectListMap.put(proj.Opportunity__c, new List<PS_Project__c>());
                        }
                        oppIdToPsProjectListMap.get(proj.Opportunity__c).add(proj);
                    }
                    index = oppIdToPsProjectListMap.containsKey(odr.OpportunityId) ? oppIdToPsProjectListMap.get(odr.OpportunityId).size() : index;
                } 
                index++;
                
                PS_Project__c proj = new PS_Project__c();
                String trimmedName;
                if(opp != null ){
                    trimmedName = acc.Name+' - '+opp.name+'('+index+')';
                }else{
                    trimmedName = acc.Name+'('+index+')';
                }
                if(trimmedName.length() > Schema.SObjectType.PS_Project__c.fields.Name.getLength()){
                    trimmedName = trimmedName.left(Schema.SObjectType.PS_Project__c.fields.Name.getLength()-6) + '...' +'('+index+')';
                }
                proj.Name = trimmedName;
                //system.debug(LoggingLevel.FINE,'Account.BillingState '+acc.BillingState+'\n Account_Billing_Address_Region__c '+newOrd.Account_Billing_Address_Region__c);
               
                 /*if( odr.Account_Billing_Address_Region__c != null) {
                    PS_Project_Manager_Mapping__c psProjectManagerMapping = PS_Project_Manager_Mapping__c.getValues(odr.Account_Billing_Address_Region__c);
                    if(psProjectManagerMapping != null && psProjectManagerMapping.Project_Manager_User_Id__c != null) {
                        proj.Project_Manager__c = psProjectManagerMapping.Project_Manager_User_Id__c;
                    }
                }*/
                
                /*if(acc.BillingState != null && acc.BillingCountry == 'United States') {
                    String psProjectManagerMapping_String = acc.BillingCountry+'-'+acc.BillingState;
                    system.debug(LoggingLevel.FINE,'psProjectManagerMapping_String '+psProjectManagerMapping_String);
                    if(acc.ETM_Area__c == 'AMER-FED') {
                        psProjectManagerMapping_String = acc.ETM_Area__c;
                    }
                    else if(acc.ETM_Area__c.contains('AMER-SLED')) {
                        psProjectManagerMapping_String = 'AMER-SLED';
                    }
                    else if(acc.BillingState == 'United States Minor Outlying Islands'){
                        psProjectManagerMapping_String = 'United States Minor Outlying Islands';
                    }
                    PS_Project_Manager_Mapping__c psProjectManager_Mapping = PS_Project_Manager_Mapping__c.getValues(psProjectManagerMapping_String);
                    if(psProjectManager_Mapping != null && psProjectManager_Mapping.Project_Manager_User_Id__c != null) {
                        proj.Project_Manager__c = psProjectManager_Mapping.Project_Manager_User_Id__c;
                    }
                }
                else if( acc.BillingCountry != null && odr.Account_Billing_Address_Region__c != null) {
                    PS_Project_Manager_Mapping__c psProject_ManagerMapping = PS_Project_Manager_Mapping__c.getValues(odr.Account_Billing_Address_Region__c);
                    if(psProject_ManagerMapping != null && psProject_ManagerMapping.Project_Manager_User_Id__c != null) {
                        proj.Project_Manager__c = psProject_ManagerMapping.Project_Manager_User_Id__c;
                    }
                }*/
                Id projectManager = psService.routePSProjectManager(odr);
                if(!setRubrikUOrderId.contains( odr.Id ) && acc.PS_Project_Manager__c != null && acc.PS_Project_Manager__r.IsActive){ //Updated for MKT26-773
                    proj.Project_Manager__c = acc.PS_Project_Manager__c;
                }   
                else if(projectManager!= null){
                    proj.Project_Manager__c = projectManager;
                }
                proj.RecordTypeId = PSExternalRecId;
                proj.Project_Status__c = 'Not Started';
                proj.Project_Expected_Start_Date__c = system.today();
                proj.Project_Expected_End_Date__c = system.today();
                proj.Billable_Hours_Override__c = false;
                proj.Account__c = odr.AccountId;
                proj.Welcome_Letter_Contact__c = primaryOCR?.ContactId;
                proj.opportunity__c = opp?.Id;
                proj.PO_Number__c = odr.PONumber ;
                OrdPSProjToInsertMap.put(odr.Id,proj);
                if (!accIdPSProjects.containsKey(proj.Account__c)) {
                    accIdPSProjects.put(proj.Account__c,new List<PS_Project__c>());
                } 
                accIdPSProjects.get(proj.Account__c).add(proj);
            }
            catch(Exception ex) {
                System.debug(LoggingLevel.Error,'err'+ ex.getMessage()); 
            }
        }
        
        if(!OrdPSProjToInsertMap.values().isEmpty()){
            System.debug('psProjectsIds'+psProjectsIds.size());
            System.debug('PSProjToInsert'+OrdPSProjToInsertMap.size());
            upsert OrdPSProjToInsertMap.values();
            System.debug('OrdPSProjToInsertMap'+OrdPSProjToInsertMap);
            List<PS_Project_Team_Member__c> TeamMemberList = new List<PS_Project_Team_Member__c>();
            for(PS_Project__c proj : OrdPSProjToInsertMap.values()){
                System.debug('proj--'+psProjectsIds);
                System.debug('proj--'+proj); 
                System.debug('Project_Manager__c--'+proj.Project_Manager__c); 
                if(!psProjectsIds.contains(proj.Id) && proj.Project_Manager__c != null){
                    TeamMemberList.add(new PS_Project_Team_Member__c(PS_Project__c = proj.Id, Team_Member__c = proj.Project_Manager__c));
                }
                System.debug('TeamMemberList--'+TeamMemberList);
            }
            if(!TeamMemberList.isEmpty()){
                insert TeamMemberList;
            }
        }
        
        List<Order> Orders = new List<Order>();        
        for(Id ordId:OrdPSProjToInsertMap.keyset()){
            Order ord = new Order(Id=ordId,PS_Project__c=OrdPSProjToInsertMap.get(ordId).Id);
            Orders.add(ord);
        }
        if(!Orders.isEmpty()){
            update Orders;
        }
        
        
        List<Id> PSProjList = new List<Id>();
        Set<OrderItem> OIList = new Set<OrderItem>();
        List<PS_Task__c> psTaskToInsert = new List<PS_Task__c>();
        List<Id> ids = new List<Id>();
        Map<Id,List<OrderItem>> idsMap = new Map<Id,List<OrderItem>>();
        List<PS_Task__c> psTasks = new List<PS_Task__c>();
        List<OrderItem> OdrItems = new List<OrderItem>();
        List<Id> taskIds = new List<Id>();
        for(Order od:[Select Id,PS_Project__c,(Select Id, OrderId, Order.AccountId, Order.Actual_Order_Ship_Date__c, Product2.Product_Type__c, Order.OrderNumber, Product2.Name,
                                               Product2.Allow_PSO_Task_Creation__c, orderItemNumber, Product2.ProductCode,Required_by_Product_Code__c,
                                               Quantity, Order.PS_Project__c from OrderItems) from Order Where PS_Project__c != null AND ID In: OrdPSProjToInsertMap.keyset()])
        {
            if(!idsMap.containsKey(od.Id)){
                idsMap.put(od.PS_Project__c,new List<OrderItem>());
            }
            idsMap.get(od.PS_Project__c).addAll(od.OrderItems);
        }
        system.debug('====>>>>>><><' + idsMap);
        for(PS_Project__c proj:[Select Id,(Select Id,Project__c,Order_Item__c from PS_Tasks__r) from PS_Project__c where Id IN:idsMap.keySet()]){
            if(proj.PS_Tasks__r.isEmpty()){
                OIList.addAll(idsMap.get(proj.Id));
            }else if(proj.PS_Tasks__r.size() < idsMap.get(proj.Id).size()){
                psTasks.addAll(proj.PS_Tasks__r);
                OdrItems.addAll(idsMap.get(proj.Id));
            }
        }
        
        for(PS_Task__c task:psTasks){
            taskIds.add(task.Order_Item__c);
        }
        for(OrderItem OI:OdrItems){
            if(!taskIds.contains(OI.Id)){
                OIList.add(OI);
            }      
        }
        
        /*set<string> Consult_Onsite = new set<string>();
        set<string> Consult_Remote = new set<string>(); 
        set<string> TE = new set<string>();
        set<string> installProducts = new set<string>();
        set<string> migrationProducts = new set<string>();
        set<string> consultProducts = new set<string>();
        set<string> reProducts = new set<string>();
        
        Consult_Onsite.AddAll(Label.Consult_Onsite.Split(','));
        Consult_Remote.AddAll(Label.Consult_Remote.Split(','));
        installProducts.AddAll(Label.RBK_INSTALL.Split(','));
        TE.AddAll(Label.RBK_T_E.Split(','));
        migrationProducts.AddAll(Label.RBK_DATA_MIGRATION.Split(','));   
        consultProducts.AddAll(Label.RBK_CONSULT.Split(','));
        reProducts.AddAll(Label.RBK_PS_RES.Split(','));*/
        Date todayDate = system.today();
        Date cutOffDate = Date.newInstance( todayDate.year() , todayDate.month(), 25);
        Map<Id, orderItem> orderItemToUpdate = new Map<Id, orderItem>();
        if(OIList != null)
            for(OrderItem OI : OIList){
                if(OI.Product2.Allow_PSO_Task_Creation__c ==true ){
                    String uniqueString = OI.orderItemNumber+Datetime.now().millisecond();
                    
                    PS_Task__c task= new PS_Task__c(Task_Status__c = 'Not Started',
                                                    Project__c = OI.Order.PS_Project__c,
                                                    Order_Item__c = OI.Id, Order_Number__c = OI.Order.OrderNumber, SKU_Name__c = OI.Product2.Name);
                    if(PS_Task_Meta__mdt.getInstance(OI.Product2.ProductCode.replace('-','_')) != null){
                    PS_Task_Meta__mdt meta = PS_Task_Meta__mdt.getInstance(OI.Product2.ProductCode.replace('-','_'));
                    task.Task_Type__c = meta.Task_Type__c;
                    task.Unique_External_ID__c = uniqueString+meta.Task_Type__c;
                    task.Billable_Hours_Expected__c = meta.Billable_Hours__c != null ? (OI.Quantity * meta.Billable_Hours__c) : null;
                    task.Revenue_Type__c = meta.Revenue_Type__c;
                    if(meta.End_Date__c == '1 Year'){
                        task.Task_End_date__c = system.today().addYears(1);
                    }else if(meta.End_Date__c == '6 Months'){
                        task.Task_End_date__c = system.today().addMonths(6)-1;
                    }
                    if(meta.Account__c){
                        task.Account__c = OI.Order.AccountId;
                    }
                    if(meta.Consult_Quantity__c){
                        task.Consult_Quantity__c = OI.Quantity;
                    }
                    if( meta.Start_Date__c == 'Formula') {  //RBK-T&E*
                        task.Task_Start_Date__c  = OI.Required_by_Product_Code__c != 'RBK-PS-RES' ? system.today() : null;
                    }else if(meta.Start_Date__c == 'Today'){
                        task.Task_Start_Date__c = System.today();
                    }else if(meta.Start_Date__c == 'Null'){
                        task.Task_Start_Date__c = Null;
                    }else if (meta.Start_Date__c == '6 Months') {
                        task.Task_Start_Date__c = System.today().addMonths(6);
                        task.Task_End_date__c = task.Task_Start_Date__c.addmonths(Integer.valueOf(task.Consult_Quantity__c))-1;
                    }
                    
                    if( task.Task_Type__c != null && task.Task_Type__c.contains('Non-Billable') ) {
                        task.Sync_to_Net_Suite__c = 'No Sync Required';
                    }
                    if(meta.OrderItem_Update__c){
                        if(OI.Order.Actual_Order_Ship_Date__c != null){
                            OrderItem OItoUpdate = orderItemToUpdate!=null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
                            OItoUpdate.id =OI.id ;
                            OItoUpdate.Support_Start_Date__c = OI.Order.Actual_Order_Ship_Date__c ;
                            OItoUpdate.Support_End_Date__c = OI.Order.Actual_Order_Ship_Date__c.addMonths(6)-1;
                            orderItemToUpdate.put(OI.id,OItoUpdate);
                        }
                    }}
                    
                    /*PS_Task__c task= new PS_Task__c(Billable_Hours_Expected__c = OI.Quantity * 8,
                                                    Task_Status__c = 'Not Started',
                                                    Project__c = OI.Order.PS_Project__c,
                                                    Task_Start_Date__c  = system.today(),
                                                    Order_Item__c = OI.Id);
                    if(OI.Product2.ProductCode =='RBK-INSTALL'){ //Old SKU INSTALL
                        task.Task_Start_Date__c  = null;//New Changes                        
                        task.Task_Type__c='Install';
                        task.Unique_External_ID__c = uniqueString;
                    }  
                    else if(OI.Product2.ProductCode == 'RBK-CONSULT'){  //Old SKU CONSULT
                        task.Task_Start_Date__c  = null;//New Changes
                        task.Task_Type__c='Consult';
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'CONSULT';
                    }
                    else if(Consult_Onsite.Contains(OI.Product2.ProductCode)){  //CONSULT-ONSITE
                        task.Task_Type__c='Consult-Onsite';
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Consult-Onsite';
                        if(OI.Product2.ProductCode.contains('ONST-PD')){
                            task.Task_Type__c='Consult-Onsite-PD';
                        }
                    }
                    else if( Consult_Remote.Contains(OI.Product2.ProductCode)) {  //CONSULT-REMOTE
                        task.Task_Type__c='Consult-Remote';
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Consult-Remote';
                        if(OI.Product2.ProductCode.contains('RMOT-PD')){
                            task.Task_Type__c='Consult-Remote-PD';
                        }
                    }
                    
                    else if( TE.Contains(OI.Product2.ProductCode)) {  //RBK-T&E*
                        task.Task_Type__c='T&E';
                        task.Billable_Hours_Expected__c = 0;
                        task.Task_Start_Date__c  = OI.Required_by_Product_Code__c != 'RBK-PS-RES' ? system.today() : null;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'TE'; 
                    }
                    else if(installProducts.Contains(OI.Product2.ProductCode)) { // RBK-INSTALL-RE
                        task.Task_Type__c='Install';
                        task.Billable_Hours_Expected__c = OI.Quantity * 12;
                        task.Account__c = OI.Order.AccountId; 
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Task_End_date__c    = system.today().addMonths(6)-1;
                        task.Unique_External_ID__c = uniqueString+'INSTALL';    
                        if(OI.Product2.ProductCode.Contains('RCDM')){//RBK-PS-RCDM-INST - Billable - 1hrs
                            task.Billable_Hours_Expected__c = OI.Quantity * 1;
                            task.Task_Type__c='RCDM-Install';
                        }
                        if(OI.Product2.ProductCode.contains('INST-PD')){
                            task.Task_Type__c='Install-PD';
                        }
                        if(OI.Order.Actual_Order_Ship_Date__c != null){
                            OrderItem OItoUpdate = orderItemToUpdate!=null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
                            OItoUpdate.id =OI.id ;
                            OItoUpdate.Support_Start_Date__c = OI.Order.Actual_Order_Ship_Date__c ; // OI.servicedate
                            OItoUpdate.Support_End_Date__c = OI.Order.Actual_Order_Ship_Date__c.addMonths(6)-1; //OI.enddate
                            orderItemToUpdate.put(OI.id,OItoUpdate); 
                        }     
                    }
                    else if(migrationProducts.Contains(OI.Product2.ProductCode)) { // RBK-DATA-MIGRATION 
                        task.Task_Type__c='Migration';
                        task.Billable_Hours_Expected__c = 0;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'MIGRATION'; 
                        task.Account__c = OI.Order.AccountId ;
                        task.Task_End_date__c = system.today().addYears(1);// New Changes
                    }
                    else if(reProducts.Contains(OI.Product2.ProductCode)) { // RBK-CONSULT-RE 
                        task.Task_Type__c    ='Resident Engineer';
                        task.Account__c = OI.Order.AccountId;
                        task.Task_Start_Date__c  = null;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Resident Engineer';  
                    }
                    else if(OI.Product2.ProductCode =='RBK-PS-RES-PD'){// CHANGES CS21-489 START
                        task.Task_Type__c    ='Resident Engineer-PD';
                        task.Account__c = OI.Order.AccountId;
                        task.Task_Start_Date__c  = null;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Resident Engineer-PD';
                    } // CHANGES CS21-489 END
                    else if(consultProducts.Contains(OI.Product2.ProductCode)) {
                        task.Task_Type__c='Consult';
                        task.Account__c = OI.Order.AccountId;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Task_End_date__c    = system.today().addMonths(6)-1;
                        task.Unique_External_ID__c = uniqueString+'CONSULT';
                        if(OI.Order.Actual_Order_Ship_Date__c != null){
                            OrderItem OItoUpdate = orderItemToUpdate!=null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
                            OItoUpdate.id =OI.id ;
                            OItoUpdate.Support_Start_Date__c = OI.Order.Actual_Order_Ship_Date__c ;
                            OItoUpdate.Support_End_Date__c = OI.Order.Actual_Order_Ship_Date__c.addMonths(6)-1;
                            orderItemToUpdate.put(OI.id,OItoUpdate);
                        }
                        
                    }*/
                    if(task.Task_Type__c != null){
                        psTaskToInsert.add(task);
                    }
                }
            }
        if(!psTaskToInsert.isEmpty()){
            System.debug('psTaskToInsert'+psTaskToInsert.size());
            insert psTaskToInsert;
        }
    }
    global void finish(Database.BatchableContext BC){}
}