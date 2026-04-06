/**
 * @description This helper class provides methods to handle various business logic related to Contact records,
 * triggered by Contact DML operations. It includes functionalities for updating contact fields,
 * managing entitlements, rolling up accreditation data, inserting contacts into campaigns,
 * handling primary mailing contacts, routing contacts, setting lead share expiration dates,
 * capturing owner profile changes, populating UTM terms, managing marketing opt-in/out,
 * setting privacy compliance flags, checking partner contacts, and calculating lead scores and MQL priority.
 */
public class ContactObjectTriggerHelper {
    private static Set<String> statusSet = new Set<String>{'Open', 'Working', 'Meeting Set', 'Active Opportunity (System Use)'};

    /**
     * @description Updates a list of Contact records. This method performs a DML update operation
     * on the provided list of contacts.
     * @param contactList List<Contact> - A list of Contact records to be updated.
     */
    public static void updateContacts(List<Contact> contactList){
        if(contactList != null && !contactList.isEmpty()){
            update contactList;
        }
    }

    /**
     * @description Performs various field updates on a Contact record, both for new creations and updates.
     * This includes setting trial end dates, updating MQL/Partner MQL flags, last MQL/SAL dates,
     * unMQL dates, contact reject reasons, and clearing status reasons based on business logic.
     * @param newContact Contact - The new version of the Contact record.
     * @param oldContact Contact - The old version of the Contact record. This will be null for insert operations.
     */
    public static void fieldUpdates(Contact newContact, Contact oldContact){
        if(oldContact == null){//New Contact Create
            if(newContact.Agreed_to_Edge_Trial_Agreement__c && newContact.trial_Edge_End_Date__c == null){
                newContact.trial_Edge_End_Date__c = System.today().addDays(30); 
            }
            // Code remove as part of MKT24-460//
            
        }else{// Update Contact Case
            if(newContact.Agreed_to_Edge_Trial_Agreement__c && newContact.trial_Edge_End_Date__c == null && !oldContact.Agreed_to_Edge_Trial_Agreement__c){
                newContact.trial_Edge_End_Date__c = System.today().addDays(30);
            }
            if(newContact.Contact_Status__c != oldContact.Contact_Status__c){
                if((newContact.MQL__c || newContact.Partner_MQL__c) && ('Nurture' == newContact.Contact_Status__c || 'Non-Qualified' == newContact.Contact_Status__c) ){
                    newContact.MQL__c = false;
                    newContact.Partner_MQL__c = false;
                    newContact.UnMQL_Date__c = Date.today();
                }
            }
            // Code remove as part of MKT24-460//
            if((!oldContact.MQL__c && newContact.MQL__c) || (!oldContact.Partner_MQL__c && newContact.Partner_MQL__c)){
                newContact.Last_MQL_Date__c = system.today();
                newContact.Touches_since_MQL__c = 0;
            }
            if((oldContact.MQL__c && !newContact.MQL__c) || (oldContact.Partner_MQL__c && !newContact.Partner_MQL__c)){
                newContact.UnMQL_Date__c = system.today();
            }
            if(oldContact.contact_status__c == 'Open' && (newContact.contact_status__c == 'Working' || newContact.contact_status__c == 'Meeting Set') && !newContact.SAL__c){
                newContact.SAL__c = true;
            }
            if(!oldContact.SAL__c && newContact.SAL__c){
                newContact.Last_SAL_Date__c = system.today();
            }
            if(oldContact.Contact_Status__c != newContact.contact_status__c && newContact.contact_status__c == 'Nurture' && newContact.ContactRejectReason__c == null){
                newContact.ContactRejectReason__c = 'Automated unMQL (Admin Only)';
            }
        }
        /*
            WF- Rule Name: CFCR Clear Status Reason
            Description: When the Status changes from an inactive status back to an active status, the Status Reason field is cleared in order to capture a new Status Reason if it becomes inactive again. (Status Reason is captured on Campaign Member also).
            Criteria: (Contact: Contact StatusSTARTS WITHOpen,Working,Meeting Set,Active Opportunity (System Use)) AND (Contact: Status ReasonNOT EQUAL TOnull)
            FieldUpdate: Contact: Status Reason = null
            Evaluate the rule when a record is created, and any time it's edited to subsequently meet criteria
        */
        newContact.CFCR_Status_Reason__c = (String.isNotBlank(newContact.CFCR_Status_Reason__c) && statusSet.contains(newContact.Contact_Status__c)) ? null : newContact.CFCR_Status_Reason__c;
        /*
            WF- Rule Name: Contact Agreed to POC terms Date
            Description: SAL-173: Update Agree to Edge Trial Date
            Criteria: Contact: Agreed to Edge Trial AgreementEQUALSTrue
            FieldUpdate: Contact: Agree to Edge Trial Date = Today
            Evaluate the rule when a record is created, and any time it's edited to subsequently meet criteria
        */
        newContact.Agree_to_Edge_Trial_Date__c = (newContact.Agreed_to_Edge_Trial_Agreement__c && (oldContact == null || (!oldContact.Agreed_to_Edge_Trial_Agreement__c))) ? System.today() : newContact.Agree_to_Edge_Trial_Date__c;
        /*
            WF- Rule Name: Set Nurture Timeout
            Description: When a contact is set to nurture - set nurture timeout based on nurture timeout via field update (Formula Commented in, includes field update formula - Adjust for organization status values)
            Criteria: Contact: Contact StatusEQUALSNurture,Nurture,Non-Qualified
            FieldUpdate: Contact: Nurture Timeout = CASE(TEXT(Contact_Status__c), ""Nurture"", Last_MQL_Date__c + 30,
            ""Nurture"",Last_MQL_Date__c + 30,
            ""Non-Qualified"",Last_MQL_Date__c + 30, FCRM__FCR_Nurture_Timeout__c)
            "
            Evaluate the rule when a record is created, and any time it's edited to subsequently meet criteria
        */
        if( newContact.Last_MQL_Date__c != null && (newContact.Contact_Status__c == 'Nurture' || newContact.Contact_Status__c == 'Non-Qualified') ){
            newContact.FCRM__FCR_Nurture_Timeout__c = newContact.Last_MQL_Date__c + 30;
        }
    }

