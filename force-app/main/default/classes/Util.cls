/**
* @File Name : Util.cls
* @Description : Created util class for Community
* @Author : Grazitti
* @Last Modified By : Shiva Sharma
* @Last Modified On : March 6, 2025
* @TestClass : UtilTest
// ********************Change Logs ******************************************************************************************************************************************************

* Modified By          Date                     Description

// ********************Change Logs Ends**************************************************************************************************************************************************/
/**
 * @description class used to get fields for hero header section based on recordtype of the case
*/ 
public with sharing class Util {
    
    /**
     * @description : identify if Calendly Section need to be shown on Portal
     * @return Boolean
    */
    @AuraEnabled
    public static Boolean hideShowCalendly(){
        User userRecord;
        Boolean hasPredibaseProduct = false;
        List<String> r6000ValuesOnAccount = new List<String>();
        if (Schema.sObjectType.USER.isAccessible()) {
            userRecord = [SELECT id,AccountId,Account.Calendly_Section_Override__C,Account.RSC_G_Support__c, Account.Type, Account.US_Federal_Account__c, Account.r6000_Series_Products_Tagged__c FROM USER WHERE Id =: UserInfo.getUserId()];
        }
        if(userRecord!= null && userRecord.Account.RSC_G_Support__c != null && (userRecord.Account.RSC_G_Support__c.contains('RSC-G') || userRecord.Account.RSC_G_Support__c.contains('RSC-G;RSC/CDM'))){
            return false;
        }
        if(userRecord != null && ( !userRecord.Account.Type.containsIgnoreCase('Customer') ||  userRecord.Account.US_Federal_Account__c)){
            return false;
        }
        //------ CS21-3477: if account has only Prediabse product, don't show calendly section ----- 
        if(userRecord!= null && userRecord.Account.r6000_Series_Products_Tagged__c != null){
            r6000ValuesOnAccount = userRecord.Account.r6000_Series_Products_Tagged__c.split(', ');
            if(r6000ValuesOnAccount.size() == 1 && r6000ValuesOnAccount.contains('Predibase')){
                hasPredibaseProduct = true;
            }
        }
        List<Order> orderList = new List<Order>();
        if (userRecord.AccountId != null){
            InnerClass inerClass = new InnerClass();
            orderList = inerClass.getRelatedOrders(userRecord.AccountId);
        }
        if(!orderList.isEmpty() && orderList[0].SBQQ__Quote__r.Manual_Fulfillment_Quote__c != null && (orderList[0].SBQQ__Quote__r.Manual_Fulfillment_Quote__c.contains('$0 RSC-RSC-P Conversion') || orderList[0].SBQQ__Quote__r.Manual_Fulfillment_Quote__c.contains('Paid RSC-P Conversion')
            || orderList[0].SBQQ__Quote__r.Manual_Fulfillment_Quote__c.contains('$0 GO-RSCP Conversion'))){
             return false;
        }
        return !orderList.isEmpty() && !userRecord.Account.Calendly_Section_Override__C && !hasPredibaseProduct? true : false;
    }
    
    /**
     * @description
     * @param userId id of the case
     * @return User
    */
    public static User getUserDetail(Id userId) {
        User returnUser;

        if (userId != null) {
            try {
                if (Schema.sObjectType.User.isAccessible()) {
                    returnUser = [select Id, Name, UserName, Email, ContactId, Contact.Agreed_to_Edge_Trial_Agreement__c, Contact.AccountId from User where Id = : userId]; 
                }
            } catch (exception ex) {
                return null;
            }
        }
        return returnUser;
    }

    /**
	* @description
	* @param null
	* @return User
	*/
    public static User CurrentUser {
        get {
            if (CurrentUser == null) {
                CurrentUser = getUserDetail(UserInfo.getUserId());
            }
            return CurrentUser;
        }

        private set;
    }
    
    /**
	* @description
	* @return String
	*/
    public static string UserType {
      get {
            if (UserType == null) {
                UserType = UserInfo.getUserType() == 'PowerPartner' ? 'partner' : UserInfo.getUserType() == 'CspLitePortal' ? 'customer' : 'internal';
                if(UserInfo.getProfileId() == Label.Trial_Edge_Profile){
                    UserType = 'Trial';
                }
            } 
          if(test.isRunningTest()) UserType = 'customer';
            return UserType;
        }
        private set;
      }

    /**
    * @description userdetail
    */
    User PartnerUser;
    
    /**
	* @description
	* @return User
	*/
    public User getPartnerUser() {
        if(PartnerUser == null) {
            if (Schema.sObjectType.User.isAccessible()) {
                PartnerUser = [select u.Contact.AccountId,u.Contact.Account.Owner.Name,
                            u.Contact.Account.Owner.Email
                            from User u where u.id= :UserInfo.getUserId() limit 1];
            }
        }
        
        return PartnerUser;
    }
         
    /**
	* @description this method is used to send email
	* @param toEmails String
    * @param ccEmails String
    * @param bccEmails String
    * @param bodyText String
    * @param subject String
    * @param isText Boolean
	*/
    public static void sendEmail(string toEmails, string ccEmails, string bccEmails, string bodyText, string subject, boolean isText) {
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        string[] to = new string[] {toEmails};
        string[] cc = new string[] {ccEmails};
         
        email.setToAddresses(to);
        if(ccEMails!=null && ccEMails != '')
            email.setCcAddresses(cc);
            email.setInReplyTo('noreply@rubrik.com');
         
        email.setSubject(subject);
         
        email.setplainTextBody(bodyText);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch(exception e) {
            String exceptionMessage = e.getMessage();
            //system.debug('### error sending email '+ exceptionMessage);
        }
    
    }

    /**
     * @description inner class to get related orders
    */
    public without sharing class InnerClass{
        /**
         * @description get related orders
         * @param accountId id of the account
         * @return List<Order>
        */
        public List<Order> getRelatedOrders(id accountId){
            return [SELECT id,SBQQ__Quote__r.Manual_Fulfillment_Quote__c FROM ORDER WHERE Actual_Order_Ship_Date__c = LAST_90_DAYS AND ACcountId =: accountId AND Type = 'Revenue'];
        }
    }
 
}