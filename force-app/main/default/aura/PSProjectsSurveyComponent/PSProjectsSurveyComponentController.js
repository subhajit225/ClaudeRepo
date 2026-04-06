({
	onInit : function(component, event, helper) {
		helper.checkSurveyInvitationAccess(component);
        helper.getUItheme(component,event,helper);
    },
    addRemoveAll : function(component, event, helper) {
        var isSelected = event.getSource().get("v.checked");

        helper.updateCurrentPageContactsList(component, isSelected);
        helper.updateAllContactsList(component, isSelected);
        helper.setHeaderCheckboxValueOnHeaderChange(component, isSelected);
        helper.isAtleastOneRowSelected(component, isSelected);
    },
    addRemoveRow : function(component, event, helper) {
        var changedRow = event.getSource().get("v.name");
        var changedRowValue = event.getSource().get("v.checked");
        var allContacts = component.get("v.allContactsList");
        var allContactsLength  = allContacts.length;

        for(var i = 0; i < allContactsLength; i++) {
            if(allContacts[i].id == changedRow) {
                allContacts[i].isSelected = changedRowValue;
                break;
            }
        }

        component.set("v.allContactsList", allContacts);

        helper.setHeaderCheckboxValueOnRowChange(component, changedRowValue);
        helper.isAtleastOneRowSelected(component, changedRowValue);
    },
    onSendSurvey : function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.prepareSelectedContactsList(component);
        helper.sendSurvey(component);
    },
    onCancel : function(component, event, helper) {
    	helper.gotoRecord(component,component.get("v.psProjectId"));
	},
    goToFirstPage : function(component, event, helper) {
        component.set("v.currentPage", 1);
        helper.getContactsForCurrentPage(component);
    },
    goToPreviousPage : function(component, event, helper) {
        component.set("v.currentPage", component.get("v.currentPage") - 1);
        helper.getContactsForCurrentPage(component);
    },
    goToNextPage : function(component, event, helper) {
        component.set("v.currentPage", component.get("v.currentPage") + 1);
        helper.getContactsForCurrentPage(component);
    },
    goToLastPage : function(component, event, helper) {
        component.set("v.currentPage", component.get("v.totalPages"));
        helper.getContactsForCurrentPage(component);
    }
})