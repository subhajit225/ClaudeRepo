/**
*  @description : This Controller is generic case Controller all Lightning controller should use this
* Class Name :- CaseDetailController
* Author :- Grazitti
* Created-Date :- 06-09-2019
* Params  : User, true, Source page method string
* TestClass :- Test_CaseDetailController
********************Change Logs ******************************************************************************************************************************************************
*
* Modified By          Date                     Description
* Grazitti             06 september, 2019       This test class contains all the lightning migration component apex controllers and vf pages apex controllers
* Shiva Sharma         25 January, 2020         Include dynamic Text in "Heads Up To Support Team" for Support.
* Vijay Kumar K R      13 Dec, 2022             1325: [FedRAMP] Disable case creation from Email
* Vijay Kumar K R      5 Feb, 2022              1326: [FedRAMP] Disable case creation from Salesforce
* Raveesh Layal        5 Sept, 2023             CS21-1737 Update to 'Assign to me' (CS21-1287) - compare by seconds
* Vijay Kumar K R      22 Nov, 2023             CS21-2010: [FedRAMP 1.5] Enable case creation in Salesforce for hybrid RSC-G/RSC/CDM customers
* Shiva Sharma         8 April, 2024            Include caseinfo support for renewal cases. 
********************Change Logs Ends**************************************************************************************************************************************************
*/
public class CaseDetailController { 

    /**
* @description selectedCaseIds
*/
    public string selectedCaseIds{get;set;}
    /**
* @description callfunc
*/
    public string callfunc{get;set;}

    /**
* @description Create Case comment from Flow/PB
* @param ids
*/
    @InvocableMethod(label='create case comment' description='create error.' category='Case')
    public static void getCaseComment(List<ID> ids) {
        List<CaseComment> caseComments = new List<CaseComment>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        for(Case caseRec : [Select id,ServiceContract.SBQQSC__RenewalOpportunity__c from Case where id IN: ids  AND RecordType.Name = 'Renewal Case' ]){
            if(caseRec.ServiceContract.SBQQSC__RenewalOpportunity__c == null){
                caseComments.add(new CaseComment(ParentId = caseRec.Id,CommentBody='There seems to be error!! Opportuntiy is not created',IsPublished = false));
            }else{
                opportunityList.add(new Opportunity(id=caseRec.ServiceContract.SBQQSC__RenewalOpportunity__c,Automatedrenewal__c=true,Renewal_Case__c=caseRec.Id ));
            }
        }
        insert caseComments;
        update opportunityList;
    }

    /**
* @description get Record type Id
* @param recId
* @return string
*/
    @auraEnabled
    public static string getRecType(String recId){
        return [Select RecordType.Name from Case where Id=:recId].RecordType.Name;
    }
    
    /**
* @description get Record type Id
* @param recId
* @param OwnerId
*/
    @auraEnabled
    public static void updateOwners(String recId,String OwnerId){
        Case cs = new Case(Id = recId,OwnerId = OwnerId);
        update cs;
    }