    //Commented as a part PRIT25-575 and 639. Code moved to UserTriggerHandler
    /*public static void updatePartnerRegRequest(Map<String,Contact> newEmailContactMap){
        if(!newEmailContactMap.isEmpty()){
            List<Partner_Registration_Request__c> partnerRegRequestListToUpdate = new List<Partner_Registration_Request__c>();
            List<Partner_Registration_Request__c> partnerRegRequestList = [select id, Email__c,is_Converted__c,Related_Partner_Contact__c from Partner_Registration_Request__c where email__c=:newEmailContactMap.keySet() order by createddate desc];
            Set<String> emailSet = new Set<String>();
            for(Partner_Registration_Request__c pr: partnerRegRequestList){
                if(!emailSet.contains(pr.Email__c.toLowerCase())){
                    emailSet.add(pr.Email__c.toLowerCase());
                    pr.is_Converted__c=true;
                    pr.Related_Partner_Contact__c = newEmailContactMap.containsKey(pr.Email__c)?newEmailContactMap.get(pr.Email__c).Id:null;
                    pr.Partner_Account_Lookup__c = newEmailContactMap.containsKey(pr.Email__c)?newEmailContactMap.get(pr.Email__c).AccountId:null;
                    partnerRegRequestListToUpdate.add(pr);
                }
            }
            if(!partnerRegRequestListToUpdate.isEmpty()){
                update partnerRegRequestListToUpdate;
            }
        }
    }*/

    /**
     * @description Manages the creation of Entitlement records for Contacts with 'Agreed to Edge Trial Agreement'.
     * An entitlement is created if an active 'EVALUATION-EDGE-TRIAL' entitlement does not already exist
     * for the Contact's Account.
     * @param newContactList List<Contact> - A list of new Contact records.
     * @param accIds Set<ID> - A set of Account IDs related to the Contacts in `newContactList`.
     */
    public static void manageEntitlement(List<Contact> newContactList, Set<ID> accIds){
        if(accIds.isEmpty()) return;
        Map<id,Integer> activeEntitlementMap = new Map<id,Integer>();
        Map<id,Account> accountMap = new Map<id,Account>([select id,Agreed_to_Edge_Trial_Agreement__c from Account where id IN: accIds]);
        List<Entitlement> entitlementList = new List<Entitlement>();
        List<Product2> proList = [select id,name from Product2 where name='EVALUATION-EDGE-TRIAL' LIMIT 1];
        Product2 pro = new Product2();
        if(!proList.isEmpty()){
            pro = proList[0];
        }
        for(Entitlement et : [SELECT id,account.Type,AccountId,Status from Entitlement where AccountId IN : accountMap.keyset() AND Status = 'Active' AND Product__c =: pro.Id ]){
            if(!activeEntitlementMap.containsKey(et.AccountId)){
                activeEntitlementMap.put(et.AccountId,0);
            }
            activeEntitlementMap.put(et.AccountId,activeEntitlementMap.get(et.AccountId)+1);
        }
        for(Contact con : newContactList){
            if(con.Agreed_to_Edge_Trial_Agreement__c && accIds.contains(con.AccountId) && !activeEntitlementMap.containsKey(con.AccountId)){
                entitlementList.add(new Entitlement(Name = Pro.Name,AccountId = con.AccountId,Product__c = pro.id, StartDate = System.today() , EndDate =  System.today().addDays(30)));
            }
        }
        if(!entitlementList.isEmpty()){
            insert entitlementList;
        }
    }


