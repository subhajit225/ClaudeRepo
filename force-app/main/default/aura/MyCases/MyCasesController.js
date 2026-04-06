({
    doInit : function(component, event, helper)
    {
        var pageSize = component.get("v.pageSize");
        var action = component.get("c.getCasesrecords");
        
        action.setCallback(this, function(response){
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS"){
                var resp = response.getReturnValue();
                if(resp.caseList.length == 0){
                    component.set('v.totalpagesize',0);
                    component.set('v.currentPage',0);
                    component.set('v.hasCaseAccess',resp.hasAccess);
                    component.set('v.accDetail',resp.accDetail);
                    
                    //added for CS21-421
                    component.set('v.caseExportDisabled', true);
                    //CS21-421 - End
                    
					if(undefined == component.get("v.accDetail").Technical_support_provided_by_Partner__r.RASP_Customer_Phone__c &&
                       undefined == component.get("v.accDetail").Technical_support_provided_by_Partner__r.RASP_Customer_Email__c &&
                       undefined ==  component.get("v.accDetail").Technical_support_provided_by_Partner__r.RASP_Customer_Portal__c ){
                        component.set('v.infoUndefined',false); 
                    } else {
                        component.set('v.infoUndefined',true);
                    }
                } else {
                    component.set('v.totalpagesize', Math.ceil(resp.caseList.length / pageSize));
                    component.set('v.hasCaseAccess',resp.hasAccess);
                    component.set('v.accDetail',resp.accDetail);
                    component.set('v.CaseList1', resp.caseList);
                    component.set("v.totalSize", component.get("v.CaseList1").length);
                    // setCon.totalSize()/pageSize.round(System.RoundingMode.CEILING);
                    component.set("v.start",0);
                    component.set("v.end",pageSize-1);
                    var paginationList = [];
                    for(var i=0; i< pageSize; i++)
                    {
                        paginationList.push(resp.caseList[i]);
                        if(component.get("v.CaseList1").length == i+1){
                            break;
                        }
                    }
                    
                    //added for CS21-421
                    component.set('v.caseExportDisabled', false);
                    //CS21-421 - End
                    component.set('v.caselist', paginationList);
                }  
            } else {
                console.log('exception occur');
            }
        });
        $A.enqueueAction(action);
        /*
        var navEvent = $A.get("e.force:navigateToList");
        var caseviewid = "00B40000007CF5O";
        navEvent.setParams({
        "listViewId": caseviewid,
        "listViewName": null,
        "scope": "Case"
        });
        navEvent.fire();*/
    },
    
    onSelectChange : function(component, event, helper) {
        var selected = component.get("v.pageSize");
        var paginationList = [];
        var oppList = component.get("v.CaseList1");
        if(selected > oppList.length){
            selected = oppList.length;
        }
        component.set('v.totalpagesize', Math.ceil(oppList.length / selected));
        component.set("v.currentPage",1);
        for(var i=0; i< selected; i++){
            paginationList.push(oppList[i]);
        }
        component.set('v.caselist', paginationList);
    },
    
    first : function(component, event, helper)
    {
        var oppList = component.get("v.CaseList1");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        for(var i=0; i< pageSize; i++)
        {
            paginationList.push(oppList[i]);
        }
        component.set('v.caselist', paginationList);
    },
    
    last : function(component, event, helper)
    {
        var oppList = component.get("v.CaseList1");
        var pageSize = component.get("v.pageSize");
        var totalSize = component.get("v.totalSize");
        var paginationList = [];
        for(var i=totalSize-pageSize+1; i< totalSize; i++)
        {
            paginationList.push(oppList[i]);
        }
        component.set('v.caselist', paginationList);
    },
    
    next : function(component, event, helper)
    {
        var oppList = component.get("v.CaseList1");
        
        var pageSize = component.get("v.pageSize");
        var totalSize = component.get("v.totalSize");
        var currentPage = component.get("v.currentPage");
        var NexPageSize = component.get("v.NexPageSize");
        NexPageSize = currentPage * pageSize;
        if(currentPage*pageSize < totalSize){
            var paginationList = [];
            var n  = NexPageSize;
            var m  = pageSize * (currentPage+1);
            if(m > totalSize){
                m = totalSize;
            }
            for(var i=n ; i<m; i++)
            {
                console.log('-----------i-----'+i);
                paginationList.push(oppList[i]);
            }
            component.set('v.caselist', paginationList);
            component.set('v.currentPage', currentPage+1);
            
        }
        
    },
    
    previous : function(component, event, helper)
    {
        var oppList = component.get("v.CaseList1");
        var pageSize = component.get("v.pageSize");
        var totalSize = component.get("v.totalSize");
        var currentPage = component.get("v.currentPage");
        if(currentPage > 1){
            var paginationList = [];
            //var n  = NexPageSize;
            var m  = (currentPage-1 )*pageSize;
            for(var i= (currentPage -2 )*pageSize ; i< m; i++)
            {
                paginationList.push(oppList[i]);
            }
            component.set('v.caselist', paginationList);
            component.set('v.currentPage', currentPage-1);
        }
    },
    
    caselist : function(component, event, helper) {
        var action = component.get("c.getCasesrecords");
        action.setCallback(this, function(response){
            if(response.getState()==="SUCCESS" && component.isValid()){
                component.set("v.caselist",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    fetchCases :  function(component, event, helper) {
        //added for CS21-421
        component.set('v.caseExportDisabled', true);
        //CS21-421 - End
        
        var selectedView = component.find("ViewSelectList").get("v.value");
        var action = component.get("c.getCasesByViews");
        action.setParams({ viewName : selectedView });
        action.setCallback(this, function(response){
            if(response.getState()==="SUCCESS"){
                if(response.getReturnValue().length == 0){
                    component.set('v.totalpagesize',0);
                    component.set('v.currentPage',0);
                    component.set('v.caselist', response.getReturnValue()); 
                } else {
                    component.set("v.CaseList1",response.getReturnValue());
                    component.set("v.totalSize", component.get("v.CaseList1").length);
                    var oppList = component.get("v.CaseList1");
                    var pageSize = component.get("v.pageSize");
                    component.set('v.totalpagesize', Math.ceil(response.getReturnValue().length / pageSize));
                    var totalSize = component.get("v.totalSize");
                    var currentPage = 1;
                    component.set("v.currentPage",currentPage);
                    if(currentPage*pageSize < totalSize){
                        var paginationList = [];
                        for(var i=0 ; i< pageSize; i++)
                        {
                            console.log('____running oppList[i]_______',oppList[i]);
                            paginationList.push(oppList[i]);
                        }
                        component.set('v.caselist', paginationList);                    
                    } else {
                        component.set('v.caselist', response.getReturnValue()); 
                    }
                    
                    //added for CS21-421
                    component.set('v.caseExportDisabled', false);
                    //CS21-421 - End
                }
            }
        });
        $A.enqueueAction(action);
    },
    Sorttable : function(component, event, helper) {
        var fieldName = event.target.name;
        var sortDirection = event.target.id;
        var currentSortingOrder =  component.get("v.sortedDirection");
        var currentfield =  component.get("v.sortedBy");
        if(fieldName != currentfield){
            currentSortingOrder ='desc';
            sortDirection = 'asc';
        }
        if(sortDirection == currentSortingOrder){
            sortDirection = 'asc';
        }
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }, 
    exportCases : function(component,event,helper) {
        var caseList = component.get("v.caselist");
        let fileName = $A.util.isEmpty(component.get("v.selectedOption")) ? 'caseexport' : component.get("v.selectedOption");
        let date = new Date();
		fileName = fileName + date;
        let message = 'Exporting Case records. Please wait.';
                
        if ($A.util.isEmpty(caseList)) {
            helper.showToast(component, 'Warning!', 'No records available for export', 'warn');
            return;
        } else {
            var csv = helper.generateCSV(component, caseList);
            
            if ($A.util.isEmpty(csv)) {
                helper.showToast(component, 'Warning!', 'No records available for export', 'warn');
                return;
            } else {
                helper.showToast(component, 'Success!', message, 'success');
                var hiddenElement = document.createElement('a');
                hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
                hiddenElement.target = '_self'; // 
                hiddenElement.download = fileName + '.csv'; 
                document.body.appendChild(hiddenElement);
                hiddenElement.click();
            }
        }      
    }
})