({
    redirectToTraning : function(component, event, helper) {
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "https://rubrik.docebosaas.com/customers/learn/course/internal/view/classroom/1161/4-day-introduction-to-rubrik-cdm-virtual-bootcamp"
        }).fire();
    },
    redirectToExam : function(component, event, helper) {
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "https://rubrik.docebosaas.com/customers/pages/70/get-certified"
        }).fire();
    }
})