    /**
     * @description Rolls up accredited contact counts to their respective Account records.
     * It queries `Accreditions_scoring_setting__mdt` custom metadata to determine
     * which Contact certification fields map to Account rollup fields.
     * @param lstContact List<Contact> - A list of new or updated Contact records.
     * @param oldConMap Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
    public static void rollupAccrediated(List<Contact> lstContact, Map<Id, Contact> oldConMap){
        List<Accreditions_scoring_setting__mdt> accrSettings = [SELECT MasterLabel, Contact_Certification_Achieved_field__c, Contact_Accreditation_Expiry_Field__c, Account_Rollup_field__c
                                                                FROM Accreditions_scoring_setting__mdt];
        Map<Id, Map<String, Integer>> accountAddRollup = new Map<Id, Map<String, Integer>>();
        for(Contact cRec : lstContact){
            for(Accreditions_scoring_setting__mdt accrSetting : accrSettings){
                //TODO:  check for expiry dates updates too
                if( cRec.get(accrSetting.Contact_Certification_Achieved_field__c) != oldConMap.get(cRec.Id).get(accrSetting.Contact_Certification_Achieved_field__c)){
                    if(accountAddRollup.containsKey(cRec.AccountId)){
                        if(accountAddRollup.get(cRec.AccountId).containsKey(accrSetting.Account_Rollup_field__c)){
                            Integer temp = accountAddRollup.get(cRec.AccountId).get(accrSetting.Account_Rollup_field__c);
                            accountAddRollup.get(cRec.AccountId).put(accrSetting.Account_Rollup_field__c, temp+1);
                        }
                        else
                            accountAddRollup.get(cRec.AccountId).put(accrSetting.Account_Rollup_field__c, 1);
                    }
                    else
                        accountAddRollup.put(cRec.AccountId, new Map<String, Integer>{accrSetting.Account_Rollup_field__c => 1});
                }
            }
        }
        if(!accountAddRollup.isEmpty()) {
            Set<Id> accountIds = accountAddRollup.keySet();
            String query;
            query = 'SELECT Id';
            for(Accreditions_scoring_setting__mdt accrSetting : accrSettings){
                query+=(','+accrSetting.Account_Rollup_field__c);
            }
            query+= ' FROM Account WHERE Id IN :accountIds';
            String q = String.escapeSingleQuotes(query);
            System.debug(LoggingLevel.DEBUG,'query:'+q);
            Map<Id, SObject> accountIdToAccount = new Map<Id, SObject>(Database.query(q));

            List<Account> updateAccounts = new List<Account>();
            for(Id accountId : accountAddRollup.keySet()) {
                Account acc = (Account)accountIdToAccount.get(accountId);
                for(String rollupField : accountAddRollup.get(accountId).keySet()) {
                    Integer currentcount = Integer.valueOf(acc.get(rollupField));
                    Integer increament = accountAddRollup.get(accountId).get(rollupField);
                    acc.put(rollupField, currentcount==null?increament:currentcount+increament);
                }
                updateAccounts.add(acc);
            }
            update updateAccounts;
        }
    }

    /**
     * @description Inserts Contacts into a specific Campaign based on their 'Salesloft_Cadence_Most_Recent__c' field
     * and if they are not already members of the campaign.
     * @param newcontactList List<Contact> - A list of new Contact records.
     * @param oldContactMap Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     * @param isInsert boolean - A flag indicating if the trigger context is an insert operation (true) or an update (false).
     */
    public static void insertContactIntoCampaign(List<Contact> newcontactList, Map<Id, Contact> oldContactMap, boolean isInsert){
        String campId = System.Label.CampaignId;
        List<Id> existingContactIdList = new List<Id>();
        List<CampaignMember> campaignMemberInsertList = new List<CampaignMember>();
        if(campId != null){
            List<CampaignMember> campaignMemberList = new List<CampaignMember>([Select Id,ContactId from CampaignMember where CampaignId = :campId]);
            for(CampaignMember cm : campaignMemberList){
                if(cm.ContactId != null)
                    existingContactIdList.add(cm.ContactId);
            }
        }
        for (Contact con : newContactList){
            if(isInsert && con.Salesloft_Cadence_Most_Recent__c != null && con.Salesloft_Cadence_Most_Recent__c.contains(System.label.CampaignMatchingString) && !existingContactIdList.contains(con.id)){
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = campId;
                cm.ContactId = con.Id;
                cm.status = 'Filled-out Form';
                campaignMemberInsertList.add(cm);
            }else if(!isInsert && con.Salesloft_Cadence_Most_Recent__c != null && con.Salesloft_Cadence_Most_Recent__c.contains(System.label.CampaignMatchingString) && con.Salesloft_Cadence_Most_Recent__c != oldContactMap.get(con.Id).Salesloft_Cadence_Most_Recent__c && !existingContactIdList.contains(con.id)){
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = campId;
                cm.ContactId = con.Id;
                cm.status = 'Filled-out Form';
                campaignMemberInsertList.add(cm);
            }
        }

        //try{
            if(!campaignMemberInsertList.isEmpty()){
                insert campaignMemberInsertList;
            }
            /*
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }*/
    }

        //Change by Aneeja on 19-07-01
    //SF-2052 Rollup onto the Account in a new field called “PSE Shadow Completed” the number of Contacts
    //who have a date in both “PSE Shadow 1 Completed” AND “PSE Shadow 2 Completed”
    /**
     * @description Rolls up the count of Contacts with both 'PSE Shadow Completed' and 'PSE Shadow 2 Completed' dates
     * to the 'PSE_Shadow_Completed__c' field on their respective Account. It also updates the 'Agreed_to_Edge_Trial_Agreement__c'
     * field on the Account if a related Contact has this flag set to true.
     * @param newcontactList List<Contact> - A list of new Contact records.
     * @param oldContactMap Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys. This will be null for insert operations.
     */
    public static void rollUpOnAccToCon(List<Contact> newcontactList, Map<Id, Contact> oldContactMap){
        Set<ID> acctIds = new Set<ID>();
        Set<Id> accountIdForEdgeTrialSet = new Set<Id>();
        if(oldContactMap == null){//Insert
            for (Contact con : newcontactList) {
                if(con.PSE_Shadow_Completed__c != null && con.PSE_Shadow_2_Completed__c != null){
                    acctIds.add(con.AccountId);
                }
                //CS21-1112 : Added logic to collect Account Ids for Contacts created with Agree to Edge Trial Agreement flag true
                if(con.Agreed_to_Edge_Trial_Agreement__c && con.AccountId != null){
                    accountIdForEdgeTrialSet.add(con.AccountId);
                }
            }
        }else if(newcontactList != null){//Update
            for(Contact con : newcontactList) {
                if(con.PSE_Shadow_Completed__c != oldContactMap.get(con.id).PSE_Shadow_Completed__c || con.PSE_Shadow_2_Completed__c != oldContactMap.get(con.id).PSE_Shadow_2_Completed__c){
                    acctIds.add(con.AccountId);
                }
                //CS21-1112 : Added logic to collect Account Ids for Contacts updated with Agree to Edge Trial Agreement flag to true
                if(con.Agreed_to_Edge_Trial_Agreement__c && !oldContactMap.get(con.Id).Agreed_to_Edge_Trial_Agreement__c && con.AccountId != null){
                    accountIdForEdgeTrialSet.add(con.AccountId);
                }
            }
        }else{//delete
            for(Contact con : oldContactMap.values()) {
                if(con.PSE_Shadow_Completed__c != null && con.PSE_Shadow_2_Completed__c != null){
                    acctIds.add(con.AccountId);
                }
            }
        }
        acctIds.remove(null);
        if(!acctIds.isEmpty() || !accountIdForEdgeTrialSet.isEmpty()){
            //CS21-1112 : Added Agreed_to_Edge_Trial_Agreement__c to the Account query and Id filter
            List<Account> acctsToUpdate = new List<Account>([SELECT Id, PSE_Shadow_Completed__c, Agreed_to_Edge_Trial_Agreement__c,
                                                            (SELECT Id, AccountId FROM Contacts
                                                            WHERE PSE_Shadow_Completed__c != null AND PSE_Shadow_2_Completed__c != null)
                                                            FROM Account
                                                            WHERE Id in :acctIds
                                                            OR (Id IN :accountIdForEdgeTrialSet AND Agreed_to_Edge_Trial_Agreement__c = false)]);
            List<Account> updateAccountList = new List<Account>();
            // for each Account, iterate over all accounts and count related contacts with date in both PSE Shadow 1/2 Completed
            for (Account acct : acctsToUpdate) {
                if(acctIds.contains(acct.Id) && (acct.getSObjects('Contacts') == null || acct.PSE_Shadow_Completed__c != acct.getSObjects('Contacts').size())){
                    acct.PSE_Shadow_Completed__c = acct.getSObjects('Contacts') == null ? null : acct.getSObjects('Contacts').size();
                    updateAccountList.add(acct);
                }
                //CS21-1112 : Added logic to update Account with Agreed to Edge Trial Agreement flag true
                if(accountIdForEdgeTrialSet.contains(acct.Id)){
                    acct.Agreed_to_Edge_Trial_Agreement__c = true;
                    updateAccountList.add(acct);
                }
            }
            if(!updateAccountList.isEmpty()){
                boolean tempFlag = flowControll.accountTrigger;
                flowControll.accountTrigger = false;
                System.debug(LoggingLevel.DEBUG, '\nBefore update, Is Account Trigger blocked? :' + flowControll.accountTrigger );
                update acctsToUpdate;
                flowControll.accountTrigger = tempFlag;
                System.debug(LoggingLevel.DEBUG, '\nAfter update, Is Account Trigger blocked? :' + flowControll.accountTrigger );
            }
        }
    }

