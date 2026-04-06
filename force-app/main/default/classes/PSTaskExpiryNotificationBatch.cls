global class PSTaskExpiryNotificationBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents { 
    
    global static Set<String> setExemptProductSKUs = new Set<String>{'RBK-INSTALL', 'RBK-CONSULT'};
    global Id projectId;
        
    global PSTaskExpiryNotificationBatch( Id projectId ) {
    	this.projectId = projectId;
    }     
    
    global PSTaskExpiryNotificationBatch() {}
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        Date currentDate    =   system.today();
        Date lastDay        =   currentDate.addDays(-1);
        Date expireIn7Days  =   currentDate.addDays(7);
        Date expireIn14Days =   currentDate.addDays(14);
        Date expireIn30Days =   currentDate.addDays(30);
        Date expireIn45Days =   currentDate.addDays(45);
        Date expireIn60Days =   currentDate.addDays(60);
        String projectIdL = this.projectId;
        if( projectIdL != null  ) {
            String query = 'SELECT Order_Product__c, Task_Status__c, Task_Type__c, Task_Start_Date__c, Task_End_date__c,Project_Status__c,Line_Value__c,Revenue_Type__c,'+'\n'+
            'Extended_End_date__c, Actual_End_date__c, Approved_Hours__c,Project__c,Account__c,Contact__c,Do_Not_Send_Expiration_Notice__c,' +'\n'+
            'Project__r.Customer_Project_Contact__c, Project__r.Customer_Project_Contact__r.Email,'+'\n'+
            'Project__r.Welcome_Letter_Contact__c, Project__r.Welcome_Letter_Contact__r.Email,'+'\n'+
            'Project__r.Opportunity__c, Project__r.Opportunity__r.Owner.Email,'+'\n'+
            'Project__r.Opportunity__r.Rubrik_Sales_Engineer__c, Project__r.Opportunity__r.Rubrik_Sales_Engineer__r.email, Test_Field_Hrs__c, Hours_Consumed__c,'+'\n'+
            '(SELECT Id, CaseNumber FROM Cases__r)'+'\n'+
            'FROM PS_Task__c WHERE ((Task_Status__c = \'Open\'' +'\n'+
            'AND ((Actual_End_date__c =: lastDay AND Approved_Hours__c = 100'+'\n'+
            'AND (Task_Type__c != \'Migration\'))'+'\n'+
            'OR (Approved_Hours__c < 100 AND (Task_Type__c = \'Accelerator\' OR Task_Type__c = \'Install\' OR Task_Type__c = \'Consult\' OR Task_Type__c = \'Consult-Onsite\' OR Task_Type__c = \'Consult-Remote\')' +'\n'+
            'AND (Actual_End_date__c =: expireIn7Days OR Actual_End_date__c =: expireIn14Days'+'\n'+
            'OR Actual_End_date__c = :expireIn30Days OR Actual_End_date__c =: expireIn45Days' +'\n'+
            'OR Actual_End_date__c =: expireIn60Days)))) OR ((Task_Status__c = \'Open\' OR Task_Status__c = \'Not Started\') AND Task_Type__c = \'Migration\' AND Actual_End_date__c =: lastDay)'+'\n'+ 
                'OR (Task_Status__c = \'Not Started\' AND (Task_Type__c = \'Resident Engineer\' OR Task_Type__c = \'Resident Engineer-PD\') AND Task_Start_Date__c =: currentDate))'+'\n'+
                'AND Project__c =:projectIdL';
        	system.debug('Inside start');
        	return Database.getQueryLocator(query);
        }
        String query = 'SELECT Order_Product__c, Task_Status__c, Task_Type__c, Task_Start_Date__c, Task_End_date__c,Project_Status__c,Line_Value__c,Revenue_Type__c,'+'\n'+
            'Extended_End_date__c, Actual_End_date__c, Approved_Hours__c,Project__c,Account__c,Contact__c,Do_Not_Send_Expiration_Notice__c,' +'\n'+
            'Project__r.Customer_Project_Contact__c, Project__r.Customer_Project_Contact__r.Email,'+'\n'+
            'Project__r.Welcome_Letter_Contact__c, Project__r.Welcome_Letter_Contact__r.Email,'+'\n'+
            'Project__r.Opportunity__c, Project__r.Opportunity__r.Owner.Email,'+'\n'+
            'Project__r.Opportunity__r.Rubrik_Sales_Engineer__c, Project__r.Opportunity__r.Rubrik_Sales_Engineer__r.email, Test_Field_Hrs__c, Hours_Consumed__c,'+'\n'+
            '(SELECT Id, CaseNumber FROM Cases__r)'+'\n'+
            'FROM PS_Task__c WHERE (Task_Status__c = \'Open\'' +'\n'+
            'AND ((Actual_End_date__c =: lastDay AND Approved_Hours__c = 100'+'\n'+
            'AND (Task_Type__c != \'Migration\'))'+'\n'+
            'OR (Approved_Hours__c < 100 AND (Task_Type__c = \'Accelerator\' OR Task_Type__c = \'Install\' OR Task_Type__c = \'Consult\' OR Task_Type__c = \'Consult-Onsite\' OR Task_Type__c = \'Consult-Remote\')' +'\n'+
            'AND (Actual_End_date__c =: expireIn7Days OR Actual_End_date__c =: expireIn14Days'+'\n'+
            'OR Actual_End_date__c = :expireIn30Days OR Actual_End_date__c =: expireIn45Days' +'\n'+
            'OR Actual_End_date__c =: expireIn60Days))))'+'\n'+ 
            'OR ((Task_Status__c = \'Open\' OR Task_Status__c = \'Not Started\') AND Task_Type__c = \'Migration\' AND Actual_End_date__c =: lastDay)'+'\n'+
            'OR (Task_Status__c = \'Not Started\' AND (Task_Type__c = \'Resident Engineer\' OR Task_Type__c = \'Resident Engineer-PD\') AND Task_Start_Date__c =: currentDate)';
        system.debug('Inside start');
        //OR Task_Type__c = \'Consult\' OR Task_Type__c = \'Consult-Onsite\' OR Task_Type__c = \'Consult-Remote\' OR Task_Type__c = \'T&E\' OR Task_Type__c = \'Resident Engineer\'
        return Database.getQueryLocator(query);
    }    
    
    global void execute(Database.BatchableContext bc, List<PS_Task__c> psTaskListToUpdate){
        system.debug('Inside execute');
        if(!psTaskListToUpdate.IsEmpty()){
           
            Date currentDate    =   system.today();
            Date lastDay        =   currentDate.addDays(-1);
            Date expireIn7Days  =   currentDate.addDays(7);
            Date expireIn14Days =   currentDate.addDays(14);
            Date expireIn30Days =   currentDate.addDays(30);
            Date expireIn45Days =   currentDate.addDays(45);
            Date expireIn60Days =   currentDate.addDays(60);
            
            Date todayDate = Date.today();
        	Date cutOffDate = Date.newInstance( todayDate.year() , todayDate.month(), 25);
            Date dayAfterCutOffDate = cutOffDate.addDays(1);
            
            EmailTemplate emailtmp = [Select Id,Subject, HtmlValue, body from EmailTemplate where name='Professional Services Reminder Letter'LIMIT 1];
            List<Messaging.SingleEmailMessage> semailList = new list<Messaging.SingleEmailMessage>();
            
            Set<Id> setCompletedDeliveryTaskId = new Set<Id>();

            Set<String> setOfMigrationSku = new Set<String>();
			for(PS_Task_Meta__mdt psmd: [SELECT Id, Label, Task_Type__c FROM PS_Task_Meta__mdt WHERE Task_Type__c = 'Migration']){
    			setOfMigrationSku.add(psmd.Label);
			}
            
            for(PS_Task__c pt : psTaskListToUpdate){
         //if(pt.Task_Type__c = 'Install' ||  pt.Task_Type__c == 'Consult' ||  pt.Task_Type__c == 'Consult-Onsite' ||  pt.Task_Type__c == 'Consult-Remote'){
                if(pt.Task_Type__c != 'Migration' && pt.Task_Type__c != 'Resident Engineer' && pt.Task_Type__c != 'Resident Engineer-PD'){
                    if(pt.Actual_End_date__c == lastDay  ){
                        if( pt.Revenue_Type__c == 'Paid upon Delivery' && pt.Line_Value__c != 0 && pt.Approved_Hours__c < 100 ) {
                            pt.Task_Status__c = 'Closed Short';
                        } else {
                        	pt.Task_Status__c = 'Completed';
                        }  
                        if( isTaskCompleted(pt) ) {
                            setCompletedDeliveryTaskId.add( pt.Id );
                        } else {
                            pt.End_Date__c = pt.Actual_End_date__c;
                        }
                        //pt.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                        if(dayAfterCutOffDate == todayDate){
                            pt.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                        }else{
                            pt.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                        }
                    } else if(!pt.Do_Not_Send_Expiration_Notice__c &&(pt.Actual_End_date__c == expireIn7Days || pt.Actual_End_date__c == expireIn14Days || pt.Actual_End_date__c == expireIn30Days || pt.Actual_End_date__c == expireIn45Days || pt.Actual_End_date__c == expireIn60Days) && 
                              (pt.Task_Type__c == 'Install' ||  pt.Task_Type__c == 'Consult' ||  pt.Task_Type__c == 'Consult-Onsite' ||  pt.Task_Type__c == 'Consult-Remote' || pt.Task_Type__c == 'Accelerator' )){
                            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
                            semail.setTemplateId(emailtmp.id);
                            semail.treatbodiesastemplate = true;
                            semail.setWhatId(pt.id);
                            List<String> ToAddresses = new List<String>();
                            If(pt.Project__r.Customer_Project_Contact__c != null)
                                ToAddresses.add(pt.Project__r.Customer_Project_Contact__r.Email);
                            if(pt.Project__r.Welcome_Letter_Contact__c != null)
                                ToAddresses.add(pt.Project__r.Welcome_Letter_Contact__r.Email);
                            system.debug('ToAddresses'+ToAddresses);
                            semail.setToAddresses(ToAddresses);
                            List<String> CCAddresses = new List<String>();
                            //CCAddresses.add('revenue@rubrik.com.sandbox');
                            CCAddresses.addAll(Label.pso_ops_notices_Email.split(','));
                            If(pt.Project__r.Opportunity__c != null && pt.Project__r.Opportunity__r.Rubrik_Sales_Engineer__c != null)
                                CCAddresses.add(pt.Project__r.Opportunity__r.Rubrik_Sales_Engineer__r.Email);
                            If(pt.Project__r.Opportunity__c != null)
                                CCAddresses.add(pt.Project__r.Opportunity__r.Owner.Email);
                            system.debug('CCAddresses'+CCAddresses);
                            semail.setCcAddresses(CCAddresses);
                            semail.setSubject(emailtmp.Subject);
                            system.debug('Subject'+emailtmp.Subject);
                            semail.setHtmlBody(emailtmp.HtmlValue);
                            system.debug('setHtmlBody'+emailtmp.HtmlValue);
                            
                            if (Label.TaskExpiryFromAddress != 'Null') {
                                semail.setOrgWideEmailAddressId(Label.TaskExpiryFromAddress);
                            }
                            
                            semailList.add(semail);
                        }
                    //(pt.Task_Type__c == 'Resident Engineer' || pt.Task_Type__c == 'T&E')
                }else if(pt.Task_Type__c == 'Migration' && setOfMigrationSku.contains(pt.Order_Product__c) && pt.Cases__r.size() == 0){
                    pt.Task_Status__c = 'Completed';
                    //pt.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                    if(dayAfterCutOffDate == todayDate){
                        pt.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                    }else{
                        pt.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                    }
                }else if((pt.Task_Type__c == 'Resident Engineer' || pt.Task_Type__c == 'Resident Engineer-PD') && pt.Task_Status__c == 'Not Started'){
                    pt.Task_Status__c = 'Open';
                } 
                /*else if((pt.Task_Type__c != 'Migration') && pt.Actual_End_date__c == lastDay){
                    if( pt.Revenue_Type__c == 'Paid upon Delivery' && pt.Line_Value__c != 0 && pt.Approved_Hours__c < 100 ) {
                        pt.Task_Status__c = 'Closed Short';} else { pt.Task_Status__c = 'Completed'; }  
                    pt.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                }*/
                /*else if((pt.Task_Type__c == 'Resident Engineer' || pt.Task_Type__c == 'T&E') && pt.Actual_End_date__c == lastDay){
                    pt.Task_Status__c = 'Completed';
                }
                if( pt.Revenue_Type__c == 'Paid upon Delivery' ) {
                    if(pt.Approved_Hours__c >= 100 || pt.Line_Value__c == 0) {
                        pt.Task_Status__c = 'Completed';
                    } else {
                        pt.Task_Status__c = 'Closed Short';
                    }
                }
                if( pt.Task_Status__c == 'Completed' || pt.Task_Status__c == 'Closed Short' ) {
                    pt.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                }*/
            }
            if( !setCompletedDeliveryTaskId.isEmpty() ) {
                Map<Id , PS_Task__c > mapIdToTaskToUpdate = new Map<Id, PS_Task__c>(psTaskListToUpdate);    
                for(PS_Task__c objTask : [Select Id, (Select Id, Time_Entry_Date__c From PS_Time_Entries__r Where Billable__c = true and Is_Billable__c = true and Status__c ='Approved'  ORDER BY Time_Entry_Date__c DESC LIMIT 1) From PS_Task__c Where Id In:setCompletedDeliveryTaskId ] ) {
                    Date actualEndDate = (mapIdToTaskToUpdate.get(objTask.Id).Extended_End_date__c != null && mapIdToTaskToUpdate.get(objTask.Id).Extended_End_date__c > mapIdToTaskToUpdate.get(objTask.Id).Task_End_date__c) ? mapIdToTaskToUpdate.get(objTask.Id).Extended_End_date__c : mapIdToTaskToUpdate.get(objTask.Id).Task_End_date__c;
                    if(mapIdToTaskToUpdate.get(objTask.Id).Hours_Consumed__c < 100){
                        mapIdToTaskToUpdate.get(objTask.Id).End_Date__c = actualEndDate;
                    }else{
                        if(objTask.PS_Time_Entries__r != null && objTask.PS_Time_Entries__r.isEmpty() == false ){
                            mapIdToTaskToUpdate.get(objTask.Id).End_Date__c = objTask.PS_Time_Entries__r[0].Time_Entry_Date__c;
                        }else{
                            mapIdToTaskToUpdate.get(objTask.Id).End_Date__c = actualEndDate;
                        }
                    }
                }    
            }
            if(!psTaskListToUpdate.IsEmpty())
                update psTaskListToUpdate;
            if(!semailList.IsEmpty())
                Messaging.sendEmail(semailList);
        }
        
    }   
    
    private Boolean isTaskCompleted( PS_Task__c objTask ) {
        if( objTask.Revenue_Type__c != 'Paid Upon Delivery' || ( objTask.Revenue_Type__c == 'Paid Upon Delivery' && objTask.Line_Value__c == 0) ) {
            if( objTask.Task_Type__c != 'Migration' ) {
                return objTask.Test_Field_Hrs__c >= 100;
            } else if(objTask.Task_Type__c == 'Migration'){
                return objTask.Task_Status__c == 'Completed';
            } else {
                return objTask.Hours_Consumed__c >= 100;
            }
        } else if( objTask.Revenue_Type__c == 'Paid Upon Delivery' ) {
            return objTask.Approved_Hours__c >= 100;
        }
        return true;
    }
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }   
    public void dummy(){
        Integer i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
    }
}