({
    showContent : function(component, event, helper) {
		component.set('v.showContent', !component.get('v.showContent'));
	},
    
    selectAll: function(component, event, helper) {
      //  var accContObjectArray = component.get("v.accContObjectArray"); 
        var contactList = component.get("v.contactList");
        var visibleAccContObjectArray = component.get("v.visibleAccContObjectArray");
         var visibleContactRecords = component.get("v.visibleContactRecords");
        visibleContactRecords.forEach(obj =>{
            obj.selected = event.getSource().get( "v.checked" );
        })
        component.set("v.visibleContactRecords", visibleContactRecords);         
      
        
        /*
        visibleAccContObjectArray.forEach(obj => {
            contactList.forEach(contact => {
              contact.selected = event.getSource().get( "v.checked" );
              let conList = contactList.filter(element => {
                    return (element.Id == contact.Id )
               }) 
               conList[0].selected = event.getSource().get( "v.checked" );
            }); 
        }); 
        */
        
       
        component.set("v.contactList", contactList);    
        component.set("v.visibleAccContObjectArray", visibleAccContObjectArray);       
    },
             
    importToSalesloft: function(component, event, helper) {
        let contactList = component.get("v.contactList");
        let selectedCon = contactList.filter(element => {
              return element.selected
        }) || [];
        let idList= [];
        for (var i = 0; i < selectedCon.length; i++) {
            idList.push(selectedCon[i].Id);
        }
        if(idList.length == 0) return;
        let stringIds = idList.toString();
        var myurl = "https://app.salesloft.com/app/import/crm?contact=" + stringIds;

		window.open(myurl,'_blank');
    },
    onPageChange: function(component, event, helper) {
        component.find('allCheckBox').set('v.checked',false);
        component.set("v.showSpinner", true);
        component.set('v.showContent', false);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.paginationResults(component, event, helper);
            }), 7
        );
		
	},
    
    doInit : function(component, event, helper) {
        helper.doInit(component, event, helper);
    },
    
    sort : function(component, event, helper) { 
        helper.sortRecords(component, event, helper);
    },
    
    /*
    sortByContact: function(component, event, helper) { 
        component.set("v.showSpinner", true); 
        var whichOne = event.currentTarget.id;
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                var currentOrder = component.get("v.sortAsc"),
                    currentList = component.get("v.accContObjectArray");
                currentOrder = !currentOrder;
                
                currentList.sort(function(a,b) {
                    var t1 = a.Contacts.length == b.Contacts.length, t2 = a.Contacts.length < b.Contacts.length;
                    return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                });
                component.set("v.sortAsc", currentOrder);
                component.set("v.accContObjectArray", currentList);
                component.set('v.selectedPage', 1);
                helper.paginationResults(component, event, helper);
            }), 7
        );
        
    },
    */
    
    applyThemeFilters : function(component, event, helper) { 
        if(component.get("v.isDataLoading")) return;
        component.set('v.showContent', false);
        component.set("v.applyFilters", false);
        //component.set("v.selectedCampaigns", []);
        //component.set("v.selectedAccounts", []);
        component.set("v.applyFilters", true);
        component.set("v.showSpinner", true);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, false);
            }), 7
        );
    },
    
    applyCampaignFilters : function(component, event, helper) { 
        //component.set("v.selectedCampaigns", []);
        if(!component.get("v.applyFilters") || component.get("v.isDataLoading")) return;
        component.set('v.showContent', false);
        component.set("v.applyFilters", false);
        //component.set("v.selectedAccounts", []);
        component.set("v.applyFilters", true);
        component.set("v.showSpinner", true);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
    },
    
    applyAccountFilters : function(component, event, helper) { 
        if(!component.get("v.applyFilters") || component.get("v.isDataLoading")) return;
        component.set("v.showSpinner", true);
        component.set('v.showContent', false);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
        //helper.getFilters(component, event, helper, '', true);
        
    },
    
    applyConatactOWnerFilters : function(component, event, helper) { 
        if(!component.get("v.applyFilters") || component.get("v.isDataLoading")) return;
        component.set("v.showSpinner", true);
        component.set('v.showContent', false);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
        //helper.getFilters(component, event, helper, '', true);
        
    },
            
             applyTierFilters : function(component, event, helper) { 
        if(!component.get("v.applyFilters") || component.get("v.isDataLoading")) return;
        component.set("v.showSpinner", true);
        component.set('v.showContent', false);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
        //helper.getFilters(component, event, helper, '', true);
        
    },
    
      applyContactStatusFilters : function(component, event, helper) { 
        if(!component.get("v.applyFilters") || component.get("v.isDataLoading")) return;
        component.set("v.showSpinner", true);
        component.set('v.showContent', false);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
        //helper.getFilters(component, event, helper, '', true);
        
    },
    
    showAssignTaskModal: function(component, event, helper) { 
        helper.showAssignTaskModal(component, event, helper);
    },
    showStatusUpdateModal: function(component, event, helper) { 
        let contactList = component.get("v.contactList");
        var selectedIdWithNames =[];
        let selectedContacts = contactList.filter(element => {
              return element.selected
        }) || [];

        selectedContacts.forEach(record => {
            selectedIdWithNames.push({Id: record.Id, Name: record.Name});
            
        });
            
         var optsdefault =[];
        optsdefault = [
            { value: $A.get("$Label.c.LeadRejectReasonActiveOpp"), label: $A.get("$Label.c.LeadRejectReasonActiveOpp")},
            { value: $A.get("$Label.c.LeadRejectAttempted"), label: $A.get("$Label.c.LeadRejectAttempted")},
            { value: $A.get("$Label.c.AutouMQLReason"), label: $A.get("$Label.c.AutouMQLReason")},
            { value: $A.get("$Label.c.LeadRejectContacted"), label: $A.get("$Label.c.LeadRejectContacted")},
            { value: $A.get("$Label.c.LeadRejectExistingCustomer"), label: $A.get("$Label.c.LeadRejectExistingCustomer")},
            { value: $A.get("$Label.c.LeadRejectedNoAE"), label: $A.get("$Label.c.LeadRejectedNoAE")},
            { value: $A.get("$Label.c.LeadRejectPurchasedCompetitor"), label: $A.get("$Label.c.LeadRejectPurchasedCompetitor")},
            { value: $A.get("$Label.c.LeadRejectedDoNotContact"), label: $A.get("$Label.c.LeadRejectedDoNotContact")},
            { value: $A.get("$Label.c.LeadRejectSalesFuture"), label: $A.get("$Label.c.LeadRejectSalesFuture")},
            { value: $A.get("$Label.c.LeadRejectedElevatorPitch"), label: $A.get("$Label.c.LeadRejectedElevatorPitch")},
            { value: $A.get("$Label.c.LeadRejectedWrongPerson"), label: $A.get("$Label.c.LeadRejectedWrongPerson")}
        ]; 
                                          
        component.set("v.selectedStatusToUpdate", 'Nurture');
        component.set("v.rejectreasonOptions", optsdefault);
        component.set("v.showValidationMessageRejectReason", false);
        
        if(!component.get('v.showStatusUpdateModal')){
            if( selectedContacts.length== 0){
                helper.showToast(component, event, helper, 'Please select atleast 1 Contact', 'warning');
                return;
            }
			component.set('v.selectedIdWithNames', selectedIdWithNames);
        	component.set('v.showStatusUpdateModal', true);
           
		}
    },
    hideAssignTaskModal: function(component, event, helper) { 
    	component.set('v.showAssignTaskModal', false);
        component.set('v.showStatusUpdateModal', false);
    }, 
    
    assignTask: function(component, event, helper) { 
         debugger;
        var selectedStatusToUpdate = component.get ( "v.selectedStatusToUpdate" );
        var contactrejectreason = component.get("v.contactrejectreason");
        if( component.get('v.selectedIdWithNames').length== 0){
            helper.showToast(component, event, helper, 'Please select atleast 1 contact', 'warning');
            return;
        }
        
         /*if( leadrejectreason== 'Select' && (selectedStatusToUpdate =='Nurture')){
           // helper.showToast(component, event, helper, 'Please select Reject Reason', 'warning');
           component.set("v.showValidationMessageRejectReason",true);
            return;
        } else {
            
           component.set("v.showValidationMessageRejectReason",false); 
        }*/
        
        
    	        
        let contactList = component.get("v.contactList");
        let selectedCon = contactList.filter(element => {
              return element.selected
        }) || [];
        let idList= [];
        for (var i = 0; i < selectedCon.length; i++) {
            idList.push(selectedCon[i].Id);
        }
        if(idList.length == 0) return;
        let stringIds = idList.toString();
        if(component.get ( "v.showStatusUpdateModal")){
            helper.updateStatus(component, event, helper, stringIds, component.get ( "v.selectedStatusToUpdate" ),contactrejectreason);
            return;
        }
        var selectedUser = component.get ( "v.selectedUser" );
        var comment = component.find( "comment" ).get ( "v.value" );
        if(component.get ( "v.selectedUser" ) == ''){
            helper.showToast(component, event, helper, 'No active SDR for selected contacts', 'warning');
            return;
        }
        
        helper.assignTasks(component, event, helper, stringIds, comment, selectedUser)
        
    },
        
    removeContact : function(component, event, helper) {
        let selectedContact= event.getSource().get('v.name');
        var contactList =  component.get("v.contactList");
        let selectedIdWithNames = component.get('v.selectedIdWithNames');
        let con = contactList.find(element => element.Id == selectedContact);
        con.selected = false;
        
        var visibledata = component.get("v.visibleAccContObjectArray");
        visibledata.forEach(val => {
            var index = val.Contacts.findIndex((element) => element.Id == selectedContact);
            if(index>-1)
            val.Contacts[index].selected = false; 
        });
        
        let indexOfSelectedRec = selectedIdWithNames.findIndex((element) => element.Id == selectedContact);
        selectedIdWithNames.splice(indexOfSelectedRec, 1);
        component.set('v.selectedIdWithNames', selectedIdWithNames);
        component.set("v.visibleAccContObjectArray", visibledata );
        component.set("v.contactList", contactList);
        helper.showAssignTaskModal(component, event, helper);
    },  
     
    displayRecordByFilter : function(component, event, helper) {
        component.set("v.donotrenderpicklist",true);
        helper.doInit(component, event, helper);
	} ,
    
      // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74.... //
    
    loadStatusOptions: function (component, event, helper) {
         
         debugger;
         var controllerKeyStatus= event.getSource().get("v.value");
         var contactrejectreason = component.get("v.contactrejectreason");
         
         var opts =[];
         if(controllerKeyStatus =='Nurture') {
             
             
         
             opts = [
                 { value: $A.get("$Label.c.LeadRejectReasonActiveOpp"), label: $A.get("$Label.c.LeadRejectReasonActiveOpp")},
                 { value: $A.get("$Label.c.LeadRejectAttempted"), label: $A.get("$Label.c.LeadRejectAttempted")},
                 { value: $A.get("$Label.c.AutouMQLReason"), label: $A.get("$Label.c.AutouMQLReason")},
                 { value: $A.get("$Label.c.LeadRejectContacted"), label: $A.get("$Label.c.LeadRejectContacted")},
                 { value: $A.get("$Label.c.LeadRejectExistingCustomer"), label: $A.get("$Label.c.LeadRejectExistingCustomer")},
                 { value: $A.get("$Label.c.LeadRejectedNoAE"), label: $A.get("$Label.c.LeadRejectedNoAE")},
                 { value: $A.get("$Label.c.LeadRejectPurchasedCompetitor"), label: $A.get("$Label.c.LeadRejectPurchasedCompetitor")},
                 { value: $A.get("$Label.c.LeadRejectedDoNotContact"), label: $A.get("$Label.c.LeadRejectedDoNotContact")},
                 { value: $A.get("$Label.c.LeadRejectSalesFuture"), label: $A.get("$Label.c.LeadRejectSalesFuture")},
                 { value: $A.get("$Label.c.LeadRejectedElevatorPitch"), label: $A.get("$Label.c.LeadRejectedElevatorPitch")},
                 { value: $A.get("$Label.c.LeadRejectedWrongPerson"), label: $A.get("$Label.c.LeadRejectedWrongPerson")}
             ];  
             
              component.set("v.rejectreasonOptions", opts);
             component.set("v.showhideaccounttoConvert", false);
           
         }else if(controllerKeyStatus =='Non-Qualified') {
           opts = [
            { value: $A.get("$Label.c.LeadRejectBadPhone"), label: $A.get("$Label.c.LeadRejectBadPhone")},
            { value: $A.get("$Label.c.LeadRejectBadTitle"), label: $A.get("$Label.c.LeadRejectBadTitle") },
            { value: $A.get("$Label.c.LeadRejectedObjection"), label: $A.get("$Label.c.LeadRejectedObjection") },
            { value: $A.get("$Label.c.LeadRejectPartner"), label: $A.get("$Label.c.LeadRejectPartner") },
            { value: $A.get("$Label.c.LeadRejectRiffRaff"), label: $A.get("$Label.c.LeadRejectRiffRaff") },
            { value: $A.get("$Label.c.LeadRejectedWrongPersonLeftCompany"), label: $A.get("$Label.c.LeadRejectedWrongPersonLeftCompany") }
       	 ];  
           component.set("v.rejectreasonOptions", opts);
           component.set("v.showhideaccounttoConvert", false);
         }
         
         else  {
             opts = [];
            component.set("v.rejectreasonOptions", opts);
            component.set("v.showValidationMessageRejectReason", false);
          
         }
 },
    
    ContactScoreFilter : function(component, event, helper) {

       
        helper.doInit(component, event, helper);
	},
  
})