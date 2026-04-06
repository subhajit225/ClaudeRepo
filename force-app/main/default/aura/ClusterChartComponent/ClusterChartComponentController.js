({
	doInit : function(component, event, helper) {
        var action = component.get("c.getChartsData");
        action.setCallback(this, function(response){
            var res = response.getReturnValue();
            component.set("v.allData",res.allData);
            component.set("v.ownData",res.ownData);
            helper.fillChart(component,helper,res.allData,'allData','pie');
            helper.fillMyChart(component,helper,res.ownData,'myData','doughnut');
        });
        $A.enqueueAction(action);
	},
    hideChart : function(component, event, helper){
        component.set("v.showChart",false);
        component.set("v.chartType",'');
        document.getElementById("childContainer").innerHTML = "";    
    }
})