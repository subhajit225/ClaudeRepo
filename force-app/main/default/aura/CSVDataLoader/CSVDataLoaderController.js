({
    handleUploadFinished : function(component, event, helper) {
        var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];
        if(file) {
            var reader = new FileReader();
            reader.readAsText(file, 'UTF-8');
            reader.onload = function(evt) {
                var csv = evt.target.result;
                component.set("v.csvString", csv);
            } 
        }
    },

    handleNewUpload : function(component, event, helper){
        component.set("v.errorMessage", '');
        component.set("v.mapLines", null);
        component.set("v.csvString", null);
        component.set("v.csvObject", null);
        component.find("file").getElement().value='';
        component.set("v.disableButton", true);
        component.set("v.displayStatus", false);
    },

    handleGetCSV : function(component, event, helper) {
        var csv = component.get("v.csvString");
        if(csv != null) {
            component.set("v.loadSpinner", true);
            helper.createCSVObject(component, csv);
        }
    },
    
    handleSave : function(component, event, helper) {
        var lstOrders = component.get("v.csvObject.lstOrders");
        if(lstOrders != undefined) {
            component.set("v.loadSpinner", true);
            component.set("v.disableSave", true);
            helper.saveOrdersHelper(component, lstOrders);
        }
    },

    cleanData : function(component) {
        component.set("v.csvString", null);
        component.set("v.csvObject", null);
        component.set("v.mapLines", null);
        component.find("file").getElement().value='';
        component.set("v.errorMessage", '');
        component.set("v.disableButton", true);
        component.set("v.disableSave", true);
        component.set("v.displayStatus", false);
    },
})