    /**
     * @description Creates a new User record with a 'Trial_Edge_Profile' for Contacts
     * if a User with the Contact's email does not already exist. This method runs asynchronously.
     * @param contactIdList Set<Id> - A set of Contact record Ids for which to potentially create Trial Edge Users.
     */
    @future
    public static void trialEdgeContact(Set<Id> contactIdList){
        List<User> usrList = new List<User>();
        //try{
            List<Contact> conList = [select FirstName ,LastName ,Email ,Title ,Phone ,Id from Contact where Id = : contactIdList];
            List<String> emailList = new List<String>();
            for(Contact con : conList){
                emailList.add(con.Email);
            }
            List<String> userWithEmail = new List<String>();
            for(User u : [SELECT id,UserName from User where username IN: emailList ]){
                userWithEmail.add(u.UserName); 
            }
            System.debug(LoggingLevel.DEBUG, userWithEmail);
            List<User> usrUpdate = new List<User>();
            for(Contact con : conList){
                if(!userWithEmail.contains(con.Email)){
                    Double rnd =  Integer.valueOf( Math.Round( Math.random()*100000000));
                    Long Ln = Math.roundToLong(rnd);
                    Integer intVal = Integer.valueOf(Ln);
                    User usr = new User();
                    usr.FirstName = con.FirstName;
                    usr.LastName = con.LastName;
                    usr.Title = con.Title;
                    usr.Email = con.Email;
                    usr.Phone = con.Phone;
                    usr.ContactId = con.Id;
                    usr.profileid = Label.Trial_Edge_Profile;
                    String nameString = con.FirstName.substring(0,1) +' '+ con.LastName.substring(0,1)+' '+intVal;
                    nameString = nameString.trim();
                    nameString = nameString.substring(0, 7);
                    usr.Username = con.Email;
                    String nickName =  con.FirstName +'.'+ con.LastName+'-'+System.now().formatGMT('MMddyy-HHmm');
                    if(nickName.length() > 40){
                        nickName = con.FirstName.substring(0,1) +'.'+ con.LastName.substring(0,1)+'-'+System.now().formatGMT('MMddyy-HHmm');
                    }
                    usr.CommunityNickname = nickName;
                    usr.Alias =  nameString;
                    usr.TimeZoneSidKey = 'America/Phoenix';
                    usr.LocaleSidKey = 'en_US';
                    usr.EmailEncodingKey = 'ISO-8859-1';
                    usr.LanguageLocaleKey = 'en_US';
                    usrList.add(usr);
                }

            }
            System.debug(LoggingLevel.DEBUG, usrList);
            if(!usrList.isEmpty())
                insert usrList;
    }