    /**
* @description gCase active entitlement method
* @param caseId
* @return caseEntitlement
*/
    @AuraEnabled
    public static caseEntitlement caseEntitlementDetails(String caseId){
        Case cs = [SELECT Id, Distributer_Account_Name__r.Name, Distributer_Account_Name__c, Partner_Account_Name__r.Name,
                    Partner_Account_Name__c, Partner_Account_Name__r.Distributor__c, Partner_Account_Name__r.Distributor__r.Name,
                    AccountId, JIRA_Status__c, (Select id,Name,Status__c from Customer_Tasks__r), Recordtype.Name, Account.Name,
                    Account.r6000_Series_Products_Tagged__c,Region__c, Account.Approved_software_program__c,Account.GTC__c
                    FROM Case WHERE Id =: caseId];
        User usr = [SELECT id,Profile.Name FROM User WHERE id =: Userinfo.getUserId()];
        /* CS21-3715 - Commenting below if condition as this profile is not in use | SOX Cleanup Activity 
        if(usr.Profile.Name == 'Japan Third Party Profile' && (cs.Region__c != 'Japan' && !cs.Account.Name.contains('Rubrik'))){
            caseEntitlement ent = new caseEntitlement();
            ent.isAuthorized = false;
            return ent;
        }*/
        Boolean isCustomerSuccessCase = false;
        if(cs.Recordtype.Name == 'Customer Success'){
            isCustomerSuccessCase = true;
        }
        if(cs.Recordtype.Name == 'Renewal Case'){
            caseEntitlement caseEnt = new caseEntitlement();
            Boolean hasCustomPermission = FeatureManagement.checkPermission('Ability_to_View_Renewal_Cases');

            if(usr.Profile.Name != 'Rubrik Renewal Specialist' && !hasCustomPermission){
                caseEnt.isAuthorized = false;
                caseEnt.isRenewalCase = true;
                return caseEnt;
            }
            if(cs.Distributer_Account_Name__c != cs.Partner_Account_Name__r.Distributor__c){
                caseEnt.hasDiffDistr = true;
                caseEnt.distributorLookup = 'The Distributer('+cs.Partner_Account_Name__r.Distributor__r.Name+') on Partner Account(' +cs.Partner_Account_Name__r.Name +') doesn\'t match with '+cs.Distributer_Account_Name__r.Name;
            }
            return caseEnt;
        }else{
            List<String> assistRequestURl = new List<String>();
            if(!cs.Customer_Tasks__r.isEmpty()){
                for(Assist_Request__c ar : cs.Customer_Tasks__r){
                    assistRequestURl.add('<a href="/'+ar.Id+'" target="_blank">'+ar.Name+'('+ar.Status__c+')</a>');
                }
            }
            //Changes CS21-400 Start
            String name='';
            String ActualaccountName='';
            Boolean isActive=false;
            //RWD-814 Changes Start
            String completeEditionProduct;
            List<OrderItem> completeEdnPdt = new List<OrderItem>([Select Id,Product2.Name,Order.ActivatedDate,Order.Account.Name from OrderItem where (Product2.Name='RBK-SVC-CMPLT-RMOT' OR Product2.Name='RA-SVC-CE-RMOT') AND Order.AccountId=:cs.AccountId]);
            //List<Order> odrList = new List<Order>([Select Id,ActivatedDate,Account.Name,(Select Id,Product2.Name from OrderItems where Product2.Name='RBK-SVC-CMPLT-RMOT' OR Product2.Name='RA-SVC-CE-RMOT') from Order where AccountId=:cs.AccountId ]);
            if(!completeEdnPdt.isEmpty()){
                for(OrderItem od:completeEdnPdt){
                    //if(!od.OrderItems.isEmpty()){
                        if(System.now()>=od.Order.ActivatedDate && od.Order.ActivatedDate.Date().addMonths(7)>=System.now()){
                            name = '<a href="/'+cs.AccountId+'" target="_blank">'+od.Order.Account.Name+'</a>';
                            isActive = true;
                            completeEditionProduct = od.Product2.Name;
                        }
                //}
            }
                //RWD-814 Changes End
            }

            //CS21-500
            if(String.isBlank(name) && !String.isBlank(cs.AccountId)){
                name = '<a href="/'+cs.AccountId+'" target="_blank">'+cs.Account.Name+'</a>';
                ActualaccountName=cs.Account.Name;
            }

            Boolean isIgneous = false;
            if(!String.isBlank(cs.Account.r6000_Series_Products_Tagged__c) && cs.Account.r6000_Series_Products_Tagged__c.containsIgnoreCase(Label.Igneous)) {
                isIgneous = true;
            }
            //CS21-500 ends

            //Changes CS21-400 End
            List<String> entitlementNames = new List<String>();
            Boolean isUSFederalAccount = false;
            Boolean isUSFederalAccountPurchasedOrApproval = false;
            List<String> USFederalAccountList = new List<String>();
            Boolean isSubscribed = false;
            Boolean isFedRAMPAccount = false;
            Boolean isRSCCDMAccount = false;
            List<String> openOpportunityStages = Label.CustomerRegistrationOpportunityStages.split(',');
            try{
                //CS21-800 : Business logic for customer entitlement change
                Date closeDate45DaysPrior = System.today() - Integer.valueOf(Label.Days_for_Opportunity_Close_Date);
                Account accountRecord = [SELECT Id, U_S_citizen_service__c,Name, RSC_G_Support__c, Type, RecordType.Name, Partner_Agreement_Status__c, US_Federal_Account__c,
                                        (SELECT Id, Name FROM Entitlements WHERE Status = 'Active'),
                                        (SELECT Id, CloseDate FROM Opportunities WHERE StageName IN :openOpportunityStages AND CloseDate >: closeDate45DaysPrior LIMIT 1),
                                        (SELECT Id, CloseDate FROM Opportunities__r WHERE StageName IN :openOpportunityStages AND CloseDate >: closeDate45DaysPrior LIMIT 1)
                                        FROM Account
                                        WHERE Id =: cs.AccountId];
                if(accountRecord != null){
                    if(!accountRecord.Entitlements.isEmpty() || !accountRecord.Opportunities.isEmpty() || !accountRecord.Opportunities__r.isEmpty() ||
                    (accountRecord.RecordType.Name == 'Partner/Distributor' && accountRecord.Partner_Agreement_Status__c == 'Signed - Active')){
                        isSubscribed = true;
                    }
                    //CS21-800 : Business logic for customer entitlement change ends

                    /*String customerType = accountRecord.Type;
Boolean isCustomer = customerType == 'Customer' || customerType == null ? true : false;
Boolean isProspect = customerType == 'Prospect' ? true : false;
Boolean isPartner = customerType == 'Reseller' || customerType == 'Distributor' || customerType == 'MSP-Reseller' || customerType == 'MSP' || customerType == 'MSP Customer'  ? true : false;
if(isCustomer){
Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
List<Opportunity> activeOpportunities = [SELECT Id, Account.EndDate__c,Account.Close_Won_Date__c,StageName FROM Opportunity WHERE AccountId =: accountRecord.Id AND (StageName = '3 Technical Validation' OR StageName = '4 Business Justification' OR StageName = '5 Negotiate & Close' OR StageName = '6 PO With Channel')];
//Integer activeOpportunityCount = [select count() from Opportunity WHERE AccountId =: accountRecord.Id AND  (StageName != '7 Closed Lost' AND StageName != '7 Closed Won')];
//Integer totalService = entitlementCount + activeOpportunities.size();
Boolean endDateIsPrevious = false;
for(Opportunity opp: activeOpportunities){
if(opp.Account.EndDate__c!=null){
if(opp.Account.EndDate__c.addDays(45) < System.today()){
endDateIsPrevious = true;
}
}
else{
if(opp.Account.Close_Won_Date__c!=null && opp.Account.Close_Won_Date__c.addDays(45) < System.today()){
endDateIsPrevious = true;
}
}
}
if(entitlementCount > 0 || (activeOpportunities.size()>0 && !endDateIsPrevious)){
isSubscribed = true;
}else{
isSubscribed = false;
}
}else if(isProspect){
Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
List<Opportunity> activeOpportunities = [SELECT Id, Account.EndDate__c,Account.Close_Won_Date__c,StageName FROM Opportunity WHERE AccountId =: accountRecord.Id AND (StageName = '3 Technical Validation' OR StageName = '4 Business Justification' OR StageName = '5 Negotiate & Close' OR StageName = '6 PO With Channel')];
//Integer activeOpportunityCount = [select count() from Opportunity WHERE AccountId =: accountRecord.Id AND  (StageName != '7 Closed Lost' AND StageName != '7 Closed Won')];
//Integer totalService = entitlementCount + activeOpportunities.size();
Boolean endDateIsPrevious = false;
for(Opportunity opp: activeOpportunities){
if(opp.Account.EndDate__c!=null){
if(opp.Account.EndDate__c.addDays(45) < System.today()){
endDateIsPrevious = true;
}
}
else{
if(opp.Account.Close_Won_Date__c!=null && opp.Account.Close_Won_Date__c.addDays(45) < System.today()){
endDateIsPrevious = true;
}
}
}
if(entitlementCount > 0 || (activeOpportunities.size()>0 && !endDateIsPrevious)){
isSubscribed = true;
}else{
isSubscribed = false;
}
}
else if(isPartner){
Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
Integer activeOpportunityCount = [select count() from Opportunity WHERE (AccountId =: accountRecord.Id OR Partner_Lookup__c =: accountRecord.Id ) AND (StageName != '7 Closed Lost' AND StageName != '7 Closed Won')];
Integer totalService = entitlementCount + activeOpportunityCount;
if(totalService == 0){
isSubscribed = false;
}else{
isSubscribed = true;
}
}
if(!isSubscribed && accountRecord.RecordType.Name == 'Partner/Distributor' ){
if(accountRecord.Partner_Agreement_Status__c == 'Signed - Active'){
isSubscribed = true;
}else if(accountRecord.Partner_Agreement_Status__c == 'Signed - Inactive'){
isSubscribed = false ;
}else if(accountRecord.Partner_Agreement_Status__c == 'Unsigned'){
isSubscribed = false ;
}
}*/
                    if(isSubscribed){
                        for(Entitlement et : accountRecord.Entitlements){
                            if(!entitlementNames.contains(et.Name))
                                entitlementNames.add(et.Name);
                        }
                    }
                    // ------ CS21-3192: Case special handling instructions for US Federal Support and Purchased and Exception approval ---
                    List<String> USCitizenFieldValues = accountRecord.U_S_citizen_service__c != null ? accountRecord.U_S_citizen_service__c.split(';') : new List<String>();
                    if(USCitizenFieldValues.contains('U.S. Federal Support (Legacy)')){
                        isUSFederalAccount= true;
                    }
                    if(USCitizenFieldValues.contains('Purchased') || USCitizenFieldValues.contains('Exception approval')){
                        isUSFederalAccountPurchasedOrApproval=true;
                    }
                    if(accountRecord.RSC_G_Support__c != null){
                        List<String> accountRSC_Support = accountRecord.RSC_G_Support__c.split(';');
                        if(accountRSC_Support.contains('RSC-G') && !accountRSC_Support.contains('RSC/CDM')){
                            isFedRAMPAccount= true;
                        }
                        if(accountRSC_Support.contains('RSC-G') && accountRSC_Support.contains('RSC/CDM')){
                            isRSCCDMAccount= true;
                        }
                    }
                }

                Boolean isJiraWarned = [select count() from zsfjira__ZIssue_Case__c where zsfjira__CaseId__c =: caseId AND zsfjira__ZIssueId__r.zsfjira__Status__c LIKE '%Info Requested%'] > 0;
                //RWD-814 Changes
                return new caseEntitlement(cs,isSubscribed,entitlementNames,isUSFederalAccount,isUSFederalAccountPurchasedOrApproval,isJiraWarned,assistRequestURl,isActive,name,completeEditionProduct, isIgneous,isFedRAMPAccount,ActualaccountName,isRSCCDMAccount,isCustomerSuccessCase);
                //RWD-814 Changes End
            }catch(Exception e){
                return new caseEntitlement(null,false,new List<String>(),false,false,false,new List<String>(),false,'',completeEditionProduct, false, false, '', false,false);
            }
        }
    }

