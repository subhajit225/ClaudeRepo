({
	toggleLeftSection : function(component, event, helper) {
        component.set('v.isLeftSidebarCollapsed', !component.get('v.isLeftSidebarCollapsed'));
    },
    parentComponentEvent : function(component, event, helper){
        var recType = event.getParam("recordType");
        //var showMilestoneComp = event.getParam("showMilestone");
        if(recType == 'Support Case'){
            component.set('v.recordType','Support');
        }else{
            component.set('v.recordType','Renewal');
        }
        //component.set('v.showMilestone', showMilestoneComp);//Used to show hide Milestone Component below hero header section
    },
    handleSectionToggle: function (component,event){
        var activeSection = component.get("v.activeSections");
        if(activeSection.includes('A')){
            component.set('v.showJira',true);
        }
        if(activeSection.includes('B')){
            component.set('v.showArticleSection',true);
        } 
        if(activeSection.includes('D')){
            component.set('v.showActivitySection',true);
        }else{
            component.set('v.showActivitySection',false);
        }
    }
})