    /**
     * @description Ensures that an Account cannot have more than two Contacts marked as 'Primary Customer Mailing Contact'.
     * If an attempt is made to set more than two, an error is added to the Contact record.
     * @param newContacts List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContacts Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys. This will be null for insert operations.
     */
    public static void allowMax2PrimaryContactMail(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        Map<Id, List<Contact>> accountIdsToContact = new Map<Id, List<Contact>>();
        for(Contact con: newContacts){
            if(con.Primary_Customer_Mailing_Contact__c
                && (
                    oldContacts == null
                    || con.Primary_Customer_Mailing_Contact__c != oldContacts.get(con.Id).Primary_Customer_Mailing_Contact__c
                )
            ){
                if(!accountIdsToContact.containsKey(con.AccountId)){
                    accountIdsToContact.put(con.AccountId, new List<Contact>{});
                }
                accountIdsToContact.get(con.AccountId).add(con);

            }
        }
        if(!accountIdsToContact.isEmpty()){
            for(AggregateResult ar : [SELECT AccountId, count(Id) FROM Contact WHERE AccountId IN :accountIdsToContact.keySet() AND Primary_Customer_Mailing_Contact__c=true GROUP BY AccountId]){
                if(Integer.valueOF(ar.get('expr0'))>=2){
                    for(Contact con : accountIdsToContact.get((Id)ar.get('AccountId'))){
                        con.addError('Cannot add more than 2 primary customer mailing contacts on an account');
                    }
                }
            }
        }
    }
    /**
     * @description Determines if a Contact's Composite Score (FCI Admin Score) needs to be updated.
     * This method identifies contacts where `Composite_Score1__c` is null or less than 10,
     * and where relevant score-contributing fields (defined in 'EinsteinScoreModelFieldsContact' metadata)
     * have changed from their old values. If such contacts are found, `updateContactCompositeScore` is called.
     * @param mapTriggerNew Map<Id, Contact> - A map of the new versions of Contact records, with their IDs as keys.
     * @param mapTriggerOld Map<Id, Contact> - A map of the old versions of Contact records, with their IDs as keys.
     */
    public static void setFCIAdminScore(Map<Id, Contact> mapTriggerNew, Map<Id, Contact> mapTriggerOld) {
        Set<Id> setContactds = new Set<Id>();
        Set<String> contactScoreFields = new Set<String>();
        for(Key_Value__mdt  keyValuePair: [SELECT Value__c FROM Key_Value__mdt
                                            WHERE MasterLabel = 'EinsteinScoreModelFieldsContact'
                                            AND Key__c = 'Contact']) {
            contactScoreFields.add(keyValuePair.Value__c);
        }
        for( COntact newContact: mapTriggerNew.values() ) {
            Contact oldContact = mapTriggerOld.get( newContact.Id );
            if(oldContact.Composite_Score1__c==null || oldContact.Composite_Score1__c < 10) {
                for(String contactScoreField : contactScoreFields){
                    if(newContact.get(contactScoreField) != oldContact.get(contactScoreField)){
                        setContactds.add( newContact.Id );
                        break;
                    }
                }
            }
        }
        if( !setContactds.isEmpty()) {
            updateContactCompositeScore(new List<Id>(setContactds));
        }
    }

