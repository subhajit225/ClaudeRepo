({
	getData : function(component) {
        this.getDataFromSessionStorage(component, 'nodename');
        this.getDataFromSessionStorage(component, 'uuid');
        this.getDataFromSessionStorage(component, 'manufacturingtime');
        this.getDataFromSessionStorage(component, 'teleporttoken');
		
        // validate Latest CDM fields
        this.validatelatestCdmFields(component);
    },

    validatelatestCdmFields: function(component) {
        if(component.get("v.manufacturingtime") || component.get("v.teleporttoken")){
            if(component.get("v.manufacturingtime")){
                component.set("v.ismanufacturingtimereq", false);
            }else{
                component.set("v.ismanufacturingtimereq", true);
	}
            if(component.get("v.teleporttoken")){
                component.set("v.isteleporttokenreq", false);
            }else{
                component.set("v.isteleporttokenreq", true);
            }
            component.set("v.isuuidreq", false);
        }
        component.set("v.isuuidreq", false);
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
    
    isValidLegacyCdm: function(component) {
        component.set("v.ismanufacturingtimereq", false);
		component.set("v.isteleporttokenreq", false);
        // validation of uuid
        var uuid = component.get("v.uuid");
        if(uuid){
            component.set("v.isuuidreq", false);
        }else{
            component.set("v.isuuidreq", true);
        }

		var nameInput = component.find("nname");
        nameInput.reportValidity();

        var mtimeInput = component.find("mtime");
        mtimeInput.reportValidity();

		var ttokenInput = component.find("ttoken");
        ttokenInput.reportValidity();

		var uuidInput = component.find("uuid");
        uuidInput.reportValidity();
		
		return (nameInput.get("v.validity").valid 
				&& uuidInput.get("v.validity").valid);
	},
	isValidLatestCdm: function(component) {

        this.validatelatestCdmFields(component);

		var nameInput = component.find("nname");
        nameInput.reportValidity();

        var mtimeInput = component.find("mtime");
        mtimeInput.reportValidity();

		var ttokenInput = component.find("ttoken");
        ttokenInput.reportValidity();

		var uuidInput = component.find("uuid");
        uuidInput.reportValidity();
		
		return (nameInput.get("v.validity").valid 
				&& mtimeInput.get("v.validity").valid
				&& ttokenInput.get("v.validity").valid);
	},
	getRegisterProduct: function(component) {

        var action = component.get("c.registerProduct");
        action.setParams({
            nodename:component.get("v.nodename"),
            uuid:component.get("v.uuid"),
            manufacturingtime:component.get("v.manufacturingtime"),
            teleporttoken:component.get("v.teleporttoken"),
			islegacy:component.get('v.islegacy')
        });
        action.setCallback(component, function(response) {
            // console.log('response: ',response.getReturnValue());
            var result = response.getReturnValue();
            component.set("v.nodeRes",result);
            if(result != null && result != ''){
                component.set("v.regString",result.regString);
                component.set("v.regdownload",result.regdownload);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
	
})