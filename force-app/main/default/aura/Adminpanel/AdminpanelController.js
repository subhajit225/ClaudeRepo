({
    init : function(component, event, helper) {
        helper.getUsrInfo(component);
        helper.fillColoumn(component);
    },
    
    Sorttable : function(component, event, helper) {
        var fieldName = event.target.name;
        var sortDirection = event.target.id;
        if(sortDirection == component.get("v.sortedDirection")){
            sortDirection = 'asc';
        }
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    AddClick :function(component, event, helper) {
        component.set("v.isAddUser", true);
    }, 
    
    cnclClick :function(component, event, helper) {
        /*Commented below logic as there is discrepency when edit user form is cancelled -
             added refresh to reset page to initial values - CS21-426 - Veera */
        //component.set("v.isAddUser", false);
        //component.set("v.isEdit", false);
        /*component.set("v.ContList", {
            'firstName':'',
            'lastName':'',
            'email':'',
            'title': '',
            'phone':'',
            'hasError':false
        });*/
         $A.get('e.force:refreshView').fire();
    },
    
    EditClick :function(component, event, helper) {
        component.set("v.isEdit", true);
    },  
    
    oncheck: function(cmp, event, helper) {
        var checkCmp = cmp.find("checkbox");
        checkCmp.get("v.isChecked");
    },
    
    savecontact1: function(component, event, helper) {
        /*New code  start*/
       
        component.set("v.Spnr",true);
        var allContact = component.get("v.ContList");
        helper.ValidateData(component,helper,event,allContact,function(hasError,updatedContact){
            if(hasError){
                component.set("v.ContList",updatedContact);
                component.set("v.Spnr",false);
            }
            else{
                var action2 = component.get('c.createContact');
                action2.setParams({
                    forInsert:component.get("v.ContList"),
                    isCreateuser:component.get("v.isChecked"),
                });
                action2.setCallback(this, function(response) {
                    component.set("v.Spnr",false);
                    //store state of response
                    var state = response.getState();
                    
                    if (state === "SUCCESS") {
                     
                        var EmailValue=response.getReturnValue();
                        if(EmailValue.includes("@") &&EmailValue!=null)
                        {    
                         helper.ValidateContactData(component,helper,event,allContact,EmailValue,function(hasError,updatedContactList){
                          if(hasError){
                                             
                                             component.set("v.showModal",false);
                                             component.set("v.ContList",updatedContactList);
                                             component.set("v.Spnr",false);
                                           
                          }else{
                           
                               component.set("v.modalMessage",response.getReturnValue());
                               component.set("v.showModal",true);
                          }
                        
                        });
                      }else{
                            component.set("v.modalMessage",response.getReturnValue());
                            component.set("v.showModal",true);
                        }
                        if(!response.getReturnValue()){
                            component.set("v.modalMessage",'User has been updated');
                            component.set("v.showModal",true);
                        }
                        
                    }
                });
                $A.enqueueAction(action2);  
            }
        });
    },
    
    newAdd: function(component, event, helper) {
        var contactList = component.get("v.ContList");
        contactList.push({
            'firstName':'',
            'lastName':'',
            'email':'',
            'title': '',
            'phone':'',
            'hasError':false
        });
        component.set("v.ContList",contactList);
    },
    
    UpdateUser: function(component, event, helper) {
        //call apex class method
        
        component.set("v.Spnr", true);
        
        /*Added validation logic to check required fields - Update User - CS21-426 - Veera*/
        let updatedUsers = component.get("v.AccountInfo.existingUsers");
        let validityCheck = true;
        
        for (let eachUser of updatedUsers) {
            if ($A.util.isEmpty(eachUser.lastName) 
                || $A.util.isEmpty(eachUser.email)) {
                validityCheck = false;
            }
        }
        
        if (!validityCheck) {
            component.set("v.Spnr", false);
            component.set("v.modalMessage",'Please fill in all the required fields.');
            component.set("v.showModalForInvalidEmail",true);           
        } else {
            
            let updatedUsers = component.get("v.AccountInfo.existingUsers");
            let originalUsers = component.get("v.AccountInfo.originalUsers");
            let authorize = component.get("v.authorize");            
            let usersToUpdate = [];
            let hasInAcitveChange = false;
            
            if(!authorize){
                for (let i = 0; i < updatedUsers.length; i++) {
                    console.log('updatedUsers[i].inactive',updatedUsers[i].isActive);
                    console.log('originalUsers[i].inactive',originalUsers[i].isActive);
                    if (updatedUsers[i].isActive != originalUsers[i].isActive) {
                        hasInAcitveChange = true;
                    }
                }
            
            if (hasInAcitveChange) {
                component.set("v.Spnr", false);
                component.set("v.showSPConfirmationModal", true);
            }
            else{
                authorize = true;
            }
        }
            if(authorize){
                var action2 = component.get('c.UserUpdate');
                
                action2.setParams({
                    forUpdate2: updatedUsers,
                    orgUser: originalUsers                    
                });
                
                action2.setCallback(this, function(response) {
                    component.set("v.Spnr",false);
                    //store state of response
                    var state = response.getState();
                    
                    if (state === "SUCCESS") {
                        console.log(response.getReturnValue());
                        component.set("v.modalMessage",response.getReturnValue());
                        if(!response.getReturnValue()){
                            component.set("v.modalMessage",'User has been updated');
                        }
                        component.set("v.showModal",true);
                    }
                });
                $A.enqueueAction(action2);  
            } 
        }
    },
    
    ackUserInactive : function(component, event, helper) {
        component.set("v.authorize", true);
        component.set("v.showSPConfirmationModal", false);
    },
    
    closeModal: function(component, event, helper) {
        if(component.get("v.showModal") == true){
            component.set("v.showModal",false);
            $A.get("e.force:refreshView").fire();
        }
        /*<Additions By: Anmol Baweja 03 Mar, 2020>*/
        /*<Reason>
				To restrict any community user to make a new user with ignored email domain as per CS-582
		</Reason>*/
        if(component.get("v.showModalForInvalidEmail") == true){
            component.set("v.showModalForInvalidEmail",false); 
        }
        /*</Additions By: Anmol Baweja>*/
    }
})