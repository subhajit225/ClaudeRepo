public without sharing class PortalUserHelper {

    public static Map<String, String> mapContactToOrder = new Map<String, String>();

    public static void processOrdersForProvisioning(Map<Id, Order> newOrders, Map<Id, Order> oldOrders, Boolean updatedOrder) {
        
        system.debug('Inside PortalUserHelper.processOrdersForProvisioning : newOrders.size() :: ' + newOrders.size());
        
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> oppPrimaryContact = new Map<Id, Id>();
        
        if(!newOrders.values().isEmpty()) {
            for (Order newOrder : newOrders.values()) {
                
                boolean processUser = newOrder.Order_Status__c == 'Shipped' && updatedOrder == false ? true : (newOrder.Order_Status__c == 'Shipped' && updatedOrder == true && oldOrders.get(newOrder.Id).Order_Status__c != 'Shipped') ? true : false;
                system.debug('Inside PortalUserHelper.processOrdersForProvisioning : processUser :: ' + processUser );
                
                if(newOrder.OpportunityId != null && processUser) {
                    oppIds.add(newOrder.OpportunityId);
                    oppPrimaryContact.put(newOrder.Opportunityid, newOrder.Opportunity.Initial_Contacts_Name__c);
                    system.debug('Inside PortalUserHelper.processOrdersForProvisioning : newOrder.Opportunityid :: '+ newOrder.Opportunityid);
                    system.debug('Inside PortalUserHelper.processOrdersForProvisioning : newOrder.Opportunity.Initial_Contacts_Name__c :: '+ newOrder.Opportunity.Initial_Contacts_Name__c);
                }
                else if(newOrder.POC_Opportunity__c != null && processUser) {
                    oppIds.add(newOrder.POC_Opportunity__c);
                    oppPrimaryContact.put(newOrder.POC_Opportunity__c, newOrder.POC_Opportunity__r.Initial_Contacts_Name__c);
                    system.debug('Inside PortalUserHelper.processOrdersForProvisioning : newOrder.Opportunityid :: '+ newOrder.POC_Opportunity__c);
                    system.debug('Inside PortalUserHelper.processOrdersForProvisioning : newOrder.Opportunity.Initial_Contacts_Name__c :: '+ newOrder.Opportunity.Initial_Contacts_Name__c);
                }
            }
            
            if(!oppIds.isEmpty()) {
                system.debug('Inside PortalUserHelper.processOrdersForProvisioning : oppIds.size() :: ' + oppIds.size());
                PortalUserHelper.opportunityOrders(oppIds, oppPrimaryContact);
            }
        }
    }
    
    public static void opportunityOrders (Set<Id> oppIds, Map<Id, Id> oppPrimaryContact) {
        
        system.debug('Inside PortalUserHelper.opportunityOrders : Label.CommunityProfileAutoProvision ::' + Label.CommunityProfileAutoProvision);
        List<OpportunityContactRole> oppConRoles = new list<OpportunityContactRole>();
        
        for(OpportunityContactRole ocr : [SELECT Id, OpportunityId, ContactID, isPrimary FROM OpportunityContactRole WHERE OpportunityId IN :oppIds AND isPrimary = TRUE]) {    
            
            if(!oppPrimaryContact.containskey(ocr.OpportunityId) 
               || (oppPrimaryContact.containskey(ocr.OpportunityId) && oppPrimaryContact.get(ocr.OpportunityId) == NULL) ) {
                   
                oppPrimaryContact.put(ocr.OpportunityId, ocr.ContactId);
            }
            
        }
        
        system.debug('Inside PortalUserHelper.opportunityOrders : oppIds.size() :: ' + oppIds.size());
        system.debug('Inside PortalUserHelper.opportunityOrders : oppPrimaryContact.size() :: ' + oppPrimaryContact.size());
        system.debug('Inside PortalUserHelper.opportunityOrders : oppPrimaryContact :: ' + oppPrimaryContact);

        List<Contact> contactToProvision = new List<Contact>();
        
        for(Id oId : oppIds) {
            
            system.debug('Inside PortalUserHelper.opportunityOrders : oppPrimaryContact.get(oId) :: ' + oppPrimaryContact.get(oId));
            
            if(oppPrimaryContact.containskey(oId) && oppPrimaryContact.get(oId) != NULL) {
                Contact tempContact = new Contact(Id = oppPrimaryContact.get(oId));
                boolean exists = checkPortalUser(tempContact);
                if(exists == false) { 
                    contactToProvision.add(tempContact);
                }
                system.debug('Inside PortalUserHelper.opportunityOrders : exists :: ' + exists);
            }
            
            if(!oppPrimaryContact.containskey(oId)) {
                system.debug('Inside PortalUserHelper.opportunityOrders : something went wrong ');
            }
            
        }
        
        system.debug('Inside PortalUserHelper.opportunityOrders : contactToProvision :: ' + contactToProvision.size());
        
        map<Id,Contact> conToProvision = new map<Id,Contact>();
        
        if(!contactToProvision.isEmpty() && contactToProvision.size() == 1 ){
            for(Contact c : contactToProvision){
                provisionPortalUser( (string) c.id, Label.CommunityProfileAutoProvision, false);
            }
        }
        //End Single size list
        
        if(!contactToProvision.isEmpty() && contactToProvision.size()>1 ){
            for(Contact c : contactToProvision) {
                conToProvision.put(c.Id, c);
            }
            
            if(!conToProvision.isEmpty() && conToProvision.size()>1 ) {
                
                BatchPortalUserProvision scriptBatch = new BatchPortalUserProvision();
                scriptBatch.conSet = conToProvision.keyset();
                Database.executeBatch(scriptBatch); 
            }
        }
    }
    
    public static boolean checkPortalUser(Contact objContact) {
        
        List<User> checkUsers = new List<User>();
        checkUsers = [SELECT Id, ContactId FROM User WHERE ContactId = :objContact.Id];
        
        system.debug('Inside PortalUserHelper.checkPortalUser : checkUsers :: ' + checkUsers);
        if(checkUsers.isEmpty()) {  
            return false; 
        } else { 
            return true; 
        }
        
    }
    
    //@future
    public static void provisionPortalUser(String objContact, String profileName, Boolean append){    
        
        Boolean retry = false;
        String conId = objContact;
        List<Contact> conDetails = [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Id = :conId];
        Map<Id, User> usersToInsert = new Map<Id, User>();
        List<User> usersToInsertList = new List<User>();
        List<Error_Logs__c> errorList = new List<Error_Logs__c>();

        string unameAppend = append == false ? '' : 'support';
        string error ='';
        integer errorCount = 0;
        integer successCount = 0;
        
        system.debug('Inside PortalUserHelper.provisionPortalUser : entered provisionPortalUser ' + objContact);
        if(objContact != null) {
            Profile pf = [SELECT Id, Name FROM Profile 
                          WHERE Name = :profileName LIMIT 1];   
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            ///SET TO TRUE WHEN READY
            dmo.EmailHeader.triggerUserEmail =  TriggerControl__c.getInstance('PortalUserCreation') != null && TriggerControl__c.getInstance('PortalUserCreation').SendEmail__c == true;   

            //Create user 
            User portalUser = new User(ContactId = conId, 
                                       UserName = unameAppend + conDetails[0].Email, 
                                       FirstName = conDetails[0].FirstName,
                                       LastName = conDetails[0].LastName, 
                                       Email = conDetails[0].Email,
                                       CommunityNickname = conDetails[0].LastName + '_' + Math.random(),
                                       ProfileId = pf.Id, 
                                       EmailEncodingKey = 'UTF-8',
                                       LanguageLocaleKey = 'en_US', 
                                       LocalesIdKey = 'en_US', 
                                       TimezonesIdKey = 'America/Los_Angeles',
                                       ProvisionType__c = 'Order Automation');  //added ProvisionType__c for CS21-51 - Veera                  
            
            if(conDetails[0].FirstName != null)
                portalUser.Alias = String.valueof(conDetails[0].FirstName.substring(0,1) + conDetails[0].LastName.substring(0,1) + string.valueof(Math.random()).substring(0,6));
            else
                portalUser.Alias = String.valueof(conDetails[0].LastName.substring(0,2) + string.valueof(Math.random()).substring(0,6));
             
            portalUser.setOptions(dmo);
                                      
            usersToInsertList.add(portalUser);
        }
        
        try { 
            if(! usersToInsertList.isempty()) { 
                insert usersToInsertList;
            }
        } catch(Exception ex) {
            
            if(ex.getMessage().contains('DUPLICATE_USERNAME')) {
                retry = true;
            }
            system.debug('Inside PortalUserHelper.provisionPortalUser : ex :: ' + ex);
            
            error =  ' Error creating portal user for ' + conDetails[0].Email + ' id: '+objContact ;
                            error += ' \n'+ex+ '\n\n';
            
            system.debug('### retry '+ retry);
            string toAddressLabel = Label.PortalProvisionErrors;
            if(retry == false) { 
                Util.sendEmail(Label.PortalProvisionErrors, null, null, error, 'Rubrik Portal Registration Error 1', true);    
                errorList.add( createErrorLog(error, null) );
            }
        } finally {
            
            system.debug('Inside PortalUserHelper.provisionPortalUser : retry in finally :: '+ retry);
            if(retry == true) {
                
                usersToInsertList[0].username = 'support.' + conDetails[0].Email;
                
                system.debug('Inside PortalUserHelper.provisionPortalUser : usersToInsertList :: ' + usersToInsertList);
                
                //add DB Save result and send email of issue.
                List<Database.SaveResult> srList = new List<Database.SaveResult>{}; 
                    if(! usersToInsertList.isempty()) srList = Database.insert(usersToInsertList, false);
                
                system.debug('Inside PortalUserHelper.provisionPortalUser : srList :: ' + srList.size() + ' :: usersToInsertList ::: ' + usersToInsertList.size() );
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        successCount = 1;
                        System.debug('Inside PortalUserHelper.provisionPortalUser : Successfully inserted Portal User after retry 2 :: ' + sr.getId());
                    }
                    else {
                        error = ' Error creating portal user for ' + conDetails[0].Email + ' id: '+objContact ;
                        
                        for(Database.Error err : sr.getErrors()) {
                            
                            error += ' \n' + err.getStatusCode();
                            error += ' \n' + err.getMessage() + '\n\n';
                            
                            System.debug('Inside PortalUserHelper.provisionPortalUser : The following error has occurred.');                    
                            System.debug('Inside PortalUserHelper.provisionPortalUser : ' + err.getStatusCode() + ': ' + err.getMessage());
                            
                        }
                    }
                }
                
                if(((error != null && error.length() > 0) || srList.size() > 0 && errorCount > 0) && successCount != 1) 
                    Util.sendEmail(Label.PortalProvisionErrors,null,  null, error, 'Rubrik Portal Registration Error ', true);    
                
            }
        }
    }
    
    private static Error_Logs__c createErrorLog(String error, Id orderId) {
        Error_Logs__c el = new Error_Logs__c(
            Error_Type__c = 'Portal Provision Error',
            Error_Message__c = 'Portal Provision Error:' + error ,
            Related_Order__c = orderId
        );
        return el;
    }
    
}