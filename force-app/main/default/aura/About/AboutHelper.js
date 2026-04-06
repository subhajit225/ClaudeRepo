({
	responseTotal : function(component) {
		var action = component.get("c.TotalResponses");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.responseTillDate",result);
        });
        $A.enqueueAction(action);
	},
    blasts : function(component) {
		var action = component.get("c.blastResults");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            console.log(result);
            component.set("v.ChartData",result);
            component.set("v.goldStar",result['Gold Star']);
            component.set("v.greenLight",result['Green Light']);
            component.set("v.yellowLight",result['Yellow Light']);
            component.set("v.redLight",result['Red Light']);
            
        });
        $A.enqueueAction(action);
	},
    hapiness : function(component) {
		var action = component.get("c.hapinessFactor");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.hapiness",result);
        });
        $A.enqueueAction(action);
    },
    temprature : function(component) {
		var action = component.get("c.HappinessValue");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.temprature",result);
        });
        $A.enqueueAction(action);
    }
})