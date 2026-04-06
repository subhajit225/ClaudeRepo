/**
* @Author : Ashwini G
* @Date : 8th Oct 2019
* @Description : CS-294, CS-401, CS-426 : Set the flag L3 Support Only on Account when one or more entitlements are provided for L3 Support Type skus and there are no other support type entitlements covered
* 
**/
global class AccountL3EntitlementsBatch implements Database.Batchable<sObject>,Database.Stateful{ 
    public List<String> errorsnewAccList = new List<String>();
    
   global Database.QueryLocator start(Database.BatchableContext BC){
    // Adding product__r.productcode SAL24-163 
        String query = 'Select Id,L3_Support_Only__c, (Select Id, Product__c, Product__r.SBQQ__SubscriptionType__c,Product__r.Category__c, Product__r.Support_Type__c,Product__r.ProductCode, AccountId, Status from Entitlements where Status = \'Active\' limit 199) From Account';
      return Database.getQueryLocator(query);
   }

    global void execute(Database.BatchableContext BC, List<Account> scope){
        try{
            List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
            system.debug(LoggingLevel.ERROR, '///CS-294 inside batch '+scope);
            for(Account s : scope){
                
                Account acc = new Account();
                acc.Id = (Id)s.Id;
                
                if(s.getSObjects('Entitlements') != null){
                    if(s.getSObjects('Entitlements').size()>0){
                        
                        
                        Integer countOfAllEntitlements = 0;
                        countOfAllEntitlements = s.getSObjects('Entitlements').size();
                        system.debug('///CS-294 account countOfAllEntitlements '+countOfAllEntitlements);
                        
                        Integer countOfL3Entitlements = 0;
                        Integer countOfNonL3Entitlements = 0;
                        system.debug('///CS-294 account countOfL3Entitlements '+countOfL3Entitlements);
                        
                        for(Entitlement entmt : (List<Entitlement>)s.getSObjects('Entitlements')){
                            // system.debug('///CS-294 account entmt '+entmt);				  
                            if(entmt.Product__r.Support_Type__c != null && (entmt.Product__r.Support_Type__c == 'L3' || entmt.Product__r.Support_Type__c == 'L3 Basic') && entmt.Product__r.SBQQ__SubscriptionType__c == 'Renewable'){ 
                                countOfL3Entitlements++;
                            }
                            else if(entmt.Product__r.Support_Type__c != null && entmt.Product__r.ProductCode !='RS-BT-RCDM-T' && (entmt.Product__r.Support_Type__c == 'Premium' || entmt.Product__r.Support_Type__c == 'PREM')){
                                countOfNonL3Entitlements++; 
                            }    // Adding entmt.product__r.productcode SAL24-163 
                            
                        }
                        system.debug('///CS-294 countOfAllEntitlements inside '+countOfAllEntitlements);
                        system.debug('///CS-294 countOfL3Entitlements inside '+countOfL3Entitlements);   
                        system.debug('///CS-294 countOfNonL3Entitlements inside '+countOfNonL3Entitlements); 
                        if(countOfL3Entitlements > 0 && countOfNonL3Entitlements == 0 ){
                            acc.L3_Support_Only__c = true;
                        } else{
                            acc.L3_Support_Only__c = false;
                        }   
                    } else{
                        acc.L3_Support_Only__c = false;
                    }
                } else{
                    acc.L3_Support_Only__c = false;
                }
                system.debug('///CS-294 accountsToUpdate '+accountsToUpdate);
                Schema.DescribeSObjectResult schemaAcc = Account.SObjectType.getDescribe();
                String accountPrefix = schemaAcc.getKeyPrefix();
                
                String prefixFromRecord;
                if(acc.Id != null){
                    prefixFromRecord = String.valueOf(acc.Id).substring(0,3);
                }
                
                // added s.L3_Support_Only__c!= acc.L3_Support_Only__c) to optimize the DML
                if(prefixFromRecord != null){
                    if(accountPrefix == prefixFromRecord && s.L3_Support_Only__c!= acc.L3_Support_Only__c){
                        accountsToUpdate.put(acc.Id, acc);
                    }
                }
            } 
            system.debug('///CS-294 accountsToUpdate.values '+accountsToUpdate.values()); 
            Map<Integer, String> mapOfIds = new Map<Integer, String>();
            Integer itr=0;
            if(accountsToUpdate!=null && accountsToUpdate.size()>0){
                List<Database.SaveResult> saveResults = Database.update(accountsToUpdate.values(), false);
                for (String ids : accountsToUpdate.keySet()) {
                    System.debug('ids ->'+ids );
                    mapOfIds.put(itr, ids);
                    itr++;
                }
                system.debug('mapOfIds-->'+mapOfIds);
                for (Integer i = 0; i < mapOfIds.size(); i++) {
                    Database.SaveResult sr = saveResults[i];
                    if(sr.isSuccess()){
                        System.debug('Success-'+mapOfIds.get(i));
                    }
                    if(!sr.isSuccess() || Test.isRunningTest()){
                        errorsnewAccList.add('<b>' + mapOfIds.get(i) + '</b> ::' + JSON.serialize(sr.getErrors()));
                        for(Database.Error errdata : sr.getErrors()) {
                            batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='AccountL3EntitlementsBatch',
                                                                       Failure_Job_ID__c=BC.getJobId(),Failure_Message__c=String.valueOf(errdata.getMessage()),
                                                                       Scenario__c='Account update for L3 support type has been failed',Service_Contract_Id__c=mapOfIds.get(i),Failure_Date__c=Date.today()));
                        }
                    }
                }
            } 
            try{
                if(!batchErrLogList.isEmpty()){
                    upsert batchErrLogList; 
                }
            }catch(exception e){
                system.debug('@@ Error Details '+e.getMessage());
            }
        }
        catch(exception e){
            system.debug('@@ Error Details '+e.getMessage());
            errorsnewAccList.add('</b> ::' + JSON.serialize(e.getMessage()));
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        System.debug('errorsnewAccList> '+errorsnewAccList);
        Messaging.SingleEmailMessage emailmessage = new Messaging.SingleEmailMessage();
        String strEmails = System.Label.ServiceContractRenewalForecastBatch_Emails;
        String strCPQAdmin = System.Label.CPQAdminEmailId;
        String[] toAddresses = !String.isBlank(strEmails) ? strEmails.split(',') : new List<String>{strCPQAdmin};
      // String[] toAddresses = new List<String>{'cpq_it_admin@rubrik.com','salesapps@rubrik.com'};//for testing
             System.debug('toAddresses> '+toAddresses);
        emailmessage.setToAddresses(toAddresses);
        emailmessage.setSubject('Account L3 Entitlements Batch Errors - ' + Date.today().format());
        
        String Message = 'Below is a list of the Accounts that failed to update <br/><br/>';
        if(!errorsnewAccList.isEmpty()) {
            Message += '<b>Accounts Updated YESTERDAY:</b> <br/>';
            for(String eachError : errorsnewAccList) {
                Message += eachError + '<br/>';
            }
            Message += '<br/>';
        }
        
        
        Message += '<br/>Thank you';
          System.debug('Message> '+Message);
        emailmessage.setHtmlBody(Message);
        if (!test.isRunningTest() && (!errorsnewAccList.isEmpty() )) {
            //Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailmessage });
            System.debug('Email is sent Successfully.');
        }
        
    }


}