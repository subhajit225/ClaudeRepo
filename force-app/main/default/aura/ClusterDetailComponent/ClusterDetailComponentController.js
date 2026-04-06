({
	doInit : function(component, event, helper) {
        var visibiltyTabs = component.get("v.UserRecord.Account.Tabs_Visibility__c");  
        console.log('tb',visibiltyTabs);
        if(visibiltyTabs != null){
            if(!visibiltyTabs.includes('Cluster')){
                component.set("v.noRecord",true);
            }
        }
        var action = component.get("c.getClusterData");
        console.log('rec',component.get("v.record"));
        action.setParams({
            'clusterId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var res = response.getReturnValue();
            console.log(res);
            if(res == null){
                component.set("v.noRecord",true);
            }else{
                res.labels.reverse();
                var labels = res.labels;
                helper.fillChart(component,helper,res.clusMap['objects_protected__c'],'ObjectsData','pie','Objects Protected (Count)',res.labels,"rgba(218, 165, 32, 0.5)");
                helper.fillChart(component,helper,res.clusMap['snapshot_count__c'],'TotalData','pie','Total Snapshots (Count)',res.labels,"rgba(77, 166, 255, 0.5)");
                helper.fillChart(component,helper,res.clusMap['storage_usage__c'],'storageData','pie','Storage Usage (TB)',labels,"rgba(175, 0, 42, 0.5)",res);

            }
           
        });
        $A.enqueueAction(action);
	},
    iframeHeight : function(component, event, helper) {
        var iframe = document.getElementById('timeC');
        console.log(iframe);
        iframe.style.height = (iframe.offsetTop -2000) + 'px';        
    }
})