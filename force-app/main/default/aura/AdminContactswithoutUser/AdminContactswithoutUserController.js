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
    OpenModal: function(component,event,helper) {
        component.set("v.Spnr",true);
        /*<Additions By: Anmol Baweja 03 Mar, 2020>*/
        /*<Reason>
  			To restrict any community user to make a new user with ignored email domain as per CS-582
 		</Reason>*/
        var hasError = false;
        var selectedContactId = event.getSource().get("v.name");
        var selectedContactEmail= [];
        var totalContactsWithoutUser = component.get("v.contactInfo");
        if(!!totalContactsWithoutUser){
            for(var i=0;i<totalContactsWithoutUser.length;i++){
                if(!!selectedContactId && totalContactsWithoutUser[i].Id.includes(selectedContactId)){
                    if(!!totalContactsWithoutUser[i].Email){
                        selectedContactEmail.push(totalContactsWithoutUser[i].Email);
                    }
                }
            }
        }
        if(!!selectedContactEmail){
            component.set("v.selectedContactEmail",selectedContactEmail);
        }
        if(component.get("v.selectedContactEmail") != null){
            var email=component.get("v.selectedContactEmail")[0].split("@");
            var domain=email[1];
            if(component.get("v.ignoredDomainList") != null && domain != null && component.get("v.ignoredDomainList").includes(domain.toLowerCase())){
                hasError = true;
                component.set("v.IgnoredDomainError",true);
            }
        }
        if(hasError == true && component.get("v.IgnoredDomainError") == true){
            component.set("v.Spnr",false);
            component.set("v.showModal",true);
            component.set("v.modalMessage",$A.get("$Label.c.S_R_Ignored_Domain"));
        }
        if(hasError == false){
            /*</Additions By: Anmol Baweja>*/
            var action = component.get("c.contactToUser");
            action.setParams({
                Id : event.getSource().get("v.name"),
            });
            action.setCallback(component, function(response) {
                component.set("v.Spnr",false);
                var result = response.getReturnValue();
                component.set("v.name",result);
                var element = document.getElementById("Modalbox");
                element.classList.remove("slds-hide");
            });
            $A.enqueueAction(action);
        }
    },
    closeModal: function(component,event,helper) {
        var element = document.getElementById("Modalbox");
        element.classList.add("slds-hide");
        $A.get("e.force:refreshView").fire(); 
    },
    
    ModalBtn: function(component,event,helper) {
        var action = component.get("c.requestAccess");
        action.setParams({
            reqAccess:component.get("v.AccountInfo.existingUsers"),
        });
        action.setCallback(component, function(response) {
            var element = document.getElementById("Modal");
            element.classList.remove("slds-hide");
            if (state === "SUCCESS") {
            }
        });
        $A.enqueueAction(action);
    },
    closeModalBtn: function(component,event,helper) {
        var element = document.getElementById("Modal");
        element.classList.add("slds-hide");
        $A.get("e.force:refreshView").fire(); 
    },
})