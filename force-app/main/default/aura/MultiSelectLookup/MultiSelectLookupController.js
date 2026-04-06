({
    // To prepopulate the seleted value pill if value attribute is filled 
	doInit : function( component, event, helper ) {
        console.log('selectedRecords-->'+component.get('v.selectedRecords'));
    	$A.util.toggleClass(component.find('resultsDiv'),'slds-is-open');
		if( !$A.util.isEmpty(component.get('v.selectedRecords')) ) {
			helper.searchRecordsHelper(component, event, helper, component.get('v.selectedRecords'));
		}
    },
 
    // When a keyword is entered in search box
	searchRecords : function( component, event, helper ) {
        if( !$A.util.isEmpty(component.get('v.searchString')) ) {
		    helper.searchRecordsHelper(component, event, helper, []);
        } else {
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

    // When an item is selected
	selectItem : function( component, event, helper ) {
        if(!$A.util.isEmpty(event.currentTarget.id)) {
    		var recordsList = component.get('v.recordsList');
            var selectedRecords = component.get('v.selectedRecords') || [];
            var selectedDataObj = component.get('v.selectedDataObj') || [];
    		var index = recordsList.findIndex(x => x.value === event.currentTarget.id)
            if(index != -1) {
                recordsList[index].isSelected = recordsList[index].isSelected === true ? false : true;
                if(selectedRecords.includes(recordsList[index].value)) {
                    selectedRecords.splice(selectedRecords.indexOf(recordsList[index].value), 1);
                    var ind = selectedDataObj.findIndex(x => x.value === event.currentTarget.id)
                    if(ind != -1) {selectedDataObj.splice(ind, 1)}
                } else {
                	selectedRecords.push(recordsList[index].value);
                    selectedDataObj.push(recordsList[index]);
                }
            }
            component.set('v.recordsList', recordsList);
            component.set('v.selectedRecords', selectedRecords);
            component.set('v.numberOfAssets', selectedRecords.length);
            component.set('v.selectedDataObj', selectedDataObj);
            var evt = $A.get("e.c:Result");
            evt.setParams({ 
                "Pass_Result" : selectedRecords, 
                "bundleRecordId" : component.get('v.bundleRecordId'),
                "numberOfAssets" : component.get('v.numberOfAssets')
            });
            evt.fire();
        }
        $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
	},
    
    removePill : function( component, event, helper ){
        var recordId = event.getSource().get('v.name');
        var recordsList = component.get('v.recordsList');
        var selectedRecords = component.get('v.selectedRecords');
        var selectedDataObj = component.get('v.selectedDataObj');
        
        selectedRecords.splice(selectedRecords.indexOf(recordId), 1);
        var index = selectedDataObj.findIndex(x => x.value === recordId)
        if(index != -1) {
            selectedDataObj.splice(index, 1)
        }
        var ind = recordsList.findIndex(x => x.value === recordId)
        if(ind != -1) {
            recordsList[ind].isSelected = false;
        }
        component.set('v.recordsList', recordsList);
        component.set('v.selectedDataObj', selectedDataObj);
        component.set('v.selectedRecords', selectedRecords);
        component.set('v.numberOfAssets', selectedRecords.length);
        var evt = $A.get("e.c:Result");
            evt.setParams({ 
                "Pass_Result" : selectedRecords, 
                "bundleRecordId" : component.get('v.bundleRecordId'),
                "numberOfAssets" : component.get('v.numberOfAssets')
            });
            evt.fire();
        
    },
    
    showRecords : function( component, event, helper ){
        /*var disabled = component.get('v.disabled');
        if(!disabled && !$A.util.isEmpty(component.get('v.recordsList')) && !$A.util.isEmpty(component.get('v.searchString'))) {
            $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
        }*/
        
		    helper.searchRecordsHelper(component, event, helper, []);
        
    },

    // To close the dropdown if clicked outside the inputbox.
    blurEvent : function( component, event, helper ){
        $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    },
    
    saveTableRecords : function(component, event, helper) {
        var recordsData = event.getParam("recordsString");
        var tableAuraId = event.getParam("tableAuraId");
        var action = component.get("c.updateRecords");
        action.setParams({
            jsonString: recordsData
        });
        action.setCallback(this,function(response){
            var datatable = component.find(tableAuraId);
            datatable.finishSaving("SUCCESS");
        });
        $A.enqueueAction(action);        
    },
    
    doSelect : function(component, event, helper) {
        var recordId = event.getSource().get('v.name');
        var recordsList = component.get('v.recordsList');
        var selectedRecords = component.get('v.selectedRecords');
        var selectedDataObj = component.get('v.selectedDataObj'); 
        var action = component.get("c.updateRecords"); 
        action.setParams({ 
            quoteId : component.get("v.recordId"),
            assetEntered : component.get("v.selectedRecords")
        });
        action.setCallback(this, function(response){
             var state = response.getState();
             if (state === "SUCCESS") {
                //component.set("v.qlList", response.getReturnValue());
                alert('Success');
             }
             else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        alert('Failed');
                    }
                }
             }
         });
         $A.enqueueAction(action);
	},
})