/*
* @Author           :   Shiva Sharma
* @CreatedDate      :   
* @Trigger          :   DomainTrigger.trigger
* @TestClass        :   DomainTriggerHandlerTest.cls
* -------------------------- @History ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date                          Description
* CS21-886         Vijay Kumar K R        June 23 2022    Block non-corporate email domains from being added to "Allowed Support Portal Email Domains" list
* CS21-1218        Vijay Kumar K R        Aug 23, 2022    [Regression ] Prevent "rubrik.com" email domain from being added to whitelist domain
* CS21-1218        Vijay Kumar K R        Aug 26, 2022    Prevent "rubrik.com" email domain from being added to whitelist domain
* CS21-1311        Vijay Kumar K R        Oct 20, 2022    Bypass Domain Approval for Support Operations team (Shivani Naik, Kiet Duong, Joan Toralba and Likitha Y) the ability to manually update the domain list.
* ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
public class DomainTriggerHandler extends TriggerHandler{

    @TestVisible
    private static final string NON_RUBRIK_ACC_DOMAIN_ERR = System.Label.Non_Rubrik_Acc_Domain_Error;
    @TestVisible
    private static final string IGNORED_DOMAIN_NAME_ERR = System.Label.Ignored_Domain_Error_Msg;
    @TestVisible
    private static final string UNAUTHORIZED_USER_ERR = System.Label.Unauthorized_User_Allow_Domain_Error_Msg;
    @TestVisible
    private static final string DUPLICATE_DOMAIN_ERROR = System.Label.Duplicate_Domain_Error_Message;

    private static final string RUBRIK_ACC_NAME = 'Rubrik';
    private static final string RUBRIK_DOMAIN_NAME = 'rubrik.com';
    private static final String SUPP_OPE_USER_EMAIL_CUSTOM_LABEL = System.Label.Support_Operations_Team_User_Emails;

    protected override void beforeInsert() {
        checkDupDomainName();
    }

    protected override void beforeUpdate() {
        checkDupDomainName();
    }

    /**
     * @Author       :   Shiva Sharma
     * @Description  :   Avoiding insertion of duplicate WL_Domain__c records under Account
     * @Params       :   
     * @Rerurn       :   void
     */
    private void checkDupDomainName(){

        Id rubrikAccId = null;
        List<Account> rubrikAccList = new List<Account>();
        rubrikAccList = [SELECT Id FROM Account WHERE Name =: RUBRIK_ACC_NAME Limit 1];
        if(!rubrikAccList.isEmpty()){
            rubrikAccId = rubrikAccList[0].Id;
        }

        Set<Id> accIdSet = new Set<Id>();
        for(WL_Domain__c objDom : (List<WL_Domain__c>) Trigger.new){
            // True: when domain added through "Customer Registration Requests" Approval
            Boolean isApproved = objDom.isApproved__c;

            // throw Error When Non Support Operation users trying to add domain under any Account
            if(!SUPP_OPE_USER_EMAIL_CUSTOM_LABEL.containsIgnoreCase(UserInfo.getUserEmail())
                && !isApproved){
                objDom.addError(UNAUTHORIZED_USER_ERR);
            }
            // Filter non-corporate domain name for Accounts ('Rubrik' Account Excluded)
            else if(objDom.Account__c != rubrikAccId
                && String.valueOf(objDom.Name).equalsIgnoreCase(RUBRIK_DOMAIN_NAME)){
                    objDom.addError(NON_RUBRIK_ACC_DOMAIN_ERR);
            }
            else if(checkForignoredDomain(objDom) != null){
                objDom.addError(IGNORED_DOMAIN_NAME_ERR);
            }else{
                accIdSet.add(objDom.Account__c);
            }
        }

        Map<Id, List<String>> existingDomainsByAccIdMap = new Map<Id, List<String>>();
        for(WL_Domain__c objDom : [SELECT Name, Account__c
                                    FROM WL_Domain__c 
                                    WHERE Account__c IN: accIdSet]){
            if(!existingDomainsByAccIdMap.containsKey(objDom.Account__c)){
                existingDomainsByAccIdMap.put(objDom.Account__c, new List<String>());
            }
            existingDomainsByAccIdMap.get(objDom.Account__c).add(objDom.Name.toLowerCase());
        }

        processApprovedDomains(existingDomainsByAccIdMap);
    }

    /**
     * @Author       :   vijay.kr@rubrik.com
     * @CreatedDate  :   Aug 26, 2022
     * @Description  :   process only domain which are approved and unique records
     * @Params       :   Map<Id, List<String>> existingDomainsByAccIdMap
     * @Rerurn       :   null
     */
    private void processApprovedDomains(Map<Id, List<String>> existingDomainsByAccIdMap){
        
        if(!existingDomainsByAccIdMap.isEmpty()){
            for(WL_Domain__c objDom : (List<WL_Domain__c>) Trigger.new){

                if(isChanged('Name', objDom)
                    && existingDomainsByAccIdMap?.containsKey(objDom.Account__c)){
                        // throw Error When user try to add duplicate domain
                        if(existingDomainsByAccIdMap.get(objDom.Account__c).contains(objDom.Name.toLowerCase())){
                            objDom.addError(DUPLICATE_DOMAIN_ERROR);
                        }
                }
            }
        }
    }

    /**
     * @Author       :   vijay.kr@rubrik.com
     * @CreatedDate  :   June 23, 2022
     * @Description  :   Fetching Ignored_Domain__mdt record based on Label filter
     * @Params       :   WL_Domain__c objDom
     * @Rerurn       :   Ignored_Domain__mdt
     */
    private Ignored_Domain__mdt checkForignoredDomain(WL_Domain__c objDom){

        Ignored_Domain__mdt objIgDomain = null;
        try {
            objIgDomain = [SELECT Id, Label, isIgnored__c
                            FROM Ignored_Domain__mdt 
                            WHERE isIgnored__c = true
                                AND Label =: objDom.Name Limit 1];
        } catch (Exception e) {
            System.debug(System.LoggingLevel.ERROR,'Exception: '+e.getMessage());
        }
        return objIgDomain;
    }
}