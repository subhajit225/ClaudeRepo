({
  handleYes: function (component, event, helper) {
    let rmaId = component.get('v.recordId');
    let orderType = 'RMA';
    let orderSubType = 'Tech Order';
    component.set('v.showCancel', 'false');
    component.set('v.content', '');
    helper
      .getOrder(component.get('c.getOrder'), rmaId, orderType, orderSubType)
      .then((order) => {
        component.set('v.order', order);
        if (order.Cancel_RMA__c) {
          component.set('v.showCancel', 'true');
          component.set('v.showOk', 'false');
          component.set('v.content', 'Order Already Cancelled');
          component.set('v.cancelButtonName', 'Cancel');
          return;
        }
        helper
          .cancelOrder(component.get('c.cancelOrder'), order.Id, component)
          .catch((err) => {
            component.set('v.showCancel', 'true');
            component.set('v.showOk', 'false');
            console.error(err);
            helper.showErrorToast(err);
            component.set('v.content', err);
            component.set('v.cancelButtonName', 'Cancel');
          }); 
      })
      .catch((err) => {
        component.set('v.showCancel', 'true');
        component.set('v.showOk', 'false');
        if (err !== 'List has no rows for assignment to SObject') {
          console.error(err);
          helper.showErrorToast(err);
          component.set('v.content', err);
        }
        component.set('v.content', 'No Tech Order for given RMA Order');
        component.set('v.cancelButtonName', 'Cancel');
      });
  },

  handleCancel: function (component) {
    $A.get('e.force:closeQuickAction').fire();
  }
});