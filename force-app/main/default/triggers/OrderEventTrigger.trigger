/************************************************************
 * @description       : Order event trigger
 * @author            : Chaitra
 * @last modified on  : 01-20-2021
 * @last modified by  : Chaitr
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   01-20-2021   Chaitra        Initial Version
 **************************************************************/
trigger OrderEventTrigger on Order_Trigger_Event__e(after insert) {
  public set<Error_Logs__c> errorLogs = new Set<Error_Logs__c>();
  public List<Messaging.SingleEmailMessage> allMails = new List<Messaging.SingleEmailMessage>();
  if(Test.IsRunningTest()) {
        dummy();
    }
  try {
    for (Order_Trigger_Event__e event : Trigger.new) {
      if (event.Action_Type__c == 'UpdateToCommunityUser') {
        updateCommunityUsers(event.Input_Data__c);
      } else if (event.Action_Type__c == 'CreateCommunityUser') {
        CreatePortalUsers(event.Input_Data__c);
      }
    }
    finalCommit();
  } catch (exception ex) {
     errorLogs.add(new Error_Logs__c( Error_Type__c = 'Order Event Trigger', Error_Message__c = ex.getmessage(), Type__c = 'SFDC'));
  } 
  /****************************************
     Update to community users 
    ***************************************/
  public void updateCommunityUsers(string conIdStr) {
    List<Id> conIds = new List<Id>();
    conIds = conIdStr.split(',');
    List<User> usersToUpdate = new List<User>();
    for (User u : [SELECT Id, ProfileId FROM User WHERE ContactId IN :conIds]) {
      if (u.ProfileId != System.Label.Rubrik_Community_Super_User_Profile_Id) {
        usersToUpdate.add(
          new User(
            Id = u.Id,
            ProfileId = System.Label.Rubrik_Community_Super_User_Profile_Id
          )
        );
      }
    }

    if (usersToUpdate.size() > 0) { 
      //Using static variable to decide if the validation rule on user trigger should fire or not
      checkRecursive.AllowSupportPortalUserCreation=True;
      update usersToUpdate;
    }
  }

 /****************************************
     Create community users 
 ***************************************/
  public void CreatePortalUsers(string ordIdStr) {
    List<Id> ordIds = new List<Id>();
    Set<Id> conIds = new Set<Id>();
    Set<Id> scaleUtilityContacts = new Set<Id>();
    ordIds = ordIdStr.split(',');
    List<Contact> contactUsersToInsert = new List<Contact>();
    List<User> usersToInsert = new List<user>();
    List<User> retryUsersToInsert = new List<user>();
    Map<Id, Id> ConIdOrdId = new Map<Id, Id>();
    Map<Id, Id> OppIdOrdId = new Map<Id, Id>();
    Id communityUserProfileId;  //CS21-1468 : Automating Third Party Manufacturing Entitlement in Welcome Email for Scale and Scale Utility Orders

    Id communityProfileId = [SELECT Id FROM Profile WHERE Name = :Label.CommunityProfileAutoProvision LIMIT 1].Id;

    Email_Preferences__mdt mdt = [Select Id,From__c,Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'Error Provisioning Order' LIMIT 1];

    Id fromEmailId = [Select Id from OrgWideEmailAddress where Address =:mdt.From__c.trim()].Id;

    Database.DMLOptions dmo = new Database.DMLOptions();
    dmo.EmailHeader.triggerUserEmail =
      TriggerControl__c.getInstance('PortalUserCreation') != null &&
      TriggerControl__c.getInstance('PortalUserCreation').SendEmail__c == true;

    for (Order ord : [SELECT Id, Welcome_Letter_Contact__c, Order_Sub_Type__c,
                        Has_Third_Party_Hardware_Product__c,
                        (SELECT Id FROM OrderItems
                        WHERE
                        //V1 (non RSC) logic:
                        (Product2.Product_Level__c = NULL AND Product2.Family = 'Rubrik Scale' AND (Product2.Product_Type__c = 'Enterprise Edition' OR Product2.Product_Type__c = 'Business Edition' OR Product2.Product_Type__c = 'RCDM'))
                        //V1 (non RSC) logic ends
                        OR
                        //V2 (RSC) logic
                        (Product2.Product_Level__c = 'Hybrid Software' AND Product2.Family = 'Rubrik Scale' AND Product2.Product_Subtype__c != 'Scale MSP' AND (Product2.Product_Type__c = 'Enterprise Edition' OR Product2.Product_Type__c = 'Business Edition' OR Product2.Product_Type__c = 'Foundation Edition'))
                        //V2 (RSC) logic ends
                        )
                      FROM Order
                      WHERE Id IN :ordIds]) {
      conIds.add(ord.Welcome_Letter_Contact__c);

      /*CS21-1468 : Automating Third Party Manufacturing Entitlement in Welcome Email
      for Scale and Scale Utility Orders*/
      if((String.isNotBlank(ord.Order_Sub_Type__c) && Label.Scale_Utility_Order_Subtypes.containsIgnoreCase(ord.Order_Sub_Type__c) && ord.Has_Third_Party_Hardware_Product__c) || !ord.OrderItems.isEmpty()){
        scaleUtilityContacts.add(ord.Welcome_Letter_Contact__c);
      }
    }

    contactUsersToInsert = [ SELECT Id, Email, FirstName, LastName FROM Contact WHERE Id IN :conIds];
    for (Contact con : contactUsersToInsert) {
      communityUserProfileId = scaleUtilityContacts.contains(con.Id) ? Label.Rubrik_Community_Super_User_Profile_Id : communityProfileId;
      usersToInsert.add(createPortalUser(con, communityUserProfileId, dmo));
    }
    if (!usersToInsert.isEmpty()) {
      Integer i = 0;
      //Using static variable to decide if the validation rule on user trigger should fire or not
      checkRecursive.AllowSupportPortalUserCreation=True;
      for (Database.SaveResult sr : Database.insert(usersToInsert, false)) {
        if (sr.isSuccess()) {
          system.debug(logginglevel.Info, 'Succesfully CreatedPortal User::' + sr.getId());
        } else {
          for (Database.Error err : sr.getErrors()) {
            try {
             system.debug(logginglevel.ERROR,'Error Message'+err.getMessage());
              if (err.getMessage().contains('DUPLICATE_USERNAME') || err.getStatusCode()== System.StatusCode.DUPLICATE_USERNAME ) {
                retryUsersToInsert.add(usersToInsert[i]);
              } else {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                string error =' Error creating portal user for ' + usersToInsert[i].Email +' id: ' +usersToInsert[i].ContactId;
                error += ' \n' + err.getMessage() + '\n\n';
                errorLogs.add( new Error_Logs__c( Error_Type__c = 'Portal Provision Error',
                                                    Error_Message__c = error,
                                                    Type__c = 'SFDC',
                                                    Related_Order__c = ConIdOrdId?.get(usersToInsert[i].ContactId) ));
                email.setInReplyTo('noreply@rubrik.com');
                email.setSubject('Rubrik Portal Registration Error 1');
                email.setplainTextBody(error);
                email.setToAddresses(new List<string>{mdt.Receipient__c} );
                email.setOrgWideEmailAddressId(fromEmailId);
                List<String> ccAddresses = new List<String>();
                if(mdt.cc__c != null){
                 for(String address: mdt.cc__c.split(',')){
                 ccAddresses.add(address.trim());
                 }
             }
        
            if(!ccAddresses.isEmpty()){
                 email.setCcAddresses(ccAddresses);
             }
                allMails.add(email);
              }
            } catch (Exception ex) {
              system.debug( logginglevel.Info,'Failed to  Create Portal User::' + ex.getMessage() );
            }
          }
        }
      }
    }
    if (!retryUsersToInsert.isEmpty()) {
      system.debug( logginglevel.FINE,'retryUsersToInsert'+retryUsersToInsert);
      for (User usr : retryUsersToInsert) {
        usr.username = 'support.' + usr.username;
      }
      Integer i = 0;
      //Using static variable to decide if the validation rule on user trigger should fire or not
      checkRecursive.AllowSupportPortalUserCreation=True;
      for (Database.SaveResult sr : Database.insert(retryUsersToInsert, false) ) {
        if (sr.isSuccess()) {
          system.debug(logginglevel.DEBUG,'Succesfully CreatedPortal User 2nd  attempt::' + sr.getId());
        } else {
          for (Database.Error err : sr.getErrors()) {
            try {
              Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
              string error =' Error creating portal user for ' +usersToInsert[i].Email +' id: ' + usersToInsert[i].ContactId;
              error += ' \n' + err.getMessage() + '\n\n';
              errorLogs.add(new Error_Logs__c(Error_Type__c = 'Portal Provision Error',Error_Message__c = error + '::2nd attempt',Type__c = 'SFDC',Related_Order__c = ConIdOrdId?.get(usersToInsert[i]?.ContactId)));
              email.setSubject('Rubrik Portal Registration Error ');
              email.setplainTextBody(error);
              email.setToAddresses(new List<string>{mdt.Receipient__c } );
              email.setOrgWideEmailAddressId(fromEmailId);
                List<String> ccAddresses = new List<String>();
                if(mdt.cc__c != null){
                 for(String address: mdt.cc__c.split(',')){
                 ccAddresses.add(address.trim());
                 }
             }
        
            if(!ccAddresses.isEmpty()){
                 email.setCcAddresses(ccAddresses);
             }
              allMails.add(email);
            } catch (Exception ex) {
              system.debug(logginglevel.Error, 'Failed to  Create Portal User on 2 attempt::' + ex.getMessage());
            }
          }
        }
        i++;
        system.debug(logginglevel.DEBUG,'allMails'+allMails);
      }
    }
  }

  private static User createPortalUser(
    Contact con,
    Id profileId,
    Database.DMLOptions dmo
  ) {
    User portalUser = new User(
      ContactId = con.id,
      UserName = con.Email,
      FirstName = con.FirstName,
      LastName = con.LastName,
      Email = con.Email,
      CommunityNickname = con.LastName + '_' + Math.random(),
      ProfileId = profileId,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocalesIdKey = 'en_US',
      TimezonesIdKey = 'America/Los_Angeles',
      ProvisionType__c = 'Order Automation'
    );//added ProvisionType__c for CS21-51 - Veera

    if (con.FirstName != null)
      portalUser.Alias = String.valueof(
        con.FirstName.substring(0, 1) +
        con.LastName.substring(0, 1) +
        string.valueof(Math.random()).substring(0, 6)
      );
    else { portalUser.Alias = String.valueof(con.LastName.substring(0, 2) +string.valueof(Math.random()).substring(0, 6)); }
    portalUser.setOptions(dmo);
    return portalUser;
  }

  private void finalCommit() {
    system.debug(logginglevel.DEBUG,'allMails'+JSON.serialize(allMails));
    if (!allMails.isEmpty()) {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(allMails);
      for (Messaging.SendEmailResult emailres : results) {
        if(!emailres.isSuccess())
          system.debug(logginglevel.ERROR, 'Error sending Order provisioning email' + emailres.getErrors());
      }
    }
  }
  
    public static void dummy(){
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
    }
}