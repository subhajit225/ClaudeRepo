/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community - Deal registration page components controller.
*******************************************************************************************************/
public without sharing class PC_DealRegController {

    /*******************************************************************************************************
    * @description Returns User record
    * @param N/A
    * @return the User record for the login user
    ***********************************************************************************************************/
    @AuraEnabled
    public Static dealRegDataWrapper getUserDetails(){
        User partner = [select Id, Name, Email, Phone, AccountID, Contact.Account.Distributor__c, Account.Show_Rubrik_Complete_Edition__c, Contact.Account.Distributor__r.Name, Contact.Name, Contact.Email, Contact.Title, Contact.Phone,
                        Contact.Account.Name,SmallPhotoUrl,FullPhotoUrl,CompanyName,Contact.Account.Type,Contact.AccountId, IsActive,Contact.Primary_Role__c,Contact.Account.BillingCountry
                        FROM User WHERE id=:UserInfo.getUserId()];
        Id oemRecId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();

        dealRegDataWrapper drWrap = new dealRegDataWrapper();
        drWrap.userRec = partner;
        drWrap.oemRecId = String.valueOf(oemRecId);
        drWrap.distributorList = PC_PartnerOnboardingRequestContoller.getDistributorNames(partner.Contact.Account.BillingCountry);
        return drWrap;
    }

    /*******************************************************************************************************
    * @description Save the Deal Registration record.
    * @param vDealReg the deal registration record object.
    * @return the Deal Registration record creation status true/false.
    ***********************************************************************************************************/
    @AuraEnabled
    public static Boolean saveDealReg(Deal_Registration__c vDealReg) {
        Boolean isSaved = false;
        User partner = [select Id, Name, Email, Phone,AccountID,ContactID from User where id=:UserInfo.getUserId()];
        // Assigning default values to Deal Registrtion.
        vDealReg.Deal_Registration_Status__c = system.label.Deal_Reg_Status;
        vDealReg.Lead_Source_Details__c = system.label.Lead_Source_Detail;
        vDealReg.Deal_Reg_Submitted_Date__c = system.now();
        //PRIT24-350 - start
        if(vDealReg.Lead_Share_Campaign__c == false || vDealReg.Lead_Share_Campaign__c == null){
            vDealReg.Lead_Source__c = system.label.LEAD_SOURCE_CHANNEL;
        }
        //PRIT24-350 - end
        vDealReg.Deal_Registration_Type__c = DealRegUtilityHelper.PSNL;//PRIT24-754
        vDealReg.Account__c = partner.AccountID;
        vDealReg.Created_by_Contact__c = partner.ContactID;
        vDealReg.Deal_Reg_Exp_Date__c = Date.today().addDays(20); //prit26-285
        try {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Datacloud.DuplicateResult duplicateResult;
            List<Datacloud.MatchRecord> matchRecords;
            Database.SaveResult sr = Database.insert(vDealReg, dml);

            if (sr.isSuccess()) {
                isSaved = true;
            }else {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                    system.debug(LoggingLevel.DEBUG,'Exception occured '+err.getMessage());
                }
            }
        } catch (DmlException exceptionInstance) {
            system.debug(LoggingLevel.DEBUG,'Exception occured '+exceptionInstance.getMessage());
        }
        return isSaved;
    }
    public class dealRegDataWrapper{
        @AuraEnabled
        public User userRec {get;set;}
        @AuraEnabled
        public List<String> distributorList {get;set;}
        @AuraEnabled
        public String oemRecId{get;set;}
        public dealRegDataWrapper(){}
    }

    @AuraEnabled
    public static SObject getRecordDetails(String objectId, String objectName){
        sObject objRec = Schema.getGlobalDescribe().get(objectName).newSObject() ;
        String query;
        if(objectName == 'Lead'){
            objRec = [Select Id, Company, FirstName, LastName, Title, Email, Phone, Country, Address, City, PostalCode, StateCode, Street,
                      Customer_Category__c, Deal_Registration_Type__c, Opportunity_Amount__c, Current_Backup_Vendor__c, Last_MQL_Date__c,
                      Budget_new__c, Authority__c, Need__c,Purchase_Timeframe__c, LeadSource,
                      Alliance_Partner_Name__c,Distributor_Company_Name__c, Distributor_Rep_Name__c, Distributor_Rep_Email__c,
                      Distributor_Rep_Phone_Number__c, Distributor__r.Name FROM Lead WHERE Id =:objectId];
        }else{
            objRec =[Select Id, Account.Name, FirstName, LastName, Title, Email, Phone, MailingCountry, LeadSource, Last_MQL_Date__c,
                     MailingCity, MailingState, MailingStateCode, MailingPostalCode, MailingStreet from Contact
                     WHERE Id =: objectId];
        }
        return objRec;
    }
}