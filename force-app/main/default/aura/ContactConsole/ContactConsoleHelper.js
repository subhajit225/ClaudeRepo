({ 
    doInit : function(component, event, helper) {
        component.set("v.isDataLoading", true);
        component.set("v.selectedAccounts", []);
        component.set("v.selectedCampaigns", []);
        component.set("v.selectedGTM", []);
        component.set("v.selectedStatuses", []);
		component.set("v.accountTier", []);
        component.set("v.contactStatus", []);
        component.set("v.selectedOwners", []);
         component.set("v.selectedContactOwners", []);
        component.set("v.clickedMatrix", '');
        component.find('allCheckBox').set('v.checked',false);
        component.set("v.showSpinner", true);
        var recID = component.get("v.recordId");
        var ContactScoreMap = component.get("v.ContactScoreMap");
       
        console.log('ContactScoreMap>>'+JSON.stringify(ContactScoreMap));
        var donotrenderpicklist = component.get("v.donotrenderpicklist");
        var accountStatusValue = (component.find("StatusSelect").get("v.value") == undefined || component.find("StatusSelect").get("v.value") == '') ? "None" : component.find("StatusSelect").get("v.value");
        console.log('accountStatusValue---',JSON.stringify(accountStatusValue));
        var action = component.get("c.getAccountContacts");
        action.setParams({
            "displayRecordBy":component.get("v.defaultFilter"),
            "fitScoremap":ContactScoreMap,
            "filterLowScoredRecordsFromView" : component.get("v.filterLowScoredRecordsFromView"),
            "accountStatus" : accountStatusValue
        });
        action.setCallback(this, function(response){
            component.set("v.isDataLoading", false);
            component.set("v.showSpinner", false);
            if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                    	helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            if(!donotrenderpicklist){
                var accountStatusOpt =[
                    {value: "Active Opportunity", label: "Active Opportunity"},
                    {value: "Existing Customer", label: "Existing Customer"},
                    {value: "Customer w/Opp", label: "Customer w/Opp"},
                    {value: "Lost Opportunity", label: "Lost Opportunity"},
                    {value: "Prospect", label: "Prospect"},
                    {value: "No Account Match", label: "No Account Match"}
                ];
                component.set("v.accountStatus",accountStatusOpt); 
            }
           
            var data = response.getReturnValue();
            console.log('ANKUSH REQUEST >>>'+JSON.stringify(data.contactRecords));
            helper.handleResponse(component, event, helper, data, true);            
        });
        $A.enqueueAction(action);
        component.set("v.selectedAccountStatus",accountStatusValue);
    },

    
    createFormatedDate : function(component, helper, numberOfDaysToAdd) {
        var todays =  new Date();
        todays.setDate(todays.getDate() + numberOfDaysToAdd);
        var dd = (todays.getDate() >= 10) ? todays.getDate() : ('0' + (todays.getDate()));
        var mm = ((todays.getMonth() + 1) >= 10) ? (todays.getMonth() + 1) : ('0' + (todays.getMonth() + 1));
        var y = todays.getFullYear();
        return y + '-' + mm + '-' + dd ;
    },
    
	formatData : function(component, event, helper, contacts, refreshView) {
        
        
         var openCount =0;
        var workignCount =0;
        var meetingsetCount =0;
                
        var activeContacts= contacts.filter(element => {
              return element.eventsIn4Days >0 || element.tasksIn4Days >0
        }) || [];
        var activeContactIds = [];
        
         contacts.forEach(val => {
            if(val.Contact_Status__c == 'Open'){
             openCount++
          }
          if(val.Contact_Status__c == 'Working'){
             workignCount++
          }
        if(val.Contact_Status__c == 'Meeting Set'){
             meetingsetCount++
          }
        });
        
        for(var i=0; i< activeContacts.length; i++){
            activeContacts[i].matricStatus = 'Active';
            activeContactIds.push(activeContacts[i].Id);
        }
        var staleContacts= contacts.filter(element => {
              return (element.neglectedEvents >0 || element.neglectedTasks >0) && !activeContactIds.includes(element.Id)
        }) || [];
        staleContacts.forEach(val => {
            val.matricStatus = 'stale';
        });
        var untouchedContacts= contacts.filter(element => {
              return !element.Events && !element.Tasks
        }) || [];
        untouchedContacts.forEach(val => {
            val.matricStatus = 'untouched';
        });
           component.set('v.noOfOpenContacts', openCount);   
              component.set('v.noOfWorkingContacts', workignCount);  
              component.set('v.noOfMeetingSetContacts', meetingsetCount);  
        component.set('v.noOfContacts', contacts.length);
        component.set('v.activeContacts', activeContacts.length);
        component.set('v.staleContacts', staleContacts.length);
        component.set('v.unTouchedContacts', untouchedContacts.length);
           console.log('INSIDE DATA FORMAT LOG'+JSON.stringify(contacts));
      /*  
		let accIdSet = new Set();
        let conId = [];
        for (var i = 0; i < contacts.length; i++) {
            conId.push(contacts[i].Id);
            if(contacts[i].AccountId)
          		accIdSet.add(contacts[i].AccountId);
        }
       
              var currentOrder = false;
              var currentList = contacts;
             
     */
            
         component.set('v.contactList', contacts);
        let totalPages = contacts.length/50 + (contacts.length%50 >0 ? 1: 0);
        var pageOptions = [];
        for(var i= 1; i<= totalPages; i++){
            pageOptions.push(i);
        }
       
      //  var contactOppList = component.get("v.contactOppList");
       // var oppList= contactOppList.filter(element => {
              //return conId.includes(element.Initial_Contacts_Name__c)
      //  }) || [];
        
        //component.set('v.visibleContactOppList', oppList);
        
                              
       // if(refreshView){
            component.set('v.selectedPage', 1);
            component.set('v.pageOptions', pageOptions);
           console.log('INSIDE PAGE PAGINATION ');
            helper.paginationResults(component, event, helper);
       // }
	},
    
    paginationResults : function(component, event, helper) {
        
        var contactList = component.get('v.contactList') || [];
        var contactListfinal;
        var startIndex = (component.get('v.selectedPage')-1)*50;
        var endIndex = component.get('v.selectedPage')*50;
        if(endIndex > contactList.length)
        	endIndex = contactList.length;
        	
       let visibleContact = [];
        for(var i = startIndex; i< endIndex ; i++){
           if(contactList[i].Composite_Score1__c){
               contactList[i].Composite_Score1__c = parseFloat(contactList[i].Composite_Score1__c).toFixed(2);
            }
            visibleContact.push(contactList[i]);
        }
        console.log('VISIBLE CONTACT >'+JSON.stringify(visibleContact.CampaignMembers));
        component.set('v.visibleContactRecords', visibleContact );
        
        
       // component.set('v.contactList', contactList );
       // console.log('visibleAccCon>>'+component.get('v.visibleAccContObjectArray'));
    },
    applyFilters : function(component, event, helper) { 
        debugger;
        component.find('allCheckBox').set('v.checked',false);
        let contacts = component.get("v.allcontactList");
        let selectedCampaigns = component.get("v.selectedCampaigns");
        let selectedAccounts = component.get("v.selectedAccounts");
        let selectedGTM = component.get("v.selectedGTM");
        let selectedStatuses = component.get("v.selectedStatuses");
		 let accountTier = component.get("v.accountTier");
         let contactStatus = component.get("v.contactStatus");
        let selectedOwners = component.get("v.selectedOwners");
         let selectedContactOwners = component.get("v.selectedContactOwners");
        let filteredContacts = [];
        for (var i = 0; i < contacts.length; i++) {
            var contactFilteredByCamp = null;
            if(selectedCampaigns.length != 0 && selectedGTM.length !=0){
                if(contacts[i].CampaignMembers){
                    let campaignRecs = contacts[i].CampaignMembers.filter(element => {
                        return (selectedCampaigns.includes(element.CampaignId) && selectedGTM.includes(element.Campaign.GTM_Play__c))
                    })
                    if(campaignRecs.length>0)
                        contactFilteredByCamp = contacts[i];
                }
                
            }else if(selectedCampaigns.length != 0 ){
                if(contacts[i].CampaignMembers){
                    let campaignRecs = contacts[i].CampaignMembers.filter(element => {
                        return (selectedCampaigns.includes(element.CampaignId) )
                    })
                    if(campaignRecs.length>0)
                        contactFilteredByCamp = contacts[i];
                }
                
            }else if(selectedGTM.length !=0){
                if(contacts[i].CampaignMembers){
                    let campaignRecs = contacts[i].CampaignMembers.filter(element => {
                        return ( selectedGTM.includes(element.Campaign.GTM_Play__c))
                    })
                    if(campaignRecs.length>0)
                        contactFilteredByCamp = contacts[i];
                }
                
            }
            else{
                contactFilteredByCamp = contacts[i];
            }
            if(contactFilteredByCamp != null)
            	filteredContacts.push(contactFilteredByCamp);
        }
        var contactFilteredByCampAndAccount = null;
        if(selectedAccounts.length != 0 ){
            contactFilteredByCampAndAccount= filteredContacts.filter(element => {
                            return ( selectedAccounts.includes(element.AccountId))
                        })
        }else{
            contactFilteredByCampAndAccount= filteredContacts;
        }
        
        
        var contactFilteredByCampAndAccountAndOwner = null;
        if(selectedOwners.length != 0 ){
            contactFilteredByCampAndAccountAndOwner= contactFilteredByCampAndAccount.filter(element => {
                            return ( selectedOwners.includes(element.Account.OwnerId))
                        })
        }else{
            contactFilteredByCampAndAccountAndOwner= contactFilteredByCampAndAccount;
        }
        
        var contactFilteredByCampAndContactAndOwner = null;
        if(selectedContactOwners.length != 0 ){
            contactFilteredByCampAndContactAndOwner= contactFilteredByCampAndAccountAndOwner.filter(element => {
                            return ( selectedContactOwners.includes(element.OwnerId))
                        })
        }else{
            contactFilteredByCampAndContactAndOwner= contactFilteredByCampAndAccountAndOwner;
        }
        
        
        var contactFilteredByCampAndAccountAndOwnerAndStatus = null;
        if(selectedStatuses.length != 0 ){
            contactFilteredByCampAndAccountAndOwnerAndStatus= contactFilteredByCampAndContactAndOwner.filter(element => {
                            return ( selectedStatuses.includes(element.Contact_Follow_Up_Status__c))
                        })
        }else{
            contactFilteredByCampAndAccountAndOwnerAndStatus= contactFilteredByCampAndContactAndOwner;
        }
		
		
		var contactFilteredByCampAndAccountAndOwnerAndStatusAndTier = null;
        if(accountTier.length != 0 ){
            contactFilteredByCampAndAccountAndOwnerAndStatusAndTier= contactFilteredByCampAndAccountAndOwnerAndStatus.filter(element => {
                            return ( accountTier.includes(element.Account_Tier__c))
                        })
        }else{
            contactFilteredByCampAndAccountAndOwnerAndStatusAndTier= contactFilteredByCampAndAccountAndOwnerAndStatus;
        }
        
        var contactFilteredByCampAndAccountAndOwnerAndStatusAndContactStatus = null;
        if(contactStatus.length != 0 ){
            contactFilteredByCampAndAccountAndOwnerAndStatusAndContactStatus= contactFilteredByCampAndAccountAndOwnerAndStatusAndTier.filter(element => {
                            return ( contactStatus.includes(element.Contact_Status__c))
                        })
        }else{
            contactFilteredByCampAndAccountAndOwnerAndStatusAndContactStatus= contactFilteredByCampAndAccountAndOwnerAndStatusAndTier;
        }
		
		
		
        var contactFilteredByCampAndAccountAndStatusAndMatrix= null;
        if(component.get("v.clickedMatrix")){
            contactFilteredByCampAndAccountAndStatusAndMatrix= contactFilteredByCampAndAccountAndOwnerAndStatusAndContactStatus.filter(element => {
                            return ( element.matricStatus == component.get("v.clickedMatrix") )
                        })
        }else{
            contactFilteredByCampAndAccountAndStatusAndMatrix= contactFilteredByCampAndAccountAndOwnerAndStatusAndContactStatus;
        }
        component.set("v.visibleContacts",contactFilteredByCampAndAccountAndStatusAndMatrix);
        helper.formatData(component, event, helper, contactFilteredByCampAndAccountAndStatusAndMatrix, true);
            

    },
    getFilters : function(component, event, helper, data, isFilterApplied, isCampaignFilterApplied) {
        debugger;
        let accArray = [];
        let accIdArray = [];
        let camArray = [];
        let themeArray = [];
        let camIdArray = [];
        let gtmThemeArray = [];
        let contacts =[];
        let statusArray = [];
		let tierArray=[];
        let contactStatusArray=[];
        let contactStatusIdArray=[];
		let tierIdArray=[];
        let statusIdArray = [];
        let ownerArray = [];
        let ownerIdArray = [];
        let ContactownerArray = [];
        let ContactownerIdArray = [];
        let timestamp1Year = helper.createFormatedDate(component, helper, -365);
        if(isFilterApplied)
            contacts = component.get("v.visibleContacts");
        else{
            contacts = data.contactRecords;
        }
        for (var i = 0; i < contacts.length; i++) {
            if(contacts[i].Account.OwnerId){
                if(!ownerIdArray.includes(contacts[i].Account.OwnerId)){
                let ownerLabelValuePair = {};
                ownerLabelValuePair.label = contacts[i].Account.Owner.Name;
                ownerLabelValuePair.value = contacts[i].Account.OwnerId;
                ownerIdArray.push(contacts[i].Account.OwnerId);    
                ownerArray.push(ownerLabelValuePair);
                }
            } 
            
             if(contacts[i].OwnerId){
                if(!ContactownerIdArray.includes(contacts[i].OwnerId)){
                let contactownerLabelValuePair = {};
                contactownerLabelValuePair.label = contacts[i].Owner.Name;
                contactownerLabelValuePair.value = contacts[i].OwnerId;
                ContactownerIdArray.push(contacts[i].OwnerId);    
                ContactownerArray.push(contactownerLabelValuePair);
                }
            } 
            if(contacts[i].Contact_Follow_Up_Status__c){
                if(!statusIdArray.includes(contacts[i].Contact_Follow_Up_Status__c)){
                let statusLabelValuePair = {};
                statusLabelValuePair.label = contacts[i].Contact_Follow_Up_Status__c;
                statusLabelValuePair.value = contacts[i].Contact_Follow_Up_Status__c;
                statusIdArray.push(contacts[i].Contact_Follow_Up_Status__c);    
                statusArray.push(statusLabelValuePair);
                }
            }
			
			if(contacts[i].Account_Tier__c){
                if(!tierIdArray.includes(contacts[i].Account_Tier__c)){
                let tierLabelValuePair = {};
                tierLabelValuePair.label = contacts[i].Account_Tier__c;
                tierLabelValuePair.value = contacts[i].Account_Tier__c;
                tierIdArray.push(contacts[i].Account_Tier__c);    
                tierArray.push(tierLabelValuePair);
                }
            }
            
            if(contacts[i].Contact_Status__c){
                if(!contactStatusIdArray.includes(contacts[i].Contact_Status__c)){
                let ContactStatusLabelValuePair = {};
                ContactStatusLabelValuePair.label = contacts[i].Contact_Status__c;
                ContactStatusLabelValuePair.value = contacts[i].Contact_Status__c;
                contactStatusIdArray.push(contacts[i].Contact_Status__c);    
                contactStatusArray.push(ContactStatusLabelValuePair);
                }
            }
            console.log('contactStatusArray>>'+JSON.stringify(contactStatusArray));
                        
            if(contacts[i].AccountId){
                if(!accIdArray.includes(contacts[i].AccountId)){
                let accLabelValuePair = {};
                accLabelValuePair.label = contacts[i].Account.Name;
                accLabelValuePair.value = contacts[i].AccountId;
                accIdArray.push(contacts[i].AccountId);    
                accArray.push(accLabelValuePair);
                }
            }
            
            var campaignMembers= contacts[i].CampaignMembers;
            if(campaignMembers){
                for (var j = 0; j < campaignMembers.length; j++) {
                    if(!camIdArray.includes(campaignMembers[j].Campaign.Id) && (campaignMembers[j].Campaign.Always_On__c || (campaignMembers[j].Campaign.IsActive && campaignMembers[j].Campaign.CreatedDate >= timestamp1Year ))){
                        let camLabelValuePair = {};
                        camLabelValuePair.label = campaignMembers[j].Campaign.Name;
                        camLabelValuePair.value = campaignMembers[j].Campaign.Id;
                        camLabelValuePair.gtmPlay = campaignMembers[j].Campaign.GTM_Play__c;
                        camIdArray.push(campaignMembers[j].Campaign.Id);    
                        camArray.push(camLabelValuePair);
                    }
                    if(!gtmThemeArray.includes(campaignMembers[j].Campaign.GTM_Play__c) && campaignMembers[j].Campaign.GTM_Play__c){
                        let gtmLabelValuePair = {};
                        gtmLabelValuePair.label = campaignMembers[j].Campaign.GTM_Play__c;
                        gtmLabelValuePair.value = campaignMembers[j].Campaign.GTM_Play__c;
                        gtmThemeArray.push(campaignMembers[j].Campaign.GTM_Play__c);    
                        themeArray.push(gtmLabelValuePair);
                    }
                    
                }
            }
            
        }
        var selectedCampaigns = component.get("v.selectedCampaigns") || [];
        var selectedAccounts = component.get("v.selectedAccounts") || [];
        var selectedGTM = component.get("v.selectedGTM") || [];
        var selectedStatuses = component.get("v.selectedStatuses") || [];
		
		 var accountTier = component.get("v.accountTier") || [];
         var contactStatus = component.get("v.contactStatus") || [];
        var selectedOwners = component.get("v.selectedOwners") || [];
         
 		var selectedContactOwners = component.get("v.selectedContactOwners") || [];
        
        if(selectedCampaigns.length ==0){
        	component.set("v.campaignPicklistOptions",camArray);
        }
           component.set("v.uniqueAccounts",accArray.length);
        
        if(selectedAccounts.length ==0)
           component.set("v.accountPicklistOptions",accArray);
        
        if(selectedGTM.length ==0){
            component.set("v.gtmPlayPicklistOptions",themeArray);
            if(selectedCampaigns.length >0){
                let campaignOptRecs = camArray.filter(element => {
                    return (selectedCampaigns.includes(element.value))
                })
                var flags = [], output = [],  i;
                for( i=0; i<campaignOptRecs.length; i++) {
                    if( flags[campaignOptRecs[i].gtmPlay]) continue;
                    flags[campaignOptRecs[i].gtmPlay] = true;
                    if(campaignOptRecs[i]){
                        let gtmLabelValuePair = {};
                        gtmLabelValuePair.label = campaignOptRecs[i].gtmPlay;
                        gtmLabelValuePair.value = campaignOptRecs[i].gtmPlay;
                        output.push(gtmLabelValuePair);
                    }
                }
                component.set("v.gtmPlayPicklistOptions",output);
            }
        }else{
            if(selectedCampaigns.length ==0){
                let campaignRecs = camArray.filter(element => {
                    return  selectedGTM.includes(element.gtmPlay)
                })
                component.set("v.campaignPicklistOptions",campaignRecs);
                
            }
        }
        if(selectedStatuses.length ==0){
            component.set("v.statusPicklistOptions",statusArray);
        }
		
		if(accountTier.length ==0){
            component.set("v.accountTierPicklistOption",tierArray);
        }
        
        if(contactStatus.length ==0){
            component.set("v.contactStatusPicklistOption",contactStatusArray);
        }
		
		
		
        if(selectedOwners.length ==0){
            component.set("v.ownerPicklistOptions",ownerArray);
              
        }
        
          if(selectedContactOwners.length ==0){
            component.set("v.ContactownerPicklistOptions",ContactownerArray);
              
        }
    },
    
    sortRecords: function(component, event, helper) {
        debugger;
        component.set("v.showSpinner", true); 
        var whichOne = event.currentTarget.id;
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                var currentOrder = component.get("v.sortAsc"),
                    currentList = component.get("v.contactList");
                currentOrder = !currentOrder;
                
                currentList.sort(function(a,b) {
                   /* if(whichOne == 'contacts[i].Account'){
                        var x = a[whichOne] ? parseFloat(a[whichOne]) : 0;
                        var y = b[whichOne] ? parseFloat(b[whichOne]) : 0;
                        
                        var t1 = (Math.round(x * 100) || '') == (Math.round(y * 100) || ''),
                            t2 = (Math.round(x * 100) || '') < (Math.round(y * 100) || '');
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1); 
                    } */
                    
                     if(whichOne == 'AccountOwner' ) {
                        a.Account.Owner['Name'] = a.Account.Owner['Name'] || '';
                        b.Account.Owner['Name'] = b.Account.Owner['Name'] || '';
                        var t1 = a.Account.Owner['Name'].toString().toUpperCase() == b.Account.Owner['Name'].toString().toUpperCase(), t2 = a.Account.Owner['Name'].toString().toUpperCase() < b.Account.Owner['Name'].toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                    if(whichOne == 'AccountName' ) {
                        a.Account.Name = a.Account.Name  || '';
                        b.Account.Name  = b.Account.Name  || '';
                        var t1 = a.Account.Name .toString().toUpperCase() == b.Account.Name.toString().toUpperCase(), t2 = a.Account.Name.toString().toUpperCase() < b.Account.Name.toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                     if(whichOne == 'Account_Status__c' ) {
                        a.Account.Name = a.Account_Routing_Status__c  || '';
                        b.Account.Name  = b.Account_Routing_Status__c  || '';
                        var t1 = a.Account_Routing_Status__c.toString().toUpperCase() == b.Account_Routing_Status__c.toString().toUpperCase(), t2 = a.Account_Routing_Status__c.toString().toUpperCase() < b.Account_Routing_Status__c.toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                    if(whichOne == 'Composite_Score1__c'){	
                        var x = a[whichOne] ? parseFloat(a[whichOne]) : 0;	
                        var y = b[whichOne] ? parseFloat(b[whichOne]) : 0;	
                        	
                        var t1 = (Math.round(x * 100) || '') == (Math.round(y * 100) || ''),	
                            t2 = (Math.round(x * 100) || '') < (Math.round(y * 100) || '');	
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1); 	
                    }
                    if(whichOne == 'Account_Tier__c' ) {
                       a[whichOne] = a[whichOne] || '';
                        b[whichOne] = b[whichOne] || '';                  
                        var t1 = a[whichOne].toString().toUpperCase() == b[whichOne].toString().toUpperCase(), t2 = a[whichOne].toString().toUpperCase() < b[whichOne].toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                    
                    
                    else {
                        a[whichOne] = a[whichOne] || '';
                        b[whichOne] = b[whichOne] || '';                  
                        var t1 = a[whichOne].toString().toUpperCase() == b[whichOne].toString().toUpperCase(), t2 = a[whichOne].toString().toUpperCase() < b[whichOne].toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                });
                component.set("v.sortAsc", currentOrder);
                component.set("v.contactList", currentList);
                component.set('v.selectedPage', 1);
                helper.paginationResults(component, event, helper);
            }), 7
        );
    },
    
    assignTasks : function(component, event, helper, contactIds, comment, usrId) {
        var recID = component.get("v.recordId");
        var action = component.get("c.assignFollowUpTask");
        action.setParams({
            "contactIds": contactIds,
            "comment": comment,
            "usrId" : usrId
        });
         component.set("v.showSpinner", true);
        action.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            component.set('v.showAssignTaskModal', false);
            component.set('v.showStatusUpdateModal', false);
            var state = response.getState();
            if (state === "SUCCESS") {
                 
                if(!response.getReturnValue().isSuccess){
                    let errorMsg= "Failed to assign "+ component.get('v.selectedIdWithNames').length +" follow up tasks - "+response.getReturnValue().errorMessage+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMsg , 'error');
                    return;
                }
                var data = component.get("v.responseData");
                var savedContacts = response.getReturnValue().contactRecords;
                for (var i = 0; i < savedContacts.length; i++) {
                    var index = data.contactRecords.findIndex((element) => element.Id == savedContacts[i].Id);
                    data.contactRecords[index] = savedContacts[i]; 
                }
                var visibledata = component.get("v.visibleAccContObjectArray");
                for (var i = 0; i < savedContacts.length; i++) {
                    visibledata.forEach(val => {
                        var index = val.Contacts.findIndex((element) => element.Id == savedContacts[i].Id);
                        if(index>-1)
                            val.Contacts[index] = savedContacts[i]; 
                    });
                    
                }
                component.set("v.visibleAccContObjectArray", visibledata );
            	helper.handleResponse(component, event, helper, data, false);
                var sdr = component.get("v.responseData.sdrUsers").find(o => o.UserId == usrId);
                var message = 'Successfully assigned '+ component.get('v.selectedIdWithNames').length + ' follow up tasks to '+ sdr.User.Name;
                helper.showToast(component, event, helper, message, 'success' );
                
            }else if (state === "ERROR") {
                
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        var errorMessage = '';
                        if(errors[0].message)
                        	errorMessage= "Failed to assign "+ component.get('v.selectedIdWithNames').length +" follow up tasks - "+errors[0].message+" ,please send this to your SFDC admin";
						else if(errors[0].pageErrors)	
                            errorMessage= "Failed to assign "+ component.get('v.selectedIdWithNames').length +" follow up tasks - "+errors[0].pageErrors+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMessage , 'error');
                       
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    handleResponse:function(component, event, helper, data, refreshView){
        var contacts =  data.contactRecords;
        var timestamp4Days = helper.createFormatedDate(component, helper, -4);
        var timestamp1Year = helper.createFormatedDate(component, helper, -365);

          // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74.... //
        var isManager = data.isManager;
        var donotrenderpicklist = component.get("v.donotrenderpicklist");
	    console.log('MANAGER FLAG+'+ JSON);
        if(!donotrenderpicklist) {

                    var opts = [];
                    if(isManager==true) {
                    opts = [
                    { value: "MQL", label: "MQL"},
                    { value: "All", label: "All"},
                    { value: "Manager View", label: "MQL-Manager View"}
                    ];  

            } else {
                    opts = [
                    { value: "MQL", label: "MQL"},
                    { value: "All", label: "All"}
                    ];  

            }

            component.set("v.displayrecord",opts); 
            }
        


            for (var k = 0; k < contacts.length; k++) {
                contacts[k].tasksIn4Days =0;
                contacts[k].eventsIn4Days = 0;
                contacts[k].neglectedTasks =0;
                contacts[k].neglectedEvents = 0;
                
                var tasksWithContact = contacts[k].Tasks || [];
                var eventsWithContact = contacts[k].Events || [];
                contacts[k].allActivities = tasksWithContact.concat(eventsWithContact);
                contacts[k].allActivities.sort(function(a,b) {
                      var aValue = a['CreatedDate'] || '';
                      var bValue = b['CreatedDate'] || '';
                      var t1 = aValue == bValue, t2 = aValue < bValue;
                      return t1? 0: (false?-1:1)*(t2?1:-1);
              	});
                if(contacts[k].Tasks){
                    let tasksIn4Days = contacts[k].Tasks.filter(element => {
                        return element.LastModifiedDate > timestamp4Days
                    })
                    contacts[k].tasksIn4Days = tasksIn4Days.length;
                    
                    let neglectedTasks = contacts[k].Tasks.filter(element => {
                        return element.LastModifiedDate < timestamp4Days 
                    })
                    contacts[k].neglectedTasks = neglectedTasks.length;
                }
                
                if(contacts[k].Events){
                    let eventsIn4Days = contacts[k].Events.filter(element => {
                        return element.LastModifiedDate > timestamp4Days
                    })
                    contacts[k].eventsIn4Days = eventsIn4Days.length;
                    
                    let neglectedEvents = contacts[k].Events.filter(element => {
                        return element.LastModifiedDate < timestamp4Days
                    })
                    contacts[k].neglectedEvents = neglectedEvents.length;
                }
            }
            component.set("v.contactOppList", data.oppList);
            component.set("v.allcontactList", data.contactRecords);
           // console.log('***'+ JSON.stringify(data.oppList));
            component.set("v.recordIdsWithPendingTaskForCurrentUser", data.recordIdsWithPendingTaskForCurrentUser);
            helper.formatData(component, event, helper, data.contactRecords, refreshView);
            helper.getFilters(component, event, helper, data, false, false);
           
            
          //  console.log('*******'+ JSON.stringify(data.contactRecords));
            //component.set ( "v.selectedUser", data.sdrUsers[0].Id );
            component.set("v.responseData", data);
    },
    
    showToast : function(component, event, helper, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if(!toastEvent){
            component.set('v.errorType',type);
            component.set('v.errorMessage',message);
            window.setTimeout(
            $A.getCallback(function() {
                component.set('v.errorType','');
                component.set('v.errorMessage','');
            }), 6000
        );
            
            return;
        }
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
            
    showAssignTaskModal: function(component, event, helper) { 
        let contactList = component.get("v.contactList");
        let responseData = component.get("v.responseData");
        let selectedCon = contactList.filter(element => {
              return element.selected
        }) || [];
        var selectedIdWithNames =[];
        var usersToSelect =[];
        var idList =[];
        selectedCon.forEach(record => {
            selectedIdWithNames.push({Id: record.Id, Name: record.Name});
            if(responseData.contactWithTerritoryUsers[record.Id]){
                responseData.contactWithTerritoryUsers[record.Id].forEach(userId => {
                    if(!idList.includes(userId)){
                        idList.push(userId);
                        var user = responseData.sdrUsers.find(o => o.UserId === userId);
                        usersToSelect.push(user);
                    }
                });
            }
        });
        if(!component.get('v.showAssignTaskModal')){
            if( selectedCon.length== 0){
                helper.showToast(component, event, helper, 'Please select atleast 1 contact', 'warning');
                return;
            }else if(usersToSelect.length == 0 ){
                helper.showToast(component, event, helper, 'No active SDR for selected contacts', 'warning');
                return;        
            }
			component.set('v.selectedIdWithNames', selectedIdWithNames);
        	component.set('v.showAssignTaskModal', true);
		}
 		if(usersToSelect.length> 0){
            component.set ( "v.selectedUser", usersToSelect[0].UserId );
            component.set('v.usersToSelect', usersToSelect);
        }else{
            component.set ( "v.selectedUser", [] );
            component.set('v.usersToSelect', '');
        }
    },
        
    updateStatus : function(component, event, helper, contactIds, status, contactrejectreason) {
        var action = component.get("c.updateContactStatus"); //"rejectreason":rejectreason
        action.setParams({
            "contactIds":contactIds,
            "status":status,
            "contactrejectreason":contactrejectreason+''
        }); 
         component.set("v.showSpinner", true);
        action.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            component.set('v.showStatusUpdateModal', false);
            var state = response.getState();
            if (state === "SUCCESS") {
                 
                if(!response.getReturnValue().isSuccess){
                    let errorMsg= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Contacts - "+response.getReturnValue().errorMessage+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMsg , 'error');
                    return;
                }
                
                var message = 'Updated '+ component.get('v.selectedIdWithNames').length + ' Contacts successfully';
                helper.showToast(component, event, helper, message, 'success' );
                helper.doInit(component, event, helper);
                
            }else if (state === "ERROR") {
                
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        var errorMessage = '';
                        if(errors[0].message)
                        	errorMessage= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Contacts - "+errors[0].message+" ,please send this to your SFDC admin";
						else if(errors[0].pageErrors)	
                            errorMessage= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Contacts - "+errors[0].pageErrors+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMessage , 'error');
                       
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },    
    
})