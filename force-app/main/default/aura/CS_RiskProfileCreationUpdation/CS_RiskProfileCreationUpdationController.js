({
    doInit : function(component, event, helper) {
        let recordId = component.get('v.recordId');
        if(recordId){
            return component.set('v.isLoading', false);
        }
        let urlData = component.get('v.pageReference');
        if(urlData.state != undefined && urlData.state.inContextOfRef != undefined){
            let inContextOfRaw = urlData.state.inContextOfRef;
            let inContextOf = inContextOfRaw.split('.')[1];
            let decoded = atob(inContextOf);
            let decodedJson = JSON.parse(decoded);
            
            if(decodedJson.attributes != undefined && decodedJson.attributes.recordId != undefined){
                component.set('v.recordId', decodedJson.attributes.recordId);//Sets the recordId 
            }
        }
        component.set('v.isLoading', false);//Sets the recordId 
    },
    closeFocusedTab: function(component, event, helper) {
        
        var workspaceAPI = component.find("workspace");
        
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation()
        .then(function(response) {            
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getEnclosingTabId().then(function(tabId) {
                
                workspaceAPI.closeTab({
                    tabId: tabId
                });
            })
            .catch(function(error) {
                
            });
        })
        .catch(function(error) {
            console.error('workspaceAPI error', error);
        });        
    }
})