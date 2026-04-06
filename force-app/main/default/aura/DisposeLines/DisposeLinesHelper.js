({
    setupTable: function(component, event, helper) {
        console.log('Get Value2: ' + component.get("v.profileName")); //Added by Shaloo
        
        // Calling apex method to get picklist values dynamically
        var action = component.get("c.getPicklistValues");
        action.setParams({ 
            objectAPIName: "SBQQ__QuoteLine__c",
            fieldAPIName: "Disposition_Reason__c",
        });
        action.setCallback(this, function(response) {
            //if (response.getState() === "SUCCESS") { 
            var reason = [];
            Object.entries(response.getReturnValue()).forEach(([key, value]) => reason.push({ 
                label: key,
                value: value
            }));
            //component.set("v.reasonList", reason);
            console.log('here picklistA > ' + JSON.stringify(reason));
            
            //START: Added by Shaloo
            if (component.get("v.profileName") != 'System Administrator' &&
                component.get("v.profileName") != 'Deal Operations' &&
                component.get("v.profileName") != 'Sales Operations' ) { //component.set()
                console.log('Enter Here for Admin B4: ' + JSON.stringify(reason));
                //reason.pop({ label: 'Converted', value: 'Not Renewing - Converted' });
                
                //MS CPQ22-5139 to include Not Renewing - Refreshed
                let drOptions = component.get("v.optionsA");
                let refOption = drOptions.find(opt => opt.value === 'Not Renewing - Refreshed');
                if (refOption) {
                    reason.splice(1, 1);
                    reason.splice(4, 1);
                } else {
                    reason.splice(1, 2);
                    reason.splice(3, 1);
                }
                console.log('Enter Here for Admin A4: ' + JSON.stringify(reason));
                component.set("v.reasonList", reason);
                component.set("v.showOptionsA", true);
            } else {
                console.log('Enter Here for Non-Admin B4: ' + reason);
                reason.splice(5,1);
                component.set("v.reasonList", reason);
                component.set("v.showOptionsA", false);
            }
            //END: Added by Shaloo
            
            this.columns(component, event, helper);
            // this.setupTableStatus(component, event, helper);
            /* } else {
                var errors = response.getError();
                var message = "Error: Unknown error";
                if (errors && Array.isArray(errors) && errors.length > 0) message = "Error: " + errors[0].message;
                component.set("v.error", message);
            }*/
        });
        $A.enqueueAction(action);
    },
    
    //START: Added by Shaloo
    getQuoteFieldValues: function(component, event, helper) {
        console.log('getQuoteFieldValues CALLED: ');
        var loggedProfileName = '';
        var dealOpsExcp;
        var action = component.get("c.getQuoteFieldValuesFromApex");
        //action.setParams({quoteId: "v.recordId"});
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            console.log('response B: ' + response);
            console.log('getReturnValue B: ' + response.getReturnValue());
            console.log('Profile Name: ' + response.getReturnValue().Running_User_Profile__c);
            loggedProfileName = response.getReturnValue().Running_User_Profile__c;
            component.set("v.profileName", loggedProfileName);
            console.log('v.profileNameA: ' + component.get("v.profileName"));
            dealOpsExcp = response.getReturnValue().RWD_Deal_Ops_Exception__c;
            if(dealOpsExcp && dealOpsExcp.includes('R7k Manual Refresh')){
                var drOpts = component.get("v.optionsA");
                drOpts.push({'label': 'Not Renewing - Refreshed', 'value': 'Not Renewing - Refreshed'});
                component.set("v.optionsA", drOpts);
                console.log('ms v.optionsA: ' + component.get("v.optionsA"));
            }
            helper.setupTable(component, event, helper);
        });
        $A.enqueueAction(action);
    },
    //END: Added by Shaloo
    
    columns: function(component, event, helper) {
        // var originOption = [];
        var reasonOption = [];
        //var replaceByOptions = [];
        console.log('inside fetchdata');
        //originOption = component.get("v.originList");
        reasonOption = component.get("v.reasonList");
        //replaceByOptions = component.get("v.replaceByMap");
        console.log('reasonOption>' + JSON.stringify(reasonOption));
        var cols = [{
            label: "Disposition reason",
            fieldName: "Disposition_Reason__c",
            type: "picklist",
            editable: true,
            selectOptions: reasonOption,
            resizable: true
        },
                    {
                        label: "Service Contract",
                        fieldName: "ServiceContract",
                        type: "Number",
                        resizable: true
                    },
                    {
                        label: "Product",
                        fieldName: "SBQQ__ProductCode__c",
                        type: "Text",
                        resizable: true
                    },
                    {
                        label: "Parent Product",
                        fieldName: "Required_By_Product_Code__c",
                        type: "Text",
                        resizable: true
                    },
                    {
                        label: "Asset",
                        fieldName: "Subscribed_Asset_Name__c",
                        type: "Text",
                        resizable: true
                    },
                    {
                        label: "Start Date",
                        fieldName: "SBQQ__StartDate__c",
                        type: "Date",
                        resizable: true
                    },
                    {
                        label: "End Date",
                        fieldName: "SBQQ__EndDate__c",
                        type: "Date",
                        resizable: true
                    },
                    {
                        label: "Quantity",
                        fieldName: "SBQQ__Quantity__c",
                        type: "Number",
                        resizable: true
                    },
                    {
                        label: "List Price",
                        fieldName: "SBQQ__ListPrice__c",
                        type: "currency",
                        resizable: true
                    }
                   ];
        console.log('Here is the data');
        console.log('Here is the data');
        component.set("v.columns", cols);
        this.loadRecords(component);
    },
    
    loadRecords: function(component) {
        var action = component.get("c.getQuoteLines");
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            //  if (response.getState() === "SUCCESS") {
            var lst = [];
            let qlLists = response.getReturnValue();
            if (qlLists != null) {
                console.log('value lst' + qlLists);
                for (var i = 0; i < qlLists.length; i++) {
                    console.log('show the ql>1' + qlLists[i]);
                    if ((qlLists[i].SBQQ__SubscriptionPricing__c === "Fixed Price" && qlLists[i].Quote_Line_Type__c === "Renewal" && qlLists[i].Special_Program__c != 'Conversion') || qlLists[i].SBQQ__Product__r.Is_MSP_Product__c  ) {
                        console.log('show the ql>' + qlLists[i]);
                        //qlLists[i].replaceBy = qlLists[i].Replace_By__c;
                        lst.push(qlLists[i]);
                        console.log('inside here0' + lst);
                    }
                    var row = qlLists[i];
                    if (row.SBQQSC__RenewedContractLine__c) row.ServiceContract = row.SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber;
                }
            }
            if (lst != null) {
                console.log('lst>>11' + JSON.stringify(lst));
                component.set("v.data", lst);
                console.log('lst : ' + JSON.stringify(component.get("v.data")));
                console.log('lst>>' + lst);
            }
            
            console.log('show data' + lst);
            console.log('show data' + lst);
            component.set("v.isLoading", false);
            this.setupTable1(component);
            /*} else {
                var errors = response.getError();
                var message = "Error: Unknown error";
                if (errors && Array.isArray(errors) && errors.length > 0) message = "Error: " + errors[0].message;
                component.set("v.error", message);
                console.log("Error: " + message);
            }*/
        });
        $A.enqueueAction(action);
    },
    
    setupTable1: function(component) {
        var cols = component.get("v.columns"),
            data = component.get("v.data");
        console.log('in setuptable');
        console.log('in setuptable11' + JSON.stringify(component.get("v.data")));
        this.setupColumns1(component, cols);
        this.setupData1(component, data);
        component.set("v.isLoading", false);
    },
    
    setupColumns1: function(component, cols) {
        console.log('inside setucols');
        console.log('cols:' + JSON.stringify(cols));
        var tempCols = [];
        //if (cols) {
        cols.forEach(function(col) {
            
            col.thClassName = "";
            tempCols.push(col);
        });
        component.set("v.columns", JSON.parse(JSON.stringify(tempCols)));
        console.log('v.columns' + component.get('v.columns'));
        // }
    },
    
    setupData1: function(component, data) {
        var dispReasonValueMap = new Map();
        console.log('inside setupddata');
        var productCode;
        var tableData = [],
            cols = component.get("v.columns");
        component.set("v.dataCache", JSON.parse(JSON.stringify(data)));
        console.log('show cols' + JSON.stringify(component.get("v.dataCache")));
        if (data) {
            data.forEach(function(value, index) {
                var row = {},
                    fields = [];
                cols.forEach(function(col) {
                    //set data values
                    var field = {};
                    field.name = col.fieldName;
                    field.value = value[col.fieldName];
                    if (field.name == 'SBQQ__ProductCode__c') {
                        productCode = field.value;
                    }
                    
                    field.type = col.type ? col.type : "text";
                    
                    if (field.type === "currency") {
                        field.isViewSpecialType = true;
                        console.log('Inside currency');
                    }
                    if (field.type === "Text") {
                        field.isViewSpecialType = true;
                        console.log('Inside text');
                    }
                    if (field.type === "Number") {
                        field.isViewSpecialType = true;
                        console.log('Inside number');
                    }
                    
                    if (field.type === "picklist") {
                        field.isEditSpecialType = true;
                        field.selectOptions = col.selectOptions;
                        var opts = col.selectOptions;
                        console.log('opts??' + JSON.stringify(opts));
                        var specificOptions = [];
                        specificOptions.push({
                            label: 'None',
                            value: 'None'
                        });
                    }
                    
                    field.editable = col.editable ? col.editable : false;
                    field.tdClassName = field.editable === true ? "slds-cell-edit" : "";
                    field.mode = "view";
                    console.log('value.Id???' + value.Id);
                    console.log('field.name???' + field.name);
                    console.log('field.value???' + field.value);
                    fields.push(field);
                });
                row.Id = value.Id;
                row.fields = fields;
                console.log('row' + JSON.stringify(row));
                tableData.push(row);
            });
            //console.log('dispReasonValueMap??' + dispReasonValueMap);
            for (var i = 0; i < tableData.length; i++) {
                console.log('tableData[i]??' + JSON.stringify(tableData[i].fields));
                for (var j = 0; j < tableData[i].fields.length; j++) {
                    console.log('tableData[i].fields[j]??' + tableData[i].fields[j]);
                    tableData[i].fields[j].isDisabled = false;
                }
            }
            component.set("v.tableData", tableData);
            console.log('datatable>' + JSON.stringify(tableData));
            component.set("v.tableDataOriginal", JSON.parse(JSON.stringify(tableData)));
            component.set("v.updatedTableData", JSON.parse(JSON.stringify(tableData)));
            console.log('updatedtable>>>' + JSON.stringify(component.get("v.updatedTableData")));
        }
    },
    
    updateTable1: function(component, rowIndex, colIndex, value) {
        //Update Displayed Data
        var data = component.get("v.tableData");
        console.log('rowIndex??' + rowIndex);
        data[rowIndex].fields[colIndex].value = value;
        component.set("v.tableData", data);
        //Update Displayed Data Cache
        var updatedData = component.get("v.updatedTableData");
        console.log('updated data<' + JSON.stringify(component.get("v.updatedTableData")));
        console.log('updatedData[rowIndex].fields[colIndex].value>>1' + updatedData[rowIndex].fields[colIndex].value);
        updatedData[rowIndex].fields[colIndex].value = value;
        console.log('updatedData[rowIndex].fields[colIndex].value>>2' + value);
        updatedData[rowIndex].fields[colIndex].mode = "view";
        
        console.log('updatedData??' + JSON.stringify(updatedData));
        component.set("v.updatedTableData", updatedData);
        //Update modified records which will be used to update corresponding salesforce records
        //
        var newList = [];
        // component.set("v.modifiedRecords", newList);
        var records = component.get("v.modifiedRecords");
        console.log("records---" + JSON.stringify(records));
        var recIndex = records.findIndex((rec) => rec.Id === data[rowIndex].Id);
        console.log("recIndex---" + recIndex);
        //if (recIndex !== -1) {
        console.log('if sam');
        var counter = 0;
        for (var i = 0; i < records.length; i++) {
            if (records[i].Id == data[rowIndex].Id) {
                counter++;
                console.log('already present');
                //records[i]["" + data[rowIndex].fields[9].name] = data[rowIndex].fields[9].value;
                records[i]["" + data[rowIndex].fields[colIndex].name] = value;
            }
        }
        console.log("records111---" + JSON.stringify(records));
        if (counter == 0) {
            var obj = {};
            obj["Id"] = data[rowIndex].Id;
            var fieldNameTemp = data[rowIndex].fields[colIndex].name;
            //obj["" + data[rowIndex].fields[9].name] = data[rowIndex].fields[9].value;
            obj["" + data[rowIndex].fields[colIndex].name] = value;
            records.push(obj);
        }
        
        console.log('here is the obj' + JSON.stringify(obj));
        component.set("v.modifiedRecords", records);
        console.log("records---123" + JSON.stringify(records));
        //Update Data Cache
        var dataCache = component.get("v.dataCache");
        console.log('datacache' + JSON.stringify(dataCache));
        var recIndex = dataCache.findIndex((rec) => rec.Id === data[rowIndex].Id);
        var fieldName = data[rowIndex].fields[colIndex].name;
        console.log('recIndex??' + recIndex);
        console.log('colIndex??' + colIndex);
        
        dataCache[recIndex][fieldName] = value;
        dataCache[recIndex][fieldName] = value;
        console.log('dataCache>>>' + JSON.stringify(dataCache));
        component.set("v.dataCache", dataCache);
    },
    
    sortData1: function(component, sortBy, sortDirection) {
        var reverse = sortDirection !== "asc",
            data = component.get("v.dataCache");
        if (!data) return;
        var data = Object.assign([], data.sort(this.sortDataBy(sortBy, reverse ? -1 : 1)));
        this.setupData(component, data);
    },
    
    sortDataBy1: function(field, reverse, primer) {
        var key = primer ?
            function(x) {
                return primer(x[field]);
            } :
        function(x) {
            return x[field];
        };
        return function(a, b) {
            var A = key(a);
            var B = key(b);
            return reverse * ((A > B) - (B > A));
        };
    }
})