    /**
* @description Case Close Related Emails method.
* @param recordId of case
* @return EmailMessage
*/
    @AuraEnabled
    public static List<EmailMessage> getCaseEmails(String recordId){
        return [SELECT Id, Subject,FromAddress,ToAddress,MessageDate,Status  FROM EmailMessage where parentId =: recordId];
    }

    /**
* @description CaseEntitlement
*/
    public class CaseEntitlement{
        /**
* @description objCase
*/
        @AuraEnabled public Case objCase{get;set;}
        /**
* @description entitlementNames
*/
        @AuraEnabled public List<String> entitlementNames{get;set;}
        /**
* @description isSubscribed
*/
        @AuraEnabled public Boolean isSubscribed{get;set;}
        /**
* @description assistUrl
*/
        @AuraEnabled public List<String> assistUrl{get;set;}
        /**
* @description isJiraWarned
*/
        @AuraEnabled public Boolean isJiraWarned{get;set;}
        /**
* @description hasDiffDistr
*/
        @AuraEnabled public Boolean hasDiffDistr{get;set;}
        /**
* @description isUSFederalAccount
*/
        @AuraEnabled public Boolean isUSFederalAccount{get;set;}
        /**
         * @description Public boolean
        */
        @AuraEnabled public Boolean isUSFederalAccountPurchasedOrApproval{get;set;}
        /**
        * @description isRenewalCase
        */
        @AuraEnabled public Boolean isRenewalCase{get;set;}
        /**
        * @description isAuthorized
        */
         @AuraEnabled public Boolean isAuthorized{get;set;}
        /**
        * @description Sets True when the record type is Customer Success and false when it is Support.
        * @return Boolean
        */
        @AuraEnabled public Boolean isCustomerSuccessCase{get;set;}
        /**
        * @description distributorLookup
        */
        @AuraEnabled public String distributorLookup{get;set;}
        /**
* @description isActivated
*/
        @AuraEnabled public Boolean isActivated{get;set;}
        /**
* @description accName
*/
        @AuraEnabled public String accName{get;set;}
        /**
* @description isIgneous
*/
        @AuraEnabled public Boolean isIgneous {get;set;}
        /**
* @description isFedRAMPAccount
*/
        @AuraEnabled public Boolean isFedRAMPAccount{get;set;}
        /**
* @description oisRSCCDMAccountbjCase
*/
        @AuraEnabled public Boolean isRSCCDMAccount{get;set;}
        /**
* @description ActualaccountName
*/
        @AuraEnabled public String ActualaccountName{get;set;}
        /**
* @description completeEdnPdt
*/
        @AuraEnabled public String completeEdnPdt{get;set;}
        //RWD-814 end
        /**
         * @description caseEntitlement
         * @param objCase
         * @param isSubscribed
         * @param entitlementNames
         * @param isUSFederalAccount
         * @param isUSFederalAccountPurchasedOrApproval
         * @param isJiraWarned
         * @param assistUrl
         * @param isActivated
         * @param accName
         * @param completeEdnPdt
         * @param isIgneous
         * @param isFedRAMPAccount
         * @param actualaccountName
         * @param isRSCCDMAccount
         * @param isCustomerSuccessCase
        */
        public caseEntitlement(Case objCase,Boolean isSubscribed,List<String> entitlementNames,Boolean isUSFederalAccount,Boolean isUSFederalAccountPurchasedOrApproval,Boolean isJiraWarned, List<String> assistUrl, Boolean isActivated,String accName,String completeEdnPdt, Boolean isIgneous,Boolean isFedRAMPAccount,String actualaccountName,Boolean isRSCCDMAccount,Boolean isCustomerSuccessCase){
            this.objCase = objCase;
            this.entitlementNames = entitlementNames;
            this.isSubscribed = isSubscribed;
            this.isJiraWarned =isJiraWarned;
            this.isUSFederalAccount = isUSFederalAccount;
            this.isUSFederalAccountPurchasedOrApproval=isUSFederalAccountPurchasedOrApproval;
            this.assistUrl = assistUrl;
            this.hasDiffDistr = false;
            this.isRenewalCase = false;
            this.isCustomerSuccessCase = isCustomerSuccessCase;
            this.isAuthorized = true;
            //Changes CS21-400 Start
            this.isActivated = isActivated;
            this.accName = accName;
            this.actualaccountName = actualaccountName;
            this.isFedRAMPAccount = isFedRAMPAccount;
            //Changes CS21-400 End
			//RWD-814
			this.completeEdnPdt = completeEdnPdt;
			//RWD-814 ends
            //CS21-500
            this.isIgneous = isIgneous;
            //CS21-500 ends
            this.isRSCCDMAccount = isRSCCDMAccount;
        }
        /**
* @description constructor
*/
        public caseEntitlement(){
            this.entitlementNames = new List<String>();
            this.isSubscribed = false;
            this.isJiraWarned =false;
            this.isUSFederalAccount = false;
            this.isUSFederalAccountPurchasedOrApproval= false;
            this.isFedRAMPAccount = false;
            this.assistUrl = new List<String>();
            this.isRenewalCase = true;
            this.isAuthorized = true;
			//RWD-814
			this.completeEdnPdt = completeEdnPdt;
			//RWD-814 ends
            //CS21-500
            this.isIgneous = false;
            //CS21-500 ends
            this.isRSCCDMAccount = false;
        }
    }
    /** 
* @description fetching Account record details based on AccountId as Param Updated by Vijay: CS21-1325: [FedRAMP] Disable case creation from Salesforce
* @param recId 
* @return Account
**/
    @AuraEnabled(cacheable=true)
    public static Account getAccountRecord(Id recId){
        try {
            return  [SELECT Id, Name, Heads_UpTo_Support_Team__c, RSC_G_Support__c, GTC__c, Tabs_Visibility__c
                        FROM Account 
                        WHERE Id =: recId Limit 1];
        } catch (Exception e) {   throw new AuraHandledException('getAccountRecord exception: '+e.getMessage());}
    }
    /** Updated by Vijay: CS21-1325: [FedRAMP] Disable case creation from Salesforce
* @description 
* @param recId 
* @return Contact
* Description: fetching Contact record details based on ContactId as Param
**/
    @AuraEnabled(cacheable=true)
    public static Contact getContactRecord(Id recId){
        try {
            return  [SELECT Id, AccountId, Account.Name, Account.RSC_G_Support__c, Account.Heads_UpTo_Support_Team__c, Account.GTC__c
                        FROM Contact 
                        WHERE Id =: recId Limit 1];
        } catch (Exception e) {throw new AuraHandledException('getContactRecord exception: '+e.getMessage()); }
    }

