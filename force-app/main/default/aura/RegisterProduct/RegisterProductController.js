({
	doInit : function(component, event, helper) {
        helper.getData(component);
        component.set("v.showSpinner", false);
        var url_string = window.location.href;
        var url = new URL(url_string);
        var nn = url.searchParams.get("nn");
        if(nn != null){
            component.set("v.nodename",nn);
            component.find("nname").set("v.value",nn);
        }
        var uuid = url.searchParams.get("uuid");
        if(uuid != null){ 
            component.set("v.uuid",uuid);
            component.find("uid").set("v.value",uuid);
        }
	},
    onBlur : function(component, event, helper) {
        let key = event.getSource().get('v.name');
        let value = event.getSource().get('v.value');
        helper.setDataInSessionStorage(key, value);
    },
    register : function(component, event, helper) {
        var manufacturingtimepattern = /^\d\d\d\d-(0[0-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])T([0-1][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$/;
        var uuidpattern = /^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/;

        component.set("v.showSpinner", true);
        var nodename = component.get("v.nodename");
        var uuid = component.get("v.uuid");
        // CS21-1150
        var manufacturingtime = component.get("v.manufacturingtime");
        var teleporttoken = component.get("v.teleporttoken");
        
        // Legacy: If the Manufacturing time and Teleport token fields are both null 
        if(!manufacturingtime && !teleporttoken){
            if(helper.isValidLegacyCdm(component) && nodename && uuid && uuidpattern.test(component.get('v.uuid'))){
                    component.set('v.islegacy', true);
                    helper.getRegisterProduct(component);
            }else{
                component.set("v.showSpinner", false);
            }
        }
        // Latest CDM: If the Manufacturing time and Teleport token fields both not null
        else if(manufacturingtime && teleporttoken){
                if(manufacturingtimepattern.test(component.get('v.manufacturingtime'))
                    && helper.isValidLatestCdm(component) && nodename){
                        component.set('v.islegacy', false);
                        helper.getRegisterProduct(component);
                    }else{
                        component.set("v.showSpinner", false);
                    }
        }else{
            component.set("v.showSpinner", false);
                }
	},
    onchange : function(component, event, helper){

        if(component.get("v.manufacturingtime")
            || component.get("v.teleporttoken")){
                component.set("v.ismanufacturingtimereq", true);
                component.set("v.isteleporttokenreq", true);
                component.set("v.isuuidreq", false);
                if(component.get("v.manufacturingtime") && !(/\s/.test(component.get("v.manufacturingtime")))){
                    component.set("v.ismanufacturingtimereq", false);
                }
                if(component.get("v.teleporttoken") && !(/\s/.test(component.get("v.teleporttoken")))){
                    component.set("v.isteleporttokenreq", false);
                }
        }else {
            component.set("v.ismanufacturingtimereq", false);
            component.set("v.isteleporttokenreq", false);
            component.set("v.isuuidreq", true);
        }
        if(component.get("v.uuid") && !(/\s/.test(component.get("v.uuid")))){
            component.set("v.isuuidreq", false);
        }
	},
    updateNode : function(component, event, helper) {
        var nodeVal = component.find("nname").get("v.value");
        if(!!nodeVal)
            component.find("nname").set("v.value",nodeVal.toUpperCase());
    },
})