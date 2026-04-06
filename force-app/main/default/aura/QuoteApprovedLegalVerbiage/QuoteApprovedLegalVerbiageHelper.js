({
    doInitHelper: function (cmp, event, helper) {
        cmp.set('v.columns', [
            {label: 'Approved Legal Language', fieldName: 'Approved_Legal_Language_Name__c', type: 'text'},
            {label: 'Approved Legal Verbiage', fieldName: 'Approved_Legal_Verbiage__c', type: 'text',wrapText: true }
        ]);
        
        var action = cmp.get("c.getData");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {                
                cmp.set("v.data", response.getReturnValue());
            }
        });
	 	$A.enqueueAction(action);
    },
    
    updateSelectedTextHelper: function (cmp, event) {
        var selectedRows = event.getParam('selectedRows');
        cmp.set('v.selectedRowsCount', selectedRows.length);
    },
    
   // handleCancelHelper: function(event){
    	//$A.get("event.force:closeQuickAction").fire();
	//},
    
    handleSaveHelper : function (cmp, event) {
        cmp.set("v.Spinner", true);
        var selectedRows = cmp.find('legalTable').getSelectedRows();
        selectedRows.forEach(function(term){
           //alert(term.Approved_Legal_Verbiage__c) ;
        });
        
        var action = cmp.get("c.updateQuote");
        action.setParams({
            legalList: selectedRows,
            recId: cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.Spinner", false);
                var resultsToast = $A.get("e.force:showToast");
                var resp = response.getReturnValue();
                if(resp['Error']!=null)
                {	
                    resultsToast.setParams({
                        "title":"Error Occured",
                        "message": resp['Error'],
                        "duration":5000, 
                        "key": "info_alt",
                        "type": "error",
                        "mode": "dismissible"
                    }); 
                    
                    
                }
                $A.get("event.force:closeQuickAction").fire();
                $A.get("event.force:refreshView").fire();
            } else {
                component.set("v.Spinner", false);
                alert("Error:", response.getError());
            }
        });
        
        $A.enqueueAction(action);
    }
});