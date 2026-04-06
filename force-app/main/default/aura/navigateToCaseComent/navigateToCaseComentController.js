({
  init: function (cmp, evt, helper) {
    var myPageRef = cmp.get('v.pageReference');
    var caseId = myPageRef.state.c__caseId;
    var caseComm = myPageRef.state.c__caseComment;

    cmp.set('v.caseId', caseId);
    cmp.set('v.caseCommentVal', caseComm);
    //Js Controller

    var action = cmp.get('c.setFocusedTabLabel');
    $A.enqueueAction(action);
  },
  setFocusedTabLabel: function (component, event, helper) {
    var workspaceAPI = component.find('workspace');
    var myPageRef = component.get('v.pageReference');
    var caseId = myPageRef.state.c__caseId;
    workspaceAPI
      .getEnclosingTabId()
      .then(function (response) {
        // getEnclosingTabId getFocusedTabInfo
        var focusedTabId = response.tabId;
        workspaceAPI.setTabLabel({
          tabId: focusedTabId,
          label: 'Case Comment'
        });
      })
      .catch(function (error) {
        console.log(error);
      });
  }
});