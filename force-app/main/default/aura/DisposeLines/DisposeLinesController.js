({
    doInit: function(component, event, helper) {
        component.set("v.isLoading", true);
        component.set("v.buttonsDisabled", false);
        helper.getQuoteFieldValues(component, event, helper); //Added by Shaloo
        //helper.setupTable(component, event, helper);//Commented & called in helper.getQuoteFieldValues by Shaloo
    },
     
    /*gotoRelatedList: function (component, event, helper) {
        helper.relatedList(component, event, helper);
        component.set("v.viewAll", false);
    },*/
    
    handleChange: function(cmp, event, helper) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        var optionCheckbox = cmp.find("optionCheckbox");
        
        if (optionCheckbox.length == undefined) {
            if (!Array.isArray(optionCheckbox)) {
                optionCheckbox = [optionCheckbox];
            }
        }
        
        var idSet = [];
        for (var i = 0; i < optionCheckbox.length; i++) {
            if (optionCheckbox[i].get("v.value") == true) {
                idSet.push(optionCheckbox[i].get("v.name"));
            }
        }
        console.log("idSet--> ", idSet);
        console.log("cmp--> ", cmp.get("v.tableData"));
        
        var tableData = cmp.get("v.tableData");
        for (var i = 0; i < tableData.length; i++) {
            console.log("idSet.includes(tableData[i].Id)--> ", idSet.includes(tableData[i].Id));
            if (idSet.includes(tableData[i].Id)) {
                for (var j = 0; j < tableData[i].fields.length; j++) {
                    console.log("tableData[i].fields[j].name--> ", tableData[i].fields[j].name);
                    if (tableData[i].fields[j].name == "Disposition_Reason__c") {
                        //tableData[i].fields[j].value = selectedOptionValue;
                        helper.updateTable1(cmp, i, j, selectedOptionValue);
                    }
                }
            }
        }
        console.log("tableData--> ", tableData);
        
        cmp.set("v.isEditModeOn", true);
        cmp.set("v.buttonsDisabled", false);
        //cmp.set("v.tableData",tableData);
    },
    
    selectAllOptions: function(cmp, event, helper) {
        var enableFlag = false;
        var selectAllOptionsCheckbox = cmp.find("selectAllOptions");
        var isSelected = selectAllOptionsCheckbox.get("v.value");
        
        var optionCheckbox = cmp.find("optionCheckbox");
        if (optionCheckbox.length == undefined) {
            if (!Array.isArray(optionCheckbox)) {
                optionCheckbox = [optionCheckbox];
            }
        }
        for (var i = 0; i < optionCheckbox.length; i++) {
            optionCheckbox[i].set("v.value", isSelected);
            if (optionCheckbox[i].get("v.value") == true) {
                enableFlag = true;
            }
            cmp.set("v.dropDownDisabled", enableFlag);
        }
    },
    
    selectOptionCheckbox: function(cmp, event, helper) {
        var enableFlag = false;
        console.log('inside selectOptionCheckbox');
        
        var optionCheckbox = cmp.find("optionCheckbox");
        console.log('optionCheckbox?', optionCheckbox);
        
        if (optionCheckbox.length == undefined) {
            if (!Array.isArray(optionCheckbox)) {
                optionCheckbox = [optionCheckbox];
            }
        }
        
        for (var i = 0; i < optionCheckbox.length; i++) {
            console.log('optionCheckbox[i]?', optionCheckbox[i]);
            if (optionCheckbox[i].get("v.value") == true) {
                enableFlag = true;
            }
            cmp.set("v.dropDownDisabled", enableFlag);
        }
    },
    
    saveTableRecords: function(component, event, helper) {
        var recordsData = event.getParam("recordsString");
        var updatedListQLIData = component.get("v.tableData");
        console.log('updatedListQLIData??' + JSON.stringify(updatedListQLIData));
        
        var tableAuraId = event.getParam("tableAuraId");
        console.log('testing save' + JSON.stringify(recordsData));
        
        var action = component.get("c.desposeLines");
        var conditionCheck = true;
        var test = true;
        console.log('conditionCheck??' + conditionCheck);
        
        if (conditionCheck == true) {
            component.set("v.showmsg", false);
            for (var i = 0; i < updatedListQLIData.length; i++) {
                console.log('  testing >>' + JSON.stringify(updatedListQLIData[i].fields));
                
                for (var j = 0; j < updatedListQLIData[i].fields.length; j++) {
                    console.log('updatedListQLIData[i].fields[j].name' + updatedListQLIData[i].fields[j].name);
                    
                    if (updatedListQLIData[i].fields[j].name == 'Disposition_Reason__c') {
                        var reason = updatedListQLIData[i].fields[j].value;
                        console.log('reason >>' + reason);
                    }
                }
                
                console.log('reason? ' + reason);
            }
        }
        if (test == true) {
            action.setParams({
                quoteLinesNew: component.get("v.modifiedRecords"),
                quoteId: component.get("v.recordId"),
                oldvalues: component.get("v.data")
            });
            var quoteId = component.get("v.recordId");
            action.setCallback(this, function(response) {
                var message = response.getReturnValue();
                component.set("v.message", message);
                console.log('show msg>' + message);
                console.log('show flag>' + component.get("v.showmsg"));
                if (message == null) {
                    component.set("v.showmsg", false);
                    var urlString = window.location.origin;
                    urlString = urlString.replace('c.', 'sbqq.');
                    console.log('urlString>>', urlString);
                    urlString = urlString + '/apex/sb?scontrolCaching=1&id=' + quoteId;
                    var callingSource = component.get("v.callingSource");
                    if (callingSource == 'QuoteDetail') {
                        urlString = '/' + quoteId;
                    }
                    
                    console.log('FinalurlString>>', urlString);
                    
                    if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
                        // Do something for Lightning Experience
                        console.log('testing lightning exp');
                        sforce.one.navigateToURL(urlString);
                    } else {
                        // Use classic Visualforce
                        console.log('testing classic exp');
                        window.location.href = urlString;
                    }
                } else {
                    component.set("v.showmsg", true);
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    editField: function(component, event, helper) {
        var field = event.getSource(),
            indexes = field.get("v.name"),
            rowIndex = indexes.split('-')[0],
            colIndex = indexes.split('-')[1];
        var data = component.get("v.tableData");
        data[rowIndex].fields[colIndex].mode = 'edit';
        data[rowIndex].fields[colIndex].tdClassName = 'slds-cell-edit slds-is-edited';
        component.set("v.tableData", data);
        component.set("v.isEditModeOn", true);
        component.set("v.buttonsDisabled", false);
    },
    
    onInputChange: function(component, event, helper) {
        var field = event.getSource(),
            value = field.get("v.value"),
            indexes = field.get("v.name"),
            rowIndex = indexes.split('-')[0],
            colIndex = indexes.split('-')[1];
        helper.updateTable1(component, rowIndex, colIndex, value);
    },
    
    saveRecords: function(component, event, helper) {
        component.set("v.buttonsDisabled", true);
        component.set("v.buttonClicked", "Save");
        component.set("v.isLoading", true);
        setTimeout(function() {
            var saveEvent = component.getEvent("dataTableSaveEvent");
            saveEvent.setParams({
                tableAuraId: component.get("v.auraId"),
                recordsString: component.get("v.modifiedRecords")
            });
            saveEvent.fire();
        }, 0);
        component.set("v.isLoading", false);
    },
    
    finishSaving: function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            var result = params.result, //Valid values are "SUCCESS" or "ERROR"
                data = params.data, //refreshed data from server
                message = params.message;
            console.log('message---' + JSON.stringify(message));
            if (result === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": 'success',
                    "message": "Records has been updated Successfully!"
                });
                toastEvent.fire();
                if (data) {
                    helper.setupData(component, data);
                } else {
                    var dataCache = component.get("v.dataCache"),
                        updatedData = component.get("v.updatedTableData");
                    component.set("v.data", JSON.parse(JSON.stringify(dataCache)));
                    component.set("v.tableDataOriginal", JSON.parse(JSON.stringify(updatedData)));
                    component.set("v.tableData", JSON.parse(JSON.stringify(updatedData)));
                }
                component.set("v.isEditModeOn", false);
                component.set("v.buttonsDisabled", true);
            } else {
                if (message) component.set("v.error", message);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": 'error',
                    "message": "Error in Updating Records!" + message
                });
                toastEvent.fire();
            }
        }
        
        component.set("v.isLoading", false);
        component.set("v.buttonsDisabled", false);
        component.set("v.buttonClicked", "");
    },
    
    closeEditMode: function(component, event, helper) {
        var urlString = window.location.origin;
        var callingSource = component.get("v.callingSource");
        var quoteId = component.get("v.recordId");
        urlString = urlString.replace('c.', 'sbqq.');
        console.log('urlString>>', urlString);
        urlString = urlString + '/apex/sb?scontrolCaching=1&id=' + quoteId;
        
        console.log('FinalurlString>>', urlString);
        
        if (callingSource == 'QuoteDetail') {
            urlString = '/' + quoteId;
        }
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            // Do something for Lightning Experience
            console.log('testing lightning exp');
            sforce.one.navigateToURL(urlString);
        } else {
            // Use classic Visualforce
            console.log('testing classic exp');
            window.location.href = urlString;
        }
    },
});