    /** Updated by Vijay: CS21-1325: [FedRAMP] Disable case creation from Salesforce
@description 
* @param recId 
* @return Contact
* Description: fetching Case record to check if Account/Contact is FedRAMP
**/
    @AuraEnabled(cacheable=true)
    public static Case checkFedRAMPForCloneCase(Id recId){
        try {
            return  [SELECT Id, Account.RSC_G_Support__c, ContactId, Contact.Account.Name, Account.Name, Account.GTC__c
                        FROM Case 
                        WHERE Id =: recId];
        } catch (Exception e) { throw new AuraHandledException('checkFedRAMPForCloneCase exception: '+e.getMessage());}
    }

    /**
* @description get rec type Ids.
* @return string
*/
    @auraEnabled
    public static string getRecTypeId(){
        //Customer success change to set default record type for CSM
        User usr = [SELECT id,is_Customer_Success_User__c FROM User WHERE Id =: Userinfo.getUserId()];
        String recordType = usr.is_Customer_Success_User__c ? 'Customer Success' : 'Support Case';
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        return recTypeId;
    }

    //CS21-137
    /**
* @description CS21-137
* @param recordId
* @return Case
*/
    @AuraEnabled(cacheable=true)
    public static List<Case> getCaseDescription(String recordId) {
        List<Case> caseattrr = [Select Id,Subject,Description,Account_Preference__c,Account.Heads_Up_to_Support_Team__c,CaseNumber from Case where Id = : recordId LIMIT 1];
        return caseattrr;

        //return [Select Id,CaseNumber,Status,Subject,Priority,LastModifiedDate,CreatedDate,Owner.Name,Resolution__c,Cluster__r.Name,Cluster__c From Case where AccountId = : AcctId AND Cluster__r.Name LIKE : newSearchText order by LastModifiedDate DESC];
    }

