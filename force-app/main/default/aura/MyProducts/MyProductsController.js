({
    init : function(component, event, helper) {
        var visibiltyTabs = component.get("v.UserRecord.Account.Tabs_Visibility__c");  
        var url_string = window.location.href;		
        var url = new URL(url_string);		
        var selectedtab = url.searchParams.get("selectedtab");	
        
        if (selectedtab)	{	
            component.set("v.selectedTab",selectedtab);
        }
        
        if (visibiltyTabs != null){
            if (visibiltyTabs.includes('Cluster')){
                component.set("v.showClusters",true); 
            }
        }
        
        //added for CS21-759 
        var ProductSpinner = component.find("ProductSpinner");
        let userDetails = component.get("v.UserRecord");
        let polarisUrl = userDetails.Account.Customer_URL__c;

        if (!$A.util.isEmpty(polarisUrl)) {
            var action = component.get("c.getPolarisDataProtectionDetails");
            
            action.setCallback(component, function(response) {
                var result = response.getReturnValue();
                component.set("v.polarisContactDetails", result);
            });
            $A.enqueueAction(action);
        }
        helper.getRSCInstances(component, event, helper);
        $A.util.addClass(ProductSpinner,"slds-hide");
        //End - CS21-759 
    },
    //updated for CS21-759 
    getAssets : function(component, event, helper) {
        var ProductSpinner = component.find("ProductSpinner");
        var action = component.get("c.getCloudAssets");
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.clout",result.cloutList);
            component.set("v.clon",result.clonList);
            component.set("v.clcl",result.clclList);
            $A.util.addClass(ProductSpinner,"slds-hide");
        });
        $A.enqueueAction(action);
    },
    getClusters : function(component, event, helper) {
        var ProductSpinner = component.find("ProductSpinner");
        $A.util.removeClass(ProductSpinner,"slds-hide");
        var action = component.get("c.clusters");
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.clusters",result);
            $A.util.addClass(ProductSpinner,"slds-hide");
        });
        $A.enqueueAction(action);
    },
    // CS21-45 Start
    updateProactiveContactModal : function(component, event, helper) {
        var clusterIdList = component.get("v.selectedClusterIdList");
        var unCheckedClusterIdList = component.get("v.unCheckedClusterIdList");
        if(unCheckedClusterIdList.length > 0 || clusterIdList.length > 0 || component.get("v.isUpdateAllCluster")){
            component.set("v.showModal",true);
        }else{
            // Show warning toast
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
                toastEvent.setParams({
                    title: "Warning",
                    message: 'Please select Clusters to update',
                    type: "warning"
                });
                toastEvent.fire();
            }
        }
    },
    closeModal : function(component, event, helper) {
        component.set("v.isUpdateAllCluster", false)
        // UnCheck Bulk Cluster Update box
        helper.unCheckBulkClustersCheckbox(component, event, helper);
        // UnCheck all Clusters selected from List
        helper.unCheckClustersFromList(component, event, helper);
        component.set("v.showModal",false);
        component.set("v.selectedProactiveContact",'');
    },
    getSelectedValue : function(component, event, helper) {
        component.set("v.selectedProactiveContact", event.getParam('selectedRecord').Id);
    },
    handleSaveProactiveContact : function(component, event, helper) {  
        // No Lookup Selected
        if(component.get("v.selectedProactiveContact")){
            component.set("v.toggleSpinner", true);
            var action = component.get("c.bulkUpdateProactiveContactOnClusters");
            var clusterIdList = component.get("v.selectedClusterIdList");
            var unCheckedClusterIdList = component.get("v.unCheckedClusterIdList");
            action.setParams({ proContactId : component.get("v.selectedProactiveContact"),
                                accId : component.get("v.UserRecord.AccountId"),
                                clusterIds : clusterIdList,
                                uncheckedclusterIds : unCheckedClusterIdList,
                                isUpdateAllClusters : component.get("v.isUpdateAllCluster")});
            action.setCallback(component, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.isUpdateAllCluster", false)
                    // UnCheck Bulk Cluster Update box
                    helper.unCheckBulkClustersCheckbox(component, event, helper);
                    // UnCheck all Clusters selected from List
                    helper.unCheckClustersFromList(component, event, helper);
                    // You can show a success toast
                    var toastEvent = $A.get("e.force:showToast");
                    if (toastEvent) {
                        toastEvent.setParams({
                            title: "Success",
                            message: "Clusterts are updated successfully.",
                            type: "success"
                        });
                        toastEvent.fire();
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    var message = "Unknown error"; // Default message
                    if (errors && errors[0] && errors[0].message) {
                        message = errors[0].message;
                    }
                    if(message.includes('INSUFFICIENT_ACCESS_OR_READONLY')){
                        message = 'Update Failed: You don\'t have the necessary permissions to update this record. Please contact your Salesforce administrator for assistance.'
                    }
                    // Show error toast
                    var toastEvent = $A.get("e.force:showToast");
                    if (toastEvent) {
                        toastEvent.setParams({
                            title: "Error",
                            message: message,
                            type: "error"
                        });
                        toastEvent.fire();
                    }
                }
                component.set("v.toggleSpinner", false);
                component.set("v.showModal",false);
            });
            $A.enqueueAction(action);
        }else{
            // Show warning toast
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
                toastEvent.setParams({
                    title: "Warning",
                    message: 'Please select Proactive Contact before updating Clusters.',
                    type: "warning"
                });
                toastEvent.fire();
            }
        }
    },
    onCheckCluster : function(component, event, helper) {
        // UnCheck Bulk Cluster Update box
        helper.unCheckBulkClustersCheckbox(component, event, helper);
        

        // Add Selected ClusterIds to List
        var clusterId = event.getSource().get('v.value');
        var clusterIdList = component.get("v.selectedClusterIdList");
        var unCheckedClusterIdList = component.get("v.unCheckedClusterIdList");
        component.set("v.isUpdateAllCluster", false)
        if(event.getSource().get('v.checked')){
            clusterIdList.push(clusterId);
        }else{
            // UnChecked Cluster Ids
            unCheckedClusterIdList.push(clusterId);


            // Remove from list
            clusterIdList = clusterIdList.filter(function(id) {
                return id !== clusterId;
            });
        }
        component.set("v.selectedClusterIdList", clusterIdList);
        component.set("v.unCheckedClusterIdList", unCheckedClusterIdList);
    },
    onCheckAllCluster : function(component, event, helper) {
        // boolean val based on checkbox
        if(event.getSource().get('v.checked')){
            component.set("v.isUpdateAllCluster", true)
            // Check all Clusters selected from List
            helper.checkAllClusters(component, event, helper);
        }else{
            // UnCheck all Clusters selected from List
            helper.unCheckClustersFromList(component, event, helper);
            component.set("v.isUpdateAllCluster", false)
        }
    },
    // CS21-45 End
    getMosaicClusters : function(component, event, helper) {
        var ProductSpinner = component.find("ProductSpinner");
        $A.util.removeClass(ProductSpinner,"slds-hide");
        var action = component.get("c.MosaicClusters");
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.mosaicClusters",result);
            $A.util.addClass(ProductSpinner,"slds-hide");
        });
        $A.enqueueAction(action);
    },
    getEdges : function(component, event, helper) {
        var ProductSpinner = component.find("ProductSpinner");
        $A.util.removeClass(ProductSpinner,"slds-hide");
        var action = component.get("c.EdgeNodes");
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.edgeAssets",result);
            $A.util.addClass(ProductSpinner,"slds-hide");
        });
        $A.enqueueAction(action);
    },
    getDarkNodes : function(component, event, helper) {
        var ProductSpinner = component.find("ProductSpinner");
        $A.util.removeClass(ProductSpinner,"slds-hide");
        var action = component.get("c.darkNodes");
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.darkNodes",result);
            $A.util.addClass(ProductSpinner,"slds-hide");
        });
        $A.enqueueAction(action);
    },
    redirect : function(cmp, event, helper) {
        var searchText = cmp.get("v.searchString");
        if(searchText != null && event.getParams().keyCode == 13){
            
            if(searchText == undefined){
                searchText = '';
            }
            window.open("productsearch?search="+searchText, '_self');
        }
        
        //window.location.href ={!$Site.CurrentSiteUrl}UnifiedSearchSupport#/search?searchString=' +encodeURIComponent(searchText);
        
    },
    //added for CS21-468 - Veera
    search: function(component, event, helper) {
        var searchText = component.get("v.searchString");
        var searchBox = component.find('searchBox');
        
        if (searchText != null){ 
            if (searchText == undefined){
                searchText = '';
            }
            $A.util.removeClass(searchBox, 'required');
            window.open("productsearch?search="+searchText, '_self');
        } else {
            $A.util.addClass(searchBox, 'required');
        }
    },
    downloadInstallBase : function(component, event, helper){
        var action = component.get("c.getInstallWrapper");
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            var csv = [];
            csv.push("Type,Name,Cluster UUID,StartDate,EndDate,Node Serial Number,Asset,Chassis Serial Number,Parent Asset");            
            for(var i in result){
                var row = [];
                row.push(result[i].ibtype);
                row.push(result[i].ibname);
                row.push(result[i].uuid);
                row.push(result[i].startdate);
                row.push(result[i].termdate ? result[i].termdate : result[i].enddate);
                row.push(result[i].serial);
                row.push(result[i].assetnum);
                row.push(result[i].chassiSerialNumber);
                row.push(result[i].parentassetname);
                csv.push(row.join(","));   
            }
            var csvFile = csv.join("\n");
            // Download CSV file
            var hiddenElement = document.createElement('a');
            hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvFile);
            hiddenElement.target = '_self'; // 
            hiddenElement.download = 'Rubrik_installbase.csv';  // CSV file Name* you can change it.[only name not .csv] 
            document.body.appendChild(hiddenElement); // Required for FireFox browser
            hiddenElement.click();
        });
        $A.enqueueAction(action);
    }
})