    /**
     * @description Asynchronously updates the Composite Score for a list of Contacts using
     * the Einstein Smart Data Discovery `predict` API. It fetches a prediction for each contact
     * based on a predefined composite score model. If the predicted score (`total`) is 10 or greater,
     * the Contact's `CFCR_Admin_Score_Increment__c` and `CFCR_Admin_Score_Increment_Audit__c` fields are updated.
     * Any errors during the prediction process are logged in `Custom_Error_Log__c`.
     * This method is designed to be called from a trigger context and runs in a future method.
     * @param lstContactIds List<Id> - A list of Contact IDs for which to update the composite score.
     */
    @future @TestVisible
    private static void updateContactCompositeScore(List<Id> lstContactIds) {
        System.debug(LoggingLevel.DEBUG, '#ContactObjectTriggerHelper#updateContactCompositeScore#lstContactIds:'+lstContactIds);
        Id compositeScoreId = '1OR6f000000PAu4GAG';
        List<Id> updateContactIds = new List<Id>();
        Integer index = 0;
        List<Custom_Error_Log__c> errors = new List<Custom_Error_Log__c>();

          ConnectApi.SmartDataDiscoveryPredictInputRecords predictInput = new ConnectApi.SmartDataDiscoveryPredictInputRecords();
          predictInput.predictionDefinition = compositeScoreId;
          predictInput.records = lstContactIds;

          if(!Test.isRunningTest()){
              ConnectApi.SmartDataDiscoveryPrediction response = ConnectApi.SmartDataDiscovery.predict(predictInput);
            for( Object genObject : response.predictions) {
                    try {
                        ConnectApi.SmartDataDiscoveryPredictObject predictionObject = (ConnectApi.SmartDataDiscoveryPredictObject)genObject;
                        ConnectApi.SmartDataDiscoveryPredict predictData = (ConnectApi.SmartDataDiscoveryPredict)(predictionObject.prediction);
                        System.debug(LoggingLevel.DEBUG, '#ContactObjectTriggerHelper#updateContactCompositeScore#predictData:'+predictData);
                        if(predictData.total >=10){
                            updateContactIds.add(lstContactIds[index]);
                        }

                    }catch(TypeException te){
                        ConnectApi.SmartDataDiscoveryPredictErrorObject connectApierror = (ConnectApi.SmartDataDiscoveryPredictErrorObject)genObject;
                        Custom_Error_Log__c errorLog = new Custom_Error_Log__c(Class__c = 'ContactObjectTriggerHelper',
                                                                                Type__c='Internal',
                                                                                Functionality__c ='Contact score update',
                                                                                ErrorTrace__c = te.getStackTraceString(),
                                                                                Exception_Message__c = connectApierror.message,
                                                                                Result__c = 'Salesforce Exception',
                                                                                FailedRecords__c = lstContactIds[index]
                                                                                );
                        errors.add(errorLog);
                    }

            }

            index++;
          } else {
              updateContactIds.addall(lstContactIds);
          }

        if(!updateContactIds.isEmpty()){
            List<Contact> updateContact = new List<Contact>();
            for(Contact objContact : [SELECT Id, CFCR_Admin_Score_Increment__c FROM COntact WHERE Id IN :lstContactIds]){
                objContact.CFCR_Admin_Score_Increment__c = ( objContact.CFCR_Admin_Score_Increment__c == null ) ? 1: ( objContact.CFCR_Admin_Score_Increment__c == 1 ? 2 : 1 );
                objContact.CFCR_Admin_Score_Increment_Audit__c = Datetime.now();
                updateContact.add(objContact);
            }
            update updateContact;
        }
        if(!errors.isEmpty()){
            insert errors;
    }
    }
    /**
     * @description Routes Contacts based on specific criteria, such as changes in MQL/Partner MQL status
     * or the 'ReRoute_Contact__c' flag, and if the Campaign Source is 'Marketing' or 'Partner'.
     * This method enqueues an asynchronous job (`RouteContactClass`) to handle the routing.
     * @param newContacts List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContacts Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
    public static void routeContacts(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Contact> contactIdToContact = new Map<Id, Contact>();
        Map<Id, Boolean> mapIdWithFalseFallback = new Map<Id, Boolean>();
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact con : newContacts) {
            if ((con.MQL__c && !oldContacts.get(con.Id).MQL__c)
                || (con.Partner_MQL__c && !oldContacts.get(con.Id).Partner_MQL__c)
                || (con.ReRoute_Contact__c && con.ReRoute_Contact__c != oldContacts.get(con.Id).ReRoute_Contact__c))
            {
                contactIds.add(con.Id);
                contactIdToContact.put(con.Id, con);
                mapIdWithFalseFallback.put(con.Id, false);
            }
        }
        
        if (!contactIds.isEmpty()) {
            for (CampaignMember cmpMem : [SELECT Id, Campaign.Routing_Method__c, CampaignId, ContactId FROM CampaignMember 
                                          WHERE ContactId IN :contactIds AND 
                                          CFCR_Current_Stage_in_Funnel__c IN ('Meeting Set', 'MQL', 'Inside Sales Accepted Lead')]){   
                if (contactIdToContact.containsKey(cmpMem.ContactId)) {
                    Contact con = new Contact(Id = cmpMem.ContactId);
                    con.Last_Applied_Routing_Modifier__c = cmpMem.Campaign.Routing_Method__c;
                    contactsToUpdate.add(con);
                }
            }

            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
            }

            ID jobID = System.enqueueJob(new RouteContactClass(contactIds, contactIdToContact, mapIdWithFalseFallback));
            System.debug(LoggingLevel.DEBUG, 'jobID: ' + jobID);
        }
    }

    /**
     * @description Sets or updates the 'Lead_Share_Program_Expiration_Date__c' for Contacts.
     * The expiration date is set based on MQL status, routing modifier, and partner of record.
     * It's also adjusted if a meeting date is set and within a specific threshold of the expiration date.
     * @param newContacts List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContacts Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
    public static void setLeadShareExpirationDate(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        for(Contact con : newContacts){
            if(oldContacts.get(con.Id).MQL__c != con.MQL__c && con.MQL__c && con.Last_Applied_Routing_Modifier__c == 'Route to Partner' && con.Partner_of_Record__c != null){
                con.Lead_Share_Program_Expiration_Date__c = system.today() + 90;
            }
            
            if(con.Lead_Share_Program_Expiration_Date__c != null && con.MeetingDate__c !=null && oldContacts.get(con.Id).MeetingDate__c != con.MeetingDate__c){
                Date meetingDate = date.newinstance(con.MeetingDate__c.year(), con.MeetingDate__c.month(), con.MeetingDate__c.day());
                if(con.Lead_Share_Program_Expiration_Date__c  <= meetingDate.addDays(5)){
                    con.Lead_Share_Program_Expiration_Date__c = meetingDate + 5 ;
                }
            }
        }
    }

    /**
     * @description Captures the name of the Profile of the User who last changed the ownership of a Contact record.
     * @param newContactList List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContactMap Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
    public static void captureOwnerProfile (List<Contact> newContactList, Map<Id,Contact> oldContactMap) {
        
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id =: userinfo.getProfileId() LIMIT 1];
        for(Contact con : newContactList){
            if(oldContactMap.get(con.Id).ownerId != con.ownerId){ 
                con.Last_Ownership_Changed_Profile__c = currentProfile.Name; 
            }
        }
    }

    /**
     * @description Populates the 'Latest_UTM_Term__c' and 'Last_UTM_Term_Date__c' fields on a Contact
     * when the 'UTM_Term__c' field is updated and matches an entry in `BDMRoutingConfiguration__mdt`.
     * @param newContacts List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContacts Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
   public static void populateUTMTerm(List<Contact> newContact, Map<Id, Contact> oldContactMap) {
    Map<String, BDMRoutingConfiguration__mdt> UTMSourceConfig = null;

    for (Contact objContact : newContact) {

        Boolean utmChanged = false;

        if (oldContactMap == null) {
            utmChanged = true;
        } else {
            Contact oldContact = oldContactMap.get(objContact.Id);
            utmChanged =
                objContact.UTM_Campaign__c != oldContact.UTM_Campaign__c ||
                objContact.UTM_Medium__c   != oldContact.UTM_Medium__c ||
                objContact.UTM_Partner__c  != oldContact.UTM_Partner__c ||
                objContact.UTM_Source__c   != oldContact.UTM_Source__c ||
                objContact.UTM_Content__c  != oldContact.UTM_Content__c ||
                objContact.UTM_Term__c     != oldContact.UTM_Term__c ||
                objContact.UTM_Type__c     != oldContact.UTM_Type__c;
        }

        if (objContact.UTM_Term__c != null &&
            (oldContactMap == null || oldContactMap.get(objContact.Id).UTM_Term__c != objContact.UTM_Term__c)) {
            if (UTMSourceConfig == null) {
                    UTMSourceConfig = RoutingUtil.getBDMDefaultUserDetails();
                }
            if (UTMSourceConfig.containsKey(objContact.UTM_Term__c)) {
                    objContact.Latest_UTM_Term__c = objContact.UTM_Term__c;
                    objContact.Last_UTM_Term_Date__c = Date.today();
                }
            }

        if (utmChanged) {
            String utmString = '';

            if (objContact.UTM_Campaign__c != null)
                utmString += 'utm_campaign=' + objContact.UTM_Campaign__c + '& ';
            if (objContact.UTM_Medium__c != null)
                utmString += 'utm_medium=' + objContact.UTM_Medium__c + '& ';
            if (objContact.UTM_Partner__c != null)
                utmString += 'utm_partner=' + objContact.UTM_Partner__c + '& ';
            if (objContact.UTM_Source__c != null)
                utmString += 'utm_source=' + objContact.UTM_Source__c + '& ';
            if (objContact.UTM_Content__c != null)
                utmString += 'utm_content=' + objContact.UTM_Content__c + '& ';
            if (objContact.UTM_Term__c != null)
                utmString += 'utm_term=' + objContact.UTM_Term__c + '& ';
            if (objContact.UTM_Type__c != null)
                utmString += 'utm_type=' + objContact.UTM_Type__c + '& ';

            if (utmString.endsWith('&')) {
                utmString = utmString.substring(0, utmString.length() - 1);
    }

            if (!String.isBlank(utmString)) {
                objContact.Last_UTM_String__c = utmString;
            }
        }
    }
}
    /**
     * @description Sets the 'Marketing_Opt_Out_Date__c' or 'Marketing_Opt_In_Date__c' fields on a Contact
     * based on changes to 'HasOptedOutOfEmail' or 'Email_Opt_In__c' respectively.
     * @param newContacts List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContacts Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
    public static void setMarketingOptInAndOut(List<Contact> newContact, Map<Id, Contact> oldContactMap){
        for(Contact con : newContact){
            if((oldContactMap == null  || (oldContactMap != null && con.HasOptedOutOfEmail != oldContactMap.get(con.Id).HasOptedOutOfEmail) && con.HasOptedOutOfEmail)){
                con.Marketing_Opt_Out_Date__c = System.now();
            }
            if((oldContactMap == null || (oldContactMap != null && con.Email_Opt_In__c != oldContactMap.get(con.Id).Email_Opt_In__c) && con.Email_Opt_In__c)){
                con.Marketing_Opt_In_Date__c = System.now();
            }
        } 
    }

    /**
     * @description Determines and sets the 'Limited_Use__c' flag on Contact records based on their
     * email opt-in status, mailing country, and lead source, referencing custom metadata.
     * @param newContactRecords List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContactMap Map<Id, Contact> - A map of old Contact records (before update) with their Ids as keys.
     */
    public static void setPrivacyCompliance(List<Contact> newContactRecords, Map<Id, Contact> oldContactMap){
        Set<String> setOfDirectLeadSources = new Set<String>();
        Set<String> setOfOptedInCountries = new Set<String>();
        for(Direct_and_Indirect_Lead_Source__mdt leadSourceMDt: [SELECT MasterLabel, Direct_Lead_Source__c FROM Direct_and_Indirect_Lead_Source__mdt WHERE Direct_Lead_Source__c= true]){
            setOfDirectLeadSources.add(leadSourceMDt.MasterLabel.deleteWhiteSpace());
        }
        for(Privacy_Opted_Countries__mdt countryOptMDt: [SELECT Country_Code__c FROM Privacy_Opted_Countries__mdt WHERE Privacy_Opt_In__c = true]){
        	setOfOptedInCountries.add(countryOptMDt.Country_Code__c);
        }
        for(Contact con : newContactRecords){
            
            Contact oldCon = (oldContactMap != null) ? oldContactMap.get(con.Id) : null;

            if(oldContactMap == null 
               || con.MailingCountryCode != oldCon.MailingCountryCode
               || con.Email_Opt_In__c != oldCon.Email_Opt_In__c
               || con.HasOptedOutOfEmail != oldCon.HasOptedOutOfEmail
               || con.LeadSource != oldCon.LeadSource
               || con.Re_compute_Data_Use_Permitted__c != oldCon.Re_compute_Data_Use_Permitted__c){
                   
                if(!con.HasOptedOutOfEmail){
                       if(con.Email_Opt_In__c ||( con.LeadSource !=null && setOfDirectLeadSources.contains(con.LeadSource.deleteWhiteSpace()))){                           
                           con.Data_Use_Permitted__c = true;                           
                       } else {                           
                         con.Data_Use_Permitted__c = false;                           
                    }
                }else{
                       con.Data_Use_Permitted__c = false;                       
                }
               
            }
            con.Data_Use_Permitted__c = (con.MailingCountryCode == 'CN') ? false : con.Data_Use_Permitted__c;
            con.Re_compute_Data_Use_Permitted__c = false;
        }

    }

