/*
 * Class Name :- AccountServiceController
 * Author :- Shiva Sharma
 * Created-Date :- 13-06-2018
 * Description : This Controller is being refered while community login. If Account has service  or not
 * Params  : User, true, Source page method string
 // ********************Change Logs ******************************************************************************************************************************************************
 *
 * Modified By          Date        Description
 *
 *
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
public without sharing class AccountServiceController {    

    public static string checkService(User u , Boolean isTrue , String sourceMethod){
        try{
            Account accountRecord= [select id,Name,Type,RecordType.Name,Partner_Agreement_Status__c from Account where Id =: u.Contact.AccountId];
            if(!u.isActive){
                String error = Label.S_R_User_Inactive;
                String responce = createFollowup(u,error,sourceMethod);
                if(responce != null)
                    error= responce;
                return error;
            }
            List<Disable_Contact_List__mdt> ignoredD = [SELECT Id, Language, Label, MasterLabel FROM Disable_Contact_List__mdt where label =: u.email];

            //Ignore Case Senestive on email
            if(!ignoredD.isEmpty()){
                String msgInfo = System.label.S_R_Ignored_Email;
                return msgInfo;
            }
            if(accountRecord != null){

                if(accountRecord.RecordType.Name == 'Partner/Distributor' ){
                    Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
                    if(accountRecord.Partner_Agreement_Status__c == 'Signed - Active'){
                        return null;
                    }else if(accountRecord.Partner_Agreement_Status__c == 'Signed - Inactive'){
                        String error = Label.S_R_Signed_inactive;
                        return error ;
                    }else if(accountRecord.Partner_Agreement_Status__c == 'Unsigned' && entitlementCount == 0){
                        String error = Label.S_R_Unassigned;
                        return error ;
                    }
                    else if(accountRecord.Partner_Agreement_Status__c == 'Terminated' && entitlementCount == 0){
                        String error = Label.S_R_Terminated;
                        return error ;
                    }
                    else if(accountRecord.Partner_Agreement_Status__c == 'Contract out of date' && entitlementCount == 0){
                        String error = Label.S_R_Contract_out_of_date;
                        return error ;
                    }
                }else{
                    String customerType = accountRecord.Type;
                    Boolean isCustomer = customerType == 'Customer' || customerType == null ? true : false;
                    Boolean isProspect = customerType == 'Prospect' ? true : false;
                    Boolean isPartner = customerType == 'Reseller' || customerType == 'Distributor' || customerType == 'MSP-Reseller' || customerType == 'MSP' || customerType == 'MSP Customer'  ? true : false;
                    //Added by ashish as per the ask in Jira CS21-1082
                    Integer shipmentDelayByDays=Integer.valueof(System.Label.Days_for_Opportunity_Close_Date);
                    //Changes CS21-333 Start
                    Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
                    List<Opportunity> OpportunityList = new List<Opportunity>();
                    //CS21-298 : Added 7 Closed Won stage to the list
                    List<String> activeStages = new List<String>{'3 Technical Validation','4 Business Justification','5 Negotiate & Close','6 PO With Channel','7 Closed Won'};
                        Integer activeOpportunityCount = 0;
                    if(isCustomer || isProspect)
                        OpportunityList = [Select Id, CloseDate from Opportunity WHERE AccountId =: accountRecord.Id AND StageName IN :activeStages];
                    else if(isPartner)
                        OpportunityList = [Select Id, CloseDate from Opportunity WHERE (AccountId =: accountRecord.Id OR Partner_Lookup__c =: accountRecord.Id ) AND StageName IN :activeStages];
                    for(Opportunity opp:OpportunityList){
                        if(opp.CloseDate.addDays(shipmentDelayByDays) > System.today()){
                            activeOpportunityCount++;
                        }
                    }
                    Integer totalService = entitlementCount + activeOpportunityCount;

                    if(totalService == 0){
                        String error;
                        if(isCustomer){
                            error = Label.S_R_Customer_Account_Service;
                        }else if(isProspect){
                            error = Label.S_R_Prospect_Account_Service;
                        }else if(isPartner){
                            error = Label.S_R_Partner_Account_Service;
                        }
                        String responce = createFollowup(u,error,sourceMethod);
                            if(responce != null)
                                error= responce;
                            return error;

                    }
                    //Changes CS21-333 End
                }
            }
            return null;
        }catch(Exception e){
            return e.getMessage();
        }
    }

     public static String createFollowup(User u ,String description,String sourcePage){
        try{
            List<Customer_Registration_Request__c> crrList = [SELECT id,email__c,Status__c from Customer_Registration_Request__c where Email__c =: u.email AND (Status__c != 'Approved' AND Status__c != 'Rejected')];
            if(!crrList.isEmpty()){
                return Label.S_R_Request_Already_Register;
            }else{
                Customer_Registration_Request__c crr = new Customer_Registration_Request__c();
                crr.FirstName__c = u.firstName;
                crr.Last_Name__c = u.lastName;
                crr.Email__c = u.email;
                crr.Phone__c= u.phone;
                crr.Contact__c = u.ContactId;
                crr.Title__c = u.title;
                crr.Description__c = description;
                crr.has_Account__c = true;
                crr.has_Domain__c = true;
                crr.Domain_Name__c = u.email.substringAfter('@').toLowerCase();
                crr.Login_Expired__c = true;
                if(sourcePage == 'forget')
                    crr.Reset_Password__c = true;
                crr.Account__c = u.Contact.AccountId;
                insert crr;
                return null;
            }
        }catch(Exception e){
            return e.getMessage();
        }
    }

    /**
     * @Modified By  :   Vijay Kumar K R
     * @Description  :   Inserting WL_Domain__c records
     * @Params       :   Map<Id, String> domainMap, Boolean isApproved
     * @Rerurn       :   void
     * CS21-1218     :   Prevent "rubrik.com" email domain from being added to whitelist domain
     */
    public static void createNewDomain(Map<Id, String> domainMap, Boolean isApproved){//Account id and domain

        try {
            List<WL_Domain__c> wlDomainsList = new List<WL_Domain__c>();
            
            for (Id acID : domainMap.Keyset()) {
                String emailDomain = domainMap.get(acID);
                wlDomainsList.add(new WL_Domain__c(Name = emailDomain , Account__c = acID, isApproved__c = isApproved));
            }
            
            // Duplicate WL_Domain__c domain names and Ignored Domain validation is being handling in "DomainTriggerHandler"
            if(!wlDomainsList.isEmpty()) {
                Database.insert(wlDomainsList, false);
            }
        } catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'ERROR :: '+ e.getMessage()); 
        }
        
    }

    // public static void createDomain(Map<Id, String> domainMap){//Account id and domain
    //     try {
    //         List<String> oldDomainsList = new List<String>();
    //         List<WL_Domain__c> wlDomainsList = new List<WL_Domain__c>();
    //         List<Ignored_Domain__mdt> ignoredDomainMetadata = Ignored_Domain__mdt.getall().values(); //CS21-596
    //         Set<String> domainNamesToIgnore = new Set<String>();//CS21-596
            
    //         for (WL_Domain__c wd : [SELECT Name FROM WL_Domain__c 
    //                                 WHERE Name IN :domainMap.values() AND AccId IN: domainMap.keyset()]) {
    //             oldDomainsList.add(wd.Name);
    //         } // Fetching all domains from Org, No filter on Account realted Domains
            
    //         //CS21-596 - To exclude adding any non-corporate email domains to the Allowed Support Portal Email Domains on Account
    //         for (Ignored_Domain__mdt eachIgnoreMetadataDomain: ignoredDomainMetadata) {
    //             domainNamesToIgnore.add(eachIgnoreMetadataDomain.Label.toLowerCase());
    //         }
            
    //         for (Id acID : domainMap.Keyset()) {
    //             String emailDomain = domainMap.get(acID);
                
    //             if(!oldDomainsList.contains(emailDomain) 
    //                && !domainNamesToIgnore.contains(emailDomain)) {
    //                 wlDomainsList.add(new WL_Domain__c(Name = emailDomain , Account__c = acID));
    //             }
    //         }
            
    //         if(!wlDomainsList.isEmpty()) {
    //             insert wlDomainsList;
    //         }
    //     } catch(Exception e){
    //         System.debug(LoggingLevel.ERROR, 'ERROR :: '+ e.getMessage()); 
    //     }
        
    // }
    
    // public static void createNewDomain(Map<id,String> domainMap){//Account id and domain    
    //     try {
    //         Set<Id> AccountIds = new Set<Id>();
    //         List<WL_Domain__c> wlDomainsList = new List<WL_Domain__c>();
    //         List<Ignored_Domain__mdt> ignoredDomainMetadata = Ignored_Domain__mdt.getall().values(); //CS21-596
    //         Set<String> blackListedList = new Set<String>();
            
    //         for (WL_Domain__c wd : [SELECT Id, Account__c, Name 
    //                                 FROM WL_Domain__c 
    //                                 WHERE Account__c IN: domainMap.Keyset()]) {
    //             AccountIds.add(wd.Account__c);
    //         }
            
    //         //CS21-596 - To exclude adding any non-corporate email domains to the Allowed Support Portal Email Domains on Account
    //         for (Ignored_Domain__mdt ignoreMeta: ignoredDomainMetadata) {
    //             blackListedList.add(ignoreMeta.Label.toLowerCase());
    //         }
            
    //         for (Id acID : domainMap.Keyset()) {
    //             String emailDomain = domainMap.get(acID);
                
    //             if (!blackListedList.contains(emailDomain) && !AccountIds.contains(acID)){
    //                 wlDomainsList.add(new WL_Domain__c(Name = emailDomain , Account__c = acID));
    //             }
    //         }
            
    //         if (!wlDomainsList.isEmpty()) {
    //             insert wlDomainsList;
    //         }
    //     } catch(Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'ERROR :: '+ e.getMessage());
    //     }  
    // }
}