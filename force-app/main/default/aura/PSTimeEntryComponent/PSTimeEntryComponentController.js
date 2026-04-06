({    
    doInit : function(component, event, helper) { 
        component.set("v.weekTypeString",""); 
        helper.allProjects(component, event, helper);
        document.title = "Timecard";
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            component.set('v.isConsoleApplication', response);
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: "Timecard"
                });
                workspaceAPI.setTabIcon({
                    tabId : focusedTabId, 
                    icon : 'standard:contact_list',
                    iconAlt : 'Timecard'
                });
            })
            .catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    openPrimaryTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            url: '/'+event.target.dataset.recid,
            focus: true
        });
    },
    NextClick : function(component, event, helper) {
        component.set("v.weekTypeString","Next Week"); 
        helper.allProjects(component, event, helper);
    },
    
    OnBackClick: function(component, event, helper) {
        var refreshEvent = $A.get("e.c:PSRefreshTabsEvent");
        if(refreshEvent){
            refreshEvent.fire();
        }
        var isConsoleApplication = component.get('v.isConsoleApplication');
        if(isConsoleApplication){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/lightning/n/PS_Time_Entry_App_New_Ltng"
                });
                urlEvent.fire();
                
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({
                    tabId : focusedTabId
                });
            })
            .catch(function(error) {
                console.log(error);
            });
        }
        else
            window.open("/apex/PSTimeEntryApp","_self");    
    },
    
    PreviousClick : function(component, event, helper) { 
        component.set("v.weekTypeString","Previous Week"); 
        helper.allProjects(component, event, helper);
    },
    
    valuechanged : function(component, event, helper) {
        var totalhr = '';
         var ValidHoursError = false;
        var mainList = component.get("v.SelectedProjects");
        if(mainList != null && mainList.length > 0){
            for(var i=0;i<mainList.length;i++) {
                for(var j=0;j < mainList[i].taskWrapperList.length;j++){                    
                    totalhr = 0;
                    for(var k=0; k<mainList[i].taskWrapperList[j].timeEntryList.length; k++){
                        var ActualHour = mainList[i].taskWrapperList[j].taskRec.Billable_Hours_Expected__c;             
                        component.set("v.ActualHour",ActualHour);
                        if(!$A.util.isUndefinedOrNull(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c) 
                           && (mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c) !== ''){
                            if(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c>24 )
                            {
                                ValidHoursError = true;
                                break;
                            }else{
                            if (isNaN(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c))                  
                                mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c = 0; 
                            totalhr = totalhr+parseInt(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c);
                            mainList[i].taskWrapperList[j].TotHours = totalhr.toString();  
                            }
                        }	
                    }
                    
                }
            }
        }
        if(ValidHoursError){
             component.set("v.errorMessage","Hours can't be more than 24.");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
        }
        else{
        component.set("v.SelectedProjects",mainList);
        }
    },
    
    fetchProjects : function(component, event, helper) {
        var values = event.getParam("values"); 
        component.set("v.newProjectIdsToAdd", values);  
        component.set("v.Spinner", true); 
        var action = component.get("c.getProjList"); 
        action.setParams({ 
            "listOfProjId" : values,
            "cmpStartDate" : component.get("v.weekStartDate"),
            "onload"       : false
        });
        action.setCallback(this, function(response) {
            var res = response.getReturnValue(); 
            //console.log('res=='+JSON.stringify(res));
            var ischeck = component.get("v.isCheck");
            var SelectedArray =[];           
            var lastlength = res.allProjects.length;
            for(var j = 0; j<res.allProjects.length; j++){
                if(res.allProjects[j].selected == true){
                    SelectedArray.push(res.allProjects[j]);
                    // SelectedArray.reverse();                    
                }                               
            }
            
            component.set("v.SelectedProjects",SelectedArray);           
            component.set("v.weekStartDate",res.weekStartDate);
            component.set("v.weekEndDate",res.weekEndDate);
            component.set("v.Spinner", false); 
        });
        $A.enqueueAction(action);
    }, 
    
    OnCancelClick : function(component,event,helper){
        window.location.reload()
    }, 
    
    OnSaveClick: function(component, event, helper) {
        var commentsBlankError = false;
        var totalHoursError = false;
        var HoursDecimal = false;
        var ValidHoursError = false;
        var re = new RegExp('[-!$%^&*()_+|~=`{}\\[\\]:";\\\'<>?,.\\/]');
        var mainList = component.get("v.SelectedProjects");
        for(var i=0; i < mainList.length; i++){
            if(commentsBlankError || totalHoursError) break;
            for(var j=0; j < mainList[i].taskWrapperList.length; j++){
                if(commentsBlankError || totalHoursError) break;
                if((mainList[i].taskWrapperList[j].comment == null || mainList[i].taskWrapperList[j].comment.trim().length == 0) && mainList[i].taskWrapperList[j].TotHours > 0) {
                    commentsBlankError = true;
                    break;
                }
                if(mainList[i].taskWrapperList[j].taskRec.Billable_Hours_Expected__c < mainList[i].taskWrapperList[j].TotHours) {
                    totalHoursError = true;
					component.set("v.errorTaskId",mainList[i].taskWrapperList[j].taskRec.Id);
                    break;
                }
                
                for(var k=0; k<mainList[i].taskWrapperList[j].timeEntryList.length; k++){
                    
                    if(!$A.util.isUndefinedOrNull(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c) 
                       && (mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c) !== ''){
                        if(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c>24)
                        {
                            // console.log('i am in');
                                ValidHoursError = true;
                                break;
                        }
                            
                        if (re.test(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c)) {                               
                            HoursDecimal = true;
                            break;
                        }
                    }
                }
            }
        }
      /*  if(commentsBlankError) {
            component.set("v.errorMessage","Comments are mandatory for each task");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
        } */
         if(totalHoursError) {
            component.set("v.errorMessage","Total hours delivered can\'t be more than purchased hours");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
            
        } 
       	else if(ValidHoursError){
             component.set("v.errorMessage","Hours can't be more than 24.");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
        }
            else if(HoursDecimal) {
                component.set("v.errorMessage","Only integer value is allowed");
                $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
                window.setTimeout($A.getCallback(function() {
                    $A.util.addClass(component.find('errorDiv'), 'slds-hide');
                }), 300000000);
                
            } 
        
                else {
                    //component.find('TotalHour_Error').set("v.value", '');
                    component.set("v.errorTaskId",'');
                    helper.helpersave(component, event, helper, 'Save');
                }
    },
    
    OnSaveAndSubmit : function(component,event,helper){ 
        var commentsBlankError = false;
        var totalHoursError = false;
        var HoursDecimal = false;
        var ValidHoursError = false;
        var re = new RegExp('[-!$%^&*()_+|~=`{}\\[\\]:";\\\'<>?,.\\/]');
        var mainList = component.get("v.SelectedProjects");
        for(var i=0; i < mainList.length; i++){
            if(commentsBlankError || totalHoursError) break;
            for(var j=0; j < mainList[i].taskWrapperList.length; j++){
                if(commentsBlankError || totalHoursError) break;
                if(( mainList[i].taskWrapperList[j].comment == null || mainList[i].taskWrapperList[j].comment.trim().length == 0) && mainList[i].taskWrapperList[j].TotHours > 0) {
                    commentsBlankError = true;
                    break;
                }
                if(mainList[i].taskWrapperList[j].taskRec.Billable_Hours_Expected__c < mainList[i].taskWrapperList[j].TotHours) {
                    component.set("v.errorTaskId",mainList[i].taskWrapperList[j].taskRec.Id);

                    totalHoursError = true;
                    break;
                }
                
                for(var k=0; k<mainList[i].taskWrapperList[j].timeEntryList.length; k++){
                    
                    if(!$A.util.isUndefinedOrNull(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c) 
                       && (mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c) !== ''){
                        if(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c>24)
                        {
                                ValidHoursError = true;
                                break;
                        }
                        if (re.test(mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c)) {                               
                            HoursDecimal = true;
                            break;
                        }
                    }
                }
            }
        }
        if(commentsBlankError) {
            component.set("v.errorMessage","Comments are mandatory for each task");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
        } else if(totalHoursError) {
            component.set("v.errorMessage","Total hours delivered can\'t be more than purchased hours");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
        }
        else if(ValidHoursError){
             component.set("v.errorMessage","Hours can't be more than 24.");
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
                $A.util.addClass(component.find('errorDiv'), 'slds-hide');
            }), 300000000);
        }
            else if(HoursDecimal) {
                component.set("v.errorMessage","Only Integer value is allowed");
                $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
                window.setTimeout($A.getCallback(function() {
                    $A.util.addClass(component.find('errorDiv'), 'slds-hide');
                }), 300000000);
                
            } else {
                //component.find('TotalHour_Error').set("v.value", '');
                component.set("v.errorTaskId",'');
                helper.helpersave(component, event, helper, 'SaveSubmit');
            } 
        component.set("v.IsModelOpen", false);
    },
    
    inlineEditName : function(component,event,helper){   
        var mainList = component.get("v.SelectedProjects");
        var rowFound = false;
        if(mainList != null && mainList.length > 0){
            for(var i=0;i<mainList.length;i++) {
                if(mainList[i].project.Id == event.target.id && rowFound == false){
                    for(var j=0;j < mainList[i].taskWrapperList.length;j++){                        
                        if(mainList[i].taskWrapperList[j].taskRec.Id == event.target.name && rowFound == false){
                            for(var k=0; k<mainList[i].taskWrapperList[j].timeEntryList.length; k++){
                                mainList[i].taskWrapperList[j].timeEntryList[k].Hours_Spent__c = null;	
                                mainList[i].taskWrapperList[j].TotHours = 0;
                                mainList[i].taskWrapperList[j].comment = '';
                                rowFound = true;
                            }
                        }
                    }
                }
            }
        }
        component.set("v.SelectedProjects",mainList);
    },
    
    hideSpinner : function(component,event,helper){
        component.set("v.weekStartDateClass", true);
        component.set("v.Spinner", false);
    },
    
    showSpinner: function(component, event, helper) {
        component.set("v.weekStartDateClass", false);
        //component.set("v.Spinner", true); 
    },
    
    OnCloseToast:function(component, event, helper) {
        $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
        $A.util.addClass(component.find('errorDiv'), 'slds-hide');
        
        
    },
    OnCloseToast1:function(component, event, helper) {
        $A.util.removeClass(component.find('warningDiv'), 'slds-hide');
        $A.util.addClass(component.find('warningDiv'), 'slds-hide');
        
        
    },
    
    openModel: function(component, event, helper) {
        // for Display Model,set the "isOpen" attribute to "true"
        component.set("v.IsModelOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.IsModelOpen", false);
    },
    
})