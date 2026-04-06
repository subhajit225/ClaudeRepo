({ Init : function(component, event, helper) {
    console.log('call init method');
    //Comment here
    var quoteQuery ='select Id,Name,Account_Screening__c,Customer_URL__c,Primary_Contact_Email__c,(Select id, Name,EndDate, RSC_Status__c from Entitlements where Status = \'Active\' and Type= \'Admin\' and SubType__c = \'RSC\' Limit 1 ),(Select Id,RSC_Status__c from RSC_Process__r limit 1),(select id,GTC_Screen_Status_Message__c from Account_Screenings__r where  (Screening_Action__c = \'Start\' or Screening_Action__c = \'Resend\') and Screening_Action_Status__c  =  \'Sent\' Limit 1)    from Account where  Id = \''+ component.get("v.recordId") + '\''+ ' order by createddate Desc limit 1';
    console.log('query is #### ' + JSON.stringify(quoteQuery));
    helper.executeQuery(component, event, helper, quoteQuery, 'AccountRec'); 
},
  executeQuery : function(component, event, helper, query, attributeName) {
      component.set("v.isReadOnly", true);
      component.set("v.showSpinner", true);
      component.set("v."+attributeName, null);
      var isFreeTrail= component.get("v.isFreeTrial");
      var action = component.get("c.executeAllQuery"); 
      action.setParams({
          "theQuery": {
              "entQuery": query
          }
      });
      action.setCallback(this, function(response) { 
          var state = response.getState();
          if(state == "SUCCESS" && component.isValid()){
              var allRecords = response.getReturnValue();
              if (allRecords.hasOwnProperty('entQuery')) {
                  //var queryResult = allRecords.entQuery;
                  var queryResult = allRecords.entQuery;
                  component.set("v.showSpinner", false);

                  /*if(queryResult[0].RSC_Process__r == null || queryResult[0].RSC_Process__r.length == 0){
                      component.set("v.showSpinner", false);
                  }*/
                  console.log('==='+JSON.stringify(queryResult))
                  component.set("v."+attributeName, queryResult[0]);
                  var accountEntitlements = component.get("v."+attributeName);
                  console.log('accountEntitlements ' + JSON.stringify(accountEntitlements));
                  console.log("17",queryResult[0].hasOwnProperty('Account_Screenings__r'));
                  var gtcScreeningFlag = (queryResult[0].hasOwnProperty('Account_Screenings__r') && queryResult[0].Account_Screenings__r.length > 0 &&  queryResult[0].Account_Screenings__r[0].GTC_Screen_Status_Message__c == 'Screening Complete');
                  component.set("v.isGTCPassed",gtcScreeningFlag);
                  if(!isFreeTrail && !gtcScreeningFlag){
                      helper.showToast(component, event, helper, 'GTC Screening is Failed For Paid Version' , 'error');
                      $A.get("e.force:closeQuickAction").fire();
                      component.set("v.reloadForm", false);
                      
                  }else if(!isFreeTrail && (!accountEntitlements.Entitlements || accountEntitlements.Entitlements.length == 0)){
                      helper.showToast(component, event, helper, 'Atleast one Active RSC Entitlements should be there on Account!' , 'error');
                      $A.get("e.force:closeQuickAction").fire();
                      component.set("v.reloadForm", false);
                  }else{
                      var rscEntitlement;
                      if(accountEntitlements.hasOwnProperty('Entitlements'))
                     rscEntitlement = accountEntitlements.Entitlements[0];
                      if(!isFreeTrail && rscEntitlement.RSC_Status__c != null && (queryResult[0].RSC_Process__r === null || queryResult[0].RSC_Process__r === undefined )){
                          helper.showToast(component, event, helper, 'RSC Process already Initiated!' , 'error');
                          $A.get("e.force:closeQuickAction").fire();
                          component.set("v.reloadForm", false);
                      } else if(!isFreeTrail && queryResult[0].RSC_Process__r && queryResult[0].RSC_Process__r.length > 0){
                          var rscs = queryResult[0].RSC_Process__r;
                          if(rscs[0].RSC_Status__c === 'Fail'){
                              component.set("v.rscRecordId", rscs[0].Id);
                          }else{
                              helper.showToast(component, event, helper, "RSC process already Initiated" , 'error');
                              $A.get("e.force:closeQuickAction").fire();
                              
                          }
                      }else {
                          var accountrec = component.get("v.AccountRec");
                          component.find("AccountId").set("v.value", accountrec.Id);
                          component.find("customerUrl").set("v.value", accountrec.Customer_URL__c);
                          // component.find("rsccontactEmail").set("v.value", accountrec.Primary_Contact_Email__c);
                          // component.find("expiryDate").set("v.value", accountrec.Customer_URL__c);
                          // component.find("customerUrl").set("v.value", accountrec.Customer_URL__c);
                          if(accountEntitlements.Entitlements && accountEntitlements.Entitlements.length>0){
                              component.find("expiryDate").set("v.value", accountEntitlements.Entitlements[0].EndDate);
                          }
                          if (isFreeTrail){
                              var result = new Date();
                              result.setDate(result.getDate() + 45);
                              var today = $A.localizationService.formatDate(result, "YYYY-MM-DD");
                              component.find("expiryDate").set("v.value", today);
                          }
                          
                      }
                  }
                  
              }
              
          }else{
              console.error("fail:" + response.getError()[0].message);
              helper.showToast(component, event, helper, "Something went wrong in your org: " + response.getError()[0].message , 'error');
              $A.get("e.force:closeQuickAction").fire();
          }
      });
      $A.enqueueAction(action);
  },
  handleFormSubmit: function(component, event, helper) {
      var accountEntitlements = component.get("v.AccountRec");
      var eventFields = event.getParam("fields"); //get the fields
      console.log('eventFields'+JSON.stringify(eventFields));
      component.set("v.showSpinner", true);
      var isFreeTrailVar= component.get("v.isFreeTrial");
      var isGTCPassedVar = component.get("v.isGTCPassed");
      var action = component.get("c.upsertRSCProcess");
      action.setParams({
          "req": eventFields,
          "isFreeTrial" :  isFreeTrailVar,       
          "gtcScreeningPassed" : isGTCPassedVar,
          "acct" : accountEntitlements
      });
      action.setCallback(this, function(a){
          var state = a.getState(); // get the response state
          if(state == 'SUCCESS') {
              var res = a.getReturnValue();
              console.log('result is ' + JSON.stringify(res));
              if(res.isSuccess){
                  component.set('v.rscRecordId', res.rscRecId);
                  
                  if(isGTCPassedVar){
                      helper.doCalloutjs(component, event, helper);
                  }else{
                      helper.showToast(component, event, helper, "GTC Screening is initiated and provisioning will happen post successful screening." , 'Success');
                      $A.get("e.force:closeQuickAction").fire();
                      
                  }
              } else{
                  console.log('error is ' + JSON.stringify(res))
                  helper.showToast(component, event, helper, res.errorMessage , 'Error');
                  $A.get("e.force:closeQuickAction").fire();
              }
          }else{
              helper.showToast(component, event, helper, "Something went wrong in your org: " + a.getError()[0].message , 'error');
              $A.get("e.force:closeQuickAction").fire();
          }
      });
      $A.enqueueAction(action);
  },
  showToast : function(component, event, helper, message, type) {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
          "message": message,
          "duration": 5000,
          "type": type
      });
      toastEvent.fire();
  },
  doCalloutjs : function(component, event, helper) {
      var action = component.get("c.doCallout");
      action.setParams({
          "recordId":component.get("v.rscRecordId")
      });
      action.setCallback(this, function(response) {
          var state = response.getState();
          if(state == "SUCCESS"){
              component.set("v.showSpinner", false);
              var res = response.getReturnValue();
              if(res.isSuccess){
                  helper.showToast(component, event, helper, "RSC process Initiated" , 'Success');
              } else {
                  console.log('error is ' + JSON.stringify(res.errorMessage));
                  helper.showToast(component, event, helper, res.errorMessage , 'Error');
              }
              $A.get("e.force:closeQuickAction").fire();
          }else{
              helper.showToast(component, event, helper, "Something went wrong in your org: " + response.getError()[0].message , 'error');
              $A.get("e.force:closeQuickAction").fire();
          }
          $A.get('e.force:refreshView').fire();
      });
      $A.enqueueAction(action);
  },
 })