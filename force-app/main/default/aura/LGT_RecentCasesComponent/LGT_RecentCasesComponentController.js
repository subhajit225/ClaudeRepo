({
    doInit : function(component, event, helper) {
    },
    /*<Modifications By: Anmol Baweja 4 march, 2020>
	<Reason>
		To make Recent cases section collapsible by default and load the data on expansion as per CS-595
   	</Reason>*/
    handleSectionToggle: function(component, event, helper){
        component.set("v.spinnerForRecentCases", true);
        var action = component.get("c.getCaseRec");
        
        action.setParams({
            caseId: component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            component.set("v.spinnerForRecentCases", false);
            var result = response.getReturnValue();
            if(result != null && result != ''){
                var caseList = [];
                component.set("v.casesList",result);
                component.set("v.casesListOriginal",result);
                component.set("v.clusterUUID",'');
                
                if(component.get("v.casesList").length>5){
                    component.set("v.showAllButton",true);
                }
                else{
                    component.set("v.showAllButton",false);
                }
                for(var i=0; i<5;i++){
                    if(i<result.length)
                        caseList.push(result[i]); 
                }
                component.set("v.casesListLess",caseList);
            }
            
        });
        $A.enqueueAction(action);
    },
    /*</Modifications By: Anmol Baweja>*/
    showAllRecords: function(component, event, helper){
        component.set("v.allRecords",true);
    },
    showLessRecords: function(component, event, helper){
        component.set("v.allRecords",false);
    },
    openCaseDetailPage:function(cmp, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.target.id,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    openClusterDetailPage: function(cmp, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.target.id,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    getCases: function(cmp,event,helper){
        helper.getCasesRelatedToClusterUUID(cmp,event,helper);
    },
    getCasesOnEnter : function(cmp, event, helper){
        if (event.keyCode === 13) {
            helper.getCasesRelatedToClusterUUID(cmp,event,helper);
        }
    },
    Sorttable : function(component, event, helper) {
        try{
            var fieldName = event.target.name;
            var sortDirection = event.target.id;
            var currentSortingOrder =  component.get("v.sortedDirection");
            var currentfield =  component.get("v.sortedBy");
            if(!!fieldName && !!currentfield && fieldName != currentfield){
                currentSortingOrder ='desc';
                sortDirection = 'asc';
            }
            if(sortDirection == currentSortingOrder){
                sortDirection = 'asc';
            }
            component.set("v.sortedBy", fieldName);
            component.set("v.sortedDirection", sortDirection);
            helper.sortData(component, fieldName, sortDirection);
        }
        catch(e){
            console.log(e);
        }
    }
})