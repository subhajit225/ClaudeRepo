({
	doinit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        component.set("v.showInsightMatchesSection", false);
        helper.identifyObject(component);
        helper.retrieveInsightMatchesWrapper(component);
    },

    toggleInsightMatchesSection : function(component, event, helper) {
        component.set("v.showInsightMatchesSection", !component.get("v.showInsightMatchesSection"));
    },

    toggleSeveritySection : function(component, event, helper) {
        let clickedSeverity = event.target.name;
        let downArrow = document.getElementById(clickedSeverity.downArrowId);
        $A.util.toggleClass(downArrow, 'slds-hide');

        let rightArrow = document.getElementById(clickedSeverity.rightArrowId);
        $A.util.toggleClass(rightArrow, 'slds-hide');

        let section = document.getElementById(clickedSeverity.section);
        $A.util.toggleClass(section, 'slds-hide');
    },
})