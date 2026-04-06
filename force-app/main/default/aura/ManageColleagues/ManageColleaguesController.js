({
    doInit : function(component, event, helper) {
        var url_string = window.location;
        var searchStrings = url_string.search;
        searchStrings = searchStrings.split('?')[1].split('&');
        var CaseNumber,CaseId;
        for(var i=0;i<searchStrings.length;i++){
            if(searchStrings[i].indexOf('caseNumber')>-1){
                CaseNumber = searchStrings[i].split("=")[1]
            }
            if(searchStrings[i].indexOf('id')>-1){
                CaseId = searchStrings[i].split("=")[1]
            }

        }
        component.set('v.Casenumber', CaseNumber);
        component.set('v.CaseId', CaseId);
        var action = component.get("c.caseTeamMembers");
        var casenumber = component.get("v.Conlist");
        action.setParams({
            "CaseId":CaseId,
            "CaseNumber":CaseNumber
        });
        action.setCallback(component, function(response) {
            component.set("v.Conlist",response.getReturnValue());
            component.set("v.allContacts", response.getReturnValue());
            var contactsList=response.getReturnValue();
            if(contactsList!=null && contactsList.length >0){
                
                var contactsInCTM=[];
                for (let i = 0; i < contactsList.length; i++) {
                    if(contactsList[i].isAdded == true){
                        contactsInCTM.push(contactsList[i].con.Id);
                    }
                }
                component.set("v.contactsAddedInCaseTeamMembers",contactsInCTM);   
            }
            component.set('v.loaded',false);
        });
        $A.enqueueAction(action);
    },
    redirect: function(component, event, helper){
        window.history.back();
        return false;
    },
    savecontact1: function(component, event, helper) {

           /*====== First Name Validation----*/
        var search = component.find("fname");
        var fnamevalue = search.get("v.value");
        if ($A.util.isEmpty(fnamevalue )) {
           search.set("v.errors",  [{message:" Please fill the required field "}]);
            search.focus();
        } else {
            search.set("v.errors", null)
        }
        /*=======*/
        /*====== Last Name Validation----*/
        var last = component.find("lname");
        var value = last.get("v.value");
        if ($A.util.isEmpty(value )) {
            last.set("v.errors",  [{message:" Please fill the required field "}]);
            last.focus();
        } else {
            last.set("v.errors", null)
        }
      /*=======*/
          /*====== Title Validation----*/
        var title = component.find("title");
        var titlevalue = title.get("v.value");
        if ($A.util.isEmpty(titlevalue)) {
            title.set("v.errors",  [{message:" Please fill the required field "}]);
            title.focus();
        } else {
            title.set("v.errors", null)
        }
      /*=======*/
            /*--------Email Validation--------------*/
        var isValidEmail = true;
       var emailField = component.find("getEmail");
        var emailFieldValue = emailField.get("v.value");
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        if ($A.util.isEmpty(emailFieldValue )) {
            emailField.set("v.errors",  [{message:" Please fill the required field "}]);
             isValidEmail = false;
            //emailField.focus();
        }
        else if(!$A.util.isEmpty(emailFieldValue )){
            if(emailFieldValue.match(regExpEmailformat)){
                emailField.set("v.errors",null);
                isValidEmail = true;
            }else{
              //  $A.util.addClass(emailField, 'slds-has-error');
                emailField.set("v.errors", [{message: "Please Enter a Valid Email Address"}]);
                isValidEmail = false;
            }
        }
        /*=======*/
         var phone = component.find("Phone");
        var phonevalue = phone.get("v.value");
 /*     var allValid = component.find('newUserForm').reduce(function (validSoFar, inputCmp) {
                inputCmp.showHelpMessageIfInvalid();
                return validSoFar && !inputCmp.get('v.validity').valueMissing;
            }, true);
            if (allValid && IsValidMail && IsvalidPhone) {
                helper.createNewContact(component, event, helper);
            }else{
                cosole.log('not valid');
            } */
        //call apex class method
           if(isValidEmail == true && !$A.util.isEmpty(fnamevalue) && !$A.util.isEmpty(value) && !$A.util.isEmpty(titlevalue)){
               component.set("v.isSave",'SAVING');
               component.set("v.isSpinner",true);
        var action2 = component.get('c.createContact');
             action2.setParams({
            firstName:fnamevalue,
            lastName:value,
            email:emailFieldValue,
            title:titlevalue,
            phone:phonevalue
        });
        }
        action2.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue()=='')
                {
                    emailField.set("v.errors",null);
                    component.set("v.isSave",'SAVING');
                    component.set("v.isSpinner", true);
                    $A.get("e.force:refreshView").fire();
                }
                else {
                        emailField.set("v.errors", [{message: response.getReturnValue()}]);
                        component.set("v.isSave",'SAVE');
                        component.set("v.isSpinner", false);
                }
            }
        });
        $A.enqueueAction(action2);
    },
    handleShowSpinner: function(component, event, helper) {
        component.set("v.isSpinner", true);
    },

    //Call by aura:doneWaiting event
    handleHideSpinner : function(component,event,helper){
        component.set("v.isSpinner", false);
    },

    saveItm : function(component, event, helper){
        var newItem = component.get("v.newItem");
        helper.saveItms(component, newItem);

        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId")
        });
        navEvt.fire();
    },
    closeModal:function(component,event,helper){
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    },
    openModal:function(component,event,helper) {
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');
    },

    //added for CS21-839 - Rajender
     onChangeSearchPhrase : function (component, event, helper) {
         var inputValue = event.getSource().get('v.value');
         let allContacts = component.get("v.allContacts");
         if(!inputValue){
            component.set("v.Conlist", allContacts);
         }
     },

    handleSearch : function (component, event, helper) {
       helper.searchRecordsBySearchPhrase(component, event, helper);
    },
    sortFirstName : function(component, event, helper)
    {
        //alert('Test--1')
        component.set("v.selectedTabsoft", 'FirstName');
        helper.sortHelper(component, event, 'FirstName');
    },
    sortLastName : function(component, event, helper)
    {
        component.set("v.selectedTabsoft", 'LastName');
        helper.sortHelper(component, event, 'LastName');
    },
    sortEmail : function(component, event, helper)
    {
        component.set("v.selectedTabsoft", 'Email');
        helper.sortHelper(component, event, 'Email');
    },
   // end of CS21-839

    onSelectContacts: function(component, event, helper) {
        var selectedContacts = component.get("v.selectedContacts");
        var removedContacts = component.get("v.removedContacts");
        var contactsAddedInCTM = component.get("v.contactsAddedInCaseTeamMembers");
         
        if(event.getSource().get('v.checked') == true){
            if(contactsAddedInCTM.indexOf(event.getSource().get('v.name')) == -1){
                selectedContacts.push(event.getSource().get('v.name')); 
            }  
            if(removedContacts.indexOf(event.getSource().get('v.name')) !== -1){
                removedContacts.splice(removedContacts.indexOf(event.getSource().get('v.name')), 1); 
            }
        }else if(event.getSource().get('v.checked') == false){
            if(selectedContacts.includes(event.getSource().get('v.name'))){
                selectedContacts.splice(selectedContacts.indexOf(event.getSource().get('v.name')), 1);
            }
            if(contactsAddedInCTM.indexOf(event.getSource().get('v.name')) !== -1){
                removedContacts.push(event.getSource().get('v.name')); 
            }  
            
        }
    },
    
    handleSelectedContacts: function(component, event, helper) {
        component.set('v.loaded',true);
        var selectedContacts = component.get("v.selectedContacts");
        var removedContacts = component.get("v.removedContacts");
        var Conlist = component.get("v.contactsAddedInCaseTeamMembers");
        for (let i = 0; i < Conlist.length; i++) {
                if(removedContacts.length == 0 || (removedContacts.length > 0 && !removedContacts.includes(Conlist[i]))){
                    if(!selectedContacts.includes(Conlist[i])){
                        selectedContacts.push(Conlist[i]);
                    }
                }
            
        }
        var action2 = component.get('c.addColleaguesToCase');
        action2.setParams({
            caseId : component.get("v.CaseId"),
            memberIdList : selectedContacts
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            
            if (state === "SUCCESS") {
                var newURL = $A.get("$Label.c.Community_Base_URL") +
                    "viewcase?id=" + component.get('v.CaseId') ;
                window.location = newURL;
            }else{
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "An unexpected failure occurred while processing your request. Please try again later, or contact Rubrik Support Operations."
                });
                toastEvent.fire();

            }
            
            component.set('v.loaded',false);
            //  window.history.back();
        });
        $A.enqueueAction(action2);
    }
});