    /**
     * @description Checks if the provided Contact IDs are associated with 'PowerPartner' Users
     * and, if so, calls `ContactService.updateUserCompany` to update the user's company information.
     * @param conIds List<Id> - A list of Contact record Ids to check.
     */
    public static void checkPartnerContacts(List<Id> conIds)
    {
        List<Id> finalContactIds = new List<Id>();
        for(User u : [SELECT Id, ContactId, UserType FROM User WHERE ContactId IN:conIds AND UserType = 'PowerPartner'])
        {
            finalContactIds.add(u.ContactId);
        }
        if(!finalContactIds.isEmpty()){
            ContactService.updateUserCompany(finalContactIds);
        }
    }

   /* //SAL25-355
    @future
    public static void updateEmailBouncedFlagFuture(Set<Id> conIds) {
        updateEmailBouncedFlag(conIds);
    }
    public static void updateEmailBouncedFlag(Set<Id> conIds) {
        List<Contact> updateContactList = new List<Contact>();
        for(Id cId :conIds){
            Contact con = new Contact(Id=cId, EmailBouncedReason = null, EmailBouncedDate = null);
            updateContactList.add(con);
        }
        if(!updateContactList.isEmpty()){
            flowControll.contactTrigger = false;
            List<Database.SaveResult> srList = Database.update(updateContactList, false);
            LogError.createDMLErrorLog((List<SObject>)updateContactList, srList, 'ContactObjectTriggerHelper','Update Contact Emailbounced Flag');
            flowControll.contactTrigger = true;
        }
    }*/