    /**
* @description Get Case record Id                 
* @param recordId
* @return Case
*/
    @AuraEnabled
    public static Case getDuplicateCaseRecord(String recordId) {
        Case currentCaseRecord = [SELECT Id, Duplicate_Case_Id__c FROM Case WHERE Id =: recordId];

        if(!String.isBlank(currentCaseRecord.Duplicate_Case_Id__c)) {
            Case duplicateCaseRecord = [SELECT Id, CaseNumber FROM Case WHERE Id =: currentCaseRecord.Duplicate_Case_Id__c];
            return duplicateCaseRecord;
        }
        return null;
    }

    //Case Description Class
    /**
* @description Case Description Class                
* @param caseId
* @return Case
*/
    @AuraEnabled
    public static Case getCaseRecForCaseDescription(Id caseId){
        List<Case> caseList = LGT_Migration_Utils.getCaseRecForAllComponents(caseId);
        if(caseList != null && !caseList.isEmpty()){
            return caseList[0];
        }
        else{List<Case> caseList1 = new List<Case>();return caseList1[0];
        }
    }
    
    //Case Description Class
    /**
* @description Case Description Class                
* @param caseId
* @param caseSubjectVal
* @param caseDescriptionVal
* 
* @return String
*/
    @AuraEnabled
    public static String saveCaseRecordForCaseDescription(Id caseId, String caseSubjectVal,String caseDescriptionVal){
        String errorMsg = '';
        if(caseId != null){
            Case caseRec = new case(Id = caseId);
            caseRec.Subject = caseSubjectVal;
            caseRec.Description = caseDescriptionVal;
            if(caseRec.Subject.contains('Automatic reply:') || caseRec.Subject.contains('Risposta automatica') || caseRec.Subject.contains('Out of Office AutoReply:') || caseRec.Subject.contains('Undelivered Mail Returned to Sender') || caseRec.Subject.contains('Automatische Antwort:') || caseRec.Subject.contains('Risposta automatica:') || caseRec.Subject.contains('Delivery Status Notification (Failure)') ||
               caseRec.Subject.contains('Warning: could not send message for past 4 hours') || caseRec.Subject.contains('Out of Office') || caseRec.Subject.contains('[Email Loop Protection] Out of Office')){
                   errorMsg= 'Thank you for your mail.' + 'This email will be ignored and will not create any cases';
               }
            else{
                UPDATE caseRec;
            }
        }
        if(errorMsg != null && errorMsg != '')
            return errorMsg;
        else
            return null;
    }

