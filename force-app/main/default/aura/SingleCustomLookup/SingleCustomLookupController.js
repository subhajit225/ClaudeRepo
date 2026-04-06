({
  onInit: function (component, event, helper) {
    if (component.get("v.sideDisplay")) {
      var lookupLabelDiv = component.find("lookupLabelDiv");
      $A.util.addClass(lookupLabelDiv, 'lookupLabelDiv');

      var lookupBox = component.find("lookupBox");
      $A.util.addClass(lookupBox, 'lookupBox');

      var lookupResultList = component.find("lookupResultList");
      $A.util.addClass(lookupResultList, 'lookupResultList');

      var lookupResultUlList = component.find("lookupResultUlList");
      $A.util.addClass(lookupResultUlList, 'lookupResultUlList');
    }
  },
  onfocus: function (component, event, helper) {
    $A.util.addClass(component.find("mySpinner"), "slds-show");
    var forOpen = component.find("searchRes");
    $A.util.addClass(forOpen, 'slds-is-open');
    $A.util.removeClass(forOpen, 'slds-is-close');
    // Get Default 5 Records order by createdDate DESC
    var getInputkeyWord = '';
    helper.searchHelper(component, event, getInputkeyWord);
  },
  onblur: function (component, event, helper) {
    component.set("v.listOfSearchRecords", null);
    var forclose = component.find("searchRes");
    $A.util.addClass(forclose, 'slds-is-close');
    $A.util.removeClass(forclose, 'slds-is-open');
  },
  keyPressController: function (component, event, helper) {
    // get the search Input keyword
    var getInputkeyWord = component.get("v.SearchKeyWord");
    // check if getInputKeyWord size id more then 0 then open the lookup result List and
    // call the helper
    // else close the lookup result List part.
    if (getInputkeyWord.length > 0) {
      var forOpen = component.find("searchRes");
      $A.util.addClass(forOpen, 'slds-is-open');
      $A.util.removeClass(forOpen, 'slds-is-close');
      helper.searchHelper(component, event, getInputkeyWord);
    }
    else {
      component.set("v.listOfSearchRecords", null);
      var forclose = component.find("searchRes");
      $A.util.addClass(forclose, 'slds-is-close');
      $A.util.removeClass(forclose, 'slds-is-open');
    }
  },

  // function for clear the Record Selaction
  clear: function (component, event, heplper) {
    var pillTarget = component.find("lookup-pill");
    var lookUpTarget = component.find("lookupField");

    $A.util.addClass(pillTarget, 'slds-hide');
    $A.util.removeClass(pillTarget, 'slds-show');

    $A.util.addClass(lookUpTarget, 'slds-show');
    $A.util.removeClass(lookUpTarget, 'slds-hide');

    component.set("v.SearchKeyWord", null);
    component.set("v.listOfSearchRecords", null);
    component.set("v.selectedRecord", {});
  },

  // This function call when the end User Select any record from the result list.
  handleComponentEvent: function (component, event, helper) {
    console.log("inside handlecomponentevent method");
    // get the selected record from the COMPONETN event
    var selectedRecord = event.getParam("recordByEvent");
    console.log("selectedRecord1===>",selectedRecord);

    if(!selectedRecord) {
      // get the selected record from the COMPONENT method
      var params = event.getParam("arguments");
      if(params) {
        selectedRecord = params.prepopulatedRecord;
      }
      console.log("selectedRecord2===>",selectedRecord.Id);
    }
    component.set("v.selectedRecord", selectedRecord);

    if (selectedRecord && selectedRecord.CaseNumber != null) {
      component.find("selectedRecordPill").set("v.label", selectedRecord.CaseNumber);
      component.find("selectedRecordPill").set("v.name", selectedRecord.CaseNumber);
    }

    var forclose = component.find("lookup-pill");
    $A.util.addClass(forclose, 'slds-show');
    $A.util.removeClass(forclose, 'slds-hide');

    var forclose = component.find("searchRes");
    $A.util.addClass(forclose, 'slds-is-close');
    $A.util.removeClass(forclose, 'slds-is-open');

    var lookUpTarget = component.find("lookupField");
    $A.util.addClass(lookUpTarget, 'slds-hide');
    $A.util.removeClass(lookUpTarget, 'slds-show');

  },
})