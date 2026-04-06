({
    getData : function(component) {
        this.getDataFromSessionStorage(component, 'uuid');
        this.getDataFromSessionStorage(component, 'nodeId');
        this.getDataFromSessionStorage(component, 'entitlementId');
        this.getDataFromSessionStorage(component, 'manufacturingTime');
        this.getDataFromSessionStorage(component, 'teleportToken');
    },

    getDataFromSessionStorage : function(component, key) {
        if(sessionStorage) {
            let value = sessionStorage.getItem(key);
            if(value) {
                component.set('v.' + key, value);
            }
        }
    },

    setDataInSessionStorage : function(key, value) {
        if(sessionStorage) {
            sessionStorage.setItem(key, value);
        }
    },

    validateData : function(component) {
  
        var uuidInput = component.find("uuid");
        uuidInput.reportValidity();

        var nodeIdInput = component.find("nodeId");
        nodeIdInput.reportValidity();

        var entitlementIdInput = component.find("entitlementId");
        entitlementIdInput.reportValidity();

        var manufacturingTimeInput = component.find("manufacturingTime");
        manufacturingTimeInput.reportValidity();

        var teleportTokenInput = component.find("teleportToken");
        teleportTokenInput.reportValidity();

        return (uuidInput.get("v.validity").valid && nodeIdInput.get("v.validity").valid && entitlementIdInput.get("v.validity").valid && manufacturingTimeInput.get("v.validity").valid && teleportTokenInput.get("v.validity").valid);
    },

    registerProduct : function(component){
        var action = component.get("c.registerThirdPartyHardware");

        var formFieldsObject = {
            serialNumber : '',
            uuid : component.get("v.uuid"),
            nodeId : component.get("v.nodeId"),
            entitlementId : component.get("v.entitlementId"),
            manufacturingTime : component.get("v.manufacturingTime"),
            teleportToken : component.get("v.teleportToken")
        }

        action.setParams({
            thirdPartyHardwareFormFields : JSON.stringify(formFieldsObject)
        });

        action.setCallback(this, function(response) {
            component.set("v.displayTimeoutMessage", false);
            var state = response.getState();
            if (state === "SUCCESS"){
                var result = response.getReturnValue();
                component.set("v.nodeRes", result);
                for(var i = 0; i < result.length; i++){
                    if((result[i].internalError || result[i].integrationError) && result[i].message != '' && result[i].message != null){
                        component.set("v.hasError", true);
                        break;
                    }
                }
            }
            else{

            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    }
})