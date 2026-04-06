public with sharing class TaskObjectTriggerHelper{
    
    static Id channelActivityRTId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Channel Activity').getRecordTypeId();
	static Id cseActivityRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('CSE_Activity').getRecordTypeId(); //PRIT26-633
       // Sprint4MKT24Deployment V2
    public static void resetFieldsValue(List<Task> newList, Map<ID, Task> oldMap){
        UserRole userRoleObj;
        if(oldMap == null && UserInfo.getUserRoleId() != null){
            userRoleObj = [Select Name from UserRole where ID = :UserInfo.getUserRoleId()];
        }
        for(Task taskObj : newList) {
            if(taskObj.Type != null && taskObj.Type != taskObj.Activity_Type__c){
                taskObj.Activity_Type__c = taskObj.Type;
            }
            if(userRoleObj != null && taskObj.CreatedByRole__c == null){//Sales Operations - Stamp Task Creator Role  
                taskObj.CreatedByRole__c = userRoleObj.Name;
            }
            if(taskObj.Status != 'Completed'){//Update Task to Complete
                taskObj.Status = 'Completed';
            }
        }
    }
    public static void updateBundleFeaturesForPolarisTasks (List<Task> newList){
    //List<Task> taskList, Map<Id, Id> taskOrderIds) {
        Id polarisTaskRTId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();

        List<Task> polarisFullfillmentOrderTaskList = new List<Task>();
        Map<Id, Id> taskOrderIds = new Map<Id, Id>();
        for(Task tsk : newList) {
            if(tsk.RecordTypeId == polarisTaskRTId && (!String.isBlank(tsk.WhatId))) {
                polarisFullfillmentOrderTaskList.add(tsk);
                if(!String.isBlank(tsk.WhatId) && !taskOrderIds.containsKey(tsk.Id))
                    taskOrderIds.put(tsk.Id, tsk.WhatId);
            }
        }
        if(polarisFullfillmentOrderTaskList.size() > 0) {
            updateInfoOnPolarisTasks (polarisFullfillmentOrderTaskList, taskOrderIds);
        }
    }    
    //SAL-709
    private static void updateInfoOnPolarisTasks (List<Task> taskList, Map<Id, Id> taskOrderIds) {

        Map<Id, Set<Id>> orderIdProductMap = new Map<Id, Set<Id>>();
        Map<Id, String> productBundleFeaturesMap = new Map<Id, String>();
        Map<Id, String> productIdNameMap = new Map<Id, String>();
        for(OrderItem oi: [Select Id, Product2Id, Product2.Name, Product2.Bundle_Features__c, OrderId from OrderItem where OrderId in :taskOrderIds.values()]) {
            if(orderIdProductMap.containsKey(oi.OrderId)) {
                Set<Id> productIds = orderIdProductMap.get(oi.OrderId);
                if(oi.Product2Id != null && oi.Product2.Bundle_Features__c != null){
                    productIds.add(oi.Product2Id);
                    String bundleFeatures = String.join(oi.Product2.Bundle_Features__c.split(';'), ',');
                    productBundleFeaturesMap.put(oi.Product2Id, bundleFeatures);
                    productIdNameMap.put(oi.Product2Id, oi.Product2.Name);
                }
            }else{
                Set<Id> productIds = new Set<Id>();
                if(oi.Product2Id != null && oi.Product2.Bundle_Features__c != null){
                    productIds.add(oi.Product2Id);
                    String bundleFeatures = String.join(oi.Product2.Bundle_Features__c.split(';'), ',');
                    productBundleFeaturesMap.put(oi.Product2Id, bundleFeatures);
                    productIdNameMap.put(oi.Product2Id, oi.Product2.Name);
                }
                orderIdProductMap.put(oi.OrderId, productIds);
            }
        }
        setBundleFeaturesForPolarisTasks(taskList, orderIdProductMap, productBundleFeaturesMap, productIdNameMap);
    }

    //SAL-709
    private static void setBundleFeaturesForPolarisTasks (List<Task> taskList, Map<Id, Set<Id>> orderIdProductMap, Map<Id, String> productBundleFeaturesMap, Map<Id, String> productIdNameMap) {
        for(Task taskObj : taskList) {           
            if(orderIdProductMap.containsKey(taskObj.WhatId)) {
                Set<Id> productIds = orderIdProductMap.get(taskObj.WhatId);
                String productName = '';
                String bundleFeatures = '';
                for(Id productId: productIds){
                    productName += productIdNameMap.get(productId) + ';';
                    bundleFeatures += productBundleFeaturesMap.get(productId) + ';';
                }
                taskObj.Product_With_Bundle_Features__c = productName;
                taskObj.Bundle_Features_for_Polaris_Task__c = bundleFeatures;
            }
        }
    }


   private static void initializeMaps(List<Task> newList, Map<Id, Lead> leadMap, Map<Id, Contact> contactMap, Map<Id, List<Deal_Registration__c>> leadIdDealRegMap){
        Set<ID> leadIdSet = new Set<ID>();
        Set<ID> contactIdSet = new Set<ID>();
        for(Task taskObj : newList) {
            if(taskObj.WhoId != null ){
                if(taskObj.WhoId!= null && string.valueOf(taskObj.WhoId).startsWithIgnoreCase('00Q')) {
                    leadIdSet.add(taskObj.WhoId);
                }
                if(taskObj.WhoId!= null && string.valueOf(taskObj.WhoId).startsWithIgnoreCase('003')){
                    contactIdSet.add(taskObj.WhoId);
                }
            }
        }
        if(!leadIdSet.isEmpty()) {
            if(leadIdDealRegMap != null){
                List<Deal_Registration__c> dealRegList = [SELECT id, Deal_Registration_Status__c,Lead__c, Primary__c from Deal_Registration__c where Lead__c in :leadIdSet];
                for(Deal_Registration__c deal : dealRegList) {
                    if(!leadIdDealRegMap.containsKey(deal.Lead__c)) {
                        leadIdDealRegMap.put(deal.Lead__c, new List<Deal_Registration__c>());
                    } 
                    leadIdDealRegMap.get(deal.Lead__c).add(deal);
                }
            }
            List<Lead> leadList = [SELECT Id, Deal_Reg_Approval_Status__c, Attempts_All_Time__c, Most_Recent_Activity_Date__c, Touches_since_MQL__c, Last_MQL_Date__c,
            (SELECT Id, CreatedDate,Type,Activity_Type__c FROM Tasks ORDER BY CreatedDate DESC)  from Lead where Id IN :leadIdSet];
            leadMap.putAll(leadList);
        }
        if(!contactIdSet.isEmpty() && contactMap != null) {
            List<Contact> contactList = [SELECT Id, Attempts_All_Time__c, Most_Recent_Activity_Date__c, Touches_since_MQL__c, Last_MQL_Date__c,
                    (SELECT Id, CreatedDate,Type,Activity_Type__c FROM Tasks ORDER BY CreatedDate DESC) 
                FROM Contact WHERE Id IN :contactIdSet];
            contactMap.putAll(contactList);
        }
    }

     public static void updateLeadAndContacts(Map<ID, Task> newMap,Boolean isInsert){
        Map<Id, Lead> editableLeadMap = new Map<Id, Lead>();
        Map<Id, Contact> editableContactMap = new Map<Id, Contact>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        initializeMaps(newMap.values(), leadMap, contactMap, null);
        List<task> insideSalesLedMeetingTaskList = new List<task>();
        List<User> rmaRequesterUserList = [Select ID from User WHERE Name = 'RMA Requester'];
        for(Task taskObj : newMap.values()){
            System.debug(taskObj +'\n~~~~Created By: ' + taskObj.CreatedById);
            if((taskObj.Subject.startsWith('Email:') || taskObj.Subject.startsWith('Call:')) && taskObj.WhoId != null && !rmaRequesterUserList.isEmpty() && taskObj.CreatedById != rmaRequesterUserList[0].id){
                insideSalesLedMeetingTaskList.add(taskObj);
            }
            Lead leadObj = leadMap.get(taskObj.WhoId);
            Contact contactObj = contactMap.get(taskObj.WhoId);
            if(leadObj != null){
                if(taskObj.Subject == 'PID Meeting' && taskObj.WhoId != null && isInsert) {
                    leadObj.skipValidationRules__c=true;
                    leadObj.PID_Meeting_Task_Id__c=taskObj.Id;
                }
                integer touchesAfterMql = 0; 
                integer touchesAlltime = 0;
                for(Task ts : leadObj.Tasks){
                  if(( ts.Activity_Type__c=='Call' || ts.Activity_Type__c=='Email'  || ts.Type=='Call' || ts.Type=='Email' )) {    
                    if(leadObj.Last_MQL_Date__c != null && Date.valueOf(ts.CreatedDate) >= leadObj.Last_MQL_Date__c){
                            touchesAfterMql += 1;
                    }
                    if(ts.CreatedDate > System.Today().addDays(-60)){
                        touchesAlltime += 1;
                    }
                  }
                }                    
                leadObj.Attempts_All_Time__c = touchesAlltime;
                leadObj.Touches_since_MQL__c = touchesAfterMql;
                if(isInsert)
                leadObj.Most_Recent_Activity_Date__c = Date.today();
                editableLeadMap.put(leadObj.id, leadObj);
            }else if(contactObj != null) {                    
                system.debug('contactObj  ---> '+contactObj );                    
                integer touchesAfterMql = 0; 
                integer touchesAlltime = 0; 
                for(Task ts : contactObj.Tasks){
                  if(( ts.Activity_Type__c=='Call' || ts.Activity_Type__c=='Email'  || ts.Type=='Call' || ts.Type=='Email' )) {   
                    if(contactObj.Last_MQL_Date__c != null && Date.valueOf(ts.CreatedDate) >= contactObj.Last_MQL_Date__c){
                        touchesAfterMql += 1;
                    }
                    if(ts.CreatedDate > System.Today().addDays(-60)){
                        touchesAlltime += 1;
                    }
                  }
                }
                contactObj.Attempts_All_Time__c = touchesAlltime;
                contactObj.Touches_since_MQL__c = touchesAfterMql;
                if(isInsert)
                contactObj.Most_Recent_Activity_Date__c = Date.today();
                editableContactMap.put(contactObj.id, contactObj);
            }
        }
        if(!editableLeadMap.isEmpty()){
            flowControll.DealRegistrationTrigger=false;
            update editableLeadMap.values();
        }
        if(!editableContactMap.isEmpty()){
            update editableContactMap.values();
        }
        updateContactFollowUpDetails(insideSalesLedMeetingTaskList);
    }

    /* Commented as part of PRIT24-27 : START  
    public static void updateLeadAndDealRegistration(List<Task> newList, Map<ID, Task> oldMap){

        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        //Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Map<Id, List<Deal_Registration__c>> leadIdDealRegMap = new Map<Id, List<Deal_Registration__c>>();

        initializeMaps(newList, leadMap, null, leadIdDealRegMap);

        Map<Id, Deal_Registration__c> drMapToUpdate = new Map<Id, Deal_Registration__c>();
        Map<Id, Lead> editableLeadMap = new Map<Id, Lead>();
        for(Task tsk : newList){ 
            Task oldtsk = oldMap.get(tsk.id) ;
            Lead leadObj = leadMap.get(tsk.WhoId);
            List<Deal_Registration__c> drList = leadIdDealRegMap.get(tsk.WhoId);
            if(drList != null) {
                if(tsk.Post_Meeting_Status__c== 'Convert to Opportunity' && tsk.Post_Meeting_Status__c != oldtsk.Post_Meeting_Status__c){
                    // SF-342
                    Boolean isPrimaryDealRegFound = false;
                    for(Deal_Registration__c dealReg : drList) {                   
                        if(dealReg.Primary__c){
                            isPrimaryDealRegFound = true;
                            dealReg.Deal_Registration_Status__c = 'Approved';
                            dealReg.Approval_Timestamp__c = Datetime.now();
                        } else {
                            dealReg.Deal_Registration_Status__c = 'Rejected';
                        }
                        dealReg.skipValidation__c=true;
                        drMapToUpdate.put(dealReg.id, dealReg);
                    }
                    if(!isPrimaryDealRegFound){
                        tsk.addError('Please select primary Deal Registration on Lead to complete the task');
                    }
                    
                } else if(tsk.Post_Meeting_Status__c == 'Do Not Convert To Opportunity' && tsk.Post_Meeting_Status__c!=oldtsk.Post_Meeting_Status__c){
                    for(Deal_Registration__c dealReg : drList) {
                        if(dealReg.Primary__c){
                            dealReg.Deal_Registration_Status__c = 'Rejected';
                            dealReg.skipValidation__c=true;
                            drMapToUpdate.put(dealReg.id, dealReg);
                        }
                    }           
                }
            }
            if(leadObj != null) {
                leadObj.skipValidationRules__c=true;
                if(tsk.Post_Meeting_Status__c== 'Convert to Opportunity' && tsk.Post_Meeting_Status__c!=oldtsk.Post_Meeting_Status__c){
                    leadObj.Deal_Reg_Approval_Status__c = 'Approved';
                    leadObj.Deal_Reg_Submitted_Date__c = Datetime.now();
                    leadObj.Deal_Reg_Approval_Timestamp__c = Datetime.now();
                }else if(tsk.Post_Meeting_Status__c == 'Do Not Convert To Opportunity' && tsk.Post_Meeting_Status__c!=oldtsk.Post_Meeting_Status__c){
                    leadObj.Deal_Reg_Approval_Status__c = 'Rejected';
                }
                editableLeadMap.put(leadObj.id, leadObj);
            }
        }

        if(!drMapToUpdate.isEmpty()){
            flowControll.DealRegistrationTrigger=false;
            update drMapToUpdate.values();
        }

        if(!editableLeadMap.isEmpty()){
            update editableLeadMap.values();
        }
    }
    Commented as part of PRIT24-27 : END */
         // Added by PALAK
       //Removed As a part of PRODOPS25-340
       

    //SAL-135: Polaris Order fulfillment 
    //Check Order fields based on Task changes  
   
    
   
         public static void updateLeadContactDataUpdate(List<Task> newTasks, Map<id,task> oldTasks) {
        List<Lead> entitityObjLead = new List<Lead>();
        List<Contact> entitityObjContact = new List<Contact>();
        entitityObjLead = UpdateleadRecordData(newTasks,oldTasks);
        entitityObjContact=UpdatecontactRecordData(newTasks,oldTasks);
         system.debug('entitityObjLead>>'+entitityObjLead);
        system.debug('entitityObjLead>>'+entitityObjLead.size());
        system.debug('entitityObjContact>>'+entitityObjContact);
        system.debug('entitityObjContact>>'+entitityObjContact.size());
        if(entitityObjLead.size()>0){
         
            update entitityObjLead;
        }
        if(entitityObjContact.size()>0){
           
            update entitityObjContact;
        }
    }
    
   
    
    public static void updateLeadContactDataAfterInsert(List<Task> newTasks) {
        List<Lead> entitityObjLead = new List<Lead>();
        List<Contact> entitityObjContact = new List<Contact>();
        entitityObjLead = UpdateleadRecordDataOnInsert(newTasks);
        entitityObjContact=UpdateContactRecordDataOnInsert(newTasks);
         system.debug('entitityObjLead>>'+entitityObjLead);
        system.debug('entitityObjLead>>'+entitityObjLead.size());
        system.debug('entitityObjContact>>'+entitityObjContact);
        system.debug('entitityObjContact>>'+entitityObjContact.size());
        if(entitityObjLead.size()>0){
          
            update entitityObjLead;
        }
        if(entitityObjContact.size()>0){
         
            update entitityObjContact;
        }
    }
    
    
    public static List<Lead> UpdateleadRecordDataOnInsert(List<Task> newTasks){
        
        List<Lead> leadList = new List<Lead>();
        map<String,Lead> LeadMap = new Map<String,Lead>();
        set<String> leadIds = new set<String>();
        map<String,String> leadMapIds= new map<String,String>();
        
        for(task t: newTasks){
            if(t.WhoId !=null) {
             if(t.WhoId.getSObjectType() == Lead.sobjectType){
                if(t.Activity_Type__c=='Email' || t.Activity_Type__c=='Call'){
                    leadIds.add(t.WhoId);
            } 
          }
                
       }
     }
        if(leadIds.size()>0) {
              //Mkt23-419 Comment//
            List<Lead> LeadLst = [Select id,Name,Status from Lead where id IN:leadIds AND Status = 'Open'];
                for(Lead rsLed:LeadLst){
                    if(rsLed.Status!='Meeting Set') {
                        LeadMap.put(rsLed.id,rsLed);
                    }
                    
                }
        }
         for(task t: newTasks){
            if(t.WhoId !=null) {
             if(t.WhoId.getSObjectType() == Lead.sobjectType){
                 if(LeadMap.containskey(t.WhoId)) {
                     if(!leadMapIds.containsKey(t.WhoId)){
                       leadList.add(new Lead (Id=t.WhoId,Status='Working',Lead_Rejection_Reason__c=null));  
                     }
                        
                    leadMapIds.put(t.WhoId,t.WhoId);
                 }
                    
          }
         }
        }
        return leadList;
        
        
    }
    
    
    
     public static List<Lead> UpdateleadRecordData(List<Task> newTasks, Map<id,task> oldTasks){
        
        List<Lead> leadList = new List<Lead>();
        map<String,Lead> LeadMap = new Map<String,Lead>();
        set<String> leadIds = new set<String>();
         map<String,String> leadMapIds= new map<String,String>();
         
        
        for(task t: newTasks){
            if(t.WhoId !=null) {
             if(t.WhoId.getSObjectType() == Lead.sobjectType){
               
                if((oldTasks != null && oldTasks.get(t.id).SalesloftDisposition__c != t.SalesloftDisposition__c) && (t.SalesloftDisposition__c=='Working - Left VM' || t.SalesloftDisposition__c=='Working - Connected' || t.SalesloftDisposition__c=='Working - No Answer')) {
                     if(!leadMapIds.containsKey(t.WhoId)){ 
                        leadList.add(new Lead (Id=t.WhoId,Status='Working',Lead_Rejection_Reason__c=null));
                     }
                    
                      leadMapIds.put(t.WhoId,t.WhoId);
                }
                 
                 if((oldTasks != null && oldTasks.get(t.id).SalesloftDisposition__c != t.SalesloftDisposition__c) && (t.SalesloftDisposition__c=='NQ - No Potential' || t.SalesloftDisposition__c=='NQ - Partner/Reseller' || t.SalesloftDisposition__c =='NQ - Bad Title' || t.SalesloftDisposition__c == 'NQ - Bad Phone/Email')) 
                 {
                       
                     if(t.SalesloftDisposition__c=='NQ - No Potential') {
                          if(!leadMapIds.containsKey(t.WhoId)){
                            leadList.add(new Lead (Id=t.WhoId,Status='Non-Qualified',Lead_Rejection_Reason__c='Objection: Not a Priority'));
                          }
                     }
                            
                        
                     if(t.SalesloftDisposition__c=='NQ - Partner/Reseller'){
                         if(!leadMapIds.containsKey(t.WhoId)){
                          leadList.add(new Lead (Id=t.WhoId,Status='Non-Qualified',Lead_Rejection_Reason__c='Partner/Reseller/Disti'));
                         }
                     }
                        
                     
                     if(t.SalesloftDisposition__c=='NQ - Bad Title'){
                          if(!leadMapIds.containsKey(t.WhoId)){
                              leadList.add(new Lead (Id=t.WhoId,Status='Non-Qualified',Lead_Rejection_Reason__c='Wrong Person: Bad Title'));
                          }
                     }
                        
                     
                     if(t.SalesloftDisposition__c=='NQ - Bad Phone/Email') {
                           if(!leadMapIds.containsKey(t.WhoId)){
                             leadList.add(new Lead (Id=t.WhoId,Status='Non-Qualified',Lead_Rejection_Reason__c='No Contact Information'));
                           }
                     }
                        
                  
                     leadMapIds.put(t.WhoId,t.WhoId);
                }
                 
          }
                
       }
     }
        
        return leadList;
        
        
    }
    
     public static List<Contact> UpdatecontactRecordData(List<Task> newTasks, Map<id,task> oldTasks){
        
        List<Contact> ContactList = new List<Contact>();
         map<string,string> contactIDmap = new map<string,string>();
         Contact tempContact = new Contact();
         map<String,String> ContactLeadsIds= new map<String,String>();
         
        for(task t: newTasks){
            if(t.WhoId !=null) {
             if(t.WhoId.getSObjectType() == Contact.sobjectType){
              // tempContact.id =t.WhoId;
                if((oldTasks != null && oldTasks.get(t.id).SalesloftDisposition__c != t.SalesloftDisposition__c) && (t.SalesloftDisposition__c=='Working-Left VM' || t.SalesloftDisposition__c=='Working - Connected' || t.SalesloftDisposition__c=='Working - No Answer')) {
                         ContactList.add(new Contact (Id=t.WhoId,Contact_Status__c='Working',ContactRejectReason__c=null));
                    
                    
                        ContactLeadsIds.put(t.WhoId,t.WhoId);
                }
                 
                 if((oldTasks != null && oldTasks.get(t.id).SalesloftDisposition__c != t.SalesloftDisposition__c) && (t.SalesloftDisposition__c=='NQ - No Potential' || t.SalesloftDisposition__c=='NQ - Partner/Reseller' || t.SalesloftDisposition__c =='NQ - Bad Title' || t.SalesloftDisposition__c == 'NQ - Bad Phone/Email'))
                    {
                        if(t.SalesloftDisposition__c=='NQ - No Potential'){
                            if(!ContactLeadsIds.containsKey(t.WhoId)) {
                                ContactList.add(new Contact (Id=t.WhoId,Contact_Status__c='Non-Qualified',ContactRejectReason__c='Objection: Not a Priority'));
                            }
                             
                        }
                            
                        
                         if(t.SalesloftDisposition__c=='NQ - Partner/Reseller') {
                        
                              if(! ContactLeadsIds.containsKey(t.WhoId)) {
                               ContactList.add(new Contact (Id=t.WhoId,Contact_Status__c='Non-Qualified',ContactRejectReason__c='Partner/Reseller/Disti'));
                              }
                              
                        }
                            
                         if(t.SalesloftDisposition__c=='NQ - Bad Title'){
                            if(!ContactLeadsIds.containsKey(t.WhoId)) {
                              ContactList.add(new Contact (Id=t.WhoId,Contact_Status__c='Non-Qualified',ContactRejectReason__c='Wrong Person: Bad Title'));
                            }
                        }   
                         
                         if(t.SalesloftDisposition__c=='NQ - Bad Phone/Email'){
                             if(!ContactLeadsIds.containsKey(t.WhoId)) {
                              ContactList.add(new Contact (Id=t.WhoId,Contact_Status__c='Non-Qualified',ContactRejectReason__c='No Contact Information'));
                             }
                        } 
                     ContactLeadsIds.put(t.WhoId,t.WhoId);    
                }
                 
          }
                
       }
     }
        system.debug('ContactList>>'+ContactList);
        return ContactList;
        
        
    }
    
   
    
    
    public static List<Contact> UpdateContactRecordDataOnInsert(List<Task> newTasks){
        
        List<Contact> ConList = new List<Contact>();
        map<String,Contact> ConMap = new Map<String,Contact>();
        set<String> ContatcIds = new set<String>();
        map<string,string> contactMapIDs= new map<String,String>();
        for(task t: newTasks){
            if(t.WhoId!=null) {
                if(t.Activity_Type__c=='Email' || t.Activity_Type__c=='Call'){
                    if(t.WhoId.getSObjectType() == Contact.sobjectType){
                        ContatcIds.add(t.WhoId);
                    }
                }
                
            }
            
        }
        
        if(ContatcIds.size()>0) {
            //Mkt23-419 Comment//
            List<Contact> ContactLst = [Select id,Name,Contact_Status__c from Contact where id IN:ContatcIds AND Contact_Status__c = 'Open'];
                for(Contact rsCon:ContactLst){
                    if(rsCon.Contact_Status__c!='Meeting Set' && rsCon.Contact_Status__c!='Active Opportunity (System Use)' ) {
                        ConMap.put(rsCon.id,rsCon);
                    }
                }
        }
        for(task t: newTasks){
            if(t.WhoId!=null) {
                if(t.Activity_Type__c=='Email' || t.Activity_Type__c=='Call'){
                    if(t.WhoId.getSObjectType() == Contact.sobjectType){
                        if(ConMap.containskey(t.WhoId)) {
                            if(!contactMapIDs.containskey(t.WhoId)) {
                               ConList.add(new Contact(Id=t.WhoId,Contact_Status__c='Working',ContactRejectReason__c=null)); 
                            }
                          
                          contactMapIDs.put(t.WhoId,t.WhoId);  
                        }
                            
                    }
                }
            }
        }
        return ConList;
    }
    private static void updateContactFollowUpDetails (List<Task> tskList) {
        List<Contact> ContactList = new List<Contact>();

        for(Task TaskRec : tskList) {
            if(TaskRec.WhoId.getSObjectType() == Contact.sobjectType){
                contact conRec = new contact(id= TaskRec.WhoId , Last_Follow_Up_Activity_Date__c = Date.today(), Contact_Follow_Up_Status__c ='Follow up completed');
                ContactList.add(conRec);
            }
        }
        if(!ContactList.isEmpty()){
            List<Task> tasksToClose = new List<Task>();
            tasksToClose = [select id from task where WhoId IN: ContactList AND Subject= 'Follow up Request' ];
            for(Task taskRec : tasksToClose) { taskRec.Status = 'Completed'; }
            update tasksToClose; update ContactList;
            
        }
    }
     /**
     * @description Assign Territory and segment field values from Account.
     *
     * @param newList A list of inserted/updated Task records.
     * @param oldMap A map of Task IDs to their previous state, used for detecting changes.
     */
    public static void populateTerritoryAndSegment(List<Task> newList, Map<Id, Task> oldMap) {
        // Collect Account Ids from inserted/updated Tasks
        Set<Id> accIds = new Set<Id>();
        for (Task t : newList) {
           
            if (t.Partner_Name__c != null &&
                (oldMap == null || oldMap.get(t.Id).Partner_Name__c != t.Partner_Name__c) 
                && (t.RecordTypeId == channelActivityRTId || t.RecordTypeId == cseActivityRTId)) {
                accIds.add(t.Partner_Name__c);
            }
        }

        if (!accIds.isEmpty()) {
           
            // Query Accounts with required fields
            Map<Id, Account> accMap = new Map<Id, Account>(
                [SELECT Id, ETM_Territory__c, Account_Segment__c, ETM_Theatre__c
                 FROM Account
                 WHERE Id IN :accIds]
            ); //PRIT26-633
    
            // Populate fields on Tasks
            for (Task t : newList) {
                if (t.Partner_Name__c != null &&
                    accMap.containsKey(t.Partner_Name__c) ) {
                    Account acc = accMap.get(t.Partner_Name__c);
                    if(t.RecordTypeId == channelActivityRTId) { //PRIT26-633
                    	
                    t.Territory__c = acc.ETM_Territory__c;
                    t.Segment__c   = acc.Account_Segment__c;
                    }
                    t.ETM_Theatre__c = acc.ETM_Theatre__c; //PRIT26-633
                }
            }
        }
    }

      /**
     * @description Assign In.Out Activity to tasks
     *
     * @param newTasks A list of inserted/updated Task records.
     */
     public static void setInOutActivityType(List<Task> newTasks) 
     {

    if (newTasks == null || newTasks.isEmpty()) return;

    Set<Id> leadIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();
    Set<Id> ownerIds = new Set<Id>();

    for (Task t : newTasks) {
        if (t.WhoId != null) {
            if (t.WhoId.getSObjectType() == Lead.sObjectType) {
                leadIds.add(t.WhoId);
            } else if (t.WhoId.getSObjectType() == Contact.sObjectType) {
                contactIds.add(t.WhoId);
            }
        }
        if (t.OwnerId != null) {
            ownerIds.add(t.OwnerId);
        }
    }

    Map<Id, Lead> leadMap = leadIds.isEmpty()
        ? new Map<Id, Lead>()
        : new Map<Id, Lead>([
            SELECT Id, Last_MQL_Date__c, Campaign_Sourced_By__c
            FROM Lead
            WHERE Id IN :leadIds
        ]);

    Map<Id, Contact> contactMap = contactIds.isEmpty()
        ? new Map<Id, Contact>()
        : new Map<Id, Contact>([
            SELECT Id, Last_MQL_Date__c, Campaign_Sourced_By__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);

    Map<Id, User> insideSalesUsers = ownerIds.isEmpty()
        ? new Map<Id, User>()
        : new Map<Id, User>([
            SELECT Id
            FROM User
            WHERE Id IN :ownerIds
            AND Profile.Name = 'Rubrik Inside Sales'
        ]);

    Date today = Date.today();

    for (Task t : newTasks) {

        if (!insideSalesUsers.containsKey(t.OwnerId)) continue;
        if (t.Type != 'Email' && t.Type != 'Call') continue;

        Date lastMqlDate;
        String campaignSource;

        if (leadMap.containsKey(t.WhoId)) {
            lastMqlDate = leadMap.get(t.WhoId).Last_MQL_Date__c;
            campaignSource = leadMap.get(t.WhoId).Campaign_Sourced_By__c;
        } else if (contactMap.containsKey(t.WhoId)) {
            lastMqlDate = contactMap.get(t.WhoId).Last_MQL_Date__c;
            campaignSource = contactMap.get(t.WhoId).Campaign_Sourced_By__c;
        } else {
            continue;
        }

         if (lastMqlDate == null) {
            
                t.Outreach_In_Out_Activity__c = 'Outbound';
            
        }else{

        Integer daysDiff = lastMqlDate.daysBetween(today);

        if (daysDiff > 60) {
            t.Outreach_In_Out_Activity__c = 'Outbound';
        } else if (daysDiff <= 60 && campaignSource == 'Sales') {
            t.Outreach_In_Out_Activity__c = 'Outbound';
        } else if (daysDiff <= 60 && campaignSource == 'Marketing') {
            t.Outreach_In_Out_Activity__c = 'Inbound';
        }
        }
    }
}

   
}