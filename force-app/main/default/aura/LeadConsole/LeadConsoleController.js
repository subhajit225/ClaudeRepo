({
    showContent : function(component, event, helper) {
		component.set('v.showContent', !component.get('v.showContent'));
	},
    
    selectAll: function(component, event, helper) {
        var visibleLeadRecords = component.get("v.visibleLeadRecords");  
        var visibleLeads = component.get("v.visibleLeads");
        let allLeadRecords = component.get("v.allLeadRecords");
         visibleLeadRecords.forEach(obj => {
            obj.selected = event.getSource().get( "v.checked" );
            let leadRec = allLeadRecords.filter(element => {
                    return (element.Id == obj.Id )
                }) 
            leadRec[0].selected  = event.getSource().get( "v.checked" );
             
            let visibleRec = visibleLeads.filter(element => {
                    return (element.Id == obj.Id )
                }) 
            leadRec[0].selected  = event.getSource().get( "v.checked" ); 
            
        });
        component.set("v.visibleLeadRecords",visibleLeadRecords); 
          
        
        
        /*visibleLeads.forEach(obj => {
            obj.selected = event.getSource().get( "v.checked" );
            let leadRec = allLeadRecords.filter(element => {
                    return (element.Id == obj.Id )
                }) 
             leadRec[0].selected  = event.getSource().get( "v.checked" );
            
        });*/
        component.set("v.visibleLeads",visibleLeads);
        component.set("v.allLeadRecords", allLeadRecords);    
            
    },
    importToSalesloft: function(component, event, helper) {
        let allLeadRecords = component.get("v.allLeadRecords");
        let selectedLeads = allLeadRecords.filter(element => {
              return element.selected
        }) || [];
        let idList= [];
        for (var i = 0; i < selectedLeads.length; i++) {
            idList.push(selectedLeads[i].Id);
        }
        if(idList.length == 0) return;
        let stringIds = idList.toString();
        var myurl = "https://app.salesloft.com/app/import/crm?lead=" + stringIds;

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
    
    showStatusUpdateModal: function(component, event, helper) { 
        debugger;
        let leadList = component.get("v.allLeadRecords");
        var selectedIdWithNames =[];
        let selectedleads = leadList.filter(element => {
              return element.selected
        }) || [];

        selectedleads.forEach(record => {
            selectedIdWithNames.push({Id: record.Id, Name: record.Name});
            
        });
        if(!component.get('v.showStatusUpdateModal')){
            if( selectedleads.length== 0){
                helper.showToast(component, event, helper, 'Please select atleast 1 lead', 'warning');
                return;
            }
			component.set('v.selectedIdWithNames', selectedIdWithNames);
        	component.set('v.showStatusUpdateModal', true);
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
       /* optsdefault = [
            { value: $A.get("$Label.c.LeadRejectReasonActiveOpp"), label: $A.get("$Label.c.LeadRejectReasonActiveOpp")},
            { value: $A.get("$Label.c.LeadRejectContacted"), label: $A.get("$Label.c.LeadRejectContacted")},
            { value: $A.get("$Label.c.LeadRejectAttempted"), label: $A.get("$Label.c.LeadRejectAttempted")},
            { value: $A.get("$Label.c.LeadRejectExistingCustomer"), label: $A.get("$Label.c.LeadRejectExistingCustomer")}
        ]; */
        
        component.set("v.selectedStatusToUpdate", 'Nurture');
        component.set("v.rejectreasonOptions", optsdefault);
        component.set("v.leadrejectreason", 'Select');
        component.set("v.selectedLookUpRecord","[]");
        component.set("v.showValidationMessageRejectReason",false);
        component.set("v.showValidationMessageConvertAccount",false);
        
        component.set("v.showhideaccounttoConvert", true);
		}
    },
 	
    hideStatusUpdateModal: function(component, event, helper) { 
    	component.set('v.showStatusUpdateModal', false);
    },
        
        
        
    showChangeOwnerModal: function(component, event, helper) { 
        debugger;
        let leadList = component.get("v.allLeadRecords");
        var selectedIdWithNames =[];
        let selectedleads = leadList.filter(element => {
              return element.selected
        }) || [];

        selectedleads.forEach(record => {
            selectedIdWithNames.push({Id: record.Id, Name: record.Name});
            
        });
        if(!component.get('v.showChangeOwnerModal')){
            if( selectedleads.length== 0){
                helper.showToast(component, event, helper, 'Please select atleast 1 lead', 'warning');
                return;
            }
			component.set('v.selectedIdWithNames', selectedIdWithNames);
				component.set('v.showChangeOwnerModal', true);
            component.set("v.showValidationMessageSelectUserQueue",false); 
             component.set('v.showMessagedefaultqueue',false);
            component.set("v.objectName",'user'); 
             component.set("v.selectedLeadOwnerType",'User');
            component.set('v.selectedLookUpRecordLeadOwner.Id',null);
            component.set('v.showMessagedefaultqueue',false);
            
            
        	
        
		}
    },
        
    hideChangeLeadOwnereModal: function(component, event, helper) { 
    	component.set('v.showChangeOwnerModal', false);
    },
        
     
    updateStatus: function(component, event, helper) { 
        debugger;
        if( component.get('v.selectedIdWithNames').length== 0){
            helper.showToast(component, event, helper, 'Please select atleast 1 lead', 'warning');
            return;
        }
    	var selectedStatusToUpdate = component.get ( "v.selectedStatusToUpdate" );
        var leadrejectreason = component.get("v.leadrejectreason");
        var accounttoConvert = component.get("v.selectedLookUpRecord").Id;
        
        if( leadrejectreason== 'Select' && (selectedStatusToUpdate =='Nurture' || selectedStatusToUpdate =='Non-Qualified')){
           // helper.showToast(component, event, helper, 'Please select Reject Reason', 'warning');
           component.set("v.showValidationMessageRejectReason",true);
            return;
        } else {
            
           component.set("v.showValidationMessageRejectReason",false); 
        }
        if(component.get("v.selectedLookUpRecord").Id == undefined && (selectedStatusToUpdate =='Nurture' && (leadrejectreason =='AE Active Opp' || leadrejectreason =='Existing Customer' ))){
           // helper.showToast(component, event, helper, 'Please select Reject Reason', 'warning');
           component.set("v.showValidationMessageConvertAccount",true);
            return;
        } else {
            
           component.set("v.showValidationMessageConvertAccount",false); 
        }
       
        
        
        let allLeadRecords = component.get("v.allLeadRecords");
        let selectedLead = allLeadRecords.filter(element => {
              return element.selected
        }) || [];
        let idList= [];
        for (var i = 0; i < selectedLead.length; i++) {
            idList.push(selectedLead[i].Id);
        }
        if(idList.length == 0) return;
        let stringIds = idList.toString();
        helper.updateStatus(component, event, helper, stringIds, selectedStatusToUpdate,leadrejectreason,accounttoConvert);
        
    },
        
 	removeLead : function(component, event, helper) {
        let selectedLead= event.getSource().get('v.name');
        var allLeadRecords =  component.get("v.allLeadRecords");
        var visibleLeadRecords = component.get("v.visibleLeadRecords");  
        var visibleLeads = component.get("v.visibleLeads");
        let selectedIdWithNames = component.get('v.selectedIdWithNames');
        let lead = allLeadRecords.find(element => element.Id == selectedLead);
        lead.selected = false;
        
        let lead1 = visibleLeadRecords.find(element => element.Id == selectedLead);
    	if(lead1)    
    		lead1.selected = false;       
        
        let lead2 = visibleLeads.find(element => element.Id == selectedLead);
        if(lead2)    
    		lead2.selected = false;  
    
        let indexOfSelectedRec = selectedIdWithNames.findIndex((element) => element.Id == selectedLead);
        selectedIdWithNames.splice(indexOfSelectedRec, 1);
        component.set('v.selectedIdWithNames', selectedIdWithNames);
        component.set("v.allLeadRecords", allLeadRecords );
        component.set("v.visibleLeadRecords", visibleLeadRecords);
    	component.set("v.visibleLeads", visibleLeads);
    },
        
	doInit : function(component, event, helper) {
        helper.doInit(component, event, helper);
	},
    
    sort : function(component, event, helper) { 
        helper.sortRecords(component, event, helper);
    },
    
    applyThemeFilters : function(component, event, helper) { 
        if(component.get("v.isDataLoading")) return;
        component.set('v.showContent', false);
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
        if(component.get("v.isDataLoading")) return;
        component.set('v.showContent', false);
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
        if(component.get("v.isDataLoading")) return;
        helper.applyAccountFilters(component, event, helper);
    },
        
        applyTierFilters : function(component, event, helper) { 
        if(component.get("v.isDataLoading")) return;
        helper.applyTierFilters(component, event, helper);
    },
        
        applyLeadOnwerFilters : function(component, event, helper) { 
        if(component.get("v.isDataLoading")) return;
        helper.applyLeadOnwerFilters(component, event, helper);
    },

    loadStatusOptionsRejectReason: function (component, event, helper) {
        var leadrejectreason = component.get("v.leadrejectreason");

        if(leadrejectreason !='AE Active Opp' && leadrejectreason !='Existing Customer') {
             
              component.set("v.showhideaccounttoConvert",false);
              component.set("v.showValidationMessageConvertAccount",false);
          }else {

            component.set("v.showhideaccounttoConvert",true);
            component.set("v.showValidationMessageConvertAccount",false);

          }

    },
        
        
     loadStatusOptions: function (component, event, helper) {
         
         debugger;
         var controllerKeyStatus= event.getSource().get("v.value");
         var leadrejectreason = component.get("v.leadrejectreason");
         
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
             component.set("v.showhideaccounttoConvert",true);
         }
         else if(controllerKeyStatus =='Non-Qualified') {
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
         else if(controllerKeyStatus =='Sales Nurture') {
             opts = [];
            component.set("v.rejectreasonOptions", opts);
           component.set("v.showhideaccounttoConvert",false);
         }

       
        
    }  ,

    displayRecordByFilter : function(component, event, helper) {

        component.set("v.donotrenderpicklist",true);
        
        helper.doInit(component, event, helper);
	},
        
    leadScoreFilter : function(component, event, helper) {

       
        helper.doInit(component, event, helper);
	},
     
        
    updateLeadOwner: function(component, event, helper) { 
        debugger;
        if( component.get('v.selectedIdWithNames').length== 0){
            helper.showToast(component, event, helper, 'Please select atleast 1 lead', 'warning');
            return;
        }
    	var selectedLeadOwnerType = component.get ( "v.selectedLeadOwnerType" );
        var leadowner = component.get("v.selectedLookUpRecordLeadOwner").Id;
        
        
       if(leadowner == undefined && selectedLeadOwnerType =='User') {
          
           component.set("v.showValidationMessageSelectUserQueue",true);
            component.set('v.showMessagedefaultqueue',false);
           return;
        } else {
            
           component.set("v.showValidationMessageSelectUserQueue",false); 
            
        }
        
       
        
        
        let allLeadRecords = component.get("v.allLeadRecords");
        let selectedLead = allLeadRecords.filter(element => {
              return element.selected
        }) || [];
        let idList= [];
        for (var i = 0; i < selectedLead.length; i++) {
            idList.push(selectedLead[i].Id);
        }
        if(idList.length == 0) return;
        let stringIds = idList.toString();
        helper.updateLeadOwner(component, event, helper, stringIds, selectedLeadOwnerType,leadowner);
        
    },
        
      setuserqueueOptions: function(component, event, helper) {
		debugger;
        var controllerKeyuserQueue= event.getSource().get("v.value");
       
        
        if(controllerKeyuserQueue =='User') {
             
            component.set('v.objectName', "user");
            component.set('v.showMessagedefaultqueue',false);
            

        }
        else {
            
            component.set('v.objectName', "group");
            component.set('v.selectedLookUpRecordLeadOwner.Id',null);
            component.set('v.showValidationMessageSelectUserQueue',false);
            
            component.set('v.showMessagedefaultqueue',true);
            
            
        }



    },
        
         whatIdChanged:function(component, event, helper) { 
            
             var leadowner = component.get("v.selectedLookUpRecordLeadOwner").Id;
             var selectedLeadOwnerType = component.get ( "v.selectedLeadOwnerType" );
             if(leadowner != undefined && selectedLeadOwnerType=='Queue'){
                
                  component.set('v.showMessagedefaultqueue',false);
             } else {
                 if(selectedLeadOwnerType=='Queue')
                 	component.set('v.showMessagedefaultqueue',true);
             }
             
    			
    }
})