    /**
     * @description Calculates the lead score for a list of new or updated Contact records.
     * The score is derived from various factors including job function, job level,
     * engagement scores (P0, P1, P2, P3), and account attributes like buying stage and tier.
     * The `Update_Lead_Score__c` flag on the Contact is reset after calculation.
     *
     * @param newContactRecords List<Contact> - The list of Contact records being inserted or updated.
     * @param oldContactMap Map<Id, Contact> - A map of existing Contact records (before update) with their Ids as keys.
     * If null, it indicates an insert operation.
     */
    public static void calculateLeadScore(List<Contact> newContactRecords, Map<Id, Contact> oldContactMap) {
        Set<Id> accountIds = new Set<Id>();
        
        for (Contact con : newContactRecords) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, accountBuyingStage6sense__c,Account_Tier__c FROM Account WHERE Id IN :accountIds]);
    
        for (Contact con : newContactRecords) {             
            if (oldContactMap == null || 
            con.Job_Function__c != oldContactMap.get(con.Id)?.Job_Function__c ||
            con.JobLevel__c != oldContactMap.get(con.Id)?.JobLevel__c ||
            con.accountBuyingStage6sense__c != oldContactMap.get(con.Id)?.accountBuyingStage6sense__c ||
            (con.AccountId != null && (
                accountMap.get(con.AccountId)?.accountBuyingStage6sense__c != oldContactMap.get(con.AccountId)?.accountBuyingStage6sense__c ||
                accountMap.get(con.AccountId)?.Account_Tier__c != oldContactMap.get(con.AccountId)?.Account_Tier__c
            )) ||
            con.P0_Engagements__c != oldContactMap.get(con.Id)?.P0_Engagements__c ||
            con.P1_Engagements__c != oldContactMap.get(con.Id)?.P1_Engagements__c ||
            con.P2_Engagements__c != oldContactMap.get(con.Id)?.P2_Engagements__c ||
            con.P3_Engagements__c != oldContactMap.get(con.Id)?.P3_Engagements__c || con.Update_Lead_Score__c
            ) 

            {
                Decimal leadScore = con.Job_Function_Score__c + con.Job_Level_Score__c;
                
                Decimal engagementScore = (con.P0_Engagements__c != null ? con.P0_Engagements__c * 60 : 0) +
                                        (con.P1_Engagements__c != null ? con.P1_Engagements__c * 40 : 0) +
                                        (con.P2_Engagements__c != null ? con.P2_Engagements__c * 10 : 0) +
                                        (con.P3_Engagements__c != null ? con.P3_Engagements__c * 3 : 0);
                
                engagementScore = Math.min(engagementScore, 60);
                leadScore += engagementScore;
    
                Integer buyingStageScore = 0;
                String buyingStage = con.AccountId != null ? accountMap.get(con.AccountId)?.accountBuyingStage6sense__c : '';
    
                if (buyingStage == 'Purchase' || buyingStage == 'Decision') {
                    buyingStageScore = 40;
                } else if (buyingStage == 'Consideration' || buyingStage == 'Awareness') {
                    buyingStageScore = 30;
                } else {
                    buyingStageScore = 0;
                }
    
                leadScore += buyingStageScore;    
    
                if (con.Account_Tier__c == 'Tier 1' || con.Account_Tier__c == 'Tier 2') {  
                    con.Lead_Score_Number__c = leadScore + 20;
                } else if (con.Account_Tier__c == 'Tier 3' || con.Account_Tier__c == 'Tier 4') {
                    con.Lead_Score_Number__c = leadScore + 10;
                } else {
                    con.Lead_Score_Number__c = leadScore;
                }

                if(con.Update_Lead_Score__c){
                    con.Update_Lead_Score__c = false;
                }
                con.CFCR_Admin_Score_Increment__c = ( con.CFCR_Admin_Score_Increment__c == null ) ? 1: ( con.CFCR_Admin_Score_Increment__c == 1 ? 2 : 1 );
            }
        }    
    }

    /**
     * @description Calculates and assigns the MQL priority ('P0', 'P1', 'P2', 'P3') for each Contact
     * based on their `Lead_Score_Number__c`. This method updates the `MQL_Priority_txt__c` field.
     *
     * @param newContactRecords List<Contact> - A list of new Contact records being inserted or updated.
     * @param oldContactMap Map<Id, Contact> - A map of old Contact records (before update) with Contact Id as the key.
     * This helps in checking if the Lead Score has changed.
     */
    public static void calculateMQLPriority(List<Contact> newContactRecords, Map<Id, Contact> oldContactMap) {
        for (Contact con : newContactRecords) {
            if(oldContactMap == null || (oldContactMap != null && ( con.Lead_Score_Number__c != oldContactMap.get(con.Id)?.Lead_Score_Number__c))){
                con.MQL_Priority_txt__c = con.Lead_Score_Number__c >= 140 ? 'P0' : con.Lead_Score_Number__c >= 120 ? 'P1' : con.Lead_Score_Number__c >= 80  ? 'P2' : 'P3';
            }
        }
    }

    /**
     * @description This method is used to update the Contact Rejection Reason field on Contact object.
     * @param newContactList List<Contact> - List of Contacts to be updated
     * @param oldContactMap Map<Id,Contact> - Map of old Contact records
     */
    public static void setContactRejectReasonBlank (List<Contact> newContactList, Map<Id,Contact> oldContactMap) {
        for(Contact con : newContactList){
            
            if(oldContactMap.get(con.Id).Contact_Status__c != con.Contact_Status__c && (con.Contact_Status__c == 'Open' || con.Contact_Status__c == 'RAW' || con.Contact_Status__c == 'Working' || con.Contact_Status__c == 'Meeting Set')){  
            con.ContactRejectReason__c = null;
            }
            
        }
    }
}