    //Case Special Handling Class
    /**
* @description Case Special Handling Class            
* @param caseId
* @return Case
*/
    @AuraEnabled
    public static Case getCaseRecord(Id caseId){
        List<Case> myCase= LGT_Migration_Utils.getCaseRecForAllComponents(caseId);

        if(myCase != NULL && !myCase.IsEmpty()) {
            return myCase[0];
        }
        else{List<Case> myCase1 = new List<Case>();return myCase1[0];
        }
    }
    //Recent Cases Class
    /**
* @description Recent Cases Class        
* @param caseId
* @return Case
*/
    @AuraEnabled
    public static List<Case> getCaseRec(Id caseId){
        Case caseRecord = [SELECT Id,CaseNumber,Status,Subject,Priority,Owner.Name,Account.Id,Cluster__r.Name,recordTypeId FROM case WHERE ID =: caseId];
        List<case> CaseRecordsRelatedToSameAccount = [SELECT Id,Status,LastModifiedDate,CaseNumber,Subject,Priority,Resolution__c,Owner.Name,Cluster__r.Name,Cluster__c,CreatedDate FROM case WHERE Account.Id =: caseRecord.AccountId AND Id !=: caseId AND recordTypeId =: caseRecord.recordTypeId Order By LastModifiedDate desc];
        if(CaseRecordsRelatedToSameAccount != null && !CaseRecordsRelatedToSameAccount.isEmpty()){ return CaseRecordsRelatedToSameAccount;
        }
        else{
            return new List<Case>();
        }

    }
    //Cluster List Class
    /**
* @description Cluster List Class      
* @param caseId
* @return Cluster__c
*/
    @AuraEnabled(cacheable=true)
    public static List<Cluster__c> getClusterList(String caseId){
        Case caseRecord = [SELECT Id,AccountId FROM Case WHERE id =: caseId];
        List<Cluster__c> accountRelatedClusterList = [SELECT Id, Name, tag__c, software_version__c, archived__c  FROM Cluster__c WHERE account__c =: caseRecord.AccountId AND archived__c = false Order By LastModifiedDate desc];
        if(accountRelatedClusterList != null && !accountRelatedClusterList.isEmpty()){
            return accountRelatedClusterList;
        }
        else{
            return new List<Cluster__c>();
        }

    }
    //RMA Request List Class
    /**
* @description RMA Request List Class    
* @param caseId
* @return RMA_Order__c
*/
    @AuraEnabled public static List<RMA_Order__c> getRMAList(Id caseId){
        //CS21-132 - Shubham - Adding null check
        List<RMA_Order__c> caseRelatedRMAList = new List<RMA_Order__c>();
        Case caseRecord = [SELECT Id,AccountId FROM Case WHERE id =: caseId];
        if(caseRecord.AccountId != null){
            caseRelatedRMAList = [SELECT Id,Name,Assets__c,Cluster__c,Node__c,Status__c,Service_Type__c,Parent_Case__r.CaseNumber FROM RMA_Order__c WHERE Parent_Case__r.AccountId =: caseRecord.AccountId Order By LastModifiedDate desc];
        }
        if(caseRelatedRMAList != null && !caseRelatedRMAList.isEmpty()){
            return caseRelatedRMAList;
        }
        else{
            return new List<RMA_Order__c>();
        }
    }
    //Case Info Section Class
    /**
* @description Case Info Section Class 
* @param recordId
* @return Wrappercase
*/
     @AuraEnabled
    public static Wrappercase getFields(String recordId){
        Wrappercase newRecord = new Wrappercase();
        List<wrapper> listWrapper = new List<wrapper>();
        String query = 'Select ';
        User u = [SELECT id, Profile.Name, is_Customer_Success_User__c FROM User WHERE id =: Userinfo.getUserId()];
        List<Schema.FieldSetMember> fieldset;
        Case caserecord = [SELECT id,RecordType.Name FROM Case WHERE Id =: recordId];
        if(u.is_Customer_Success_User__c){//change from division to is_Customer_Success_User__c
            fieldset = SObjectType.Case.FieldSets.Customer_Sucess_Fieldset.getFields();
        }else if(caseRecord.RecordType.Name == 'Renewal Case'){
            fieldset = SObjectType.Case.FieldSets.Renewal_Fieldset.getFields();
        }else{
            fieldset = SObjectType.Case.FieldSets.ConsoleFields.getFields();
        }
        for(Schema.FieldSetMember each : fieldset){
            wrapper eachRecord = new wrapper();
            eachRecord.label = each.getLabel();
            eachRecord.Name= each.getFieldPath();
            eachRecord.Type= String.ValueOf(each.getType());    //CS21-1984
            listWrapper.add(eachrecord);
            query +=each.getFieldPath() + ',';
        }
        newRecord.wrapperList = listWrapper;
        if(u.is_Customer_Success_User__c && !query.containsIgnoreCase('Account.Rubrik_Sales_Engineer__r.Name')){ 
            query += ' Account.Rubrik_Sales_Engineer__r.Name, ';
        }
        /*if(caseRecord.RecordType.Name == 'Renewal Case'){
        //    query += ' Opportunity_lookup__r.ACV_Amount__c, Opportunity_lookup__r.Amount, ';
        }*/
        //Added EscalationManagerOwner__r.Name field - CS21-504 - Veera
        query += ' EscalationManagerOwner__r.Name, Id, Account.Owner.Name, RecordType.Name FROM Case where Id = :recordId';
        case cs = Database.query(String.escapeSingleQuotes(query));
        newRecord.recordDetail = cs;
        return newRecord;
        
    }
    
    /**
* @description Save Case
* @param fieldName of case
* @param value of case
* @param recordId of case
* @return String
*/
    @AuraEnabled
    public static String saveRecordApex1(String fieldName, String value, String recordId){
        try{
            if(recordId.startsWith('500')){
                Case cs = [SELECT id,priority,origin FROM case WHERE id = :recordId];
                if(fieldName != null && fieldName != '' && value != null && value != ''){
                    if(fieldName == 'Snooze_End_DateTime__c'){
                        value = value.replace('T',' ').replace('Z','');
                        cs.put(fieldName,Datetime.valueOfGMT(value));
                    }
                    //CS21-2406 - Sales escalations field update
                    else if(fieldName == 'Sales_Escalated__c'){
                        cs.put(fieldName,Boolean.valueOf(value));
                    }
                    else{
                        cs.put(fieldName,value);
                    }
                }
                update cs;
            }
            
            return 'SUCCESS';
        }catch(exception e){if(e.getMessage().contains('Resolution_Details__c')){ return 'Please provide the resolution details in the "Case resolution section" before changing the status.';  }if(e.getMessage().contains('Date/Time field is mandatory when Sub Phase is snooze')){return 'Date/Time field is mandatory when Sub Phase is snooze'; } if(e.getMessage().contains('Case update failed:Date/Time cannot be in the past')){ return 'Case update failed:Date/Time cannot be in the past!';}return e.getMessage();}}
    
    /**
* @description get Email message
* @param recordId of case
* @return EmailMessage
*/
    @AuraEnabled
    public static List<EmailMessage> getCaseEmailsForCaseInfo(String recordId){
        return [SELECT Id, Subject,FromAddress,ToAddress,MessageDate,Status  FROM EmailMessage where parentId =: recordId];
    }

