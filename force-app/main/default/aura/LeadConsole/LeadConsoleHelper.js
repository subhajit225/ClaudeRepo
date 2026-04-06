({
    doInit : function(component, event, helper) {
        component.set("v.isDataLoading", true);
        component.set("v.selectedAccounts", []);
        component.set("v.selectedCampaigns", []);
        component.set("v.selectedGTM", []);
        component.set("v.selectedStatuses", []);
		component.set("v.accountTier", []);
        component.set("v.leadowner", []);
        component.set("v.selectedAccountOwners", []);
        component.set("v.clickedMatrix", '');
        component.find('allCheckBox').set('v.checked',false);
        component.set("v.showSpinner", true);
        var donotrenderpicklist = component.get("v.donotrenderpicklist");
        var LeadScoreMap = component.get("v.LeadScoreMap");
       
        var filterLowScoredRecordsFromView = component.get("v.filterLowScoredRecordsFromView");
        
        var accountStatusValue = (component.find("StatusSelect").get("v.value") == undefined || component.find("StatusSelect").get("v.value") == '') ? "None" : component.find("StatusSelect").get("v.value");
        var action = component.get("c.getLeadAccountCampaigns");
        action.setParams({
            "userId": component.get("v.selectedUser"),
            "displayRecordBy":component.get("v.defaultFilter"),
            "fitScoremap":LeadScoreMap,
            "filterLowScoredRecordsFromView":filterLowScoredRecordsFromView,
            "accountStatus" : accountStatusValue
        });
        action.setCallback(this, function(response){
            component.set("v.isDataLoading", false);
            if (response.getState() === "ERROR") {
                component.set("v.showSpinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                    	helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var data = response.getReturnValue();
            var leadRecords =  data.leadRecords;
            var isManager = data.isManager;
            console.log('MANAGER FLAG+'+data.isManager);

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
             
            var sdrUsers =  data.sdrUsers;
            let sdrUsersArray = [];
            let sdrUsersIdArray = [];
            var timestamp4Days = helper.createFormatedDate(component, helper, -4);
            var timestamp1Year = helper.createFormatedDate(component, helper, -365);
            sdrUsers.forEach(val => {
                if(!sdrUsersIdArray.includes(val.User.Id)){
                let sdrUsersLabelValuePair = {};
                sdrUsersLabelValuePair.label = val.User.Name;
                sdrUsersLabelValuePair.value = val.User.Id;
                sdrUsersIdArray.push(val.User.Id);    
                sdrUsersArray.push(sdrUsersLabelValuePair);
                }
            });
            if(!component.get("v.selectedUser"))
            	component.set("v.selectedUser", $A.get("$SObjectType.CurrentUser.Id"));
            component.set("v.sdrUsersArray", sdrUsersArray);
            
            for (var k = 0; k < leadRecords.length; k++) {
                leadRecords[k].tasksIn4Days =0;
                leadRecords[k].eventsIn4Days = 0;
                leadRecords[k].neglectedTasks =0;
                leadRecords[k].neglectedEvents = 0;
                
                var tasksWithLead = leadRecords[k].Tasks || [];
                var eventsWithLead = leadRecords[k].Events || [];
                leadRecords[k].allActivitiesRec = tasksWithLead.concat(eventsWithLead);
                leadRecords[k].allActivitiesRec.sort(function(a,b) {
                      var aValue = a['CreatedDate'] || '';
                      var bValue = b['CreatedDate'] || '';
                      var t1 = aValue == bValue, t2 = aValue < bValue;
                      return t1? 0: (false?-1:1)*(t2?1:-1);
              	});
                if(leadRecords[k].Tasks){
                    let tasksIn4Days = leadRecords[k].Tasks.filter(element => {
                        return element.LastModifiedDate > timestamp4Days
                    })
                    leadRecords[k].tasksIn4Days = tasksIn4Days.length;
                    
                    let neglectedTasks = leadRecords[k].Tasks.filter(element => {
                        return element.LastModifiedDate < timestamp4Days
                    })
                    leadRecords[k].neglectedTasks = neglectedTasks.length;
                }else{
                    leadRecords[k].Tasks = [];
                }
                
                if(leadRecords[k].Events){
                    let eventsIn4Days = leadRecords[k].Events.filter(element => {
                        return element.LastModifiedDate > timestamp4Days
                    })
                    leadRecords[k].eventsIn4Days = eventsIn4Days.length;
                    
                    let neglectedEvents = leadRecords[k].Events.filter(element => {
                        return element.LastModifiedDate < timestamp4Days 
                    })
                    leadRecords[k].neglectedEvents = neglectedEvents.length;
                }
                else{
                    leadRecords[k].Events = [];
                }
                leadRecords[k].activitiesIn1yearbutlessthan1month = leadRecords[k].neglectedEvents + leadRecords[k].neglectedTasks;
                leadRecords[k].activitiesIn4Days = leadRecords[k].eventsIn4Days + leadRecords[k].tasksIn4Days;
                leadRecords[k].allActivities = leadRecords[k].Tasks.length + leadRecords[k].Events.length;
                if(leadRecords[k].CampaignMembers)
                	leadRecords[k].campaignResponse = leadRecords[k].CampaignMembers.length;
                else
                    leadRecords[k].campaignResponse = 0;
        	}
            component.set("v.allLeadRecords", data.leadRecords);
            component.set("v.responseData", data);
			helper.getFilters(component, event, helper, data, false, false);
            helper.formatData(component, event, helper, data.leadRecords);
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
	},
	createFormatedDate : function(component, helper, numberOfDaysToAdd) {
        var todays =  new Date();
        todays.setDate(todays.getDate() + numberOfDaysToAdd);
        var dd = (todays.getDate() >= 10) ? todays.getDate() : ('0' + (todays.getDate()));
        var mm = ((todays.getMonth() + 1) >= 10) ? (todays.getMonth() + 1) : ('0' + (todays.getMonth() + 1));
        var y = todays.getFullYear();
        return y + '-' + mm + '-' + dd ;
    },
    
    formatData : function(component, event, helper, leads) {
         debugger;       
       /* var activeLeads= leads.filter(element => {
              return element.eventsIn4Days >0 || element.tasksIn4Days >0
        }) || [];*/
        var activeLeads= leads;
        var openLeadsCount =0;
        var workignLeadsCount =0;
        var meetingsetLeadsCount =0;
        
      /* var activeLeads= leads.filter(element => {
               return element.Status=='Open'
        }) || [];*/
        
        //console.log('OPNE LEAD :'leads.filter);
       var activeLeadIds =[];
        leads.forEach(val => {
            if(val.Status == 'Open'){
             openLeadsCount++
          }
          if(val.Status == 'Working'){
             workignLeadsCount++
          }
        if(val.Status == 'Meeting Set'){
             meetingsetLeadsCount++
          }
        });
        var staleLeads= leads.filter(element => {
              return (element.neglectedEvents >0 || element.neglectedTasks >0 ) && !activeLeadIds.includes(element.Id)
        }) || [];
        staleLeads.forEach(val => {
           // val.Status = 'Working';
        });
        var untouchedLeads= leads.filter(element => {
              return (element.Events.length==0 && element.Tasks.length==0)
        }) || [];
        untouchedLeads.forEach(val => {
          //  val.Status = 'Meeting Set';
        });
         
        //alert('sd'+openLeadsCount);
        component.set('v.noOfLeads', leads.length);
        component.set('v.activeLeads', openLeadsCount);
        component.set('v.staleLeads', workignLeadsCount);
        component.set('v.unTouchedLeads', meetingsetLeadsCount);
        
		
        
        component.set('v.leadRecords', leads);
        let totalPages = leads.length/50 + (leads.length%50 >0 ? 1: 0);
        var pageOptions = [];
        for(var i= 1; i<= totalPages; i++){
            pageOptions.push(i);
        }
        component.set('v.selectedPage', 1);
        component.set('v.pageOptions', pageOptions);
        helper.paginationResults(component, event, helper);
	},
    
    paginationResults : function(component, event, helper) {
        let leads = component.get('v.leadRecords') || [];
        var startIndex = (component.get('v.selectedPage')-1)*50;
        var endIndex = component.get('v.selectedPage')*50;
        if(endIndex > leads.length)
        	endIndex = leads.length;
        let visibleLeads = [];
        for(var i = startIndex; i< endIndex ; i++){
            if(leads[i].Composite_Score__c){
                leads[i].Composite_Score__c = parseFloat(leads[i].Composite_Score__c).toFixed(2);
            }
            visibleLeads.push(leads[i]);
        }
        component.set('v.visibleLeadRecords', visibleLeads );
        
    },
    
    getFilters : function(component, event, helper, data, isFilterApplied, isCampaignFilterApplied) {
        
        debugger;
        let accArray = [];
        let accIdArray = [];
        let statusArray = [];
		let tierArray = [];
        let leadownerArray = [];
        let leadIdownerArray = [];
        let tierIdArray = [];
        let statusIdArray = [];
        let accOwnerArray = [{ "label": "--None--",  "value": ""}];
        let accOwnerIdArray = [];
        let latticeGradeArray = [];
        let latticeUniqueArray = [];
        let camArray = [];
        let themeArray = [];
        let gtmThemeArray = [];
        let camIdArray = [];
        let leads =[];
        let timestamp1Year = helper.createFormatedDate(component, helper, -365);
        if(isFilterApplied)
            leads = component.get("v.visibleLeads");
        else{
            leads = data.leadRecords;
        }
        for (var i = 0; i < leads.length; i++) {
            
            if(leads[i].Status){
                if(!statusIdArray.includes(leads[i].Status)){
                let statusLabelValuePair = {};
                statusLabelValuePair.label = leads[i].Status;
                statusLabelValuePair.value = leads[i].Status;
                statusIdArray.push(leads[i].Status);    
                statusArray.push(statusLabelValuePair);
                }
            }
			 
             if(leads[i].L2AAccountTier__c){
                if(!tierIdArray.includes(leads[i].L2AAccountTier__c)){
                let tierLabelValuePair = {};
                tierLabelValuePair.label = leads[i].L2AAccountTier__c;
                tierLabelValuePair.value = leads[i].L2AAccountTier__c;
                tierIdArray.push(leads[i].L2AAccountTier__c);    
                tierArray.push(tierLabelValuePair);
                }
            }
            
           if(leads[i].Owner.Name){
                if(!leadIdownerArray.includes(leads[i].Owner.Name)){
                let leadLabelValuePair = {};
                leadLabelValuePair.label = leads[i].Owner.Name;
                leadLabelValuePair.value = leads[i].OwnerId;
                leadIdownerArray.push(leads[i].Owner.Name);    
                leadownerArray.push(leadLabelValuePair);
                }
            }
          
			 // Tire logic //
			 
			
            
            if(leads[i].Company){
                if(!accIdArray.includes(leads[i].Company)){
                let accLabelValuePair = {};
                accLabelValuePair.label = leads[i].Company;
                accLabelValuePair.value = leads[i].Company;
                accIdArray.push(leads[i].Company);    
                accArray.push(accLabelValuePair);
                }
            }
            
            if(leads[i].L2A_Account__r && leads[i].L2A_Account__r.Owner && leads[i].L2A_Account__r.Owner.Name && leads[i].L2A_Confidence_Code__c>=3){
                if(!accOwnerIdArray.includes(leads[i].L2A_Account__r.Owner.Id)){
                let ownerLabelValuePair = {};
                ownerLabelValuePair.label = leads[i].L2A_Account__r.Owner.Name;
                ownerLabelValuePair.value = leads[i].L2A_Account__r.Owner.Id;
                accOwnerIdArray.push(leads[i].L2A_Account__r.Owner.Id);    
                accOwnerArray.push(ownerLabelValuePair); 
                }
            }else{
                if(leads[i].L2A_Account__r && leads[i].L2A_Account__r.Owner)
                	leads[i].L2A_Account__r.Owner.Id = '';
                else if(!leads[i].L2A_Account__r){
                    leads[i].L2A_Account__r = {};
                    leads[i].L2A_Account__r.Owner ={};
                    leads[i].L2A_Account__r.Owner.Id = ''
                }
                    
            }
           
            var campaignMembers= leads[i].CampaignMembers;
                if(campaignMembers){
                    for (var j = 0; j < campaignMembers.length; j++) {
                        if(!camIdArray.includes(campaignMembers[j].Campaign.Id) && (campaignMembers[j].Campaign.Always_On__c || (campaignMembers[j].Campaign.IsActive && campaignMembers[j].Campaign.CreatedDate >= timestamp1Year )) ){
                            let camLabelValuePair = {};
                            camLabelValuePair.label = campaignMembers[j].Campaign.Name;
                            camLabelValuePair.value = campaignMembers[j].Campaign.Id;
                            camLabelValuePair.gtmPlay = campaignMembers[j].Campaign.GTM_Play__c;
                            camLabelValuePair.CreatedDate = campaignMembers[j].Campaign.CreatedDate;
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
        var leadowner = component.get("v.leadowner") || [];
        var selectedAccountOwners = component.get("v.selectedAccountOwners") || [];
        camArray.sort(function(a,b) {
            var aValue = a['CreatedDate'] || '';
            var bValue = b['CreatedDate'] || '';
            var t1 = aValue == bValue, t2 = aValue < bValue;
            return t1? 0: (false?-1:1)*(t2?1:-1);
        });
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
                    let gtmLabelValuePair = {};
                    if(campaignMembers[j]){
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
        
        if(leadowner.length ==0){
            component.set("v.leadownerPicklistOption",leadownerArray);
        }
        
        if(selectedAccountOwners.length ==0){
            component.set("v.accountOwnerOptions",accOwnerArray);
        }
        
    },
    
    sortRecords: function(component, event, helper) {
        debugger;
        component.set("v.showSpinner", true); 
        var whichOne = event.currentTarget.id;
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                var currentOrder = component.get("v.sortAsc");
                var currentList = component.get("v.leadRecords");
                currentOrder = !currentOrder;
                currentList.sort(function(a,b) {
                    a[whichOne] = a[whichOne] || '';
                    b[whichOne] = b[whichOne] || '';
                    console.log(whichOne);
                    if(whichOne == 'AccountOwner' ) {
                        a.L2A_Account__r.Owner['Name'] = a.L2A_Account__r.Owner['Name'] || '';
                        b.L2A_Account__r.Owner['Name'] = b.L2A_Account__r.Owner['Name'] || '';
                        var t1 = a.L2A_Account__r.Owner['Name'].toString().toUpperCase() == b.L2A_Account__r.Owner['Name'].toString().toUpperCase(), t2 = a.L2A_Account__r.Owner['Name'].toString().toUpperCase() < b.L2A_Account__r.Owner['Name'].toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                    if(whichOne == 'AccountStatus' ) {
                        
                        a.Account_Routing_Status__c = a.Account_Routing_Status__c || '';
                        b.Account_Routing_Status__c = b.Account_Routing_Status__c || '';
                        var t1 = a.Account_Routing_Status__c.toString().toUpperCase() == b.Account_Routing_Status__c.toString().toUpperCase(), t2 = a.Account_Routing_Status__c.toString().toUpperCase() < b.Account_Routing_Status__c.toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
						
                    }if(whichOne == 'MQLCampaignType' ) {
                        a.MQL_Campaign_Type__c = a.MQL_Campaign_Type__c || '';
                        b.MQL_Campaign_Type__c = b.MQL_Campaign_Type__c || '';
                        var t1 = a.MQL_Campaign_Type__c.toString().toUpperCase() == b.MQL_Campaign_Type__c.toString().toUpperCase(), t2 = a.MQL_Campaign_Type__c.toString().toUpperCase() < b.MQL_Campaign_Type__c.toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    } 
                    else if(whichOne == 'LeadOwner' ) {
                        a.Owner['Name'] = a.Owner['Name'] || '';
                        b.Owner['Name'] = b.Owner['Name'] || '';
                        var t1 = a.Owner['Name'].toString().toUpperCase() == b.Owner['Name'].toString().toUpperCase(), t2 = a.Owner['Name'].toString().toUpperCase() < b.Owner['Name'].toString().toUpperCase();
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                    else if(whichOne == 'Composite_Score__c'){	
                        var x = a[whichOne] ? parseFloat(a[whichOne]) : 0;	
                        var y = b[whichOne] ? parseFloat(b[whichOne]) : 0;	
                        	
                        var t1 = (Math.round(x * 100) || '') == (Math.round(y * 100) || ''),	
                            t2 = (Math.round(x * 100) || '') < (Math.round(y * 100) || '');	
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1); 	
                    }
                    else if(whichOne == 'allActivities' || whichOne =='activitiesIn4Days' || whichOne =='campaignResponse'){
                        console.log('INSIDE IF');
                        var t1 = (a[whichOne] || '') == (b[whichOne] || ''), t2 = (a[whichOne] || '') < (b[whichOne] || '');
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
                    }
                    else{
                        var t1 = (a[whichOne].toString().toUpperCase() || '') == (b[whichOne].toString().toUpperCase() || ''), t2 = (a[whichOne].toString().toUpperCase() || '') < (b[whichOne].toString().toUpperCase() || '');
                        return t1? 0: (currentOrder?-1:1)*(t2?1:-1); 
                    }
                });
                component.set("v.sortAsc", currentOrder);
                component.set("v.leadRecords", currentList);
                component.set('v.selectedPage', 1);
                helper.paginationResults(component, event, helper);
            }), 7
        );
        
    },
    
    applyFilters : function(component, event, helper) { 
        debugger;
        component.find('allCheckBox').set('v.checked',false);
        let leadRecords = component.get("v.allLeadRecords");
        let selectedCampaigns = component.get("v.selectedCampaigns");
        let selectedAccounts = component.get("v.selectedAccounts");
        let selectedGTM = component.get("v.selectedGTM");
        let selectedStatuses = component.get("v.selectedStatuses");
		 let accountTier = component.get("v.accountTier");
         let leadowner = component.get("v.leadowner");
		 
        let selectedAccountOwners = component.get("v.selectedAccountOwners");
        let filteredContacts = [];
        for (var i = 0; i < leadRecords.length; i++) {
            var leadFilteredByCamp = null;
            if(selectedCampaigns.length != 0 && selectedGTM.length !=0){
                if(leadRecords[i].CampaignMembers){
                    let campaignRecs = leadRecords[i].CampaignMembers.filter(element => {
                        return (selectedCampaigns.includes(element.CampaignId) && selectedGTM.includes(element.Campaign.GTM_Play__c))
                    })
                    if(campaignRecs.length>0)
                        leadFilteredByCamp = leadRecords[i];
                }
                
            }else if(selectedCampaigns.length != 0 ){
                if(leadRecords[i].CampaignMembers){
                    let campaignRecs = leadRecords[i].CampaignMembers.filter(element => {
                        return (selectedCampaigns.includes(element.CampaignId) )
                    })
                    if(campaignRecs.length>0)
                        leadFilteredByCamp = leadRecords[i];
                }
                
            }else if(selectedGTM.length !=0){
                if(leadRecords[i].CampaignMembers){
                    let campaignRecs = leadRecords[i].CampaignMembers.filter(element => {
                        return ( selectedGTM.includes(element.Campaign.GTM_Play__c))
                    })
                    if(campaignRecs.length>0)
                        leadFilteredByCamp = leadRecords[i];
                }
                
            }
            else{
                leadFilteredByCamp = leadRecords[i];
            }
            if(leadFilteredByCamp != null)
            	filteredContacts.push(leadFilteredByCamp);
        }
        var leadFilteredByCampAndAccount = null;
        if(selectedAccounts.length != 0 ){
            leadFilteredByCampAndAccount= filteredContacts.filter(element => {
                            return ( selectedAccounts.includes(element.Company))
                        })
        }else{
            leadFilteredByCampAndAccount= filteredContacts;
        }
        
        var leadFilteredByCampAndAccountAndStatus = null;
        if(selectedStatuses.length != 0 ){
            leadFilteredByCampAndAccountAndStatus= leadFilteredByCampAndAccount.filter(element => {
                            return ( selectedStatuses.includes(element.Status))
                        })
        }
		else{
            leadFilteredByCampAndAccountAndStatus= leadFilteredByCampAndAccount;
        }
        
        
         var leadFilteredByAccountTier = null;
        if(accountTier.length != 0 ){
            leadFilteredByAccountTier= leadFilteredByCampAndAccountAndStatus.filter(element => {
                            return ( accountTier.includes(element.L2AAccountTier__c))
                        })
        }
		else {
		leadFilteredByAccountTier =leadFilteredByCampAndAccountAndStatus;
		
		}
        
          var leadFilteredByLeadOwner = null;
        if(leadowner.length != 0 ){
            leadFilteredByLeadOwner= leadFilteredByAccountTier.filter(element => {
                            return ( leadowner.includes(element.OwnerId))
                        })
        }
		else {
		leadFilteredByLeadOwner =leadFilteredByAccountTier;
		
		}
        
        
        
        
        var leadFilteredByCampAndAccountAndStatusAndMatrix= null;
        if(component.get("v.clickedMatrix")){
            leadFilteredByCampAndAccountAndStatusAndMatrix= leadFilteredByLeadOwner.filter(element => {
                            return ( element.matricStatus == component.get("v.clickedMatrix") )
                        })
        }else{
            leadFilteredByCampAndAccountAndStatusAndMatrix= leadFilteredByLeadOwner;
        }
        
        var leadFilteredByCampAndAccountAndStatusAndMatrixAndAccOwner= null;
        if(selectedAccountOwners.length != 0){
            leadFilteredByCampAndAccountAndStatusAndMatrixAndAccOwner= leadFilteredByCampAndAccountAndStatusAndMatrix.filter(element => {
                            return ( element.L2A_Account__r && element.L2A_Account__r.Owner && selectedAccountOwners.includes(element.L2A_Account__r.Owner.Id))
                        })
        }else{
            leadFilteredByCampAndAccountAndStatusAndMatrixAndAccOwner= leadFilteredByCampAndAccountAndStatusAndMatrix;
        }
        component.set("v.visibleLeads",leadFilteredByCampAndAccountAndStatusAndMatrixAndAccOwner);
        helper.formatData(component, event, helper, leadFilteredByCampAndAccountAndStatusAndMatrixAndAccOwner);
    },
    
    applyAccountFilters : function(component, event, helper) { 
        component.set('v.showContent', false);
        component.set("v.showSpinner", true);
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
        component.set('v.showContent', false);
        component.set("v.showSpinner", true);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
        //helper.getFilters(component, event, helper, '', true);
        
    },
        
        applyLeadOnwerFilters : function(component, event, helper) { 
        component.set('v.showContent', false);
        component.set("v.showSpinner", true);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showSpinner", false);
                helper.applyFilters(component, event, helper);
                helper.getFilters(component, event, helper, '', true, true);
            }), 7
        );
        //helper.getFilters(component, event, helper, '', true);
        
    },
    
        // Added rejectreasonfield//
    updateStatus : function(component, event, helper, leadIds, status,leadrejectreason,accounttoConvert) {
        var action = component.get("c.updateLeadStatus");
        var rejectreasonVal ='';
        if(leadrejectreason !='Select'){
            rejectreasonVal=leadrejectreason;
        }else {
          rejectreasonVal='';  
        }
        action.setParams({
            "leadIds": leadIds,
            "status" : status,
            "rejectReason":rejectreasonVal,
            "AccounttoConvert":accounttoConvert
        }); 
         component.set("v.showSpinner", true);
        action.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            component.set('v.showStatusUpdateModal', false);
            var state = response.getState();
            if (state === "SUCCESS") {
                 
                if(!response.getReturnValue().isSuccess){
                    let errorMsg= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Leads - "+response.getReturnValue().errorMessage+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMsg , 'error');
                    return;
                }
                
                var message = 'Updated '+ component.get('v.selectedIdWithNames').length + ' Leads successfully';
                helper.showToast(component, event, helper, message, 'success' );
                helper.doInit(component, event, helper);
                
            }else if (state === "ERROR") {
                
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        var errorMessage = '';
                        if(errors[0].message)
                        	errorMessage= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Leads - "+errors[0].message+" ,please send this to your SFDC admin";
						else if(errors[0].pageErrors)	
                            errorMessage= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Leads - "+errors[0].pageErrors+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMessage , 'error');
                       
                    }
                }
            }
        });
        $A.enqueueAction(action);
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
        
        
      // Added rejectreasonfield//
    updateLeadOwner : function(component, event, helper, leadIds, selectedLeadOwnerType,leadowner) {
        var action = component.get("c.updateLeadOwnerAction");
        action.setParams({
            "leadIds": leadIds,
            "userType" : selectedLeadOwnerType,
            "ownerId":leadowner
           
        }); 
         component.set("v.showSpinner", true);
        action.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            component.set('v.showChangeOwnerModal', false);
            var state = response.getState();
            if (state === "SUCCESS") {
                 
                if(!response.getReturnValue().isSuccess){
                    let errorMsg= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Leads - "+response.getReturnValue().errorMessage+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMsg , 'error');
                    return;
                }
                
                var message = 'Updated '+ component.get('v.selectedIdWithNames').length + ' Leads successfully';
                helper.showToast(component, event, helper, message, 'success' );
                helper.doInit(component, event, helper);
                
            }else if (state === "ERROR") {
                
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        var errorMessage = '';
                        if(errors[0].message)
                        	errorMessage= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Leads - "+errors[0].message+" ,please send this to your SFDC admin";
						else if(errors[0].pageErrors)	
                            errorMessage= "Failed to update status of "+ component.get('v.selectedIdWithNames').length +" Leads - "+errors[0].pageErrors+" ,please send this to your SFDC admin";
                    helper.showToast(component, event, helper, errorMessage , 'error');
                       
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },    
        
        
    
})