    /**
* @description Generic
*/
    public class Wrapper{
        /**
* @description Generic
*/
        @AuraEnabled
        public string label{get;set;}
        /**
* @description Generic
*/
        @AuraEnabled
        public string Name{get;set;}
        /**
* @description Generic
*/
        @AuraEnabled
        public string Type{get;set;}
    }
    /**
* @description Generic
*/
    public class WrapperCase{
        /**
* @description Generic
*/
        @AuraEnabled
        public Sobject recordDetail{get;set;}
        /**
* @description Generic
*/
        @AuraEnabled
        public List<wrapper> wrapperList{get;set;}
    }

    /**
* @description Generic
*/
    public case caseRecordUpdation;
    /**
* @description Generic
*/
    Public PageReference pageRef;
    /**
* @description Generic
*/
    public Id caseId{get;set;}
    /**
* @description Generic
* @param controller
*/
    public CaseDetailController(ApexPages.StandardController controller){
	    caseId = (Id)controller.getId();
    }
    /**
* @description Generic
* @return Pagereference
*/
    public PageReference spam(){
        CaseRecordUpdation = new case();
        Case caseRecord = [SELECT Recordtype__c,id,Status,Resolution__c,Type,Origin,Platform__c,KCS_Article_Candidate__c,Resolution_Details__c,Priority,KCS_or_Supportability_comments__c,Supportability_Improvement_Requested__c From Case WHERE id =: ApexPages.currentPage().getParameters().get('id')];
        if(caseRecord != null){
            CaseRecordUpdation.Id = caseRecord.Id;
            CaseRecordUpdation.Status = 'Closed';
            CaseRecordUpdation.Resolution__c = 'Spam/Junk';
            CaseRecordUpdation.Type = 'Other';
            CaseRecordUpdation.Origin = 'Other';
            CaseRecordUpdation.Platform__c = 'Spam/Junk';
            CaseRecordUpdation.KCS_Article_Candidate__c = 'No Article required';
            CaseRecordUpdation.Resolution_Details__c = 'Spam';
            CaseRecordUpdation.Priority = 'P4';
            CaseRecordUpdation.KCS_or_Supportability_comments__c = 'Spam';
            CaseRecordUpdation.Supportability_Improvement_Requested__c = 'No - Supportability Improvement not requested';
            if(CaseRecord.Recordtype__c == 'Renewal Case')
                CaseRecordUpdation.Resolution_Code__c = 'Duplicate';
            UPDATE CaseRecordUpdation;
        }
        PageReference casePage = new ApexPages.StandardController(CaseRecordUpdation).view();
        casePage.setRedirect(true);
        return casePage;
    }
    /**
* @description Generic
* @return User

*/
    @AuraEnabled
    public static user fetchUser(){
        User currentUser = [select id,Name,Profile.Name from User where id =: userInfo.getUserId()];
        return currentUser;
    }

    //Lightning Strike Button Class
    /*public pageReference Strike(){
Case caseRecordForStrike = [SELECT Id,Strike1__c,Strike2__c,Strike3__c,ContactEmail,Status,AccountId,ContactId,Contact.Email,Permanent_Fix_Date__c FROM Case WHERE ID =: ApexPages.currentPage().getParameters().get('id')];
Case UpdatedCsRecord = new Case();
if(caseRecordForStrike != null){
if(caseRecordForStrike.Strike1__c == null && caseRecordForStrike.Strike2__c == null && caseRecordForStrike.Strike3__c == null){
UpdatedCsRecord.Id = caseRecordForStrike.Id;
UpdatedCsRecord.Strike1__c = system.now();
UPDATE UpdatedCsRecord;
}
if(caseRecordForStrike.Strike1__c != null && caseRecordForStrike.Strike2__c == null && caseRecordForStrike.Strike3__c == null){
UpdatedCsRecord.Id = caseRecordForStrike.Id;
UpdatedCsRecord.Strike2__c = system.now();
UPDATE UpdatedCsRecord;
}
if(caseRecordForStrike.Strike1__c != null && caseRecordForStrike.Strike2__c != null && caseRecordForStrike.Strike3__c == null && caseRecordForStrike.Permanent_Fix_Date__c == null){
UpdatedCsRecord.Id = caseRecordForStrike.Id;
UpdatedCsRecord.Strike3__c = system.now();
UpdatedCsRecord.Status = 'Closed';
UpdatedCsRecord.Permanent_Fix_Date__c = system.now();
UPDATE UpdatedCsRecord;
}
if(caseRecordForStrike.Strike1__c != null && caseRecordForStrike.Strike2__c != null && caseRecordForStrike.Strike3__c == null && caseRecordForStrike.Permanent_Fix_Date__c != null ){
UpdatedCsRecord.Id = caseRecordForStrike.Id;
UpdatedCsRecord.Strike3__c = system.now();
UpdatedCsRecord.Status = 'Closed';
UPDATE UpdatedCsRecord;
}

}
PageReference casePage1 = new ApexPages.StandardController(UpdatedCsRecord).view();
casePage1.setRedirect(true);
return casePage1;


}*/

    /**
* @description Generic
* @param listcontroller
*/
    public CaseDetailController(ApexPages.StandardSetController listcontroller){
        string CaseIds = '';
        for(Case obj : (Case[])listcontroller.getSelected()){
            CaseIds = CaseIds +obj.Id + '_';
        }
        selectedCaseIds = CaseIds.removeEnd('_');
    }
    /**
* @description Generic
* @return Pagereference
*/
    public PageReference navigateToCase(){
        return new PageReference('/'+caseId);
    }


    //CS21-1326: Lightning Assign To Me Component CLass
    /**
* @description Generic
* @param caseIds
* @return string
*/
    @AuraEnabled
    public static String updateOwner(string caseIds){
        try {
            if(caseIds!=null){
                List<id> caseId = caseIds.split('_');
                List<Case> cases = [Select id, OwnerId  from Case where Id IN: caseId FOR UPDATE];
                Datetime minDateTime = System.now().addMinutes(-5);
                List<CaseHistory> historyList = [SELECT NewValue, CreatedDate FROM CaseHistory WHERE field ='Owner' AND CaseId =: caseIds  AND DataType = 'EntityId' AND CreatedDate >=: minDateTime order by createddate desc limit 1];
                if(!historyList.isEmpty()){
                    CaseHistory historyRecord = historyList[0];
                    String userId = (String)historyRecord.NewValue;
                    if(userId.startsWith('005')){
                        User usr = [SELECT id, Name FROM User WHERE Id =: userId];
                        return 'Case has already been assigned to '+usr.Name;
                    }
                }
                if(cases.size() > 0){
                    for(case obj : cases){
                        obj.OwnerId = UserInfo.getUserId();
                    }
                    update cases;
                }
            }   
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('UpdateOwner exception: '+e.getMessage());
        }
    }

    /**
* @description Generic
*/
    public void callJS(){
        callfunc='<script>RefreshPrimaryTab();</script>';
    }

    /**
* @description method to check if the current user is support manager - CS21-504 - Veera
* @return boolean
*/
    @AuraEnabled
    public static boolean isSupportManager() {
        Boolean isSupportManager = false;
        List<String> managerProfiles = Label.CaseInfoManagerProfiles.trim().split(',');

        for (Profile managerProfile : [SELECT Id FROM Profile WHERE Name IN :managerProfiles]) {
            if (Test.isrunningTest() || (UserInfo.getProfileId() == managerProfile.Id)) {
                isSupportManager = true;
                break;
            }
        }

        return isSupportManager;
    }
    
    /**
* @description Generic
* @param ObjectName of case
* @param fieldName of case
* @param value of case
* @param parentId of case
* @return SObJectResult
*/
    @AuraEnabled
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, String parentId) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        for(sObject so : Database.Query('Select Id, '+String.escapeSingleQuotes( fieldName)+' FROM '+String.escapeSingleQuotes( ObjectName)+' WHERE '+String.escapeSingleQuotes( fieldName)+' LIKE \'%' +String.escapeSingleQuotes(value) + '%\' AND AccountId =:parentId')) {
            String fieldvalue = (String)so.get(fieldName);
            sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
        }
        
        return sObjectResultList;
    }

    /**
* CS21-1325
* @description getUIThemeDescription 
* @return String
**/
    @AuraEnabled
    public static String getUIThemeDescription() {
        try {
            String theme = UserInfo.getUiThemeDisplayed();
            return theme;
        } catch (Exception e) {throw new AuraHandledException('getUIThemeDescription exception: '+e.getMessage());
        }
    }

    /**
* CS21-1325
* @description getQueueIds 
* @return String
**/
    @AuraEnabled
    public static Map<String, Id> getQueueIds() {
        try {
            Map<String, Id> queueIdByNameMap = new Map<String, Id>();
            List<String> groupNameList = new List<String>{'Unassigned_Cases', 'Customer_Success'};
            for(Group objGrp : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: groupNameList]){
                queueIdByNameMap.put(objGrp.DeveloperName, objGrp.Id);
            }
            return queueIdByNameMap;
        } catch (Exception e) {  throw new AuraHandledException('getQueueIds exception: '+e.getMessage());
        }
    }
    
    /**
* @description Generic
*/
    public class SObJectResult {
        /**
* @description Generic
*/
        @AuraEnabled
        public String recName;
        /**
* @description Generic
*/
        @AuraEnabled
        public Id recId;
        /**
* @description Generic
* @param recNameTemp of case
* @param recIdTemp of case
        
*/
        public SObJectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
    }

     /**
* CS21-2220
* @description getRansomware 
* @param caseId 
* @return Escalation__c
**/
    @AuraEnabled(cacheable=true)
    public static Escalation__c getRansomware(String caseId){

        Id ransomwareRtId = Schema.SObjectType.Escalation__c.getRecordTypeInfosByDeveloperName().get('Escalation_Ransomware').getRecordTypeId();

        try {
            return [SELECT Id
                    FROM Escalation__c 
                    WHERE Case__c =: caseId 
                    AND RecordTypeId =: ransomwareRtId
                    AND Status__c != 'Closed' Limit 1];
        } catch (Exception e) {throw new AuraHandledException('Error fetching Escalation RRT in getRansomware method: ' + e.getMessage());}
        
    }
    /**
     * @description Retrieves the AccountId from a given ContactId.
     * @description This is called by the LGT_NewCase component when the Contact is selected
     * @description to automatically populate the related Account.
     * @param contactId  The ID of the Contact record to query.
     * @return String    The related AccountId, or null if not found or if input is blank.
     */
    @AuraEnabled(cacheable=true)
    public static String getAccountFromContact(String contactId) {
        
        // Basic validation to prevent a SOQL query on empty or invalid data
        if (String.isBlank(contactId)) { return null;}
        
        try { 
            // Perform the SOQL query. 
            // We query into a List to gracefully handle cases where no record is found,
            // which prevents a 'List has no rows for assignment to SObject' exception.
            List<Contact> contacts = [
                SELECT AccountId 
                FROM Contact 
                WHERE Id = :contactId 
                LIMIT 1
            ];

            // Check if the list is not empty (i.e., we found the contact)
            if (!contacts.isEmpty()) {
                // Return the AccountId from the first (and only) record
                return contacts[0].AccountId;
            } else { return null;/* A valid query was run, but no contact matched the ID. */ }

        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }
}